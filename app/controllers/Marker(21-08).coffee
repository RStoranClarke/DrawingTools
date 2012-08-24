Spine = require('spine')

class Marker extends Spine.Controller
  className: "Marker"

  stage       : null

  noLines     : null
  closed      : null
  joins       : null
  defPoints   : null
  visibility  : null

  annotation  : null
  complete    : null
  
  shapes      : null
  layer       : null

  label       : null

  id          : null  
  disabled    : null
  closed      : null
  selected    : false


  elements:=>
    '#selectionArea' : 'selectionArea'

  constructor: ->
    super

    @shapes   = []
    @complete = false
    @disabled = false
    @layer    = new Kinetic.Layer({drawFunc : @drawJoin})

    @checkValid()
    @render()
    @bindEvents()
    @buildPoly()

    @delay =>
      @addJoin(join) for join in @joins
      @layer.draw()
    ,200

  checkValid :=>
    # TO-DO: 
    # - Repeat in deinintion points

    return if @noLines is 0

    if @defPoints.length > ((@noLines*2)-@joins.length)
      throw new Error("More Definition Points have been specified than exist")
    if @visibility.length < @noLines
      throw new Error("Visibility has not been specified for all lines")
    if @visibility.length > @noLines
      throw new Error("Visibility has been specified for more lines than exist")
    for join in @joins
      if join.length is not 2
        throw new Error("Joins must consist of two points")
      # Join consists of a number in the range of noLines and a letter (either a or b)
      if parseInt(join[0][0]) > @noLines || parseInt(join[0][0]) < 1
        throw new Error("Join ["+join+"] is invalid, line "+join[0][0]+" does not exist.")
      if parseInt(join[1][0]) > @noLines || parseInt(join[1][0]) < 1
        throw new Error("Join ["+join+"] is invalid, line "+join[1][0]+" does not exist.")

  render:=>
    @html require('views/classifier')

  bindEvents :=>
   # @stage._onContent 'mousedown', (e)=>
     # @onMouseDown (e)
    @stage._onContent 'mousemove', (e)=>
      @onMouseMove (e)
    @stage._onContent 'mouseup', (e)=>
      @onMouseUp (e)

    @hover = false
 
  getLayer:=>
    @layer

  isComplete:=>
    @complete

  disable: (disable)=>
    @disabled = disable

  onMouseEnter:=>
    @hover = true

  onMouseLeave:=>
    @hover = false


  buildAnchor: (x, y, id) =>
    
    anchor = new Kinetic.Circle({
      id : id,
      name : "anchor",
      x: x,
      y: y,
      radius: 5,
      stroke: "#fff",
      strokeWidth: 2,
      fill: "#fff",
      draggable: true,
      visible: false
    });

    anchor.start =  { x: x, y: y }
    anchor.was   =  { x: 0, y: 0 }

    # Add event animations
    anchor.on "mouseover", (e) =>
      document.body.style.cursor = "move";
      @layer.draw();

    anchor.on "mouseout", (e) =>
      document.body.style.cursor = "default";
      @layer.draw();

    @layer.add(anchor);
    anchor.moveToTop()

    anchor

  buildLine : (i) =>

    line = new Kinetic.Line({
      id : "line"+i+'-'+@id,
      stroke: '#fff',
      strokeWidth: 3, 
      draggable: 'true',
      visible: false
    });  

    line.on 'dragend', (e) =>
      line.saveImageData()

    line.on "mouseover", (e) =>
      document.body.style.cursor = "pointer";
      @layer.draw();

    line.vertices  = [ @buildAnchor(100, i*20+200, i+'a') ,  @buildAnchor(200, i*20+200, i+'b') ]
    line.was       = { x: 0, y: 0 }

    line

  buildCircle : =>

    circle = new Kinetic.Circle({
      id : "circle"+@id,
      name : "circle"+@id,
      x: 150,
      y: 150,
      stroke: '#fff',
      strokeWidth: 3,
      fill: 'rgba(0,0,0,0)',
      draggable: true,
      visible: false
    });  

    circle.destroy = =>
      console.log 'destroying'

    circle.vertices  = [ @buildAnchor(150, 150, '2a') ,  @buildAnchor(150+5, 150, '2b')]
    circle.was       = { x: 0, y: 0 }

    circle

  buildPoly : =>
    
    if @noLines is 0
     circle = @buildCircle()
     @shapes.push circle
    else
      for i in [1..@noLines]
        line =  @buildLine(i) 
        @shapes.push line

    for shape in @shapes
      @layer.add shape


     # @shapes.push poly
    @movementAxis = @buildLine 0
    @movementAxis.setDashArray([10, 5])
    @layer.add @movementAxis
    @movementAxis.hide()
    @noLines++

  addPoint : =>
    @currAnchor = @layer.get("#"+@defPoints[@pointsPlaced])[0]

    return unless @currAnchor? 

    @currAnchor.setX(@currPos.x);
    @currAnchor.setY(@currPos.y);

    @currAnchor.placed   = true
    @currAnchor.isMoving = false

    @movementAxis.vertices[0].setX(@currPos.x)
    @movementAxis.vertices[0].setY(@currPos.y)

    @currAnchor.show()  

    @pointsPlaced++
  
  mouseMoves: 0
  onMouseDown: (e) =>
    e.stopPropagation()
    return if @complete or @disabled

    @mouseIsDown = true
    @currPos = {x:e.layerX , y:e.layerY }

    @addPoint()
    e.preventDefault?()

    @layer.draw()

  onMouseMove: (e) =>
    return unless @mouseIsDown
    return if @complete or @disabled
    return if @pointsPlaced >= @defPoints.length

    currX = e.layerX 
    currY = e.layerY
    @movementAxis.setPoints([@currPos.x,@currPos.y,currX,currY])
    @movementAxis.vertices[1].setX(currX)
    @movementAxis.vertices[1].setY(currY)

    @currAnchor = @layer.get("#"+@defPoints[@pointsPlaced])[0]
    return unless @currAnchor?
    @currAnchor.isMoving = true
    @currAnchor.setX(currX);
    @currAnchor.setY(currY);

    @movementAxis.show()

    for i in [0..@shapes.length-1]
      if @visibility[i] <= @pointsPlaced
        @shapes[i].show()  
        for vertex in @shapes[i].vertices
          vertex.show()   
    
    @movementAxis.moveToBottom()
    @layer.draw()


  pointsPlaced : 0
  onMouseUp: (e) =>

    if @currAnchor
      if @currAnchor.isMoving
        @currPos = {x:e.layerX , y:e.layerY }
        @addPoint()
      @currAnchor.isMoving = false

    return if @disabled
    return unless @mouseIsDown and @pointsPlaced is @defPoints.length

    @complete = true
    @disabled = true
    @close()
    @bind()
    @deselect()
    
    @mouseIsDown = false

    axis = @layer.get('#line0'+'-'+@id)[0]
    @layer.remove(axis)
    @layer.remove(axis.vertices[0])
    @layer.remove(axis.vertices[1])

    @layer.draw()

  bind: =>
    for shape in @shapes
      shape.on 'dragstart click', (e)=>
        @select()
      shape.on 'mouseout click', (e)=>
        @onMouseLeave (e)
      shape.on 'mouseover', (e)=>
        @onMouseEnter (e)
    for anchor in @layer.get(".anchor")
      anchor.on 'dragstart click', (e)=>
        @select()
      anchor.on 'mouseout click', (e)=>
        @onMouseLeave (e)
      anchor.on 'mouseover', (e)=>
        @onMouseEnter (e)


  defaultDraw : (i) =>
    anchors = @layer.get(".anchor") 
    if anchors[i].isMoving and @fan
        for j in [0..anchors.length-1]
          if (j isnt i) and (not anchors[j].placed) and (anchors[j].attrs.id[0] isnt '0')

            line1 = @layer.get('#line4-'+@id)[0]
            line2 = @layer.get('#line2-'+@id)[0] 
            line3 = @layer.get('#line3-'+@id)[0]
            
            
            a = line3.vertices[1]
            b = line2.vertices[1]
            c = anchors[i]
            d = line1.vertices[1]

            c1 = Math.abs(c.getX() - a.getX())

            ax = a.getX()
            ay = a.getY()
            cx = c.getX()
            cy = c.getY()
            
            frac = c1 / Math.abs(c.getY() - a.getY())
            angle = (Math.atan(frac))%(2*Math.PI)

            x = Math.pow(a.attrs.x - c.attrs.x, 2)
            y = Math.pow(a.attrs.y - c.attrs.y, 2)
            scale = ((Math.sqrt(x+y))/5)

            d.start.x  = (a.getX()+scale)
            d.start.y  = (a.getY()+scale)
            b.start.x  = (a.getX()-scale)
            b.start.y  = (a.getY()+scale)

            ninety = 90 * (Math.PI/180)

            if c.getY() < a.getY()
              if c.getX() < a.getX()
                angle = ninety + (ninety-angle)
              else
                angle = (ninety*2) + angle
            else if c.getX() > a.getX()
                angle = (ninety*3)  + (ninety- angle)


            x = (b.start.x - a.getX())
            y = (b.start.y - a.getY())
            b.setX( ( x * Math.cos(angle)) - (y * Math.sin(angle)) + a.getX())
            b.setY( ( x * Math.sin(angle)) + (y * Math.cos(angle)) + a.getY())

            x = (d.start.x - a.getX())
            y = (d.start.y - a.getY())
            d.setX( ( x * Math.cos(angle)) - (y * Math.sin(angle)) + a.getX())
            d.setY( ( x * Math.sin(angle)) + (y * Math.cos(angle)) + a.getY())
            


  drawJoin : () => 
    anchors = @layer.get(".anchor") 

    for i in [0..anchors.length-1]
      @defaultDraw(i)

    for i in [0..@shapes.length-1]
      shape  = @shapes[i]
      break if shape.attrs.id.indexOf("circle") != -1

      if shape? and not shape.isDragging()
        newPoints = []
        for vertex in shape.vertices
          newPoints.push vertex.attrs.x - shape.was.x, vertex.attrs.y - shape.was.y

        shape.setPoints(newPoints)

      if shape? and shape.isDragging()
        for anchor in @layer.get(".anchor")
          anchor.setX(anchor.getX() + (shape.getX() - shape.was.x));
          anchor.setY(anchor.getY() + (shape.getY() - shape.was.y));

        @layer.draw()

      shape.was.x = shape.getX();
      shape.was.y = shape.getY();


    # Circle
    circle = @layer.get('#circle'+@id)[0]
    if circle? and not circle.isDragging()
      newPoints = []

      x = Math.pow(circle.vertices[0].attrs.x - circle.vertices[1].attrs.x, 2)
      y = Math.pow(circle.vertices[0].attrs.y - circle.vertices[1].attrs.y, 2)
      radius = Math.sqrt(x+y)

      newPoints.push circle.vertices[0].attrs.x , circle.vertices[0].attrs.y
      newPoints.push Math.abs(newPoints[1]-circle.vertices[1].attrs.x)


      circle.setX(newPoints[0])
      circle.setY(newPoints[1])
      circle.setRadius(radius)

    if circle? and circle.isDragging()
      circle.vertices[0].setX(circle.vertices[0].getX() + (circle.getX() - circle.was.x))
      circle.vertices[1].setX(circle.vertices[1].getX() + (circle.getX() - circle.was.x))
      circle.vertices[0].setY(circle.vertices[0].getY() + (circle.getY() - circle.was.y))
      circle.vertices[1].setY(circle.vertices[1].getY() + (circle.getY() - circle.was.y))

    if circle?
      circle.was.x = circle.getX();
      circle.was.y = circle.getY();

    for anchor in @layer.get(".anchor")
      anchor.was.x = anchor.getX()
      anchor.was.y = anchor.getY()

    @layer.draw()

  select: =>
    @selected = true

    for shape in @shapes
      shape.show()   
      for vertex in shape.vertices
        vertex.show()   
 
      shape.transitionTo({
        duration: 0.5,
        strokeWidth: 3,
        easing: 'linear'
      });

      shape.setFill("rgba(0,0,0,0)")
      shape.setStroke("rgba(255,255,255,0.5)")

    @layer.draw()
    

  deselect: =>
    console.log 'deselect'
    @selected = false
    width = 0
    
    for shape in @shapes

      if shape.attrs.id.indexOf('line') >= 0 then width = 5

      shape.transitionTo({
        duration: 1,
        strokeWidth: width,
        easing: 'linear'
      });

      shape.setFill("rgba(0,0,0,0.3)")
      shape.setStroke("rgba(0,0,0,0.3)")


      shape.on 'mouseDown', (e) =>
        console.log 'down'
  
    for anchor in @layer.get(".anchor")
      anchor.hide()
   
  addJoin: (join) =>
    line1 = @layer.get('#line'+join[0][0]+'-'+@id)[0]
    join1 = join[0][1]
    line2 = @layer.get('#line'+join[1][0]+'-'+@id)[0]
    join2 = join[1][1]

    # Assign Default
    if join[3]? then join.angle=join[3] else join.angle = 90 
    angle = join.angle * (Math.PI/180)  # Convert to Radians

    
    # Get Target
    if join1 is 'a'
      join = line1.vertices[0]
      oldVert = line1.vertices[1]
    else
      join = line1.vertices[1]
      oldVert = line1.vertices[0] 
    
    if join2 is 'a'
      id = line2.vertices[0].attrs.id
      line2.vertices[0] = join
      newVert = line2.vertices[1]
    else
      id = line2.vertices[1].attrs.id
      line2.vertices[1] = join
      newVert = line2.vertices[0]

    # Apply rotation
    newVert.attrs.x = ((oldVert.attrs.x - join.attrs.x) * Math.cos(angle) ) - ((oldVert.attrs.y - join.attrs.y) * Math.sin(angle)) + join.attrs.x
    newVert.attrs.y = ((oldVert.attrs.x- join.attrs.x) * Math.sin(angle)) + ((oldVert.attrs.y - join.attrs.y) * Math.cos(angle)) + join.attrs.y

    anchor = @layer.get('#'+id)
    @layer.remove(anchor[0])

    @layer.draw()

  addintersect: (int) =>
    line1 = @layer.get('#line'+int[0][0])[0]
    line2 = @layer.get('#line'+int[1][0])[0]

  close: =>
    if @closed
      newPoints = []
      vertices = []

      for i in [1..@noLines-1]
        line = @layer.get('#line'+i+'-'+@id)[0]
        newPoints.push line.getPoints()[0].x
        newPoints.push line.getPoints()[0].y
        newPoints.push line.getPoints()[1].x
        newPoints.push line.getPoints()[1].y
        vertices.push line.vertices[0]
        vertices.push line.vertices[1]


      poly = new Kinetic.Polygon({
        points: newPoints,
        fill: "rgba(255,255,255,0)",
        stroke: "#eee",
        strokeWidth: 3,
        draggable: true,
        id : 'poly'+ @id
      })


      poly.was       = { x: 0, y: 0 }

      for i in [1..@noLines]
        line = @layer.get('#line'+i+'-'+@id)[0]
        @layer.remove(line)

      console.log @layer

      poly.vertices = vertices
      
      delete @lines
      @shapes = []
      @shapes.push poly
      console.log 'closed'
      @layer.add poly
      poly.moveToBottom()


  test: =>
    console.log 'test'

  
    
module.exports = Marker