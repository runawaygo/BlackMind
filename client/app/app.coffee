define (require, exports)->
	utility = require('./utl')
	template = utility.template
	nodeTemplateStr = require('./template/node.html')
	
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
				size: 14
				color: '#000'
			offset:
				x: 0
				y: 0
			order: 0
			isRoot: false
		addChild:(node)->
			@children.add(node)
			node.parent = @
			node.set('depth', @get('depth')+1)
			@

	class NodeCollection extends Backbone.Collection
		initialize:->
		model:Node


	class Map extends Backbone.Collection
		initialize:(data)->
			if not data
				@root = new Node({isRoot:true}) 
				@add @root
			
			@on('add', @setRoot)
		model: Node
		setRoot:(node)->
			@root.addChild(node)


	class NodeView extends utility.BaseView
		initialize:->
			@model.children.on('add',@renderChild)
		tagName: 'section'
		template: _.template(nodeTemplateStr)
		className: 'mind-node'
		renderChild:(node)=>
			nodeView = new NodeView({model:node})
			@$el.append(nodeView.render().el)
			@
		renderChildren:=>
			@renderChild(node) for node in @model.children.models
			@
		render:=>
			@$el.html @template(@model.toJSON())
			offset = @model.get('offset')
			@$el.css({
				top:offset.y
				left:offset.x
			})

			@$el.find('div.line').css({
				width:  Math.abs(offset.x)
				height: Math.abs(offset.y)
				left: if offset.x>0 then -offset.x else 0
				top: if offset.y>0 then -offset.y else 0
			})
			.removeClass('up')
			.removeClass('down')
			.addClass(if offset.y>0 then 'down' else 'up')


			@renderChildren()
			@

	
	class MapView extends utility.BaseView
		initialize:->
		tagName: 'div'
		className: 'mind-map'
		# renderNode:(node)=>
		# 	nodeView = new NodeView({model:node})
		# 	@$el.append(nodeView.render().el)
		# 	@
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