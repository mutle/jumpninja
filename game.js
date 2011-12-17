
  window.engine = null;

  $(document).ready(function() {
    var Engine, Rect, Sprite, Text, Vector, sprite, sprite2, text, update;
    Engine = (function() {

      function Engine() {
        this.screen = $('#screen').get(0);
        this.ctx = this.screen.getContext("2d");
        this.w = this.screen.width;
        this.h = this.screen.height;
        this.clearColor = '#000';
        this.ctx.fillStyle = this.clearColor;
        this.ctx.fillRect(0, 0, this.w, this.h);
        this.running = true;
        this.objects = [];
        this.lastMillis = this.milliseconds();
      }

      Engine.prototype.add = function(object) {
        return this.objects.push(object);
      };

      Engine.prototype.update = function() {
        var delta, o, _i, _j, _len, _len2, _ref, _ref2;
        if (!this.running) return;
        this.currentMillis = this.milliseconds();
        delta = (this.currentMillis - this.lastMillis) / 1000;
        _ref = this.objects;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          o = _ref[_i];
          o.update(delta);
        }
        this.ctx.fillStyle = this.clearColor;
        this.ctx.fillRect(0, 0, this.w, this.h);
        _ref2 = this.objects;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          o = _ref2[_j];
          o.draw(this);
        }
        return this.lastMillis = this.currentMillis;
      };

      Engine.prototype.pause = function() {
        this.running = !this.running;
        return this.lastMillis = this.milliseconds();
      };

      Engine.prototype.translate = function(offset, rotate, callback) {
        var angle;
        angle = rotate * Math.PI / 180;
        this.ctx.translate(offset.x, offset.y);
        this.ctx.rotate(angle);
        callback.apply(this);
        this.ctx.rotate(-angle);
        return this.ctx.translate(-offset.x, -offset.y);
      };

      Engine.prototype.drawImage = function(image, src, dst, rotate, center) {
        return this.translate(dst.pos, rotate, function() {
          return this.ctx.drawImage(image, src.pos.x, src.pos.y, src.size.x, src.size.y, -center.x, -center.y, dst.size.x, dst.size.y);
        });
      };

      Engine.prototype.measureText = function(text, color, font, align) {
        this.ctx.fillStyle = color;
        this.ctx.font = font;
        this.ctx.textAlign = align;
        this.ctx.textBaseline = 'middle';
        return this.ctx.measureText(text);
      };

      Engine.prototype.drawText = function(text, position, rotate, center, color, font, align) {
        this.ctx.fillStyle = color;
        this.ctx.font = font;
        this.ctx.textAlign = align;
        this.ctx.textBaseline = 'middle';
        return this.translate(position, rotate, function() {
          return this.ctx.fillText(text, -center.x, -center.y);
        });
      };

      Engine.prototype.milliseconds = function() {
        var d;
        d = new Date;
        return d.getTime();
      };

      return Engine;

    })();
    Rect = (function() {

      function Rect(x, y, w, h) {
        this.pos = new Vector(x, y);
        this.size = new Vector(w, h);
      }

      return Rect;

    })();
    Vector = (function() {

      function Vector(x, y, z) {
        this.x = x;
        this.y = y;
        this.z = z;
        if (!this.z) this.z = 0;
      }

      return Vector;

    })();
    Text = (function() {

      function Text(text) {
        var width;
        this.text = text;
        this.position = new Vector(100, 100, 10);
        this.color = '#fff';
        this.font = '20px sans-serif';
        this.align = 'left';
        this.rotate = 45;
        width = engine.measureText(this.text, this.color, this.font, this.align).width;
        this.center = new Vector(width / 2, 0);
      }

      Text.prototype.update = function(delta) {
        return this.rotate++;
      };

      Text.prototype.draw = function(engine) {
        return engine.drawText(this.text, this.position, this.rotate, this.center, this.color, this.font, this.align);
      };

      return Text;

    })();
    Sprite = (function() {

      function Sprite(src, attrs) {
        var sprite;
        this.image = new Image;
        this.loaded = false;
        sprite = this;
        this.w = 0;
        this.h = 0;
        this.scale = 2;
        this.position = new Vector(100, 100);
        this.center = new Vector(0, 0);
        this.image.onload = function() {
          sprite.loaded = true;
          return sprite.setSize(this.width, this.height);
        };
        this.image.src = src;
        if (attrs) {
          this.sprites = new Vector(attrs.sprites[0], attrs.sprites[1]);
        } else {
          this.sprites = [1, 1];
        }
        this.frame = 0;
        this.setFPS(1);
        this.frameTime = 0;
        this.totalFrames = this.sprites.x * this.sprites.y;
        this.rotate = 0;
      }

      Sprite.prototype.setFPS = function(fps) {
        return this.frameRate = 1 / fps;
      };

      Sprite.prototype.setSize = function(w, h) {
        this.w = w / this.sprites.x;
        this.h = h / this.sprites.y;
        this.center.x = this.w / 2 * this.scale;
        this.center.y = this.h / 2 * this.scale;
        return this.updatePos();
      };

      Sprite.prototype.update = function(delta) {
        if (this.updateCallback) this.updateCallback(delta);
        this.nextFrame(delta);
        return this.updatePos();
      };

      Sprite.prototype.updatePos = function() {
        this.src = new Rect(this.frame * this.w, 0, this.w, this.h);
        return this.dst = new Rect(this.position.x, this.position.y, this.w * this.scale, this.h * this.scale);
      };

      Sprite.prototype.draw = function(engine) {
        if (!this.loaded) return;
        return engine.drawImage(this.image, this.src, this.dst, this.rotate, this.center);
      };

      Sprite.prototype.nextFrame = function(delta) {
        this.frameTime += delta;
        if (this.frameTime > this.frameRate) {
          this.frameTime -= this.frameRate;
          this.frame++;
          if (this.frame >= this.totalFrames) return this.frame = 0;
        }
      };

      return Sprite;

    })();
    window.engine = new Engine;
    update = function() {
      return window.engine.update();
    };
    window.setInterval(update, 0.0333);
    sprite = new Sprite("anim.png", {
      sprites: [3, 1]
    });
    sprite.updateCallback = function(delta) {
      return this.rotate += 5;
    };
    sprite2 = new Sprite("anim.png", {
      sprites: [3, 1]
    });
    sprite2.position.y += 200;
    sprite2.setFPS(0.5);
    sprite2.updateCallback = function(delta) {
      return this.rotate += 1;
    };
    window.document.addEventListener('keypress', function(event) {
      var char;
      window.console.log('down');
      char = String.fromCharCode(event.keyCode);
      if (char === 'd') sprite.position.x += 1;
      return true;
    });
    text = new Text("foo");
    window.engine.add(sprite);
    window.engine.add(sprite2);
    window.engine.add(text);
    return $("#pause").click(function() {
      window.engine.pause();
      if (window.engine.running) {
        return $("#pause").html("Pause");
      } else {
        return $("#pause").html("Resume");
      }
    });
  });
