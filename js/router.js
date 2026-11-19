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

  const BTN = 'padding:.42rem .9rem;border:1px solid var(--ink);border-radius:2rem;background:var(--ink);color:var(--on-dark);font:inherit;font-size:.58rem';

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
    if (id === 'diary') return diaryView();
    if (id === 'album') return albumView();
    if (id === 'settings') return settingsView();
    return '<div class="empty-state">这间还没开门。<br>骨架先立着，下一间再填它。</div>';
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
      '<div style="margin-top:.55rem;text-align:right">' +
        '<button type="button" id="diary-save" style="' + BTN + '">落笔</button>' +
      '</div>' +
      '<div id="diary-list" style="margin-top:1rem">' + rows + '</div>' +
    '</div>';
  }

  /* ── 相册 ── */
  function albumView() {
    const list = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    const gridStyle = 'display:grid;grid-template-columns:repeat(3,1fr);gap:.4rem;margin-top:.9rem';
    const cellStyle = 'position:relative;margin:0;aspect-ratio:1/1;border:1px solid var(--line);border-radius:.5rem;overflow:hidden;background:var(--card)';
    const imgStyle = 'width:100%;height:100%;object-fit:cover;display:block';
    const delStyle = 'position:absolute;top:.16rem;right:.16rem;width:1.1rem;height:1.1rem;border:0;border-radius:50%;background:rgba(0,0,0,.45);color:#fff;font-size:.62rem;line-height:1;

    const cells = list.map(function (url, i) {
      return '<figure style="' + cellStyle + '">' +
          '<img src="' + url + '" alt="" style="' + imgStyle + '">' +
          '<button type="button" data-del="' + i + '" aria-label="删掉这张" style="' + delStyle + '">×</button>' +
        '</figure>';
    }).join('');

    const body = list.length
      ? '<div style="' + gridStyle + '">' + cells + '</div>'
      : '<div class="empty-state" style="margin-top:2rem">还没有照片。<br>放一张进来，这里就有东西了。</div>';

    return '<div>' +
      '<div style="text-align:right"><button type="button" id="album-add" style="' + BTN + '">＋ 放一张</button></div>' +
      '<input id="album-file" type="file" accept="image/*" multiple hidden>' +
      body +
      '<p style="margin-top:1rem;font-size:.5rem;line-height:1.8;color:var(--ink-3)">照片只存在这台设备的浏览器里，清缓存会丢。</p>' +
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
  function settingsView() {
    return '<div>' +
      '<div class="kicker">WHO</div>' +
      '<p style="margin-top:.5rem;font-size:.8rem">' + UI.esc(XW.S.hisName) + ' &amp; ' + UI.esc(XW.S.herName) + '</p>' +
      '<div class="kicker" style="margin-top:1.3rem">SINCE</div>' +
      '<p style="margin-top:.5rem;font-size:.8rem">' + UI.esc(XW.S.loveDate) + '</p>' +
      '<p style="margin-top:1.8rem;font-size:.55rem;line-height:1.9;color:var(--ink-3)">骨架版。改名、改起算日、深色模式之后接在这里。</p>' +
    '</div>';
  }

  function bind(id) {
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
          const index = Number(btn.dataset.del);
          XW.S.photos.splice(index, 1);
          XW.save('photos');
          UI.toast('删掉了');
          paint('album');
        });
      });
    }
  }

  window.Router = { open: open, back: back, current: function () { return currentId; } };
})();
