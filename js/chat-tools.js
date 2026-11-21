/* chat-tools.js · 聊天里几件用得上的小事
   草稿、回到底、失败重发、找一句话 */
(function () {
  const D = document;
  const DRAFT = 'xw_chat_draft';

  let timer = null;

  function wrapEl() {
    return D.querySelector('#app-body .chat-wrap');
  }

  /* ---------- 草稿 ---------- */

  function restoreDraft() {
    const input = D.getElementById('chat-input');
    if (!input || input.value) return;
    let v = '';
    try { v = localStorage.getItem(DRAFT) || ''; } catch (e) { v = ''; }
    if (v) input.value = v;
  }

  /* ---------- 回到底 ---------- */

  function ensureJump() {
    const wrap = wrapEl();
    if (!wrap) return;

    let btn = D.getElementById('cs-jump');
    if (!btn) {
      btn = D.createElement('button');
      btn.type = 'button';
      btn.id = 'cs-jump';
      btn.className = 'cs-jump';
      btn.textContent = '↓ 最新';
      wrap.appendChild(btn);
    }

    const scroll = D.getElementById('chat-scroll');
    if (!scroll) return;

    btn.onclick = function () {
      scroll.scrollTop = scroll.scrollHeight;
      btn.classList.remove('on');
    };

    if (!scroll.getAttribute('data-jump')) {
      scroll.setAttribute('data-jump', '1');
      scroll.addEventListener('scroll', function () {
        const far = scroll.scrollHeight - scroll.scrollTop - scroll.clientHeight;
        const b = D.getElementById('cs-jump');
        if (b) b.classList.toggle('on', far > 240);
      }, { passive: true });
    }
  }

  /* ---------- 顶部加一颗放大镜 ---------- */

  function ensureSearchBtn() {
    const wrap = wrapEl();
    if (!wrap) return;

    const more = wrap.querySelector('#cs-more');
    if (!more) return;

    let right = wrap.querySelector('.cs-top-right');
    if (right) return;

    right = D.createElement('div');
    right.className = 'cs-top-right';
    more.parentNode.insertBefore(right, more);
    right.appendChild(more);

    const s = D.createElement('button');
    s.type = 'button';
    s.id = 'cs-search';
    s.className = 'cs-more';
    s.textContent = '⌕';
    right.insertBefore(s, more);
  }

  function openFind() {
    const wrap = wrapEl();
    if (!wrap) return;

    let f = wrap.querySelector('.cs-find');
    if (f) {
      const i = f.querySelector('input');
      if (i) i.focus();
      return;
    }

    f = D.createElement('div');
    f.className = 'cs-find';
    f.innerHTML = '<input id=cs-find-in type=search placeholder=找一句话>' +
      '<button type=button class=cs-find-x id=cs-find-x>×</button>';

    const top = wrap.querySelector('.cs-top');
    wrap.insertBefore(f, top ? top.nextSibling : wrap.firstChild);

    const i = f.querySelector('input');
    if (i) i.focus();
  }

  function closeFind() {
    const f = document.querySelector('.cs-find');
    if (f && f.parentNode) f.parentNode.removeChild(f);

    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-row'), function (r) {
      r.classList.remove('cs-dim');
    });
  }

  function filter(q) {
    const rows = D.querySelectorAll('#chat-scroll .msg-row');
    const key = String(q || '').trim();
    let first = null;

    Array.prototype.forEach.call(rows, function (r) {
      r.classList.remove('cs-dim');
      if (!key) return;
      const hit = (r.textContent || '').indexOf(key) >= 0;
      if (hit) { if (!first) first = r; }
      else r.classList.add('cs-dim');
    });

    if (first && first.scrollIntoView) first.scrollIntoView({ block: 'center' });
  }

  /* ---------- 失败重发 ---------- */

  function ensureRetry() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    if (!list.length) return;

    const last = list[list.length - 1];
    if (!last || last.who !== 'sys') return;

    const evs = D.querySelectorAll('#chat-scroll .chat-event');
    if (!evs.length) return;

    const box = evs[evs.length - 1];
    if (box.querySelector('.cs-retry')) return;

    const b = D.createElement('button');
    b.type = 'button';
    b.className = 'cs-retry';
    b.textContent = '重发';
    box.appendChild(b);
  }

  function tick() {
    const wrap = wrapEl();
    if (!wrap) return;
    ensureJump();
    ensureSearchBtn();
    ensureRetry();
    restoreDraft();
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; tick(); }, 70);
  }

  /* ---------- 事件 ---------- */

  D.addEventListener('input', function (e) {
    const t = e.target;
    if (!t || !t.id) return;

    if (t.id === 'chat-input') {
      try { localStorage.setItem(DRAFT, t.value); } catch (err) {}
      return;
    }

    if (t.id === 'cs-find-in') filter(t.value);
  }, true);

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cs-search')) { openFind(); return; }
    if (t.closest('#cs-find-x')) { closeFind(); return; }

    if (t.closest('.cs-retry')) {
      const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
      for (let i = list.length - 1; i >= 0; i--) {
        if (list[i].who === 'me' && list[i].text) {
          const input = D.getElementById('chat-input');
          if (input) {
            input.value = list[i].text;
            input.focus();
          }
          UI.toast('放回输入框了，点发送');
          return;
        }
      }
    }
  }, false);

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  tick();
  setTimeout(tick, 300);
  setTimeout(tick, 900);
})();
