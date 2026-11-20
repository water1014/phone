/* desktop.js · 桌面：网格 + 横向翻页 + 长按拖动换位；时钟改为首屏组件 */
(function () {
  const D = document;

  let pagesEl = null;
  let dotsEl = null;
  let dockEl = null;
  let suppressTap = false;

  const PER_PAGE = 8;

  function ensure() {
    const screen = D.getElementById('screen');
    if (!screen || pagesEl) return;
    screen.innerHTML =
      '<div class="desk">' +
        '<div class="desk-pages" id="desk-pages"></div>' +
        '<div class="dots" id="dots"></div>' +
      '</div>' +
      '<nav class="dock" id="dock" aria-label="常用"></nav>';

    pagesEl = D.getElementById('desk-pages');
    dotsEl = D.getElementById('dots');
    dockEl = D.getElementById('dock');
  }

  function order() {
    const all = window.Apps.ALL.map(function (a) { return a.id; });
    const saved = Array.isArray(XW.S.appOrder) ? XW.S.appOrder : [];
    const out = saved.filter(function (id) { return all.indexOf(id) >= 0; });
    all.forEach(function (id) { if (out.indexOf(id) < 0) out.push(id); });
    return out;
  }

  function headFor(index) {
    const W = window.Widgets;
    if (!W) return '';
    if (index === 0) return W.clock() + W.days() + W.stats();
    if (index === 1) return W.calendar() + W.weatherCard() + W.quote();
    return '';
  }

  function iconHtml(app, i) {
    return '<button type="button" class="app-ico" data-app="' + app.id + '" data-idx="' + i + '">' +
        '<i>' + UI.icon(app.icon) + '</i>' +
        '<span>' + app.name + '</span>' +
      '</button>';
  }

  function renderPages() {
    const ids = order();
    const chunks = [];
    for (let i = 0; i < ids.length; i += PER_PAGE) chunks.push(ids.slice(i, i + PER_PAGE));
    if (!chunks.length) chunks.push([]);

    let html = '';
    chunks.forEach(function (list, pageIndex) {
      let cells = '';
      list.forEach(function (id, k) {
        const app = window.Apps.find(id);
        if (app) cells += iconHtml(app, pageIndex * PER_PAGE + k);
      });

      html += '<section class="page">' +
          '<div class="grid">' + headFor(pageIndex) + cells + '</div>' +
        '</section>';
    });

    pagesEl.innerHTML = html;

    let dots = '';
    for (let i = 0; i < chunks.length; i++) dots += '<span' + (i === 0 ? ' class="on"' : '') + '></span>';
    dotsEl.innerHTML = dots;

    if (window.Widgets && window.Widgets.after) window.Widgets.after(pagesEl);
    tick();
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
    const clock = D.getElementById('desk-clock');
    if (!clock) return;
    const date = D.getElementById('desk-date');
    const now = new Date();
    clock.textContent = UI.fmtClock(now);
    if (date) {
      date.textContent = UI.greetWord(now.getHours()) + ' · ' + UI.fmtWeek(now) + ' ' + UI.fmtMonthDay(now);
    }
  }

  function pageWidth() { return Math.max(1, pagesEl.clientWidth); }
  function currentPage() { return Math.round(pagesEl.scrollLeft / pageWidth()); }
  function totalPages() { return pagesEl.querySelectorAll('.page').length || 1; }

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
      if (el) {
        el.classList.remove('dragging');
        el.style.transform = '';
      }
      clearTarget();
      el = null;
      from = -1;
      dragged = false;
    };

    pagesEl.addEventListener('touchstart', function (event) {
      if (!event.touches || event.touches.length !== 1) return;
      const ico = event.target.closest('.app-ico');
      if (!ico) return;
      const t = event.touches[0];
      sx = t.clientX;
      sy = t.clientY;
      dragged = false;
      cancelTimer();
      timer = setTimeout(function () {
        timer = null;
        el = ico;
        from = Number(ico.dataset.idx);
        el.classList.add('dragging');
        if (navigator.vibrate) { try { navigator.vibrate(12); } catch (e) {} }
      }, 450);
    }, { passive: true });

    pagesEl.addEventListener('touchmove', function (event) {
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
      const over = hit ? hit.closest('.app-ico') : null;
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

    pagesEl.addEventListener('touchend', function () {
      cancelTimer();
      if (!el) return;

      if (dragged && target && from >= 0) {
        const ids = order();
        const to = Number(target.dataset.idx);
        if (!isNaN(to) && ids[from] && ids[to]) {
          const tmp = ids[from];
          ids[from] = ids[to];
          ids[to] = tmp;
          XW.S.appOrder = ids;
          XW.save('appOrder');
        }
      }

      reset();
      renderPages();
      suppressTap = true;
    });

    pagesEl.addEventListener('touchcancel', function () {
      cancelTimer();
      reset();
    });
  }

  function bindOpen() {
    D.addEventListener('click', function (event) {
      if (suppressTap) {
        suppressTap = false;
        return;
      }
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

    pagesEl.addEventListener('scroll', function () {
      requestAnimationFrame(syncDots);
    }, { passive: true });

    bindSwipe(pagesEl);
    bindSwipe(dockEl);
    bindDrag();
    bindOpen();

    setInterval(tick, 20000);

    window.addEventListener('resize', function () {
      pagesEl.scrollTo({ left: currentPage() * pageWidth() });
    });
  }

  window.Desktop = { init: init, goPage: goPage, rerender: renderPages };
})();
