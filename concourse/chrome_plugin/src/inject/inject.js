chrome.extension.sendMessage({}, function(response) {
    var readyStateCheckInterval = setInterval(function() {
        if (document.readyState === "complete") {
            clearInterval(readyStateCheckInterval);

            console.log("Monitor mode is go");
            var element = document.getElementsByClassName("legend")[0];
            element.parentNode.removeChild(element);

            var element = document.getElementById("cli-downloads");
            element.parentNode.removeChild(element);

            var hostname = location.hostname.replace("deployer.", "").replace(".cloudpipeline.digital","")

            var element = document.getElementsByTagName("nav")[0];
            element.innerHTML = "&nbsp;<font size=5>" + hostname + "</font>";
        }
    }, 10);
});
