/* chat-format.js · 每条消息头上那行只留缓存率 */
(function () {
  const D = document;

  function retag() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    if (!list.length) return;

    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-row[data-i]'), function (row) {
      const i = Number(row.getAttribute('data-i'));
      const m = list[i];
      if (!m || !m.usage) return;

      const tag = row.querySelector('.msg-tag');
      if (!tag) return;

      const input = Number(m.usage.input) || 0;
      const hit = Number(m.usage.cached) || 0;
      const ratio = input ? Math.round(hit / input * 100) : 0;

      const txt = '\u7f13\u5b58 ' + ratio + '%';
      if (tag.textContent !== txt) tag.textContent = txt;
    });
  }

  function placeholder() {
    const input = D.getElementById('chat-input');
    if (input && input.getAttribute('placeholder') !== '\u8f93\u5165\u6d88\u606f\u2026') {
      input.setAttribute('placeholder', '\u8f93\u5165\u6d88\u606f\u2026');
    }
  }

  let timer = null;

  function tick() {
    if (!D.getElementById('chat-scroll')) return;
    retag();
    placeholder();
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; tick(); }, 90);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  tick();
  setTimeout(tick, 500);
})();
