/* layout.js · 首页布局表
   每页一个四列网格，组件与 App 都是网格上的一个块。
   长按 450ms 拖动；拖到最近的块上松手就交换；拖到空白就落到该页末尾。 */
(function () {
  const D = document;
  const K = 'xw_layout';

  const SPAN = {
    collage: 4, days: 4, quote: 4, clock: 4,
    wx: 2, quota: 2, cal: 4, now: 4
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
  let justDragged = false;

  /* ============ 位置表 ============ */

  function valid(k) {
    if (SPAN[k] !== undefined) return true;
    if (typeof k !== 'string') return false;
    if (k.indexOf('app:') === 0) return !!window.Apps.find(k.slice(4));
    return false;
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

    for (let i = 0; i < saved.length; i++) {
      if (!Array.isArray(saved[i])) return copy(DEF);
      for (let j = 0; j < saved[i].length; j++) {
        if (!valid(saved[i][j])) return copy(DEF);
      }
    }

    return saved;
  }

  function write(list) {
    try { localStorage.setItem(K, JSON.stringify(list)); } catch (e) {}
  }

  /* ============ 渲染 ============ */

  function htmlOf(k) {
    const W = window.Widgets || {};

    if (k === 'collage') return (window.Collage && Collage.html) ? Collage.html() : '';
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
        return '<div class="gi gi' + (SPAN[k] || 1) + '" data-key="' + k + '">' + h + '</div>';
      }).join('');

      return '<section class="page gpage" data-page="' + i + '">' + inner + '</section>';
    }).join('');
  }

  /* ============ 拖动 ============ */

  function homeEl() { return D.getElementById('home'); }

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

  /* 手指附近最近的那块（不要求正对着），140px 以内都算 */
  function targetAt(x, y) {
    const home = homeEl();
    if (!home) return null;

    const pg = pageAt(home, currentIndex(home));
    if (!pg) return null;

    let best = null;
    let score = Infinity;

    Array.prototype.forEach.call(pg.querySelectorAll('.gi'), function (gi) {
      if (st && gi === st.item) return;
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

  function onStart(ev) {
    if (!ev.touches || ev.touches.length !== 1) return;
    const home = homeEl();
    if (!home) return;

    const item = ev.target.closest ? ev.target.closest('.gi') : null;
    if (!item) return;

    const t = ev.touches[0];
    st = {
      item: item,
      home: home,
      sx: t.clientX, sy: t.clientY,
      lx: t.clientX, ly: t.clientY,
      active: false,
      over: null,
      side: 0,
      flipped: false,
      target: -1,
      timer: null,
      edge: null
    };

    st.timer = setTimeout(function () {
      if (!st) return;
      st.active = true;
      st.item.classList.add('lift');
      st.home.classList.add('dragging');
      st.home.style.scrollSnapType = 'none';
      if (navigator.vibrate) { try { navigator.vibrate(12); } catch (e) {} }
    }, 450);
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

    const over = targetAt(t.clientX, t.clientY);
    if (over !== st.over) {
      if (st.over) st.over.classList.remove('dc-drop');
      st.over = over;
      if (over) over.classList.add('dc-drop');
    }

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

    const target = pageAt(home, next);
    if (target && st.item.parentNode !== target) {
      target.appendChild(st.item);
      st.sx = st.lx;
      st.sy = st.ly;
      st.item.style.transform = '';
    }

    st.flipped = true;
    st.target = next;
    home.scrollTo({ left: next * w, behavior: 'smooth' });
    if (navigator.vibrate) { try { navigator.vibrate(8); } catch (e) {} }
  }

  /* 两块互换位置；跨页也能换 */
  function swap(a, b) {
    if (!a || !b || a === b) return;

    const pa = a.parentNode;
    const pb = b.parentNode;
    if (!pa || !pb) return;

    const ma = D.createComment('sw');
    const mb = D.createComment('sw');

    pa.insertBefore(ma, a);
    pb.insertBefore(mb, b);

    pa.insertBefore(b, ma);
    pb.insertBefore(a, mb);

    pa.removeChild(ma);
    pb.removeChild(mb);
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
    if (s.over) s.over.classList.remove('dc-drop');
    s.home.classList.remove('dragging');
    s.home.style.scrollSnapType = '';

    let changed = false;

    if (s.over) {
      swap(s.item, s.over);
      changed = true;
    } else {
      const pg = pageAt(s.home, s.flipped ? s.target : currentIndex(s.home));
      if (pg && s.item.parentNode !== pg) {
        pg.appendChild(s.item);
        changed = true;
      } else if (s.flipped) {
        changed = true;
      }
    }

    if (changed) {
      save();
      if (navigator.vibrate) { try { navigator.vibrate(8); } catch (e) {} }
    }

    justDragged = true;
    setTimeout(function () { justDragged = false; }, 360);
  }

  function save() {
    const home = homeEl();
    if (!home) return;

    const out = [];
    Array.prototype.forEach.call(home.querySelectorAll('.page'), function (pg) {
      const keys = [];
      Array.prototype.forEach.call(pg.querySelectorAll('.gi'), function (gi) {
        keys.push(gi.getAttribute('data-key'));
      });
      out.push(keys);
    });

    write(out);
  }

  D.addEventListener('click', function (e) {
    if (!justDragged) return;
    e.stopPropagation();
    e.preventDefault();
  }, true);

  /* ============ 挂载 ============ */

  function bindWidgets(root) {
    Array.prototype.forEach.call(root.querySelectorAll('#home .gi'), function (gi) {
      const k = gi.getAttribute('data-key');
      if (k === 'days' && window.DayCard && DayCard.bind) DayCard.bind(gi);
      if (k === 'collage' && window.Collage && Collage.bind) Collage.bind(gi);
    });
  }

  function bindDrag(root) {
    const home = root.querySelector ? root.querySelector('#home') : null;
    if (!home) return;

    home.addEventListener('touchstart', onStart, { passive: true });
    home.addEventListener('touchmove', onMove, { passive: false });
    home.addEventListener('touchend', onEnd);
    home.addEventListener('touchcancel', onEnd);
  }

  window.Layout = {
    pagesHtml: pagesHtml,
    read: read,
    bind: function (root) {
      if (!root) return;
      bindWidgets(root);
      bindDrag(root);
    },
    reset: function () {
      try { localStorage.removeItem(K); } catch (e) {}
    }
  };
})();
