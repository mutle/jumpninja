window.engine = null

$(document).ready ->
  class Engine
    constructor: ->
      @screen = $('#screen').get 0
      @ctx = @screen.getContext "2d"
      @w = @screen.width
      @h = @screen.height
      @clearColor = '#000'
      @ctx.fillStyle = @clearColor
      @ctx.fillRect 0, 0, @w, @h
      @running = true
      @objects = []
      @lastMillis = @milliseconds()
    add: (object) ->
      @objects.push object
    update: ->
      return if not @running
      @currentMillis = @milliseconds()
      delta = (@currentMillis - @lastMillis) / 1000
      for o in @objects
        o.update delta
      @ctx.fillStyle = @clearColor
      @ctx.fillRect 0, 0, @w, @h
      for o in @objects
        o.draw this
      @lastMillis = @currentMillis
    pause: ->
      @running = not @running
      @lastMillis = @milliseconds()
    translate: (offset, rotate, callback) ->
      angle = rotate * Math.PI / 180
      @ctx.translate offset.x, offset.y
      @ctx.rotate angle
      callback.apply this
      @ctx.rotate -angle
      @ctx.translate -offset.x, -offset.y

    drawImage: (image, src, dst, rotate, center) ->
      @translate dst.pos, rotate, ->
        @ctx.drawImage image, src.pos.x, src.pos.y, src.size.x, src.size.y, -center.x, -center.y, dst.size.x, dst.size.y
    measureText: (text, color, font, align) ->
      @ctx.fillStyle = color
      @ctx.font = font
      @ctx.textAlign = align
      @ctx.textBaseline = 'middle';
      @ctx.measureText text
    drawText: (text, position, rotate, center, color, font, align) ->
      @ctx.fillStyle = color
      @ctx.font = font
      @ctx.textAlign = align
      @ctx.textBaseline = 'middle';
      @translate position, rotate, ->
        @ctx.fillText text, -center.x, -center.y
    milliseconds: ->
      d = new Date
      d.getTime()

  class Rect
    constructor: (x,y,w,h) ->
      @pos = new Vector(x,y)
      @size = new Vector(w,h)

  class Vector
    constructor: (@x, @y, @z) ->
      if !@z
        @z = 0

  class Text
    constructor: (@text) ->
      @position = new Vector 100, 100, 10
      @color = '#fff'
      @font = '20px sans-serif'
      @align = 'left'
      @rotate = 45
      width = engine.measureText(@text, @color, @font, @align).width
      @center = new Vector width / 2, 0
    update: (delta) ->
      @rotate++
    draw: (engine) ->
      engine.drawText @text, @position, @rotate, @center, @color, @font, @align


  class Sprite
    constructor: (src, attrs) ->
      @image = new Image
      @loaded = false
      sprite = this
      @w = 0
      @h = 0
      @scale = 2
      @position = new Vector 100, 100
      @center = new Vector 0, 0
      @image.onload = ->
        sprite.loaded = true
        sprite.setSize @width, @height
      @image.src = src
      if attrs
        @sprites = new Vector attrs.sprites[0], attrs.sprites[1]
      else
        @sprites = [1,1]
      @frame = 0
      @setFPS 1
      @frameTime = 0
      @totalFrames = @sprites.x * @sprites.y
      @rotate = 0

    setFPS: (fps) ->
      @frameRate = 1/fps;

    setSize: (w,h) ->
      @w = w / @sprites.x
      @h = h / @sprites.y
      @center.x = @w / 2 * @scale
      @center.y = @h / 2 * @scale
      @updatePos()

    update: (delta) ->
      @updateCallback(delta) if @updateCallback
      @nextFrame(delta)
      @updatePos()

    updatePos: ->
      @src = new Rect(@frame * @w, 0, @w, @h)
      @dst = new Rect(@position.x, @position.y, @w * @scale, @h * @scale)

    draw: (engine) ->
      return if not @loaded
      engine.drawImage @image, @src, @dst, @rotate, @center

    nextFrame: (delta) ->
      @frameTime += delta
      if @frameTime > @frameRate
        @frameTime -= @frameRate
        @frame++
        @frame = 0 if @frame >= @totalFrames

  window.engine = new Engine
  update = ->
    window.engine.update();
  window.setInterval update, 0.0333

  sprite = new Sprite "anim.png", sprites:[3,1]
  sprite.updateCallback = (delta) ->
    @rotate += 5

  sprite2 = new Sprite "anim.png", sprites:[3,1]
  sprite2.position.y += 200
  sprite2.setFPS 0.5
  sprite2.updateCallback = (delta) ->
    @rotate += 1

  window.document.addEventListener 'keypress', (event) ->
    window.console.log 'down'
    char = String.fromCharCode event.keyCode
    sprite.position.x += 1 if char == 'd'
    true

  text = new Text "foo"

  window.engine.add sprite
  window.engine.add sprite2
  window.engine.add text

  $("#pause").click ->
    window.engine.pause()
    if window.engine.running
      $("#pause").html "Pause"
    else
      $("#pause").html "Resume"
