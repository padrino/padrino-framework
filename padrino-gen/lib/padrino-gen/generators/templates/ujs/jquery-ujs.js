/*
 * Padrino Javascript Jquery Adapter
 * Created for use with Padrino Ruby Web Framework (http://www.padrinorb.com)
**/

/* Remote Form Support
 * form_for @user, '/user', :remote => true
**/

$("form[data-remote=true]").live('submit', function(e) {
  e.preventDefault(); e.stopped = true;
  var element = $(e.target);
  var message = element.attr('data-confirm');
  if (message && !confirm(message)) { return false; }
  JSAdapter.sendRequest(element, { 
    verb: element.attr('method') || 'post', 
    url: element.attr('action'), 
    params: element.serializeArray()
  });
});

/* Confirmation Support
 * link_to 'sign out', '/logout', :confirm => "Log out?"
**/

$("a[data-confirm]").live('click', function(e) {
  var message = $(e.target).attr('data-confirm');
  if (!confirm(message)) { e.preventDefault(); e.stopped = true; }
});

/* 
 * Link Remote Support 
 * link_to 'add item', '/create', :remote => true
**/

$("a[data-remote=true]").live('click', function(e) {
  var element = $(e.target); 
  if (e.stopped) return;
  e.preventDefault(); e.stopped = true;
  JSAdapter.sendRequest(element, { 
    verb: element.attr('data-method') || 'get', 
    url: element.attr('href')
  });
});

/* 
 * Link Method Support
 * link_to 'delete item', '/destroy', :method => :delete
**/

$("a[data-method]").live('click', function(e) {
  if (e.stopped) return;
  JSAdapter.sendMethod($(e.target));
  e.preventDefault(); e.stopped = true;
});

/* JSAdapter */
var JSAdapter = {
  // Sends an xhr request to the specified url with given verb and params
  // JSAdapter.sendRequest(element, { verb: 'put', url : '...', params: {} });
  sendRequest : function(element, options) {
    var verb = options.verb, url = options.url, params = options.params;
    var event = element.trigger("ajax:before");
    if (event.stopped) return false;
    $.ajax({
      url: url,
      type: verb.toUpperCase() || 'POST',
      data: params || [],
      dataType: 'script',

      beforeSend: function(request) { element.trigger("ajax:loading", {request: request}); },
      complete:   function(request) { element.trigger("ajax:complete", {request: request}); },
      success:    function(request) { element.trigger("ajax:success", {request: request}); },
      error:      function(request) { element.trigger("ajax:failure", {request: request}); }
    });
    element.trigger("ajax:after");
  },
  // Triggers a particular method verb to be triggered in a form posting to the url
  // JSAdapter.sendMethod(element);
  sendMethod : function(element) {
    var verb = element.attr('data-method');
    var url = element.attr('href');
    var form = $('<form method="post" action="'+url+'"></form>');
    form.hide().appendTo('body');
    if (verb !== 'post') {
      var field = '<input type="hidden" name="_method" value="' + verb + '" />';
      form.append(field);
    }
    form.submit();
  }
};