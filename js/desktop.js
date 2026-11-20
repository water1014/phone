/* desktop.js · 桌面：左栏图标 + 右侧内容流 */
(function () {
  const D = document;

  let screenEl = null;
  let suppressTap = false;

  function order() {
    const all = window.Apps.ALL.map(function (a) { return a.id; });
    const saved = Array.isArray(XW.S.appOrder) ? XW.S.appOrder : [];
    const out = saved.filter(function (id) { return all.indexOf(id) >= 0; });
    all.forEach(function (id) { if (out.indexOf(id) < 0) out.push(id); });
    return out;
  }

  function railHtml() {
    return order().map(function (id, i) {
      const app = window.Apps.find(id);
      if (!app) return '';
      return '<button type="button" class="rail-ico" data-app="' + id + '" data-idx="' + i + '">' +
          UI.icon(app.icon) +
          '<span>' + app.name + '</span>' +
        '</button>';
    }).join('');
  }

  function homeHtml() {
    const W = window.Widgets;
    if (!W) return '';
    return W.clock() + W.days() + W.stats() +
      W.calendar() + W.weatherCard() + W.quote() +
      W.memoryCard() + W.quota();
  }

  function renderAll() {
    screenEl.innerHTML =
      '<div class="desk">' +
        '<aside class="rail" id="rail">' + railHtml() + '</aside>' +
        '<main class="home" id="home"><div class="grid">' + homeHtml() + '</div></main>' +
      '</div>';

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
      const ico = event.target.closest('.rail-ico');
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

    D.addEventListener('touchmove', function (event) {
      const t = event.touches && event.touches[0];
      if (!t) return;

      if (!el) {
        if (Math.abs(t.clientX - sx) > 9 || Math.abs(t.clientY - sy) > 9) cancelTimer();
        return;
      }

      event.preventDefault();
      dragged = true;
      el.style.transform = 'translate(' + (t.clientX - sx) + 'px,' + (t.clientY - sy) + 'px) scale(1.1)';

      const hit = D.elementFromPoint(t.clientX, t.clientY);
      const over = hit ? hit.closest('.rail-ico') : null;
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
      renderAll();
      suppressTap = true;
    });

    D.addEventListener('touchcancel', function () {
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
    screenEl = D.getElementById('screen');
    if (!screenEl) return;
    renderAll();
    bindDrag();
    bindOpen();
    setInterval(tick, 20000);
  }

  window.Desktop = { init: init, goPage: function () {}, rerender: renderAll };
})();
