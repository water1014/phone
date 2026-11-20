/* layout.js · 首页布局表 + dock
   1) 每页一个四列网格，组件与 App 都是网格上的块
   2) 长按一块 → 编辑态（整桌轻抖），此时拖任何一块都直接跟手
   3) dock 里的 App 也能长按拖：在 dock 内换位、拖进页面、页面拖进 dock
   4) 自制小组件在编辑态下左上角有 × */
(function () {
  const D = document;
  const K = 'xw_layout';
  const DK = 'xw_dock';
  const DOCK_DEF = ['chat', 'diary', 'album', 'memory'];

  const SPAN = {
    collage: 4, profile: 4, days: 4, quote: 4,
    clock: 4, wx: 2, quota: 2, cal: 4, now: 4
  };

  const DEF = [
    ['collage', 'days', 'quote'],
    ['clock', 'wx', 'quota',
      'app:calendar', 'app:plans', 'app:accounting', 'app:mood',
      'app:health', 'app:cycle', 'app:study', 'app:quotes'],
    ['cal', 'now',
      'app:letter', 'app:music', 'app:moments', 'app:favorites',
      'app:games', 'app:studio', 'app:worldbook', 'app:windows'],
    ['app:weather', 'app:mcp', 'app:beautify', 'app:settings']
  ];

  let st = null;
  let dst = null;
  let justDragged = false;
  let editing = false;

  function modId(k) {
    return (typeof k === 'string' && k.indexOf('mod:') === 0) ? k.slice(4) : '';
  }

  function valid(k) {
    if (SPAN[k] !== undefined) return true;
    if (typeof k !== 'string') return false;
    if (k.indexOf('app:') === 0) return !!window.Apps.find(k.slice(4));
    if (k.indexOf('mod:') === 0) return !!(window.Mods && Mods.find(k.slice(4)));
    return false;
  }

  function spanOf(k) {
    if (SPAN[k]) return SPAN[k];
    const id = modId(k);
    if (id && window.Mods) return Number(Mods.span(id)) || 2;
    return 1;
  }

  function copy(src) {
    return src.map(function (p) { return p.slice(0); });
  }

  function read() {
    let saved = null;
    try {
      const raw = localStorage.getItem(K);
      if (raw) saved = JSON.parse(raw);
    } catch (e) { saved = null; }

    if (!Array.isArray(saved) || !saved.length) return copy(DEF);

    const cleaned = saved.map(function (p) {
      if (!Array.isArray(p)) return [];
      return p.map(function (k) { return k === 'profile' ? 'days' : k; })
        .filter(function (k) {
          if (typeof k !== 'string') return false;
          if (k.indexOf('mod:') === 0) return valid(k);
          return true;
        });
    });

    for (let i = 0; i < cleaned.length; i++) {
      for (let j = 0; j < cleaned[i].length; j++) {
        const k = cleaned[i][j];
        if (k.indexOf('mod:') === 0) continue;
        if (!valid(k)) return copy(DEF);
      }
    }

    return cleaned;
  }

  function write(list) {
    try { localStorage.setItem(K, JSON.stringify(list)); } catch (e) {}
  }

  /* ============ dock 顺序 ============ */

  function dockOrder() {
    let arr = null;
    try {
      const raw = localStorage.getItem(DK);
      arr = raw ? JSON.parse(raw) : null;
    } catch (e) { arr = null; }

    if (!Array.isArray(arr) || !arr.length) arr = DOCK_DEF.slice(0);

    return arr.filter(function (id) { return !!window.Apps.find(id); });
  }

  function setDockOrder(arr) {
    const clean = arr.filter(function (id) { return !!window.Apps.find(id); });
    try { localStorage.setItem(DK, JSON.stringify(clean)); } catch (e) {}
    try { if (window.XW) { XW.S.dockOrder = clean.slice(0); XW.save('dockOrder'); } } catch (e) {}
  }

  function applyDockOrder(root) {
    const dock = root && root.querySelector ? root.querySelector('#dock') : D.getElementById('dock');
    if (!dock) return;

    const order = dockOrder();
    const more = dock.querySelector('[data-more]');

    Array.prototype.forEach.call(dock.querySelectorAll('.dock-item[data-app]'), function (b) {
      if (order.indexOf(b.getAttribute('data-app')) < 0 && b.parentNode) {
        b.parentNode.removeChild(b);
      }
    });

    order.forEach(function (id) {
      let btn = dock.querySelector('.dock-item[data-app="' + id + '"]');

      if (!btn) {
        const app = window.Apps.find(id);
        if (!app) return;
        btn = D.createElement('button');
        btn.type = 'button';
        btn.className = 'dock-item';
        btn.setAttribute('data-app', id);
        btn.innerHTML = UI.icon(app.icon) + '<span>' + app.name + '</span>';
      }

      dock.appendChild(btn);
    });

    if (more) dock.appendChild(more);
  }

  /* ============ 数据层的各种换法 ============ */

  function swapPageKeys(aKey, bKey) {
    if (aKey === bKey) return false;

    const list = read();
    let done = false;

    list.forEach(function (p) {
      const i = p.indexOf(aKey);
      const j = p.indexOf(bKey);
      if (i >= 0 && j >= 0) { p[i] = bKey; p[j] = aKey; done = true; return; }
      if (i >= 0) { p[i] = bKey; done = true; }
      if (j >= 0) { p[j] = aKey; done = true; }
    });

    if (done) write(list);
    return done;
  }

  function moveKeyToPageEnd(key, pageIndex) {
    const list = read();
    let found = false;

    list.forEach(function (p) {
      const i = p.indexOf(key);
      if (i >= 0) { p.splice(i, 1); found = true; }
    });

    if (!found) return false;

    while (list.length <= pageIndex) list.push([]);
    list[pageIndex].push(key);
    write(list);
    return true;
  }

  /* 页面上的 app:X 与 dock 里的 Y 对调 */
  function swapPageDock(giKey, dockId) {
    if (typeof giKey !== 'string' || giKey.indexOf('app:') !== 0) return false;

    const x = giKey.slice(4);
    if (x === dockId) return false;

    const order = dockOrder();
    const j = order.indexOf(dockId);
    if (j < 0) return false;

    const list = read();
    let hit = false;

    list.forEach(function (p) {
      const i = p.indexOf(giKey);
      if (i >= 0) { p[i] = 'app:' + dockId; hit = true; }
    });

    if (!hit) return false;

    order[j] = x;
    setDockOrder(order);
    write(list);
    return true;
  }

  /* 页面上的 app:X 拖到 dock 空白 → 进 dock 末尾 */
  function pageToDockEnd(giKey) {
    if (typeof giKey !== 'string' || giKey.indexOf('app:') !== 0) return false;

    const x = giKey.slice(4);
    const order = dockOrder();
    if (order.indexOf(x) >= 0) return false;
    if (order.length >= 6) return false;

    const list = read();
    let hit = false;

    list.forEach(function (p) {
      const i = p.indexOf(giKey);
      if (i >= 0) { p.splice(i, 1); hit = true; }
    });

    if (!hit) return false;

    order.push(x);
    setDockOrder(order);
    write(list);
    return true;
  }

  /* dock 里的 Y 拖到页面空白 → 从 dock 拿出，落到那一页末尾 */
  function dockToPageEnd(dockId, pageIndex) {
    const order = dockOrder();
    if (order.indexOf(dockId) < 0) return false;

    setDockOrder(order.filter(function (x) { return x !== dockId; }));

    const list = read();
    while (list.length <= pageIndex) list.push([]);

    const key = 'app:' + dockId;
    if (list[pageIndex].indexOf(key) < 0) list[pageIndex].push(key);
    write(list);
    return true;
  }

  /* dock 里的 Y 拖到页面上某块 → 那块是 App 就换；是组件就把 Y 插在它前面 */
  function dockToPageKey(dockId, giKey) {
    if (giKey.indexOf('app:') === 0) return swapPageDock(giKey, dockId);

    const list = read();
    let done = false;

    list.forEach(function (p) {
      const i = p.indexOf(giKey);
      if (i >= 0) { p.splice(i, 0, 'app:' + dockId); done = true; }
    });

    if (!done) return false;

    setDockOrder(dockOrder().filter(function (x) { return x !== dockId; }));
    write(list);
    return true;
  }

  function swapDock(a, b) {
    if (a === b) return false;

    const order = dockOrder();
    const i = order.indexOf(a);
    const j = order.indexOf(b);
    if (i < 0 || j < 0 || i === j) return false;

    const t = order[i];
    order[i] = order[j];
    order[j] = t;
    setDockOrder(order);
    return true;
  }

  /* ============ 渲染 ============ */

  function htmlOf(k) {
    const W = window.Widgets || {};

    const mid = modId(k);
    if (mid) return window.Mods ? Mods.html(mid) : '';

    if (k === 'collage') return (window.Collage && Collage.html) ? Collage.html() : '';
    if (k === 'profile') return (window.Profile && Profile.html) ? Profile.html() : '';
    if (k === 'days') return (window.DayCard && DayCard.html) ? DayCard.html() : '';
    if (k === 'quote') return W.quote ? W.quote() : '';
    if (k === 'clock') return W.clock ? W.clock() : '';
    if (k === 'wx') return W.weatherCard ? W.weatherCard() : '';
    if (k === 'quota') return W.quota ? W.quota() : '';
    if (k === 'cal') return W.calendar ? W.calendar() : '';
    if (k === 'now') return W.nowPlaying ? W.nowPlaying() : '';

    if (k.indexOf('app:') === 0) {
      const app = window.Apps.find(k.slice(4));
      if (!app) return '';
      return '<button type="button" class="appcell" data-app="' + app.id + '">' +
        UI.icon(app.icon) + '<span>' + app.name + '</span></button>';
    }

    return '';
  }

  function pagesHtml() {
    return read().map(function (keys, i) {
      const inner = keys.map(function (k) {
        const h = htmlOf(k);
        if (!h) return '';
        return '<div class="gi gi' + spanOf(k) + '" data-key="' + k + '">' + h + '</div>';
      }).join('');

      return '<section class="page gpage" data-page="' + i + '">' + inner + '</section>';
    }).join('');
  }

  function homeEl() { return D.getElementById('home'); }

  /* ============ 编辑态 ============ */

  function hint(on) {
    let el = D.getElementById('edit-hint');
    if (!on) {
      if (el && el.parentNode) el.parentNode.removeChild(el);
      return;
    }
    if (el) return;
    el = D.createElement('div');
    el.id = 'edit-hint';
    el.textContent = '拖动摆位置 · 点空白结束';
    D.body.appendChild(el);
  }

  function markDel() {
    const home = homeEl();
    if (!home) return;

    Array.prototype.forEach.call(home.querySelectorAll('.gi-del'), function (b) {
      if (b.parentNode) b.parentNode.removeChild(b);
    });

    if (!editing) return;

    Array.prototype.forEach.call(home.querySelectorAll('.gi[data-key^="mod:"]'), function (gi) {
      const b = D.createElement('button');
      b.type = 'button';
      b.className = 'gi-del';
      b.textContent = '×';
      b.setAttribute('aria-label', '删掉这个');
      gi.appendChild(b);
    });
  }

  function enterEdit() {
    if (editing) return;
    editing = true;
    const home = homeEl();
    if (home) home.classList.add('editing');
    hint(true);
    markDel();
  }

  function exitEdit() {
    if (!editing) return;
    editing = false;
    const home = homeEl();
    if (home) home.classList.remove('editing');
    hint(false);
    markDel();
  }

  /* ============ 落点 ============ */

  function pageAt(home, i) {
    const pages = home.querySelectorAll('.page');
    if (!pages.length) return null;
    const idx = Math.max(0, Math.min(pages.length - 1, i));
    return pages[idx];
  }

  function currentIndex(home) {
    const w = home.clientWidth || 1;
    const pages = home.querySelectorAll('.page');
    const i = Math.round(home.scrollLeft / w);
    return Math.max(0, Math.min(pages.length - 1, i));
  }

  function giAt(x, y, skip) {
    const home = homeEl();
    if (!home) return null;

    const pg = pageAt(home, currentIndex(home));
    if (!pg) return null;

    let best = null;
    let score = Infinity;

    Array.prototype.forEach.call(pg.querySelectorAll('.gi'), function (gi) {
      if (skip && gi === skip) return;
      const r = gi.getBoundingClientRect();
      if (!r.width && !r.height) return;

      const dx = Math.max(r.left - x, 0, x - r.right);
      const dy = Math.max(r.top - y, 0, y - r.bottom);
      const d = Math.sqrt(dx * dx + dy * dy);

      if (d < score) { score = d; best = gi; }
    });

    if (best && score <= 140) return best;
    return null;
  }

  function dockAt(x, y) {
    const dock = D.getElementById('dock');
    if (!dock) return null;

    const r = dock.getBoundingClientRect();
    if (!r.width) return null;
    if (x < r.left - 8 || x > r.right + 8 || y < r.top - 8 || y > r.bottom + 8) return null;

    let best = null;
    let score = Infinity;

    Array.prototype.forEach.call(dock.querySelectorAll('.dock-item[data-app]'), function (b) {
      const br = b.getBoundingClientRect();
      const d = Math.abs(x - (br.left + br.right) / 2) + Math.abs(y - (br.top + br.bottom) / 2);
      if (d < score) { score = d; best = b; }
    });

    return { zone: true, item: best };
  }

  function hitTest(x, y, skip) {
    const gi = giAt(x, y, skip);
    if (gi) return { kind: 'gi', el: gi };

    const dk = dockAt(x, y);
    if (dk) return { kind: 'dock', item: dk.item };

    return null;
  }

  function sigOf(hit) {
    if (!hit) return '';
    if (hit.kind === 'gi') return 'gi:' + hit.el.getAttribute('data-key');
    return 'dock:' + (hit.item ? hit.item.getAttribute('data-app') : '_end');
  }

  function clearMarks() {
    Array.prototype.forEach.call(D.querySelectorAll('.dc-drop'), function (el) {
      el.classList.remove('dc-drop');
    });
    Array.prototype.forEach.call(D.querySelectorAll('.drop-target'), function (el) {
      el.classList.remove('drop-target');
    });
    const dock = D.getElementById('dock');
    if (dock) dock.classList.remove('dock-drop');
  }

  function paintHit(hit) {
    clearMarks();
    if (!hit) return;

    const dock = D.getElementById('dock');

    if (hit.kind === 'gi') {
      hit.el.classList.add('dc-drop');
      if (dock) dock.classList.add('dock-drop');
      return;
    }

    if (dock) dock.classList.add('dock-drop');
    if (hit.item) hit.item.classList.add('drop-target');
  }

  /* ============ 页面块拖动 ============ */

  function onStart(ev) {
    if (!ev.touches || ev.touches.length !== 1) return;
    const home = homeEl();
    if (!home) return;

    const item = ev.target.closest ? ev.target.closest('.gi') : null;
    if (!item) return;

    const t = ev.touches[0];
    st = {
      kind: 'page',
      item: item,
      home: home,
      sx: t.clientX, sy: t.clientY,
      lx: t.clientX, ly: t.clientY,
      active: false,
      hit: null,
      sig: '',
      side: 0,
      flipped: false,
      target: -1,
      timer: null,
      edge: null
    };

    if (editing) {
      lift(st);
      return;
    }

    st.timer = setTimeout(function () {
      if (!st) return;
      st.timer = null;
      enterEdit();
      lift(st);
    }, 420);
  }

  function lift(s) {
    s.active = true;
    s.item.classList.add('lift');
    if (s.home) s.home.classList.add('dragging');
    else D.body.classList.add('dragging');
    if (navigator.vibrate) { try { navigator.vibrate(12); } catch (e) {} }
  }

  function trackHit(s, x, y, skip) {
    const hit = hitTest(x, y, skip);
    const sig = sigOf(hit);

    s.hit = hit;
    if (sig !== s.sig) {
      s.sig = sig;
      paintHit(hit);
    }
  }

  function onMove(ev) {
    if (!st) return;
    const t = ev.touches && ev.touches[0];
    if (!t) return;

    st.lx = t.clientX;
    st.ly = t.clientY;

    if (!st.active) {
      if (Math.abs(t.clientX - st.sx) > 9 || Math.abs(t.clientY - st.sy) > 9) {
        clearTimeout(st.timer);
        st = null;
      }
      return;
    }

    ev.preventDefault();

    st.item.style.transform =
      'translate(' + (t.clientX - st.sx) + 'px,' + (t.clientY - st.sy) + 'px) scale(1.05)';

    trackHit(st, t.clientX, t.clientY, st.item);

    const w = st.home.clientWidth || 1;
    const side = t.clientX < 30 ? -1 : (t.clientX > w - 30 ? 1 : 0);

    if (side !== st.side) {
      st.side = side;
      if (st.edge) { clearTimeout(st.edge); st.edge = null; }
      if (side) {
        st.edge = setTimeout(function () {
          if (!st) return;
          st.edge = null;
          flip(side);
        }, 360);
      }
    }
  }

  function flip(dir) {
    if (!st) return;

    const home = st.home;
    const w = home.clientWidth || 1;
    const total = home.querySelectorAll('.page').length;
    const cur = currentIndex(home);
    const next = Math.max(0, Math.min(total - 1, cur + dir));
    if (next === cur) return;

    st.flipped = true;
    st.target = next;
    home.scrollTo({ left: next * w, behavior: 'smooth' });
    if (navigator.vibrate) { try { navigator.vibrate(8); } catch (e) {} }
  }

  function endPage(s) {
    const key = s.item.getAttribute('data-key');
    const pageIdx = currentIndex(s.home);
    const hit = s.hit;
    let changed = false;

    if (hit && hit.kind === 'gi') {
      if (hit.el !== s.item) changed = swapPageKeys(key, hit.el.getAttribute('data-key'));
    } else if (hit && hit.kind === 'dock') {
      if (hit.item) changed = swapPageDock(key, hit.item.getAttribute('data-app'));
      else changed = pageToDockEnd(key);
    } else {
      changed = moveKeyToPageEnd(key, pageIdx);
    }

    return changed;
  }

  function onEnd() {
    if (!st) return;

    const s = st;
    st = null;

    if (s.timer) clearTimeout(s.timer);
    if (s.edge) clearTimeout(s.edge);

    if (!s.active) return;

    s.item.classList.remove('lift');
    s.item.style.transform = '';
    s.home.classList.remove('dragging');
    clearMarks();

    const changed = endPage(s);

    justDragged = true;
    setTimeout(function () { justDragged = false; }, 380);

    if (changed) {
      if (navigator.vibrate) { try { navigator.vibrate(8); } catch (e) {} }
      rerender();
    }
  }

  /* ============ dock 拖动 ============ */

  function startDock(ev, item) {
    const t = ev.touches[0];
    const home = homeEl();

    dst = {
      kind: 'dock',
      id: item.getAttribute('data-app'),
      item: item,
      home: home,
      sx: t.clientX, sy: t.clientY,
      lx: t.clientX, ly: t.clientY,
      active: false,
      hit: null,
      sig: '',
      side: 0,
      timer: null,
      edge: null
    };

    dst.timer = setTimeout(function () {
      if (!dst) return;
      dst.timer = null;
      dst.active = true;
      dst.item.classList.add('dk-lift');
      if (home) home.classList.add('dragging');
      if (navigator.vibrate) { try { navigator.vibrate(12); } catch (e) {} }
    }, 420);
  }

  function dockMove(ev) {
    if (!dst) return;

    const t = ev.touches && ev.touches[0];
    if (!t) return;

    dst.lx = t.clientX;
    dst.ly = t.clientY;

    if (!dst.active) {
      if (Math.abs(t.clientX - dst.sx) > 9 || Math.abs(t.clientY - dst.sy) > 9) {
        clearTimeout(dst.timer);
        dst = null;
      }
      return;
    }

    ev.preventDefault();

    dst.item.style.transform =
      'translate(' + (t.clientX - dst.sx) + 'px,' + (t.clientY - dst.sy) + 'px) scale(1.1)';

    trackHit(dst, t.clientX, t.clientY, null);

    const home = dst.home;
    if (!home) return;

    const w = home.clientWidth || 1;
    const side = t.clientX < 30 ? -1 : (t.clientX > w - 30 ? 1 : 0);

    if (side !== dst.side) {
      dst.side = side;
      if (dst.edge) { clearTimeout(dst.edge); dst.edge = null; }
      if (side) {
        dst.edge = setTimeout(function () {
          if (!dst) return;
          dst.edge = null;
          const cur = currentIndex(home);
          const total = home.querySelectorAll('.page').length;
          const next = Math.max(0, Math.min(total - 1, cur + side));
          if (next !== cur) {
            home.scrollTo({ left: next * w, behavior: 'smooth' });
            if (navigator.vibrate) { try { navigator.vibrate(8); } catch (err) {} }
          }
        }, 420);
      }
    }
  }

  function dockEnd() {
    if (!dst) return;

    const s = dst;
    dst = null;

    if (s.timer) clearTimeout(s.timer);
    if (s.edge) clearTimeout(s.edge);

    if (!s.active) return;

    s.item.classList.remove('dk-lift');
    s.item.style.transform = '';
    if (s.home) s.home.classList.remove('dragging');
    clearMarks();

    const hit = s.hit;
    const pageIdx = s.home ? currentIndex(s.home) : 0;
    let changed = false;

    if (hit && hit.kind === 'dock') {
      if (hit.item) changed = swapDock(s.id, hit.item.getAttribute('data-app'));
      else changed = true;
    } else if (hit && hit.kind === 'gi') {
      changed = dockToPageKey(s.id, hit.el.getAttribute('data-key'));
    } else {
      changed = dockToPageEnd(s.id, pageIdx);
    }

    justDragged = true;
    setTimeout(function () { justDragged = false; }, 380);

    if (changed) {
      if (navigator.vibrate) { try { navigator.vibrate(8); } catch (e) {} }
      rerender();
    }
  }

  /* ============ 全局事件 ============ */

  D.addEventListener('touchstart', function (e) {
    if (e.touches && e.touches.length !== 1) return;
    const item = e.target.closest ? e.target.closest('.dock-item[data-app]') : null;
    if (!item) return;

    e.stopPropagation();
    startDock(e, item);
  }, { passive: true, capture: true });

  D.addEventListener('touchmove', function (e) {
    if (!dst) return;
    dockMove(e);
  }, { passive: false });

  D.addEventListener('touchend', function () { dockEnd(); });
  D.addEventListener('touchcancel', function () {
    if (dst) {
      if (dst.timer) clearTimeout(dst.timer);
      if (dst.edge) clearTimeout(dst.edge);
      dst.item.classList.remove('dk-lift');
      dst.item.style.transform = '';
      if (dst.home) dst.home.classList.remove('dragging');
      dst = null;
      clearMarks();
    }
  });

  D.addEventListener('click', function (e) {
    const del = e.target.closest ? e.target.closest('.gi-del') : null;

    if (del) {
      e.stopPropagation();
      e.preventDefault();

      const gi = del.parentNode;
      const key = gi && gi.getAttribute('data-key');
      const mid = key ? modId(key) : '';

      if (mid && window.Mods) {
        Mods.remove(mid);
        delKey(key);
        if (gi.parentNode) gi.parentNode.removeChild(gi);
        if (navigator.vibrate) { try { navigator.vibrate(10); } catch (err) {} }
      }
      return;
    }

    if (justDragged) {
      e.stopPropagation();
      e.preventDefault();
      return;
    }

    if (!editing) return;

    if (e.target.closest('.gi')) {
      e.stopPropagation();
      e.preventDefault();
      return;
    }

    exitEdit();
  }, true);

  /* ============ 绑定 ============ */

  function bindWidgets(root) {
    Array.prototype.forEach.call(root.querySelectorAll('#home .gi'), function (gi) {
      const k = gi.getAttribute('data-key');
      if (k === 'profile' && window.Profile && Profile.bind) Profile.bind(gi);
      if (k === 'days' && window.DayCard && DayCard.bind) DayCard.bind(gi);
      if (k === 'collage' && window.Collage && Collage.bind) Collage.bind(gi);
    });
  }

  function bindDrag(root) {
    const home = root.querySelector ? root.querySelector('#home') : null;
    if (!home || home.getAttribute('data-drag') === '1') return;

    home.setAttribute('data-drag', '1');
    home.addEventListener('touchstart', onStart, { passive: true });
    home.addEventListener('touchmove', onMove, { passive: false });
    home.addEventListener('touchend', onEnd);
    home.addEventListener('touchcancel', onEnd);
  }

  function rerender() {
    if (window.Desktop && Desktop.rerender) Desktop.rerender();
  }

  function addKey(key) {
    const list = read();
    let exists = false;

    list.forEach(function (p) { if (p.indexOf(key) >= 0) exists = true; });
    if (exists) return;

    if (!list[1]) list[1] = [];
    list[1].push(key);
    write(list);
  }

  function delKey(key) {
    const list = read().map(function (p) {
      return p.filter(function (k) { return k !== key; });
    });
    write(list);
  }

  window.Layout = {
    pagesHtml: pagesHtml,
    read: read,
    addKey: addKey,
    delKey: delKey,
    dockOrder: dockOrder,
    bind: function (root) {
      if (!root) return;
      exitEdit();
      applyDockOrder(root);
      bindWidgets(root);
      bindDrag(root);
    },
    exit: exitEdit,
    rerender: rerender,
    reset: function () {
      try { localStorage.removeItem(K); } catch (e) {}
      try { localStorage.removeItem(DK); } catch (e) {}
      exitEdit();
    }
  };
})();
