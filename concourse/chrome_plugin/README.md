What
====

This is a small chrome plugin that strips away some of the cruft from the concourse pipeline view when showing it on monitoring screens.

It removes:
* The legend from the bottom left
* The download links from the bottom right
* The top menu bar & shortcuts

It adds:
* The hostname of the concourse instance to the top left, stripped of "deployer." and ".cloudpipeline.digital"

Installing
==========

1. Download this directory onto the machine running the monitors
2. Open [chrome://extensions](chrome://extensions)
3. Tick the "Developer mode" checkbox in the top right
4. Click "Load unpacked extention..." and select this directory
5. Refresh your concourse tabs, and they shall lack cruft.
