$.fn.ImageDrop = (args) ->
  this.each (index, tag) ->
    canvas = $('<canvas class="' + tag.attributes['class'].value + '" />')
    img = new Image
    img.src = tag.src
    $(tag).replaceWith(canvas)
    canvas = canvas[0]
    size = tag.width + tag.height
    canvas.width = tag.width 
    canvas.height = tag.height
    $(canvas).css('margin-left', 0 - tag.width )
    $(canvas).css('margin-top', 0 - tag.height )
    ctx = canvas.getContext('2d')
    rt = 0
    a = 1.5
    cost_r = null 
    running_interval = null
    droping = false
    f_t = 0

    drawFrame = ->
      ctx.clearRect(-400,-400,800,800)
      ctx.rotate(Math.cos(rt) * a)
      rt = rt + .02
      a = a - 0.001 if a > 0
      rt = 0 if rt >= (Math.PI * 2)
      ctx.rotate(-Math.cos(rt) * a)
      ctx.drawImage(img,0,0)

    drawDrop = ->
      f_t = f_t + 1 #falling time
      g = 9.8 #m/s
      ctx.clearRect(-400,-400,800,800)
      ctx.rotate(Math.cos(rt) * a)
      volocity = f_t * g 
      volocity_last = (f_t - 1) * g 
      displacement = (volocity*volocity)/(2 * g)
      displacement_last = (volocity_last*volocity_last)/(2 * g)
      ctx.translate( (displacement - displacement_last) / 30,0)
      ctx.rotate(-Math.cos(rt + .005 ) * a)
      ctx.drawImage(img,0,0)

    img.onload = ->
      canvas.onclick()

    canvas.onclick = ->
      start_swing = -> 
        ctx.canvas.width = 800
        ctx.canvas.height = 800
        ctx.translate(img.width,img.height)
        setInterval drawFrame, 10 
      start_drop = ->
        setInterval drawDrop, 10 
      stop_drop = ->
        clearInterval running_interval
        $('.checkout').remove()
      if running_interval == null
        running_interval = start_swing() 
      else if droping == false
        droping = true
        clearInterval running_interval
        running_interval = start_drop() 
        setTimeout stop_drop, 3000
