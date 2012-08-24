Spine = require('spine')

class Marker extends Spine.Controller
  className: "Marker"

  stage       : null

  joins       : null
  defPoints   : null
  visibility  : null

  annotation  : null
  complete    : null 

  pointsPlaced : null
  
  shape       : null  # Overall Shape
  layer       : null

  label       : null

  id          : null  
  disabled    : null
  selected    : false


  elements:=>
    '#selectionArea' : 'selectionArea'

  constructor: ->
    super

    @defPoints = []
    @anchors = []
    @pointsPlaced = 0
    @complete = false
    @disabled = false
    @layer    = new Kinetic.Layer() 

    @checkValid()
    @render()
    @bindEvents()
    @build()

    @delay =>
      @addJoin(join) for join in @joins
      @layer.draw()
    ,200

  checkValid :=>

    @noLines = 0

    for set in @deflines
      if set instanceof Array
        for item in set
          @noLines++
          @check(item)
      else
          @noLines++
          @check(set)

    for join in @joins
      if join.length is not 2
        throw new Error("Joins must consist of exactly two points")
      
      limit = 'A'.charCodeAt() + @noLines
      code  = join[0].charCodeAt()
      if code < 'A'.charCodeAt() or code > limit
        throw new Error("Invalid join point")

  check : (item,i) =>
    if not item.visibility?
      throw new Error("The visibiliy for line"+@noLines+"has not been set")
    if not item.type?
      throw new Error("No type has been specified for item"+@noLines)

  render:=>
    @html require('views/classifier')

  bindEvents :=>
    
    #@stage._onContent 'mousedown', (e)=>
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


  buildAnchor: (x, y, id, line, next) =>

    console.log  'creating'+id
    
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

    Text = new Kinetic.Text(
        x: 100,
        y: 100,
        text: id,
        fontSize: 14,
        textFill: "red"
        anchor: anchor
    );
    anchor.label = Text
    #@layer.add Text

    anchor.start =  { x: x, y: y }
    anchor.was   =  { x: 0, y: 0 }

    if line?
      console.log 'creating', line.type
      anchor.type = line.type
      if line.type is 'arc'
        anchor.controlX = line.controlX
        anchor.controlY = line.controlY
        anchor.radius   = line.radius


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

    line.vertices  = {anchor:@buildAnchor(100, i*20+200, i+'a'), next:@buildAnchor(200, i*20+200, i+'b')}
    line.was       = { x: 0, y: 0 }

    line

# NOTES: lines named after SOURCE
  buildShape :  =>

    shape = new Kinetic.Shape(   
      drawFunc: @drawShape,
      id : 'fill'+ @id,    
      stroke: "#fff",
      strokeWidth: 3,
      draggable: true
    )

    shape.vertices  = []
    shape.was       = { x: 0, y: 0 }

    shape.get = (id, position) =>
      pnt = null
      pos = []
      nxt = false

      for vertex,j in shape.vertices
        if vertex instanceof Array
          for point,i in vertex
            point = point.anchor
            if point.attrs.id is id
              pnt = point
              pos.push j,i
        else
          console.log 'Checking', vertex.anchor.attrs.id
          if vertex.anchor.attrs.id is id
            console.log 'FOUND', vertex.anchor
            pnt = vertex
            pos.push j
          console.log 'Checking nexts', vertex.next.attrs.id
          if vertex.next.attrs.id is id
            console.log 'FOUND', vertex.next
            pnt = vertex
            pos.push j
            nxt = true

      console.log 'pnt', pnt

      if position
        return {pos:pos, nxt:nxt}
      else 
        console.log 'RETURNING', pnt
        return pnt


    name = 'A'

    for set in @deflines

      if set instanceof Array
        group = []
        prevNode  = null

        for item,i in set
          node = {anchor:(@buildAnchor(200, i*20+200, name, item)), visibility:item.visibility}
          group.push node
          
          if prevNode? then prevNode.next = item

          if item.type is 'circle'
            group.push  {anchor:(@buildAnchor(200-20, i*20+200, 'centre', item)), visibility:(item.visibility-1)}
            @defPoints.push 'centre'

          if item.def? then @defPoints.push name

          prevNode = node

          name = String.fromCharCode(name.charCodeAt() + 1) # Increment Naming

        shape.vertices.push group
      else 
        next = String.fromCharCode(name.charCodeAt() + 1)
        node = {anchor:@buildAnchor(100, i*20+200, name, set), next:@buildAnchor(200, i*20+200, next, set), visibility:set.visibility}
        shape.vertices.push node
        @defPoints.push name, next

        name = String.fromCharCode(name.charCodeAt() + 2) # Increment Naming

    console.log 'FORMING', shape.vertices
    console.log 'DEF', @defPoints
  
    shape

  build : =>
    # Build shape
    @shape =  @buildShape() 
    @layer.add @shape
    @shape.moveToBottom()

    # Add drawing axis
    # Used for temporary lines between definition points which may not be part of the final shape
    @movementAxis = @buildLine 0
    @movementAxis.setDashArray([10, 5])
    @layer.add @movementAxis

    # Keep reference to all anchors
    @delay =>
      @anchors = @layer.get(".anchor")
    ,1

  # Add a visible anchor to the canvas after the user has defined it
  addPoint : =>
    @currAnchor = @layer.get("#"+@defPoints[@pointsPlaced])[0]
    console.log 'getting', @defPoints[@pointsPlaced]
    return unless @currAnchor? 

    @currAnchor.setX(@currPos.x);
    @currAnchor.setY(@currPos.y);

    @currAnchor.placed   = true
    @currAnchor.isMoving = false

    @movementAxis.vertices.anchor.setX(@currPos.x)
    @movementAxis.vertices.anchor.setY(@currPos.y)

    @currAnchor.show()  

    @pointsPlaced++
  
  mouseMoves: 0
  onMouseDown: (e) =>
    e.stopPropagation()
    return if @complete or @disabled

    @mouseIsDown = true
    @currPos = {x:e.layerX , y:e.layerY }

    @addPoint()
    console.log 'CLICK,DOWN'
    e.preventDefault?()

    @layer.draw()

  onMouseMove: (e) =>
    return unless @mouseIsDown
    return if @complete or @disabled
    return if @pointsPlaced >= @defPoints.length

    currX = e.layerX 
    currY = e.layerY
    @movementAxis.setPoints([@currPos.x,@currPos.y,currX,currY])
    @movementAxis.vertices.next.setX(currX)
    @movementAxis.vertices.next.setY(currY)

    @currAnchor = @layer.get("#"+@defPoints[@pointsPlaced])[0]
    return unless @currAnchor?
    @shape.moved = true
    @currAnchor.isMoving = true
    @currAnchor.setX(currX);
    @currAnchor.setY(currY);

    @movementAxis.show()   
    @movementAxis.moveToBottom()
    @layer.draw()


  pointsPlaced : 0
  onMouseUp: (e) =>

    if @currAnchor
      if @defPoints.length <= 2 and @currAnchor.isMoving
        @currPos = {x:e.layerX , y:e.layerY }
        console.log 'CLICK,UP'
        @addPoint()
      @currAnchor.isMoving = false

    return if @disabled
    return unless @mouseIsDown and @pointsPlaced is @defPoints.length

    @complete = true
    @disabled = true
    @bind()
    @deselect()
    
    @mouseIsDown = false

    axis = @layer.get('#line0'+'-'+@id)[0]
    @layer.remove(axis)
    @layer.remove(axis.vertices.anchor)
    @layer.remove(axis.vertices.next)

    @layer.draw()

  bind: =>
    shape = @shape
    shape.on 'dragstart click', (e)=>
      @select()
    shape.on 'mouseout click', (e)=>
      @onMouseLeave (e)
    shape.on 'mouseover', (e)=>
      @onMouseEnter (e)
    for anchor in @anchors
      anchor.on 'dragstart click', (e)=>
        @select()
      anchor.on 'mouseout click', (e)=>
        @onMouseLeave (e)
      anchor.on 'mouseover', (e)=>
        @onMouseEnter (e)


  defaultDraw : (i) =>

    # Draw groups at 90 degrees
    for vertex in @shape.vertices
      if vertex instanceof Array
        prevNode = null
        for point in vertex
          if prevNode? 
            a = 6
            #@applyRotation(point.anchor, null, 90, prevNode.anchor)
          prevNode = point

    #@applyRotation(@shape.vertices[0][1].anchor, @shape.vertices[0][2].anchor, 90, @shape.vertices[0][0].anchor)

  
  drawShape : () => 
    anchors = @anchors 

    # Start drawing path
    context = @shape.getContext();
    context.beginPath()


    for vertex in @shape.vertices
      
      if vertex instanceof Array
        prevPoint = null
        
        for point in vertex

          endY = point.anchor.attrs.y - @shape.was.y
          endX = point.anchor.attrs.x - @shape.was.x

          # First point
          if prevPoint is null
            #context.moveTo  endX,  endY 
            start = {x:endX, y:endY}

          if point.visibility <= @pointsPlaced and @shape.moved

            if point.anchor.type is 'line'
              context.lineTo  endX,  endY 

            if point.anchor.type is 'arc'
              #context.arc(endX, endY, 10, 0 , 2 * Math.PI, false);
              controlY = prevPoint.getY() + point.anchor.controlY - @shape.was.y
              x = Math.pow(prevPoint.getX() - endX, 2)
              y = Math.pow(prevPoint.getY() - endY, 2)
              dist = Math.sqrt(x+y)
              controlX = prevPoint.getX() + (dist*point.controlX) 
              controlX -= @shape.was.x

              context.quadraticCurveTo(controlX, controlY, endX, endY);
              #anch = @buildAnchor(controlX, controlY, 'blah')
              #anch.setFill('pink')
              #anch.show()
              #context.quadraticCurveTo  point.controlX, point.controlY,endX, endY

            if point.anchor.type is 'circle'
              if prevPoint isnt null
                centre = prevPoint
                x = Math.pow(centre.getX() - endX, 2)
                y = Math.pow(centre.getY() - endY, 2)
                radius = Math.sqrt(x+y)
                context.arc(endX, endY, radius, 0 , 2 * Math.PI, false);

            unless @disabled 
              point.anchor.show()
            prevPoint = point.anchor

        if point.anchor.type isnt 'circle' 
          context.lineTo  start.x,  start.y 
          
      else
        if vertex.visibility <= @pointsPlaced 
          context.moveTo vertex.anchor.attrs.x - @shape.was.x, vertex.anchor.attrs.y - @shape.was.y
          context.lineTo vertex.next.attrs.x - @shape.was.x, vertex.next.attrs.y - @shape.was.y
          unless @disabled 
            vertex.anchor.show()
            vertex.next.show()

    context.closePath()
    @shape.fill context
    @shape.stroke context

    # Default draw 
    for anchor,i in anchors
      if @draw? then @draw(i) else @defaultDraw(0)

    # Show Labels
    for anchor,i in anchors
      anchor.label.setX(anchor.getX())
      anchor.label.setY(anchor.getY())

    # Anchors follow shape on drag
    if @shape? and @shape.isDragging()
      for anchor in anchors
        anchor.setX(anchor.getX() + (@shape.getX() - @shape.was.x));
        anchor.setY(anchor.getY() + (@shape.getY() - @shape.was.y));

    # Update Positions
    @shape.was.x = @shape.getX()
    @shape.was.y = @shape.getY()

    for anchor in anchors
      anchor.was.x = anchor.getX()
      anchor.was.y = anchor.getY()

    @constrain

    @layer.draw()

  select: =>
    @selected = true
    if @onSelect? then @onSelect() else @selectTransition()
    @layer.draw()

  selectTransition: =>

    @shape.transitionTo({
      duration: 0.5,
      strokeWidth: 3,
      easing: 'linear'
    });

    @shape.setFill("rgba(0,0,0,0)")
    @shape.setStroke("rgba(255,255,255,0.5)")

    for anchor in @anchors
      anchor.show()

  deselect: =>
    @selected = false
    if @onDeselect? @onDeselect() else @deselectTransition()
    @layer.draw()
  
  deselectTransition: =>

    @shape.transitionTo({
      duration: 1,
      strokeWidth: 0,
      easing: 'linear'
    });

    @shape.setFill("rgba(0,0,0,0.3)")
    @shape.setStroke("rgba(0,0,0,0.3)")

    for anchor in @anchors
      anchor.hide()

  # Join two points
  addJoin: (join) =>
    point1  = @layer.get("#"+join[0])[0]  
    res     = @shape.get(join[1],true)

    console.log '1', @shape.vertices[1].anchor.attrs.id, @shape.vertices[1].next.attrs.id
    console.log '2', @shape.vertices[2].anchor.attrs.id, @shape.vertices[2].next.attrs.id

    console.log 'JOIN', point1.attrs.id, join[1]
    console.log res.nxt

    del = $.inArray(join[1], @defPoints)
    @defPoints.splice( del, 1 );
    console.log 'NEW', @defPoints


    #console.log 'JOIN', point1.attrs.id, if res.nxt then @shape.vertices[res.pos].next.attrs.id else @shape.vertices[res.pos].anchor.attrs.id

    if res.nxt
      if res.pos.length is 2
        @shape.vertices[res.pos[0]][res.pos[1]].next  = point1
      else
        @shape.vertices[res.pos[0]].next  = point1
    else
      if res.pos.length is 2
        @shape.vertices[res.pos[0]][res.pos[1]].anchor = point1
      else
        @shape.vertices[res.pos].anchor = point1

    console.log '1', @shape.vertices[1].anchor.attrs.id, @shape.vertices[1].next.attrs.id
    console.log '2', @shape.vertices[2].anchor.attrs.id, @shape.vertices[2].next.attrs.id

    #@applyRotation(node.anchor, null, 90, node.next)
    
    #point1 = point2
    @layer.remove(@layer.get("#"+join[1])[0])

    @layer.draw()

  # If point2 is not defined it will rotate by the given angle from it's original position
  applyRotation :(point1, point2, angle, origin) =>

    angle = angle * (Math.PI/180)  # Convert to Radians
    if not point2?
      point2 = {}
      point2.attrs = {x:0, y:0}
      point2.attrs.x = point1.attrs.x
      point2.attrs.y = point1.attrs.y

    # Apply rotation
    point1.attrs.x = ((point2.attrs.x - origin.attrs.x) * Math.cos(angle)) - ((point2.attrs.y - origin.attrs.y) * Math.sin(angle)) + origin.attrs.x
    point1.attrs.y = ((point2.attrs.x - origin.attrs.x) * Math.sin(angle)) + ((point2.attrs.y - origin.attrs.y) * Math.cos(angle)) + origin.attrs.y

  addintersect: (int) =>

  test: =>
    console.log 'test'

  
    
module.exports = Marker