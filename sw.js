/* sw.js · 小窝的离线壳
   有网就走网络（每次都拿新的），没网才用缓存的
   manifest 也由这里发，因为仓库里写不了纯 JSON 文件 */
const CACHE = 'xiaowo-v1';

const MANIFEST = {
  name: '小窝',
  short_name: '小窝',
  description: '我们的小家',
  lang: 'zh-CN',
  id: './',
  start_url: './',
  scope: './',
  display: 'standalone',
  orientation: 'portrait',
  background_color: '#fcfcfc',
  theme_color: '#fcfcfc',
  icons: [
    { src: 'icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' },
    { src: 'icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'maskable' }
  ]
};

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (k) {
        if (k !== CACHE) return caches.delete(k);
        return null;
      }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  const req = e.request;
  if (req.method !== 'GET') return;

  let url;
  try { url = new URL(req.url); } catch (err) { return; }

  if (url.pathname.slice(-14) === '/manifest.json') {
    e.respondWith(new Response(JSON.stringify(MANIFEST), {
      headers: { 'Content-Type': 'application/manifest+json; charset=utf-8' }
    }));
    return;
  }

  const sameSite = (url.origin === self.location.origin);
  const fonts = (url.hostname === 'fonts.loli.net');
  if (!sameSite && !fonts) return;

  e.respondWith(
    fetch(req).then(function (res) {
      if (res && res.status === 200) {
        const copy = res.clone();
        caches.open(CACHE).then(function (c) { c.put(req, copy); }).catch(function () {});
      }
      return res;
    }).catch(function () {
      return caches.match(req).then(function (hit) {
        if (hit) return hit;
        if (req.mode === 'navigate') {
          return caches.match('./index.html').then(function (page) {
            return page || new Response('断网了，先连上再开一次。');
          });
        }
        return new Response('', { status: 504 });
      });
    })
  );
});
