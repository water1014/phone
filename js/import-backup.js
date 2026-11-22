/* import-backup.js · 把导出的 json 读回来（导出在 settings-extra.js） */
(function () {
  const D = document;
  const BAK = 'xw_bak_before_import';
  let pending = null;

  function holder() { return D.getElementById('set-extra'); }

  function dump() {
    const out = {};
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i);
      out[k] = localStorage.getItem(k);
    }
    return out;
  }

  function count(v) {
    try {
      const a = JSON.parse(v);
      return Array.isArray(a) ? a.length : -1;
    } catch (e) { return -1; }
  }

  function stat(data) {
    let chat = -1, diary = -1, photo = -1, n = 0;
    Object.keys(data).forEach(function (k) {
      n++;
      const c = count(data[k]);
      if (c < 0) return;
      if (chat < 0 && /chat/i.test(k)) chat = c;
      else if (diary < 0 && /diar/i.test(k)) diary = c;
      else if (photo < 0 && /photo|album|img/i.test(k)) photo = c;
    });
    const bits = [n + ' \u9879'];
    if (chat >= 0) bits.push('\u804a\u5929 ' + chat + ' \u6761');
    if (diary >= 0) bits.push('\u65e5\u8bb0 ' + diary + ' \u7bc7');
    if (photo >= 0) bits.push('\u7167\u7247 ' + photo + ' \u5f20');
    return bits.join(' \u00b7 ');
  }

  function card(html) {
    const b = holder();
    if (!b) return;
    let c = D.getElementById('xw-import-card');
    if (!c) {
      c = D.createElement('div');
      c.id = 'xw-import-card';
      c.className = 'xw-ic';
      b.appendChild(c);
    }
    c.innerHTML = html;
  }

  function clearCard() {
    const c = D.getElementById('xw-import-card');
    if (c) c.remove();
  }

  function pick() {
    const inp = D.getElementById('xw-import-file');
    if (inp) inp.click();
  }

  function onFile(e) {
    const f = e.target.files && e.target.files[0];
    e.target.value = '';
    if (!f) return;

    const r = new FileReader();
    r.onload = function () {
      let data = null;
      try { data = JSON.parse(String(r.result || '')); } catch (err) { data = null; }

      if (!data || typeof data !== 'object' || Array.isArray(data) || !Object.keys(data).length) {
        UI.toast('\u8fd9\u4e2a\u6587\u4ef6\u8bfb\u4e0d\u51fa\u6765\uff0c\u662f\u4e0d\u662f\u9009\u9519\u4e86');
        return;
      }

      const clean = {};
      Object.keys(data).forEach(function (k) {
        if (typeof data[k] === 'string') clean[k] = data[k];
      });

      if (!Object.keys(clean).length) {
        UI.toast('\u6587\u4ef6\u91cc\u6ca1\u6709\u80fd\u7528\u7684\u4e1c\u897f');
        return;
      }

      pending = clean;
      card(
        '<div class="xw-ic-name">' + f.name.replace(/[<>&]/g, '') + '</div>' +
        '<div class="xw-ic-stat">' + stat(clean) + '</div>' +
        '<div class="xw-ic-warn">\u5bfc\u5165\u4f1a\u76d6\u6389\u8fd9\u53f0\u624b\u673a\u4e0a\u73b0\u5728\u7684\u5168\u90e8\u5185\u5bb9\u3002\u5199\u4e4b\u524d\u6211\u5148\u628a\u73b0\u5728\u7684\u5b58\u4e00\u4efd\uff0c\u5bfc\u9519\u4e86\u8fd8\u80fd\u9000\u56de\u53bb\u3002</div>' +
        '<div class="xw-ic-row">' +
          '<button type="button" id="xw-import-go" class="btn-solid">\u5c31\u8fd9\u4e2a\uff0c\u5bfc\u5165</button>' +
          '<button type="button" id="xw-import-no" class="btn-glass">\u7b97\u4e86</button>' +
        '</div>'
      );
    };

    r.readAsText(f);
  }

  function go() {
    if (!pending) return;

    try { localStorage.setItem(BAK, JSON.stringify(dump())); } catch (e) {}

    const keys = Object.keys(pending);
    let done = 0;
    keys.forEach(function (k) {
      try { localStorage.setItem(k, pending[k]); done++; } catch (e) {}
    });

    pending = null;
    card('<div class="xw-ic-stat">\u5199\u8fdb\u53bb\u4e86 ' + done + ' \u9879\uff0c\u9a6c\u4e0a\u91cd\u65b0\u5f00\u4e00\u6b21\u3002</div>');
    setTimeout(function () { location.reload(); }, 900);
  }

  function undo(btn) {
    const raw = localStorage.getItem(BAK);
    if (!raw) {
      UI.toast('\u6ca1\u6709\u53ef\u64a4\u9500\u7684\u5907\u4efd');
      return;
    }

    if (btn.getAttribute('data-armed') !== '1') {
      const old = btn.textContent;
      btn.setAttribute('data-armed', '1');
      btn.textContent = '\u518d\u70b9\u4e00\u4e0b\uff0c\u9000\u56de\u5bfc\u5165\u524d';
      setTimeout(function () {
        btn.removeAttribute('data-armed');
        btn.textContent = old;
      }, 5000);
      return;
    }

    let data = null;
    try { data = JSON.parse(raw); } catch (e) { data = null; }
    if (!data) {
      UI.toast('\u90a3\u4efd\u5907\u4efd\u574f\u4e86');
      return;
    }

    Object.keys(data).forEach(function (k) {
      try { localStorage.setItem(k, data[k]); } catch (e) {}
    });
    try { localStorage.removeItem(BAK); } catch (e) {}

    location.reload();
  }

  function inject() {
    const b = holder();
    if (!b) return;

    if (!D.getElementById('xw-import')) {
      const btn = D.createElement('button');
      btn.type = 'button';
      btn.id = 'xw-import';
      btn.className = 'btn-glass';
      btn.textContent = '\u5bfc\u5165\u5907\u4efd';

      const bak = D.getElementById('xw-backup');
      const row = bak && bak.parentNode;
      if (row && row.insertBefore) row.insertBefore(btn, bak.nextSibling);
      else b.appendChild(btn);

      const inp = D.createElement('input');
      inp.type = 'file';
      inp.id = 'xw-import-file';
      inp.accept = '.json,application/json';
      inp.style.display = 'none';
      inp.addEventListener('change', onFile, false);
      b.appendChild(inp);
    }

    if (localStorage.getItem(BAK) && !D.getElementById('xw-import-undo')) {
      const u = D.createElement('button');
      u.type = 'button';
      u.id = 'xw-import-undo';
      u.className = 'btn-glass';
      u.textContent = '\u64a4\u9500\u4e0a\u6b21\u5bfc\u5165';

      const bak = D.getElementById('xw-backup');
      const row = bak && bak.parentNode;
      if (row) row.appendChild(u);
      else b.appendChild(u);
    }
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.id) return;

    if (t.id === 'xw-import') { pick(); return; }
    if (t.id === 'xw-import-go') { go(); return; }
    if (t.id === 'xw-import-no') { pending = null; clearCard(); return; }
    if (t.id === 'xw-import-undo') { undo(t); return; }
  }, false);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; inject(); }, 80);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  inject();
  setTimeout(inject, 500);
})();
