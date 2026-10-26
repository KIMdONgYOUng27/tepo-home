import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { dirname, resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = dirname(fileURLToPath(import.meta.url));
const port = Number(process.env.TEPO_HOME_PORT || 4180);
const types = {'.json':'application/json; charset=utf-8','.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.webp':'image/webp','.svg':'image/svg+xml','.wasm':'application/wasm','.pck':'application/octet-stream','.ogg':'audio/ogg','.woff2':'font/woff2'};
createServer(async(req,res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    const pathname=url.pathname.endsWith('/')?url.pathname+'index.html':url.pathname;
    const file = resolve(root, '.' + decodeURIComponent(pathname));
    if (!file.startsWith(root + sep)) { res.writeHead(403).end(); return; }
    const content = await readFile(file);
    const headers={'Content-Type':extname(file)==='.mp4'?'video/mp4':types[extname(file)] || 'application/octet-stream','Cache-Control':'no-cache','Accept-Ranges':'bytes'};
    const range=/^bytes=(\d+)-(\d*)$/.exec(req.headers.range||'');
    if(range){const start=Number(range[1]),end=Math.min(range[2]?Number(range[2]):content.length-1,content.length-1);if(start>end){res.writeHead(416,{'Content-Range':`bytes */${content.length}`}).end();return;}res.writeHead(206,{...headers,'Content-Range':`bytes ${start}-${end}/${content.length}`,'Content-Length':end-start+1}).end(content.subarray(start,end+1));return;}
    res.writeHead(200, {...headers,'Content-Length':content.length}).end(content);
  } catch { res.writeHead(404).end('Not found'); }
}).listen(port, '127.0.0.1', () => console.log(`TEPO home: http://127.0.0.1:${port}`));
