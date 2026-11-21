/* settings-extra.js · 设置页补一块：装到桌面 / 备份 / 清空 / 重置
   router.js 不动，渲染完再 append */
(function () {
  const D = document;

  function bodyIfSettings() {
    const body = D.getElementById('app-body');
    if (!body) return null;
    if (!body.querySelector('#set-ai-provider')) return null;
    return body;
  }

  function days() {
    try { return UI.diffDay(new Date(XW.S.loveDate || '2025-01-01'), new Date()); }
    catch (e) { return 0; }
  }

  function html() {
    return '<div class="sheet" id="set-extra">' +
        '<div class="sheet-head"><span class="sheet-title">这个小窝</span><span class="kicker">HOUSE</span></div>' +
        '<div class="row-actions" style="justify-content:flex-start">' +
          '<button type="button" id="xw-install" class="btn-solid">装到桌面</button></div>' +
        '<div class="sheet-note" id="xw-install-note">装到桌面之后，从图标点开就是全屏，没有浏览器那根地址栏。</div>' +
        '<div class="row-actions">' +
          '<button type="button" id="xw-backup" class="btn-glass">导出备份</button>' +
          '<button type="button" id="xw-clearchat" class="btn-glass">清空聊天</button></div>' +
        '<div class="row-actions" style="justify-content:flex-start">' +
          '<button type="button" id="xw-reset" class="btn-glass">全部重置</button></div>' +
        '<div class="sheet-note">备份是一个 json 文件，字、图、设置都在里面。换手机之前先导一份。</div>' +
        '<div class="sheet-note">已经过了 ' + days() + ' 天 · 仓库 water1014/phone</div>' +
      '</div>';
  }

  function inject() {
    const body = bodyIfSettings();
    if (!body) return;
    if (D.getElementById('set-extra')) return;

    const box = D.createElement('div');
    box.innerHTML = html();
    body.appendChild(box.firstChild);

    const note = D.getElementById('xw-install-note');
    if (note && window.XWPWA && XWPWA.can) {
      note.textContent = '直接点「装到桌面」，确认一下就行。';
    }
  }

  function stamp() {
    const d = new Date();
    const p = function (n) { return ('0' + n).slice(-2); };
    return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) +
      '-' + p(d.getHours()) + p(d.getMinutes());
  }

  function dump() {
    const out = {};
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i);
      out[k] = localStorage.getItem(k);
    }
    return JSON.stringify(out);
  }

  function saveFile(name, text) {
    try {
      const blob = new Blob([text], { type: 'application/json' });
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

  function arm(btn, label, rest) {
    if (btn.getAttribute('data-armed') === '1') return true;
    btn.setAttribute('data-armed', '1');
    const old = btn.textContent;
    btn.textContent = label;
    setTimeout(function () {
      if (btn.getAttribute('data-armed') === '1') {
        btn.removeAttribute('data-armed');
        btn.textContent = old;
      }
    }, rest || 5000);
    return false;
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.id) return;

    if (t.id === 'xw-install') {
      const ok = (window.XWPWA && XWPWA.install) ? XWPWA.install() : false;
      UI.toast(ok ? '就这样，确认一下' : '用浏览器菜单里的「添加到主屏幕」也行');
      return;
    }

    if (t.id === 'xw-backup') {
      const ok = saveFile('xiaowo-' + stamp() + '.json', dump());
      UI.toast(ok ? '存了一份，去下载里看看' : '这台机器不让下载');
      return;
    }

    if (t.id === 'xw-clearchat') {
      if (!arm(t, '再点一下，聊就没有了')) return;
      XW.S.chat = [];
      XW.save('chat');
      t.removeAttribute('data-armed');
      UI.toast('聊天空了');
      if (window.Router && Router.reopen) Router.reopen('settings');
      return;
    }

    if (t.id === 'xw-reset') {
      if (!arm(t, '再点一下，全没了')) return;
      try { localStorage.clear(); } catch (err) {}
      location.reload();
    }
  }, false);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; inject(); }, 70);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  inject();
  setTimeout(inject, 400);
})();
