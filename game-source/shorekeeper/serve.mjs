import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { createGzip } from 'node:zlib';

const root = path.resolve(fileURLToPath(new URL('./web/', import.meta.url)));
const mime = {'.html':'text/html; charset=utf-8','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    const relative = decodeURIComponent(url.pathname).replace(/^\/+/, '') || 'index.html';
    const target = path.resolve(root, relative);
    if (!target.startsWith(root + path.sep) && target !== path.join(root, 'index.html')) {
      res.writeHead(403).end(); return;
    }
    const info = await stat(target);
    if (!info.isFile()) { res.writeHead(404).end(); return; }
    res.setHeader('Content-Type', mime[path.extname(target)] || 'application/octet-stream');
    res.setHeader('Cache-Control','no-cache');
    res.setHeader('X-Content-Type-Options','nosniff');
    res.setHeader('Vary','Accept-Encoding');
    const stream = createReadStream(target);
    if (/gzip/.test(req.headers['accept-encoding'] || '') && info.size > 1024) {
      res.setHeader('Content-Encoding','gzip');
      stream.pipe(createGzip()).pipe(res);
    } else stream.pipe(res);
  } catch { res.writeHead(404).end('Not found'); }
});
server.listen(4197,'127.0.0.1',()=>console.log('TEPO Godot Web: http://127.0.0.1:4197'));
