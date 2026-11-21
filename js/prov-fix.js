/* prov-fix.js · 服务商跟地址、模型、上下文上限对起来
   router.js 不动，渲染完在旁边补一块 */
(function () {
  const D = document;
  const K = 'xw_ctx_map';

  const P = {
    deepseek: {
      label: 'DeepSeek',
      url: 'https://api.deepseek.com',
      model: 'deepseek-chat',
      ctx: '128000',
      note: '地址填到域名就行，会自动接 /v1/chat/completions',
      session: false
    },
    opencode: {
      label: 'OpenCode Go',
      url: 'https://opencode.ai/inference/go',
      model: 'deepseek-v4.1-flash',
      ctx: '128000',
      note: '浏览器直连会被跨域挡，要的话走本机 proxy',
      session: true
    },
    openai: {
      label: 'OpenAI 兼容',
      url: '',
      model: '',
      ctx: '128000',
      note: '填你自己那家的地址，一般是 …/v1',
      session: false
    }
  };

  let prevProv = null;
  let timer = null;

  function ctxMap() {
    try { return JSON.parse(localStorage.getItem(K) || '{}') || {}; }
    catch (e) { return {}; }
  }

  function setCtxOf(prov, v) {
    const m = ctxMap();
    m[prov] = String(v);
    try { localStorage.setItem(K, JSON.stringify(m)); } catch (e) {}
  }

  function ctxOf(prov) {
    const m = ctxMap();
    return m[prov] || (P[prov] && P[prov].ctx) || '128000';
  }

  function inject() {
    const sel = D.getElementById('set-ai-provider');
    if (!sel) return;

    const field = sel.closest('.field');
    if (!field || !field.parentNode) return;

    let box = D.getElementById('prov-box');
    if (!box) {
      box = D.createElement('div');
      box.id = 'prov-box';
      box.className = 'prov-box';
      field.parentNode.insertBefore(box, field.nextSibling);
    }

    const prov = sel.value || 'deepseek';
    const p = P[prov] || P.openai;

    box.innerHTML =
      '<div class=prov-line>地址 ' + (p.url || '（你自己填）') + '</div>' +
      '<div class=prov-line>模型 ' + (p.model || '（你自己填）') +
        ' · 上下文 ' + ctxOf(prov) + '</div>' +
      '<div class="prov-line prov-soft">' + p.note + '</div>' +
      '<button type=button class=prov-btn id=prov-fill>按这家填好</button>';
  }

  function fillCurrent() {
    const sel = D.getElementById('set-ai-provider');
    const prov = sel ? (sel.value || 'deepseek') : 'deepseek';
    const p = P[prov] || P.openai;

    const urlEl = D.getElementById('set-ai-url');
    const modelEl = D.getElementById('set-ai-model');
    const ctxEl = D.getElementById('set-ctx');
    const headEl = D.getElementById('set-ai-headers');

    if (urlEl && p.url) urlEl.value = p.url;
    if (modelEl && p.model) modelEl.value = p.model;
    if (ctxEl) ctxEl.value = p.ctx;
    if (headEl && prov === 'opencode' && !headEl.value.trim()) headEl.value = '{}';

    UI.toast('填好了，贴上 Key 再保存');
    inject();
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (t && t.closest && t.closest('#prov-fill')) fillCurrent();
  }, false);

  D.addEventListener('change', function (e) {
    if (e.target && e.target.id === 'set-ai-provider') {
      prevProv = XW.S.aiProvider || 'deepseek';
    }
  }, true);

  D.addEventListener('change', function (e) {
    if (!e.target || e.target.id !== 'set-ai-provider') return;

    const oldCtx = D.getElementById('set-ctx');
    if (oldCtx && prevProv && prevProv !== e.target.value) setCtxOf(prevProv, oldCtx.value);

    const next = e.target.value || 'deepseek';

    setTimeout(function () {
      const c = D.getElementById('set-ctx');
      if (c) c.value = ctxOf(next);
      inject();
    }, 70);
  }, false);

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      inject();
    }, 90);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  inject();
  setTimeout(inject, 500);
})();
