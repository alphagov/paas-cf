What
====

This is a small chrome plugin filters undesired checks.
It workarounds the issue of using a shared Pingdom Account with checks from multiple teams:
Pingdom only provides one status page per account, and we want to display only our checks in the dashboard.

It keeps only the checks which name starts with "PaaS"

It also strips away some of the cruft:
* The header a footer
* The page selector
* The page title


Installing
==========

1. Download this directory onto the machine running the monitors.
2. Open [chrome://extensions](chrome://extensions).
3. Tick the "Developer mode" checkbox in the top right.
4. Click "Load unpacked extention..." and select this directory.
5. Refresh your pingdom status page.

For Firefox or Chrome with a greasemonkey extension
===================================================
1. Click [src/inject.user.js](src/inject.user.js) and your browser _should_ auto-install it.
3. If not, drag it onto the browser.
4. Refresh your pingdom status page.
