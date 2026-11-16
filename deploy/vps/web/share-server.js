// Minimaler Node-Server, der die Vercel-Function api/share.js ausführt.
// nginx leitet /post/<id>, /share/<type>/<id>, /open usw. hierher weiter.
'use strict';

const http = require('http');
const path = require('path');

const port = Number(process.env.PORT || 3000);
const handlerPath = path.join(__dirname, 'api', 'share.js');

function loadHandler() {
  // Bei jedem Deploy kommt eine neue share.js; Cache leeren, damit sie greift.
  delete require.cache[require.resolve(handlerPath)];
  return require(handlerPath);
}

http
  .createServer(async (req, res) => {
    try {
      const url = new URL(req.url, 'http://localhost');
      if (url.pathname === '/healthz') {
        res.statusCode = 200;
        return res.end('ok');
      }
      req.query = Object.fromEntries(url.searchParams);
      await loadHandler()(req, res);
    } catch (err) {
      console.error('share handler failed', err);
      if (!res.headersSent) {
        res.statusCode = 302;
        res.setHeader('Location', '/');
      }
      res.end();
    }
  })
  .listen(port, () => console.log(`share server listening on :${port}`));
