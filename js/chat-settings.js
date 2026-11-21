/* chat-settings.js · 聊天自己的设置面板
   点右上三个点打开，不跳去全局设置 */
(function () {
  const D = document;
  const ROOT = D.documentElement;
  const K = 'xw_chatcfg';

  const DEF = { fs: '0.8', think: '1', usage: '1', time: '1' };

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

  function applyCfg() {
    ROOT.style.setProperty('--cs-fs', st.fs + 'rem');
    ROOT.setAttribute('data-chat-think', st.think);
    ROOT.setAttribute('data-chat-usage', st.usage);
    ROOT.setAttribute('data-chat-time', st.time);
  }

  function build() {
    const p = D.createElement('div');
    p.className = 'cset';
    p.id = 'cset';

    p.innerHTML =
      '<div class=cset-head><b>聊天设置</b>' +
        '<button type=button id=cset-x>×</button></div>' +
      '<div class=cset-body>' +

        '<div class=cset-sec><div class=cset-lab>称呼</div>' +
          '<label class=cset-f>他<input id=cset-his type=text></label>' +
          '<label class=cset-f>我<input id=cset-her type=text></label></div>' +

        '<div class=cset-sec><div class=cset-lab>头像</div>' +
          '<div class=cset-row>' +
            '<button type=button class=cset-ava id=cset-ava-his>他</button>' +
            '<button type=button class=cset-ava id=cset-ava-her>我</button>' +
          '</div>' +
          '<div class=cset-note>点头像换图。和天数卡共用同一张，这边改了那里也跟着变。</div></div>' +

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
          '</div></div>' +

        '<div class=cset-sec><div class=cset-lab>记录</div>' +
          '<div class=cset-row>' +
            '<button type=button class=cset-btn id=cset-export>导出聊天</button>' +
            '<button type=button class="cset-btn danger" id=cset-clear>清空聊天</button>' +
          '</div></div>' +

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

    ['think', 'usage', 'time'].forEach(function (k) {
      const b = D.querySelector('.cset-opt[data-t=' + k + ']');
      if (b) b.classList.toggle('on', st[k] === '1');
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

    if (t.closest('#cset-x')) {
      close();
      return;
    }

    if (t.closest('#cset-ava-his')) { pickAva('his'); return; }
    if (t.closest('#cset-ava-her')) { pickAva('her'); return; }

    const fsBtn = t.closest('.cset-opt[data-fs]');
    if (fsBtn) {
      st.fs = String(fsBtn.getAttribute('data-fs'));
      save();
      applyCfg();
      fill();
      return;
    }

    const tBtn = t.closest('.cset-opt[data-t]');
    if (tBtn) {
      const k = tBtn.getAttribute('data-t');
      st[k] = (st[k] === '1') ? '0' : '1';
      save();
      applyCfg();
      fill();
      return;
    }

    if (t.closest('#cset-export')) {
      const text = transcript();
      const ok = download('xiaowo-chat-' + stamp() + '.txt', text || '还没有聊天记录。');
      UI.toast(ok ? '导出了' : '这台机器不让下载');
      return;
    }

    if (t.closest('#cset-clear')) {
      const b = t.closest('#cset-clear');
      if (b.getAttribute('data-armed') !== '1') {
        b.setAttribute('data-armed', '1');
        b.textContent = '再点一下，聊就没有了';
        setTimeout(function () {
          if (b.getAttribute('data-armed') === '1') {
            b.removeAttribute('data-armed');
            b.textContent = '清空聊天';
          }
        }, 5000);
        return;
      }
      XW.S.chat = [];
      XW.save('chat');
      b.removeAttribute('data-armed');
      b.textContent = '清空聊天';
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
