/* chat-settings.js · 聊天自己的设置
   四个分类：外观 / 头像 / 背景 / 记录 */
(function () {
  const D = document;
  const ROOT = D.documentElement;
  const K = 'xw_chatcfg';
  const BK = 'xw_chat_bg';
  const WK = 'xw_wall_img';

  const DEF = {
    fs: '0.8', think: '1', usage: '1', time: '1',
    bubble: '0', bg: 'none', tone: 'blue', tab: 'look'
  };

  const BG = {
    dawn: {
      css: 'radial-gradient(130% 100% at 15% 0%, #fffdf9 0%, #f6f1e6 58%, #efe8db 100%)',
      op: '1'
    },
    paper: {
      css: 'repeating-linear-gradient(0deg, rgba(160,145,120,.07) 0 1px, transparent 1px 7px),' +
           'linear-gradient(180deg, #fbf7ee, #f4efe3)',
      op: '1'
    }
  };

  let st = {};
  try { st = JSON.parse(localStorage.getItem(K) || '{}') || {}; }
  catch (e) { st = {}; }

  Object.keys(DEF).forEach(function (k) {
    if (st[k] === undefined || st[k] === null || st[k] === '') st[k] = DEF[k];
  });

  function save() {
    try { localStorage.setItem(K, JSON.stringify(st)); } catch (e) {}
  }

  function lsGet(k) {
    try { return localStorage.getItem(k) || ''; } catch (e) { return ''; }
  }

  function lsSet(k, v) {
    try { localStorage.setItem(k, v); return true; } catch (e) { return false; }
  }

  function lsDel(k) {
    try { localStorage.removeItem(k); } catch (e) {}
  }

  function applyCfg() {
    ROOT.style.setProperty('--cs-fs', st.fs + 'rem');

    let css = 'none';
    let op = '.26';

    if (st.bg === 'photo') {
      const u = lsGet(BK);
      if (u) css = 'url(' + u + ')';
    } else if (st.bg === 'wall') {
      const u = lsGet(WK);
      if (u) css = 'url(' + u + ')';
    } else if (BG[st.bg]) {
      css = BG[st.bg].css;
      op = BG[st.bg].op;
    }

    ROOT.style.setProperty('--cs-bg', css);
    ROOT.style.setProperty('--cs-bg-op', op);

    ROOT.setAttribute('data-chat-think', st.think);
    ROOT.setAttribute('data-chat-usage', st.usage);
    ROOT.setAttribute('data-chat-time', st.time);
    ROOT.setAttribute('data-chat-bubble', st.bubble);
    ROOT.setAttribute('data-chat-bg', st.bg);
    ROOT.setAttribute('data-chat-tone', st.tone);
  }

  function tabsHtml() {
    const T = [
      ['look', '外观'],
      ['face', '头像'],
      ['bg', '背景'],
      ['more', '记录']
    ];
    return '<div class=cset-tabs>' + T.map(function (p) {
      return '<button type=button class=cset-tab data-cp=' + p[0] + '>' + p[1] + '</button>';
    }).join('') + '</div>';
  }

  function pane(k, inner) {
    return '<div class=cset-pane data-cp=' + k + '>' + inner + '</div>';
  }

  function bgHtml() {
    const wall = lsGet(WK);
    const own = lsGet(BK);

    const tone = function (v, label, css) {
      const on = String(st.bg) === v ? ' on' : '';
      return '<button type=button class="cset-swatch' + on + '" data-bgv=' + v +
        (css ? ' style="background-image:' + css + '"' : '') + '>' + label + '</button>';
    };

    let out = '<div class=cset-bgs>' +
      '<button type=button class="cset-swatch' + (st.bg === 'none' ? ' on' : '') +
        '" data-bgv=none>不铺</button>' +
      tone('dawn', '米光', 'radial-gradient(130% 100% at 15% 0%, #fffdf9 0%, #f6f1e6 58%, #efe8db 100%)') +
      tone('paper', '纸纹', 'repeating-linear-gradient(0deg, rgba(160,145,120,.12) 0 1px, transparent 1px 5px), linear-gradient(180deg, #fbf7ee, #f4efe3)') +
      (wall ? tone('wall', '用壁纸', 'url(' + wall + ')') : '') +
      (own ? tone('photo', '我选的', 'url(' + own + ')') : '') +
      '</div>' +
      '<div class=cset-row style="margin-top:.7rem">' +
        '<button type=button class=cset-btn id=cset-bgpick>＋ 放一张自己的</button>' +
        '<button type=button class=cset-danger id=cset-bgclear>清掉</button>' +
      '</div>' +
      '<div class=cset-note>「用壁纸」直接拿美化里那张，不用重传。铺上去会很淡，只当水印。</div>';

    return out;
  }

  function build() {
    const p = D.createElement('div');
    p.className = 'cset';
    p.id = 'cset';

    const look =
      '<div class=cset-sec><div class=cset-lab>称呼</div>' +
        '<label class=cset-f>他<input id=cset-his type=text></label>' +
        '<label class=cset-f>我<input id=cset-her type=text></label></div>' +
      '<div class=cset-sec><div class=cset-lab>外观</div>' +
        '<div class=cset-row>' +
          '<button type=button class=cset-opt data-bubble=0>无气泡</button>' +
          '<button type=button class=cset-opt data-bubble=1>有气泡</button>' +
        '</div>' +
        '<div class=cset-lab style="margin-top:1rem">气泡颜色</div>' +
        '<div class=cset-dots>' +
          '<button type=button class=cset-dot data-tone=blue></button>' +
          '<button type=button class=cset-dot data-tone=pink></button>' +
          '<button type=button class=cset-dot data-tone=paper></button>' +
          '<button type=button class=cset-dot data-tone=sage></button>' +
        '</div></div>' +
      '<div class=cset-sec><div class=cset-lab>字大小</div>' +
        '<div class=cset-row>' +
          '<button type=button class=cset-opt data-fs=0.72>小</button>' +
          '<button type=button class=cset-opt data-fs=0.8>中</button>' +
          '<button type=button class=cset-opt data-fs=0.9>大</button>' +
        '</div></div>' +
      '<div class=cset-sec><div class=cset-lab>显示什么</div>' +
        '<div class=cset-row>' +
          '<button type=button class=cset-opt data-t=think>思考</button>' +
          '<button type=button class=cset-opt data-t=usage>用量</button>' +
          '<button type=button class=cset-opt data-t=time>时间</button>' +
        '</div></div>';

    const face =
      '<div class=cset-sec><div class=cset-lab>头像</div>' +
        '<div class=cset-row>' +
          '<button type=button class=cset-ava id=cset-ava-his>他</button>' +
          '<button type=button class=cset-ava id=cset-ava-her>我</button>' +
        '</div>' +
        '<div class=cset-note>点头像换图。和天数卡共用同一张，这边改了那里也跟着变。</div></div>';

    p.innerHTML =
      '<div class=cset-head><b>聊天设置</b>' +
        '<button type=button id=cset-x>×</button></div>' +
      tabsHtml() +
      '<div class=cset-body>' +
        pane('look', look) +
        pane('face', face) +
        pane('bg', bgHtml()) +
        pane('more', '<div class=cset-sec><div class=cset-lab>聊天记录</div>' +
          '<div class=cset-row>' +
            '<button type=button class=cset-btn id=cset-export>导出聊天</button>' +
            '<button type=button class=cset-danger id=cset-clear>清空聊天</button>' +
          '</div></div>') +
      '</div>';

    return p;
  }

  function paintAva(who) {
    const el = D.getElementById('cset-ava-' + who);
    if (!el) return;
    const url = lsGet(who === 'his' ? 'xw_ava_his' : 'xw_ava_her');
    el.style.backgroundImage = url ? 'url(' + url + ')' : '';
    el.textContent = url ? '' : (who === 'his' ? '他' : '我');
  }

  function fill() {
    const his = D.getElementById('cset-his');
    const her = D.getElementById('cset-her');
    if (his) his.value = XW.S.hisName || '';
    if (her) her.value = XW.S.herName || '';

    paintAva('his');
    paintAva('her');

    Array.prototype.forEach.call(D.querySelectorAll('.cset-opt[data-fs]'), function (b) {
      b.classList.toggle('on', String(b.getAttribute('data-fs')) === String(st.fs));
    });

    Array.prototype.forEach.call(D.querySelectorAll('.cset-opt[data-bubble]'), function (b) {
      b.classList.toggle('on', String(b.getAttribute('data-bubble')) === String(st.bubble));
    });

    Array.prototype.forEach.call(D.querySelectorAll('.cset-dot[data-tone]'), function (b) {
      b.classList.toggle('on', String(b.getAttribute('data-tone')) === String(st.tone));
    });

    Array.prototype.forEach.call(D.querySelectorAll('.cset-swatch[data-bgv]'), function (b) {
      b.classList.toggle('on', String(b.getAttribute('data-bgv')) === String(st.bg));
    });

    ['think', 'usage', 'time'].forEach(function (k) {
      const b = D.querySelector('.cset-opt[data-t=' + k + ']');
      if (b) b.classList.toggle('on', st[k] === '1');
    });

    Array.prototype.forEach.call(D.querySelectorAll('.cset-tab'), function (b) {
      b.classList.toggle('on', b.getAttribute('data-cp') === st.tab);
    });

    Array.prototype.forEach.call(D.querySelectorAll('.cset-pane'), function (p) {
      p.classList.toggle('on', p.getAttribute('data-cp') === st.tab);
    });
  }

  function open() {
    let p = D.getElementById('cset');
    if (!p) {
      p = build();
      D.body.appendChild(p);
    }
    fill();
    p.classList.add('on');
  }

  function close() {
    const p = D.getElementById('cset');
    if (p) p.classList.remove('on');
    if (window.Router && Router.reopen) Router.reopen('chat');
  }

  function shrink(file, maxSide, cb) {
    const reader = new FileReader();
    reader.onerror = function () { cb(''); };
    reader.onload = function () {
      const im = new Image();
      im.onerror = function () { cb(''); };
      im.onload = function () {
        const scale = Math.min(1, maxSide / Math.max(im.width, im.height));
        const cv = D.createElement('canvas');
        cv.width = Math.max(1, Math.round(im.width * scale));
        cv.height = Math.max(1, Math.round(im.height * scale));
        cv.getContext('2d').drawImage(im, 0, 0, cv.width, cv.height);
        let data = '';
        try { data = cv.toDataURL('image/jpeg', 0.74); } catch (e) { data = ''; }
        cb(data);
      };
      im.src = reader.result;
    };
    reader.readAsDataURL(file);
  }

  function pickBg() {
    const inp = D.createElement('input');
    inp.type = 'file';
    inp.accept = 'image/*';
    inp.style.display = 'none';
    D.body.appendChild(inp);

    inp.addEventListener('change', function () {
      const f = inp.files && inp.files[0];
      if (inp.parentNode) inp.parentNode.removeChild(inp);
      if (!f) return;

      shrink(f, 1100, function (data) {
        if (!data) { UI.toast('这张读不出来'); return; }
        if (!lsSet(BK, data)) { UI.toast('太大了，换一张小点的'); return; }
        st.bg = 'photo';
        save();
        applyCfg();
        fill();
        UI.toast('铺上了');
      });
    });

    inp.click();
    setTimeout(function () {
      if (inp.parentNode) inp.parentNode.removeChild(inp);
    }, 60000);
  }

  function pickAva(who) {
    const inp = D.createElement('input');
    inp.type = 'file';
    inp.accept = 'image/*';
    inp.style.display = 'none';
    D.body.appendChild(inp);

    inp.addEventListener('change', function () {
      const f = inp.files && inp.files[0];
      if (inp.parentNode) inp.parentNode.removeChild(inp);
      if (!f) return;

      const reader = new FileReader();
      reader.onerror = function () {};
      reader.onload = function () {
        const im = new Image();
        im.onerror = function () {};
        im.onload = function () {
          const S = 200;
          const cv = D.createElement('canvas');
          cv.width = S;
          cv.height = S;
          const g = cv.getContext('2d');
          const m = Math.min(im.width, im.height);
          g.drawImage(im, (im.width - m) / 2, (im.height - m) / 2, m, m, 0, 0, S, S);

          let data = '';
          try { data = cv.toDataURL('image/jpeg', 0.82); } catch (e) { data = ''; }
          if (!data) return;

          lsSet(who === 'his' ? 'xw_ava_his' : 'xw_ava_her', data);
          paintAva(who);
        };
        im.src = reader.result;
      };
      reader.readAsDataURL(f);
    });

    inp.click();
    setTimeout(function () {
      if (inp.parentNode) inp.parentNode.removeChild(inp);
    }, 60000);
  }

  function stamp() {
    const d = new Date();
    const p = function (n) { return ('0' + n).slice(-2); };
    return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + '-' + p(d.getHours()) + p(d.getMinutes());
  }

  function transcript() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    const p = function (n) { return ('0' + n).slice(-2); };
    return list.map(function (m) {
      const d = new Date(m.t || Date.now());
      const day = d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) +
        ' ' + p(d.getHours()) + ':' + p(d.getMinutes());
      const who = m.who === 'sys' ? '系统'
        : (m.who === 'me' ? (XW.S.herName || '我') : (XW.S.hisName || '他'));
      const body = m.img ? '［图片］' : String(m.text || '');
      return day + '  ' + who + '：' + body;
    }).join('\n\n');
  }

  function download(name, text) {
    try {
      const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = D.createElement('a');
      a.href = url;
      a.download = name;
      a.style.display = 'none';
      D.body.appendChild(a);
      a.click();
      setTimeout(function () {
        if (a.parentNode) a.parentNode.removeChild(a);
        URL.revokeObjectURL(url);
      }, 5000);
      return true;
    } catch (e) { return false; }
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cs-more')) {
      e.preventDefault();
      e.stopPropagation();
      open();
      return;
    }
  }, true);

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cset-x')) { close(); return; }

    const tab = t.closest('.cset-tab');
    if (tab) {
      st.tab = tab.getAttribute('data-cp');
      save();
      fill();
      const body = D.querySelector('.cset-body');
      if (body) body.scrollTop = 0;
      return;
    }

    if (t.closest('#cset-ava-his')) { pickAva('his'); return; }
    if (t.closest('#cset-ava-her')) { pickAva('her'); return; }

    const sw = t.closest('.cset-swatch[data-bgv]');
    if (sw) {
      st.bg = String(sw.getAttribute('data-bgv'));
      save(); applyCfg(); fill();
      return;
    }

    if (t.closest('#cset-bgpick')) { pickBg(); return; }

    if (t.closest('#cset-bgclear')) {
      lsDel(BK);
      st.bg = 'none';
      save(); applyCfg(); fill();
      UI.toast('清掉了');
      return;
    }

    const dot = t.closest('.cset-dot[data-tone]');
    if (dot) {
      st.tone = String(dot.getAttribute('data-tone'));
      save(); applyCfg(); fill();
      return;
    }

    const fsBtn = t.closest('.cset-opt[data-fs]');
    if (fsBtn) {
      st.fs = String(fsBtn.getAttribute('data-fs'));
      save(); applyCfg(); fill();
      return;
    }

    const bubBtn = t.closest('.cset-opt[data-bubble]');
    if (bubBtn) {
      st.bubble = String(bubBtn.getAttribute('data-bubble'));
      save(); applyCfg(); fill();
      return;
    }

    const tBtn = t.closest('.cset-opt[data-t]');
    if (tBtn) {
      const k = tBtn.getAttribute('data-t');
      st[k] = (st[k] === '1') ? '0' : '1';
      save(); applyCfg(); fill();
      return;
    }

    if (t.closest('#cset-export')) {
      const ok = download('xiaowo-chat-' + stamp() + '.txt', transcript() || '还没有聊天记录。');
      UI.toast(ok ? '导出了' : '这台机器不让下载');
      return;
    }

    const clr = t.closest('#cset-clear');
    if (clr) {
      if (clr.getAttribute('data-armed') !== '1') {
        clr.setAttribute('data-armed', '1');
        clr.textContent = '再点一下，聊就没有了';
        setTimeout(function () {
          if (clr.getAttribute('data-armed') === '1') {
            clr.removeAttribute('data-armed');
            clr.textContent = '清空聊天';
          }
        }, 5000);
        return;
      }
      XW.S.chat = [];
      XW.save('chat');
      clr.removeAttribute('data-armed');
      clr.textContent = '清空聊天';
      UI.toast('聊天空了');
      if (window.Router && Router.reopen) Router.reopen('chat');
    }
  }, false);

  D.addEventListener('change', function (e) {
    const t = e.target;
    if (!t || !t.id) return;

    if (t.id === 'cset-his') {
      XW.S.hisName = String(t.value || '').trim() || '他';
      XW.save('hisName');
      if (window.Desktop) Desktop.rerender();
    }

    if (t.id === 'cset-her') {
      XW.S.herName = String(t.value || '').trim() || '我';
      XW.save('herName');
      if (window.Desktop) Desktop.rerender();
    }
  }, false);

  applyCfg();
  window.XWChatSet = { open: open, close: close, state: function () { return st; } };
})();
