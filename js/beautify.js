/* beautify.js · 美化
   外观偏好存 localStorage['xw_look']，开关落在 html 的 data-* 上；
   自制小组件存 localStorage['xw_mods']：写字卡，或者直接写 HTML/CSS/JS。 */
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
    mat: 'flat',
    wall: 'none',
    mspan: '2',
    mkind: 'text',
    mheight: '140'
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
    none: { thumb: 'background:#fff', css: '' },
    dawn: {
      thumb: 'background:linear-gradient(180deg,#f8f6f2,#e9e5df)',
      css: 'radial-gradient(900px 520px at 86% -6%, rgba(255,255,255,.92), transparent 62%),' +
           'radial-gradient(760px 480px at -8% 20%, rgba(198,210,226,.55), transparent 60%),' +
           'linear-gradient(180deg,#f8f6f2 0%,#e9e5df 100%)'
    },
    dusk: {
      thumb: 'background:linear-gradient(170deg,#f6ece7,#ded8ce)',
      css: 'radial-gradient(820px 520px at 88% -8%, rgba(255,241,236,.95), transparent 62%),' +
           'linear-gradient(170deg,#f6ece7 0%,#e9ded4 55%,#ded8ce 100%)'
    },
    night: {
      thumb: 'background:linear-gradient(180deg,#232220,#121110)',
      css: 'radial-gradient(760px 460px at 82% -6%, rgba(255,255,255,.07), transparent 60%),' +
           'linear-gradient(180deg,#232220 0%,#121110 100%)'
    }
  };

  const PRESET = {
    dawn: { skin: 'light', accent: 'ink', card: 'white', radius: '16', wall: 'dawn' },
    night: { skin: 'night', accent: 'lilac', card: 'white', radius: '22', wall: 'night' },
    paper: { skin: 'paper', accent: 'sand', card: 'paper', radius: '16', wall: 'dusk' },
    mist: { skin: 'light', accent: 'mist', card: 'line', radius: '12', wall: 'none' }
  };

  const PRESET_NAME = { dawn: '晨', night: '夜', paper: '纸', mist: '雾' };

  let st = load();
  let editId = '';
  let pending = '';

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
    ROOT.setAttribute('data-mat', st.mat);

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
    return '<button type="button" class="bz-opt"' +
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
      return '<button type="button" class="bz-dot"' +
        ' data-k="accent" data-v="' + id + '" style="background:' + ACCENT[id] + '"' +
        ' aria-label="' + id + '"></button>';
    }).join('');
  }

  function walls() {
    const img = pic();

    const base = Object.keys(WALL).map(function (id) {
      return '<button type="button" class="bz-wall"' +
        ' data-k="wall" data-v="' + id + '" style="' + WALL[id].thumb + '"></button>';
    }).join('');

    const picked = '<button type="button" class="bz-wall bz-wall-txt" data-wall-pick="1">' +
      (img ? '换图' : '＋图') + '</button>';

    const own = img
      ? '<button type="button" class="bz-wall' + (st.wall === 'photo' ? ' on' : '') + '"' +
        ' data-k="wall" data-v="photo" style="background-image:url(' + img + ')"></button>' +
        '<button type="button" class="bz-wall bz-wall-txt" data-wall-clear="1">清掉</button>'
      : '';

    return base + picked + own;
  }

  function currentPreset() {
    const keys = Object.keys(PRESET);
    for (let i = 0; i < keys.length; i++) {
      const p = PRESET[keys[i]];
      let same = true;
      Object.keys(p).forEach(function (kk) { if (st[kk] !== p[kk]) same = false; });
      if (same) return keys[i];
    }
    return '';
  }

  function modRows() {
    const list = (window.Mods && Mods.all) ? Mods.all() : [];

    if (!list.length) {
      return '<div class="bz-empty">桌面上一块都没有。下面写一条，点「加到桌面」。</div>';
    }

    const rows = list.map(function (m) {
      const isCode = m.kind === 'code';
      const t = m.title || (isCode ? '（没名字的代码卡）' : '（没标题）');
      const s = isCode
        ? ('代码 · ' + (m.span || '2') + ' 格宽 · ' + (m.height || '140') + 'px 高')
        : (m.text ? String(m.text).replace(/\n/g, ' ') : '（没正文）');

      return '<div class="bz-mod">' +
          '<div class="bz-mod-i"><b>' + esc(t) + '</b><i>' + esc(s) + '</i></div>' +
          '<button type="button" class="bz-ed" data-mod-edit="' + esc(m.id) + '">改</button>' +
          '<button type="button" class="bz-x" data-mod-del="' + esc(m.id) + '">×</button>' +
        '</div>';
    }).join('');

    return '<div class="bz-mods">' + rows + '</div>';
  }

  function spanOpts() {
    return opt('mspan', '1', '一格') + opt('mspan', '2', '两格') + opt('mspan', '4', '一整行');
  }

  function saveRow() {
    return '<div class="row-actions">' +
        '<button type="button" id="bz-mcancel" class="btn-glass">取消</button>' +
        '<button type="button" id="bz-msave" class="btn-solid">加到桌面</button></div>';
  }

  function textForm() {
    return '<label class="field"><span>标题（可以空着）</span>' +
        '<input id="bz-mt" type="text" placeholder="写在桌面上的标题"></label>' +
      '<label class="field"><span>正文</span>' +
        '<textarea id="bz-mb" rows="3" placeholder="想放桌面上的那句话"></textarea></label>' +
      sec('宽度', 'WIDTH', spanOpts()) +
      saveRow() +
      '<div class="sheet-note">加好后在桌面上长按，就能拖到任意一页、任意位置。编辑时长按，自制的块左上角有 ×，点它就从桌面删掉。</div>';
  }

  function codeForm() {
    return '<label class="field"><span>名字（列表里显示）</span>' +
        '<input id="bz-mt" type="text" placeholder="比如：小钟"></label>' +

      '<div class="bz-lab" style="margin-top:14px"><b>HTML</b><i>BODY</i></div>' +
      '<textarea id="bz-mh" class="bz-ta" rows="5" spellcheck="false"' +
        ' placeholder="&lt;div class=&#39;clock&#39;&gt;--:--&lt;/div&gt;"></textarea>' +

      '<div class="bz-lab" style="margin-top:12px"><b>CSS</b><i>STYLE</i></div>' +
      '<textarea id="bz-mc" class="bz-ta" rows="4" spellcheck="false"' +
        ' placeholder=".clock{font:600 28px/1.2 system-ui;text-align:center}"></textarea>' +

      '<div class="bz-lab" style="margin-top:12px"><b>JS</b><i>SCRIPT</i></div>' +
      '<textarea id="bz-mj" class="bz-ta" rows="4" spellcheck="false"' +
        ' placeholder="// document 就是这张卡自己"></textarea>' +

      sec('宽度', 'WIDTH', spanOpts()) +
      sec('高度', 'HEIGHT',
        opt('mheight', '90', '矮') + opt('mheight', '140', '中') +
        opt('mheight', '200', '高') + opt('mheight', '280', '很高')) +

      '<div class="row-actions">' +
        '<button type="button" id="bz-mprev" class="btn-glass">预览</button>' +
        '<button type="button" id="bz-mcancel" class="btn-glass">取消</button>' +
        '<button type="button" id="bz-msave" class="btn-solid">加到桌面</button></div>' +

      '<div class="bz-prev" id="bz-pbox"><div class="bz-prev-box">写完点「预览」，就在这儿跑</div></div>' +

      '<div class="sheet-note">它跑在一张独立的沙箱网页里：样式和脚本都不出这张卡，也读不到桌面上的东西。想让它不透明，就自己给 body 上底色。</div>';
  }

  function view() {
    return '<header class="hero">' +
        '<span class="kicker">APPEARANCE</span>' +
        '<h1 class="hero-title">美化</h1>' +
        '<div class="hero-sub">点了就变，不用保存</div>' +
      '</header>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">成套</span>' +
          '<button type="button" id="bz-reset" class="btn-glass">回到最初</button></div>' +
        sec('一按就走', 'ONE TAP', Object.keys(PRESET).map(function (id) {
          return opt('preset', id, PRESET_NAME[id]);
        }).join('')) +
        '<div class="sheet-note">整套换，下面每一项还能单独再调。</div>' +
      '</div>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">小组件</span></div>' +
        modRows() +
        sec('做法', 'HOW', opt('mkind', 'text', '写字') + opt('mkind', 'code', '写代码')) +
        (st.mkind === 'code' ? codeForm() : textForm()) +
      '</div>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">样子</span></div>' +
        sec('皮', 'SKIN', opt('skin', 'light', '光') + opt('skin', 'night', '夜') + opt('skin', 'paper', '纸')) +
        sec('主色', 'ACCENT', accentDots()) +
        sec('背景', 'WALLPAPER', walls()) +
      '</div>' +

      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">手感</span></div>' +
        sec('材质', 'MATERIAL',
          opt('mat', 'flat', '素的') + opt('mat', 'frost', '磨砂') +
          opt('mat', 'glass', '玻璃') + opt('mat', 'liquid', '液态')) +
        sec('卡片', 'CARD', opt('card', 'white', '纯白') + opt('card', 'paper', '米纸') + opt('card', 'line', '描边')) +
        sec('圆角', 'RADIUS', opt('radius', '12', '利') + opt('radius', '16', '中') + opt('radius', '22', '圆')) +
        sec('图标', 'ICON', opt('icon', '19', '小') + opt('icon', '21', '中') + opt('icon', '23', '大')) +
        sec('字', 'TYPE', opt('cn', 'serif', '宋') + opt('cn', 'sans', '黑') + opt('cn', 'mono', '等宽')) +
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

  function mark(root) {
    const pre = currentPreset();

    Array.prototype.forEach.call(root.querySelectorAll('.bz-opt,.bz-dot,.bz-wall'), function (el) {
      const k = el.getAttribute('data-k');
      const v = el.getAttribute('data-v');
      if (!k || !v) return;
      const on = (k === 'preset') ? (pre === v) : (st[k] === v);
      el.classList.toggle('on', on);
    });
  }

  function fillForm(m) {
    const ti = D.getElementById('bz-mt');
    if (ti) ti.value = m.title || '';

    if (m.kind === 'code') {
      const mh = D.getElementById('bz-mh');
      const mc = D.getElementById('bz-mc');
      const mj = D.getElementById('bz-mj');
      if (mh) mh.value = m.html || '';
      if (mc) mc.value = m.css || '';
      if (mj) mj.value = m.js || '';
    } else {
      const bo = D.getElementById('bz-mb');
      if (bo) bo.value = m.text || '';
    }

    const btn = D.getElementById('bz-msave');
    if (btn) btn.textContent = '存下改动';
  }

  function val(id) {
    const el = D.getElementById(id);
    return el ? el.value : '';
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

  function chooseWall() {
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
        UI.toast('换上了');
        if (window.Router && Router.reopen) Router.reopen('beautify');
      });
    });

    input.click();
  }

  function redraw() {
    if (window.Desktop && Desktop.rerender) Desktop.rerender();
    if (window.Router && Router.reopen) Router.reopen('beautify');
  }

  function bind(bodyEl) {
    if (!bodyEl) return;

    editId = '';

    bodyEl.addEventListener('click', function (e) {
      const t = e.target;
      if (!t || !t.closest) return;

      const del = t.closest('[data-mod-del]');
      if (del) {
        const id = del.getAttribute('data-mod-del');
        if (window.Mods) Mods.remove(id);
        if (window.Layout && Layout.delKey) Layout.delKey('mod:' + id);
        UI.toast('从桌面拿掉了');
        redraw();
        return;
      }

      const ed = t.closest('[data-mod-edit]');
      if (ed) {
        const id = ed.getAttribute('data-mod-edit');
        const m = (window.Mods && Mods.find) ? Mods.find(id) : null;
        if (!m) return;

        const need = (m.kind === 'code') ? 'code' : 'text';
        st.mspan = String(m.span || '2');
        if (m.kind === 'code') st.mheight = String(m.height || '140');

        if (st.mkind !== need) {
          st.mkind = need;
          save();
          pending = id;
          redraw();
          return;
        }

        editId = id;
        fillForm(m);
        mark(bodyEl);
        const ti = D.getElementById('bz-mt');
        if (ti && ti.scrollIntoView) ti.scrollIntoView({ behavior: 'smooth', block: 'center' });
        return;
      }

      const pickBtn = t.closest('[data-wall-pick]');
      if (pickBtn) { chooseWall(); return; }

      const clr = t.closest('[data-wall-clear]');
      if (clr) {
        try { localStorage.removeItem(IK); } catch (err) {}
        if (st.wall === 'photo') st.wall = 'none';
        save();
        apply();
        if (window.Router && Router.reopen) Router.reopen('beautify');
        return;
      }

      const btn = t.closest('.bz-opt,.bz-dot,.bz-wall');
      if (!btn) return;

      const k = btn.getAttribute('data-k');
      const v = btn.getAttribute('data-v');
      if (!k || !v) return;

      if (k === 'mspan' || k === 'mheight') {
        st[k] = v;
        save();
        mark(bodyEl);
        return;
      }

      if (k === 'mkind') {
        st.mkind = v;
        save();
        if (window.Router && Router.reopen) Router.reopen('beautify');
        return;
      }

      if (k === 'preset') {
        const p = PRESET[v];
        if (!p) return;
        Object.keys(p).forEach(function (kk) { st[kk] = p[kk]; });
        save();
        apply();
        mark(bodyEl);
        return;
      }

      st[k] = v;
      if (k === 'wall' && v === 'night') st.skin = 'night';
      if (k === 'skin' && v === 'light' && st.wall === 'night') st.wall = 'none';

      save();
      apply();
      mark(bodyEl);
    });

    const msave = D.getElementById('bz-msave');
    if (msave) {
      msave.addEventListener('click', function () {
        if (!window.Mods) return;

        const title = val('bz-mt').trim();

        if (st.mkind === 'code') {
          const html = val('bz-mh');
          const css = val('bz-mc');
          const js = val('bz-mj');

          if (!html.trim() && !css.trim() && !js.trim()) {
            UI.toast('还空着，先写点什么');
            return;
          }

          if (editId) {
            Mods.update(editId, { kind: 'code', title: title, html: html, css: css, js: js, span: st.mspan, height: st.mheight });
            UI.toast('改好了');
          } else {
            const id = Mods.create({ kind: 'code', title: title, html: html, css: css, js: js, span: st.mspan, height: st.mheight });
            if (window.Layout && Layout.addKey) Layout.addKey('mod:' + id);
            UI.toast('加到桌面了');
          }

          redraw();
          return;
        }

        const text = val('bz-mb').trim();
        if (!title && !text) { UI.toast('先写一句'); return; }

        if (editId) {
          Mods.update(editId, { kind: 'text', title: title, text: text, span: st.mspan });
          UI.toast('改好了');
        } else {
          const id = Mods.create({ kind: 'text', title: title, text: text, span: st.mspan });
          if (window.Layout && Layout.addKey) Layout.addKey('mod:' + id);
          UI.toast('加到桌面了');
        }

        redraw();
      });
    }

    const mprev = D.getElementById('bz-mprev');
    if (mprev) {
      mprev.addEventListener('click', function () {
        const box = D.getElementById('bz-pbox');
        if (!box || !window.Mods) return;

        const h = Number(st.mheight) || 140;
        const doc = Mods.doc({ html: val('bz-mh'), css: val('bz-mc'), js: val('bz-mj') });

        box.innerHTML = '<iframe sandbox="allow-scripts" scrolling="no"' +
          ' style="height:' + h + 'px;width:100%;border:0;display:block;background:#fff"></iframe>';

        const fr = box.querySelector('iframe');
        if (fr) fr.srcdoc = doc;
      });
    }

    const mcancel = D.getElementById('bz-mcancel');
    if (mcancel) {
      mcancel.addEventListener('click', function () {
        editId = '';
        st.mspan = '2';
        const ti = D.getElementById('bz-mt');
        const bo = D.getElementById('bz-mb');
        const mh = D.getElementById('bz-mh');
        const mc = D.getElementById('bz-mc');
        const mj = D.getElementById('bz-mj');
        const btn = D.getElementById('bz-msave');
        if (ti) ti.value = '';
        if (bo) bo.value = '';
        if (mh) mh.value = '';
        if (mc) mc.value = '';
        if (mj) mj.value = '';
        if (btn) btn.textContent = '加到桌面';
        const box = D.getElementById('bz-pbox');
        if (box) box.innerHTML = '<div class="bz-prev-box">写完点「预览」，就在这儿跑</div>';
        mark(bodyEl);
      });
    }

    const reset = D.getElementById('bz-reset');
    if (reset) {
      reset.addEventListener('click', function () {
        Object.keys(DEF).forEach(function (k) { st[k] = DEF[k]; });
        try { localStorage.removeItem(IK); } catch (e) {}
        save();
        apply();
        UI.toast('外观回到最初了');
        if (window.Router && Router.reopen) Router.reopen('beautify');
      });
    }

    if (pending && window.Mods && Mods.find) {
      const m = Mods.find(pending);
      const id = pending;
      pending = '';

      if (m) {
        editId = id;
        st.mspan = String(m.span || '2');
        if (m.kind === 'code') st.mheight = String(m.height || '140');
        fillForm(m);
      }
    }

    mark(bodyEl);
  }

  function watchMods() {
    if (window.Mods && Mods.mount) Mods.mount(document);
    if (!window.MutationObserver || !D.body) return;

    let timer = null;
    const mo = new MutationObserver(function () {
      if (timer) return;
      timer = setTimeout(function () {
        timer = null;
        if (window.Mods && Mods.mount) Mods.mount(document);
      }, 60);
    });

    mo.observe(D.body, { childList: true, subtree: true });
  }

  apply();
  watchMods();

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
