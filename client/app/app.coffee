define (require, exports)->
	utility = require('./utl')
	template = utility.template
	nodeTemplateStr = require('./template/node.html')
	EventBus = Backbone.Mediator
	
	class Node extends Backbone.Model
		initialize:(data)->
			if not data.id then data.id = utility.createUUID()
			if data.isRoot then data.depth = 0
			@children = new NodeCollection
		defaults:
			title: 'New Idea'
			content: ''
			font:
				style:''
				size: 20
				color: 'purple'
			offset:
				x: 0
				y: 0
			order: 0
			isRoot: false
			isActive: false
		addChild:(node)->
			@children.add(node)
			node.parent = @
			node.set('depth', @get('depth')+1)
			@
		getAbsoluteOffset:->
			result = {x:0,y:0}
			tempNode = @
			while tempNode
				pOffset = tempNode.get('offset')
				result.x += pOffset.x
				result.y += pOffset.y
				tempNode = tempNode.parent

			result

	class NodeCollection extends Backbone.Collection
		initialize:->
		model:Node


	class Map extends Backbone.Collection
		initialize:(data)->
			if not data
				@root = new Node({isRoot:true}) 
				@add @root
				@active = @root
				@root.set('isActive', true)
			
			@on('add', @setRoot)
			EventBus.on('node:active', (node)=>@active=node)

		model: Node
		addAt:(absoluteOffset)=>
			pAbsoluteOffset = @active.getAbsoluteOffset()
			@add new Node
					offset:
						x: absoluteOffset.x - pAbsoluteOffset.x
						y: absoluteOffset.y - pAbsoluteOffset.y


		setRoot:(node)->
			@active.addChild(node)


	class NodeView extends utility.BaseView
		tagName: 'section'
		template: _.template(nodeTemplateStr)
		className: 'mind-node'
		events:
			'click .title': 'active'
			'mousedown .title': 'startDrag'

		initialize:->
			@model.children.on('add',@renderChild)
			@model.on('change:isActive', @renderActive)
			@model.on('change:offset', @setPosition)

			$('#main-container').on('mousemove',@moveDrag)
			$('#main-container').on('mouseup',@endDrag)

		active:(e)=>
			e.stopPropagation()
			if @model.get('isActive') then return @

			EventBus.trigger('node:active', @model)
			@model.set('isActive',true)
			@
		startDrag:(e)=>
			point = e.touches?[0] ? e
			@startX = @lastX = point.clientX
			@startY = @lastY = point.clientY
			@dragging = true
			e.stopPropagation()
			@
		moveDrag:(e)=>
			if not @dragging then return
			@$el.addClass('dragging')

			point = e.touches?[0] ? e
			@lastX = point.clientX
			@lastY = point.clientY
			@$el.css('-webkit-transform', 'translate3d(' +(@lastX-@startX)+ 'px,'+(@lastY-@startY)+'px, 0) scale(1.05)')
			e.stopPropagation()
			@
		endDrag:(e)=>
			if not @dragging then return
			@$el.removeClass('dragging')
			@dragging = false
			@$el.css('-webkit-transform', '')

			offset = @model.get('offset')
			@model.set(
				offset:
					x: offset.x + @lastX - @startX
					y: offset.y + @lastY - @startY
			)
			e.stopPropagation()
			@
		renderActive:(node)=>
			if @model.get('isActive')
				@$el.addClass('active')
				EventBus.once('node:active', =>
					@model.set('isActive', false)
				)
			else 
				@$el.removeClass('active')
			@
		renderChild:(node)=>
			nodeView = new NodeView({model:node})
			@$el.append(nodeView.render().el)
			@
		renderChildren:=>
			@renderChild(node) for node in @model.children.models
			@
		setPosition:=>
			@renderContainer().renderLine()
			@
		renderContainer:=>
			offset = @model.get('offset')
			@$el.css({
				top:offset.y
				left:offset.x
			})
			@
		renderTitle:->
			font = @model.get('font')
			@$el.find('div.title').first().css({
				"font-size": font.size
				"color": font.color
			})
			@
		renderLine:->
			offset = @model.get('offset')
			@$el.find('div.line').first().css({
				width:  Math.abs(offset.x)
				height: Math.abs(offset.y)
				left: if offset.x>0 then -offset.x else 0
				top: if offset.y>0 then -offset.y else 0
			})
			.removeClass('up')
			.removeClass('down')
			.addClass(if offset.y*offset.x>0 then 'down' else 'up')
			@
		render:=>
			@$el.html @template(@model.toJSON())
			@renderContainer()
				.renderTitle()
				.renderLine()
				.renderActive()

			@renderChildren()
			@

	
	class MapView extends utility.BaseView
		initialize:->
			@initEvent()
		$container:$('#main-container')
		tagName: 'div'
		className: 'mind-map'
		initEvent:->
			@$container.on('dblclick', (e)=>
				x = e.clientX-@$container.width()/2+50
				y = e.clientY-@$container.height()/2+20
				@model.addAt({x:x,y:y})
			)
			@

		render:=>
			nodeView = new NodeView({model:@model.root})
			@$el.html(nodeView.render().el)
			@

	class AppModel extends Backbone.Model
		initialize:->
			
	class AppView extends utility.BaseView
		el:$('body')
		mainContainer:$('#main-container')
		initialize:->
		renderNode:->
			nodeView = new NodeView({model:new Node()})
			nodeView.render()
			@mainContainer.append(nodeView.el)
			@
		render:=>
			mapView = new MapView({model:new Map})
			mapView.render()
			@mainContainer.append(mapView.el)
			mapView.model.add({isRoot:false, offset:{x:100,y:-100}})
			mapView.model.add({isRoot:false, offset:{x:100,y:200}})
			@
		
	class App extends Backbone.Router
		constructor:->
			super()
			@appModel = new AppModel()
			@appView = new AppView({model:@appModel})

		routes:
			"list/:id":"list"
			"":"default"
			
		default:()->
			@appView.render()
			
		list:(id)->
		start:->
			Backbone.history.start()

	$(->
		new App().start()
	)
  	
	exports