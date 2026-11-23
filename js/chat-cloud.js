/* chat-cloud.js · 思考链：点水滴弹整页，标题是「名字的碎碎念」
   水滴放在气泡上方那行的位置（原来放缓存率的地方） */
(function () {
  const D = document;

  const DROP = "<svg viewBox='0 0 24 24'><path d='M12 3.4c0 0 6.1 6.5 6.1 10.4a6.1 6.1 0 0 1-12.2 0C5.9 9.9 12 3.4 12 3.4z'/><path d='M9.4 13.8a2.6 2.6 0 0 0 2.2 2.9'/></svg>";

  function close() {
    const old = D.getElementById('cc-mask');
    if (old) old.remove();
  }

  function titleOf() {
    const n = String(XW.S.hisName || '').trim() || '\u4ed6';
    return n + '\u7684\u788e\u788e\u5ff5';
  }

  function open(text) {
    close();

    const mask = D.createElement('div');
    mask.id = 'cc-mask';
    mask.className = 'cc-mask';

    const card = D.createElement('div');
    card.className = 'cc-card';

    const grip = D.createElement('div');
    grip.className = 'cc-grip';
    card.appendChild(grip);

    const title = D.createElement('div');
    title.className = 'cc-title';
    title.textContent = titleOf();
    card.appendChild(title);

    const body = D.createElement('div');
    body.className = 'cc-body';
    body.textContent = String(text || '').trim();
    card.appendChild(body);

    mask.appendChild(card);

    mask.addEventListener('click', function (e) {
      if (e.target === mask || e.target === grip) close();
    });

    D.body.appendChild(mask);
  }

  function addDrop(row) {
    if (!row || row.querySelector('.cc-cloud')) return;
    const box = row.querySelector('details.think .think-body');
    if (!box) return;

    const btn = D.createElement('button');
    btn.type = 'button';
    btn.className = 'cc-cloud';
    btn.innerHTML = DROP;
    btn.setAttribute('aria-label', '\u770b\u788e\u788e\u5ff5');

    btn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      open(box.textContent);
    });

    ['touchstart', 'touchend'].forEach(function (n) {
      btn.addEventListener(n, function (e) { e.stopPropagation(); }, { passive: true });
    });

    const main = row.querySelector('.msg-main');
    if (main) {
      main.insertBefore(btn, main.firstChild);
      return;
    }

    const time = row.querySelector('.cc-time');
    if (time) {
      time.appendChild(btn);
      return;
    }

    const tag = row.querySelector('.msg-tag');
    if (tag && tag.parentNode) tag.parentNode.insertBefore(btn, tag);
  }

  function chip() {
    const com = D.querySelector('.chat-wrap .composer');
    if (!com || com.querySelector('.cc-model')) return;
    const m = String(XW.S.aiModel || '').trim();
    if (!m) return;

    const s = D.createElement('span');
    s.className = 'cc-model';
    s.textContent = m;

    const send = com.querySelector('#chat-send') || com.querySelector('.btn-solid');
    if (send && send.parentNode === com) com.insertBefore(s, send);
    else com.appendChild(s);
  }

  function tick() {
    if (!D.getElementById('chat-scroll')) return;
    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-row.ta'), addDrop);
    chip();
  }

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      tick();
    }, 120);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  tick();
  setTimeout(tick, 600);
})();
