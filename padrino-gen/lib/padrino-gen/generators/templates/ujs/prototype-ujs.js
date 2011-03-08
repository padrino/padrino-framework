/*
 * Padrino Javascript Prototype + LowPro Adapter
 * Created for use with Padrino Ruby Web Framework (http://www.padrinorb.com)
**/

document.observe("dom:loaded", function() {

  /* Remote Form Support
   * form_for @user, '/user', :remote => true
  **/

  document.observe("submit", function(e) {
    var element = e.findElement("form[data-remote=true]");
    if (element) {
      e.stop();
      var message = element.readAttribute('data-confirm');
      if (message && !confirm(message)) { return false; }
      JSAdapter.sendRequest(element, { 
        verb:element.readAttribute('data-method') || element.readAttribute('method') || 'post', 
        url: element.readAttribute('action'), 
        params: element.serialize(true)
      });
    }
  });

  /* Confirmation Support
   * link_to 'sign out', '/logout', :confirm => "Log out?"
  **/
  
  document.observe("click", function(e) {
    var element = e.findElement("a[data-confirm]");
    if (element) {
      var message = element.readAttribute('data-confirm');
      if (!confirm(message)) { e.stop(); }
    }
  }); 

  /* 
   * Link Remote Support 
   * link_to 'add item', '/create', :remote => true
  **/

  document.observe("click", function(e) {
    var element = e.findElement("a[data-remote]");
    if (element) {
      if (e.stopped) return;
      e.stop();
      JSAdapter.sendRequest(element, { 
        verb: element.readAttribute('data-method') || 'get', 
        url: element.readAttribute('href')
      });
    }
  });
  
  /* 
   * Link Method Support
   * link_to 'delete item', '/destroy', :method => :delete
  **/
  
  document.observe("click", function(e) {
    var element = e.findElement("a[data-method]:not([data-remote])");
    if (element) {
      if (e.stopped) return;
      JSAdapter.sendMethod(e.target);
      e.stop();
    }
  });  
  
});

/* JSAdapter */
var JSAdapter = {
  // Sends an xhr request to the specified url with given verb and params
  // JSAdapter.sendRequest(element, { verb: 'put', url : '...', params: {} });
  sendRequest : function(element, options) {
    var verb = options.verb, url = options.url, params = options.params;
    var event = element.fire("ajax:before");
    if (event.stopped) return false;
    new Ajax.Request(url, {
      method: verb || 'post',
      parameters: params || {},
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
    var verb = element.readAttribute('data-method');
    var url = element.readAttribute('href');
    var form = new Element('form', { method: "POST", action: url, style: "display: none;" });
    element.parentNode.insert(form);
    if (verb !== 'post') {
      var field = new Element('input', { type: 'hidden', name: '_method', value: verb });
      form.insert(field);
    }
    form.submit();
  }
};