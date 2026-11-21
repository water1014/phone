/* pwa.js · 让它能装到桌面上 */
(function () {
  let deferred = null;

  const api = {
    can: false,
    install: function () {
      if (!deferred) return false;
      const p = deferred;
      deferred = null;
      api.can = false;
      p.prompt();
      if (p.userChoice) p.userChoice.then(function () {});
      return true;
    }
  };

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('sw.js').catch(function () {});
    });
  }

  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    deferred = e;
    api.can = true;
  });

  window.addEventListener('appinstalled', function () {
    deferred = null;
    api.can = false;
  });

  window.XWPWA = api;
})();
