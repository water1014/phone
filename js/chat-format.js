/* chat-format.js · 把状态行换成图上那种写法，顺带改提示字 */
(function () {
  const D = document;

  function fmt(n) {
    const v = Number(n) || 0;
    if (v < 1000) return String(v);
    return (v / 1000).toFixed(1).replace('\.0', '') + 'k';
  }

  function retag() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    if (!list.length) return;

    const limit = Number(XW.S.ctxLimit) || 128000;
    const rounds = Number((XW.S.usage || {}).rounds) || 0;

    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-row[data-i]'), function (row) {
      const i = Number(row.getAttribute('data-i'));
      const m = list[i];
      if (!m || !m.usage) return;

      const tag = row.querySelector('.msg-tag');
      if (!tag) return;

      const input = Number(m.usage.input) || 0;
      const out = Number(m.usage.output) || 0;
      const hit = Number(m.usage.cached) || 0;
      const pct = limit ? Math.min(999, Math.round(input / limit * 100)) : 0;
      const ratio = input ? Math.round(hit / input * 100) : 0;

      const txt = pct + '% 输入' + fmt(input) +
        '·命中' + fmt(hit) + '(' + ratio + '%)' +
        '·输出' + fmt(out) +
        '·' + rounds + '轮';

      if (tag.textContent !== txt) tag.textContent = txt;
    });
  }

  function placeholder() {
    const input = D.getElementById('chat-input');
    if (input && input.getAttribute('placeholder') !== '输入消息…') {
      input.setAttribute('placeholder', '输入消息…');
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
