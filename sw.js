// V5: rede em primeiro lugar para HTML, JS e CSS; nunca cachear configuracao antiga.
const CACHE='lovespace-shell-v5';
const SHELL=['./','./index.html','./style.css','./leaflet-fix.css','./app.js','./manifest.webmanifest','./icon.svg'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(SHELL)));self.skipWaiting()});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('lovespace-shell-')&&k!==CACHE).map(k=>caches.delete(k)))));self.clients.claim()});
self.addEventListener('fetch',e=>{const req=e.request;const url=new URL(req.url);if(req.method!=='GET'||url.origin!==self.location.origin)return;
if(url.pathname.endsWith('/config.js')){e.respondWith(fetch(req,{cache:'no-store'}));return}
e.respondWith(fetch(req).then(res=>{if(res.ok){const copy=res.clone();e.waitUntil(caches.open(CACHE).then(c=>c.put(req,copy)))}return res}).catch(()=>caches.match(req)))});
