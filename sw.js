/* sw.js · 小窝的离线壳；有网拿新的，自身更新后自动重载已开页面 */
const CACHE = 'xiaowo-v4';

const MANIFEST = {
  name: '\u5c0f\u7a9d',
  short_name: '\u5c0f\u7a9d',
  description: '\u6211\u4eec\u7684\u5c0f\u5bb6',
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
        return caches.delete(k);
      }));
    }).then(function () {
      return self.clients.claim();
    }).then(function () {
      return self.clients.matchAll({ type: 'window' }).then(function (list) {
        list.forEach(function (c) {
          try { if (c.navigate) c.navigate(c.url); } catch (err) {}
        });
      });
    })
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
    fetch(req.url, { cache: 'no-store', credentials: 'same-origin', redirect: 'follow' })
      .then(function (res) {
        if (res && res.status === 200) {
          const copy = res.clone();
          caches.open(CACHE).then(function (c) { c.put(req, copy); }).catch(function () {});
        }
        return res;
      })
      .catch(function () {
        return caches.match(req).then(function (hit) {
          if (hit) return hit;
          if (req.mode === 'navigate') {
            return caches.match('./index.html').then(function (page) {
              return page || new Response('\u65ad\u7f51\u4e86\uff0c\u5148\u8fde\u4e0a\u518d\u5f00\u4e00\u6b21\u3002');
            });
          }
          return new Response('', { status: 504 });
        });
      })
  );
});
