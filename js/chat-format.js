/* chat-format.js · 聊天页不再显示用量；用量去设置里看 */
(function () {
  const D = document;

  function retag() {
    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-row .msg-tag'), function (t) {
      if (t.style.display !== 'none') t.style.display = 'none';
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
