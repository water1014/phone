/* collage.js · 首页第 1 页：照片墙（左一大 + 右三小 + 可改题注）
   替换 desktop.js 生成的 .cover，其余页不动。 */
(function () {
  const D = document;
  const CAP_KEY = 'xw_caption';

  const MODES = [
    { id: 'all', name: '全部' },
    { id: 'recent', name: '最近' },
    { id: 'star', name: '收藏' }
  ];

  let mode = 'all';
  let queued = false;

  /* 照片可能是字符串，也可能是对象 —— 两种都认 */
  function srcOf(p) {
    if (!p) return '';
    if (typeof p === 'string') return p;
    return p.src || p.url || p.data || p.href || '';
  }

  function timeOf(p) {
    if (!p || typeof p !== 'object') return 0;
    const v = p.date || p.t || p.time || 0;
    const n = typeof v === 'number' ? v : Date.parse(String(v));
    return isNaN(n) ? 0 : n;
  }

  function pool() {
    const all = (Array.isArray(XW.S.photos) ? XW.S.photos : [])
      .filter(function (p) { return !!srcOf(p); });

    if (mode === 'recent') {
      return all.slice().sort(function (a, b) { return timeOf(b) - timeOf(a); });
    }
    if (mode === 'star') {
      return all.filter(function (p) { return p && typeof p === 'object' && p.star; });
    }
    return all;
  }

  function attr(u) {
    return String(u).replace(/"/g, '%22').replace(/</g, '%3C');
  }

  function tile(u, cls) {
    if (!u) return '<div class="' + cls + ' clg-none"></div>';
    return '<div class="' + cls + '"><img src="' + attr(u) + '" alt="" loading="lazy"></div>';
  }

  function gridHtml() {
    const L = pool();

    if (!L.length) {
      const msg = mode === 'star'
        ? '还没收藏过。相册里点一下星，这里就有了。'
        : '还没照片。相册里放几张，这里就会有。';
      return '<div class="clg-grid clg-empty"><span>' + msg + '</span></div>';
    }

    return '<div class="clg-grid">' +
        tile(srcOf(L[0]), 'clg-main') +
        '<div class="clg-side">' +
          tile(srcOf(L[1]), 'clg-small') +
          tile(srcOf(L[2]), 'clg-small') +
          tile(srcOf(L[3]), 'clg-small') +
        '</div>' +
      '</div>';
  }

  function tabsHtml() {
    return '<div class="clg-tabs">' +
      MODES.map(function (m) {
        return '<span class="clg-tab' + (m.id === mode ? ' active' : '') +
          '" data-mode="' + m.id + '">' + m.name + '</span>';
      }).join('') +
      '</div>';
  }

  function readCap() {
    try {
      const raw = localStorage.getItem(CAP_KEY);
      if (raw == null) return '';
      return String(JSON.parse(raw) || '');
    } catch (e) { return ''; }
  }

  function writeCap(text) {
    XW.S.caption = text;
    try { localStorage.setItem(CAP_KEY, JSON.stringify(text)); } catch (e) {}
  }

  function esc(t) {
    return String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function capHtml() {
    return '<div class="clg-cap" contenteditable="true" spellcheck="false" ' +
      'data-ph="点这儿写一句">' + esc(readCap()) + '</div>';
  }

  function innerHtml() {
    return tabsHtml() + gridHtml() + capHtml();
  }

  function bind(root) {
    Array.prototype.forEach.call(root.querySelectorAll('.clg-tab'), function (tab) {
      tab.addEventListener('click', function () {
        mode = tab.getAttribute('data-mode');
        root.innerHTML = innerHtml();
        bind(root);
      });
    });

    const cap = root.querySelector('.clg-cap');
    if (!cap) return;

    let last = readCap();

    function save() {
      const t = cap.innerText.replace(/\r?\n/g, ' ').trim();
      if (t === last) return;
      last = t;
      writeCap(t);
    }

    cap.addEventListener('input', save);
    cap.addEventListener('blur', save);
    cap.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        save();
        cap.blur();
      }
    });
  }

  function mount() {
    if (!window.XW) return;

    const home = D.getElementById('home');
    if (!home) return;

    const page = home.querySelector('.page');
    if (!page) return;

    const cover = page.querySelector('.cover');
    if (!cover) return;

    const wrap = D.createElement('div');
    wrap.className = 'clg';
    wrap.innerHTML = innerHtml();
    bind(wrap);

    page.replaceChild(wrap, cover);
  }

  function schedule() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () {
      queued = false;
      mount();
    });
  }

  const screen = D.getElementById('screen');
  if (screen) {
    new MutationObserver(schedule).observe(screen, { childList: true });
  }

  schedule();
  D.addEventListener('DOMContentLoaded', schedule);
  setTimeout(schedule, 400);
})();
