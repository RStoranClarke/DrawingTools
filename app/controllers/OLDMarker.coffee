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

  buildAnchor: (x, y, name, bound) =>
    anchor = new Kinetic.Circle({
      x: x,
      y: y,
      radius: 5,
      stroke: "#666",
      fill: "#ddd",
      strokeWidth: 2,
      draggable: true,
      name : name,
      id : "anchor"+ @anchorCount,
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

    @layer.add(anchor);
    anchor.moveToTop()
    anchor

  addLine : (i) =>
    console.log "Adding line", i
    line = new Kinetic.Line({
      points : [100,100,200,100],
      stroke: '#555',
      strokeWidth: 3,
      id : "line"+i,
      draggable: 'true',
      visible: false,
      dashArray: [10, 5]
    });  

    line.on 'dragend', (e) =>
      line.saveImageData()

    line.on "mouseover", (e) =>
      document.body.style.cursor = "pointer";
      @layer.draw();
      console.log "mouse"

    a = @buildAnchor(100*(i%(@noLines/2)), i*20+20, "anchor")
    b = @buildAnchor(100*(i%(@noLines/2)), i*20, "anchor")

    line.vertices  = [a, b]
    line.was       = { x : 0, y : 0 }

    line

  
  mouseMoves: 0
  onMouseDown: (e) =>
   return if @complete
   @currPos = {x:e.pageX - selectionArea.offsetLeft, y:e.pageY - selectionArea.offsetTop}

   if @mouseIsDown  
    @linesDrawn++
    @movementAxis.vertices[1].setX(@currPos.x)
    @movementAxis.vertices[1].setY(@currPos.y)
    @movementAxis.attrs.dashArray = []

   @movementAxis = null
   @mouseIsDown = true


   @layer.draw()

  onMouseMove: (e) =>
    return unless @mouseIsDown
    return if @complete
    return if @linesDrawn is @noLines

    ###
    currLine = (@userDef[@linesDrawn][0]) 
    if @userDef[@linesDrawn][1] is 'b' then currLine++
    console.log currLine
    ###

    @movementAxis  ||= @layer.get('#line'+(@linesDrawn+1))[0]
    #@movementAxis  ||= @layer.get('#line'+ currLine)[0]
    @movementAxis.show()
    @movementAxis.vertices[0].show()
    @movementAxis.vertices[1].show()
    
    ###
    for i in [0..@noLines-1]
      if @visibility[i] < @linesDrawn+1
        @layer.get('#line'+(i+1))[0].show()
    ###

    @movementAxis.vertices[0].setX(@currPos.x)
    @movementAxis.vertices[0].setY(@currPos.y)
    
    currX = e.pageX- selectionArea.offsetLeft
    currY = e.pageY- selectionArea.offsetTop
    @movementAxis.vertices[1].setX(currX)
    @movementAxis.vertices[1].setY(currY)

    @movementAxis.setPoints([@currPos.x,@currPos.y,currX,currY])   
    @movementAxis.moveToBottom()
    @layer.draw()

    ###

    @movementAxis ||= @layer.get('#line'+@linesDrawn)[0]
    console.log 'move' ,@movementAxis
    @movementAxi ||= @addLine(@noLines + @linesDrawn)
    console.log @movementAxi
    console.log 'Gettting line', @linesDrawn, @movementAxis
    @movementAxis.vertices[0] = @currAnchor

    #@movementAxis.setPoints([@currAnchor.attrs.x,@currAnchor.attrs.y,600,200])    
    

    points = @movementAxis.getPoints()
    points.pop()
    points.push {x:e.pageX- selectionArea.offsetLeft, y:e.pageY- selectionArea.offsetTop}
    @movementAxis.setPoints(points)
    
    #@layer.add @movementAxis
    @movementAxis.vertices.pop()
    @movementAxis.vertices.push @currAnchor
    #
    @layer.draw()
    ###

  linesDrawn : 0
  onMouseUp: (e) =>
    return if @disabled
    #return unless @mouseIsDown and @linesDrawn is @userDef.length
    return unless @mouseIsDown and @linesDrawn is @noLines
    @mouseIsDown = false

    @disabled = true
    @complete = true
    @movementAxis = null
    @layer.draw()

  newPoly : =>
    shape = new Kinetic.Group({
      draggable: true
    })

    for i in [1..@noLines]
      line =  @addLine(i) 
      #shape.add line
      @layer.add line

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
            newPoints.push @poly.vertices[1].attrs.x, @poly.vertices[i].attrs.y - @poly.was.y
          else
            newPoints.push @poly.vertices[i].attrs.x - @poly.was.x, @poly.vertices[i].attrs.y - @poly.was.y
      @poly.setPoints(newPoints)
      anchors = @layer.get(".anchor")
      if anchors[0]
       @line.setX(anchors[0].getX());
       @line.setY(anchors[0].getY());
    else
      anchors = @layer.get(".anchor")
      for i in [0..anchors.length-1]
        anchors[i].setX(anchors[i].getX() + (@poly.getX() - @poly.was.x));
        anchors[i].setY(anchors[i].getY() + (@poly.getY() - @poly.was.y));
        @line.setX(anchors[0].getX());
        @line.setY(anchors[0].getY());
      #@line.setPoints([@line.getPoints()[0], @line.getPoints()[1], anchors[0].getX() ,anchors[0].getY()]);
      @poly.was.x = @poly.getX();
      @poly.was.y = @poly.getY();

    if @poly.vertices[0] and @poly.vertices[0].isDragging() 
      # Ensure left of vertex 2
      if @poly.vertices[0].attrs.x > @poly.vertices[1].attrs.x
        @poly.vertices[0].attrs.x =  @poly.vertices[1].attrs.x
        @draw = false
 
      @poly.calculatecentre.apply(@poly);
    else 
      @draw = true
      @layer.draw()

  drawJoin : () => 
    for i in [1..@linesDrawn]
      line = @layer.get('#line'+i)[0]
      return if not line?
      return if not line.vertices[0] and not line.vertices[1]
      newPoints = []
      for i in [0..line.vertices.length-1]
        newPoints.push line.vertices[i].attrs.x - line.was.x, line.vertices[i].attrs.y - line.was.y
      line.setPoints(newPoints)

    @layer.draw()
  
   
  addJoin: (join) =>
    line1 = @layer.get('#line'+join[0][0])[0]
    join1 = join[0][1]
    line2 = @layer.get('#line'+join[1][0])[0]
    join2 = join[1][1]
    
    # Get Target
    if join1 is 'a'
      join = line1.vertices[0]
    else
      join = line1.vertices[1]
    
    if join2 is 'a'
      id = line2.vertices[0].attrs.id
      line2.vertices[0] = join
    else
      id = line2.vertices[1].attrs.id
      line2.vertices[1] = join 

    anchor = @layer.get('#'+id)
    @layer.remove(anchor[0])
    @layer.draw()

  addintersect: (int) =>
    line1 = @layer.get('#line'+int[0][0])[0]
    line2 = @layer.get('#line'+int[1][0])[0]


  setVisibiility: =>

  
    
module.exports = Marker