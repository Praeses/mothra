(function() {
  $.fn.ImageDrop = function(args) {
    return this.each(function(index, tag) {
      var a, canvas, cost_r, ctx, drawDrop, drawFrame, droping, f_t, img, rt, running_interval, size;
      canvas = $('<canvas class="' + tag.attributes['class'].value + '" />');
      img = new Image;
      img.src = tag.src;
      $(tag).replaceWith(canvas);
      canvas = canvas[0];
      size = tag.width + tag.height;
      canvas.width = tag.width;
      canvas.height = tag.height;
      $(canvas).css('margin-left', 0 - tag.width);
      $(canvas).css('margin-top', 0 - tag.height);
      ctx = canvas.getContext('2d');
      rt = 0;
      a = 1.5;
      cost_r = null;
      running_interval = null;
      droping = false;
      f_t = 0;
      drawFrame = function() {
        ctx.clearRect(-400, -400, 800, 800);
        ctx.rotate(Math.cos(rt) * a);
        rt = rt + .02;
        if (a > 0) {
          a = a - 0.001;
        }
        if (rt >= (Math.PI * 2)) {
          rt = 0;
        }
        ctx.rotate(-Math.cos(rt) * a);
        return ctx.drawImage(img, 0, 0);
      };
      drawDrop = function() {
        var displacement, displacement_last, g, volocity, volocity_last;
        f_t = f_t + 1;
        g = 9.8;
        ctx.clearRect(-400, -400, 800, 800);
        ctx.rotate(Math.cos(rt) * a);
        volocity = f_t * g;
        volocity_last = (f_t - 1) * g;
        displacement = (volocity * volocity) / (2 * g);
        displacement_last = (volocity_last * volocity_last) / (2 * g);
        ctx.translate((displacement - displacement_last) / 30, 0);
        ctx.rotate(-Math.cos(rt + .005) * a);
        return ctx.drawImage(img, 0, 0);
      };
      img.onload = function() {
        return canvas.onclick();
      };
      return canvas.onclick = function() {
        var start_drop, start_swing, stop_drop;
        start_swing = function() {
          ctx.canvas.width = 800;
          ctx.canvas.height = 800;
          ctx.translate(img.width, img.height);
          return setInterval(drawFrame, 10);
        };
        start_drop = function() {
          return setInterval(drawDrop, 10);
        };
        stop_drop = function() {
          clearInterval(running_interval);
          return $('.checkout').remove();
        };
        if (running_interval === null) {
          return running_interval = start_swing();
        } else if (droping === false) {
          droping = true;
          clearInterval(running_interval);
          running_interval = start_drop();
          return setTimeout(stop_drop, 3000);
        }
      };
    });
  };
}).call(this);
