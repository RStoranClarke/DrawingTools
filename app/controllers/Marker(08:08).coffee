Spine = require('spine')

class Marker extends Spine.Controller
  className: "Marker"

  noLines    : null
  layer       : null
  joins       : null
  visibility  : null
  stage       : null
  draw        : null
  complete    : false
  annotation  : null
  anchorCount : 0
  userDef     : null
  visibility  : null
  shape       : null


  elements:=>
    '#selectionArea' : 'selectionArea'

  #events:
    'click #selectionArea' : 'test'

  constructor: ->
    super
    @clickCount = 0
    @draw = true
    @render()

    @colours = ['bl','red','yellow','blue','green','purple']
    
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

    
    @layer = new Kinetic.Layer({
      drawFunc : @drawJoin
    })
    console.log @noLines
    @newPoly()
    @movementAxis = @addLine @noLines+1
    @movementAxis.setDashArray([10, 5])
    @layer.add @movementAxis
    @movementAxis.hide()
    
    
    @delay =>
      @buildPoly( "poly");
      @addJoin(join) for join in @joins
      @layer.draw()
    ,200
 
  getLayer:=>
    @layer

  isComplete:=>
    @complete

  render:=>
    @html require('views/classifier')

  test:=>
    console.log "test"


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
      visible: false
    });

    @anchorCount++

    anchor.bound = bound

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
    console.log "Adding line", i
    line = new Kinetic.Line({
      points : [100,100,200,100],
      #stroke: '#555',
      stroke: @colours[i],
      strokeWidth: 3,
      id : "line"+i,
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

  
  mouseMoves: 0
  onMouseDown: (e) =>
    return if @complete
    
    @currPos = {x:e.pageX - selectionArea.offsetLeft, y:e.pageY - selectionArea.offsetTop}

    @currAnchor = @layer.get("#"+@userDef[@pointsPlaced])[0]
    
    @currAnchor.setX(@currPos.x);
    @currAnchor.setY(@currPos.y);

    @movementAxis.vertices.a.setX(@currPos.x)
    @movementAxis.vertices.a.setY(@currPos.y)

    @pointsPlaced++

    for i in [0..@noLines-1]
      if @visibility[i] <= @pointsPlaced
        line = @layer.get('#line'+(i+1))[0]
        line.show()     
        line.vertices.a.show()
        line.vertices.b.show()

    @mouseIsDown = true

    @layer.draw()

  onMouseMove: (e) =>
    return unless @mouseIsDown
    return if @complete
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
    @mouseIsDown = false

    @disabled = true
    @complete = true
    console.log @noLines+1
    console.log @layer
    axis = @layer.get('#line'+(@noLines+1))[0]
    console.log axis
    @layer.remove(axis)
    @layer.remove(axis.vertices.a)
    @layer.remove(axis.vertices.b)
    @layer.draw()

  newPoly : =>
    shape = new Kinetic.Group({
      draggable: true
    })

    for i in [1..@noLines]
      line =  @addLine(i) 

      #shape.add line
      @layer.add line
      line.moveToBottom()

    shape.on 'mouseover', (e) =>
      console.log("hover")


    #@layer.add shape

  buildPoly :  (name) =>

    poly = new Kinetic.Polygon({
      points: [0,0,100,0,200,100],
      stroke: "black",
      strokeWidth: 4,
      name : name,
      draggable: true,
      visible: false
    });

    points = []
    poly.vertices = []
    #for i in [0..@noLines-1]
     #poly.vertices.push @buildAnchor(100*(i%(@noLines/2)), i*20+20, "anchor")


    poly.calculatecentre = =>
      sumX = sumY = 0
      for i in [0..@noLines-1]
        sumX += @poly.vertices[i].attrs.x
        sumY += @poly.vertices[i].attrs.y

      @poly.centre.x =  sumX / 3;
      @poly.centre.y =  sumY / 3;
    

    poly.was    = { x : 0, y : 0 };
    poly.centre = { x : 0, y : 0 };

    @poly = poly
    #@layer.add poly

  drawPoly : () =>
    if not @poly.isDragging()   
      newPoints = []
      linePoints = []
      for i in [0..@poly.vertices.length]
        if @poly.vertices[i] 
          if i is 0 and not @draw
            newPoints.push @poly.vertices.b.attrs.x, @poly.vertices[i].attrs.y - @poly.was.y
          else
            newPoints.push @poly.vertices[i].attrs.x - @poly.was.x, @poly.vertices[i].attrs.y - @poly.was.y
      @poly.setPoints(newPoints)
      anchors = @layer.get(".anchor")
      if anchors[0]
       @line.setX(anchors[0].getX());
       @line.setY(anchors[0].getY());
    else
      anchors = @layer.get(".anchor")
      for i in [0..@noLines-1]
        anchors[i].setX(anchors[i].getX() + (@poly.getX() - @poly.was.x));
        anchors[i].setY(anchors[i].getY() + (@poly.getY() - @poly.was.y));
        @line.setX(anchors[0].getX());
        @line.setY(anchors[0].getY());
      #@line.setPoints([@line.getPoints()[0], @line.getPoints()[1], anchors[0].getX() ,anchors[0].getY()]);
      @poly.was.x = @poly.getX();
      @poly.was.y = @poly.getY();

    if @poly.vertices.a and @poly.vertices.a.isDragging() 
      # Ensure left of vertex 2
      if @poly.vertices.a.attrs.x > @poly.vertices.b.attrs.x
        @poly.vertices.a.attrs.x =  @poly.vertices.b.attrs.x
        @draw = false
 
      @poly.calculatecentre.apply(@poly);
    else 
      @draw = true
      @layer.draw()

  drawJoin : () => 
    for i in [1..@noLines]
      line = @layer.get('#line'+i)[0]
      return if not line?
      newPoints = []
      newPoints.push line.vertices.a.attrs.x - line.was.x, line.vertices.a.attrs.y - line.was.y
      newPoints.push line.vertices.b.attrs.x - line.was.x, line.vertices.b.attrs.y - line.was.y
      line.setPoints(newPoints)
      
      anchors = @layer.get(".anchor")     
      for i in [0..@noLines-1]
        if anchors[i].isMoving
          for j in [0..@noLines-1]
            if (j isnt i) and not anchors[j].placed
              anchors[j].setX(anchors[j].getX() + (anchors[i].getX() - anchors[i].was.x));
              anchors[j].setY(anchors[j].getY() + (anchors[i].getY() - anchors[i].was.y));
      
      for i in [0..@noLines-1]
        anchors[i].was.x = anchors[i].getX()
        anchors[i].was.y = anchors[i].getY()
      line.was.x = line.getX();
      line.was.y = line.getY();
      

    @layer.draw()
  
   
  addJoin: (join, angle) =>
    line1 = @layer.get('#line'+join[0][0])[0]
    join1 = join[0][1]
    line2 = @layer.get('#line'+join[1][0])[0]
    join2 = join[1][1]

    # Assign Default
    if not angle? then join.angle = 90
    angle = 90 * (Math.PI/180)  # Convert to Radians

    
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
    
    newX = ((oldVert.attrs.x - join.attrs.x) * Math.cos(angle) ) - ((oldVert.attrs.y - join.attrs.y) * Math.sin(angle))
    newX += join.attrs.x

    newY = ((oldVert.attrs.x- join.attrs.x) * Math.sin(angle)) + ((oldVert.attrs.y - join.attrs.y) * Math.cos(angle))
    newY += join.attrs.y

    console.log 'To:', newX, newY

    newVert.attrs.x = newX
    newVert.attrs.y = newY

    anchor = @layer.get('#'+id)
    @layer.remove(anchor[0])
    @layer.draw()

  addintersect: (int) =>
    line1 = @layer.get('#line'+int[0][0])[0]
    line2 = @layer.get('#line'+int[1][0])[0]

  # x' = 



  setVisibiility: =>

  
    
module.exports = Marker