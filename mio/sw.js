/* 小手机 Service Worker：只负责系统通知，不做任何缓存，所以不会影响网页更新 */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));

// 点通知：回到小手机，并打开对应聊天
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const pid = (e.notification.data || {}).pid || '';
  e.waitUntil((async () => {
    const list = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of list) {
      if ('focus' in c) { await c.focus(); c.postMessage({ type: 'open-chat', pid }); return; }
    }
    if (self.clients.openWindow) await self.clients.openWindow('./' + (pid ? '?openChat=' + encodeURIComponent(pid) : ''));
  })());
});

// 预留：以后做服务器 Web Push 时，推送内容在这里显示
self.addEventListener('push', e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (_) {}
  e.waitUntil(self.registration.showNotification(d.title || 'Mio水汪汪', {
    body: d.body || '', tag: d.tag || 'push', data: d.data || {}, icon: d.icon, renotify: true
  }));
});
