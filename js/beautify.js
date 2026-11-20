/* beautify.js · 美化
   外观偏好存在 localStorage['xw_look']，开关落在 html 的 data-* 上，
   CSS 靠属性选择器接管，不动任何别的文件。 */
(function () {
  const D = document;
  const ROOT = D.documentElement;
  const K = 'xw_look';
  const IK = 'xw_wall_img';

  const DEF = {
    skin: 'light',
    accent: 'ink',
    card: 'white',
    radius: '16',
    icon: '21',
    cn: 'serif',
    gap: 'mid',
    motion: 'on',
    dock: 'on',
    dots: 'on',
    wall: 'none'
  };

  const ACCENT = {
    ink: '#5c6a79',
    rose: '#bd7c7c',
    sand: '#b09472',
    sage: '#8e9c83',
    mist: '#8497a9',
    lilac: '#9a8fa8'
  };

  const WALL = {
    none: {
      name: '不铺',
      thumb: 'background:#fff',
      css: ''
    },
    dawn: {
      name: '晨',
      thumb: 'background:linear-gradient(180deg,#f8f6f2,#e9e5df)',
      css: 'radial-gradient(900px 520px at 86% -6%, rgba(255,255,255,.92), transparent 62%),' +
           'radial-gradient(760px 480px at -8% 20%, rgba(198,210,226,.55), transparent 60%),' +
           'linear-gradient(180deg,#f8f6f2 0%,#e9e5df 100%)'
    },
    dusk: {
      name: '暮',
      thumb: 'background:linear-gradient(170deg,#f6ece7,#ded8ce)',
      css: 'radial-gradient(820px 520px at 88% -8%, rgba(255,241,236,.95), transparent 62%),' +
           'linear-gradient(170deg,#f6ece7 0%,#e9ded4 55%,#ded8ce 100%)'
    },
    night: {
      name: '夜',
      thumb: 'background:linear-gradient(180deg,#232220,#121110)',
      css: 'radial-gradient(760px 460px at 82% -6%, rgba(255,255,255,.07), transparent 60%),' +
           'linear-gradient(180deg,#232220 0%,#121110 100%)'
    }
  };

  let st = load();

  function load() {
    const out = {};
    Object.keys(DEF).forEach(function (k) { out[k] = DEF[k]; });
    try {
      const raw = localStorage.getItem(K);
      if (raw) {
        const saved = JSON.parse(raw);
        Object.keys(DEF).forEach(function (k) {
          if (saved && saved[k] !== undefined && saved[k] !== null) out[k] = String(saved[k]);
        });
      }
    } catch (e) {}
    return out;
  }

  function save() {
    try { localStorage.setItem(K, JSON.stringify(st)); } catch (e) {}
  }

  function pic() {
    try { return localStorage.getItem(IK) || ''; } catch (e) { return ''; }
  }

  function apply() {
    ROOT.setAttribute('data-skin', st.skin);
    ROOT.setAttribute('data-accent', st.accent);
    ROOT.setAttribute('data-card', st.card);
    ROOT.setAttribute('data-radius', st.radius);
    ROOT.setAttribute('data-icon', st.icon);
    ROOT.setAttribute('data-cn', st.cn);
    ROOT.setAttribute('data-gap', st.gap);
    ROOT.setAttribute('data-motion', st.motion);
    ROOT.setAttribute('data-dock', st.dock);
    ROOT.setAttribute('data-dots', st.dots);

    ROOT.style.setProperty('--xw-ac', ACCENT[st.accent] || ACCENT.ink);
    ROOT.style.setProperty('--xw-wall', (WALL[st.wall] || WALL.none).css);

    const body = D.body;
    if (!body) return;

    const img = pic();
    if (st.wall === 'photo' && img) {
      body.style.background = 'url("' + img + '") center / cover no-repeat fixed';
    } else {
      body.style.background = '';
    }
  }

  function esc(text) {
    if (window.UI && UI.esc) return UI.esc(text);
    return String(text == null ? '' : text).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  function opt(k, v, label) {
    return '<button type="button" class="bz-opt' + (st[k] === v ? ' on' : '') + '"' +
      ' data-k="' + k + '" data-v="' + v + '">' + label + '</button>';
  }

  function sec(cn, en, inner) {
    return '<div class="bz-sec">' +
        '<div class="bz-lab"><b>' + cn + '</b><i>' + en + '</i></div>' +
        '<div class="bz-opts">' + inner + '</div>' +
      '</div>';
  }

  function accentDots() {
    return Object.keys(ACCENT).map(function (id) {
      return '<button type="button" class="bz-dot' + (st.accent === id ? ' on' : '') + '"' +
        ' data-k="accent" data-v="' + id + '" style="background:' + ACCENT[id] + '"' +
        ' aria-label="' + id + '"></button>';
    }).join('');
  }

  function walls() {
    const img = pic();

    const base = Object.keys(WALL).map(function (id) {
      return '<button type="button" class="bz-wall' + (st.wall === id ? ' on' : '') + '"' +
        ' data-k="wall" data-v="' + id + '" style="' + WALL[id].thumb + '"></button>';
    }).join('');

    const up = '<button type="button" class="bz-wall bz-wall-up' + (st.wall === 'photo' ? ' on' : '') + '"' +
      ' data-k="wall" data-v="photo"' +
      (img ? ' style="background-image:url(' + img + ')"' : '') + '>' +
      (img ? '' : '＋图') + '</button>';

    return base + up;
  }

  function view() {
    return '<header class="hero">' +
        '<span class="kicker">APPEARANCE</span>' +
        '<h1 class="hero-title">美化</h1>' +
        '<div class="hero-sub">点了就变，不用保存</div>' +
      '</header>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">样子</span>' +
          '<button type="button" id="bz-reset" class="btn-glass">回到最初</button></div>' +
        sec('皮', 'SKIN', opt('skin', 'light', '光') + opt('skin', 'night', '夜') + opt('skin', 'paper', '纸')) +
        sec('主色', 'ACCENT', accentDots()) +
        sec('背景', 'WALLPAPER', walls()) +
      '</div>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">手感</span></div>' +
        sec('卡片', 'CARD', opt('card', 'white', '纯白') + opt('card', 'paper', '米纸') + opt('card', 'line', '描边')) +
        sec('圆角', 'RADIUS', opt('radius', '12', '利') + opt('radius', '16', '中') + opt('radius', '22', '圆')) +
        sec('图标', 'ICON', opt('icon', '19', '小') + opt('icon', '21', '中') + opt('icon', '23', '大')) +
        sec('字', 'TYPE', opt('cn', 'serif', '宋') + opt('cn', 'sans', '黑')) +
        sec('间距', 'SPACING', opt('gap', 'tight', '紧') + opt('gap', 'mid', '中') + opt('gap', 'loose', '松')) +
        sec('动效', 'MOTION', opt('motion', 'on', '开着') + opt('motion', 'off', '关掉')) +
      '</div>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">桌面</span></div>' +
        sec('底部四格', 'DOCK', opt('dock', 'on', '留着') + opt('dock', 'off', '收起')) +
        sec('页码点', 'DOTS', opt('dots', 'on', '显示') + opt('dots', 'off', '藏起')) +
        '<div class="sheet-note">名字和纪念日在「设置」里改。</div>' +
      '</div>' +

      '<div class="bz-foot">XIAOWO · 改坏了就点上面「回到最初」</div>';
  }

  function refresh(root) {
    Array.prototype.forEach.call(root.querySelectorAll('.bz-opt,.bz-dot,.bz-wall'), function (el) {
      const k = el.getAttribute('data-k');
      const v = el.getAttribute('data-v');
      el.classList.toggle('on', st[k] === v);
    });
  }

  function shrink(file, maxSide, quality, done) {
    const reader = new FileReader();
    reader.onerror = function () { done(''); };
    reader.onload = function () {
      const im = new Image();
      im.onerror = function () { done(''); };
      im.onload = function () {
        const scale = Math.min(1, maxSide / Math.max(im.width, im.height));
        const c = D.createElement('canvas');
        c.width = Math.max(1, Math.round(im.width * scale));
        c.height = Math.max(1, Math.round(im.height * scale));
        c.getContext('2d').drawImage(im, 0, 0, c.width, c.height);
        try { done(c.toDataURL('image/jpeg', quality)); } catch (e) { done(''); }
      };
      im.src = reader.result;
    };
    reader.readAsDataURL(file);
  }

  function pick(root) {
    const input = D.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';

    input.addEventListener('change', function () {
      const file = input.files && input.files[0];
      if (!file) return;

      shrink(file, 1100, .74, function (data) {
        if (!data) { UI.toast('这张读不出来'); return; }
        try {
          localStorage.setItem(IK, data);
        } catch (err) {
          UI.toast('太大了，换一张小点的');
          return;
        }
        st.wall = 'photo';
        save();
        apply();
        refresh(root);
        UI.toast('换上了');
      });
    });

    input.click();
  }

  function bind(bodyEl) {
    if (!bodyEl) return;

    bodyEl.addEventListener('click', function (e) {
      const btn = e.target.closest ? e.target.closest('.bz-opt,.bz-dot,.bz-wall') : null;
      if (!btn) return;

      const k = btn.getAttribute('data-k');
      const v = btn.getAttribute('data-v');
      if (!k || !v) return;

      if (k === 'wall' && v === 'photo' && !pic()) {
        pick(bodyEl);
        return;
      }

      st[k] = v;

      if (k === 'wall' && v === 'night') st.skin = 'night';
      if (k === 'skin' && v === 'light' && st.wall === 'night') st.wall = 'none';

      save();
      apply();
      refresh(bodyEl);
    });

    const reset = D.getElementById('bz-reset');
    if (reset) {
      reset.addEventListener('click', function () {
        const img = pic();
        Object.keys(DEF).forEach(function (k) { st[k] = DEF[k]; });
        if (img) { try { localStorage.removeItem(IK); } catch (e) {} }
        save();
        apply();
        refresh(bodyEl);
        UI.toast('回到最初了');
      });
    }
  }

  apply();

  if (D.body) D.body.setAttribute('data-hoc', '1');

  window.Beautify = {
    view: view,
    bind: bind,
    apply: apply,
    state: function () { return st; }
  };

  window.Pages = window.Pages || {};
  window.Pages.beautify = view;
  window.Pages.beautifyBind = bind;
})();
