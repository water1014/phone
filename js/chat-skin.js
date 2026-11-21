/* chat-skin.js · 聊天页顶部双头像 + 输入栏加一颗心
   router.js 不动，渲染完再插。属性一律不写引号，省得惹麻烦 */
(function () {
  const D = document;
  const ROOT = D.documentElement;

  function esc(t) {
    return String(t == null ? '' : t)
      .split('&').join('&amp;')
      .split('<').join('&lt;')
      .split('>').join('&gt;');
  }

  function nameOf(who) {
    const raw = who === 'his' ? XW.S.hisName : XW.S.herName;
    return String(raw == null ? '' : raw).trim() || (who === 'his' ? '他' : '她');
  }

  function avaOf(who) {
    try { return localStorage.getItem(who === 'his' ? 'xw_ava_his' : 'xw_ava_her') || ''; }
    catch (e) { return ''; }
  }

  function one(who) {
    const src = avaOf(who);
    const label = esc(nameOf(who));
    let inner = label.charAt(0);
    if (src && src.indexOf(' ') < 0) inner = '<img src=' + src + '>';
    return '<div class=cs-one><span class=cs-ava>' + inner +
      '</span><b>' + label + '</b></div>';
  }

  function topHtml() {
    return '<div class=cs-top>' +
        '<button type=button class=cs-back id=cs-back>‹</button>' +
        '<div class=cs-pair>' + one('his') +
          '<span class=cs-heart>♥</span>' + one('her') + '</div>' +
        '<button type=button class=cs-more id=cs-more>···</button>' +
      '</div>';
  }

  function decorate() {
    const body = D.getElementById('app-body');
    const wrap = body && body.querySelector('.chat-wrap');
    if (!wrap) return false;

    if (!wrap.querySelector('.cs-top')) {
      const box = D.createElement('div');
      box.innerHTML = topHtml();
      wrap.insertBefore(box.firstChild, wrap.firstChild);
    }

    const composer = wrap.querySelector('.composer');
    if (composer && !composer.querySelector('#cs-heart')) {
      const b = D.createElement('button');
      b.type = 'button';
      b.id = 'cs-heart';
      b.className = 'cs-heart-btn';
      b.textContent = '♡';
      composer.appendChild(b);
    }

    return true;
  }

  function tick() {
    const app = D.getElementById('app');
    const isChat = !!(app && app.classList.contains('show') &&
      D.getElementById('chat-scroll') && D.querySelector('.chat-wrap'));

    if (isChat) {
      ROOT.setAttribute('data-page', 'chat');
      decorate();
    } else if (ROOT.getAttribute('data-page') === 'chat') {
      ROOT.removeAttribute('data-page');
    }
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cs-back')) {
      if (window.Router) Router.back();
      return;
    }

    if (t.closest('#cs-more')) {
      if (window.Router) Router.open('settings');
      return;
    }

    if (t.closest('#cs-heart')) {
      const input = D.getElementById('chat-input');
      if (!input) return;
      input.value = (input.value || '') + '♡';
      input.focus();
    }
  }, false);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; tick(); }, 60);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });

    const app = D.getElementById('app');
    if (app) {
      new MutationObserver(tick).observe(app, { attributes: true, attributeFilter: ['class'] });
    } else {
      let w = new MutationObserver(function () {
        const a = D.getElementById('app');
        if (!a) return;
        w.disconnect();
        w = null;
        new MutationObserver(tick).observe(a, { attributes: true, attributeFilter: ['class'] });
        tick();
      });
      w.observe(D.body, { childList: true });
    }
  }

  tick();
  setTimeout(tick, 400);
})();
