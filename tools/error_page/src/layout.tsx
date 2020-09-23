/* eslint-disable max-len */
import { promisify } from 'util';

import sass from 'node-sass';
import React, { ReactElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

import { devDependencies } from '../package.json';

const outputStyle: 'compact' | 'compressed' | 'expanded' | 'nested' = 'compressed';

const sassRender = promisify(sass.render);

type renderConfig = {
  readonly language?: string;
  readonly themeColor?: string;
  readonly title: string;
};

export async function render(content: ReactElement, config: renderConfig): Promise<string> {
  const govukFrontendVersion = devDependencies['govuk-frontend'].replace('^', 'v');
  const cfg: renderConfig = {
    language: 'en',
    themeColor: '#0b0c0c',

    ...config,
  };
  const sassConfig = (location: string): object => ({
    file: location,
    includePaths: [ `${__dirname}/../node_modules` ],
    outputStyle,
  });

  const cssScreen = await sassRender(sassConfig(`${__dirname}/styles/screen.scss`));
  const cssPrint = await sassRender(sassConfig(`${__dirname}/styles/print.scss`));

  const html = `<!DOCTYPE html>
  <html lang=${cfg.language} class="govuk-template">
    <head>
      <meta charSet="utf-8" />
      <title lang="${cfg.language}">${cfg.title}</title>
      <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
      <meta name="theme-color" content="${cfg.themeColor}" />
      <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
      <!--[if !IE 8]><!-->
        <style media="screen">${cssScreen.css}</style>
        <style media="print">${cssPrint.css}</style>
      <!--<![endif]-->
    </head>
    ${renderToStaticMarkup(
      <body className="govuk-template__body">
        <script
          dangerouslySetInnerHTML={{
            __html:
              // eslint-disable-next-line quotes
              `document.body.className = ((document.body.className) ? document.body.className + ' js-enabled' : 'js-enabled');`,
          }}
        ></script>
        <a href="#main-content" className="govuk-skip-link">
          Skip to main content
        </a>
        <div className="govuk-width-container">
          <main
            className="govuk-main-wrapper"
            id="main-content"
            role="main"
            lang={cfg.language}
          >
            {content}
          </main>
        </div>
      </body>,
    )}
  </html>`;

  return html.replace(/{{ .Header.Get &quot;X-Cf-RouterError&quot; }}/g, '{{ .Header.Get "X-Cf-RouterError" }}');
}
