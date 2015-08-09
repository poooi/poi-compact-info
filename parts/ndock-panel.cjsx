{ROOT, layout, _, $, $$, React, ReactBootstrap} = window
{resolveTime} = window
{Panel, Table, Label} = ReactBootstrap
{join} = require 'path-extra'

NdockPanel = React.createClass
  getInitialState: ->
    docks: [
        name: '未使用'
        completeTime: -1
        countdown: -1
      ,
        name: '未使用'
        completeTime: -1
        countdown: -1
      ,
        name: '未使用'
        completeTime: -1
        countdown: -1
      ,
        name: '未使用'
        completeTime: -1
        countdown: -1
      ,
        name: '未使用'
        completeTime: -1
        countdown: -1
    ]
    notified: []
  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    {$ships, _ships} = window
    {docks, notified} = @state
    switch path
      when '/kcsapi/api_port/port'
        for ndock in body.api_ndock
          id = ndock.api_id
          switch ndock.api_state
            when -1
              docks[id] =
                name: '未解锁'
                completeTime: -1
                countdown: -1
            when 0
              docks[id] =
                name: '未使用'
                completeTime: -1
                countdown: -1
              notified[id] = false
            when 1
              docks[id] =
                name: $ships[_ships[ndock.api_ship_id].api_ship_id].api_name
                completeTime: ndock.api_complete_time
                countdown: Math.floor((ndock.api_complete_time - new Date()) / 1000)
        @setState
          docks: docks
          notified: notified
      when '/kcsapi/api_get_member/ndock'
        for ndock in body
          id = ndock.api_id
          switch ndock.api_state
            when -1
              docks[id] =
                name: '未解锁'
                completeTime: -1
                countdown: -1
            when 0
              docks[id] =
                name: '未使用'
                completeTime: -1
                countdown: -1
              notified[id] = false
            when 1
              docks[id] =
                name: $ships[_ships[ndock.api_ship_id].api_ship_id].api_name
                completeTime: ndock.api_complete_time
                countdown: Math.floor((ndock.api_complete_time - new Date()) / 1000)
        @setState
          docks: docks
          notified: notified
  updateCountdown: ->
    {docks, notified} = @state
    for i in [1..4]
      if docks[i].countdown > 0
        docks[i].countdown = Math.floor((docks[i].completeTime - new Date()) / 1000)
        if docks[i].countdown <= 60 && !notified[i]
          notify "#{docks[i].name} 修复完成",
            type: 'repair'
            icon: join(ROOT, 'assets', 'img', 'operation', 'repair.png')
          notified[i] = true
    @setState
      docks: docks
      notified: notified
  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
    setInterval @updateCountdown, 1000
  componentWillUnmount: ->
    window.removeEventListener 'game.response', @handleResponse
    clearInterval @updateCountdown, 1000
  render: ->
    <Panel bsStyle="default" >
    {
      for i in [1..4]
        if @state.docks[i].countdown > 60
          <div key={i} className="panelItem ndockItem">
            <div className="ndockName">{@state.docks[i].name}</div>
            <Label className="ndockTimer" bsStyle="info">
              {resolveTime @state.docks[i].countdown}
            </Label>
          </div>
        else if @state.docks[i].countdown > -1
          <div key={i}  className="panelItem ndockItem">
            <div className="ndockName">{@state.docks[i].name}</div>
            <Label className="ndockTimer" bsStyle="success">
              {resolveTime @state.docks[i].countdown}
            </Label>
          </div>
        else
          <div key={i}  className="panelItem ndockItem">
            <div className="ndockName">{@state.docks[i].name}</div>
            <Label className="ndockTimer" bsStyle="default">
              {resolveTime 0}
            </Label>
          </div>
    }
    </Panel>

module.exports = NdockPanel
