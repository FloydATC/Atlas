// Code derived from CGI::Ajax (http://search.cpan.org/~bct/CGI-Ajax-0.701/lib/CGI/Ajax.pm)
// Modified by floyd@atc.no
var ajax = [];
function pjx(args,method) { 
  this.target=args[2];
  this.args=args[1];
  method=(method)?method:'GET';
  if(method=='post'){method='POST';}
  this.method = method;
  this.r=ghr();
  this.url = this.getURL();
}

function formDump(){
  var all = [];
  var fL = document.forms.length;
  for(var f = 0;f<fL;f++){
    var els = document.forms[f].elements;
    for(var e in els){
      var tmp = (els[e].id != undefined)? els[e].id : els[e].name;
      if(typeof tmp != 'string'){continue;}
      if(tmp){ all[all.length]=tmp}
    }
  }
  return all;
}
function getVal(id) {
  if (id.constructor == Function ) { return id(); }
  if (typeof(id)!= 'string') { return id; }

  var element = document.getElementById(id);
  if( !element ) {
    for( var i=0; i<document.forms.length; i++ ){
      element = document.forms[i].elements[id];
      if( element ) break;
    }
    if( element && !element.type ) element = element[0];
  }
  if(!element){
    alert('ERROR: Cant find HTML element with id or name: ' +
    id+'. Check that an element with name or id='+id+' exists');
    return 0;
  }

  if(element.type == 'select-one') {
    if(element.selectedIndex == -1) return;
    var item = element[element.selectedIndex];
    return  item.value || item.text;
  }
  if(element.type == 'select-multiple') {
    var ans = [];
    var k =0;
    for (var i=0;i<element.length;i++) {
      if (element[i].selected || element[i].checked ) {
        ans[k++]= element[i].value || element[i].text;
      }
    }
    return ans;
  }
  if(element.type == 'radio' || element.type == 'checkbox'){
    var ans =[];
    var elms = document.getElementsByTagName('input');
    var endk = elms.length ;
    var i =0;
    for(var k=0;k<endk;k++){
      if(elms[k].type== element.type && elms[k].checked && (elms[k].id==id||elms[k].name==id)){
        ans[i++]=elms[k].value;
      }
    }
    return ans;
  }
  if( element.value == undefined ){
    return element.innerHTML;
  }else{
    return element.value;
  }
}
function fnsplit(arg) {
  var url="";
  if(arg=='NO_CACHE'){return '&pjxrand='+Math.random()}
  if((typeof(arg)).toLowerCase() == 'object'){
      for(var k in arg){
         if (url) { url += '&'; }
         url += k + '=' + arg[k];
      }
  } else if (arg.indexOf('__') != -1) {
    arga = arg.split(/__/);
    if (url) { url += '&'; }
    url += arga[0] +'='+ escape(arga[1]);
  } else {
    var res = getVal(arg) || '';
    if(res.constructor != Array){ res = [res] }
    for(var i=0;i<res.length;i++) {
      if (url) { url += '&'; }
      url += arg + '=' + escape(res[i]);
    }
  }
  return url;
}

pjx.prototype =  {
  send2perl : function(){
    var r = this.r;
    var dt = this.target;
    this.pjxInitialized(dt);
    var url=this.url;
    var postdata;
    if(this.method=="POST"){
      var idx=url.indexOf('?');
      postdata = url.substr(idx+1);
      url = url.substr(0,idx);
    }
    r.open(this.method,url,true);
    ;
    if(this.method=="POST"){
      r.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      r.send(postdata);
    }
    if(this.method=="GET"){
      r.send(null);
    }
    r.onreadystatechange = handleReturn;
 },
 pjxInitialized : function(){},
 pjxCompleted : function(){},
 readyState4 : function(){
    var rsp = unescape(this.r.responseText);  /* the response from perl */
    var splitval = '__pjx__';  /* to split text */
    /* fix IE problems with undef values in an Array getting squashed*/
    rsp = rsp.replace(splitval+splitval+'g',splitval+" "+splitval);
    var data = rsp.split(splitval);  
    dt = this.target;
    if (dt.constructor != Array) { dt=[dt]; }
    if (data.constructor != Array) { data=[data]; }
    if (typeof(dt[0])!='function') {
      for ( var i=0; i<dt.length; i++ ) {
        var div = document.getElementById(dt[i]);
        if (div.type =='text' || div.type=='textarea' || div.type=='hidden' ) {
          div.value=data[i];
        } else{
          div.innerHTML = data[i];
        }
      }
    } else if (typeof(dt[0])=='function') {
       dt[0].apply(this,data);
    }
    this.pjxCompleted(dt);
 },

  getURL : function() {
      var args = this.args;
      var url= '';
      for (var i=0;i<args.length;i++) {
        if (url) { url += '&'; }
        url=url + args[i];
      }
      return url;
  }
};

handleReturn = function() {
  for( var k=0; k<ajax.length; k++ ) {
    if (ajax[k].r==null) { ajax.splice(k--,1); continue; }
    if ( ajax[k].r.readyState== 4) { 
      ajax[k].readyState4();
      ajax.splice(k--,1);
      continue;
    }
  }
};

var ghr=getghr();
function getghr(){
    if(typeof XMLHttpRequest != "undefined")
    {
        return function(){return new XMLHttpRequest();}
    }
    var msv= ["Msxml2.XMLHTTP.7.0", "Msxml2.XMLHTTP.6.0",
    "Msxml2.XMLHTTP.5.0", "Msxml2.XMLHTTP.4.0", "MSXML2.XMLHTTP.3.0",
    "MSXML2.XMLHTTP", "Microsoft.XMLHTTP"];
    for(var j=0;j<=msv.length;j++){
        try
        {
            A = new ActiveXObject(msv[j]);
            if(A){ 
              return function(){return new ActiveXObject(msv[j]);}
            }
        }
        catch(e) { }
     }
     return false;
}

function cgi() {
  var args = cgi.arguments;
  for( var i=0; i<args[1].length;i++ ) {
    args[1][i] = fnsplit(args[1][i]);
  }
  var l = ajax.length;
  ajax[l]= new pjx(args,args[3]);
  ajax[l].url = args[0] + '?' + ajax[l].url;
  ajax[l].send2perl();
}


