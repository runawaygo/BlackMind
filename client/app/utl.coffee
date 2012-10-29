define (require, exports)->
	exports.template = (elementId)->
		_.template($(elementId).html().trim())
	exports.later = (action, delta)->
		delta ?= 0
		setTimeout(action,delta)
	exports.getRandomBetween = (l,r)->
		r = Math.random() * (r-l) + l
		Math.round(r)
	exports.createUUID = ->
		'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c)->
			r = Math.random() * 16 | 0
			v = if c == 'x' then r else (r & 0x3 | 0x8)
			v.toString(16)
		)

	
	class BaseView extends Backbone.View
		_remove:=>
			@undelegateEvents()
			@$el.remove()
			@
		_wrap:(obj)->
			_.extend({},@options,obj)

	exports.BaseView = BaseView
	exports	