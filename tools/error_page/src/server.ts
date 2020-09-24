import Koa from 'koa';

import { ErrorPage } from './error';
import { render } from './layout';

const app = new Koa();

app.use(async ctx => {
  const body = await render(ErrorPage(), { title: '{{ .StatusText }}' });

  ctx.body = body
    .replace(/{{ \.Status }}/g, '404')
    .replace(/{{ \.StatusText }}/g, 'Not Found')
    .replace(/{{ \.Message }}/g, '__MESSAGE__')
    .replace(/{{ \.Header\.Get "X-Cf-RouterError" }}/g, '__CAUSE__');
});

app.listen(process.env.PORT || 3000);
