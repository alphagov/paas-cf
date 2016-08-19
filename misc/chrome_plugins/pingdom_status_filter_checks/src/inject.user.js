// ==UserScript==
// @name        Pingdom Status Filter checks
// @namespace   cloudpipeline.digital
// @description Filters out any check in pingdom status page not starting with PaaS and Strips away some of the cruft
// @include     http://stats.pingdom.com/*
// @version     1
// @grant       GM_addStyle
// ==/UserScript==

// Workaround for webkit as in http://stackoverflow.com/a/10913069/395686
function addDebouncedEventListener(obj, eventType, delay, listener) {
    var timer;

    obj.addEventListener(eventType, function(evt) {
        if (timer) {
            window.clearTimeout(timer);
        }
        timer = window.setTimeout(function() {
            timer = null;
            listener.call(obj, evt);
        }, delay);
    }, false);
}

var prefix = "PaaS"
addDebouncedEventListener(document, "DOMNodeInserted", 10, function(e) {
    // Filter the desired checks
    var checks = document.getElementById('checks')
        var check_trs = checks.getElementsByTagName('tr')
        for (index = 0; index < check_trs.length; ++index) {
            tr = check_trs[index];
            try {
                line = tr.getElementsByClassName('check-name')[0]
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
    if (element) {
        element.parentNode.removeChild(element);
    }

    var element = document.getElementById("footer");
    if (element) {
        element.parentNode.removeChild(element);
    }

    var element = document.getElementsByClassName("largeTitle")[0];
    if (element) {
        element.parentNode.removeChild(element);
    }

    // Fix CSS for the checks when removing header
    document.getElementById("checks").style.marginTop = "0px";
});
