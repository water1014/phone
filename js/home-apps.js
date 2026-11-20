/* home-apps.js · 给第 2、3 页补 App 入口（不碰 desktop.js） */
(function () {
  const PLAN = {
    1: ['calendar', 'plans', 'accounting', 'mood', 'health', 'cycle', 'study', 'quotes'],
    2: ['letter', 'music', 'moments', 'favorites', 'games', 'studio', 'worldbook', 'windows']
  };

  function cell(app) {
    return '<button type="button" class="appcell" data-app="' + app.id + '">' +
        window.UI.icon(app.icon) + '<span>' + app.name + '</span></button>';
  }

  function fill() {
    const pages = D.querySelectorAll('#home .page');
    if (!pages.length) return;

    Object.keys(PLAN).forEach(function (key) {
      const page = pages[Number(key)];
      if (!page || page.querySelector('.approw')) return;

      const row = D.createElement('div');
      row.className = 'approw';
      row.innerHTML = PLAN[key].map(function (id) {
        const app = window.Apps.find(id);
        return app ? cell(app) : '';
      }).join('');

      page.appendChild(row);
    });
  }

  const D = document;

  let queued = false;
  function schedule() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () {
      queued = false;
      fill();
    });
  }

  function watch() {
    const screen = D.getElementById('screen');
    if (!screen) { setTimeout(watch, 120); return; }

    schedule();

    const mo = new MutationObserver(schedule);
    mo.observe(screen, { childList: true, subtree: false });
  }

  if (D.readyState === 'loading') D.addEventListener('DOMContentLoaded', watch);
  else watch();
})();
