/* pages.js · 日记 / 相册（卡片式版式） */
(function () {
  const D = document;

  function esc(text) {
    if (window.UI && UI.esc) return UI.esc(text);
    return String(text == null ? '' : text).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  function hero(kicker, title, sub) {
    return '<header class="hero">' +
        '<span class="kicker">' + esc(kicker) + '</span>' +
        '<h1 class="hero-title">' + esc(title) + '</h1>' +
        '<div class="hero-sub">' + esc(sub) + '</div>' +
      '</header>';
  }

  function dayKey(date) {
    const hit = String(date || '').match(/(\d{4})-(\d{2})-(\d{2})/);
    return hit ? hit[1] + '-' + hit[2] + '-' + hit[3] : '';
  }

  function streak(list) {
    const set = {};
    list.forEach(function (item) { const k = dayKey(item.date); if (k) set[k] = true; });

    let count = 0;
    const cursor = new Date();
    for (let i = 0; i < 400; i++) {
      const y = cursor.getFullYear();
      const m = String(cursor.getMonth() + 1).padStart(2, '0');
      const d = String(cursor.getDate()).padStart(2, '0');
      const key = y + '-' + m + '-' + d;
      if (set[key]) {
        count += 1;
        cursor.setDate(cursor.getDate() - 1);
        continue;
      }
      if (i === 0) { cursor.setDate(cursor.getDate() - 1); continue; }
      break;
    }
    return count;
  }

  /* ── 日记 ── */
  function diary() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary : [];
    const year = new Date().getFullYear();
    const yearCount = list.filter(function (item) {
      return String(item.date || '').indexOf(String(year)) === 0;
    }).length;

    const sub = '今年 ' + yearCount + ' 篇 · 共 ' + list.length + ' 篇 · 连续 ' + streak(list) + ' 天';

    const cards = list.slice().reverse().map(function (item) {
      const text = String(item.text || '');
      return '<article class="dcard">' +
          '<div class="dcard-date">' + esc(item.date || '') + '</div>' +
          '<p class="dcard-text">' + esc(text) + '</p>' +
          '<div class="dcard-meta">' + text.length + ' 字</div>' +
        '</article>';
    }).join('');

    const body = list.length
      ? '<div class="cards">' + cards + '</div>'
      : '<div class="empty-state" style="margin-top:1.2rem">还没有第一篇。<br>今天我也还没动笔。</div>';

    return hero('DIARY', '日记', sub) +
      '<div class="sheet">' +
        '<label class="field"><span>今天</span>' +
          '<textarea id="diary-input" rows="4" placeholder="今天想留一句什么…"></textarea>' +
        '</label>' +
        '<div class="row-actions"><button type="button" id="diary-save" class="btn-solid">落笔</button></div>' +
      '</div>' +
      '<div class="album-date-band">写过的</div>' +
      body;
  }

  function diaryBind(bodyEl) {
    const input = D.getElementById('diary-input');
    const save = D.getElementById('diary-save');
    if (!save) return;
    save.addEventListener('click', function () {
      const text = (input.value || '').trim();
      if (!text) { UI.toast('空着的，先写一句'); return; }
      const now = new Date();
      XW.S.diary.push({ text: text, date: UI.fmtYmd(now) + ' ' + UI.fmtClock(now), t: Date.now() });
      XW.save('diary');
      UI.toast('记下了');
      window.Router.reopen('diary');
    });
  }

  /* ── 相册 ── */
  function album() {
    const list = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    const sub = list.length ? (list.length + ' 张 · 都在这一台设备上') : '还空着';

    const cells = list.map(function (url, i) {
      return '<figure class="album-cell"><img src="' + url + '" alt="">' +
        '<button type="button" class="album-del" data-del="' + i + '" aria-label="删掉这张">×</button></figure>';
    }).join('');

    const body = list.length
      ? '<div class="album-grid">' + cells + '</div>'
      : '<div class="empty-state" style="margin-top:1.2rem">还没有照片。<br>放一张进来，这里就有东西了。</div>';

    return hero('ALBUM', '相册', sub) +
      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">照片</span>' +
          '<button type="button" id="album-add" class="btn-glass">＋ 放一张</button></div>' +
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

  function albumBind(bodyEl) {
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
        window.Router.reopen('album');
      });
    }
    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-del]'), function (btn) {
      btn.addEventListener('click', function () {
        XW.S.photos.splice(Number(btn.dataset.del), 1);
        XW.save('photos');
        UI.toast('删掉了');
        window.Router.reopen('album');
      });
    });
  }

  window.Pages = { diary: diary, diaryBind: diaryBind, album: album, albumBind: albumBind, hero: hero };
})();
