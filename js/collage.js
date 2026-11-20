/* collage.js · 照片墙（由 layout.js 摆放）
   左一大 + 右三小，顶部三个切换，底下一行可改题注 */
(function () {
  const D = document;
  const CAP_KEY = 'xw_caption';
  const Q = String.fromCharCode(34);

  const MODES = [
    { id: 'all', name: '全部' },
    { id: 'recent', name: '最近' },
    { id: 'star', name: '收藏' }
  ];

  let mode = 'all';

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
    return String(u).split(Q).join('%22').split('<').join('%3C');
  }

  function tile(u, cls) {
    if (!u) return '<div class=' + Q + cls + ' clg-none' + Q + '></div>';
    return '<div class=' + Q + cls + Q + '><img src=' + Q + attr(u) + Q + ' alt=' + Q + Q +
      ' loading=' + Q + 'lazy' + Q + '></div>';
  }

  function gridHtml() {
    const L = pool();

    if (!L.length) {
      const msg = mode === 'star'
        ? '还没收藏过。相册里点一下星，这里就有了。'
        : '还没照片。相册里放几张，这里就会有。';
      return '<div class=' + Q + 'clg-grid clg-empty' + Q + '><span>' + msg + '</span></div>';
    }

    return '<div class=' + Q + 'clg-grid' + Q + '>' +
        tile(srcOf(L[0]), 'clg-main') +
        '<div class=' + Q + 'clg-side' + Q + '>' +
          tile(srcOf(L[1]), 'clg-small') +
          tile(srcOf(L[2]), 'clg-small') +
          tile(srcOf(L[3]), 'clg-small') +
        '</div>' +
      '</div>';
  }

  function tabsHtml() {
    return '<div class=' + Q + 'clg-tabs' + Q + '>' +
      MODES.map(function (m) {
        return '<span class=' + Q + 'clg-tab' + (m.id === mode ? ' active' : '') + Q +
          ' data-mode=' + Q + m.id + Q + '>' + m.name + '</span>';
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
    return String(t).split('&').join('&amp;').split('<').join('&lt;').split('>').join('&gt;');
  }

  function capHtml() {
    return '<div class=' + Q + 'clg-cap' + Q + ' contenteditable=' + Q + 'true' + Q +
      ' spellcheck=' + Q + 'false' + Q + ' data-ph=' + Q + '点这儿写一句' + Q + '>' +
      esc(readCap()) + '</div>';
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
      const t = cap.innerText.split(String.fromCharCode(13)).join('')
        .split(String.fromCharCode(10)).join(' ').trim();
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

  window.Collage = {
    html: function () {
      return '<div class=' + Q + 'clg' + Q + ' data-key=' + Q + 'collage' + Q + '>' +
        innerHtml() + '</div>';
    },
    bind: function (root) {
      if (!root) return;
      const box = root.classList && root.classList.contains('clg')
        ? root
        : root.querySelector('.clg');
      if (!box) return;
      bind(box);
    }
  };
})();
