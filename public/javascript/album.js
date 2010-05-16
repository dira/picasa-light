$(document).ready(ready);
PAGE_SIZE = 2;
last = null;

function ready() {
  elements = $('.photos li');

  elements.slice(PAGE_SIZE).children('img').each(prevent_loading);
  $('.photos').show();

  last = $(elements[Math.min(PAGE_SIZE - 1, elements.size() - 1)]);
  $(window).scroll(scrolled);
}

function load(index, image) {
  $(image).parent('li').show();
  image.src = $(image).data("src");
}

function prevent_loading(index, image) {
  $(image).parent('li').hide();
  $(image).data("src", image.src);
  image.src = "/empty.png";
}

function scrolled(){
  if (!last || !last.next()) return;

  if ($(window).height() + 200 >= last.offset().top + last.height() - $(window).scrollTop()) {
    var elements = last.nextAll();
    elements = elements.slice(0, PAGE_SIZE);
    last = (elements.size() > 0 ? $(elements.last()) : null);
    elements.children('img').each(load);
  }
}
