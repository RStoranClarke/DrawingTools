Spine  = require('spine')

Marker          =   require 'controllers/Marker'

class MarkingSurface extends Spine.Controller
  className: "MarkingSurface"

  selectedTool  : null
  selectedShape : null

  markers       : []
  currMarker    : null

  layers        : []

  count : null

  elements:
    '#selectionArea' : 'selectionArea'
    '#selectionArea img' : 'image'

  events:
    'mousedown' : 'test'
    'click #selectionArea': 'test'

  test: =>
    console.log 'clicky'
    @image.attr 'src', "http://mars.jpl.nasa.gov/MPF/parker/TwnPks_RkGdn_left_th.jpg"
    @resize()


  constructor: ->
    super
    @render()

    console.log @el
    window.markers = @markers
    @delay =>
      @setUpCanvas()
      @setUpAsset()
    ,2

  render:=>
    @html require('views/classifier')
    
  setUpCanvas:=>
    @stage = new Kinetic.Stage
      container: 'selectionArea'
      width: 1000
      height: 631
      stroke: "#000"

    @stage._onContent 'mousedown  touchdown', @onMouseDown

  setUpAsset:=>
    @nextImage('sampleAsset.png')
    $(".kineticjs-content").css("background-size", "cover")

  nextImage: (img) =>
    $(".kineticjs-content").css("background-image", "url('"+img+"')")
    @stage.clear()
    for i in [0..@layers.length-1]
      @stage.remove @layers[i]
    if @selectedTool?
      @currMarker = @createMarker()
    else
      @currMarker = null
   
  onMouseDown: (e) =>
    m.deselect() for m in @markers when m.selected

    hover = false
    for m in @markers 
      if m.hover and @currMarker?
        #@currMarker.disable(true)
        hover = true
    
    #if not hover and @currMarker?
      #@currMarker.disable(false)
      
    #return unless @stage._onContent is e.target 
    return unless @selectedTool?
    @currMarker.onMouseDown(e)

    @delay =>
      console.log 'check'
      if @currMarker? and @currMarker.isComplete()
        console.log 'done'
        @currMarker = @createMarker()
        @currMarker.onMouseDown(e)
    ,20

    

  createMarker: =>
    console.log 'New Marker'
    @count++


    console.log 'def', @selectedShape.lines
    marker = new Marker
     el          : @el
     stage       : @stage
     deflines    : @selectedShape.lines
     joins       : @selectedShape.joins
     id          : @count
     fan         : @selectedShape.fan
     onDeselect  : @selectedShape.onDeselect
     onSelect    : @selectedShape.onSelect
     draw        : @selectedShape.draw

    @markers.push marker

    @layers.push @markers[@markers.length-1].getLayer()
    window.layers = @layers
    @stage.add @markers[@markers.length-1].getLayer()

    @stage.draw()
    marker


  changeClassification: (@classification) =>
    console.log 'Changing'

    if @currMarker?
      if @currMarker.isComplete()
       console.log 'Complete'
       @currMarker = null
      else
       console.log 'Deleting'

       @stage.remove @layers[@layers.length-1]

       @layers[@layers.length-1] = null
       @layers.pop()
       @markers[@markers.length - 1].disable()
       @markers[@markers.length - 1] = null
       @markers.pop()

       console.log @markers
       console.log @layers

     if @selectedTool?
      @currMarker = @createMarker()
     else
      @currMarker = null


module.exports = MarkingSurface