// ==UserScript==
// @name        Pingdom Status Filter checks
// @namespace   cloudpipeline.digital
// @description Filters out any check in pingdom status page not starting with PaaS and Strips away some of the cruft
// @include     http://stats.pingdom.com/*
// @version     1
// @grant       GM_addStyle
// ==/UserScript==

// Filter the desired checks
var prefix = "PaaS"
var checks = document.getElementById('checks')
checks.addEventListener("DOMNodeInserted", function(e) {
  var check_trs = checks.getElementsByTagName('tr')
  for (index = 0; index < check_trs.length; ++index) {
      tr = check_trs[index];
      try {
          line = tr.getElementsByClassName('check-name')[0]
          //alert(check_trs.length)
          check_name = line.getElementsByTagName('a')[0].text
          if (! check_name.startsWith(prefix)) {
              tr.style.display = "none";
          }
      }
      catch (e) {
        continue
      }
  }
  // Remove cruft
  var element = document.getElementsByClassName("fg-toolbar")[0];
  element.parentNode.removeChild(element);

  var element = document.getElementById("header");
  element.parentNode.removeChild(element);

  var element = document.getElementById("footer");
  element.parentNode.removeChild(element);

  var element = document.getElementsByClassName("largeTitle")[0];
  element.parentNode.removeChild(element);

}, false);


// Fix CSS for the checks when removing header
GM_addStyle ( "           \
    div#checks.overview { \
        margin-top: 0px;  \
    }                     \
" );
