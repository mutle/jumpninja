
  window.engine = null;

  $(document).ready(function() {
    var Engine, Sprite, Vector, sprite, update;
    Engine = (function() {

      function Engine() {
        this.screen = $('#screen').get(0);
        this.ctx = this.screen.getContext("2d");
        this.w = this.screen.width;
        this.h = this.screen.height;
        this.ctx.fillColor = '#fff';
        this.ctx.fillRect(0, 0, this.w, this.h);
        this.running = true;
        this.objects = [];
      }

      Engine.prototype.add = function(object) {
        return this.objects.push(object);
      };

      Engine.prototype.update = function() {
        var delta, o, _i, _j, _len, _len2, _ref, _ref2, _results;
        if (!this.running) return;
        delta = 0;
        _ref = this.objects;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          o = _ref[_i];
          o.update(delta);
        }
        this.ctx.fillRect(0, 0, this.w, this.h);
        _ref2 = this.objects;
        _results = [];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          o = _ref2[_j];
          _results.push(o.draw(this.ctx));
        }
        return _results;
      };

      Engine.prototype.pause = function() {
        return this.running = !this.running;
      };

      return Engine;

    })();
    Vector = (function() {

      function Vector(x, y) {
        this.x = x;
        this.y = y;
      }

      return Vector;

    })();
    Sprite = (function() {

      function Sprite(src) {
        var sprite;
        this.image = new Image;
        this.loaded = false;
        sprite = this;
        this.w = 0;
        this.h = 0;
        this.scale = 2;
        this.position = new Vector(100, 100);
        this.image.onload = function() {
          sprite.loaded = true;
          sprite.w = this.width;
          return sprite.h = this.height;
        };
        this.image.src = src;
      }

      Sprite.prototype.update = function(delta) {};

      Sprite.prototype.draw = function(ctx) {
        if (!this.loaded) return;
        return ctx.drawImage(this.image, 0, 0, this.w, this.h, this.position.x, this.position.y, this.w * this.scale, this.h * this.scale);
      };

      return Sprite;

    })();
    window.engine = new Engine;
    update = function() {
      return window.engine.update();
    };
    window.setInterval(update, 0.0333);
    sprite = new Sprite("sprite.png");
    sprite.update = function(delta) {};
    window.engine.add(sprite);
    return $("#pause").click(function() {
      window.engine.pause();
      if (window.engine.running) {
        return $("#pause").html("Pause");
      } else {
        return $("#pause").html("Resume");
      }
    });
  });
