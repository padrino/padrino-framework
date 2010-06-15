/*
 * Padrino RightJS UJS Adapter
 * Created for use with Padrino Ruby Web Framework (http://www.padrinorb.com)
**/

// Halt Definition
Event.include({ halt: function() { this.stop(); this.stopped = true; }});

/* Remote Form Support
 * form_for @user, '/user', :remote => true
**/

"form[data-remote=true]".on('submit', function(e) {
  e.halt();
  var element = e.target;
  var message = element.get('data-confirm');
  if (message && !confirm(message)) { return false; }
  JSAdapter.sendRequest(element, { 
    verb: element.get('data-method') || element.get('method') || 'post', 
    url: element.get('action'), 
    params: element.values()
  });
});

/* Confirmation Support
 * link_to 'sign out', '/logout', :confirm => "Log out?"
**/

"a[data-confirm]".on('click', function(e) {
  var message = e.target.get('data-confirm');
  if (!confirm(message)) { e.halt(); }
});

/* 
 * Link Remote Support 
 * link_to 'add item', '/create', :remote => true
**/

"a[data-remote=true]".on('click', function(e) {
  var element = e.target; 
  if (e.stopped) return;
  e.halt();
  JSAdapter.sendRequest(element, { 
    verb: element.get('data-method') || 'get', 
    url: element.get('href')
  });
});

/* 
 * Link Method Support
 * link_to 'delete item', '/destroy', :method => :delete
**/

"a[data-method]:not([data-remote])".on('click', function(e) {
  if (e.stopped) return;
  JSAdapter.sendMethod(e.target);
  e.halt();
});

/* JSAdapter */
var JSAdapter = {
  // Sends an xhr request to the specified url with given verb and params
  // JSAdapter.sendRequest(element, { verb: 'put', url : '...', params: {} });
  sendRequest : function(element, options) {
    var verb = options.verb, url = options.url, params = options.params;
    var event = element.fire("ajax:before");
    if (event.stopped) return false;
    Xhr.load(url, {
      method: verb || 'post',
      params: params || {},
      evalScripts: true,

      onLoading:     function(request) { element.fire("ajax:loading", {request: request}); },
      onLoaded:      function(request) { element.fire("ajax:loaded", {request: request}); },
      onInteractive: function(request) { element.fire("ajax:interactive", {request: request}); },
      onComplete:    function(request) { element.fire("ajax:complete", {request: request}); },
      onSuccess:     function(request) { element.fire("ajax:success", {request: request}); },
      onFailure:     function(request) { element.fire("ajax:failure", {request: request}); }
    });
    element.fire("ajax:after");
  },
  // Triggers a particular method verb to be triggered in a form posting to the url
  // JSAdapter.sendMethod(element);
  sendMethod : function(element) {
    var verb = element.get('data-method');
    var url = element.get('href');
    var form = new Element('form', { method: "POST", action: url, style: "display: none;" });
    element.parentNode.insert(form);
    if (verb !== 'post') {
      var field = new Element('input', { type: 'hidden', name: '_method', value: verb });
      form.insert(field);
    }
    form.submit();
  }
};