/* beautify.js · 美化
   预览固定在上方，下面一条横滑分类长条，内容只显示当前那一类。 */
(function () {
  const D = document;
  const ROOT = D.documentElement;
  const K = 'xw_look';
  const IK = 'xw_wall_img';

  const DEF = {
    tab: 'kit',
    skin: 'light',
    accent: 'ink',
    card: 'white',
    radius: '16',
    icon: '21',
    gap: '12',
    blur: '16',
    alpha: '68',
    gloss: '70',
    cn: 'serif',
    motion: 'on',
    dock: 'on',
    dots: 'on',
    mat: 'flat',
    wall: 'none',
    mspan: '2',
    mkind: 'text',
    mheight: '140'
  };

  const TABS = [
    { k: 'kit', n: '成套' },
    { k: 'look', n: '样子' },
    { k: 'mat', n: '材质' },
    { k: 'text', n: '字与桌面' },
    { k: 'mods', n: '小组件' }
  ];

  const RANGES = [
    { k: 'radius', cn: '圆角', en: 'RADIUS', min: 8, max: 28, unit: 'px' },
    { k: 'icon', cn: '图标', en: 'ICON', min: 15, max: 28, unit: 'px' },
    { k: 'gap', cn: '间距', en: 'SPACING', min: 6, max: 24, unit: 'px' },
    { k: 'blur', cn: '糊度', en: 'BLUR', min: 0, max: 30, unit: 'px' },
    { k: 'alpha', cn: '厚薄', en: 'DENSITY', min: 8, max: 100, unit: '%' },
    { k: 'gloss', cn: '光泽', en: 'GLOSS', min: 0, max: 100, unit: '%' }
  ];

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

  const SAMPLE = '<div class="clock" id="t">--:--</div>\n' +
    '<style>\n' +
    '  body{background:#fff;display:flex;align-items:center;justify-content:center}\n' +
    '  .clock{font:300 34px/1 "Cormorant Garamond",Georgia,serif;letter-spacing:2px;color:#2a2723}\n' +
    '</style>\n' +
    '<script>\n' +
    '  setInterval(function(){\n' +
    '    var d=new Date();\n' +
    '    var h=("0"+d.getHours()).slice(-2);\n' +
    '    var m=("0"+d.getMinutes()).slice(-2);\n' +
    '    document.getElementById("t").textContent=h+":"+m;\n' +
    '  },1000);\n' +
    '<\/script>';

  let st = load();
  let editId = '';
  let pending = '';

  function num(v, d) {
    const n = parseFloat(v);
    return isFinite(n) ? n : d;
  }

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
    ROOT.setAttribute('data-cn', st.cn);
    ROOT.setAttribute('data-motion', st.motion);
    ROOT.setAttribute('data-dock', st.dock);
    ROOT.setAttribute('data-dots', st.dots);
    ROOT.setAttribute('data-mat', st.mat);

    ROOT.style.setProperty('--xw-ac', ACCENT[st.accent] || ACCENT.ink);
    ROOT.style.setProperty('--xw-radius', num(st.radius, 16) + 'px');
    ROOT.style.setProperty('--xw-icon', num(st.icon, 21) + 'px');
    ROOT.style.setProperty('--xw-gap', num(st.gap, 12) + 'px');
    ROOT.style.setProperty('--xw-blur', num(st.blur, 16) + 'px');
    ROOT.style.setProperty('--xw-alpha', (num(st.alpha, 68) / 100).toFixed(2));
    ROOT.style.setProperty('--xw-gloss', (num(st.gloss, 70) / 100).toFixed(2));

    const body = D.body;
    if (!body) return;

    const img = pic();
    const photo = (st.wall === 'photo' && img) ? img : '';

    if (photo) {
      body.style.background = 'url("' + photo + '") center / cover no-repeat fixed';
    } else {
      body.style.background = '';
    }

    const pv = D.getElementById('bz-pv');
    if (pv) pv.style.backgroundImage = photo ? 'url("' + photo + '")' : '';
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

  function rangeRow(r) {
    const v = num(st[r.k], r.min);
    return '<div class="bz-sec">' +
        '<div class="bz-lab"><b>' + r.cn + '</b><i>' + r.en + '</i></div>' +
        '<div class="bz-range">' +
          '<input type="range" min="' + r.min + '" max="' + r.max + '" step="1"' +
            ' value="' + v + '" data-range="' + r.k + '" data-unit="' + r.unit + '">' +
          '<span>' + v + r.unit + '</span>' +
        '</div>' +
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

  function preview() {
    const app = (window.Apps && Apps.find) ? Apps.find('chat') : null;
    const svg = app ? UI.icon(app.icon) : '';
    const cell = '<div class="pv-cell">' + svg + '</div>';

    return '<div class="pv" id="bz-pv">' +
        '<div class="pv-grid">' + cell + cell + cell + cell + '</div>' +
        '<div class="pv-bar"><div class="pv-line"></div><div class="pv-line short"></div></div>' +
        '<div class="pv-dock"><i></i><i></i><i></i><i></i></div>' +
      '</div>';
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
      '<div class="sheet-note">加好后在桌面上长按，就能拖到任意一页、任意位置，也能拖进 dock。</div>';
  }

  function codeForm() {
    return '<label class="field"><span>名字（列表里显示）</span>' +
        '<input id="bz-mt" type="text" placeholder="比如：小钟"></label>' +

      '<div class="bz-lab" style="margin-top:14px"><b>整段代码</b><i>PASTE</i></div>' +
      '<textarea id="bz-mq" class="bz-ta" rows="12" spellcheck="false"' +
        ' placeholder="整段粘进来就行。HTML、style、script 放一起&#10;&lt;div id=&#39;t&#39;&gt;--&lt;/div&gt;&#10;&lt;style&gt;body{background:#fff}&lt;/style&gt;&#10;&lt;script&gt;...&lt;/script&gt;"></textarea>' +

      '<div class="row-actions" style="justify-content:flex-start">' +
        '<button type="button" id="bz-mext" class="btn-glass">填一段示例</button></div>' +

      sec('宽度', 'WIDTH', spanOpts()) +
      sec('高度', 'HEIGHT',
        opt('mheight', '90', '矮') + opt('mheight', '140', '中') +
        opt('mheight', '200', '高') + opt('mheight', '280', '很高')) +

      '<div class="row-actions">' +
        '<button type="button" id="bz-mprev" class="btn-glass">预览</button>' +
        '<button type="button" id="bz-mcancel" class="btn-glass">取消</button>' +
        '<button type="button" id="bz-msave" class="btn-solid">加到桌面</button></div>' +

      '<div class="bz-prev" id="bz-pbox"><div class="bz-prev-box">写完点「预览」，就在这儿跑</div></div>' +

      '<div class="sheet-note">它跑在一张独立的沙箱网页里：样式和脚本都不出这张卡，也读不到桌面上的东西。写完整网页也能直接认。</div>';
  }

  function pane(k, inner) {
    return '<div class="bz-pane' + (st.tab === k ? ' on' : '') + '" data-pane="' + k + '">' +
      '<div class="sheet">' + inner + '</div></div>';
  }

  function kitPane() {
    return sec('一按就走', 'ONE TAP', Object.keys(PRESET).map(function (id) {
        return opt('preset', id, PRESET_NAME[id]);
      }).join('')) +
      '<div class="sheet-note">整套换。其他分类里每一项还能单独再调。</div>' +
      '<div class="row-actions"><button type="button" id="bz-reset" class="btn-glass">全部回到最初</button></div>';
  }

  function lookPane() {
    return sec('皮', 'SKIN', opt('skin', 'light', '光') + opt('skin', 'night', '夜') + opt('skin', 'paper', '纸')) +
      sec('主色', 'ACCENT', accentDots()) +
      sec('背景', 'WALLPAPER', walls());
  }

  function matPane() {
    return sec('做法', 'MATERIAL',
        opt('mat', 'flat', '素的') + opt('mat', 'frost', '磨砂') +
        opt('mat', 'glass', '玻璃') + opt('mat', 'liquid', '液态')) +
      RANGES.map(rangeRow).join('') +
      '<div class="sheet-note">糊度、厚薄、光泽只在选了磨砂 / 玻璃 / 液态后看得出来。想要明显，先铺一张壁纸。</div>';
  }

  function textPane() {
    return sec('卡片', 'CARD', opt('card', 'white', '纯白') + opt('card', 'paper', '米纸') + opt('card', 'line', '描边')) +
      sec('字', 'TYPE', opt('cn', 'serif', '宋') + opt('cn', 'sans', '黑') + opt('cn', 'mono', '等宽')) +
      sec('动效', 'MOTION', opt('motion', 'on', '开着') + opt('motion', 'off', '关掉')) +
      sec('底部四格', 'DOCK', opt('dock', 'on', '留着') + opt('dock', 'off', '收起')) +
      sec('页码点', 'DOTS', opt('dots', 'on', '显示') + opt('dots', 'off', '藏起')) +
      '<div class="sheet-note">名字和纪念日在「设置」里改。</div>';
  }

  function modsPane() {
    return modRows() +
      sec('做法', 'HOW', opt('mkind', 'text', '写字') + opt('mkind', 'code', '写代码')) +
      (st.mkind === 'code' ? codeForm() : textForm()) +
      '<div class="bz-foot">XIAOWO · 改坏了就去「成套」点全部回到最初</div>';
  }

  function view() {
    return '<div class="bz-stage">' +
        '<div class="bz-preview">' + preview() + '</div>' +
        '<div class="bz-tabs">' + TABS.map(function (t) {
          return '<button type="button" class="bz-tab' + (st.tab === t.k ? ' on' : '') + '"' +
            ' data-tab="' + t.k + '">' + t.n + '</button>';
        }).join('') + '</div>' +
        '<div class="bz-body">' +
          pane('kit', kitPane()) +
          pane('look', lookPane()) +
          pane('mat', matPane()) +
          pane('text', textPane()) +
          pane('mods', modsPane()) +
        '</div>' +
      '</div>';
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

  function switchTab(root) {
    Array.prototype.forEach.call(root.querySelectorAll('.bz-tab'), function (b) {
      b.classList.toggle('on', b.getAttribute('data-tab') === st.tab);
    });

    Array.prototype.forEach.call(root.querySelectorAll('.bz-pane'), function (p) {
      p.classList.toggle('on', p.getAttribute('data-pane') === st.tab);
    });
  }

  function fillForm(m) {
    const ti = D.getElementById('bz-mt');
    if (ti) ti.value = m.title || '';

    if (m.kind === 'code') {
      const mq = D.getElementById('bz-mq');
      if (mq) mq.value = (window.Mods && Mods.codeOf) ? Mods.codeOf(m) : (m.code || '');
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

    bodyEl.addEventListener('input', function (e) {
      const el = e.target;
      if (!el || !el.getAttribute) return;

      const k = el.getAttribute('data-range');
      if (!k) return;

      st[k] = el.value;

      const lab = el.parentNode ? el.parentNode.querySelector('span') : null;
      if (lab) lab.textContent = el.value + (el.getAttribute('data-unit') || '');

      save();
      apply();
    });

    bodyEl.addEventListener('click', function (e) {
      const t = e.target;
      if (!t || !t.closest) return;

      const tab = t.closest('[data-tab]');
      if (tab) {
        st.tab = tab.getAttribute('data-tab');
        save();
        switchTab(bodyEl);
        const box = bodyEl.querySelector('.bz-body');
        if (box) box.scrollTop = 0;
        return;
      }

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

    const mext = D.getElementById('bz-mext');
    if (mext) {
      mext.addEventListener('click', function () {
        const mq = D.getElementById('bz-mq');
        if (mq) mq.value = SAMPLE;
      });
    }

    const msave = D.getElementById('bz-msave');
    if (msave) {
      msave.addEventListener('click', function () {
        if (!window.Mods) return;

        const title = val('bz-mt').trim();

        if (st.mkind === 'code') {
          const code = val('bz-mq');

          if (!code.trim()) {
            UI.toast('还空着，先粘一段');
            return;
          }

          if (editId) {
            Mods.update(editId, { kind: 'code', title: title, code: code, span: st.mspan, height: st.mheight });
            UI.toast('改好了');
          } else {
            const id = Mods.create({ kind: 'code', title: title, code: code, span: st.mspan, height: st.mheight });
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
        const doc = Mods.doc({ code: val('bz-mq') });

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
        ['bz-mt', 'bz-mb', 'bz-mq'].forEach(function (id) {
          const el = D.getElementById(id);
          if (el) el.value = '';
        });
        const btn = D.getElementById('bz-msave');
        if (btn) btn.textContent = '加到桌面';
        const box = D.getElementById('bz-pbox');
        if (box) box.innerHTML = '<div class="bz-prev-box">写完点「预览」，就在这儿跑</div>';
        mark(bodyEl);
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
    switchTab(bodyEl);
    apply();
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
