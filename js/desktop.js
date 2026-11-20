/* desktop.js · 桌面：通宽内容流 + 隐藏侧栏（分组菜单） + 底部 dock */
(function () {
  const D = document;

  let screenEl = null;
  let suppressTap = false;

  const DOCK = ['chat', 'diary', 'album', 'memory'];

  const RAIL_META = {
    chat: ['CHAT', '回到你们正在说的话'],
    memory: ['MEMORY', '你让我记住的事'],
    diary: ['DIARY', '一天一页，写给以后'],
    album: ['ALBUM', '存在这里的照片'],
    letter: ['LETTER', '没说完的话'],
    music: ['MUSIC', '现在在听什么'],
    calendar: ['CALENDAR', '写过的日子都在上面'],
    plans: ['PLANS', '接下来要做的'],
    accounting: ['LEDGER', '每天花了多少'],
    weather: ['WEATHER', '今天穿什么'],
    mood: ['MOOD', '今天的情绪'],
    health: ['HEALTH', '身体怎么样'],
    cycle: ['CYCLE', '日子与记录'],
    study: ['STUDY', '要背的那些'],
    quotes: ['QUOTES', '挑出来的一句话'],
    moments: ['MOMENTS', '我们最近'],
    favorites: ['SAVED', '想留住的'],
    games: ['GAMES', '一起玩两局'],
    studio: ['STUDIO', '画一张给你'],
    worldbook: ['WORLDBOOK', '我们的设定'],
    windows: ['WINDOWS', '望出去的地方'],
    mcp: ['MCP', '接进来的工具'],
    beautify: ['STYLE', '换个样子'],
    settings: ['SETTINGS', '名字、纪念日、接口']
  };

  const RAIL_GROUPS = [
    { title: '日常', ids: ['chat', 'memory', 'diary', 'album'] },
    { title: '记录', ids: ['calendar', 'plans', 'accounting', 'weather', 'mood', 'health', 'cycle', 'study', 'quotes'] },
    { title: '我们', ids: ['letter', 'music', 'moments', 'favorites', 'games', 'studio'] },
    { title: '其他', ids: ['worldbook', 'windows', 'mcp', 'beautify', 'settings'] }
  ];

  function railHtml() {
    const love = new Date(XW.S.loveDate || '2025-01-01');
    const days = UI.diffDay(love, new Date());

    const body = RAIL_GROUPS.map(function (group) {
      const rows = group.ids.map(function (id) {
        const app = window.Apps.find(id);
        if (!app) return '';
        const meta = RAIL_META[id] || ['', ''];
        return '<button type="button" class="rail-row" data-app="' + id + '">' +
            '<span class="rail-main">' +
              '<span class="rail-name">' + app.name + '<i>' + meta[0] + '</i></span>' +
              '<span class="rail-desc">' + meta[1] + '</span>' +
            '</span>' +
            '<span class="rail-arrow">›</span>' +
          '</button>';
      }).join('');
      return '<div class="rail-group">' +
          '<div class="rail-group-title">' + group.title + '</div>' +
          rows +
        '</div>';
    }).join('');

    return '<div class="rail-head">' +
        '<b>XIAOWO</b>' +
        '<span class="rail-day">第 ' + days + ' 天<em>OUR SPACE</em></span>' +
      '</div>' + body;
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
    const cells = window.Apps.ALL.map(function (app) {
      return '<button type="button" class="appcell" data-app="' + app.id + '">' +
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
    return '<div class="topline">' +
        '<button type="button" class="rail-toggle" data-rail="1" aria-label="打开侧栏">' +
          '<svg viewBox="0 0 24 24" aria-hidden="true">' +
            '<path d="M4 7h13M4 12h13M4 17h13"/>' +
          '</svg>' +
        '</button>' +
      '</div>' +
      W.clock() +
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
      '<div class="scrim" id="scrim" hidden></div>' +
      '<aside class="rail" id="rail">' + railHtml() + '</aside>' +
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

      if (event.target.closest('[data-rail]')) {
        event.preventDefault();
        openRail();
        return;
      }

      if (event.target.closest('[data-more]')) {
        event.preventDefault();
        openDrawer();
        return;
      }

      if (event.target.closest('[data-close]') || event.target.id === 'drawer' || event.target.id === 'scrim') {
        event.preventDefault();
        closeDrawer();
        closeRail();
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
