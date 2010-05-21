Ro = {}
Ro.Dira = {1:1
  ,HOW_MANY_IN_PARALLEL : 4
  ,ready: function() {
    var noscript = $('.photos noscript');
    var html = noscript.decodeHTML()[0];

    var container = document.createElement('ol');
    noscript.after(container);

    var lines = html.split("\n");
    Ro.Dira.items = $.map(lines, function(element){ return element.indexOf("<li") > -1 ? element : null });
    Ro.Dira.container = $(container);

    Ro.Dira.loadPhotos(Ro.Dira.HOW_MANY_IN_PARALLEL);
  }

  ,loadPhotos: function(how_many) {
    if (Ro.Dira.items.length == 0) return;

    Ro.Dira.current_batch = Ro.Dira.items.splice(0, how_many);
    $.each(Ro.Dira.current_batch, function(i, element) { Ro.Dira.createItem(element) });
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
}

jQuery.fn.decodeHTML = function() {
  return this.map(function(){
    return jQuery(this).html().replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
  });
};

$(document).ready(Ro.Dira.ready);
