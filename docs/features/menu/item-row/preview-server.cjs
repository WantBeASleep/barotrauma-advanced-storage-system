// Read-only preview of this mockup and its atlas; no directory listing or arbitrary file access.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const routes = new Map([
  ['/', ['prototype.html', 'text/html; charset=utf-8']],
  ['/prototype.html', ['prototype.html', 'text/html; charset=utf-8']],
  ['/my_proto.png', ['my_proto.png', 'image/png']],
  ['/assets/InventoryIconAtlas.png', ['assets/InventoryIconAtlas.png', 'image/png']],
  ['/assets/Exosuit.png', ['assets/Exosuit.png', 'image/png']]
]);
http.createServer((req, res) => {
  const host = req.headers.host;
  if (host !== '127.0.0.1:8765' && host !== 'localhost:8765') {
    res.writeHead(403); return res.end();
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { Allow: 'GET, HEAD' }); return res.end();
  }
  const route = routes.get(req.url.split('?')[0]);
  if (!route) { res.writeHead(404); return res.end(); }
  fs.readFile(path.join(__dirname, route[0]), (error, data) => {
    if (error) { res.writeHead(500); return res.end('Preview unavailable'); }
    res.writeHead(200, { 'Content-Type': route[1], 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
    res.end(req.method === 'HEAD' ? undefined : data);
  });
}).listen(8765, '127.0.0.1', () => console.log('Preview: http://127.0.0.1:8765/prototype.html'));