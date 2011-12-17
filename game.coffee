window.engine = null

$(document).ready ->
  class Engine
    constructor: ->
      @screen = $('#screen').get 0
      @ctx = @screen.getContext "2d"
      @origw = @w = @screen.width
      @origh = @h = @screen.height
      @clearColor = '#000'
      @ctx.fillStyle = @clearColor
      @ctx.fillRect 0, 0, @w, @h
      @running = true
      @lastMillis = @milliseconds()
      @resolution = 1
      @keyEvents = {}
      @delta = 0
      @layers = []
      window.document.addEventListener 'keydown', (event) ->
        char = String.fromCharCode event.keyCode
        window.engine.updateEvent char, 'down'
        false
      window.document.addEventListener 'keyup', (event) ->
        char = String.fromCharCode event.keyCode
        window.engine.updateEvent char, 'up'
        false
    registerKeyEvent: (key, callback) ->
      @keyEvents[key] = {callback: callback, key: key, state: 'idle'}
    updateEvent: (key, state) ->
      event = @keyEvents[key]
      event.state = state if event
    handleEvent: (event) ->
      if event.callback
        event.callback event.state is 'down'
      if event.state is 'up'
        event.state = 'idle'
    keyDown: (key) ->
      event = @keyEvents[key]
      event and event.state is 'down'
    scale: (factor) ->
      @resolution = factor
      @screen.width = @origw * factor
      @screen.height = @origh * factor
      @ctx = @screen.getContext "2d"
      @ctx.scale factor, factor
    addLayer: (layer) ->
      @layers.push layer
    update: ->
      return unless @running

      for key, event of @keyEvents
        continue if event.state is 'idle'
        @handleEvent event

      @currentMillis = @milliseconds()
      @delta = (@currentMillis - @lastMillis) / 1000
      layer.update @delta for layer in @layers
      @ctx.fillStyle = @clearColor
      @ctx.fillRect 0, 0, @w, @h
      layer.draw this for layer in @layers
        # @delta = (@milliseconds() - @lastMillis) / 1000
      @lastMillis = @currentMillis
      @delta
    pause: ->
      @running = not @running
      @lastMillis = @milliseconds()
    fullscreen: ->
      if document.webkitIsFullScreen
        $('#game').get(0).webkitCancelFullScreen()
      else
        $('#game').get(0).webkitRequestFullScreen()
    translate: (offset, rotate, flipH, flipV, callback) ->
      angle = rotate * Math.PI / 180
      @ctx.translate offset.x, offset.y
      @ctx.rotate angle
      if flipH
        @ctx.scale -1, 1
      callback.apply this
      if flipH
        @ctx.scale -1, 1
      @ctx.rotate -angle
      @ctx.translate -offset.x, -offset.y

    drawImage: (image, src, dst, rotate, center, flipH, flipV) ->
      @translate dst.pos, rotate, flipH, flipV, ->
        # centerX = if flipH then center.x else -center.x
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
      @translate position, rotate, false, false, ->
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
    add: (v) ->
      new Vector @x + v.x, @y + v.y, @z + v.z
    sub: (v) ->
      new Vector @x - v.x, @y - v.y, @z - v.z
    mult: (a) ->
      new Vector @x * a, @y * a, @z * a
    div: (a) ->
      new Vector @x / a, @y / a, @z / a

  class Renderable
    constructor: ->
      @position = new Vector 0, 0, 0
      @rotate = 0
      @center = new Vector 0, 0

  class Layer extends Renderable
    constructor: ->
      super()
      @objects = []
    update: (delta) ->
      @sortedObjects = _.sortBy @objects, (o) -> o.position.z
      o.update delta for o in @sortedObjects
    draw: (engine) ->
      for o in @sortedObjects
        engine.translate @position, @rotate, false, false, ->
          o.draw engine 
    add: (object) ->
      @objects.push object

  class Text extends Renderable
    constructor: (@text) ->
      super
      @color = '#fff'
      @fontName = 'VT323'
      @size = 30
      @setFont @size, @fontName
      @align = 'left'
      width = engine.measureText(@text, @color, @font, @align).width
      @center = new Vector width / 2, 0
    update: (delta) ->
      @updateCallback(delta) if @updateCallback
    draw: (engine) ->
      engine.drawText @text, @position, @rotate, @center, @color, @font, @align
    setFont: (size,font) ->
      @size = size
      if font
        @fontName = font
      @font = @size+'px '+@fontName
    setAlign: (horiz,vert) ->
      if horiz == 'left'
        @align = 'left'
        @center.x = 0
      if vert == 'top'
        @center.y = -@size / 2


  class Sprite extends Renderable
    constructor: (src, attrs) ->
      super
      @image = new Image
      @loaded = false
      sprite = this
      @w = 0
      @h = 0
      @scale = 2
      @image.onload = ->
        sprite.loaded = true
        sprite.setSize @width, @height
      @image.src = src
      if attrs
        @sprites = new Vector attrs.sprites[0], attrs.sprites[1]
      else
        @sprites = new Vector 1, 1
      @frame = 0
      @setFPS 1
      @frameTime = 0
      @totalFrames = @sprites.x * @sprites.y
      @rotate = 0
      @animating = false
      @flipH = false
      @flipV = false

    setFPS: (fps) ->
      @frameRate = 1/fps;

    setSize: (w,h) ->
      @w = w / @sprites.x
      @h = h / @sprites.y
      if not @center?
        @center.x = @w / 2 * @scale
        @center.y = @h / 2 * @scale
      @updatePos()

    update: (delta) ->
      @updateCallback(delta) if @updateCallback?
      @nextFrame(delta)
      @updatePos()

    updatePos: ->
      frameX = @frame % @sprites.x
      frameY = Math.floor @frame / @sprites.x
      @src = new Rect(frameX * @w, frameY * @h, @w, @h)
      @dst = new Rect(@position.x, @position.y, @w * @scale, @h * @scale)

    draw: (engine) ->
      return if not @loaded
      engine.drawImage @image, @src, @dst, @rotate, @center, @flipH, @flipV

    nextFrame: (delta) ->
      return if not @animating
      @frameTime += delta
      if @frameTime > @frameRate
        @frameTime -= @frameRate
        @frame++
        @frame = 0 if @frame >= @totalFrames

  class Character extends Sprite
    constructor: () ->
      super "character.png", sprites: [8,2]
      @frames = {'front': [0], 'left': [1], 'right': [1]}
      @jumpFrames = {'front': [8], 'left': [9], 'right': [9]}
      @direction 'front'
      @jumping = false
      @center = new Vector 64, 102
    jump: (jumping) ->
      @jumping = jumping
    direction: (dir) ->
      @dir = dir
      @flipH = @dir is 'left'
      @frame = @frames[@dir][0]
    updateCallback: (delta) ->
      if @jumping
        @position.y -= 100 * delta
        @frame = @jumpFrames[@dir][0]
      else
        # @position.y += 10 * delta
        @frame = @frames[@dir][0]

  class TilesLayer extends Layer
    constructor: ->
      super()
      @tileSize = 32
      @rows = {}
      @offset = new Vector 0, 13
    addTileRow: (tiles) ->
      y=0
      x = 0
      offset = @offset.mult @tileSize
      row = []
      for tile in tiles
        if tile >= 0
          sprite = @sprite()
          sprite.frame = tile
          sprite.scale = 1
          sprite.position = new Vector offset.x + (x+1) * @tileSize, offset.y + (y+1) * @tileSize
          sprite.center = new Vector 0, 0
          @add sprite
          row.push sprite
        else
          row.push null
        x++
      @rows[@offset.y] = row
      @offset.y--
    sprite: () ->
      sprite = new Sprite "tiles.png", sprites: [8,4]
      sprite


  window.engine = new Engine
  updateRate = 1000/60
  update = ->
    delta = window.engine.update()
    window.setTimeout update, updateRate - (delta * 1000)
  window.setTimeout update, 1

  backgroundLayer = new Layer
  window.engine.addLayer backgroundLayer
  tilesLayer = new TilesLayer
  window.engine.addLayer tilesLayer
  gameLayer = new Layer
  window.engine.addLayer gameLayer
  uiLayer = new Layer
  window.engine.addLayer uiLayer

  character = new Character
  gameLayer.add character

  fps = new Text ""
  fps.frames = 0;
  fps.elapsed = 0;
  fps.setAlign 'left', 'top'
  fps.updateCallback = (delta) ->
    fps.elapsed += delta
    @frames++

    if fps.elapsed > 1
      rate = @frames / fps.elapsed
      fps.elapsed -= 1
      @frames = 0
      @text = rate.toFixed(0)+" FPS"

  fps.position = new Vector 0, 0, 100
  uiLayer.add fps

  # 19 x 14 
  tilesLayer.addTileRow [ 0,  8,  8,  8,  8,  8,  8,  8,  8,  0, -1, -1, -1, -1, -1, -1,  0,  0,  8]
  tilesLayer.addTileRow [-1,  0, -1,  0,  0,  0,  0,  0,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1,  8]
  tilesLayer.addTileRow  [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  0]

  character.position = new Vector 320, 480

  window.engine.registerKeyEvent 'D', (down) ->
    if down
      character.position.x += 100 * window.engine.delta
      character.direction 'right'
    else
      character.direction 'front'
  window.engine.registerKeyEvent 'A', (down) ->
    if down
      character.direction 'left'
      character.position.x -= 100 * window.engine.delta
    else
      character.direction 'front'
  window.engine.registerKeyEvent 'W', (down) ->
    if down
      character.jump true
    else
      character.jump false



  $("#fullscreen").click ->
    window.engine.fullscreen()

  $("#resolution").click ->
    if window.engine.resolution > 1
      $(this).html "Double Size"
      window.engine.scale 1
    else
      $(this).html "Original Size"
      window.engine.scale 2

  $("#pause").click ->
    window.engine.pause()
    if window.engine.running
      $("#pause").html "Pause"
    else
      $("#pause").html "Resume"
