Spine  = require('spine')

Marker          =   require 'controllers/Marker'
MarkingSurface  =   require 'controllers/MarkingSurface'

User            = require 'zooniverse/lib/models/user'


class Classifier extends Spine.Controller
  className: "Classifier"

  markingSurface: null

  shapes : [
    (circleShape: {
      lines      :  [[{type:'circle', def: 2, visibility: 1}]]
      joins      :  []
      fan         : false
    }),

    (lineShape: {
      lines    :  [
                    {type:'line', def: 2, visibility: 1},
                  ]
      joins      :  [],
      fan        : false
    }),

    (fanShape: {
      lines    :  [
                    [
                      {type:'line', def: 1, visibility: 1},
                      {type:'line', visibility: 1},
                      {type:'line', def: 2, visibility: 1},
                      {type:'line', visibility: 1, controlX:0.5, controlY: 10, radius: 10}
                    ]
                  ]
      joins       : [],
      fan         : true
    })
  ]

  count : 0


  elements:
    '.toggles li'       : 'toolSelector'
    '.blackWhite span'  : 'colourSelector'
    
    '#selectionArea img': 'image'
    '#selectionArea'    : 'sel'
    #'.classifierControls': 'controls'

  events:
    'click .toggles li'       : 'changeTool'
    'click .blackWhite span'  : 'changeColour'
    'click .next'             : 'next'
    #'mouseenter .options'     : 'show'
    #'mouseleave .options'     : 'hide'


  constructor: ->
    super
    console.log @shapes[2]

    for shape in @shapes
      shape.onDeselect = @deselectTransition
      shape.onSelect   = @selectTransition

    @shapes[2].draw = @fanDraw
    @markingSurface = new MarkingSurface
    @render()
    @renderControls()


  render:=>
    @html require('views/classifier')
   
  hide: =>
    @controls.slideUp "slow"

  show: (e) =>
    console.log 'showing'
    currY = e.pageY- selectionArea.offsetTop
    area =  @el.height() - 50
    #if currY >= area
    #@controls.slideToggle();
    @controls.slideDown "slow"
    #@controls.show "slide"

  test:=>
    console.log 'test'

  renderControls:=>
    @append require('views/classifierControls')()

  changeTool: (e) =>
    target = $(e.target).closest 'li'
    tool   = target.data 'value'
    
    @toolSelector.removeClass 'active'

    
    if @markingSurface.selectedTool is tool
      @markingSurface.selectedTool = null
    else
      @markingSurface.selectedTool  = tool
      @markingSurface.selectedShape = @shapes[target.data 'shape']
      target.addClass 'active'

    @markingSurface.changeClassification()


  changeColour: (e) =>
    target = $(e.target)
    colour = target.contents()[0]
    console.log(colour)

    @colourSelector.removeClass 'active'

    target.addClass 'active'

  next: (e) =>
    if @count < 8
      @markingSurface.nextImage((@count+1)+'.png')
      @count++
    else
      console.log 'Out of images'

  fanDraw : (i) ->

    if @anchors[i].isMoving 

      a = @layer.get("#A")[0]
      b = @layer.get("#B")[0]
      c = @layer.get("#C")[0]
      d = @layer.get("#D")[0]

      ax = a.getX()
      ay = a.getY()
      cx = c.getX()
      cy = c.getY()
      
      frac = Math.abs(cx - ax) / Math.abs(c.getY() - a.getY())
      angle = (Math.atan(frac))%(2*Math.PI)

      ninety = 90 * (Math.PI/180)
      if cy < ay
        if cx < ax then angle = ninety + (ninety-angle) else angle = (ninety*2) + angle
      else if cx > ax then angle = (ninety*3)  + (ninety - angle)

      axis = Math.sqrt( Math.pow(a.attrs.x - c.attrs.x, 2) + Math.pow(a.attrs.y - c.attrs.y, 2))
      scale = (axis/5)

      x = (ax - scale - ax)
      y = (ay + scale - ay)
      b.setX( ( x * Math.cos(angle)) - (y * Math.sin(angle)) + ax)
      b.setY( ( x * Math.sin(angle)) + (y * Math.cos(angle)) + ay)

      x = (ax + scale - ax)
      y = (ay + scale - ay)
      d.setX( ( x * Math.cos(angle)) - (y * Math.sin(angle)) + ax)
      d.setY( ( x * Math.sin(angle)) + (y * Math.cos(angle)) + ay)

  selectTransition: ->

    @shape.transitionTo({
      duration: 0.5,
      strokeWidth: 3,
      easing: 'linear'
    });

    @shape.setFill("rgba(0,0,0,0)")
    @shape.setStroke("rgba(255,255,255,0.5)")

    for anchor in @anchors
      anchor.show()
    

  deselectTransition: ->

    @shape.transitionTo({
      duration: 1,
      strokeWidth: 0,
      easing: 'linear'
    });

    @shape.setFill("rgba(0,0,0,0.3)")
    @shape.setStroke("rgba(0,0,0,0.3)")

    for anchor in @anchors
      anchor.hide()


    
module.exports = Classifier