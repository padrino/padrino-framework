/*
 * Padrino Javascript Mootools Adapter
 * Created for use with Padrino Ruby Web Framework (http://www.padrinorb.com)
**/

// Halt Definition
Event.implement({ halt: function() { this.stop(); this.stopped = true; }});

window.addEvent('domready', function() {

/* Remote Form Support
 * form_for @user, '/user', :remote => true
**/

document.body.delegateEvent('submit', { "form[data-remote=true]" :
  function(e) {
    e.halt();
    var element = e.target;
    var message = element.get('data-confirm');
    if (message && !confirm(message)) { return false; }
    JSAdapter.sendRequest(element, { 
      verb: element.get('data-method') || element.get('method') || 'post', 
      url: element.get('action'), 
      params: element.toQueryString()
    });
  }
});

/* Confirmation Support
 * link_to 'sign out', '/logout', :confirm => "Log out?"
**/

document.body.delegateEvent('click', { "a[data-confirm]" : 
  function(e) {
    var message = e.target.get('data-confirm');
    if (message && !confirm(message)) { e.halt(); }
  }
});

/* 
 * Link Remote Support 
 * link_to 'add item', '/create', :remote => true
**/

document.body.delegateEvent('click', { "a[data-remote]" : 
  function(e) {
    if (e.stopped) return; e.halt();
    var element = e.target;
    JSAdapter.sendRequest(element, { 
      verb: element.get('data-method') || 'get', 
      url: element.get('href')
    }); 
  }
});

/* 
 * Link Method Support
 * link_to 'delete item', '/destroy', :method => :delete
**/

document.body.delegateEvent('click', { "a[data-method]:not([data-remote])" :
  function(e) {
    if (e.stopped) return;
    console.log(e.target);
    JSAdapter.sendMethod(e.target);
    e.halt();
  }});
});

/* JSAdapter */
var JSAdapter = {
  // Sends an xhr request to the specified url with given verb and params
  // JSAdapter.sendRequest(element, { verb: 'put', url : '...', params: {} });
  sendRequest : function(element, options) {
    var verb = options.verb, url = options.url, params = options.params;
    var event = element.fireEvent("ajax:before");
    if (event.stopped) return false;
    new Request({
      url: url, 
      method: verb || 'post',
      data: params || '',
      evalScripts: true,

      onRequest:     function(request) { element.fireEvent("ajax:loading", {request: request}); },
      onComplete:    function(request) { element.fireEvent("ajax:complete", {request: request}); },
      onSuccess:     function(request) { element.fireEvent("ajax:success", {request: request}); },
      onFailure:     function(request) { element.fireEvent("ajax:failure", {request: request}); }
    }).send();
    element.fireEvent("ajax:after");
  },
  // Triggers a particular method verb to be triggered in a form posting to the url
  // JSAdapter.sendMethod(element);
  sendMethod : function(element) {
    var verb = element.get('data-method');
    var url = element.get('href');
    var form = new Element('form', { method: "POST", action: url, style: "display: none;" });
    element.parentNode.adopt(form);
    if (verb !== 'post') {
      var field = new Element('input', { type: 'hidden', name: '_method', value: verb });
      form.adopt(field);
    }
    form.submit();
  }
};