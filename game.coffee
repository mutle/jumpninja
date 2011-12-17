window.engine = null

$(document).ready ->
  class Engine
    constructor: ->
      @screen = $('#screen').get 0
      @ctx = @screen.getContext "2d"
      @w = @screen.width
      @h = @screen.height
      @ctx.fillColor = '#fff'
      @ctx.fillRect 0, 0, @w, @h
      @running = true
      @objects = []
    add: (object) ->
      @objects.push object
    update: ->
      return if not @running
      delta = 0
      for o in @objects
        o.update delta
      @ctx.fillRect 0, 0, @w, @h
      for o in @objects
        o.draw @ctx
    pause: ->
      @running = not @running

  class Vector
    constructor: (@x, @y) ->

  class Sprite
    constructor: (src) ->
      @image = new Image
      @loaded = false
      sprite = this
      @w = 0
      @h = 0
      @scale = 2
      @position = new Vector 100, 100
      @image.onload = ->
        sprite.loaded = true
        sprite.w = this.width
        sprite.h = this.height
      @image.src = src

    update: (delta) ->

    draw: (ctx) ->
      return if not @loaded
      ctx.drawImage @image, 0, 0, @w, @h, @position.x, @position.y, @w * @scale, @h * @scale

  window.engine = new Engine
  update = ->
    window.engine.update();
  window.setInterval update, 0.0333

  sprite = new Sprite "sprite.png"
  sprite.update = (delta) ->

  window.engine.add sprite

  $("#pause").click ->
    window.engine.pause()
    if window.engine.running
      $("#pause").html "Pause"
    else
      $("#pause").html "Resume"
