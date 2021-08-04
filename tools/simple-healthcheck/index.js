const Koa = require('koa');
const app = new Koa();

app.use(async ctx => {
    ctx.body = {
        status: 'OK',
        timestamp: new Date() / 1000,
    };
});

app.listen(process.env.PORT || 3000);
