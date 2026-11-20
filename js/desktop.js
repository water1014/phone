/* desktop.js · 首页四页横滑
   页面内容由 layout.js 的布局表决定，这边只管外壳（侧栏 / dock / 分页点） */
(function () {
  const D = document;

  let screenEl = null;
  let suppressTap = false;

  const DOCK = ['chat', 'diary', 'album', 'memory'];
  const TOTAL = 4;

  const EN = {
    chat: 'CHAT', memory: 'MEMORY', diary: 'DIARY', album: 'ALBUM',
    letter: 'LETTER', music: 'MUSIC', calendar: 'CALENDAR', plans: 'PLANS',
    accounting: 'LEDGER', weather: 'WEATHER', mood: 'MOOD', health: 'HEALTH',
    cycle: 'CYCLE', study: 'STUDY', quotes: 'QUOTES', moments: 'MOMENTS',
    favorites: 'SAVED', games: 'GAMES', studio: 'STUDIO', worldbook: 'WORLD',
    windows: 'WINDOWS', mcp: 'MCP', beautify: 'STYLE', settings: 'SETTINGS'
  };

  const GROUPS = [
    { title: '日常', ids: ['chat', 'memory', 'diary', 'album'] },
    { title: '记录', ids: ['calendar', 'plans', 'accounting', 'weather', 'mood', 'health', 'cycle', 'study', 'quotes'] },
    { title: '我们', ids: ['letter', 'music', 'moments', 'favorites', 'games', 'studio'] },
    { title: '其他', ids: ['worldbook', 'windows', 'mcp', 'beautify', 'settings'] }
  ];

  function pagesHtml() {
    if (window.Layout && Layout.pagesHtml) return Layout.pagesHtml();
    return '';
  }

  function railHtml() {
    const card = (window.Profile && Profile.html) ? Profile.html(true) : '';

    const list = GROUPS.map(function (g) {
      const rows = g.ids.map(function (id) {
        const app = window.Apps.find(id);
        if (!app) return '';
        return '<button type="button" class="rail-row" data-app="' + id + '">' +
            '<b>' + app.name + '</b><i>' + (EN[id] || '') + '</i></button>';
      }).join('');
      return '<div class="rail-grp">' + g.title + '</div>' + rows;
    }).join('');

    return '<div class="rail-profile">' + card + '</div>' +
      '<div class="rail-list">' + list + '</div>' +
      '<div class="rail-rule"></div>' +
      '<button type="button" class="rail-act" data-act="reset">重排首页</button>' +
      '<div class="rail-foot">XIAOWO · OUR SPACE</div>';
  }

  function dockHtml() {
    const items = DOCK.map(function (id) {
      const app = window.Apps.find(id);
      if (!app) return '';
      return '<button type="button" class="dock-item" data-app="' + id + '">' +
          UI.icon(app.icon) + '<span>' + app.name + '</span></button>';
    }).join('');

    return items +
      '<button type="button" class="dock-item" data-more="1">' +
        '<svg viewBox="0 0 24 24" aria-hidden="true">' +
          '<circle cx="6" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="18" cy="12" r="1.3"/>' +
        '</svg><span>全部</span></button>';
  }

  function drawerHtml() {
    const cells = window.Apps.ALL.map(function (app) {
      return '<button type="button" class="appcell" data-app="' + app.id + '">' +
          UI.icon(app.icon) + '<span>' + app.name + '</span></button>';
    }).join('');

    return '<div class="drawer" id="drawer" hidden><div class="drawer-inner">' +
        '<div class="drawer-head"><span class="kicker">ALL APPS</span>' +
          '<button type="button" class="drawer-x" data-close="1">关闭</button></div>' +
        '<div class="drawer-grid">' + cells + '</div></div></div>';
  }

  function dotsHtml() {
    let out = '';
    for (let i = 0; i < TOTAL; i++) out += '<i' + (i === 0 ? ' class="on"' : '') + '></i>';
    return out;
  }

  function renderAll() {
    screenEl.innerHTML =
      '<div class="desk">' +
        '<button type="button" class="rail-toggle overlay" data-rail="1" aria-label="打开"><i></i></button>' +
        '<main class="home" id="home">' + pagesHtml() + '</main>' +
        '<div class="pager" id="pager">' + dotsHtml() + '</div>' +
        '<nav class="dock" id="dock">' + dockHtml() + '</nav>' +
      '</div>' +
      '<div class="scrim" id="scrim" hidden></div>' +
      '<aside class="rail" id="rail">' + railHtml() + '</aside>' +
      drawerHtml();

    if (window.Widgets && window.Widgets.after) window.Widgets.after(screenEl);
    if (window.Layout && window.Layout.bind) window.Layout.bind(screenEl);

    if (window.Profile && Profile.bind) {
      const pf = screenEl.querySelector('#rail .pf');
      if (pf) Profile.bind(pf);
    }

    tick();
    watchPager();
  }

  function watchPager() {
    const home = D.getElementById('home');
    const pager = D.getElementById('pager');
    if (!home || !pager) return;

    home.addEventListener('scroll', function () {
      const width = home.clientWidth || 1;
      const idx = Math.max(0, Math.min(TOTAL - 1, Math.round(home.scrollLeft / width)));
      const dots = pager.children;
      for (let i = 0; i < dots.length; i++) {
        dots[i].classList.toggle('on', i === idx);
      }
    }, { passive: true });
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

  function openRail() {
    const rail = D.getElementById('rail');
    const scrim = D.getElementById('scrim');
    if (scrim) scrim.hidden = false;
    if (rail) rail.classList.add('open');
  }

  function closeRail() {
    const rail = D.getElementById('rail');
    const scrim = D.getElementById('scrim');
    if (rail) rail.classList.remove('open');
    if (scrim) scrim.hidden = true;
  }

  function openDrawer() { const d = D.getElementById('drawer'); if (d) d.hidden = false; }
  function closeDrawer() { const d = D.getElementById('drawer'); if (d) d.hidden = true; }

  function bindOpen() {
    D.addEventListener('click', function (event) {
      if (suppressTap) { suppressTap = false; return; }

      if (event.target.closest('[data-rail]')) { event.preventDefault(); openRail(); return; }
      if (event.target.closest('[data-more]')) { event.preventDefault(); openDrawer(); return; }
      if (event.target.closest('[data-close]') || event.target.id === 'drawer' || event.target.id === 'scrim') {
        event.preventDefault(); closeDrawer(); closeRail(); return;
      }

      const act = event.target.closest('[data-act]');
      if (act) {
        event.preventDefault();
        const what = act.getAttribute('data-act');
        closeRail();
        if (what === 'reset' && window.Layout && Layout.reset) {
          Layout.reset();
          renderAll();
          UI.toast('首页摆回原样');
        }
        return;
      }

      const btn = event.target.closest('[data-app]');
      if (!btn) return;
      event.preventDefault();
      closeDrawer();
      closeRail();
      window.Router.open(btn.dataset.app);
    });
  }

  function bindDockDrag() {
    let timer = null, el = null, from = -1, target = null;
    let sx = 0, sy = 0, dragged = false;

    function stopTimer() { if (timer) { clearTimeout(timer); timer = null; } }
    function clearTarget() { if (target) target.classList.remove('drop-target'); target = null; }
    function reset() {
      if (el) { el.classList.remove('dragging'); el.style.transform = ''; }
      clearTarget(); el = null; from = -1; dragged = false;
    }

    D.addEventListener('touchstart', function (event) {
      if (!event.touches || event.touches.length !== 1) return;
      const item = event.target.closest('.dock-item[data-app]');
      if (!item) return;
      const t = event.touches[0];
      sx = t.clientX; sy = t.clientY; dragged = false;
      stopTimer();
      timer = setTimeout(function () {
        timer = null; el = item;
        from = DOCK.indexOf(item.dataset.app);
        el.classList.add('dragging');
        if (navigator.vibrate) { try { navigator.vibrate(12); } catch (e) {} }
      }, 450);
    }, { passive: true });

    D.addEventListener('touchmove', function (event) {
      const t = event.touches && event.touches[0];
      if (!t) return;
      if (!el) {
        if (Math.abs(t.clientX - sx) > 9 || Math.abs(t.clientY - sy) > 9) stopTimer();
        return;
      }
      event.preventDefault();
      dragged = true;
      el.style.transform = 'translate(' + (t.clientX - sx) + 'px,' + (t.clientY - sy) + 'px) scale(1.08)';

      const hit = D.elementFromPoint(t.clientX, t.clientY);
      const over = hit ? hit.closest('.dock-item[data-app]') : null;
      if (over && over !== el) {
        if (target !== over) { clearTarget(); target = over; target.classList.add('drop-target'); }
      } else if (!over) clearTarget();
    }, { passive: false });

    D.addEventListener('touchend', function () {
      stopTimer();
      if (!el) return;

      if (dragged && target && from >= 0) {
        const to = DOCK.indexOf(target.dataset.app);
        if (to >= 0 && to !== from) {
          const tmp = DOCK[from]; DOCK[from] = DOCK[to]; DOCK[to] = tmp;
          try { XW.S.dockOrder = DOCK.slice(0); XW.save('dockOrder'); } catch (err) {}
        }
      }

      reset();
      if (dragged) { renderAll(); suppressTap = true; }
    });

    D.addEventListener('touchcancel', function () { stopTimer(); reset(); });
  }

  function init() {
    screenEl = D.getElementById('screen');
    if (!screenEl) return;

    const saved = Array.isArray(XW.S.dockOrder) ? XW.S.dockOrder : [];
    if (saved.length === DOCK.length) {
      saved.forEach(function (id, i) { if (DOCK.indexOf(id) >= 0) DOCK[i] = id; });
    }

    renderAll();
    bindDockDrag();
    bindOpen();
    setInterval(tick, 20000);
  }

  window.Desktop = { init: init, goPage: function () {}, rerender: renderAll };
})();
