{relative, join} = require 'path-extra'
{_, $, $$, React, ReactBootstrap, ROOT, toggleModal} = window
{$ships, $shipTypes, _ships} = window
{Button, ButtonGroup} = ReactBootstrap
{ProgressBar, OverlayTrigger, Tooltip, Alert, Overlay, Label, Panel, Popover} = ReactBootstrap

inBattle = [false, false, false, false]
getStyle = (state) ->
  if state in [0..5]
    # 0: Cond >= 40, Supplied, Repaired, In port
    # 1: 20 <= Cond < 40, or not supplied, or medium damage
    # 2: Cond < 20, or heavy damage
    # 3: Repairing
    # 4: In mission
    # 5: In map
    return ['success', 'warning', 'danger', 'info', 'default', 'primary'][state]
  else
    return 'default'

getDeckState = (deck) ->
  state = 0
  {$ships, _ships} = window
  # In mission
  if inBattle[deck.api_id - 1]
    state = Math.max(state, 5)
  if deck.api_mission[0] > 0
    state = Math.max(state, 4)
  for shipId in deck.api_ship
    continue if shipId == -1
    ship = _ships[shipId]
    shipInfo = $ships[ship.api_ship_id]
    # Cond < 20 or medium damage
    if ship.api_cond < 20 || ship.api_nowhp / ship.api_maxhp < 0.25
      state = Math.max(state, 2)
    # Cond < 40 or heavy damage
    else if ship.api_cond < 40 || ship.api_nowhp / ship.api_maxhp < 0.5
      state = Math.max(state, 1)
    # Not supplied
    if ship.api_fuel / shipInfo.api_fuel_max < 0.99 || ship.api_bull / shipInfo.api_bull_max < 0.99
      state = Math.max(state, 1)
    # Repairing
    if shipId in window._ndocks
      state = Math.max(state, 3)
  state

getHpStyle = (percent) ->
  if percent <= 25
    'danger'
  else if percent <= 50
    'warning'
  else if percent <= 75
    'primary'
  else
    'success'

getMaterialStyle = (percent) ->
  if percent <= 50
    'danger'
  else if percent <= 75
    'warning'
  else if percent < 100
    'primary'
  else
    'success'

getCondStyle = (cond) ->
  if cond > 84
    '#FCFA00'
  else if cond > 49
    '#FFCF00'
  else if cond < 20
    '#DD514C'
  else if cond < 30
    '#F37B1D'
  else if cond < 40
    '#FFC880'
  else
    '#FFF'

getStatusStyle = (status) ->
  flag = status.reduce (a, b) -> a or b
  if flag? and flag
    return {opacity: 0.4}
  else
    return {}
    # $("#ShipView #shipInfo").style.opacity = 0.4

getStatusArray = (shipId) ->
  status = []
  # retreat status
  status[0] = false
  # reparing
  status[1] = if shipId in _ndocks then true else false
  # special 1
  status[2] = false
  # special 2
  status[3] = false
  # special 3
  status[4] = false
  return status

getFontStyle = (theme)  ->
  if window.isDarkTheme then color: '#FFF' else color: '#000'

getCondCountdown = (deck) ->
  {$ships, $slotitems, _ships} = window
  countdown = [0, 0, 0, 0, 0, 0]
  cond = [49, 49, 49, 49, 49, 49]
  for shipId, i in deck.api_ship
    if shipId == -1
      countdown[i] = 0
      cond[i] = 49
      continue
    ship = _ships[shipId]
    # if ship.api_cond < 49
    #   cond[i] = Math.min(cond[i], ship.api_cond)
    cond[i] = ship.api_cond
    countdown[i] = Math.max(countdown[i], Math.ceil((49 - cond[i]) / 3) * 180)
  ret =
    countdown: countdown
    cond: cond

getBackdropStyle = ->
  if window.isDarkTheme
    backgroundColor: 'rgba(33, 33, 33, 0.7)'
  else
    backgroundColor: 'rgba(256, 256, 256, 0.7)'

# Tyku
# 制空値 = [(艦載機の対空値) × √(搭載数)] の総計
getTyku = (deck) ->
  {$ships, $slotitems, _ships, _slotitems} = window
  totalTyku = 0
  for shipId in deck.api_ship
    continue if shipId == -1
    ship = _ships[shipId]
    for itemId, slotId in ship.api_slot
      continue if itemId == -1
      item = _slotitems[itemId]
      if item.api_type[3] in [6, 7, 8]
        totalTyku += Math.floor(Math.sqrt(ship.api_onslot[slotId]) * item.api_tyku)
      else if item.api_type[3] == 10 && item.api_type[2] == 11
        totalTyku += Math.floor(Math.sqrt(ship.api_onslot[slotId]) * item.api_tyku)
  totalTyku

getDeckMessage = (deck) ->
  {$ships, $slotitems, _ships} = window
  totalLv = totalShip = 0
  for shipId in deck.api_ship
    continue if shipId == -1
    ship = _ships[shipId]
    totalLv += ship.api_lv
    totalShip += 1
  avgLv = totalLv / totalShip

  totalLv: totalLv
  avgLv: parseFloat(avgLv.toFixed(0))
  tyku: getTyku(deck)
  # saku25: getSaku25(deck)
  # saku25a: getSaku25a(deck)

###
# usage:
# get a ship's all status using props, sorted by status priority
# status array: [retreat, repairing, special1, special2, special3]
# value: boolean
###
StatusLabelMini = React.createClass
  render: ->
    if @props.status[0]? and @props.status[0]
      <Label bsStyle="danger"> </Label>
    else if @props.status[1]? and @props.status[1]
      <Label bsStyle="info"> </Label>
    else if @props.status[2]? and @props.status[2]
      <Label bsStyle="warning"> </Label>
    else if @props.status[3]? and @props.status[3]
      <Label bsStyle="primary"> </Label>
    else if @props.status[4]? and @props.status[4]
      <Label bsStyle="success"> </Label>
    else
      <Label bsStyle="default" style={border:"1px solid "}></Label>

###
# usage:
# display current deck status progress
# by repair mission and cond
# pass in
# repairTimer:
#   remain: int
#   total: int
# missionTimer
# condTimer
###
RecoveryBar = React.createClass
  componentDidMount: ->
    if @props.repairTimer?
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#28BDF4"
    else if @props.missionTimer?
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#747474"
    else if @props.condTimer?
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#F4CD28"
    else
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#7FC135"
  componentDidUpdate: (prevProps, prevState) ->
    if @props.repairTimer > 0
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#28BDF4"
    else if @props.missionTimer > 0
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#747474"
    else if @props.condTimer > 0
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#F4CD28"
    else
      $("#MiniShip #recProgress-#{@props.deckIndex}.progress-bar").style.backgroundColor = "#7FC135"
  render: ->
    if @props.repairTimer?
      <ProgressBar key={1} className="recProgress" id="recProgress-#{@props.deckIndex}" now={(@props.repairTimer.total - @props.repairTimer.remain) / @props.repairTimer.total * 100} />
    else if @props.missionTimer?
      <ProgressBar key={1} className="recProgress" id="recProgress-#{@props.deckIndex}" now={(@props.missionTimer.total - @props.missionTimer.remain) / @props.missionTimer.total * 100} />
    else if @props.condTimer?
      <ProgressBar key={1} className="recProgress" id="recProgress-#{@props.deckIndex}" now={(@props.condTimer.total - @props.condTimer.remain) / @props.condTimer.total * 100} />
    else
      <ProgressBar key={1} className="recProgress" id="recProgress-#{@props.deckIndex}" now={100} />

Slotitems = React.createClass
  render: ->
    <div className="slotitems">
    {
      {$slotitems, _slotitems} = window
      for itemId, i in @props.data
        continue if itemId == -1
        item = _slotitems[itemId]
        <div key={i} className="slotitem-container">
          <img key={itemId} src={join('assets', 'img', 'slotitem', "#{item.api_type[3] + 33}.png")} />
          <span>
            {item.api_name}
            {if item.api_level > 0 then <strong style={color: '#45A9A5'}>★+{item.api_level}</strong> else ''}
          </span>
          <span className="slotitem-onslot label label-default
                          #{if (item.api_type[3] >= 6 && item.api_type[3] <= 10) || (item.api_type[3] >= 21 && item.api_type[3] <= 22) || item.api_type[3] == 33 then 'show' else 'hide'}
                          #{if @props.onslot[i] < @props.maxeq[i] then 'text-warning' else ''}"
                          style={getBackdropStyle()}>
            {@props.onslot[i]}
          </span>
        </div>
    }
    </div>

TopAlert = React.createClass
  messages: ['没有舰队信息']
  countdown: [0, 0, 0, 0, 0, 0]
  maxCountdown: 0
  missionCountdown: 0
  completeTime: 0
  timeDelta: 0
  cond: [0, 0, 0, 0, 0, 0]
  isMount: false
  inBattle: false
  getInitialState: ->
    inMission: false
  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    refreshFlag = false
    switch path
      when '/kcsapi/api_port/port'
        if @props.deckIndex != 0
          deck = body.api_deck_port[@props.deckIndex]
          @missionCountdown = -1
          switch deck.api_mission[0]
            # In port
            when 0
              @missionCountdown = -1
              @completeTime = -1
            # In mission
            when 1
              @completeTime = deck.api_mission[2]
              @missionCountdown = Math.floor((deck.api_mission[2] - new Date()) / 1000)
            # Just come back
            when 2
              @completeTime = 0
              @missionCountdown = 0
        @inBattle = false
        refreshFlag = true
      when '/kcsapi/api_req_mission/start'
        # postBody.api_deck_id is a string starting from 1
        if postBody.api_deck_id == "#{@props.deckIndex + 1}"
          @completeTime = body.api_complatetime
          @missionCountdown = Math.floor((body.api_complatetime - new Date()) / 1000)
          @inBattle = false
          refreshFlag = true
      when '/kcsapi/api_req_mission/return_instruction'
        if postBody.api_deck_id == @props.deckIndex
          @completeTime = body.api_mission[2]
          @missionCountdown = Math.floor((body.api_mission[2] - new Date()) / 1000)
          @inBattle = false
          refreshFlag = true
      when '/kcsapi/api_req_map/start'
        @inBattle = true
      when '/kcsapi/api_get_member/deck', '/kcsapi/api_get_member/ship_deck', '/kcsapi/api_get_member/ship2', '/kcsapi/api_get_member/ship3'
        refreshFlag = true
      when '/kcsapi/api_req_hensei/change', '/kcsapi/api_req_kaisou/powerup', '/kcsapi/api_req_kousyou/destroyship', '/kcsapi/api_req_nyukyo/start'
        refreshFlag = true
    if refreshFlag
      @setAlert()
  getState: ->
    if @state.inMission
      return '远征'
    else
      return '回复'
  setAlert: ->
    decks = window._decks
    @messages = getDeckMessage decks[@props.deckIndex]
    tmp = getCondCountdown decks[@props.deckIndex]
    @missionCountdown = Math.max(0, Math.floor((@completeTime - new Date()) / 1000))
    {inMission} = @state
    changeFlag = false
    if @missionCountdown > 0
      @maxCountdown = @missionCountdown
      @timeDelta = 0
      if not inMission
        changeFlag = true
      @cond = tmp.cond
    else
      @maxCountdown = tmp.countdown.reduce (a, b) -> Math.max a, b    # new countdown
      @countdown = tmp.countdown
      minCond = tmp.cond.reduce (a, b) -> Math.min a, b               # new cond
      thisMinCond = @cond.reduce (a, b) -> Math.min a, b              # current cond
      if thisMinCond isnt minCond
        @timeDelta = 0
      @cond = tmp.cond
      if inMission
        changeFlag = true
    if changeFlag
      @setState
        inMission: not inMission
    if @maxCountdown > 0
      @interval = setInterval @updateCountdown, 1000 if !@interval?
    else
      if @interval?
        @interval = clearInterval @interval
        @clearCountdown()
  componentWillUpdate: ->
    @setAlert()
  updateCountdown: ->
    flag = true
    if @maxCountdown - @timeDelta > 0
      flag = false
      @timeDelta += 1
      # Use DOM operation instead of React for performance
      if @isMount
        $("#MiniShip #deck-condition-countdown-#{@props.deckIndex}-#{@componentId}").innerHTML = resolveTime(@maxCountdown - @timeDelta)
      if @timeDelta % (3 * 60) == 0
        cond = @cond.map (c) => if c < 49 then Math.min(49, c + @timeDelta / 60) else c
        @props.updateCond(cond)
      # if @maxCountdown is @timeDelta and not @inBattle and not @state.inMission and window._decks[@props.deckIndex].api_mission[0] <= 0
      #   notify "#{@props.deckName} 疲劳回复完成",
      #     type: 'morale'
      #     icon: join(ROOT, 'assets', 'img', 'operation', 'sortie.png')
    if flag or (@inBattle and not @state.inMission)
      @interval = clearInterval @interval
      @clearCountdown()
  clearCountdown: ->
    if @isMount
      $("#MiniShip #deck-condition-countdown-#{@props.deckIndex}-#{@componentId}").innerHTML = resolveTime(0)
  componentWillMount: ->
    @componentId = Math.ceil(Date.now() * Math.random())
    if @props.deckIndex != 0
      deck = window._decks[@props.deckIndex]
      @missionCountdown = -1
      switch deck.api_mission[0]
        # In port
        when 0
          @missionCountdown = -1
          @completeTime = -1
        # In mission
        when 1
          @completeTime = deck.api_mission[2]
          @missionCountdown = Math.floor((deck.api_mission[2] - new Date()) / 1000)
        # Just come back
        when 2
          @completeTime = 0
          @missionCountdown = 0
    @setAlert()
  componentDidMount: ->
    @isMount = true
    window.addEventListener 'game.response', @handleResponse
  componentWillUnmount: ->
    window.removeEventListener 'game.response', @handleResponse
    @interval = clearInterval @interval if @interval?
  render: ->
    <div style={display: "flex", justifyContent: "space-around"}>
      <span style={flex: "none"}>总 Lv.{@messages.totalLv}</span>
      <span style={flex: "none"}>均 Lv.{@messages.avgLv}</span>
      <span style={flex: "none"}>制空:&nbsp;{@messages.tyku}</span>

      <span style={flex: "none"}>{@getState()}:&nbsp;<span id={"deck-condition-countdown-#{@props.deckIndex}-#{@componentId}"}>{resolveTime @maxCountdown}</span></span>
    </div>

PaneBody = React.createClass
  condDynamicUpdateFlag: false
  getInitialState: ->
    cond: [0, 0, 0, 0, 0, 0]
    repairTimer:
      remain: 10
      total: 100
    missionTimer:
      remain: 20
      total: 100
    condTimer:
      remain: 50
      total: 100
  onCondChange: (cond) ->
    condDynamicUpdateFlag = true
    @setState
      cond: cond
  shouldComponentUpdate: (nextProps, nextState) ->
    nextProps.activeDeck is @props.deckIndex
  componentWillReceiveProps: (nextProps) ->
    if @condDynamicUpdateFlag
      @condDynamicUpdateFlag = not @condDynamicUpdateFlag
    else
      cond = [0, 0, 0, 0, 0, 0]
      for shipId, j in nextProps.deck.api_ship
        if shipId == -1
          cond[j] = 49
          continue
        ship = _ships[shipId]
        cond[j] = ship.api_cond
      @setState
        cond: cond
  componentWillMount: ->
    cond = [0, 0, 0, 0, 0, 0]
    for shipId, j in @props.deck.api_ship
      if shipId == -1
        cond[j] = 49
        continue
      ship = _ships[shipId]
      cond[j] = ship.api_cond
    @setState
      cond: cond
  render: ->
    <div>
      <div style={display:"flex", justifyContent:"space-between", margin:"5px 0"}>
        <OverlayTrigger trigger='hover' placement="top" overlay={
          <Popover>
            <div>
              <TopAlert
                updateCond={@onCondChange}
                messages={@props.messages}
                deckIndex={@props.deckIndex}
                deckName={@props.deckName}
              />
            </div>
          </Popover>
          }>
          <Label className="shipMore" bsStyle="default" style={flex:"none"}>◎</Label>
        </OverlayTrigger>
        <RecoveryBar style={flex:"auto"}
          deck={@props.deck}
          deckIndex = {@props.deckIndex}
          repairTimer = {@state.repairTimer}
          missionTimer = {@state.missionTimer}
          condTimer = {@state.condTimer}
          />
      </div>
      <div className="shipDetails">
      {
        {$ships, $shipTypes, _ships} = window
        for shipId, j in @props.deck.api_ship
          continue if shipId == -1
          ship = _ships[shipId]
          shipInfo = $ships[ship.api_ship_id]
          shipType = $shipTypes[shipInfo.api_stype].api_name
          status = getStatusArray shipId
          [
            <div className="shipTile">
              <div className="statusLabel">
                <StatusLabelMini status={status}/>
              </div>
              <div className="shipItem" style={getStatusStyle status}>
                <OverlayTrigger trigger='hover' placement="top" overlay={
                  <Popover>
                    <div>
                      <Slotitems className="shipSlot" data={ship.api_slot} onslot={ship.api_onslot} maxeq={ship.api_maxeq} />
                    </div>
                  </Popover>
                }>
                  <div className="shipInfo" >
                    <span className="shipLv">
                      Lv. {ship.api_lv}
                    </span>
                    <span className="shipName">
                      {shipInfo.api_name}
                    </span>
                    <span className="shipCond" style={color:getCondStyle ship.api_cond}>
                      ★{ship.api_cond}
                    </span>
                  </div>
                </OverlayTrigger>
                <div style={display:"flex", flexFlow:"row nowrap", width:"100%", marginTop:5}>
                  <span className="shipHp">
                    <span className="shipHpText" style={flex: "none", display: "flex"}>
                      {ship.api_nowhp} / {ship.api_maxhp}
                    </span>
                    <OverlayTrigger show = {ship.api_ndock_time} placement='bottom' overlay={<Tooltip>入渠时间：{resolveTime ship.api_ndock_time / 1000}</Tooltip>}>
                      <ProgressBar style={flex: "auto"} bsStyle={getHpStyle ship.api_nowhp / ship.api_maxhp * 100} now={ship.api_nowhp / ship.api_maxhp * 100} />
                    </OverlayTrigger>
                    <span className="shipFB" style={flex: "none"}>
                      <ProgressBar bsStyle={getMaterialStyle ship.api_fuel / shipInfo.api_fuel_max * 100}
                                   now={ship.api_fuel / shipInfo.api_fuel_max * 100} />
                    </span>
                    <span className="shipFB" style={flex: "none"}>
                      <ProgressBar bsStyle={getMaterialStyle ship.api_bull / shipInfo.api_bull_max * 100}
                                   now={ship.api_bull / shipInfo.api_bull_max * 100} />
                    </span>
                  </span>
                </div>

              </div>
            </div>
          ]
      }
      </div>
    </div>

module.exports =
  name: 'MiniShip'
  priority: 100000.1
  displayName: <span><FontAwesome key={0} name='bars' /> Mini舰队</span>
  description: '舰队展示页面，展示舰队详情信息'
  reactClass: React.createClass
    getInitialState: ->
      names: ['I', 'II', 'III', 'IV']
      states: [-1, -1, -1, -1]
      decks: []
      activeDeck: 0
      dataVersion: 0
    showDataVersion: 0
    shouldComponentUpdate: (nextProps, nextState)->
      # if ship-pane is visibile and dataVersion is changed, this pane should update!
      if nextProps.selectedKey is @props.index and nextState.dataVersion isnt @showDataVersion
        @showDataVersion = nextState.dataVersion
        return true
      if @state.decks.length is 0 and nextState.decks.length isnt 0
        return true
      false
    handleClick: (idx) ->
      if idx isnt @state.activeDeck
        @setState
          activeDeck: idx
          dataVersion: @state.dataVersion + 1
    handleResponse: (e) ->
      {method, path, body, postBody} = e.detail
      {names} = @state
      flag = true
      switch path
        when '/kcsapi/api_port/port'
          # names = body.api_deck_port.map (e) -> e.api_name
          inBattle = [false, false, false, false]
        when '/kcsapi/api_req_hensei/change', '/kcsapi/api_req_hokyu/charge', '/kcsapi/api_get_member/deck', '/kcsapi/api_get_member/ship_deck', '/kcsapi/api_get_member/ship2', '/kcsapi/api_get_member/ship3', '/kcsapi/api_req_kousyou/destroyship', '/kcsapi/api_req_kaisou/powerup', '/kcsapi/api_req_nyukyo/start', '/kcsapi/api_req_nyukyo/speedchange'
          true
        when '/kcsapi/api_req_map/start'
          deckId = parseInt(postBody.api_deck_id) - 1
          inBattle[deckId] = true
          {decks, states} = @state
          {_ships} = window
          deck = decks[deckId]
          # for shipId in deck.api_ship
          #   continue if shipId == -1
          #   ship = _ships[shipId]
          #   if ship.api_nowhp / ship.api_maxhp < 0.250001
          #     toggleModal '出击注意！', "Lv. #{ship.api_lv} - #{ship.api_name} 大破，可能会被击沉！"
        # when '/kcsapi/api_req_map/next'
        #   {decks, states} = @state
        #   {_ships} = window
        #   for deck, i in decks
        #     continue if states[i] != 5
        #     for shipId in deck.api_ship
        #       continue if shipId == -1
        #       ship = _ships[shipId]
        #       if ship.api_nowhp / ship.api_maxhp < 0.250001
        #         toggleModal '进击注意！', "Lv. #{ship.api_lv} - #{ship.api_name} 大破，可能会被击沉！"
        else
          flag = false
      return unless flag
      decks = window._decks
      states = decks.map (deck) ->
        getDeckState deck
      @setState
        names: names
        decks: decks
        states: states
        dataVersion: @state.dataVersion + 1
    componentDidMount: ->
      window.addEventListener 'game.response', @handleResponse
    componentWillUnmount: ->
      window.removeEventListener 'game.response', @handleResponse
      @interval = clearInterval @interval if @interval?
    render: ->
      <Panel bsStyle="default" >
        <link rel="stylesheet" href={join(relative(ROOT, __dirname),'..', 'assets', 'miniship.css')} />
        <ButtonGroup>
        {
          for i in [0..3]
            <Button key={i} bsSize="small"
                            bsStyle={getStyle @state.states[i]}
                            onClick={@handleClick.bind(this, i)}
                            className={if @state.activeDeck == i then 'active' else ''}>
              {@state.names[i]}
            </Button>
        }
        </ButtonGroup>
        {
          for deck, i in @state.decks
            <div className="ship-deck" className={if @state.activeDeck is i then 'show' else 'hidden'} key={i}>
              <PaneBody
                key={i}
                deckIndex={i}
                deck={@state.decks[i]}
                activeDeck={@state.activeDeck}
                deckName={@state.names[i]}
              />
            </div>
        }
      </Panel>
