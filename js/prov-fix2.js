/* prov-fix2.js · 把「服务商 / 地址」串错的那种情况修回来
   拉模型前先把输入框落盘，否则一重绘就回旧值 */
(function () {
  const D = document;

  const P = {
    deepseek: { url: 'https://api.deepseek.com', model: 'deepseek-chat', ctx: '128000' },
    opencode: { url: 'https://opencode.ai/inference/go', model: 'deepseek-v4.1-flash', ctx: '128000' },
    openai: { url: '', model: '', ctx: '128000' }
  };

  function val(id) {
    const el = D.getElementById(id);
    return el ? String(el.value || '').trim() : '';
  }

  function prov() {
    const sel = D.getElementById('set-ai-provider');
    return sel ? (sel.value || 'deepseek') : (XW.S.aiProvider || 'deepseek');
  }

  function syncDom() {
    const p = prov();
    const url = val('set-ai-url');
    const model = val('set-ai-model');
    const key = val('set-ai-key');
    const headers = val('set-ai-headers');
    const ctx = val('set-ctx');

    XW.S.aiProvider = p;
    XW.S.aiUrl = url;
    XW.S.aiModel = model;
    XW.S.aiKey = key;
    XW.S.aiHeaders = headers;
    if (ctx) XW.S.ctxLimit = Number(ctx) || 128000;

    XW.S.profiles = XW.S.profiles || {};
    XW.S.profiles[p] = { url: url, model: model, key: key, headers: headers };

    ['aiProvider', 'aiUrl', 'aiModel', 'aiKey', 'aiHeaders', 'ctxLimit', 'profiles'].forEach(XW.save);
  }

  function heal() {
    const pr = XW.S.profiles;
    let changed = false;

    if (pr && typeof pr === 'object') {
      Object.keys(pr).forEach(function (k) {
        const preset = P[k];
        if (!preset || !preset.url) return;
        const u = String(pr[k].url || '');
        if (!u) return;
        if (k !== 'opencode' && u.indexOf('opencode') >= 0) { pr[k].url = preset.url; changed = true; }
        if (k === 'opencode' && u.indexOf('deepseek.com') >= 0) { pr[k].url = preset.url; changed = true; }
      });
      if (changed) XW.save('profiles');
    }

    const cur = XW.S.aiProvider || 'deepseek';
    const preset = P[cur];
    const url = String(XW.S.aiUrl || '');

    if (preset && preset.url && cur !== 'opencode' && url.indexOf('opencode') >= 0) {
      XW.S.aiUrl = preset.url;
      XW.S.aiUrlResolved = '';
      XW.save('aiUrl');
      XW.save('aiUrlResolved');
    }
  }

  function paintBox() {
    const wrap = D.getElementById('prov-box');
    if (!wrap) return;

    if (!wrap.querySelector('#prov-clear')) {
      const b = D.createElement('button');
      b.type = 'button';
      b.className = 'prov-btn';
      b.id = 'prov-clear';
      b.textContent = '清掉这家的记录';
      wrap.appendChild(b);
    }

    if (!wrap.querySelector('.prov-warn')) {
      const p = prov();
      const preset = P[p] || P.openai;
      const cur = String(XW.S.aiUrl || '');
      if (preset.url && cur && cur !== preset.url) {
        const w = D.createElement('div');
        w.className = 'prov-line prov-warn';
        w.textContent = '现在存着的是 ' + cur + '，不是这家的。点「按这家填好」再保存一次。';
        wrap.insertBefore(w, wrap.firstChild);
      }
    }
  }

  function clearProfile() {
    const p = prov();
    if (XW.S.profiles) delete XW.S.profiles[p];
    XW.save('profiles');

    const preset = P[p] || P.openai;
    const urlEl = D.getElementById('set-ai-url');
    const modelEl = D.getElementById('set-ai-model');
    const ctxEl = D.getElementById('set-ctx');

    if (urlEl) urlEl.value = preset.url;
    if (modelEl) modelEl.value = preset.model;
    if (ctxEl) ctxEl.value = preset.ctx;

    XW.S.aiProvider = p;
    XW.S.aiUrl = preset.url;
    XW.S.aiModel = preset.model;
    XW.S.aiUrlResolved = '';
    ['aiProvider', 'aiUrl', 'aiModel', 'aiUrlResolved'].forEach(XW.save);

    const old = D.querySelector('.prov-warn');
    if (old && old.parentNode) old.parentNode.removeChild(old);

    UI.toast('这家的记录清掉了');
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#set-pull-models')) {
      syncDom();
      return;
    }

    if (t.closest('#prov-fill')) {
      setTimeout(function () { syncDom(); paintBox(); }, 40);
      return;
    }

    if (t.closest('#prov-clear')) {
      clearProfile();
      return;
    }
  }, true);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; paintBox(); }, 140);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  heal();
  setTimeout(paintBox, 600);
})();
