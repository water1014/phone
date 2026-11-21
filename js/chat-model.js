/* chat-model.js · 聊天设置顶部：看上次回复到底带没带思考 */
(function () {
  const D = document;

  function current() {
    return String(XW.S.aiModel || '').trim();
  }

  function provider() {
    return String(XW.S.aiProvider || '').trim() || 'deepseek';
  }

  function last() {
    return window.XW_LAST || null;
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

  function textOf() {
    const m = current();
    const l = last();
    if (!m) return '模型还没填';
    let s = '模型 ' + m;
    if (!l) {
      s += ' \u00b7 \u8fd8\u6ca1\u804a\u8fc7';
    } else {
      s += l.think ? ' \u00b7 \u4e0a\u6b21\u5e26\u7740\u601d\u8003' : ' \u00b7 \u4e0a\u6b21\u6ca1\u5e26\u601d\u8003';
    }
    return s;
  }

  function kindOf() {
    const l = last();
    if (!l) return '';
    return l.think ? 'ok' : 'no';
  }

  let boxEl = null;
  let lineEl = null;
  let btnEl = null;

  function sync() {
    if (lineEl) {
      lineEl.textContent = textOf();
      lineEl.className = 'cd-line ' + kindOf();
    }
    if (btnEl) {
      const l = last();
      const show = !!(l && !l.think) || !l;
      btnEl.style.display = show ? '' : 'none';
    }
  }

  function build() {
    const box = D.createElement('div');
    box.className = 'cd-row';

    lineEl = D.createElement('div');
    lineEl.className = 'cd-line';
    box.appendChild(lineEl);

    btnEl = D.createElement('button');
    btnEl.type = 'button';
    btnEl.className = 'cd-btn';
    btnEl.textContent = '\u6362\u6210 deepseek-reasoner';
    btnEl.addEventListener('click', function () {
      apply('deepseek-reasoner');
      if (lineEl) {
        lineEl.textContent = '\u6a21\u578b deepseek-reasoner \u00b7 \u4e0b\u4e00\u6761\u5c31\u77e5\u9053';
        lineEl.className = 'cd-line ok';
      }
      btnEl.style.display = 'none';
    });
    box.appendChild(btnEl);

    sync();
    return box;
  }

  let timer = null;

  function render() {
    const p = D.querySelector('.cset');
    if (!p) return;
    if (boxEl && D.contains(boxEl)) { sync(); return; }
    boxEl = build();
    p.insertBefore(boxEl, p.firstChild);
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 150);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  setTimeout(render, 700);
})();
