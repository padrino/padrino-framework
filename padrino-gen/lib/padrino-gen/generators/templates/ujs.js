/*
 * Padrino UJS: the unobtrusive behaviour of Padrino's helpers, in plain browser
 * JavaScript with no dependencies.
 *
 * Load it from your layout, with the CSRF meta tags it reads the token from:
 *
 *   <%= csrf_meta_tags %>
 *   <%= javascript_include_tag 'ujs' %>
 *
 * Handled attributes:
 *   data-confirm  on links and forms: ask first, cancel on "no"
 *   data-method   on links: submit a form with that verb and the CSRF token
 *   data-remote   on links and forms: send the request over XHR
 *   data-type     on remote forms: the response type, 'script' by default
 *
 * Remote elements fire bubbling events, with the value in `event.detail`:
 *   ajax:before    call preventDefault() to cancel the request
 *   ajax:loading   the XMLHttpRequest
 *   ajax:after     fired once the request is sent
 *   ajax:success   the response data
 *   ajax:failure   the XMLHttpRequest
 *   ajax:complete  the XMLHttpRequest
 */
(function () {
  'use strict';

  // A second load would answer every click and submit twice.
  if (window.padrinoUJS) return;
  window.padrinoUJS = true;

  var ACCEPT = {
    script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript, */*; q=0.01',
    json: 'application/json, text/javascript, */*; q=0.01',
    html: 'text/html, */*; q=0.01',
    xml: 'application/xml, text/xml, */*; q=0.01',
    text: 'text/plain, */*; q=0.01'
  };

  function meta(name) {
    var tag = document.querySelector('meta[name="' + name + '"]');
    return tag ? tag.getAttribute('content') : null;
  }

  function isSameOrigin(url) {
    try {
      return new URL(url, document.baseURI).origin === window.location.origin;
    } catch (error) {
      return false;
    }
  }

  function fire(element, name, detail) {
    return element.dispatchEvent(new CustomEvent(name, { bubbles: true, cancelable: true, detail: detail }));
  }

  function hiddenInput(name, value) {
    var input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    return input;
  }

  // Submits a hidden form, since a link can only GET. Padrino reads the verb from `_method`.
  function sendMethod(link) {
    var verb = link.getAttribute('data-method');
    var url = link.getAttribute('href') || window.location.href;
    var target = link.getAttribute('target');
    var param = meta('csrf-param');
    var token = meta('csrf-token');
    var form = document.createElement('form');
    form.method = 'post';
    form.setAttribute('action', url);
    if (target) form.setAttribute('target', target);
    form.style.display = 'none';
    if (verb !== 'post') form.appendChild(hiddenInput('_method', verb));
    if (param !== null && token !== null && isSameOrigin(url)) form.appendChild(hiddenInput(param, token));
    document.body.appendChild(form);
    form.submit();
  }

  // The form's successful controls, without files: they can't be urlencoded.
  // FormData leaves out the button that submitted the form.
  function formParams(form, submitter) {
    var params = new URLSearchParams();
    new FormData(form).forEach(function (value, name) {
      if (typeof value === 'string') params.append(name, value);
    });
    if (submitter && submitter.name) params.append(submitter.name, submitter.value);
    return params;
  }

  function runScript(source) {
    var script = document.createElement('script');
    script.text = source;
    document.head.appendChild(script).parentNode.removeChild(script);
  }

  function parseXML(source) {
    var xml = new DOMParser().parseFromString(source, 'text/xml');
    if (xml.getElementsByTagName('parsererror').length) throw new Error('Invalid XML');
    return xml;
  }

  // Parses the response by the requested type, or by its Content-Type when none was requested.
  // Scripts run only when the request and its final URL, after redirects, are on this origin.
  // A response with no content has nothing to parse.
  function responseData(xhr, type, sameOrigin) {
    if (xhr.status === 204 || xhr.status === 304) return undefined;
    var contentType = xhr.getResponseHeader('Content-Type') || '';
    if (!type) {
      if (/\bjson\b/.test(contentType)) type = 'json';
      else if (/\bxml\b/.test(contentType)) type = 'xml';
      else if (/\b(?:java|ecma)script\b/.test(contentType)) type = 'script';
    }
    if (type === 'json') return JSON.parse(xhr.responseText);
    if (type === 'xml') return parseXML(xhr.responseText);
    if (type === 'script' && sameOrigin && isSameOrigin(xhr.responseURL)) runScript(xhr.responseText);
    return xhr.responseText;
  }

  function sendRequest(element, options) {
    if (!fire(element, 'ajax:before')) return;

    var xhr = new XMLHttpRequest();
    var verb = options.verb.toUpperCase();
    var safe = verb === 'GET' || verb === 'HEAD';
    var sameOrigin = isSameOrigin(options.url);
    var param = meta('csrf-param');
    var token = meta('csrf-token');
    var body = null;
    try {
      var url = new URL(options.url, document.baseURI);
      if (options.params && !sameOrigin && param !== null) options.params.delete(param);
      if (options.params && safe) {
        options.params.forEach(function (value, name) { url.searchParams.append(name, value); });
      } else if (options.params) {
        body = options.params.toString() || null;
      }
      xhr.open(verb, url.href);
    } catch (error) {
      fire(element, 'ajax:failure', xhr);
      fire(element, 'ajax:complete', xhr);
      return;
    }

    xhr.setRequestHeader('Accept', ACCEPT[options.type] || '*/*');
    if (body) xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
    if (sameOrigin) {
      xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
      if (token && !safe) xhr.setRequestHeader('X-CSRF-Token', token);
    }

    xhr.addEventListener('loadend', function () {
      var success = (xhr.status >= 200 && xhr.status < 300) || xhr.status === 304;
      var data;
      if (success) {
        try {
          data = responseData(xhr, options.type, sameOrigin);
        } catch (error) {
          success = false;
        }
      }
      if (success) fire(element, 'ajax:success', data);
      else fire(element, 'ajax:failure', xhr);
      fire(element, 'ajax:complete', xhr);
    });

    fire(element, 'ajax:loading', xhr);
    xhr.send(body);
    fire(element, 'ajax:after');
  }

  document.addEventListener('submit', function (event) {
    if (event.defaultPrevented) return;
    var form = event.target;
    var message = form.getAttribute('data-confirm');
    if (message && !window.confirm(message)) {
      event.preventDefault();
      return;
    }
    if (form.getAttribute('data-remote') !== 'true') return;
    event.preventDefault();
    sendRequest(form, {
      verb: form.getAttribute('data-method') || form.getAttribute('method') || 'get',
      url: form.getAttribute('action') || window.location.href,
      type: (form.getAttribute('data-type') || 'script').toLowerCase(),
      params: formParams(form, event.submitter)
    });
  });

  document.addEventListener('click', function (event) {
    if (event.defaultPrevented) return;
    var link = event.target.closest && event.target.closest('a[data-confirm], a[data-remote="true"], a[data-method]');
    if (!link) return;
    if (link.hasAttribute('data-confirm') && !window.confirm(link.getAttribute('data-confirm'))) {
      event.preventDefault();
    } else if (link.getAttribute('data-remote') === 'true') {
      event.preventDefault();
      sendRequest(link, {
        verb: link.getAttribute('data-method') || 'get',
        url: link.getAttribute('href') || window.location.href
      });
    } else if (link.hasAttribute('data-method') && !link.hasAttribute('data-remote')) {
      event.preventDefault();
      sendMethod(link);
    }
  });
})();
