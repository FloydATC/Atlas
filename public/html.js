


var scale = 1;

var dragged_object = null;
var dragged_originalx = 0;
var dragged_originaly = 0;

var scrolling = 0;
var scrolled = 0;
var lastx = 0;
var lasty = 0;


var refresh = null; // Used for storing timer object
svg_setTimer();


if (navigator.appName == 'Microsoft Internet Explorer' && navigator.appVersion < 9) {
  alert('Beklager, denne websiden fungerer kun i nettlesere med SVG, f.eks. Firefox, Opera, Chrome, Safari og IE versjon 9 eller h&oslash;yere.\nSVG er en anbefalt webstandard fra W3C siden 2001.');
}


// Shorthand function for addressing the <OBJECT> tag containing the SVG
function svg() {
  return window.top.document.getElementById('svg');
}


// Shorthand function for addressing the SVG document object
function svgdoc() {
  var svg = window.document.getElementById('svg');
  if (svg != null) { return svg.contentDocument; }
  return null;
}




// SVG Document functions
// ----------------------

function svg_click(event, id) {
  var object = event.target;

  // User clicked on the svg itself, destroy the popup menu (if any)
  // Note: if window was scrolled, ignore the click
  if (dragged_object) {
    end_drag_object();
  }
  if (event.button == 0 && scrolled == 0 && active_popups() > 0) {
    close_popups()
    return;
  }
  if (event.button == 0 && scrolled == 0) {
    var type = id.replace(/\d+/, '');
    popup_create(event, id, type);
    event.cancelBubble = true;
  }
  scrolled = 0;
}


function svg_mousedown(event) {
  var object = event.target;

  svg_cancelTimer();

  if (dragged_object == null) {
    scrolling = 1;
    lastx = svg().offsetLeft + event.clientX;
    lasty = svg().offsetTop + event.clientY;
  }

}


function svg_mouseup(event) {
  var object = event.target;

  scrolling = 0;
  svg_setTimer();
}


function svg_mousemove(event) {
  var object = event.target;

  if (scrolling == 1) {
    var mousex = svg().offsetLeft + event.clientX;
    var mousey = svg().offsetTop + event.clientY;

    // Calculate relative mouse movement
    window.top.scrollBy(-(mousex-lastx), -(mousey-lasty));

    lastx = mousex - (mousex - lastx); 
    lasty = mousey - (mousey - lasty); 
 
    scrolled = 1;
  }

  if (dragged_object) {
//    var mousex = svg().offsetLeft + event.clientX;
//    var mousey = svg().offsetTop + event.clientY;
    var mousex = event.clientX;
    var mousey = event.clientY;



    continue_drag_object(mousex, mousey);
  }
}


function svg_mouseover(event) {
  var object = event.target;
}


function svg_mouseout(event) {
  var object = event.target;
}


function svg_setTimer() {
  refresh = setTimeout("svg_refresh()", 30000); // Refresh SVG every 30 seconds 
}


function svg_cancelTimer() {
  clearTimeout(refresh);
}


function svg_refresh() {
  var svg = svgdoc();
  if (svg != null) { svg.location.reload(); }
}


function svg_resize(x, y, newscale) {
  close_popups();
  var obj = document.getElementById('svg');
  obj.width = x;
  obj.height = y;
  scale = newscale;
}





// Site functions
// --------------

function site_click(event, id) {
  var object = event.target;

  // User clicked on a site, show popup menu
  if (event.button == 0 && scrolled == 0 && dragged_object == null) {
    close_popups();
    popup_create(event, id, 'site');
    event.cancelBubble = true;
  }
}


function site_mousedown(event) {
  var object = event.target;
}


function site_mouseup(event) {
  var object = event.target;
}


function site_mousemove(event) {
  var object = event.target;
}


function site_mouseover(event) {
  var object = event.target;
}

function site_mouseout(event) {
  var object = event.target;
}






// Host functions
// --------------

function host_click(event, id) {
  var object = event.target;

  // User clicked on a host, show popup menu
  if (event.button == 0 && scrolled == 0 && dragged_object == null) {
    close_popups();
    popup_create(event, id, 'host');
    event.cancelBubble = true;
  }
}


function host_mousedown(event) {
  var object = event.target;
}


function host_mouseup(event) {
  var object = event.target;
}


function host_mousemove(event) {
  var object = event.target;
}


function host_mouseover(event) {
  var object = event.target;
}

function host_mouseout(event) {
  var object = event.target;
}

function host_disabled(id, disabled) {
  close_popups();
  var http = new XMLHttpRequest();
  var params = "type=host&id="+id+"&disabled="+disabled;
  http.open("post", "update.ajax");
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  http.setRequestHeader("Content-length", params.length);
  http.setRequestHeader("Connection", "close");
  http.send(params);
}

function snmp_probe(id, snmp) {
  close_popups();
  var http = new XMLHttpRequest();
  var params = "type=host&id="+id+"&snmp="+snmp;
  http.open("post", "update.ajax");
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  http.setRequestHeader("Content-length", params.length);
  http.setRequestHeader("Connection", "close");
  http.send(params);
}

function host_role(id, role) {
  close_popups();
  var http = new XMLHttpRequest();
  var params = "type=host&id="+id+"&role="+role;
  http.open("post", "update.ajax");
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  http.setRequestHeader("Content-length", params.length);
  http.setRequestHeader("Connection", "close");
  http.send(params);
}

function host_comment(id, comment) {
  close_popups();
  var http = new XMLHttpRequest();
  var params = "type=host&id="+id+"&comment="+comment;
  http.open("post", "update.ajax");
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  http.setRequestHeader("Content-length", params.length);
  http.setRequestHeader("Connection", "close");
  http.send(params);
}

function site_type(id, type) {
  close_popups();
  var http = new XMLHttpRequest();
  var params = "type=site&id="+id+"&sitetype="+type;
  http.open("post", "update.ajax");
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  http.setRequestHeader("Content-length", params.length);
  http.setRequestHeader("Connection", "close");
  http.send(params);
}

function site_comment(id, comment) {
  close_popups();
  var http = new XMLHttpRequest();
  var params = "type=site&id="+id+"&comment="+comment;
  http.open("post", "update.ajax");
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
  http.setRequestHeader("Content-length", params.length);
  http.setRequestHeader("Connection", "close");
  http.send(params);
}






// Sitegroup functions
// --------------

function sitegroup_click(event, id) {
  var object = event.target;

  // User clicked on a sitegroup, show popup menu
  if (event.button == 0 && scrolled == 0 && dragged_object == null) {
    close_popups();
    popup_create(event, id, 'sitegroup');
    event.cancelBubble = true;
  }
}


function sitegroup_mousedown(event) {
  var object = event.target;
}


function sitegroup_mouseup(event) {
  var object = event.target;
}


function sitegroup_mousemove(event) {
  var object = event.target;
}


function sitegroup_mouseover(event) {
  var object = event.target;
}

function sitegroup_mouseout(event) {
  var object = event.target;
}






// Hostgroup functions
// --------------

function hostgroup_click(event, id) {
  var object = event.target;

  // User clicked on a hostgroup, show popup menu
  if (event.button == 0 && scrolled == 0 && dragged_object == null) {
    close_popups();
    popup_create(event, id, 'hostgroup');
    event.cancelBubble = true;
  }
}


function hostgroup_mousedown(event) {
  var object = event.target;
}


function hostgroup_mouseup(event) {
  var object = event.target;
}


function hostgroup_mousemove(event) {
  var object = event.target;
}


function hostgroup_mouseover(event) {
  var object = event.target;
}

function hostgroup_mouseout(event) {
  var object = event.target;
}






// Commlink functions
// --------------

function commlink_click(event, id) {
  var object = event.target;

  // User clicked on a commlink, show popup menu
  if (event.button == 0 && scrolled == 0 && dragged_object == null) {
    close_popups();
    popup_create(event, id, 'commlink');
    event.cancelBubble = true;
  }
}


function commlink_mousedown(event) {
  var object = event.target;
}


function commlink_mouseup(event) {
  var object = event.target;
}


function commlink_mouseover(event) {
  var object = event.target;
}

function commlink_mouseout(event) {
  var object = event.target;
}


function commlink_mousemove(event) {
  var object = event.target;
}


function commlink_planned(id, planned) {
  close_popups();
  var http = new XMLHttpRequest();
  http.open("get", "update.ajax?type=commlink&id="+id+"&planned="+planned);
  http.onreadystatechange = svg_refresh(); // When request is complete
  http.send(null); // Send nothing (get)
}






function popup_create(event, id, type) {
//  alert('popup_create('+event+','+id+','+type+')');

  var object = event.target;
  var num_id = id.replace(/\D+/, '');
  var posx = svg().offsetLeft + event.clientX - 4;
  var posy = svg().offsetTop + event.clientY - 4;
  
//  alert('/'+type+'/popup?id='+num_id+', '+posx+', '+posy);
  create_popup('/'+type+'/popup?id='+num_id, posx, posy);
}




function cancel() {
  close_popups();
}





// Drag and drop functions, use with any SVG element that has a valid ID

function begin_drag_object(id) {
//  popup_destroy();
  close_popups();
  svg_cancelTimer();
  dragged_object = svgdoc().getElementById(id); 
  //alert('Begin dragging '+dragged_object+' id='+dragged_object.id);
  dragged_originalx = dragged_object.getAttribute('x');
  dragged_originaly = dragged_object.getAttribute('y');
}


function continue_drag_object(x, y) {
  if (dragged_object) {
    //alert('Continue dragging '+dragged_object+' id='+dragged_object.id);
    dragged_object.setAttribute('x', parseInt((x / scale) - 25));
    dragged_object.setAttribute('y', parseInt((y / scale) - 25));
  }
}


function end_drag_object() {
  var http = new XMLHttpRequest();
  if (dragged_object) {
    var x = dragged_object.getAttribute('x');
    var y = dragged_object.getAttribute('y');
    var relx = x - dragged_originalx;
    var rely = y - dragged_originaly;
    var type = dragged_object.id.replace(/\d+/, '');
    var id = dragged_object.id.replace(/\D+/, '');
    var params = "id="+id+"&x="+x+"&y="+y+"&relx="+relx+"&rely="+rely;
    http.open("post", "/"+type+"/move");
    http.onload = function() { 
      window.location.reload();
    };
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    http.send(params);
    pause(3000);
    // http.onload should kick in. If not, reload after timeout.
    window.location.reload(); 
  }
}

function pause(ms)
{
  var date = new Date();
  var curDate = null;
  do { curDate = new Date(); }
  while(curDate-date < millis);
}

function logout() {
  var http = new XMLHttpRequest();
  http.open("GET", "/logout", true, "#null", "#null");
  http.send(null);
}
