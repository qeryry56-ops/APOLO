// Local-only static server for the compiled Flutter release.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../build/web');
const mime = {'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.css':'text/css','.svg':'image/svg+xml'};
http.createServer((req,res)=>{
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url,'http://localhost').pathname); } catch {res.writeHead(400).end();return;}
  let file = path.resolve(root, '.' + pathname);
  if (file !== root && !file.startsWith(root + path.sep)) {res.writeHead(403).end();return;}
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(root,'index.html');
  res.setHeader('Content-Type',mime[path.extname(file)] || 'application/octet-stream');
  res.setHeader('Cache-Control','no-store');
  fs.createReadStream(file).on('error',()=>res.destroy()).pipe(res);
}).listen(8080,'127.0.0.1',()=>console.log('Apolo release preview ready at http://localhost:8080'));
