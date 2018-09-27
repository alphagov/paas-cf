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
const readyStateCheckInterval = setInterval(() => {
  if (document.readyState === 'complete') {
    clearInterval(readyStateCheckInterval);

    console.log('Monitor mode is go');
    const $legend = document.querySelector('.legend');
    $legend.style.display = 'none';

    const $infoBox = document.querySelector('.lower-right-info');
    $infoBox.style.display = 'none';

    const $topBar = document.querySelector('#top-bar-app');
    $topBar.style.display = 'none';

    const $groupsBar = document.querySelector('.groups-bar');
    $groupsBar.style.display = 'none';

    const $bottom = document.querySelector('.bottom');
    // Remove the padding because the top bar isn't there any more.
    $bottom.style.paddingTop = '0';

    const hostname = window.location.hostname.replace('deployer.', '').replace('.cloudpipeline.digital', '');
    document.body.insertAdjacentHTML('beforeend', `<div style="bottom: 0; font-size: 24px; padding: 16px; position: absolute;">${hostname}</div>`);
  }
}, 2000);
