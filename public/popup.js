

// Use and modify freely as long as the following text is included:
// Copyright (c) 2010 Andreas Lund <floyd@atc.no> - All Rights Reserved
// THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

var popupArray = [];



// Create a new popup object

function create_popup(url, left, top) {
  var object = new popupMenu(url, left, top);
  return object;
}



// Destroy named popup object

function close_popup(name) {
  for (i in popupArray) {
    if (popupArray[i] != null && popupArray[i].name == name) {
      popupArray[i].destroy();
      popupArray[i] = null;
    }
  }
}



// Destroy all popup objects

function close_popups() {
  for (i in popupArray) {
    if (popupArray[i] != null) {
      popupArray[i].destroy();
    }
  }
  popupArray = [];
}



// Popup object definition

function popupMenu(url, left, top) {
  this.index = popupArray.length;
  this.name = 'popup' + (this.index + 1);
  this.url = url;
//  alert('url='+url+' top='+top+' left='+left);  

  // Generate coordinates if none were given
  if (top == null) 	{ top = ((this.index % 16)+1) * 16; }
  if (left == null) 	{ left = ((this.index % 16)+1) * 16; }

  // Create DIV object
//  this.div = document.createElement('div');
  this.div = document.createElementNS("http://www.w3.org/1999/xhtml", "div");
  this.div.setAttribute('class', 'popup');
  this.div.setAttribute('id', this.name);
  this.div.style.visibility = 'hidden';
  this.div.style.position = 'absolute';
  this.div.style.top = top+'px';
  this.div.style.left = left+'px';
  document.body.appendChild(this.div);

  // Create HTTP request and fetch DIV content  
  this.http = new XMLHttpRequest();
  var self = this;
  this.http.onreadystatechange = function (event) {

    // Note: 'this' is the XMLHttpRequest object in this scope so use 'self'
    if (this.readyState == 4) {
      self.div.innerHTML = this.responseText;
      self.div.style.visibility = 'visible';
    }
    
  };
  this.http.open("GET", this.url, true);
  this.http.setRequestHeader("X-Popup-ID", this.name);
  this.http.send( null );

  this.destroy = function () {
    document.body.removeChild(this.div);    
    this.div = null;
    this.http = null;
  }
  
  popupArray[this.index] = this;
  return this;
} 



