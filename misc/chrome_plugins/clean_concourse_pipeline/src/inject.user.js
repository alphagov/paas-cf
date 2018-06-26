// ==UserScript==
// @name        Remove concourse elements
// @namespace   cloudpipeline.digital
// @description Strips away some of the cruft from the concourse pipeline view when showing it on monitoring screens.
// @include     https://deployer.*.cloudpipeline.digital/*
// @include     https://deployer.cloud.service.gov.uk/*
// @include     https://deployer.london.cloud.service.gov.uk/*
// @version     1
// @grant       none
// ==/UserScript==
var readyStateCheckInterval = setInterval(function() {
    if (document.readyState === "complete") {
        clearInterval(readyStateCheckInterval);

        console.log("Monitor mode is go");
        var element = document.getElementsByClassName("legend")[0];
        element.parentNode.removeChild(element);

        var element = document.getElementsByClassName("lower-right-info")[0];
        element.parentNode.removeChild(element);

        var hostname = location.hostname.replace("deployer.", "").replace(".cloudpipeline.digital","");

        var element = document.getElementById("top-bar-app");
        element.innerHTML = "&nbsp;<font size=5>" + hostname + "</font>";
        // Move it to the bottom because there's more space there.
        element.style.position = "absolute";
        element.style.bottom = "0";

        var element = document.getElementsByClassName("bottom")[0];
        // Remove the padding because the top bar isn't there any more.
        element.style.paddingTop = "0";
    }
}, 2000);
