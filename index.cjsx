path = require 'path-extra'
{layout, ROOT, $, $$, React, ReactBootstrap} = window
{TabbedArea, TabPane, Grid, Col, Row, Accordion, Panel, Nav, NavItem} = ReactBootstrap
{MissionPanel, NdockPanel, KdockPanel, TaskPanel, MiniShip} = require './parts'
module.exports =
  name: 'TimeGauge'
  priority: 100000
  displayName: [<FontAwesome key={0} name='clock-o' />, ' 计时面板']
  description: '计时面板，提供舰队各种信息倒计时'
  reactClass: React.createClass
    getInitialState: ->
      xs: if layout == 'horizonal' then 6 else 6
      key: 1
    handleChangeLayout: (e) ->
      {layout} = e.detail
      @setState
        xs: if layout == 'horizonal' then 6 else 6
    handleSelect: (key) ->
      @setState {key}
      @forceUpdate()
    componentDidMount: ->
      window.addEventListener 'layout.change', @handleChangeLayout
    componentWillUnmount: ->
      window.removeEventListener 'layout.change', @handleChangeLayout
    shouldComponentUpdate: (nextProps, nextState)->
      false
    render: ->
      <div>
        <link rel="stylesheet" href={path.join(path.relative(ROOT, __dirname), 'assets', 'timegauge.css')} />
        <div className="panel-container">
          <div className="combinedPanels" style={display:"flex", alignItems:"center"}>
            <Nav bsStyle='pills' stacked activeKey={@state.key} onSelect={@handleSelect}>
              <NavItem key={0} eventKey={0} id="navItemKdock">建造</NavItem>
              <NavItem key={1} eventKey={1} id="navItemNdock">入渠</NavItem>
            </Nav>
            <div className={"panel-col kdock-panel " + if @state.key == 0 then 'show' else 'hidden'} eventKey={0} key={0} style={flex: 1}>
              <KdockPanel />
            </div>
            <div className={"panel-col ndock-panel " + if @state.key == 1 then 'show' else 'hidden'} eventKey={1} key={1} style={flex: 1}>
              <NdockPanel />
            </div>
          </div>
          <div style={display:"flex", flexFlow:"row"}>
            <div style={display:"flex", flexFlow:"column nowrap", width:"50%"}>
              <div className="panel-col mission-panel" ref="missionPanel" >
                <MissionPanel />
              </div>
              <div className="panel-col task-panel" ref="taskPanel" >
                <TaskPanel />
              </div>
            </div>
            <div className="panel-col miniship" id={MiniShip.name} ref="miniship" >
              {React.createElement MiniShip.reactClass}
            </div>
          </div>
        </div>
      </div>
