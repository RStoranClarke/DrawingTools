Spine = require('spine')

class Marker extends Spine.Controller
  className: "Marker"

  stage       : null

  noLines     : null
  closed      : null
  joins       : null
  userDef     : null
  visibility  : null

  annotation  : null
  complete    : null
  
  shapes      : null
  draw        : null
  layer       : null

  label       : null

  id          : null  
  disabled    : null


  elements:=>
    '#selectionArea' : 'selectionArea'

  #events:
    'click #selectionArea' : 'test'

  constructor: ->
    super

    @checkValid()
    @draw = true
    @render()
    @shapes = []
    @complete = false
    @disabled = false

    @drawLabel()

    #@colours = ['bl','red','yellow','blue','green','purple']
    
    @bindEvents()
    
    
    @layer = new Kinetic.Layer({
      drawFunc : @drawJoin
    })



    @newPoly()
    
    @delay =>
      @addJoin(join) for join in @joins
      @layer.draw()
    ,200


  checkValid :=>
    errors = []
    if @userDef.length < @noLines.length
      errors.push "Definition Points have not been specified for all lines"
    if @userDef.length > @noLines.length
      errors.push "More Definition Points have been specified than required"
    if @visibility.length < @noLines.length
      errors.push "Visibility has not been specified for all lines"
    if @visibility.length > @noLines.length
      errors.push "Visibility has been specified for more lines than exist"
    for join in @joins
      if parseInt(join[0][0]) > @noLines.length
        errors.push "The line for which the join"+join+" is specified does not exist"
      if parseInt(join[1][0]) > @noLines.length
        errors.push "The line for which the join"+join+" is specified does not exist"

    console.log "ERRORS", errors




  bindEvents :=>
    @stage._onContent 'mousedown', (e)=>
      @onMouseDown (e)
    @stage._onContent 'mousemove', (e)=>
      @onMouseMove (e)
    @stage._onContent 'mouseup', (e)=>
      @onMouseUp (e)
    @stage._onContent 'touchstart', (e)=>
      alert 'hello'
      @onTouchStart (e)
    @stage._onContent 'touchend', (e)=>
      @onTouchEnd(e)
    @stage._onContent 'touchmove', (e)=>
      @onTouchMove (e)
 
  getLayer:=>
    @layer

  getLines:=>
    @noLines

  setLines: (lines) =>
    @noLines = lines

  disable:=>
    @disabled = true

  isComplete:=>
    @complete

  render:=>
    @html require('views/classifier')

  test:=>
    console.log "test", @id

  drawLabel: (text) =>

  onTouchStart: (e) =>
    e.preventDefault()
    @onMouseDown e.originalEvent.touches[0]

  onTouchMove: (e) =>
    @onMouseMove e.originalEvent.touches[0]

  onTouchEnd: (e) =>
    @onMouseUp e.originalEvent.touches[0]

  buildAnchor: (x, y, id, bound) =>
    anchor = new Kinetic.Circle({
      x: x,
      y: y,
      radius: 5,
      stroke: "#666",
      fill: "#ddd",
      strokeWidth: 2,
      draggable: true,
      name : "anchor",
      id : id,
      #visible: false
    });

    anchor.bound = bound

    anchor.start =  { x: x, y: y }

    # Add event animations
    anchor.on "mouseover", (e) =>
      document.body.style.cursor = "move";
      #this.setStrokeWidth(4);
      @layer.draw();

    anchor.on "mouseout", (e) =>
      document.body.style.cursor = "default";
      #this.setStrokeWidth(2);
      @layer.draw();

    anchor.was       = { x: 0, y: 0 }

    @layer.add(anchor);
    anchor.moveToTop()
    anchor

  addLine : (i) =>
    line = new Kinetic.Line({
      points : [100,100,200,100],
      stroke: '#555',
      #stroke: @colours[i],
      strokeWidth: 3,
      id : "line"+i+'-'+@id,
      draggable: 'true',
      visible: false
    });  


    line.on 'dragend', (e) =>
      line.saveImageData()

    line.on "mouseover", (e) =>
      document.body.style.cursor = "pointer";
      @layer.draw();
      console.log "mouse"

    line.destroy = =>
      console.log 'destroying'

    line.vertices  = { a: @buildAnchor(100, i*20+200, i+'a') , b: @buildAnchor(200, i*20+200, i+'b')}
    line.was       = { x: 0, y: 0 }

    line

  newPoly : =>
    shape = new Kinetic.Group({
      draggable: true
    })

    if @noLines is 0
     circle = @newCircle()
     @layer.add circle
     @shapes.push circle
    #else if @closed
     # @shapes.push poly
    else
      for i in [1..@noLines]
        line =  @addLine(i) 

        @shapes.push line
        @layer.add line
        line.moveToBottom()


    @movementAxis = @addLine 0
    @movementAxis.setDashArray([10, 5])
    @layer.add @movementAxis
    @movementAxis.hide()
    @noLines++


    shape.on 'mouseover', (e) =>
      console.log("hover")


    #@layer.add shape

  newCircle : =>
    console.log "Adding circle"
    circle = new Kinetic.Circle({
      x: 150,
      y: 150,
      fill: '#555',
      radius: {
        x: 70,
        y: 70
      }
      stroke: '#555',
      strokeWidth: 3,
      id : "circle"+@id,
      name : "circle"+@id,
      draggable: true,
      #visible: false
    });  

    circle.destroy = =>
      console.log 'destroying'

    circle.vertices  = { a: @buildAnchor(150, 150, '2a') , b: @buildAnchor(150+70, 150, '2b')}
    circle.was       = { x: 0, y: 0 }

    circle
  
  mouseMoves: 0
  onMouseDown: (e) =>
    return if @complete or @disabled
    console.log 'complete?', @complete, @id
    
    @currPos = {x:e.pageX - selectionArea.offsetLeft, y:e.pageY - selectionArea.offsetTop}

    @currAnchor = @layer.get("#"+@userDef[@pointsPlaced])[0]

    @currAnchor.setX(@currPos.x);
    @currAnchor.setY(@currPos.y);

    @movementAxis.vertices.a.setX(@currPos.x)
    @movementAxis.vertices.a.setY(@currPos.y)

    @pointsPlaced++

    for i in [0..@noLines-1]
      if @visibility[i] <= @pointsPlaced
        line = @layer.get('#line'+(i+1)+'-'+@id)[0]
        line.show()     
        line.vertices.a.show()
        line.vertices.b.show()

    @mouseIsDown = true

    @layer.draw()

  onMouseMove: (e) =>
    return unless @mouseIsDown
    return if @complete or @disabled
    return if @pointsPlaced is @userDef.length
    
    
    currX = e.pageX- selectionArea.offsetLeft
    currY = e.pageY- selectionArea.offsetTop
    @movementAxis.setPoints([@currPos.x,@currPos.y,currX,currY])
    @movementAxis.vertices.b.setX(currX)
    @movementAxis.vertices.b.setY(currY)

    @currAnchor = @layer.get("#"+@userDef[@pointsPlaced])[0]
    @currAnchor.isMoving = true
    @currAnchor.setX(currX);
    @currAnchor.setY(currY);

    @movementAxis.show()
    
    @movementAxis.moveToBottom()
    @layer.draw()


  pointsPlaced : 0
  onMouseUp: (e) =>
    if @currAnchor
      @currAnchor.isMoving = false
      @currAnchor.placed = true

    return if @disabled
    return unless @mouseIsDown and @pointsPlaced is @userDef.length
    #return unless @mouseIsDown and @pointsPlaced is @noLines
    
    @complete = true
    @animate()
    @disabled = true
    @mouseIsDown = false
    axis = @layer.get('#line0'+'-'+@id)[0]
    @layer.remove(axis)
    @layer.remove(axis.vertices.a)
    @layer.remove(axis.vertices.b)
    @layer.draw()


  drawJoin : () => 
    anchors = @layer.get(".anchor") 

    for i in [0..anchors.length-1]
      if anchors[i].isMoving
        for j in [0..anchors.length-1]
          if (j isnt i) and (not anchors[j].placed) and (anchors[j].attrs.id[0] isnt '0')
            anchors[j].setX(anchors[j].getX() + (anchors[i].getX() - anchors[i].was.x));
            anchors[j].setY(anchors[j].getY() + (anchors[i].getY() - anchors[i].was.y));

            
            line = @layer.get('#line3-'+@id)[0]
            c1 = Math.abs(anchors[i].getX() - line.vertices.b.getX())
            a = line.vertices.b
            c2 = anchors[i].getY()
            frac = c1 / (c2 - (a.getY()))
            angle = Math.atan(frac)

            line1 = @layer.get('#line4-'+@id)[0]
            line2 = @layer.get('#line2-'+@id)[0] 
            d = line1.vertices.b
            b = line2.vertices.b

            d.start.x  = (a.getX()-50)
            d.start.y  = (a.getY()+50)
            b.start.x  = (a.getX()+50)
            b.start.y  = (a.getY()+50)

            x = (anchors[j].start.x - line.vertices.b.getX())
            y = (anchors[j].start.y - line.vertices.b.getY())

            #anchors[j].setX( ((x * Math.cos(angle)) - (y * Math.sin(angle))) ) + line.vertices.b.getX()
            
            #anchors[j].setY( ((x * Math.sin(angle)) + (y * Math.cos(angle))) ) + line.vertices.b.getY()


    
    for i in [0..@noLines]
      line = @layer.get('#line'+i+'-'+@id)[0]
      if line?
        #console.log ('line')
        newPoints = []
        newPoints.push line.vertices.a.attrs.x - line.was.x, line.vertices.a.attrs.y - line.was.y
        newPoints.push line.vertices.b.attrs.x - line.was.x, line.vertices.b.attrs.y - line.was.y

        line.setPoints(newPoints)
        line.was.x = line.getX();
        line.was.y = line.getY();

    # Circle
    circle = @layer.get('#circle'+@id)[0]
    if circle? and not circle.isDragging()
      newPoints = []

      x = Math.pow(circle.vertices.a.attrs.x - circle.vertices.b.attrs.x, 2)
      y = Math.pow(circle.vertices.a.attrs.y - circle.vertices.b.attrs.y, 2)
      radius = Math.sqrt(x+y)

      newPoints.push circle.vertices.a.attrs.x , circle.vertices.a.attrs.y
      newPoints.push Math.abs(newPoints[1]-circle.vertices.b.attrs.x)


      circle.setX(newPoints[0])
      circle.setY(newPoints[1])
      circle.setRadius(radius)

    if circle? and circle.isDragging()
      circle.vertices.a.setX(circle.vertices.a.getX() + (circle.getX() - circle.was.x))
      circle.vertices.b.setX(circle.vertices.b.getX() + (circle.getX() - circle.was.x))
      circle.vertices.a.setY(circle.vertices.a.getY() + (circle.getY() - circle.was.y))
      circle.vertices.b.setY(circle.vertices.b.getY() + (circle.getY() - circle.was.y))

    if circle?
      circle.was.x = circle.getX();
      circle.was.y = circle.getY();

      
    for i in [0..anchors.length-1]
      anchors[i].was.x = anchors[i].getX()
      anchors[i].was.y = anchors[i].getY()
    
      
    @layer.draw()
  
   
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
      join = line1.vertices.a
      oldVert = line1.vertices.b
    else
      join = line1.vertices.b
      oldVert = line1.vertices.a 
    
    if join2 is 'a'
      id = line2.vertices.a.attrs.id
      line2.vertices.a = join
      newVert = line2.vertices.b
    else
      id = line2.vertices.b.attrs.id
      line2.vertices.b = join
      newVert = line2.vertices.a

    # Apply rotation
    
    newVert.attrs.x = ((oldVert.attrs.x - join.attrs.x) * Math.cos(angle) ) - ((oldVert.attrs.y - join.attrs.y) * Math.sin(angle)) + join.attrs.x

    newVert.attrs.y = ((oldVert.attrs.x- join.attrs.x) * Math.sin(angle)) + ((oldVert.attrs.y - join.attrs.y) * Math.cos(angle)) + join.attrs.y


    anchor = @layer.get('#'+id)
    @layer.remove(anchor[0])

    @layer.draw()

  addintersect: (int) =>
    line1 = @layer.get('#line'+int[0][0])[0]
    line2 = @layer.get('#line'+int[1][0])[0]

  test: =>
    console.log 'test'

  animate : () =>
    console.log 'animating'
    console.log @shapes
    for i in [0..@shapes.length-1]
      @shapes[i].transitionTo({
        alpha: 0.2,
        duration: 0.5,
        strokeWidth: 0,
        easing: 'linear'
      });

      @shapes[i].on 'mouseDown', (e) =>
        console.log 'down'

    ###
    anchors = @layer.get(".anchor")  
    for i in [0..anchors.length-1]
      anchors[i].hide()
    ###

  destroy: =>
    console.log 'f'
    container = @stage.getContainer()
    container.removeEventListener('mousedown')
    $(".kineticjs-content").off('mousedown')
    
    ###
    @stage._onContent 'mousedown', (e)=>
      @onMouseDown (e)
    @stage._onContent 'mousemove', (e)=>
      @onMouseMove (e)
    @stage._onContent 'mouseup', (e)=>
      @onMouseUp (e)
    @stage._onContent 'touchstart', (e)=>
      alert 'hello'
      @onTouchStart (e)
    @stage._onContent 'touchend', (e)=>
      @onTouchEnd(e)
    @stage._onContent 'touchmove', (e)=>
      @onTouchMove (e)
    ###

  
    
module.exports = Marker