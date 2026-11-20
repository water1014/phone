/* desktop.js · 桌面：通宽单列内容流 + 底部 dock */
(function () {
  const D = document;

  let screenEl = null;
  let suppressTap = false;

  const DOCK = ['chat', 'diary', 'album', 'memory'];

  function order() {
    const all = window.Apps.ALL.map(function (a) { return a.id; });
    const saved = Array.isArray(XW.S.appOrder) ? XW.S.appOrder : [];
    const out = saved.filter(function (id) { return all.indexOf(id) >= 0; });
    all.forEach(function (id) { if (out.indexOf(id) < 0) out.push(id); });
    return out;
  }

  function dockHtml() {
    const items = DOCK.map(function (id) {
      const app = window.Apps.find(id);
      if (!app) return '';
      return '<button type="button" class="dock-item" data-app="' + id + '">' +
          UI.icon(app.icon) +
          '<span>' + app.name + '</span>' +
        '</button>';
    }).join('');

    return items +
      '<button type="button" class="dock-item" data-more="1">' +
        '<svg viewBox="0 0 24 24" aria-hidden="true">' +
          '<circle cx="6" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="18" cy="12" r="1.3"/>' +
        '</svg>' +
        '<span>全部</span>' +
      '</button>';
  }

  function drawerHtml() {
    const cells = order().map(function (id) {
      const app = window.Apps.find(id);
      if (!app) return '';
      return '<button type="button" class="appcell" data-app="' + id + '">' +
          UI.icon(app.icon) +
          '<span>' + app.name + '</span>' +
        '</button>';
    }).join('');

    return '<div class="drawer" id="drawer" hidden>' +
        '<div class="drawer-inner">' +
          '<div class="drawer-head">' +
            '<span class="kicker">ALL APPS</span>' +
            '<button type="button" class="drawer-x" data-close="1">关闭</button>' +
          '</div>' +
          '<div class="drawer-grid">' + cells + '</div>' +
        '</div>' +
      '</div>';
  }

  function homeHtml() {
    const W = window.Widgets;
    if (!W) return '';
    return W.clock() +
      W.days() +
      W.trio() +
      W.calendar() +
      '<div class="pair">' + W.weatherCard() + W.quota() + '</div>' +
      W.quote() +
      W.rows();
  }

  function renderAll() {
    screenEl.innerHTML =
      '<div class="desk">' +
        '<main class="home" id="home"><div class="grid">' + homeHtml() + '</div></main>' +
        '<nav class="dock" id="dock">' + dockHtml() + '</nav>' +
      '</div>' +
      drawerHtml();

    if (window.Widgets && window.Widgets.after) window.Widgets.after(screenEl);
    tick();
  }

  function tick() {
    const clock = D.getElementById('desk-clock');
    if (!clock) return;
    const date = D.getElementById('desk-date');
    const now = new Date();
    clock.textContent = UI.fmtClock(now);
    if (date) {
      date.textContent = UI.greetWord(now.getHours()) + ' · ' + UI.fmtWeek(now) + ' ' + UI.fmtMonthDay(now);
    }
  }

  function openDrawer() {
    const drawer = D.getElementById('drawer');
    if (drawer) drawer.hidden = false;
  }

  function closeDrawer() {
    const drawer = D.getElementById('drawer');
    if (drawer) drawer.hidden = true;
  }

  function bindOpen() {
    D.addEventListener('click', function (event) {
      if (suppressTap) {
        suppressTap = false;
        return;
      }

      if (event.target.closest('[data-more]')) {
        event.preventDefault();
        openDrawer();
        return;
      }

      if (event.target.closest('[data-close]') || event.target.id === 'drawer') {
        event.preventDefault();
        closeDrawer();
        return;
      }

      const btn = event.target.closest('[data-app]');
      if (!btn) return;
      event.preventDefault();
      closeDrawer();
      window.Router.open(btn.dataset.app);
    });
  }

  function bindDrag() {
    let timer = null;
    let el = null;
    let from = -1;
    let target = null;
    let sx = 0;
    let sy = 0;
    let dragged = false;

    const cancelTimer = function () {
      if (timer) { clearTimeout(timer); timer = null; }
    };
    const clearTarget = function () {
      if (target) target.classList.remove('drop-target');
      target = null;
    };
    const reset = function () {
      if (el) { el.classList.remove('dragging'); el.style.transform = ''; }
      clearTarget();
      el = null;
      from = -1;
      dragged = false;
    };

    D.addEventListener('touchstart', function (event) {
      if (!event.touches || event.touches.length !== 1) return;
      const item = event.target.closest('.dock-item[data-app]');
      if (!item) return;
      const t = event.touches[0];
      sx = t.clientX;
      sy = t.clientY;
      dragged = false;
      cancelTimer();
      timer = setTimeout(function () {
        timer = null;
        el = item;
        from = DOCK.indexOf(item.dataset.app);
        el.classList.add('dragging');
        if (navigator.vibrate) { try { navigator.vibrate(12); } catch (e) {} }
      }, 450);
    }, { passive: true });

    D.addEventListener('touchmove', function (event) {
      const t = event.touches && event.touches[0];
      if (!t) return;

      if (!el) {
        if (Math.abs(t.clientX - sx) > 9 || Math.abs(t.clientY - sy) > 9) cancelTimer();
        return;
      }

      event.preventDefault();
      dragged = true;
      el.style.transform = 'translate(' + (t.clientX - sx) + 'px,' + (t.clientY - sy) + 'px) scale(1.08)';

      const hit = D.elementFromPoint(t.clientX, t.clientY);
      const over = hit ? hit.closest('.dock-item[data-app]') : null;
      if (over && over !== el) {
        if (target !== over) {
          clearTarget();
          target = over;
          target.classList.add('drop-target');
        }
      } else if (!over) {
        clearTarget();
      }
    }, { passive: false });

    D.addEventListener('touchend', function () {
      cancelTimer();
      if (!el) return;

      if (dragged && target && from >= 0) {
        const to = DOCK.indexOf(target.dataset.app);
        if (to >= 0 && to !== from) {
          const tmp = DOCK[from];
          DOCK[from] = DOCK[to];
          DOCK[to] = tmp;
          try {
            XW.S.dockOrder = DOCK.slice(0);
            XW.save('dockOrder');
          } catch (err) { console.warn('[dock] save failed', err); }
        }
      }

      reset();
      if (dragged) { renderAll(); suppressTap = true; }
    });

    D.addEventListener('touchcancel', function () {
      cancelTimer();
      reset();
    });
  }

  function init() {
    screenEl = D.getElementById('screen');
    if (!screenEl) return;

    const saved = Array.isArray(XW.S.dockOrder) ? XW.S.dockOrder : [];
    if (saved.length === DOCK.length) {
      saved.forEach(function (id, i) { if (DOCK.indexOf(id) >= 0) DOCK[i] = id; });
    }

    renderAll();
    bindDrag();
    bindOpen();
    setInterval(tick, 20000);
  }

  window.Desktop = { init: init, goPage: function () {}, rerender: renderAll };
})();
