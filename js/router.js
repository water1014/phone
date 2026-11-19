/* router.js · 打开 App / 返回桌面 */
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

  const BTN = 'padding:.42rem .9rem;border:1px solid var(--ink);border-radius:2rem;background:var(--ink);color:var(--on-dark);font:inherit;font-size:.58rem';
  const INPUT = 'width:100%;min-width:0;padding:.55rem .6rem;border:1px solid var(--line);border-radius:.55rem;background:var(--card);color:var(--ink);font:inherit;font-size:.7rem;outline:none';

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
    return '<div class="empty-state">这间还没开门。<br>骨架先立着，下一间再填它。</div>';
  }

  /* ── 聊天 ── */
  function chatView() {
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    const rows = list.map(function (m) {
      if (m._typing) {
        return '<div style="display:flex;justify-content:flex-start;margin-bottom:.5rem">' +
          '<div style="padding:.5rem .66rem;border:1px solid var(--line);border-radius:.7rem .7rem .7rem .2rem;background:var(--card);color:var(--ink-3);font-size:.7rem">…</div>' +
        '</div>';
      }
      const mine = m.who === 'me';
      return '<div style="display:flex;justify-content:' + (mine ? 'flex-end' : 'flex-start') + ';margin-bottom:.5rem">' +
          '<div style="max-width:78%;padding:.5rem .66rem;white-space:pre-wrap;border:1px solid ' + (mine ? 'transparent' : 'var(--line)') + ';border-radius:' + (mine ? '.7rem .7rem .2rem .7rem' : '.7rem .7rem .7rem .2rem') + ';background:' + (mine ? 'var(--dark)' : 'var(--card)') + ';color:' + (mine ? 'var(--on-dark)' : 'var(--ink)') + ';font-size:.72rem;line-height:1.7">' + UI.esc(m.text) + '</div>' +
        '</div>';
    }).join('');

    const body = list.length ? rows : '<div class="empty-state" style="margin-top:2rem">还没说话。<br>在下面写一句，就有了。</div>';
    const hint = XW.S.aiKey ? '' : '<p style="margin-top:.5rem;font-size:.48rem;color:var(--ink-3)">还没填接口，现在只存你自己说的话。</p>';

    return '<div>' +
        '<div id="chat-scroll" style="max-height:58vh;overflow-y:auto;padding-bottom:.6rem">' + body + '</div>' +
        hint +
        '<div style="display:flex;gap:.4rem;margin-top:.6rem;padding-top:.6rem;border-top:1px solid var(--line)">' +
          '<input id="chat-input" placeholder="说一句…" style="' + INPUT + '">' +
          '<button type="button" id="chat-send" style="' + BTN + '">发</button>' +
        '</div>' +
      '</div>';
  }

  function scrollChat() {
    const box = D.getElementById('chat-scroll');
    if (box) box.scrollTop = box.scrollHeight;
  }

  async function callAI() {
    const key = (XW.S.aiKey || '').trim();
    if (!key) return '';
    const url = (XW.S.aiUrl || 'https://api.openai.com/v1/chat/completions').trim();
    const model = (XW.S.aiModel || 'gpt-4o-mini').trim();
    const history = XW.S.chat
      .filter(function (m) { return !m._typing; })
      .slice(-20)
      .map(function (m) { return { role: m.who === 'ta' ? 'assistant' : 'user', content: String(m.text || '') }; })
      .filter(function (m) { return m.content; });

    const system = '你住在「小窝」这个私人小手机里。说话自然、简短，像真人在手机上回消息，不要列条目、不要客服腔。';
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + key },
      body: JSON.stringify({
        model: model,
        messages: [{ role: 'system', content: system }].concat(history),
        stream: false
      })
    });
    if (!res.ok) throw new Error('HTTP ' + res.status);
    const data = await res.json();
    const choice = data && data.choices && data.choices[0];
    const message = choice && choice.message;
    let content = message && message.content;
    if (Array.isArray(content)) content = content.map(function (p) { return typeof p === 'string' ? p : (p && p.text) || ''; }).join('');
    return String(content || '').trim();
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

    if (!(XW.S.aiKey || '').trim()) return;

    XW.S.chat.push({ who: 'ta', text: '', t: Date.now(), _typing: true });
    paint('chat');
    scrollChat();

    try {
      const reply = await callAI();
      XW.S.chat = XW.S.chat.filter(function (m) { return !m._typing; });
      XW.S.chat.push({ who: 'ta', text: reply || '（没说出话）', t: Date.now() });
    } catch (err) {
      XW.S.chat = XW.S.chat.filter(function (m) { return !m._typing; });
      XW.S.chat.push({ who: 'ta', text: '（连不上：' + (err.message || err) + '）', t: Date.now() });
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
          return '<article style="padding:.7rem 0;border-bottom:1px solid var(--line)">' +
            '<div class="kicker">' + UI.esc(item.date || '') + '</div>' +
            '<p style="margin-top:.35rem;font-size:.72rem;line-height:1.8">' + UI.esc(item.text || '') + '</p>' +
          '</article>';
        }).join('')
      : '<div class="empty-state" style="margin-top:2rem">还没有第一篇。<br>今天我也还没动笔。</div>';

    return '<div>' +
      '<textarea id="diary-input" rows="4" placeholder="今天想留一句什么…" style="width:100%;min-height:5.2rem;padding:.65rem;border:1px solid var(--line);border-radius:.6rem;background:var(--card);color:var(--ink);font:inherit;font-size:.72rem;line-height:1.7;outline:none;resize:vertical"></textarea>' +
      '<div style="margin-top:.55rem;text-align:right"><button type="button" id="diary-save" style="' + BTN + '">落笔</button></div>' +
      '<div id="diary-list" style="margin-top:1rem">' + rows + '</div>' +
    '</div>';
  }

  /* ── 相册 ── */
  function albumView() {
    const list = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    const cellStyle = 'position:relative;margin:0;aspect-ratio:1/1;border:1px solid var(--line);border-radius:.5rem;overflow:hidden;background:var(--card)';
    const imgStyle = 'width:100%;height:100%;object-fit:cover;display:block';
    const delStyle = 'position:absolute;top:.16rem;right:.16rem;width:1.1rem;height:1.1rem;border:0;border-radius:50%;background:rgba(0,0,0,.45);color:#fff;font-size:.62rem;line-height:1';

    const cells = list.map(function (url, i) {
      return '<figure style="' + cellStyle + '"><img src="' + url + '" alt="" style="' + imgStyle + '"><button type="button" data-del="' + i + '" aria-label="删掉这张" style="' + delStyle + '">×</button></figure>';
    }).join('');

    const body = list.length
      ? '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:.4rem;margin-top:.9rem">' + cells + '</div>'
      : '<div class="empty-state" style="margin-top:2rem">还没有照片。<br>放一张进来，这里就有东西了。</div>';

    return '<div>' +
      '<div style="text-align:right"><button type="button" id="album-add" style="' + BTN + '">＋ 放一张</button></div>' +
      '<input id="album-file" type="file" accept="image/*" multiple hidden>' +
      body +
      '<p style="margin-top:1rem;font-size:.48rem;line-height:1.8;color:var(--ink-3)">照片只存在这台设备的浏览器里，清缓存会丢。</p>' +
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
  function fieldView(label, id, value, type) {
    return '<label style="display:block;margin-top:.8rem">' +
        '<span class="kicker">' + label + '</span>' +
        '<input id="' + id + '" type="' + (type || 'text') + '" value="' + UI.esc(value) + '" style="' + INPUT + ';margin-top:.3rem">' +
      '</label>';
  }

  function settingsView() {
    return '<div>' +
      '<div class="kicker">名字</div>' +
      fieldView('他的称呼', 'set-his', XW.S.hisName) +
      fieldView('她的称呼', 'set-her', XW.S.herName) +
      fieldView('在一起从哪天开始', 'set-love', XW.S.loveDate) +
      '<div class="kicker" style="margin-top:1.5rem">AI 连接｜不填就只存你自己的话</div>' +
      fieldView('接口地址', 'set-ai-url', XW.S.aiUrl) +
      fieldView('模型', 'set-ai-model', XW.S.aiModel) +
      fieldView('API Key', 'set-ai-key', XW.S.aiKey, 'password') +
      '<div style="margin-top:1rem;text-align:right"><button type="button" id="set-save" style="' + BTN + '">保存</button></div>' +
      '<p style="margin-top:1.2rem;font-size:.48rem;line-height:1.8;color:var(--ink-3)">所有东西都存在这台设备的浏览器里，不上传任何服务器。</p>' +
    '</div>';
  }

  function bind(id) {
    if (id === 'chat') {
      const btn = D.getElementById('chat-send');
      const input = D.getElementById('chat-input');
      if (btn) btn.addEventListener('click', sendChat);
      if (input) input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendChat(); }
      });
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
      const saveBtn = D.getElementById('set-save');
      if (!saveBtn) return;
      saveBtn.addEventListener('click', function () {
        const read = function (el) { return (el && el.value ? el.value : '').trim(); };
        XW.S.hisName = read(D.getElementById('set-his')) || '他';
        XW.S.herName = read(D.getElementById('set-her')) || '她';
        XW.S.loveDate = read(D.getElementById('set-love')) || '2025-01-01';
        XW.S.aiUrl = read(D.getElementById('set-ai-url')) || 'https://api.openai.com/v1/chat/completions';
        XW.S.aiModel = read(D.getElementById('set-ai-model')) || 'gpt-4o-mini';
        XW.S.aiKey = read(D.getElementById('set-ai-key'));
        ['hisName', 'herName', 'loveDate', 'aiUrl', 'aiModel', 'aiKey'].forEach(XW.save);
        UI.toast('保存了');
        if (window.Desktop) window.Desktop.rerender();
      });
    }
  }

  window.Router = { open: open, back: back, current: function () { return currentId; } };
})();
