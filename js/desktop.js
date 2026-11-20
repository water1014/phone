/* desktop.js · 桌面：手账首屏（天数/月历/摘句）+ 图标页 + dock
   第一页只放“今天”，图标从第二页起。横向 snap 翻页。 */
(function () {
  const D = document;

  let pagesEl = null;
  let dotsEl = null;
  let dockEl = null;
  let clockEl = null;
  let dateEl = null;

  function ensure() {
    const screen = D.getElementById('screen');
    if (!screen || pagesEl) return;
    screen.innerHTML =
      '<div class="desk">' +
        '<header class="desk-head">' +
          '<div class="desk-clock" id="desk-clock">--:--</div>' +
          '<div class="desk-date" id="desk-date"></div>' +
        '</header>' +
        '<div class="desk-pages" id="desk-pages"></div>' +
        '<div class="dots" id="dots"></div>' +
      '</div>' +
      '<nav class="dock" id="dock" aria-label="常用"></nav>';

    pagesEl = D.getElementById('desk-pages');
    dotsEl = D.getElementById('dots');
    dockEl = D.getElementById('dock');
    clockEl = D.getElementById('desk-clock');
    dateEl = D.getElementById('desk-date');
  }

  function daysWidgetHtml() {
    const love = new Date(XW.S.loveDate || '2025-01-01');
    const days = UI.diffDay(love, new Date());
    return '<section class="wdg wdg-days">' +
        '<div class="kicker">TOGETHER</div>' +
        '<div class="wdg-days">' + days + '<small>DAYS</small></div>' +
        '<div class="wdg-names">' + UI.esc(XW.S.hisName) + ' &amp; ' + UI.esc(XW.S.herName) + '</div>' +
        '<div class="wdg-sub">SINCE ' + UI.fmtYmd(love) + '</div>' +
      '</section>';
  }

  function iconHtml(app) {
    return '<button type="button" class="app-ico" data-app="' + app.id + '">' +
        '<i>' + UI.icon(app.icon) + '</i>' +
        '<span>' + app.name + '</span>' +
      '</button>';
  }

  function renderPages() {
    const groups = window.Apps.pages();

    let html = '<section class="page page-today">' +
        daysWidgetHtml() +
        '<nav class="grid"></nav>' +
      '</section>';

    groups.forEach(function (list) {
      html += '<section class="page"><nav class="grid">' + list.map(iconHtml).join('') + '</nav></section>';
    });

    pagesEl.innerHTML = html;

    const count = groups.length + 1;
    let dots = '';
    for (let i = 0; i < count; i++) dots += '<span' + (i === 0 ? ' class="on"' : '') + '></span>';
    dotsEl.innerHTML = dots;
  }

  function renderDock() {
    dockEl.innerHTML = window.Apps.DOCK.map(function (id) {
      const app = window.Apps.find(id);
      if (!app) return '';
      return '<button type="button" data-app="' + app.id + '">' +
          UI.icon(app.icon) +
          '<span>' + app.name + '</span>' +
        '</button>';
    }).join('');
  }

  function tick() {
    if (!clockEl) return;
    const now = new Date();
    clockEl.textContent = UI.fmtClock(now);
    dateEl.textContent = UI.greetWord(now.getHours()) + ' · ' + UI.fmtWeek(now) + ' ' + UI.fmtMonthDay(now);
  }

  function pageWidth() {
    return Math.max(1, pagesEl.clientWidth);
  }

  function currentPage() {
    return Math.round(pagesEl.scrollLeft / pageWidth());
  }

  function totalPages() {
    return pagesEl.querySelectorAll('.page').length || 1;
  }

  function goPage(index) {
    const next = Math.min(totalPages() - 1, Math.max(0, index));
    pagesEl.scrollTo({ left: next * pageWidth(), behavior: 'smooth' });
  }

  function syncDots() {
    if (!dotsEl) return;
    const index = currentPage();
    Array.prototype.forEach.call(dotsEl.children, function (dot, i) {
      dot.classList.toggle('on', i === index);
    });
  }

  function bindSwipe(el) {
    let start = null;
    let swallow = false;

    el.addEventListener('touchstart', function (event) {
      if (!event.touches || event.touches.length !== 1) { start = null; return; }
      const t = event.touches[0];
      start = { x: t.clientX, y: t.clientY };
      swallow = false;
    }, { passive: true });

    el.addEventListener('touchmove', function (event) {
      if (!start) return;
      const t = event.touches[0];
      if (!t) return;
      const dx = t.clientX - start.x;
      const dy = t.clientY - start.y;
      if (Math.abs(dx) > 12 && Math.abs(dx) > Math.abs(dy)) swallow = true;
    }, { passive: true });

    el.addEventListener('touchend', function (event) {
      if (!start || !event.changedTouches || event.changedTouches.length !== 1) { start = null; return; }
      const t = event.changedTouches[0];
      const dx = t.clientX - start.x;
      const dy = t.clientY - start.y;
      start = null;
      if (Math.abs(dx) < 42 || Math.abs(dx) < Math.abs(dy) * 1.2) return;
      event.preventDefault();
      goPage(currentPage() + (dx < 0 ? 1 : -1));
    }, { passive: false });

    el.addEventListener('click', function (event) {
      if (!swallow) return;
      swallow = false;
      event.preventDefault();
      event.stopPropagation();
    }, true);
  }

  function bindOpen() {
    D.addEventListener('click', function (event) {
      const btn = event.target.closest('[data-app]');
      if (!btn) return;
      event.preventDefault();
      window.Router.open(btn.dataset.app);
    });
  }

  function init() {
    ensure();
    renderPages();
    renderDock();
    tick();

    pagesEl.addEventListener('scroll', function () {
      requestAnimationFrame(syncDots);
    }, { passive: true });

    bindSwipe(pagesEl);
    bindSwipe(dockEl);
    bindOpen();

    window.addEventListener('resize', function () {
      pagesEl.scrollTo({ left: currentPage() * pageWidth() });
    });
  }

  window.Desktop = { init: init, goPage: goPage, rerender: renderPages };
})();
