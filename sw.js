/* sw.js · 网络优先，失败时回缓存
   这样改了文件不会因为缓存放不出去。 */
const CACHE = 'xiaowo-phone-v1';

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', function (event) {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    fetch(event.request).then(function (response) {
      const copy = response.clone();
      caches.open(CACHE).then(function (cache) {
        cache.put(event.request, copy).catch(function () {});
      });
      return response;
    }).catch(function () {
      return caches.match(event.request);
    })
  );
});
