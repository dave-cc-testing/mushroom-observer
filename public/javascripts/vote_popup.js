// Popup little votes box.
function show_votes(this_id) {
  for (id in POPUPS) {
    var div = POPUPS[id]
    if (div) {
      if (id == this_id) {
        center_div(div);
        show_div(div);
      } else {
        hide_div(div);
      }
    }
  }
}

// Close vote box.
function hide_votes(this_id) {
  for (id in POPUPS) {
    var div = POPUPS[id]
    if (div)
      hide_div(div);
  }
}

// Called when vote is changed.
function change_vote(this_id) {
  if (VOTES[this_id].value == 100)
    for (id in POPUPS)
      if (id != this_id && VOTES[id].value == 100)
        VOTES[id].value = 80;
  CHANGED = 1;
}

// Called when submit button clicked (to prevent confirmation).
function set_changed(flag) {
  CHANGED = flag;
}

//-------------------------------------------------------------------
// These are a (very small) subset of prototype and our extensions.
// No reason to include prototype (yet) for this little vote popup.
//-------------------------------------------------------------------

// Make a div visible.
function show_div(div) {
  div.style.visibility = "visible";
}

// Make a div hidden.
function hide_div(div) {
  div.style.visibility = "hidden";
}

// Try to center a div in the window.
function center_div(div) {
  var w = div.offsetWidth;
  var h = div.offsetHeight;
  var sx = document.documentElement.scrollLeft || document.body.scrollLeft;
  var sy = document.documentElement.scrollTop  || document.body.scrollTop;
  var win = window_size();
  var sw = win[0];
  var sh = win[1];
  var x = Math.round((sw - w) / 2);
  var y = Math.round((sh - h) / 2);
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  div.style.left = (x + sx) + "px";
  div.style.top  = (y + sy) + "px";
}

// Get inner size of browser window.  This is a bit tricky.
// Apparently it can fail on Safari: if the document height
// is between the window height and window height plus scroll
// bar width, if will incorrectly choose the document height.
function window_size() {
  var sw, sh;
  var dw = document.width;
  var dh = document.height;
  var sw1 = document.body.clientWidth;
  var sw2 = document.documentElement.clientWidth;
  var sh1 = document.body.clientHeight;
  var sh2 = document.documentElement.clientHeight;
  var sh3 = window.innerHeight;
  sw = sw1 != 0 && sw1 != dw ? sw1 : sw2 != 0 ? sw2 : dw;
  sh = sh1 != 0 && sh1 != dh ? sh1 : sh2 != 0 ? sh2 : dh;
  if (sh3 != 0 && sh3 < sh) sh = sh3;
  return [sw, sh];
}
