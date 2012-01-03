# jQuery Plugin
$.fn.spin = (opts) ->
  opts = {} if opts is undefined
  presets =
    "small":    { lines: 8,  length: 2, width: 2, radius: 3 }
    "standard": { lines: 8,  length: 0, width: 3, radius: 5 }
    "large":    { lines: 10, length: 0, width: 4, radius: 8 }

  this.each ->
    $this = $(this)
    data = $this.data()

    if data.spinner
      data.spinner.stop()
      delete data.spinner

    if opts isnt 'stop'
      opts.preset = 'standard' unless opts.preset of presets
      $.extend opts, presets[opts.preset]

      data.spinner = new Spinner($.extend({color: $this.css('color')}, opts)).spin(this)
      $this.css('visibility', 'hidden') if opts.hide
    else
      $this.css('visibility', 'visible') if $this.not(':visible')


# Spinner-Script
((window, document, undefined_) ->

  animations       = {}
  prefixes         = [ "webkit", "Moz", "ms", "O" ]
  useCssAnimations = undefined


  # Utility function to create elements. If no tag name is given,
  # a DIV is created. Optionally properties can be passed.
  createElement = (tag, property) ->
    element		 = document.createElement(tag or "div")
    element[n] = property[n] for n of property

    return element


  # Inserts child1 before child2. If child2 is not specified,
  # child1 is appended. If child2 has no parentNode, child2 is
  # appended first.
  insert = (parent, child1, child2) ->
    insert parent, child2 if child2 and not child2.parentNode
    parent.insertBefore child1, child2 or null

    return parent


	# Creates a stylesheet in the <head> to dynamically insert the CSS3 animations
  sheet = (->
    el = createElement("style", {type: 'text/css'})
    insert document.getElementsByTagName("head")[0], el
    el.sheet or el.styleSheet
  )()


  # Creates an opacity keyframe animation rule and returns its name.
  # Since most mobile Webkits have timing issues with animation-delay,
  # we create separate rules for each line/segment.
  addAnimation = (alpha, trail, i, lines) ->
    name   = [ "opacity", trail, ~~(alpha * 100), i, lines ].join("-")
    start  = 0.01 + i / lines * 100
    z      = Math.max(1 - (1 - alpha) / trail * (100 - start), alpha)
    prefix = useCssAnimations.substring(0, useCssAnimations.indexOf("Animation")).toLowerCase()
    pre    = prefix and "-" + prefix + "-" or ""

    unless animations[name]
      sheet.insertRule "@" + pre + "keyframes " + name + "{" + "0%{opacity:" + z + "}" + start + "%{opacity:" + alpha + "}" + (start + 0.01) + "%{opacity:1}" + (start + trail) % 100 + "%{opacity:" + alpha + "}" + "100%{opacity:" + z + "}" + "}", 0
      animations[name] = 1

    return name


  # Tries various vendor prefixes and returns the first supported property.
  vendor = (el, prop) ->
    style = el.style

    return prop if style[prop] isnt undefined

    prop = prop.charAt(0).toUpperCase() + prop.slice(1)

    i = 0
    while i < prefixes.length
      prefixedProp = prefixes[i] + prop
      return prefixedProp if style[prefixedProp] isnt undefined
      i++
    

  # Returns the absolute page-offset of the given element.
  pos = (el) ->
    o =
      x: el.offsetLeft
      y: el.offsetTop

    while (el = el.offsetParent)
      o.x += el.offsetLeft
      o.y += el.offsetTop

    return o



  # Constructor
  class Spinner
    constructor: (opts) ->
      @defaults =
        color:       "#000"
        fps:         20
        length:      7
        lines:       12
        offsetX:     0
        offsetY:     0
        opacity:     1 / 4
        radius:      10
        speed:       1.5
        trail:       80
        transform3d: false # can cause a strobe-like effect in webkit due to a webkit-bug
        width:       5

      @opts = $.extend(@defaults, opts or {})
      return Spinner unless @spin


    spin: (target) ->
      @stop()
      self = this
      el = self.el = $('<div>').css('position', 'relative')[0]

      if target
        $(target).after(el) # insert target into DOM
        tp = pos(target) # target position
        ep = pos(el)     # element position
        $(el).css left: (target.offsetWidth >> 1 ) - ep.x + tp.x + @opts.offsetX + "px", top:  (target.offsetHeight >> 1) - ep.y + tp.y + @opts.offsetY + "px"

      el.setAttribute "aria-role", "progressbar"
      @lines el, @opts

      unless useCssAnimations
        o     = @opts
        i     = 0
        fps   = o.fps
        f     = fps / o.speed
        ostep = (1 - o.opacity) / (f * o.trail / 100)
        astep = f / o.lines
        (anim = ->
          i++
          s = o.lines

          while s
            alpha = Math.max(1 - (i + s * astep) % f * ostep, o.opacity)
            self.opacity el, o.lines - s, alpha, o
            s--
          self.timeout = self.el and setTimeout(anim, ~~(1000 / fps))
        )()
      self

    stop: ->
      el = @el
      if el
        clearTimeout @timeout
        el.parentNode.removeChild el  if el.parentNode
        @el = `undefined`
      this

    lines: (el, o) ->
      fill = (color, shadow) ->
        $('<div>').css({
          position:         "absolute"
          width:            (o.length + o.width) + "px"
          height:           o.width + "px"
          background:       color
          boxShadow:        shadow
          transformOrigin:  "left"
          transform:        "rotate(" + ~~(360 / o.lines * i) + "deg) translate(" + o.radius + "px" + ",0)"
          borderRadius:     (o.width >> 1) + "px"
        })[0]

      i = 0
      while i < o.lines
        seg = $('<div>').css({
          position:   "absolute"
          top:        1 + ~(o.width / 2) + "px"
          transform:  if @opts.transform3d then "translate3d(0,0,0)" else ''
          opacity:    o.opacity
          animation:  useCssAnimations and addAnimation(o.opacity, o.trail, i, o.lines) + " " + 1 / o.speed + "s linear infinite"
        })[0]
        
        insert seg, $(fill("#000", "0 0 4px " + "#000")).css('top', 2 + 'px') if o.shadow
        insert el, insert(seg, fill(o.color, "0 0 1px rgba(0,0,0,.1)"))
        i++

      return el


    opacity: (el, i, val) ->
      el.childNodes[i].style.opacity = val  if i < el.childNodes.length

 
  # VML rendering for IE
  # (->
  #   s = css(createElement("group"), behavior: "url(#default#VML)")
  #   if not vendor(s, "transform") and s.adj
  #     i = 4
  #     while i--
  #       sheet.addRule [ "group", "roundrect", "fill", "stroke" ][i], "behavior:url(#default#VML)"

  #     proto.lines = (el, o) ->
  #       grp = ->
  #         css createElement("group",
  #           coordsize: s + " " + s
  #           coordorigin: -r + " " + -r
  #         ),
  #           width: s
  #           height: s
  #       seg = (i, dx, filter) ->
  #         insert g, insert(css(grp(),
  #           rotation: 360 / o.lines * i + "deg"
  #           left:     ~~dx

  #         ), insert(css(createEl("roundrect",
  #           arcsize:  1

  #         ),
  #           width:  r
  #           height: o.width
  #           left:   o.radius
  #           top:    -o.width >> 1
  #           filter: filter

  #         ), createElement("fill",
  #           color:   o.color
  #           opacity: o.opacity

  #         ), createElement("stroke",
  #           opacity: 0
  #         )))

  #       r = o.length + o.width
  #       s = 2 * r
  #       g = grp()
  #       margin = ~(o.length + o.radius + o.width) + "px"
  #       i = undefined
  #       if o.shadow
  #         i = 1
  #         while i <= o.lines
  #           seg i, -2, "progid:DXImageTransform.Microsoft.Blur(pixelradius=2,makeshadow=1,shadowopacity=.3)"
  #           i++

  #       seg i for i in o.lines

  #       insert(css(el, margin: margin + " 0 0 " + margin, zoom: 1), g)

  #     proto.opacity = (el, i, val, o) ->
  #       c = el.firstChild
  #       o = o.shadow and o.lines or 0
  #       if c and i + o < c.childNodes.length
  #         c = c.childNodes[i + o]
  #         c = c and c.firstChild
  #         c = c and c.firstChild
  #         c.opacity = val  if c
  #   else
  #     useCssAnimations = vendor(s, "animation")
  # )()
  window.Spinner = Spinner
) window, document