Ro = {}
Ro.Dira = {1:1
  ,HOW_MANY_IN_PARALLEL : 4
  ,ready: function() {
    var noscript = $('.photos noscript');
    var container = document.createElement('ol');

    noscript.after(container);
    Ro.Dira.container = $(container);

    Ro.Dira.getNoscriptContents(noscript, Ro.Dira.gotNoscript);
  }

  ,gotNoscript: function(noscriptText) {
    var lines = noscriptText.split("\n");
    Ro.Dira.items = $.map(lines, function(element){ return element.indexOf("<li") > -1 ? element : null });
    Ro.Dira.loadPhotos(Ro.Dira.HOW_MANY_IN_PARALLEL);
  }

  ,loadPhotos: function(how_many) {
    if (Ro.Dira.items.length == 0) return;

    Ro.Dira.current_batch = Ro.Dira.items.splice(0, how_many);
    $.each(Ro.Dira.current_batch, function(i, itemHtml) { Ro.Dira.createItem(itemHtml) });
  }

  ,createItem: function(html) {
    Ro.Dira.container.append(html);

    var img = $('img', Ro.Dira.container).last();
    if (img[0].complete) {
      Ro.Dira.photoLoaded();
    } else {
      img.bind('load', Ro.Dira.photoLoaded).bind('error', Ro.Dira.photoLoaded);
    }
  }

  ,photoLoaded: function() {
    Ro.Dira.loadPhotos(1);
  }

  ,getNoscriptContents: function(noscript, continuation) {
    var html = noscript.decodeHTML()[0];
    if (html != '') {
      continuation(html);
    } else {
      Ro.Dira.getNoscriptInWebkit(noscript, continuation);
    }
  }

  // WebKit does not reveal noscript's contents  http://bit.ly/9Jp2T3
  ,getNoscriptInWebkit: function(noscript, continuation) {
    // we'll ajaxy load the page again (from cache) and parse it ourselves :}
    $.ajax({
      async : false,
      success: function(data, status, request) {
        if (status == 'success') {
          continuation(Ro.Dira.extractNoscript(data));
        }
      }
    });
  }

  ,extractNoscript: function(data) {
    var insideNoscript = false;
    var lines = $.map(data.split("\n"), function(line){
      if (insideNoscript) {
        if (line.indexOf("</noscript") > -1) {
          insideNoscript = false;
          return null;
        }
        return line;
      } else {
        if (line.indexOf("<noscript") > -1) {
          insideNoscript = true;
        }
        return null;
      }
    });
    return lines.join("\n");
  }
}

jQuery.fn.decodeHTML = function() {
  return this.map(function(){
    return jQuery(this).html().replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
  });
};

$(document).ready(Ro.Dira.ready);
