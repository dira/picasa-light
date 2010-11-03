Ro = {}
Ro.Dira = {1:1
  ,HOW_MANY_IN_PARALLEL : 4
  ,ready: function() {
    var noscript = $('.photos noscript');
    var container = document.createElement('ol');
    noscript.after(container);
    Ro.Dira.container = $(container);
    Ro.Dira.targetPhoto = document.location.hash ? document.location.hash.slice(1) : null;

    Ro.Dira.getNoscriptContents(noscript, Ro.Dira.gotNoscript);
  }

  ,gotNoscript: function(noscriptText) {
    var lines = noscriptText.split("\n");
    lines = $.map(lines, function(element){ return element.contains("<li") ? element : null });
    if (Ro.Dira.targetPhoto) {
      lines = $.map(lines, function(element){ return element.contains("name='" + Ro.Dira.targetPhoto + "'") ? element : null });
    }
    Ro.Dira.photosHtml = lines;
    Ro.Dira.loadPhotos(Ro.Dira.HOW_MANY_IN_PARALLEL);
  }

  ,loadPhotos: function(how_many) {
    if (Ro.Dira.photosHtml.length == 0) {
      Ro.Dira.loadingEnded();
      return;
    }

    Ro.Dira.current_batch = Ro.Dira.photosHtml.splice(0, how_many);
    $.each(Ro.Dira.current_batch, function(i, photoHtml) { Ro.Dira.createPhoto(photoHtml) });
  }

  ,createPhoto: function(html) {
    var lastPhoto = $('li', Ro.Dira.container).last();
    Ro.Dira.container.append(html);
    var photo = lastPhoto.next();
    if (photo.length == 0) photo = $('li', Ro.Dira.container).first();

    var img = $('img', photo);
    if (img[0].complete) {
      Ro.Dira.imageLoaded();
    } else {
      img.bind('load', Ro.Dira.imageLoaded).bind('error', Ro.Dira.imageLoaded);
    }

    var a = $('a', photo);
    a.bind('click', Ro.Dira.photoClicked);
  }

  ,imageLoaded: function() {
    Ro.Dira.loadPhotos(1);
  }

  ,loadingEnded: function() {
    if (Ro.Dira.targetPhoto) {
      Ro.Dira.container.after('<a href="' + Ro.Dira.albumUrl() + '">Entire album</a>');
      $('li .meta', Ro.Dira.container).addClass('visible');
    }
  }

  ,albumUrl: function() {
    return document.location.href.match(/[^#]*/);
  }

  ,photoClicked: function(e) {
    var a = $(e.currentTarget);
    var small = $('img', a).first();
    var big = small.next();

    if (!(a.hasClass('small') || a.hasClass('big'))) {
      a.addClass('small');
    }

    if (a.hasClass('small')) {
      if (big.length == 0) {
        var big = small.clone();
        big.attr( {
          src: big.attr('data-big-src'),
          width: big.attr('data-big-width'), height: big.attr('data-big-height')
        });
        big.appendTo(a);
      }
      small.hide(); big.show();
    } else {
      small.show(); big.hide();
    }
    a.toggleClass('small').toggleClass('big');
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
        if (line.contains("</noscript")) {
          insideNoscript = false;
          return null;
        }
        return line;
      } else {
        if (line.contains("<noscript")) {
          insideNoscript = true;
        }
        return null;
      }
    });
    return lines.join("\n");
  }

  ,showEmbed: function(element) {
    var code = element.getAttribute('data-code');
    prompt('Embed code:', Ro.Dira.decode(code));
    return false;
  }

  ,decode: function(code) {
    return code.replace(/\\"/g, '"').replace(/\\'/g, "'").replace(/>\s+</g, "><") ;
  }
}

String.prototype.contains = function(substring) {
  return this.indexOf(substring) > -1;
}

jQuery.fn.decodeHTML = function() {
  return this.map(function(){
    return jQuery(this).html().replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
  });
};

$(document).ready(Ro.Dira.ready);
