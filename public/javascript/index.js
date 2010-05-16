window.onload = init;
host = document.location;

function is_changed() {
  if (source.value != value) {
    value = source.value;
    update(value);
  }
}

function update(value) {
  target.href = host + escape(value);
  target.innerHTML = host + value;
}

function goto_target() {
  document.location = target.href;
  return false;
}

function init() {
  source = document.getElementById("picasa_id");
  source.select();
  source.focus();
  source.parentNode.onsubmit = goto_target;
  target = document.getElementById("light_link_id");

  value = source.value;
  update(value);
  setInterval(is_changed, 300);
}
