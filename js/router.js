/* router.js · App 打开层；聊天支持旁白 / 思考 / token 用量 */
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

  /* 服务商预设：地址与模型固定，只换 Key */
  const PRESETS = {
    deepseek: { label: 'DeepSeek', url: 'https://api.deepseek.com/chat/completions', model: 'deepseek-chat', headers: '' },
    kimi: { label: 'Kimi', url: 'https://api.moonshot.cn/v1/chat/completions', model: 'kimi-latest', headers: '' },
    opencode: { label: 'OpenCode Go', url: 'https://opencode.ai/zen/go', model: '', headers: '' },
    openai: { label: 'OpenAI 兼容（自定义）', url: '', model: '', headers: '' }
  };

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
    if (id === 'diary') return diaryView();
    if (id === 'album') return albumView();
    if (id === 'settings') return settingsView();
    return '<div class="sheet"><div class="empty-state" style="margin-top:1rem">这间还没开门。<br>骨架先立着，下一间再填它。</div></div>';
  }

  /* ── 小工具 ── */
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

  function authHeaders(keyText, headerText) {
    const headers = { 'Content-Type': 'application/json' };
    const key = String(keyText || '').trim();
    if (key) headers.Authorization = 'Bearer ' + key;
    const extra = parseHeaders(headerText);
    Object.keys(extra).forEach(function (k) { headers[k] = extra[k]; });
    return headers;
  }

  function fmtK(n) {
    const num = Number(n) || 0;
    if (num < 1000) return String(num);
    return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'k';
  }

  /* 地址补全：填前绝也能找到 chat/completions */
  function urlCandidates(url) {
    const base = String(url || '').trim().replace(/\/+$/, '');
    if (!base) return [];
    const list = [base];
    if (!/\/chat\/completions$/.test(base)) {
      list.push(base + '/chat/completions');
      list.push(base + '/v1/chat/completions');
    }
    return list;
  }

  /* ── 聊天 ── */
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

  function messageHtml(msg) {
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
      tag = '<div class="msg-tag">入 ' + fmtK(msg.usage.input) + ' · 出 ' + fmtK(msg.usage.output) +
        (msg.usage.cached ? ' · 命中 ' + fmtK(msg.usage.cached) : '') + '</div>';
    }

    const initial = String(name).charAt(0);
    return '<div class="msg-row ' + (mine ? 'me' : 'ta') + '">' +
        '<div class="msg-ava">' + UI.esc(initial) + '</div>' +
        '<div class="msg-main">' +
          '<div class="msg-name">' + UI.esc(name) + '</div>' +
          inner + tag +
        '</div>' +
      '</div>';
  }

  function chatView() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    let lastT = 0;

    const rows = list.map(function (m) {
      let sep = '';
      const t = Number(m.t) || 0;
      if (t - lastT > 5 * 60 * 1000) {
        sep = '<div class="chat-time"><span class="kicker">' + UI.esc(stamp(t)) + '</span></div>';
      }
      if (t) lastT = t;
      return sep + messageHtml(m);
    }).join('');

    const empty = list.length ? '' : '<div class="empty-state" style="margin-top:26%">还没说话。<br>在下面写一句，就有了。</div>';

    const keyed = String(XW.S.aiKey || '').trim();
    const usage = XW.S.usage || { rounds: 0, input: 0, cached: 0, output: 0 };
    const limit = Number(XW.S.ctxLimit) || 128000;
    const used = Number(usage.input) || 0;
    const percent = Math.min(999, Math.round(used / limit * 100));
    const hitRate = used ? Math.round((Number(usage.cached) || 0) / used * 100) : 0;

    const topLeft = keyed ? (XW.S.aiModel || 'model') : 'LOCAL';
    const topRight = keyed ? (percent + '% · ' + fmtK(used) + ' / ' + fmtK(limit)) : '只存你自己的话';
    const meter = keyed
      ? '输入 ' + fmtK(usage.input) + ' · 命中 ' + fmtK(usage.cached) + '(' + hitRate + '%) · 输出 ' + fmtK(usage.output) + ' · ' + usage.rounds + ' 轮'
      : '本地模式';

    return '<div class="chat-wrap">' +
        '<div class="chat-status"><span class="kicker">' + UI.esc(topLeft) + '</span>' +
          '<span class="kicker">' + UI.esc(topRight) + '</span></div>' +
        '<div class="chat-scroll" id="chat-scroll">' + rows + empty + '</div>' +
        '<div class="chat-meter">' + UI.esc(meter) + '</div>' +
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

    const history = XW.S.chat
      .filter(function (m) { return !m._typing; })
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
          headers: authHeaders(key, XW.S.aiHeaders),
          body: body
        });
      } catch (err) {
        lastError = new Error('连不上 ' + candidate + '（' + (err.message || err) + '）');
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
        if (UI.toast) UI.toast('地址自动补全：' + candidate.replace(/^https:\/\//, ''));
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
      XW.S.chat.push({ who: 'ta', text: '（' + (err.message || err) + '）', t: Date.now() });
    }
    XW.save('chat');
    paint('chat');
    scrollChat();
  }

  /* ── 日记 ── */
  function diaryView() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary.slice().reverse() : [];
    const rows = list.length
      ? list.map(function (item) {
          return '<div class="list-item"><div class="kicker">' + UI.esc(item.date || '') + '</div>' +
            '<div class="list-text">' + UI.esc(item.text || '') + '</div></div>';
        }).join('')
      : '<div class="empty-state" style="margin-top:1rem">还没有第一篇。<br>今天我也还没动笔。</div>';

    return '<div class="sheet">' +
        '<label class="field"><span>今天</span><textarea id="diary-input" rows="4" placeholder="今天想留一句什么…"></textarea></label>' +
        '<div class="row-actions"><button type="button" id="diary-save" class="btn-solid">落笔</button></div>' +
      '</div>' +
      '<div class="sheet"><div class="sheet-head"><span class="sheet-title">写过的东西</span><span class="kicker">' + list.length + ' 篇</span></div>' + rows + '</div>';
  }

  /* ── 相册 ── */
  function albumView() {
    const list = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    const cells = list.map(function (url, i) {
      return '<figure class="album-cell"><img src="' + url + '" alt="">' +
        '<button type="button" class="album-del" data-del="' + i + '" aria-label="删掉这张">×</button></figure>';
    }).join('');

    const body = list.length
      ? '<div class="album-grid">' + cells + '</div>'
      : '<div class="empty-state" style="margin-top:1rem">还没有照片。<br>放一张进来，这里就有东西了。</div>';

    return '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">照片</span><button type="button" id="album-add" class="btn-glass">＋ 放一张</button></div>' +
        '<input id="album-file" type="file" accept="image/*" multiple hidden>' +
        '<div style="margin-top:.8rem">' + body + '</div>' +
        '<div class="sheet-note">照片只存在这台设备的浏览器里，清缓存会丢。</div>' +
      '</div>';
  }

  function shrink(file, maxSide, quality) {
    return new Promise(function (resolve) {
      const reader = new FileReader();
      reader.onerror = function () { resolve(''); };
      reader.onload = function () {
        const img = new Image();
        img.onerror = function () { resolve(''); };
        img.onload = function () {
          const scale = Math.min(1, maxSide / Math.max(img.width, img.height));
          const canvas = D.createElement('canvas');
          canvas.width = Math.max(1, Math.round(img.width * scale));
          canvas.height = Math.max(1, Math.round(img.height * scale));
          canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height);
          resolve(canvas.toDataURL('image/jpeg', quality));
        };
        img.src = reader.result;
      };
      reader.readAsDataURL(file);
    });
  }

  /* ── 设置 ── */
  function fieldView(label, id, value, type, placeholder) {
    return '<label class="field"><span>' + label + '</span>' +
      '<input id="' + id + '" type="' + (type || 'text') + '" value="' + UI.esc(value) + '" spellcheck="false"' +
      (placeholder ? ' placeholder="' + UI.esc(placeholder) + '"' : '') + '></label>';
  }

  function providerOptions(current) {
    const list = [
      ['deepseek', 'DeepSeek'],
      ['kimi', 'Kimi（Moonshot）'],
      ['opencode', 'OpenCode Go'],
      ['openai', 'OpenAI 兼容（自己填地址）']
    ];
    return list.map(function (pair) {
      return '<option value="' + pair[0] + '"' + (pair[0] === current ? ' selected' : '') + '>' + pair[1] + '</option>';
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

    const names = '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">我们是谁</span><span class="kicker">NAMES</span></div>' +
        fieldView('他的称呼', 'set-his', XW.S.hisName) +
        fieldView('她的称呼', 'set-her', XW.S.herName) +
        fieldView('在一起从哪天开始', 'set-love', XW.S.loveDate) +
        '<div class="row-actions"><button type="button" id="set-save" class="btn-solid">保存</button></div>' +
      '</div>';

    const chatApi = '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">聊天的接口</span><span class="kicker">CHAT</span></div>' +
        '<label class="field"><span>服务商</span><select id="set-ai-provider">' + providerOptions(provider) + '</select></label>' +
        fieldView('接口地址', 'set-ai-url', XW.S.aiUrl) +
        fieldView('模型', 'set-ai-model', XW.S.aiModel, 'text', '例：deepseek-chat') +
        fieldView('API Key（只换这一项）', 'set-ai-key', XW.S.aiKey, 'password') +
        '<label class="field"><span>自定义请求头（JSON，可留空）</span><textarea id="set-ai-headers" rows="3" spellcheck="false" placeholder="{\"X-Title\":\"小窝\"}"></textarea></label>' +
        fieldView('上下文上限（token）', 'set-ctx', String(XW.S.ctxLimit || 128000)) +
        '<div class="row-actions"><button type="button" id="set-ai-save" class="btn-solid">保存连接</button></div>' +
        (resolved ? '<div class="sheet-note">上次走通的地址：' + UI.esc(resolved) + '</div>' : '') +
        '<div class="sheet-note">地址填到前缀也行（如 https://opencode.ai/zen/go），我会自己试 /chat/completions 与 /v1/chat/completions 两种接法。</div>' +
      '</div>';

    const others = '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">其它接口</span><span class="kicker">' + apis.length + ' 套</span></div>' +
        apis.map(apiItem).join('') +
        '<div class="row-actions"><button type="button" id="api-add" class="btn-glass">＋ 新增一套</button></div>' +
        '<div class="sheet-note">生图、语音、识图各存一套，各自带自己的 Key 和请求头。不填不影响聊天。</div>' +
      '</div>';

    return names + chatApi + others;
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
      scrollChat();
      return;
    }

    if (id === 'diary') {
      const input = D.getElementById('diary-input');
      const saveBtn = D.getElementById('diary-save');
      if (!saveBtn) return;
      saveBtn.addEventListener('click', function () {
        const text = (input.value || '').trim();
        if (!text) { UI.toast('空着的，先写一句'); return; }
        const now = new Date();
        XW.S.diary.push({ text: text, date: UI.fmtYmd(now) + ' ' + UI.fmtClock(now), t: Date.now() });
        XW.save('diary');
        UI.toast('记下了');
        paint('diary');
      });
      return;
    }

    if (id === 'album') {
      const add = D.getElementById('album-add');
      const file = D.getElementById('album-file');
      if (add && file) {
        add.addEventListener('click', function () { file.click(); });
        file.addEventListener('change', async function () {
          const files = Array.prototype.slice.call(file.files || []);
          if (!files.length) return;
          UI.toast('处理中…');
          for (const f of files) {
            const data = await shrink(f, 900, 0.82);
            if (data) XW.S.photos.push(data);
          }
          XW.save('photos');
          file.value = '';
          UI.toast('放进来了');
          paint('album');
        });
      }
      Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-del]'), function (btn) {
        btn.addEventListener('click', function () {
          XW.S.photos.splice(Number(btn.dataset.del), 1);
          XW.save('photos');
          UI.toast('删掉了');
          paint('album');
        });
      });
      return;
    }

    if (id === 'settings') {
      const headBox = D.getElementById('set-ai-headers');
      if (headBox) headBox.value = XW.S.aiHeaders || '';

      const provider = D.getElementById('set-ai-provider');
      if (provider) {
        provider.addEventListener('change', function () {
          const preset = PRESETS[provider.value] || PRESETS.openai;
          XW.S.aiProvider = provider.value;
          XW.save('aiProvider');
          const urlEl = D.getElementById('set-ai-url');
          const modelEl = D.getElementById('set-ai-model');
          if (preset.url) urlEl.value = preset.url;
          if (preset.model) modelEl.value = preset.model;
          XW.S.aiHeaders = preset.headers || '';
          XW.save('aiHeaders');
          if (headBox) headBox.value = XW.S.aiHeaders;
          UI.toast(preset.label + ' 已填好，只差 Key');
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
          XW.S.aiUrl = read('set-ai-url');
          XW.S.aiModel = read('set-ai-model');
          XW.S.aiKey = read('set-ai-key');
          XW.S.aiHeaders = (D.getElementById('set-ai-headers').value || '').trim();
          XW.S.ctxLimit = Number(read('set-ctx')) || 128000;
          XW.S.aiUrlResolved = '';
          ['aiUrl', 'aiModel', 'aiKey', 'aiHeaders', 'ctxLimit', 'aiUrlResolved'].forEach(XW.save);
          UI.toast('连接保存了');
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
  }

  window.Router = { open: open, back: back, current: function () { return currentId; } };
})();
