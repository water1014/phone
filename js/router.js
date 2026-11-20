/* router.js · App 打开层；聊天 / 设置内建，其余页面交给 pages.js 自动分发 */
(function () {
  const D = document;

  let host = null;
  let bodyEl = null;
  let nameEl = null;
  let enEl = null;
  let currentId = null;

  const EN = {
    chat: 'MESSAGE', memory: 'MEMORY', diary: 'DIARY', album: 'ALBUM',
    letter: 'LETTER', music: 'MUSIC', calendar: 'CALENDAR', plans: 'PLANS',
    accounting: 'EXPENSES', weather: 'WEATHER', mood: 'MOOD', health: 'WELLNESS',
    cycle: 'CYCLE', study: 'STUDY', quotes: 'QUOTES', moments: 'MOMENTS',
    favorites: 'FAVORITES', games: 'GAMES', studio: 'STUDIO', worldbook: 'WORLDBOOK',
    windows: 'WINDOW GALLERY', mcp: 'CONNECTIONS', beautify: 'APPEARANCE', settings: 'SETTINGS'
  };

  const PRESETS = {
    deepseek: { label: 'DeepSeek', url: 'https://api.deepseek.com', model: 'deepseek-chat', headers: '', session: false },
    opencode: { label: 'OpenCode Go', url: 'https://opencode.ai/inference/go', model: 'deepseek-v4.1-flash', headers: '', session: true },
    openai: { label: 'OpenAI 兼容', url: '', model: '', headers: '', session: false }
  };

  const PROVIDER_ORDER = ['deepseek', 'opencode', 'openai'];
  const QUICK = ['在吗', '抱抱', '晚安'];

  function readProfile(name) {
    const all = XW.S.profiles || {};
    const saved = all[name] || null;
    const preset = PRESETS[name] || PRESETS.openai;
    return {
      url: saved && saved.url ? saved.url : (preset.url || ''),
      model: saved && saved.model ? saved.model : (preset.model || ''),
      key: saved && saved.key ? saved.key : '',
      headers: saved && saved.headers !== undefined ? saved.headers : (preset.headers || '')
    };
  }

  function writeProfile(name, data) {
    XW.S.profiles = XW.S.profiles || {};
    XW.S.profiles[name] = data;
    XW.save('profiles');
  }

  function sessionId() {
    if (!XW.S.sessionId) {
      XW.S.sessionId = 'xw-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 10);
      XW.save('sessionId');
    }
    return XW.S.sessionId;
  }

  function ensure() {
    if (host) return;
    host = D.createElement('div');
    host.className = 'app';
    host.id = 'app';
    host.innerHTML =
      '<header class="app-head">' +
        '<button type="button" class="app-back" id="app-back" aria-label="返回桌面">' +
          '<svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7"/></svg>' +
        '</button>' +
        '<div class="app-title"><span id="app-name">App</span><small id="app-en"></small></div>' +
      '</header>' +
      '<main class="app-body" id="app-body"></main>';
    D.body.appendChild(host);

    bodyEl = host.querySelector('#app-body');
    nameEl = host.querySelector('#app-name');
    enEl = host.querySelector('#app-en');
    host.querySelector('#app-back').addEventListener('click', back);
  }

  function open(id) {
    ensure();
    const app = window.Apps.find(id);
    if (!app) return;
    currentId = id;
    nameEl.textContent = app.name;
    enEl.textContent = EN[id] || '';
    paint(id);
    host.classList.add('show');
  }

  function paint(id) {
    bodyEl.innerHTML = render(id);
    bind(id);
  }

  function back() {
    if (!host) return;
    host.classList.remove('show');
    bodyEl.innerHTML = '';
    currentId = null;
  }

  function render(id) {
    if (id === 'chat') return chatView();
    if (id === 'settings') return settingsView();
    const page = window.Pages && window.Pages[id];
    if (typeof page === 'function') return page();
    return '<div class="sheet"><div class="empty-state" style="margin-top:1rem">这间还没开门。<br>骨架先立着，下一间再填它。</div></div>';
  }

  function parseHeaders(text) {
    const raw = String(text || '').trim();
    if (!raw) return {};
    let obj = null;
    try { obj = JSON.parse(raw); } catch (err) { return {}; }
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return {};
    const clean = {};
    Object.keys(obj).forEach(function (k) {
      if (k && typeof obj[k] === 'string') clean[k] = obj[k];
    });
    return clean;
  }

  function authHeaders(keyText, headerText, withSession) {
    const headers = { 'Content-Type': 'application/json' };
    const key = String(keyText || '').trim();
    if (key) headers.Authorization = 'Bearer ' + key;
    const extra = parseHeaders(headerText);
    Object.keys(extra).forEach(function (k) { headers[k] = extra[k]; });
    if (withSession && !extra['x-opencode-session']) {
      headers['x-opencode-session'] = sessionId();
    }
    return headers;
  }

  function fmtK(n) {
    const num = Number(n) || 0;
    if (num < 1000) return String(num);
    return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'k';
  }

  function stripTail(url) {
    return String(url || '').trim().replace(/\/+$/, '').replace(/\/chat\/completions$/, '');
  }

  function urlCandidates(url) {
    const base = stripTail(url);
    if (!base) return [];
    const list = [];
    const raw = String(url || '').trim().replace(/\/+$/, '');
    if (/\/chat\/completions$/.test(raw)) list.push(raw);
    list.push(base + '/v1/chat/completions');
    list.push(base + '/chat/completions');
    return list;
  }

  function modelCandidates(url) {
    const base = stripTail(url);
    if (!base) return [];
    return [base + '/v1/models', base + '/models'];
  }

  function stamp(ts) {
    const d = new Date(ts || Date.now());
    if (d.toDateString() === new Date().toDateString()) {
      return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
    }
    return (d.getMonth() + 1) + '月' + d.getDate() + '日 ' +
      String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  function renderText(text) {
    const lines = String(text || '').split(/\n+/);
    let bubble = [];
    const chunks = [];

    const flush = function () {
      if (!bubble.length) return;
      chunks.push({ kind: 'bubble', text: bubble.join('\n') });
      bubble = [];
    };

    lines.forEach(function (line) {
      const t = line.trim();
      if (!t) { bubble.push(''); return; }
      const isNarr = /^[（(].*[）)]$/.test(t) || /^\*.*\*$/.test(t);
      if (isNarr) {
        flush();
        chunks.push({ kind: 'narr', text: t.replace(/^\*|\*$/g, '') });
      } else {
        bubble.push(t);
      }
    });
    flush();
    return chunks;
  }

  function messageHtml(msg, compact) {
    if (msg.who === 'sys') {
      return '<div class="chat-event"><span>' + UI.esc(msg.text || '') + '</span></div>';
    }

    const mine = msg.who === 'me';
    const name = mine ? (XW.S.herName || '我') : (XW.S.hisName || '他');

    let inner = '';
    if (msg._typing) {
      inner = '<div class="bub typing">…</div>';
    } else {
      if (msg.think) {
        inner += '<details class="think"><summary>思考</summary>' +
          '<div class="think-body">' + UI.esc(msg.think) + '</div></details>';
      }
      renderText(msg.text).forEach(function (c) {
        if (c.kind === 'narr') inner += '<div class="narr">' + UI.esc(c.text) + '</div>';
        else inner += '<div class="bub' + (mine ? ' me' : '') + '">' + UI.esc(c.text) + '</div>';
      });
    }

    let tag = '';
    if (msg.usage && !mine) {
      const bits = ['入 ' + fmtK(msg.usage.input), '出 ' + fmtK(msg.usage.output)];
      if (msg.usage.cached) bits.push('命中 ' + fmtK(msg.usage.cached));
      tag = '<div class="msg-tag">' + bits.join(' · ') + '</div>';
    }

    return '<div class="msg-row ' + (mine ? 'me' : 'ta') + (compact ? ' compact' : '') + '">' +
        '<div class="msg-ava' + (compact ? ' ghost' : '') + '">' + UI.esc(String(name).charAt(0)) + '</div>' +
        '<div class="msg-main">' +
          (compact ? '' : '<div class="msg-name">' + UI.esc(name) + '</div>') +
          inner + tag +
        '</div>' +
      '</div>';
  }

  function chatView() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    let lastT = 0;

    const rows = list.map(function (m, index) {
      const prev = index > 0 ? list[index - 1] : null;
      let sep = '';
      const t = Number(m.t) || 0;
      const gap = t - lastT;
      if (m.who !== 'sys' && gap > 5 * 60 * 1000) {
        sep = '<div class="chat-time"><span class="kicker">' + UI.esc(stamp(t)) + '</span></div>';
      }
      if (t) lastT = t;

      const same = prev && prev.who === m.who && m.who !== 'sys' && gap < 5 * 60 * 1000 && !prev._typing;
      return sep + messageHtml(m, same);
    }).join('');

    const empty = list.length ? '' : '<div class="empty-state" style="margin-top:22%">还没说话。<br>在下面写一句，就有了。</div>';

    const keyed = String(XW.S.aiKey || '').trim();
    const usage = XW.S.usage || { rounds: 0, input: 0, cached: 0, output: 0 };
    const limit = Number(XW.S.ctxLimit) || 128000;
    const used = Number(usage.input) || 0;
    const percent = Math.min(999, Math.round(used / limit * 100));
    const provider = (PRESETS[XW.S.aiProvider] || PRESETS.deepseek).label;

    const head = '<div class="chat-status">' +
        '<span class="chat-who">' + UI.esc(XW.S.hisName || '他') + '</span>' +
        '<span class="chat-flag">' + (keyed ? '<i class="dot"></i>ONLINE' : '本地') + '</span>' +
      '</div>';

    const top = keyed
      ? '<div class="chat-top">' +
          '<span class="num"><b>' + percent + '%</b></span>' +
          '<span class="num"><b>' + fmtK(used) + '</b><i>/' + fmtK(limit) + '</i></span>' +
          '<span class="num"><i>命中</i><b>' + fmtK(usage.cached) + '</b></span>' +
          '<span class="num"><i>出</i><b>' + fmtK(usage.output) + '</b></span>' +
          '<span class="num"><b>' + usage.rounds + '</b><i>轮</i></span>' +
          '<span class="num model">' + UI.esc(provider) + '</span>' +
        '</div><div class="usage-bar"><i style="width:' + Math.min(100, percent) + '%"></i></div>'
      : '';

    const chips = QUICK.map(function (w) {
      return '<button type="button" class="quick-chip" data-quick="' + UI.esc(w) + '">' + UI.esc(w) + '</button>';
    }).join('');

    return '<div class="chat-wrap">' + head + top +
        '<div class="chat-scroll" id="chat-scroll">' + rows + empty + '</div>' +
        '<div class="quick">' + chips + '</div>' +
        '<div class="composer"><input id="chat-input" placeholder="写点什么…"><button type="button" id="chat-send" class="btn-solid">发</button></div>' +
      '</div>';
  }

  function scrollChat() {
    const box = D.getElementById('chat-scroll');
    if (box) box.scrollTop = box.scrollHeight;
  }

  function readUsage(usage) {
    const total = XW.S.usage || { rounds: 0, input: 0, cached: 0, output: 0 };
    const input = Number(usage && usage.prompt_tokens) || 0;
    const output = Number(usage && usage.completion_tokens) || 0;
    let cached = Number(usage && usage.prompt_cache_hit_tokens) || 0;
    if (!cached && usage && usage.prompt_tokens_details) {
      cached = Number(usage.prompt_tokens_details.cached_tokens) || 0;
    }
    const slice = { input: input, output: output, cached: cached };
    XW.S.usage = {
      rounds: (Number(total.rounds) || 0) + 1,
      input: (Number(total.input) || 0) + input,
      cached: (Number(total.cached) || 0) + cached,
      output: (Number(total.output) || 0) + output
    };
    XW.save('usage');
    return slice;
  }

  async function callAI() {
    const key = String(XW.S.aiKey || '').trim();
    if (!key) throw new Error('没填 Key');
    const url = String(XW.S.aiUrl || '').trim();
    if (!url) throw new Error('没填接口地址');
    const model = String(XW.S.aiModel || '').trim();
    if (!model) throw new Error('没填模型名');

    const withSession = (XW.S.aiProvider === 'opencode');

    const history = XW.S.chat
      .filter(function (m) { return !m._typing && m.who !== 'sys'; })
      .slice(-20)
      .map(function (m) { return { role: m.who === 'ta' ? 'assistant' : 'user', content: String(m.text || '') }; })
      .filter(function (m) { return m.content; });

    const system = '你在「小窝」这个私人小手机里。你就是你自己，不是客服。说话自然、有体温，偶尔走神、偶尔说重一点。可以用（括号）写神情和动作当旁白，也可以直接说话，不要列条目。';

    const body = JSON.stringify({
      model: model,
      messages: [{ role: 'system', content: system }].concat(history),
      stream: false
    });

    const candidates = urlCandidates(url);
    let lastError = null;

    for (let i = 0; i < candidates.length; i++) {
      const candidate = candidates[i];
      let res = null;
      try {
        res = await fetch(candidate, {
          method: 'POST',
          headers: authHeaders(key, XW.S.aiHeaders, withSession),
          body: body
        });
      } catch (err) {
        lastError = new Error('连不上（可能被跨域挡了）：' + candidate);
        continue;
      }

      if (res.status === 404 || res.status === 405) {
        lastError = new Error('地址不认：' + candidate + ' (HTTP ' + res.status + ')');
        continue;
      }

      if (!res.ok) {
        const detail = await res.text().catch(function () { return ''; });
        throw new Error('HTTP ' + res.status + (detail ? '：' + detail.slice(0, 160) : ''));
      }

      const data = await res.json();
      const choice = (data && data.choices && data.choices[0]) || null;
      const message = (choice && choice.message) || {};
      let content = message.content;
      if (Array.isArray(content)) {
        content = content.map(function (p) { return typeof p === 'string' ? p : (p && p.text) || ''; }).join('');
      }
      const think = String(message.reasoning_content || message.reasoning || (choice && choice.reasoning) || '').trim();
      const slice = readUsage(data.usage);

      if (candidate !== url) {
        XW.S.aiUrlResolved = candidate;
        XW.save('aiUrlResolved');
      }

      return { text: String(content || '').trim(), think: think, usage: slice };
    }

    throw lastError || new Error('没找到能用的地址');
  }

  async function sendChat() {
    const input = D.getElementById('chat-input');
    const text = (input.value || '').trim();
    if (!text) return;
    input.value = '';

    XW.S.chat.push({ who: 'me', text: text, t: Date.now() });
    XW.save('chat');
    paint('chat');
    scrollChat();

    if (!String(XW.S.aiKey || '').trim()) return;

    XW.S.chat.push({ who: 'ta', text: '', t: Date.now(), _typing: true });
    paint('chat');
    scrollChat();

    try {
      const reply = await callAI();
      XW.S.chat = XW.S.chat.filter(function (m) { return !m._typing; });
      XW.S.chat.push({
        who: 'ta',
        text: reply.text || '（没说话）',
        think: reply.think,
        usage: reply.usage,
        t: Date.now()
      });
    } catch (err) {
      XW.S.chat = XW.S.chat.filter(function (m) { return !m._typing; });
      XW.S.chat.push({ who: 'sys', text: String(err.message || err), t: Date.now() });
    }
    XW.save('chat');
    paint('chat');
    scrollChat();
  }

  function fieldView(label, id, value, type, placeholder, listId) {
    return '<label class="field"><span>' + label + '</span>' +
      '<input id="' + id + '" type="' + (type || 'text') + '" value="' + UI.esc(value) + '" spellcheck="false"' +
      (placeholder ? ' placeholder="' + UI.esc(placeholder) + '"' : '') +
      (listId ? ' list="' + listId + '"' : '') + '></label>';
  }

  function providerOptions(current) {
    return PROVIDER_ORDER.map(function (key) {
      return '<option value="' + key + '"' + (key === current ? ' selected' : '') + '>' + PRESETS[key].label + '</option>';
    }).join('');
  }

  function apiItem(api, i) {
    const item = api || {};
    const title = (item.name || '未命名') + (item.model ? ' · ' + item.model : '');
    return '<details class="fold">' +
        '<summary><span>' + UI.esc(title) + '</span><i>' + (i + 1) + '</i></summary>' +
        '<div class="fold-inner">' +
          '<label class="field"><span>名字（生图 / 语音 / 识图…）</span><input data-k="name" value="' + UI.esc(item.name || '') + '" spellcheck="false"></label>' +
          '<label class="field"><span>接口地址</span><input data-k="url" value="' + UI.esc(item.url || '') + '" spellcheck="false" placeholder="https://…"></label>' +
          '<label class="field"><span>模型（可留空）</span><input data-k="model" value="' + UI.esc(item.model || '') + '" spellcheck="false"></label>' +
          '<label class="field"><span>API Key</span><input data-k="key" type="password" value="' + UI.esc(item.key || '') + '" spellcheck="false"></label>' +
          '<label class="field"><span>自定义请求头（JSON）</span><textarea data-k="headers" rows="3" spellcheck="false" placeholder="{}">' + UI.esc(item.headers || '') + '</textarea></label>' +
          '<div class="row-actions">' +
            '<button type="button" class="btn-glass" data-api-del="' + i + '">删除</button>' +
            '<button type="button" class="btn-solid" data-api-save="' + i + '">保存这条</button>' +
          '</div>' +
        '</div>' +
      '</details>';
  }

  function settingsView() {
    const apis = Array.isArray(XW.S.apis) ? XW.S.apis : [];
    const provider = XW.S.aiProvider || 'deepseek';
    const resolved = XW.S.aiUrlResolved || '';
    const models = Array.isArray(XW.S.modelList) ? XW.S.modelList : [];

    const modelDatalist = '<datalist id="model-list">' +
      models.map(function (id) { return '<option value="' + UI.esc(id) + '"></option>'; }).join('') +
      '</datalist>';

    const names = '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">我们是谁</span><span class="kicker">NAMES</span></div>' +
        fieldView('他的称呼', 'set-his', XW.S.hisName) +
        fieldView('她的称呼', 'set-her', XW.S.herName) +
        fieldView('在一起从哪天开始', 'set-love', XW.S.loveDate) +
        '<div class="row-actions"><button type="button" id="set-save" class="btn-solid">保存</button></div>' +
      '</div>';

    const chatApi = '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">聊天的接口</span><span class="kicker">CHAT</span></div>' +
        '<label class="field"><span>服务商（每家各存一套）</span><select id="set-ai-provider">' + providerOptions(provider) + '</select></label>' +
        fieldView('接口地址', 'set-ai-url', XW.S.aiUrl) +
        fieldView('模型（选或填）', 'set-ai-model', XW.S.aiModel, 'text', '例：deepseek-chat', 'model-list') +
        modelDatalist +
        '<div class="row-actions" style="justify-content:flex-start">' +
          '<button type="button" id="set-pull-models" class="btn-glass">拉取模型</button>' +
          '<span class="kicker" id="model-hint">' + (models.length ? models.length + ' 个可选' : '还没拉过') + '</span>' +
        '</div>' +
        fieldView('API Key', 'set-ai-key', XW.S.aiKey, 'password') +
        '<label class="field"><span>自定义请求头（JSON）</span><textarea id="set-ai-headers" rows="3" spellcheck="false" placeholder="{}"></textarea></label>' +
        fieldView('上下文上限（token）', 'set-ctx', String(XW.S.ctxLimit || 128000)) +
        '<div class="row-actions"><button type="button" id="set-ai-save" class="btn-solid">保存连接</button></div>' +
        (resolved ? '<div class="sheet-note">上次走通的地址：' + UI.esc(resolved) + '</div>' : '') +
        (provider === 'opencode' ? '<div class="sheet-note">Go 入口填到 …/inference/go。浏览器直连会被跨域拦，需要时用 tools/proxy.py 在本机中转。</div>' : '') +
        '<div class="sheet-note">切换服务商时刚才那套会自动存起来，切回来还在。</div>' +
      '</div>';

    const others = '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">其它接口</span><span class="kicker">' + apis.length + ' 套</span></div>' +
        apis.map(apiItem).join('') +
        '<div class="row-actions"><button type="button" id="api-add" class="btn-glass">＋ 新增一套</button></div>' +
        '<div class="sheet-note">生图、语音、识图各存一套，各自带自己的 Key 和请求头。不填不影响聊天。</div>' +
      '</div>';

    return names + chatApi + others;
  }

  async function pullModels() {
    const urlEl = D.getElementById('set-ai-url');
    const keyEl = D.getElementById('set-ai-key');
    const headEl = D.getElementById('set-ai-headers');
    const hint = D.getElementById('model-hint');
    const url = urlEl ? urlEl.value.trim() : '';
    const key = keyEl ? keyEl.value.trim() : '';
    const headers = headEl ? headEl.value : '';
    const withSession = (XW.S.aiProvider === 'opencode');

    if (!url) { UI.toast('先填接口地址'); return; }
    if (hint) hint.textContent = '正在拉…';

    const candidates = modelCandidates(url);
    let lastError = null;

    for (let i = 0; i < candidates.length; i++) {
      const candidate = candidates[i];
      let res = null;
      try {
        res = await fetch(candidate, { method: 'GET', headers: authHeaders(key, headers, withSession) });
      } catch (err) {
        lastError = new Error('连不上（可能被跨域挡了）：' + candidate);
        continue;
      }
      if (res.status === 404 || res.status === 405) {
        lastError = new Error('没有模型列表接口：' + candidate);
        continue;
      }
      if (!res.ok) {
        const detail = await res.text().catch(function () { return ''; });
        throw new Error('HTTP ' + res.status + (detail ? '：' + detail.slice(0, 100) : ''));
      }

      const data = await res.json();
      const arr = Array.isArray(data) ? data : ((data && (data.data || data.models)) || []);
      const ids = arr.map(function (x) {
        if (typeof x === 'string') return x;
        return (x && (x.id || x.name)) || '';
      }).filter(Boolean);

      if (!ids.length) { lastError = new Error('返回里没有模型'); continue; }

      ids.sort();
      XW.S.modelList = ids;
      XW.save('modelList');
      if (hint) hint.textContent = ids.length + ' 个可选';
      UI.toast('拉到 ' + ids.length + ' 个模型');
      paint('settings');
      return;
    }

    if (hint) hint.textContent = '没拉到';
    throw lastError || new Error('没拉到模型列表');
  }

  function bind(id) {
    if (id === 'chat') {
      const btn = D.getElementById('chat-send');
      const input = D.getElementById('chat-input');
      if (btn) btn.addEventListener('click', sendChat);
      if (input) {
        input.addEventListener('keydown', function (e) {
          if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendChat(); }
        });
      }
      Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-quick]'), function (chip) {
        chip.addEventListener('click', function () {
          if (!input) return;
          input.value = chip.dataset.quick;
          input.focus();
        });
      });
      scrollChat();
      return;
    }

    if (id === 'settings') {
      bindSettings();
      return;
    }

    const pageBind = window.Pages && window.Pages[id + 'Bind'];
    if (typeof pageBind === 'function') pageBind(bodyEl);
  }

  function bindSettings() {
    const headBox = D.getElementById('set-ai-headers');
    if (headBox) headBox.value = XW.S.aiHeaders || '';

    if (!XW.S.profiles) {
      XW.S.profiles = {};
      XW.S.profiles[XW.S.aiProvider || 'deepseek'] = {
        url: XW.S.aiUrl || '',
        model: XW.S.aiModel || '',
        key: XW.S.aiKey || '',
        headers: XW.S.aiHeaders || ''
      };
      XW.save('profiles');
    }

    const provider = D.getElementById('set-ai-provider');
    if (provider) {
      provider.addEventListener('change', function () {
        const urlEl = D.getElementById('set-ai-url');
        const modelEl = D.getElementById('set-ai-model');
        const keyEl = D.getElementById('set-ai-key');
        const prev = XW.S.aiProvider || 'deepseek';
        const next = provider.value;

        writeProfile(prev, {
          url: (urlEl.value || '').trim(),
          model: (modelEl.value || '').trim(),
          key: (keyEl.value || '').trim(),
          headers: (headBox ? headBox.value : '').trim()
        });

        const prof = readProfile(next);
        urlEl.value = prof.url;
        modelEl.value = prof.model;
        keyEl.value = prof.key;
        if (headBox) headBox.value = prof.headers;

        XW.S.aiProvider = next;
        XW.S.aiUrl = prof.url;
        XW.S.aiModel = prof.model;
        XW.S.aiKey = prof.key;
        XW.S.aiHeaders = prof.headers;
        XW.S.aiUrlResolved = '';
        ['aiProvider', 'aiUrl', 'aiModel', 'aiKey', 'aiHeaders', 'aiUrlResolved'].forEach(XW.save);

        UI.toast(PRESETS[next].label + (prof.key ? ' 已载入' : ' 已填好，贴 Key 就行'));
        paint('settings');
      });
    }

    const pullBtn = D.getElementById('set-pull-models');
    if (pullBtn) {
      pullBtn.addEventListener('click', function () {
        pullModels().catch(function (err) { UI.toast(err.message || '拉取失败'); });
      });
    }

    const saveNames = D.getElementById('set-save');
    if (saveNames) {
      saveNames.addEventListener('click', function () {
        const read = function (elId) { const el = D.getElementById(elId); return el && el.value ? el.value.trim() : ''; };
        XW.S.hisName = read('set-his') || '他';
        XW.S.herName = read('set-her') || '她';
        XW.S.loveDate = read('set-love') || '2025-01-01';
        ['hisName', 'herName', 'loveDate'].forEach(XW.save);
        UI.toast('保存了');
        if (window.Desktop) window.Desktop.rerender();
      });
    }

    const saveChat = D.getElementById('set-ai-save');
    if (saveChat) {
      saveChat.addEventListener('click', function () {
        const read = function (elId) { const el = D.getElementById(elId); return el && el.value ? el.value.trim() : ''; };
        const current = XW.S.aiProvider || 'deepseek';
        const data = {
          url: read('set-ai-url'),
          model: read('set-ai-model'),
          key: read('set-ai-key'),
          headers: (D.getElementById('set-ai-headers').value || '').trim()
        };
        XW.S.aiUrl = data.url;
        XW.S.aiModel = data.model;
        XW.S.aiKey = data.key;
        XW.S.aiHeaders = data.headers;
        XW.S.ctxLimit = Number(read('set-ctx')) || 128000;
        XW.S.aiUrlResolved = '';
        writeProfile(current, data);
        ['aiUrl', 'aiModel', 'aiKey', 'aiHeaders', 'ctxLimit', 'aiUrlResolved'].forEach(XW.save);
        UI.toast(PRESETS[current].label + ' 保存了');
      });
    }

    const addApi = D.getElementById('api-add');
    if (addApi) {
      addApi.addEventListener('click', function () {
        XW.S.apis = Array.isArray(XW.S.apis) ? XW.S.apis : [];
        XW.S.apis.push({ name: '', url: '', model: '', key: '', headers: '' });
        XW.save('apis');
        paint('settings');
      });
    }

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-api-save]'), function (btn) {
      btn.addEventListener('click', function () {
        const index = Number(btn.dataset.apiSave);
        const box = btn.closest('.fold');
        const read = function (k) {
          const el = box ? box.querySelector('[data-k="' + k + '"]') : null;
          return el && el.value ? el.value.trim() : '';
        };
        XW.S.apis[index] = {
          name: read('name') || '未命名',
          url: read('url'),
          model: read('model'),
          key: read('key'),
          headers: read('headers')
        };
        XW.save('apis');
        UI.toast('这一条保存了');
      });
    });

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-api-del]'), function (btn) {
      btn.addEventListener('click', function () {
        XW.S.apis.splice(Number(btn.dataset.apiDel), 1);
        XW.save('apis');
        UI.toast('删掉了');
        paint('settings');
      });
    });
  }

  function reopen(id) {
    if (!host || currentId !== id) return;
    paint(id);
  }

  window.Router = { open: open, back: back, reopen: reopen, current: function () { return currentId; } };
})();
