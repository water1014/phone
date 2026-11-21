/* app-guard.js · 进 App 就退出桌面编辑态
   router.js 不动，看 #app 的 class 变化就行 */
(function () {
  const D = document;
  const ROOT = D.documentElement;

  let bound = false;
  let watcher = null;

  function apply() {
    const app = D.getElementById('app');
    const on = !!(app && app.classList.contains('show'));

    if (on) {
      ROOT.setAttribute('data-app', '1');
      if (window.Layout && typeof Layout.exit === 'function') Layout.exit();
    } else {
      ROOT.removeAttribute('data-app');
    }
  }

  function bind() {
    const app = D.getElementById('app');
    if (!app || bound) return false;
    bound = true;
    new MutationObserver(apply).observe(app, { attributes: true, attributeFilter: ['class'] });
    apply();
    return true;
  }

  if (!bind()) {
    if (window.MutationObserver && D.body) {
      watcher = new MutationObserver(function () {
        if (bind() && watcher) {
          watcher.disconnect();
          watcher = null;
        }
      });
      watcher.observe(D.body, { childList: true });
    }
  }
})();
