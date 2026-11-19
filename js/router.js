/* router.js · 打开 App / 返回桌面
   一个全屏层，一次只开一个 App。 */
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
    bodyEl.innerHTML = render(id);
    host.classList.add('show');
    bind(id);
  }

  function back() {
    if (!host) return;
    host.classList.remove('show');
    bodyEl.innerHTML = '';
    currentId = null;
  }

  function render(id) {
    if (id === 'diary') return diaryView();
    if (id === 'settings') return settingsView();
    return '<div class="empty-state">这间还没开门。<br>骨架先立着，下一间再填它。</div>';
  }

  /* ── 日记：真能写、真能存 ── */
  function diaryView() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary.slice().reverse() : [];
    const rows = list.length
      ? list.map(function (item) {
          return '<article class="diary-item">' +
            '<div class="kicker">' + UI.esc(item.date || '') + '</div>' +
            '<p>' + UI.esc(item.text || '') + '</p>' +
          '</article>';
        }).join('')
      : '<div class="empty-state" style="margin-top:2rem">还没有第一篇。<br>今天我也还没动笔。</div>';

    return '<div>' +
      '<textarea id="diary-input" rows="4" placeholder="今天想留一句什么…" style="width:100%;min-height:5.2rem;padding:.65rem;border:1px solid var(--line);border-radius:.6rem;background:var(--card);color:var(--ink);font:inherit;font-size:.72rem;line-height:1.7;outline:none;resize:vertical"></textarea>' +
      '<div style="margin-top:.55rem;text-align:right">' +
        '<button type="button" id="diary-save" style="padding:.42rem .9rem;border:1px solid var(--ink);border-radius:2rem;background:var(--ink);color:var(--on-dark);font:inherit;font-size:.58rem">落笔</button>' +
      '</div>' +
      '<div id="diary-list" style="margin-top:1rem">' + rows + '</div>' +
    '</div>';
  }

  function settingsView() {
    return '<div>' +
      '<div class="kicker">WHO</div>' +
      '<p style="margin-top:.5rem;font-size:.8rem">' + UI.esc(XW.S.hisName) + ' &amp; ' + UI.esc(XW.S.herName) + '</p>' +
      '<div class="kicker" style="margin-top:1.2rem">SINCE</div>' +
      '<p style="margin-top:.5rem;font-size:.8rem">' + UI.esc(XW.S.loveDate) + '</p>' +
      '<p style="margin-top:1.6rem;font-size:.56rem;line-height:1.9;color:var(--ink-3)">这里是骨架版。名字、起算日、深色模式之后接过来。</p>' +
    '</div>';
  }

  function bind(id) {
    if (id !== 'diary') return;
    const input = D.getElementById('diary-input');
    const saveBtn = D.getElementById('diary-save');
    if (!saveBtn) return;
    saveBtn.addEventListener('click', function () {
      const text = (input.value || '').trim();
      if (!text) { UI.toast('空着的，先写一句'); return; }
      const now = new Date();
      XW.S.diary.push({ text: text, date: UI.fmtYmd(now) + ' ' + UI.fmtClock(now), t: Date.now() });
      XW.save('diary');
      input.value = '';
      bodyEl.querySelector('#diary-list').innerHTML =
        '<article class="diary-item"><div class="kicker">' + UI.esc(XW.S.diary[XW.S.diary.length - 1].date) + '</div><p>' + UI.esc(text) + '</p></article>' +
        bodyEl.querySelector('#diary-list').innerHTML;
      UI.toast('记下了');
    });
  }

  window.Router = { open: open, back: back, current: function () { return currentId; } };
})();
