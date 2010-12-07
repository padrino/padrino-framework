/* jslint immed:false */
LowPro = {};
LowPro.Version = '0.5';
LowPro.CompatibleWithPrototype = '1.6';

if ( Prototype.Version.indexOf(LowPro.CompatibleWithPrototype) !== 0 && window.console && window.console.warn) {
  console.warn("This version of Low Pro is tested with Prototype " + LowPro.CompatibleWithPrototype + " it may not work as expected with this version (" + Prototype.Version + ")");
}

if (!Element.addMethods) {
  Element.addMethods = function(o) { Object.extend(Element.Methods, o); };
}
  

// Simple utility methods for working with the DOM
DOM = {};

// DOMBuilder for prototype
DOM.Builder = {
	tagFunc : function(tag) {
    return function() {
     var attrs, children;
     if (arguments.length>0) {
       if (arguments[0].constructor == Object) {
         attrs = arguments[0];
         children = Array.prototype.slice.call(arguments, 1);
       } else {
         children = arguments;
       }
       children = $A(children).flatten();
     }
     return DOM.Builder.create(tag, attrs, children);
    };
  },
	create : function(tag, attrs, children) {
		tag = tag.toLowerCase();
		attrs = attrs || {}; 
		children = children || []; 
		
		var el = new Element(tag, attrs);
	  
		for (var i=0; i<children.length; i++) {
			if (typeof children[i] == 'string') {
			  children[i] = document.createTextNode(children[i]);
			}
			el.appendChild(children[i]);
		}
		return $(el);
	}
};

// Automatically create node builders as $tagName.
(function() { 
	var els = ("p|div|span|strong|em|img|table|tr|td|th|thead|tbody|tfoot|pre|code|" + 
				     "h1|h2|h3|h4|h5|h6|ul|ol|li|form|input|textarea|legend|fieldset|" + 
				     "select|option|blockquote|cite|br|hr|dd|dl|dt|address|a|button|abbr|acronym|" +
				     "script|link|style|bdo|ins|del|object|param|col|colgroup|optgroup|caption|" + 
				     "label|dfn|kbd|samp|var").split("|");
	for( var i = 0, l = els.length; i < l; i++ ) {
	  el = els[i];
	  window['$' + el] = DOM.Builder.tagFunc(el);
	}
})();

DOM.Builder.fromHTML = function(html) {
  var root;
  if (!(root = arguments.callee._root)){
    root = arguments.callee._root = document.createElement('div');
  }
  root.innerHTML = html;
  return root.childNodes[0];
};

// Wraps the 1.6 contentloaded event for backwards compatibility
//
// Usage:
//
// Event.onReady(callbackFunction);
Object.extend(Event, {
  onReady : function(f) {
    if (document.body) { 
      f();
    } else {
      document.observe('dom:loaded', f);
    }
  }
});

// Based on event:Selectors by Justin Palmer
// http://encytemedia.com/event-selectors/
//
// Usage:
//
// Event.addBehavior({
//      "selector:event" : function(event) { /* event handler.  this refers to the element. */ },
//      "selector" : function() { /* runs function on dom ready.  this refers to the element. */ }
//      ...
// });
//
// Multiple calls will add to exisiting rules.  Event.addBehavior.reassignAfterAjax and
// Event.addBehavior.autoTrigger can be adjusted to needs.
Event.addBehavior = function(rules) {
  var ab = this.addBehavior;
  Object.extend(ab.rules, rules);
  
  if (!ab.responderApplied) {
    Ajax.Responders.register({
      onComplete : function() { 
        if (Event.addBehavior.reassignAfterAjax) {
          setTimeout(function() { ab.reload(); }, 10);
        }
      }
    });
    ab.responderApplied = true;
  }
  
  if (ab.autoTrigger) {
    this.onReady(ab.load.bind(ab, rules));
  }
  
};

Event.delegate = function(rules) {
  return function(e) {
    for (var selector in rules) {
      if ( selector !== null ) {
        var parts = $A(selector.split(','));
        var match_found = parts.any(function(part) { return e.findElement(part) != null; });
        if ( match_found ){ return rules[selector].apply(this, $A(arguments)); }
      }
    }
  };
};

Object.extend(Event.addBehavior, {
  rules : {},
  cache : [],
  reassignAfterAjax : false,
  autoTrigger : true,
  
  load : function(rules) {
    for (var selector in rules) {
      if ( selector ){
        var observers = [rules[selector]].flatten();
        var sels = selector.split(',');
        sels.each( function(sel) {
          observers.each(function(observer) {
            var parts = sel.split(/:(?=[a-z]+$)/), css = parts[0], event = parts[1];
            $$(css).each(function(element) {
              if (event) {
                var wrappedObserver = Event.addBehavior._wrapObserver(observer);
                $(element).observe(event, wrappedObserver);
                Event.addBehavior.cache.push([element, event, wrappedObserver]);                
              } else {
                if (!element.$$assigned || !element.$$assigned.include(observer)) {
                  if (observer.attach) {
                    observer.attach(element);
                  } else {
                    observer.call($(element));
                  }
                  element.$$assigned = element.$$assigned || [];
                  element.$$assigned.push(observer);
                }
              }
            });
          });
        });
      }
    }
  },
  
  unload : function() {
    this.cache.each(function(c) {
      Event.stopObserving.apply(Event, c);
    });
    this.cache = [];
  },
  
  reload: function() {
    var ab = Event.addBehavior;
    ab.unload(); 
    ab.load(ab.rules);
  },
  
  _wrapObserver: function(observer) {
    return function(event) {
      if (observer.call(this, event) === false) {
        event.stop();
      }
    };
  }
  
});

Event.observe(window, 'unload', Event.addBehavior.unload.bind(Event.addBehavior));

// A silly Prototype style shortcut for the reckless
$$$ = Event.addBehavior.bind(Event);

// Behaviors can be bound to elements to provide an object orientated way of controlling elements
// and their behavior.  Use Behavior.create() to make a new behavior class then use attach() to
// glue it to an element.  Each element then gets it's own instance of the behavior and any
// methods called onxxx are bound to the relevent event.
// 
// Usage:
// 
// var MyBehavior = Behavior.create({
//   onmouseover : function() { this.element.addClassName('bong') } 
// });
//
// Event.addBehavior({ 'a.rollover' : MyBehavior });
// 
// If you need to pass additional values to initialize use:
//
// Event.addBehavior({ 'a.rollover' : MyBehavior(10, { thing : 15 }) })
//
// You can also use the attach() method.  If you specify extra arguments to attach they get passed to initialize.
//
// MyBehavior.attach(el, values, to, init);
//
// Finally, the rawest method is using the new constructor normally:
// var draggable = new Draggable(element, init, vals);
//
// Each behaviour has a collection of all its instances in Behavior.instances
//
var Behavior = {
  create: function() {
    var parent = null, properties = $A(arguments);
    if (Object.isFunction(properties[0])) {
      parent = properties.shift();
    }
      var behavior = function() { 
        var args = null;
        if (!this.initialize) {
          args = $A(arguments);

          return function() {
            var initArgs = [this].concat(args);
            behavior.attach.apply(behavior, initArgs);
          };
        } else {
          args = (arguments.length == 2 && arguments[1] instanceof Array) ? arguments[1] : Array.prototype.slice.call(arguments, 1);
          this.element = $(arguments[0]);
          this.initialize.apply(this, args);
          behavior._bindEvents(this);
          behavior.instances.push(this);
          behavior.instance = this;
        }
      };

    Object.extend(behavior, Class.Methods);
    Object.extend(behavior, Behavior.Methods);
    behavior.superclass = parent;
    behavior.subclasses = [];
    behavior.instances = [];
    behavior.instance = null;

    if (parent) {
      var subclass = function() { };
      subclass.prototype = parent.prototype;
      behavior.prototype = new subclass();
      parent.subclasses.push(behavior);
    }

    for (var i = 0; i < properties.length; i++){
      behavior.addMethods(properties[i]);
    }
    if (!behavior.prototype.initialize){
      behavior.prototype.initialize = Prototype.emptyFunction;
    }
    behavior.prototype.constructor = behavior;

    return behavior;
  },
  Methods : {
    attach : function(element) {
      return new this(element, Array.prototype.slice.call(arguments, 1));
    },
    _bindEvents : function(bound) {
      for (var member in bound) {
        var matches = member.match(/^on(.+)/);
        if (matches && typeof bound[member] == 'function')
          bound.element.observe(matches[1], Event.addBehavior._wrapObserver(bound[member].bindAsEventListener(bound)));
      }
    }
  }
};

Remote = Behavior.create({
  initialize: function(options) {
    if (this.element.nodeName == 'FORM'){ 
      return new Remote.Form(this.element, options);
    } else { 
      return new Remote.Link(this.element, options);
    }
  }
});

Remote.Base = {
  initialize : function(options) {
    this.options = Object.extend({
      evalScripts : true
    }, options || {});
    
    this._bindCallbacks();
  },
  _makeRequest : function(options) {
    if (options.confirm && !confirm(options.confirm)) { return false;  }
    if (options.update) { 
      var updater = new Ajax.Updater(options.update, options.url, options);
    } else {
      var request = new Ajax.Request(options.url, options);
    }
    return false;
  },
  _bindCallbacks: function() {
    $w('onCreate onComplete onException onFailure onInteractive onLoading onLoaded onSuccess').each(function(cb) {
      if (Object.isFunction(this.options[cb])) {
        this.options[cb] = this.options[cb].bind(this);
      }
    }.bind(this));
  }
};

Remote.Link = Behavior.create(Remote.Base, {
  onclick : function() {
    var options = Object.extend({ url : this.element.href, method : 'get' }, this.options);
    return this._makeRequest(options);
  }
});

Remote.Form = Behavior.create(Remote.Base, {
  onclick : function(e) {
    var sourceElement = e.element();
    if (['input', 'button'].include(sourceElement.nodeName.toLowerCase()) && 
        ['submit', 'image'].include(sourceElement.type)) {
      this._submitButton = sourceElement;
    }
  },
  onsubmit : function() {
    var additionalParameters = (this._submitButton) ? { submit: this._submitButton.name } : {};
    var options = Object.extend({
      url : this.element.action,
      method : this.element.method || 'get',
      parameters : this.element.serialize(additionalParameters)
    }, this.options);
    this._submitButton = null;
    return this._makeRequest(options);
  }
});

Observed = Behavior.create({
  initialize : function(callback, options) {
    this.callback = callback.bind(this);
    this.options = options || {};
    this.observer = (this.element.nodeName == 'FORM') ? this._observeForm() : this._observeField();
  },
  stop: function() {
    this.observer.stop();
  },
  _observeForm: function() {
    return (this.options.frequency) ? new Form.Observer(this.element, this.options.frequency, this.callback) :
                                      new Form.EventObserver(this.element, this.callback);
  },
  _observeField: function() {
    return (this.options.frequency) ? new Form.Element.Observer(this.element, this.options.frequency, this.callback) :
                                      new Form.Element.EventObserver(this.element, this.callback);
  }
});

