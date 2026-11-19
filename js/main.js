/* main.js · 启动 */
(function () {
  function boot() {
    if (window.XW && XW.S.theme === 'dark') {
      document.documentElement.classList.add('dark');
    }
    if (window.Desktop) window.Desktop.init();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

  /* PWA：网络优先，拿不到时才回缓存 —— 免得更了版本还看到旧文件 */
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('sw.js').catch(function (err) {
        console.warn('[sw] register failed', err);
      });
    });
  }
})();
