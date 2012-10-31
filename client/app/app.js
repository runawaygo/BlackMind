// Generated by CoffeeScript 1.2.1-pre
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(function(require, exports) {
    var App, AppModel, AppView, EventBus, Map, MapView, Node, NodeCollection, NodeView, nodeTemplateStr, template, utility;
    utility = require('./utl');
    template = utility.template;
    nodeTemplateStr = require('./template/node.html');
    EventBus = Backbone.Mediator;
    Node = (function(_super) {

      __extends(Node, _super);

      Node.name = 'Node';

      function Node() {
        return Node.__super__.constructor.apply(this, arguments);
      }

      Node.prototype.initialize = function(data) {
        if (!data.id) data.id = utility.createUUID();
        if (data.isRoot) data.depth = 0;
        return this.children = new NodeCollection;
      };

      Node.prototype.defaults = {
        title: 'New Idea',
        content: '',
        font: {
          style: '',
          size: 20,
          color: 'purple'
        },
        offset: {
          x: 0,
          y: 0
        },
        order: 0,
        isRoot: false,
        isActive: false
      };

      Node.prototype.addChild = function(node) {
        this.children.add(node);
        node.parent = this;
        node.set('depth', this.get('depth') + 1);
        return this;
      };

      Node.prototype.getAbsoluteOffset = function() {
        var pOffset, result, tempNode;
        result = {
          x: 0,
          y: 0
        };
        tempNode = this;
        while (tempNode) {
          pOffset = tempNode.get('offset');
          result.x += pOffset.x;
          result.y += pOffset.y;
          tempNode = tempNode.parent;
        }
        return result;
      };

      return Node;

    })(Backbone.Model);
    NodeCollection = (function(_super) {

      __extends(NodeCollection, _super);

      NodeCollection.name = 'NodeCollection';

      function NodeCollection() {
        return NodeCollection.__super__.constructor.apply(this, arguments);
      }

      NodeCollection.prototype.initialize = function() {};

      NodeCollection.prototype.model = Node;

      return NodeCollection;

    })(Backbone.Collection);
    Map = (function(_super) {

      __extends(Map, _super);

      Map.name = 'Map';

      function Map() {
        this.addAt = __bind(this.addAt, this);
        return Map.__super__.constructor.apply(this, arguments);
      }

      Map.prototype.initialize = function(data) {
        var _this = this;
        if (!data) {
          this.root = new Node({
            isRoot: true
          });
          this.add(this.root);
          this.active = this.root;
          this.root.set('isActive', true);
        }
        this.on('add', this.setRoot);
        return EventBus.on('node:active', function(node) {
          return _this.active = node;
        });
      };

      Map.prototype.model = Node;

      Map.prototype.addAt = function(absoluteOffset) {
        var pAbsoluteOffset;
        pAbsoluteOffset = this.active.getAbsoluteOffset();
        console.log(absoluteOffset);
        console.log(pAbsoluteOffset);
        return this.add(new Node({
          offset: {
            x: absoluteOffset.x - pAbsoluteOffset.x,
            y: absoluteOffset.y - pAbsoluteOffset.y
          }
        }));
      };

      Map.prototype.setRoot = function(node) {
        return this.active.addChild(node);
      };

      return Map;

    })(Backbone.Collection);
    NodeView = (function(_super) {

      __extends(NodeView, _super);

      NodeView.name = 'NodeView';

      function NodeView() {
        this.render = __bind(this.render, this);

        this.renderChildren = __bind(this.renderChildren, this);

        this.renderChild = __bind(this.renderChild, this);

        this.renderActive = __bind(this.renderActive, this);

        this.active = __bind(this.active, this);
        return NodeView.__super__.constructor.apply(this, arguments);
      }

      NodeView.prototype.tagName = 'section';

      NodeView.prototype.template = _.template(nodeTemplateStr);

      NodeView.prototype.className = 'mind-node';

      NodeView.prototype.initialize = function() {
        this.model.children.on('add', this.renderChild);
        return this.model.on('change:isActive', this.renderActive);
      };

      NodeView.prototype.events = {
        'click .title': "active"
      };

      NodeView.prototype.active = function(e) {
        e.stopPropagation();
        if (this.model.get('isActive')) return this;
        EventBus.trigger('node:active', this.model);
        this.model.set('isActive', true);
        return this;
      };

      NodeView.prototype.renderActive = function(node) {
        var _this = this;
        if (this.model.get('isActive')) {
          this.$el.addClass('active');
          EventBus.once('node:active', function() {
            return _this.model.set('isActive', false);
          });
        } else {
          this.$el.removeClass('active');
        }
        return this;
      };

      NodeView.prototype.renderChild = function(node) {
        var nodeView;
        nodeView = new NodeView({
          model: node
        });
        this.$el.append(nodeView.render().el);
        return this;
      };

      NodeView.prototype.renderChildren = function() {
        var node, _i, _len, _ref;
        _ref = this.model.children.models;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          this.renderChild(node);
        }
        return this;
      };

      NodeView.prototype.renderContainer = function() {
        var offset;
        offset = this.model.get('offset');
        this.$el.css({
          top: offset.y,
          left: offset.x
        });
        return this;
      };

      NodeView.prototype.renderTitle = function() {
        var font;
        font = this.model.get('font');
        this.$el.find('div.title').css({
          "font-size": font.size,
          "color": font.color
        });
        return this;
      };

      NodeView.prototype.renderLine = function() {
        var offset;
        offset = this.model.get('offset');
        this.$el.find('div.line').css({
          width: Math.abs(offset.x),
          height: Math.abs(offset.y),
          left: offset.x > 0 ? -offset.x : 0,
          top: offset.y > 0 ? -offset.y : 0
        }).removeClass('up').removeClass('down').addClass(offset.y * offset.x > 0 ? 'down' : 'up');
        return this;
      };

      NodeView.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        this.renderContainer().renderTitle().renderLine().renderActive();
        this.renderChildren();
        return this;
      };

      return NodeView;

    })(utility.BaseView);
    MapView = (function(_super) {

      __extends(MapView, _super);

      MapView.name = 'MapView';

      function MapView() {
        this.render = __bind(this.render, this);
        return MapView.__super__.constructor.apply(this, arguments);
      }

      MapView.prototype.initialize = function() {
        return this.initEvent();
      };

      MapView.prototype.$container = $('#main-container');

      MapView.prototype.tagName = 'div';

      MapView.prototype.className = 'mind-map';

      MapView.prototype.initEvent = function() {
        var _this = this;
        this.$container.on('dblclick', function(e) {
          var x, y;
          x = e.clientX - _this.$container.width() / 2 + 50;
          y = e.clientY - _this.$container.height() / 2 + 20;
          return _this.model.addAt({
            x: x,
            y: y
          });
        });
        return this;
      };

      MapView.prototype.render = function() {
        var nodeView;
        nodeView = new NodeView({
          model: this.model.root
        });
        this.$el.html(nodeView.render().el);
        return this;
      };

      return MapView;

    })(utility.BaseView);
    AppModel = (function(_super) {

      __extends(AppModel, _super);

      AppModel.name = 'AppModel';

      function AppModel() {
        return AppModel.__super__.constructor.apply(this, arguments);
      }

      AppModel.prototype.initialize = function() {};

      return AppModel;

    })(Backbone.Model);
    AppView = (function(_super) {

      __extends(AppView, _super);

      AppView.name = 'AppView';

      function AppView() {
        this.render = __bind(this.render, this);
        return AppView.__super__.constructor.apply(this, arguments);
      }

      AppView.prototype.el = $('body');

      AppView.prototype.mainContainer = $('#main-container');

      AppView.prototype.initialize = function() {};

      AppView.prototype.renderNode = function() {
        var nodeView;
        nodeView = new NodeView({
          model: new Node()
        });
        nodeView.render();
        this.mainContainer.append(nodeView.el);
        return this;
      };

      AppView.prototype.render = function() {
        var mapView;
        mapView = new MapView({
          model: new Map
        });
        mapView.render();
        this.mainContainer.append(mapView.el);
        mapView.model.add({
          isRoot: false,
          offset: {
            x: 100,
            y: -100
          }
        });
        mapView.model.add({
          isRoot: false,
          offset: {
            x: 100,
            y: 200
          }
        });
        return this;
      };

      return AppView;

    })(utility.BaseView);
    App = (function(_super) {

      __extends(App, _super);

      App.name = 'App';

      function App() {
        App.__super__.constructor.call(this);
        this.appModel = new AppModel();
        this.appView = new AppView({
          model: this.appModel
        });
      }

      App.prototype.routes = {
        "list/:id": "list",
        "": "default"
      };

      App.prototype["default"] = function() {
        return this.appView.render();
      };

      App.prototype.list = function(id) {};

      App.prototype.start = function() {
        return Backbone.history.start();
      };

      return App;

    })(Backbone.Router);
    $(function() {
      return new App().start();
    });
    return exports;
  });

}).call(this);
