_name = "wall"
_instances = []
_nav = []
_id = 0
_axisTable =
	landscape:
		x: "gamma"
		y: "beta"
		z: "alpha"

	portrait:
		y: "beta"
		x: "gamma"
		z: "alpha"

class Wall extends MaxmertkitHelpers
	
	_name: _name
	_instances: _instances
	_nav: _nav
	
	# =============== Public methods

	constructor: ( @el, @options ) ->
		@$el = $(@el)

		@_id = _id++
		
		_options =
			kind: @$el.data('kind') or 'wall'
			group: @$el.data('group') or 'wall'
			name: @$el.data('name') or 'wall'
			video: @$el.data('video') or no
			videoOpacity: no
			poster: @$el.data('poster') or no
			image: @$el.data('image') or no
			imageBlur: no
			imageOpacity: no
			caption: @$el.data('caption') or no
			
			beforeactive: ->
			onactive: ->
			beforeunactive: ->
			onunactive: ->
		
		@options = @_merge _options, @options

		super @$el, @options

		@_setOptions @options

		@header = @$el.find('.-header, header')
		caption = @$el.find('.-caption, caption')
		if caption.length then @caption = caption
		@scroller = @$el.find('.-scroller')
		@scroll = @_getScrollParent @el

		@activate()

	
	_setOptions: ( options ) ->
		
		for key, value of options
			
			if not @options[key]?
				return console.error "Maxmertkit Wall. You're trying to set unpropriate option."

			switch key
				when 'video'
					@video.remove() if @video?
					if value
						urls = value.split(',')
						

						video = "<video preload autoplay loop muted volume='0'>"
						for url in urls
							video += "<source src='#{url}' type='video/#{_parseUrl(url).ext}'>"
						video += "</video>"

						@video = $( video )
						@$el.append @video

				when 'image'
					@image.remove() if @image?
					if value
						image = "<figure><img src='#{value}'/>"
						if @options.caption then image += "<caption>#{@options.caption}</caption>"
						image += "</figure>"

						@image = $(image)
						@$el.append @image

				when 'group'
					i = 0
					while i < @_nav.length and @_nav[i].data('group') isnt value
						i++

					if not @_nav.length or @_nav[i].data('group') isnt value
						$nav = $("[data-kind='wall-nav'][data-group='#{value}']")
						if $nav.length then @_nav.push $nav

					else
						$nav = @_nav[i]
					
					nav = "<i data-scroll='#{@_id}'>"
					nav += "<span>#{@options.name}</span>" if @options.name?
					nav += "</i>"
					@nav = $(nav)
					@navContainer = $nav
					@navContainer.append @nav

					@nav.on "click.#{@_name}.#{@_id}", =>
						_scrollTo.call @, @$el.offset().top

				else
					@options[key] = value
					if typeof value is 'function'
						@[key] = @options[key]



	destroy: ->
		@$el.off ".#{@_name}"
		$(document).off "scroll.#{@_name}.#{@_id}"
		$(window).off "resize.#{@_name}.#{@_id}"
		super

	# updateImagePosition: ( e ) ->
	# 	# pull proper angle based on orientation
	# 	axis = Lenticular.axisTable[Lenticular.orientation][image.axis];
	# 	angle = e[axis];

	# 	// show the proper frame
	# 	var percent = Lenticular.clamp((angle - image.adjustedMin) / image.tiltRange, 0, 1);
	# 	image.showFrame(Math.floor(percent * (image.frames - 1)));

	activate: ->
		_refreshDevice.call @
		@_orientation = (if window.orientation is 0 then "portrait" else "landscape")

		$(window).on "resize.#{@_name}.#{@_id}", =>
			_refreshHeaderHeight.call @
			_refreshDevice.call @

		window.addEventListener 'deviceorientation', (e) =>
			axis = _axisTable[@_orientation].x
			angle = e[axis]
			percent = (angle - 0) / 40

			if @image?
				@image.height $(window).height()
				@image.find('img').height $(window).height()
				@image.find('img').animate marginLeft: "#{( @image.width() - $(window).width() ) * percent}px"
				# if @image.find('img').length
				@$el.html "#{( @image.width() - $(window).width() ) * percent}px"
		, false

		window.addEventListener 'orientationchange', (e) =>
			@_orientation = (if window.orientation is 0 then "portrait" else "landscape")
		, false

		$(document).on "scroll.#{@_name}.#{@_id}", ( event ) =>
			min = @$el.offset().top - $(window).height()
			max = @$el.offset().top + @$el.height() + $(window).height()
			current = @scroll.scrollTop() + $(window).height()
			
			if current > min
				percent = 1 - current / max
			else
				percent = 0

			if not @deviceMobile
				
				# Check if wall is almost invisible
				# and perform some blur and opacity tricks
				if 1 - percent >= 0.5 and 1 - percent <= 1
					if @video? 
						if @options.videoOpacity then @video.css opacity: (percent + 0.5)
					if @image?
						if @options.imageOpacity then @image.css opacity: (percent + 0.5)
						if @options.imageBlur
							if 1 - percent >= 0.8
								@$el.addClass '_blur_'
							else
								@$el.removeClass '_blur_'

				if 1 > percent > 0
					# Do parallax magic here
					if @video? then @video.css top: Math.round((@scroll.scrollTop() - @$el.offset().top ) * percent)
					if @image? then @image.css top: Math.round( (@scroll.scrollTop() - @$el.offset().top ) * percent)

					if @scroller? then @scroller.css opacity: percent * 2
				
				
			_setNavActive.call @
						
				
		
		if @scroller?
			@scroller.on "click.#{@_name}.#{@_id}", =>
				# if @caption?
					# scrollTo = @caption.offset().top - 10
				# else
				scrollTo = @$el.offset().top + @$el.height() 
				
				_scrollTo.call @, scrollTo


		_setNavActive.call @
		_refreshHeaderHeight.call @
			
		@$el.addClass '_active_'

	deactivate: ->
		if @$el.hasClass '_active_'
			_beforeunactive.call @

	disable: ->
		@$el.toggelleClass '_disabled_'






# =============== Private methods

_clamp = (val, min, max) ->
	if(val > max) then max
	if(val < min) then min
	val

_refreshDevice = ->
	@deviceMobile = @_deviceMobile()

_scrollTo = ( px ) ->
	if @scroll[0].activeElement.nodeName is 'BODY'
		$('body,html').animate {scrollTop: "#{px}px"}, 700
	else
		@scroll.animate {scrollTop: "#{px}px"}, 700

_setNavActive = ->
	if @$el.offset().top + @$el.height() / 2 > @scroll.scrollTop() > @$el.offset().top - @$el.height() / 2
		@navContainer.find('._active_').removeClass '_active_'
		@nav.addClass '_active_'

	

_refreshHeaderHeight = ->
	if not @deviceMobile
		@header.css( height: $(window).height() )
	else
		@header.css( height: 'auto')

_parseUrl = (url) ->
	m = url.match(/(.*)[\/\\]([^\/\\]+)\.(\w+)$/)

	path: m[1],
	file: m[2],
	ext: m[3]


$.fn[_name] = (options) ->
	@each ->
		unless $.data(@, "kit-" + _name)
			$.data @, "kit-" + _name, new Wall(@, options)
		else
			if typeof options is "object"
				$.data(@, "kit-" + _name)._setOptions options


			else
				(if typeof options is "string" and options.charAt(0) isnt "_" then $.data(@, "kit-" + _name)[options] else console.error("Maxmertkit Wall. You passed into the #{_name} something wrong."))
		return

$(window).on 'load', ->
	$('[data-kind="wall"]').each ->
		$wall = $(@)
		$wall.wall($wall.data())