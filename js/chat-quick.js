/* chat-quick.js · 底部那三句常用语，自己改 */
(function () {
  const D = document;
  const K = 'xw_quick';
  const DEF = ['在吗', '抱抱', '晚安'];

  function esc(t) {
    return String(t == null ? '' : t)
      .split('&').join('&amp;')
      .split('<').join('&lt;')
      .split('>').join('&gt;');
  }

  function qs() {
    let arr = null;
    try { arr = JSON.parse(localStorage.getItem(K) || 'null'); } catch (e) { arr = null; }
    if (!Array.isArray(arr) || !arr.length) return DEF.slice(0);
    return arr.map(function (x) { return String(x == null ? '' : x).trim(); })
      .filter(Boolean).slice(0, 4);
  }

  function syncQuick() {
    const quick = D.querySelector('#app-body .chat-wrap .quick');
    if (!quick) return;

    const arr = qs();
    const want = arr.join('|');
    if (quick.getAttribute('data-q') === want) return;

    quick.setAttribute('data-q', want);
    quick.innerHTML = arr.map(function (t) {
      return '<button type=button class=quick-chip data-quick>' + esc(t) + '</button>';
    }).join('');
  }

  function injectPanel() {
    const pane = D.querySelector('.cset-body');
    if (!pane || pane.querySelector('#cq-wrap')) return;

    const box = D.createElement('div');
    box.className = 'cset-sec';
    box.id = 'cq-wrap';
    box.innerHTML =
      '<div class=cset-lab>常用语</div>' +
      '<label class=cset-f>1<input id=cq0 type=text maxlength=12></label>' +
      '<label class=cset-f>2<input id=cq1 type=text maxlength=12></label>' +
      '<label class=cset-f>3<input id=cq2 type=text maxlength=12></label>' +
      '<button type=button class=cset-btn id=cq-save>存下这几句</button>';

    pane.appendChild(box);

    const arr = qs();
    [0, 1, 2].forEach(function (i) {
      const el = D.getElementById('cq' + i);
      if (el) el.value = arr[i] || '';
    });
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cq-save')) {
      const arr = [0, 1, 2].map(function (i) {
        const el = D.getElementById('cq' + i);
        return el ? String(el.value || '').trim() : '';
      }).filter(Boolean);

      if (!arr.length) { UI.toast('至少留一句'); return; }

      try { localStorage.setItem(K, JSON.stringify(arr)); } catch (err) { return; }

      const quick = D.querySelector('#app-body .chat-wrap .quick');
      if (quick) quick.removeAttribute('data-q');
      syncQuick();

      UI.toast('存下了');
      return;
    }

    const chip = t.closest('[data-quick]');
    if (chip) {
      const input = D.getElementById('chat-input');
      if (!input) return;
      input.value = String(chip.textContent || '').trim();
      input.focus();
      try { localStorage.setItem('xw_chat_draft', input.value); } catch (err) {}
    }
  }, false);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      syncQuick();
      injectPanel();
    }, 80);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  syncQuick();
  setTimeout(later, 400);
})();
