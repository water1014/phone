/* api-panel.js · 「接线的地方」重做成一张完整表单
   分段选服务商 / 地址带说明 / 模型可拉取 / 温度 / 最大输出
   全部都真写进请求 */
(function () {
  const D = document;

  const PROV = {
    deepseek: { label: 'DeepSeek', url: 'https://api.deepseek.com', model: 'deepseek-chat', ctx: 128000 },
    opencode: { label: 'OpenCode Go', url: 'https://opencode.ai/inference/go', model: 'deepseek-v4.1-flash', ctx: 128000 },
    openai: { label: 'OpenAI \u517c\u5bb9', url: '', model: '', ctx: 128000 }
  };

  const ORDER = ['deepseek', 'opencode', 'openai'];

  function ls(k, d) {
    try {
      const v = localStorage.getItem(k);
      return v == null || v === '' ? d : v;
    } catch (e) { return d; }
  }

  function lsSet(k, v) {
    try { localStorage.setItem(k, String(v)); } catch (e) {}
  }

  function infer() { return String((XW.S && XW.S.aiProvider) || 'deepseek'); }

  function profOf(name) {
    const all = (XW.S && XW.S.profiles) || {};
    const saved = all[name] || null;
    const p = PROV[name] || PROV.openai;
    return {
      url: saved && saved.url ? saved.url : (p.url || ''),
      model: saved && saved.model ? saved.model : (p.model || ''),
      key: saved && saved.key ? saved.key : '',
      headers: saved && saved.headers !== undefined ? saved.headers : ''
    };
  }

  const st = {
    provider: infer(),
    url: String((XW.S && XW.S.aiUrl) || ''),
    model: String((XW.S && XW.S.aiModel) || ''),
    key: String((XW.S && XW.S.aiKey) || ''),
    headers: String((XW.S && XW.S.aiHeaders) || ''),
    ctx: Number((XW.S && XW.S.ctxLimit) || 128000),
    temp: Number(ls('xw_ai_temp', 0.9)),
    maxout: Number(ls('xw_ai_maxout', 1024))
  };

  function flush() {
    XW.S.aiProvider = st.provider;
    XW.S.aiUrl = st.url;
    XW.S.aiModel = st.model;
    XW.S.aiKey = st.key;
    XW.S.aiHeaders = st.headers;
    XW.S.ctxLimit = Number(st.ctx) || 128000;
    XW.S.aiUrlResolved = '';
    XW.S.profiles = XW.S.profiles || {};
    XW.S.profiles[st.provider] = {
      url: st.url, model: st.model, key: st.key, headers: st.headers
    };
    ['aiProvider', 'aiUrl', 'aiModel', 'aiKey', 'aiHeaders', 'ctxLimit', 'aiUrlResolved', 'profiles']
      .forEach(function (k) { XW.save(k); });
    lsSet('xw_ai_temp', st.temp);
    lsSet('xw_ai_maxout', st.maxout);
  }

  let saveTimer = null;
  function autoSave() {
    if (saveTimer) clearTimeout(saveTimer);
    saveTimer = setTimeout(function () {
      saveTimer = null;
      flush();
      mark();
    }, 400);
  }

  function base(u) {
    return String(u || '').trim().replace(/\/+$/, '').replace(/\/chat\/completions$/, '');
  }

  function endpoints(u) {
    const b = base(u);
    if (!b) return [];
    const out = [];
    if (/\/v\d+$/.test(b)) out.push(b + '/chat/completions');
    out.push(b + '/v1/chat/completions');
    out.push(b + '/chat/completions');
    return out;
  }

  function headersOf(key, raw) {
    const h = { 'Content-Type': 'application/json' };
    const k = String(key || '').trim();
    if (k) h.Authorization = 'Bearer ' + k;
    if (raw) {
      try {
        const o = JSON.parse(raw);
        if (o && typeof o === 'object' && !Array.isArray(o)) {
          Object.keys(o).forEach(function (n) {
            if (typeof o[n] === 'string') h[n] = o[n];
          });
        }
      } catch (e) {}
    }
    if (st.provider === 'opencode' && !h['x-opencode-session']) {
      h['x-opencode-session'] = 'xw-' + Date.now().toString(36);
    }
    return h;
  }

  function el(tag, cls, txt) {
    const n = D.createElement(tag);
    if (cls) n.className = cls;
    if (txt != null) n.textContent = txt;
    return n;
  }

  function mkField(label, hint, input) {
    const box = el('label', 'api-field');
    box.appendChild(el('span', 'api-cap', label));
    box.appendChild(input);
    if (hint) box.appendChild(el('em', 'api-hint', hint));
    return box;
  }

  function mkInput(type, value, ph) {
    const i = D.createElement('input');
    i.type = type || 'text';
    i.value = value == null ? '' : String(value);
    i.spellcheck = false;
    if (ph) i.placeholder = ph;
    return i;
  }

  let liveEl = null;
  let tempOut = null;
  let chipsEl = null;
  let resEl = null;

  function mark() {
    if (!liveEl) return;
    const bits = [];
    bits.push((PROV[st.provider] || PROV.openai).label);
    bits.push(st.model || '\u6ca1\u586b\u6a21\u578b');
    bits.push(st.key ? '\u6709 Key' : '\u6ca1 Key');
    bits.push(st.url ? '\u6709\u5730\u5740' : '\u6ca1\u5730\u5740');
    liveEl.textContent = bits.join(' \u00b7 ');
  }

  function drawChips() {
    if (!chipsEl) return;
    chipsEl.textContent = '';
    const list = Array.isArray(XW.S.modelList) ? XW.S.modelList : [];

    if (!list.length) {
      chipsEl.appendChild(el('div', 'api-note', '\u5148\u70b9\u300c\u62c9\u53d6\u300d\uff0c\u62c9\u56de\u6765\u5c31\u80fd\u76f4\u63a5\u70b9\uff0c\u4e0d\u7528\u624b\u6253\u3002'));
      return;
    }

    list.forEach(function (id) {
      const b = el('button', 'api-chip' + (id === st.model ? ' on' : ''), id);
      b.type = 'button';
      b.addEventListener('click', function () {
        st.model = String(id);
        if (modelInput) modelInput.value = st.model;
        drawChips();
        flush();
        mark();
        UI.toast('\u6a21\u578b\u6362\u6210 ' + id);
      });
      chipsEl.appendChild(b);
    });
  }

  let modelInput = null;

  function build() {
    const box = el('div', 'api-sheet');

    const head = el('div', 'api-top');
    head.appendChild(el('span', 'api-kicker', 'CONNECTION'));
    head.appendChild(el('h2', 'api-title', '\u63a5\u7ebf\u7684\u5730\u65b9'));
    head.appendChild(el('p', 'api-sub', '\u8fd9\u91cc\u586b\u9519\uff0c\u6574\u4e2a\u5bb6\u5c31\u54d1\u4e86\u3002'));
    box.appendChild(head);

    liveEl = el('div', 'api-live');
    box.appendChild(liveEl);

    // 服务商分段
    const segWrap = el('div', 'api-field');
    segWrap.appendChild(el('span', 'api-cap', '\u670d\u52a1\u5546'));
    const seg = el('div', 'api-seg');
    ORDER.forEach(function (k) {
      const b = el('button', 'api-seg-b' + (k === st.provider ? ' on' : ''), PROV[k].label);
      b.type = 'button';
      b.setAttribute('data-p', k);
      b.addEventListener('click', function () {
        const cur = profOf(st.provider);
        const save = { url: st.url, model: st.model, key: st.key, headers: st.headers };
        XW.S.profiles = XW.S.profiles || {};
        XW.S.profiles[st.provider] = save;

        st.provider = k;
        const next = profOf(k);
        st.url = next.url;
        st.model = next.model;
        st.key = next.key;
        st.headers = next.headers;
        st.ctx = PROV[k].ctx;

        Array.prototype.forEach.call(seg.children, function (x) {
          x.classList.toggle('on', x.getAttribute('data-p') === k);
        });
        if (urlInput) urlInput.value = st.url;
        if (modelInput) modelInput.value = st.model;
        if (keyInput) keyInput.value = st.key;
        if (hdrInput) hdrInput.value = st.headers;
        if (ctxInput) ctxInput.value = st.ctx;
        drawChips();
        flush();
        mark();
        UI.toast(PROV[k].label + (st.key ? ' \u5df2\u8f7d\u5165' : ' \u5df2\u586b\u597d\uff0c\u8d34 Key \u5c31\u884c'));
      });
      seg.appendChild(b);
    });
    segWrap.appendChild(seg);
    box.appendChild(segWrap);

    // 地址
    const urlInput = mkInput('text', st.url, 'https://api.deepseek.com');
    urlInput.addEventListener('input', function () { st.url = urlInput.value.trim(); autoSave(); });
    box.appendChild(mkField('\u5730\u5740', '\u586b\u5230\u57df\u540d\u5c31\u884c\uff0c\u5e26\u4e0d\u5e26 /v1 \u90fd\u4f1a\u81ea\u52a8\u5404\u8bd5\u4e00\u6b21\u3002', urlInput));

    // Key
    const keyInput = mkInput('password', st.key, 'sk-...');
    keyInput.addEventListener('input', function () { st.key = keyInput.value.trim(); autoSave(); });
    box.appendChild(mkField('API Key', '\u53ea\u5b58\u5728\u8fd9\u53f0\u624b\u673a\u4e0a\uff0c\u4e0d\u4f1a\u53d1\u5230\u522b\u5904\u53bb\u3002', keyInput));

    // 模型 + 拉取
    modelInput = mkInput('text', st.model, 'deepseek-chat');
    modelInput.addEventListener('input', function () { st.model = modelInput.value.trim(); autoSave(); });
    const modelField = mkField('\u6a21\u578b', '', modelInput);
    const pull = el('button', 'api-pull', '\u62c9\u53d6');
    pull.type = 'button';
    pull.addEventListener('click', function () { pullModels(pull); });
    modelField.appendChild(pull);
    box.appendChild(modelField);

    chipsEl = el('div', 'api-chips');
    box.appendChild(chipsEl);

    // 温度
    const tempRow = el('div', 'api-field');
    tempOut = el('span', 'api-cap', '\u6e29\u5ea6 \u00b7 ' + st.temp.toFixed(1));
    tempRow.appendChild(tempOut);
    const range = D.createElement('input');
    range.type = 'range';
    range.min = '0';
    range.max = '2';
    range.step = '0.1';
    range.value = String(st.temp);
    range.className = 'api-range';
    range.addEventListener('input', function () {
      st.temp = Number(range.value);
      tempOut.textContent = '\u6e29\u5ea6 \u00b7 ' + st.temp.toFixed(1);
      autoSave();
    });
    tempRow.appendChild(range);
    tempRow.appendChild(el('em', 'api-hint', '\u9ad8\u4e00\u70b9\u66f4\u6d3b\uff0c\u4f4e\u4e00\u70b9\u66f4\u7a33\u3002\u5e26\u63a8\u7406\u7684\u6a21\u578b\u4e0d\u5403\u8fd9\u4e2a\u3002'));
    box.appendChild(tempRow);

    // 最大输出
    const moInput = mkInput('number', st.maxout, '1024');
    moInput.addEventListener('input', function () { st.maxout = Number(moInput.value) || 0; autoSave(); });
    box.appendChild(mkField('\u6700\u5927\u8f93\u51fa', '\u4e00\u6b21\u56de\u590d\u6700\u591a\u5199\u591a\u5c11 token\u3002\u592a\u5c0f\u4f1a\u88ab\u622a\u65ad\u3002', moInput));

    // 上下文
    const ctxInput = mkInput('number', st.ctx, '128000');
    ctxInput.addEventListener('input', function () { st.ctx = Number(ctxInput.value) || 128000; autoSave(); });
    box.appendChild(mkField('\u4e0a\u4e0b\u6587\u4e0a\u9650', '\u53ea\u5f71\u54cd\u90a3\u4e2a\u767e\u5206\u6bd4\u7684\u7b97\u6cd5\uff0c\u6027\u80fd\u4e0d\u53d7\u5f71\u54cd\u3002', ctxInput));

    // 请求头
    const hdrInput = D.createElement('textarea');
    hdrInput.rows = 3;
    hdrInput.spellcheck = false;
    hdrInput.value = st.headers || '';
    hdrInput.placeholder = '{}';
    hdrInput.addEventListener('input', function () { st.headers = hdrInput.value; autoSave(); });
    box.appendChild(mkField('\u81ea\u5b9a\u4e49\u8bf7\u6c42\u5934', '\u4e00\u822c\u7559\u7a7a\u3002\u4e2d\u8f6c\u670d\u52a1\u8981\u6c42\u624d\u586b\uff0c\u5199 JSON\u3002', hdrInput));

    // 底部按钮
    const row = el('div', 'api-actions');
    const tb = el('button', 'api-btn', '\u6d4b\u8bd5\u4e00\u4e0b');
    tb.type = 'button';
    resEl = el('span', 'api-res');
    tb.addEventListener('click', function () { test(tb); });

    const sb = el('button', 'api-btn solid', '\u4fdd\u5b58');
    sb.type = 'button';
    sb.addEventListener('click', function () {
      flush();
      mark();
      UI.toast('\u4fdd\u5b58\u4e86');
    });

    row.appendChild(tb);
    row.appendChild(sb);
    box.appendChild(row);
    box.appendChild(resEl);

    box.appendChild(el('div', 'api-note', '\u7f51\u9875\u76f4\u8fde\u9700\u8981\u63a5\u53e3\u5141\u8bb8\u8de8\u57df\uff08CORS\uff09\u3002\u88ab\u6321\u4f4f\u65f6\u53ef\u4ee5\u7528 tools/proxy.py \u5728\u672c\u673a\u4e2d\u8f6c\u3002'));

    return box;
  }

  async function pullModels(btn) {
    if (!st.url) { UI.toast('\u5148\u586b\u5730\u5740'); return; }
    const old = btn.textContent;
    btn.textContent = '\u62c9\u4e2d\u2026';
    btn.disabled = true;

    const b = base(st.url);
    const urls = [/\/v\d+$/.test(b) ? b + '/models' : b + '/v1/models', b + '/models'];
    let last = '';

    for (let i = 0; i < urls.length; i++) {
      let r = null;
      try {
        r = await fetch(urls[i], { method: 'GET', headers: headersOf(st.key, st.headers) });
      } catch (e) { last = '\u8fde\u4e0d\u4e0a'; continue; }
      if (r.status === 404 || r.status === 405) { last = '\u6ca1\u6709\u6a21\u578b\u5217\u8868'; continue; }
      if (!r.ok) {
        const t = await r.text().catch(function () { return ''; });
        last = 'HTTP ' + r.status + (t ? '\uff1a' + t.slice(0, 90) : '');
        break;
      }
      const d = await r.json().catch(function () { return null; });
      const arr = Array.isArray(d) ? d : ((d && (d.data || d.models)) || []);
      const ids = arr.map(function (x) {
        return typeof x === 'string' ? x : ((x && (x.id || x.name)) || '');
      }).filter(Boolean);

      if (!ids.length) { last = '\u8fd4\u56de\u91cc\u6ca1\u6709\u6a21\u578b'; continue; }

      ids.sort();
      XW.S.modelList = ids;
      XW.save('modelList');
      drawChips();
      UI.toast('\u62c9\u5230 ' + ids.length + ' \u4e2a');
      btn.textContent = old;
      btn.disabled = false;
      return;
    }

    UI.toast(last || '\u6ca1\u62c9\u5230');
    btn.textContent = old;
    btn.disabled = false;
  }

  async function test(btn) {
    if (!st.url) { resEl.textContent = '\u5148\u586b\u5730\u5740'; return; }
    if (!st.model) { resEl.textContent = '\u5148\u586b\u6a21\u578b'; return; }

    resEl.textContent = '\u6b63\u5728\u8bd5\u2026';
    resEl.className = 'api-res';
    btn.disabled = true;

    const list = endpoints(st.url);
    const t0 = Date.now();
    let last = '';

    for (let i = 0; i < list.length; i++) {
      let r = null;
      const body = { model: st.model, messages: [{ role: 'user', content: '\u5728\u5417' }], stream: false };
      if (!/reason/i.test(st.model) && st.temp >= 0) body.temperature = st.temp;
      if (st.maxout > 0) body.max_tokens = Math.min(64, st.maxout);

      try {
        r = await fetch(list[i], {
          method: 'POST',
          headers: headersOf(st.key, st.headers),
          body: JSON.stringify(body)
        });
      } catch (e) { last = '\u8fde\u4e0d\u4e0a\uff08\u53ef\u80fd\u88ab\u8df3\u57df\u6321\u4e86\uff09'; continue; }

      if (r.status === 404) { last = '\u8fd9\u4e2a\u5730\u5740\u6ca1\u6709 chat \u63a5\u53e3'; continue; }
      if (!r.ok) {
        const t = await r.text().catch(function () { return ''; });
        last = 'HTTP ' + r.status + (t ? '\uff1a' + t.slice(0, 110) : '');
        break;
      }

      const d = await r.json().catch(function () { return null; });
      const ch = d && d.choices && d.choices[0];
      const m = (ch && (ch.message || ch.delta)) || {};
      const hasThink = !!(m.reasoning_content || m.reasoning);
      const reply = String(m.content || '').trim().slice(0, 20);
      const sec = ((Date.now() - t0) / 1000).toFixed(1);

      let line = '\u901a \u00b7 ' + sec + 's \u00b7 ' + (hasThink ? '\u5e26\u601d\u8003\u94fe' : '\u4e0d\u5e26\u601d\u8003\u94fe');
      if (reply) line += ' \u00b7 \u56de\u300c' + reply + '\u300d';

      resEl.textContent = line;
      resEl.className = 'api-res ' + (hasThink ? 'ok' : 'warn');
      btn.disabled = false;
      return;
    }

    resEl.textContent = last || '\u6ca1\u8bd5\u901a';
    resEl.className = 'api-res bad';
    btn.disabled = false;
  }

  let timer = null;

  function render() {
    const orig = D.getElementById('set-ai-provider');
    if (!orig) return;
    const sheet = orig.closest('.sheet');
    if (!sheet) return;

    if (!D.querySelector('.api-sheet')) {
      sheet.classList.add('xw-hide');
      sheet.parentNode.insertBefore(build(), sheet.nextSibling);
      drawChips();
      mark();
    }
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 110);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  render();
  setTimeout(render, 600);
  setTimeout(render, 1200);
})();
