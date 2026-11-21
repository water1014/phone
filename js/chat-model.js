/* chat-model.js · 聊天设置顶部：显示当前模型、能不能带思考链，可一键换 */
(function () {
  const D = document;

  function canThink(model) {
    return /reason|r1|r2|thinking|qwq|o1|o3|o4/i.test(String(model || ''));
  }

  function current() {
    return String(XW.S.aiModel || '').trim();
  }

  function provider() {
    return String(XW.S.aiProvider || '').trim() || 'deepseek';
  }

  function apply(model) {
    XW.S.aiModel = model;
    XW.save('aiModel');
    XW.S.profiles = XW.S.profiles || {};
    const name = provider();
    const old = XW.S.profiles[name] || {};
    XW.S.profiles[name] = Object.assign({}, old, { model: model });
    XW.save('profiles');
  }

  function build() {
    const box = D.createElement('div');
    box.className = 'cd-row';

    const line = D.createElement('div');
    line.className = 'cd-line';
    const m = current();
    const ok = canThink(m);
    line.textContent = '模型 ' + (m || '(未填)') + (ok ? ' · 会带思考链' : ' · 不带思考链');
    line.classList.add(ok ? 'ok' : 'no');
    box.appendChild(line);

    if (!ok) {
      const btn = D.createElement('button');
      btn.type = 'button';
      btn.className = 'cd-btn';
      btn.textContent = '换成 deepseek-reasoner';
      btn.addEventListener('click', function () {
        apply('deepseek-reasoner');
        line.textContent = '模型 deepseek-reasoner · 会带思考链';
        line.classList.remove('no');
        line.classList.add('ok');
        btn.remove();
      });
      box.appendChild(btn);
    }
    return box;
  }

  let boxEl = null;
  let timer = null;

  function render() {
    const p = D.querySelector('.cset');
    if (!p) return;
    if (boxEl && D.contains(boxEl)) {
      if (boxEl.textContent.indexOf(current() || '(未填)') >= 0) return;
      const next = build();
      boxEl.parentNode.replaceChild(next, boxEl);
      boxEl = next;
      return;
    }
    boxEl = build();
    p.insertBefore(boxEl, p.firstChild);
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 130);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  setTimeout(render, 600);
})();
