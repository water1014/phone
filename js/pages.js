/* pages.js · 日记 / 相册 / 日历 / 记忆 */
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

  function pad2(n) { return String(n).padStart(2, '0'); }

  function dayKey(date) {
    const hit = String(date || '').match(/(\d{4})-(\d{2})-(\d{2})/);
    return hit ? hit[1] + '-' + hit[2] + '-' + hit[3] : '';
  }

  function ymdKey(d) {
    return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate());
  }

  function streak(list) {
    const set = {};
    list.forEach(function (item) { const k = dayKey(item.date); if (k) set[k] = true; });

    let count = 0;
    const cursor = new Date();
    for (let i = 0; i < 400; i++) {
      const key = ymdKey(cursor);
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

  /* ── 日历 ── */
  let calMonth = null;
  let calPick = '';

  function calendarFocus(key) {
    const hit = String(key || '').match(/(\d{4})-(\d{2})-(\d{2})/);
    if (!hit) return;
    calPick = hit[1] + '-' + hit[2] + '-' + hit[3];
    calMonth = new Date(Number(hit[1]), Number(hit[2]) - 1, 1);
  }

  function calendar() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary : [];
    const set = {};
    list.forEach(function (item) { const k = dayKey(item.date); if (k) set[k] = true; });

    const today = new Date();
    const todayKey = ymdKey(today);
    const base = calMonth || new Date(today.getFullYear(), today.getMonth(), 1);
    const y = base.getFullYear();
    const m = base.getMonth();

    if (!calPick) calPick = todayKey;

    const startPad = new Date(y, m, 1).getDay();
    const days = new Date(y, m + 1, 0).getDate();
    const monthKey = y + '-' + pad2(m + 1);

    let wrote = 0;
    Object.keys(set).forEach(function (k) { if (k.indexOf(monthKey) === 0) wrote += 1; });

    const cells = [];
    for (let i = 0; i < startPad; i++) cells.push('<span class="cal-cell out"></span>');
    for (let d = 1; d <= days; d++) {
      const key = monthKey + '-' + pad2(d);
      const cls = ['cal-cell'];
      if (set[key]) cls.push('has');
      if (key === todayKey) cls.push('today');
      if (key === calPick) cls.push('sel');
      cells.push('<button type="button" class="' + cls.join(' ') + '" data-day="' + key + '">' + d + '</button>');
    }

    const week = ['日', '一', '二', '三', '四', '五', '六'].map(function (w) {
      return '<span>' + w + '</span>';
    }).join('');

    const grid = '<div class="sheet cal-sheet">' +
        '<div class="cal-head">' +
          '<button type="button" class="cal-nav" data-cal="prev" aria-label="上个月">‹</button>' +
          '<span class="cal-title">' + y + '年' + (m + 1) + '月</span>' +
          '<button type="button" class="cal-nav" data-cal="next" aria-label="下个月">›</button>' +
        '</div>' +
        '<div class="cal-week">' + week + '</div>' +
        '<div class="cal-grid">' + cells.join('') + '</div>' +
      '</div>';

    const picked = list.filter(function (item) { return dayKey(item.date) === calPick; });
    let detail = '';

    if (picked.length) {
      detail = picked.slice().reverse().map(function (item) {
        const text = String(item.text || '');
        const clock = (String(item.date || '').split(' ')[1]) || '';
        return '<article class="dcard">' +
            '<div class="dcard-date">' + esc(calPick) + (clock ? ' · ' + esc(clock) : '') + '</div>' +
            '<p class="dcard-text">' + esc(text) + '</p>' +
            '<div class="dcard-meta">' + text.length + ' 字</div>' +
          '</article>';
      }).join('');
    } else {
      detail = '<div class="sheet"><div class="empty-state">这天还空着。<br>想补就补，不想就算了。</div></div>';
    }

    const sub = y + '年' + (m + 1) + '月 · 写过 ' + wrote + ' 天';

    return hero('CALENDAR', '日历', sub) + grid +
      '<div class="album-date-band">' + (calPick === todayKey ? '今天' : esc(calPick)) + '</div>' + detail;
  }

  function calendarBind(bodyEl) {
    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-cal]'), function (btn) {
      btn.addEventListener('click', function () {
        const base = calMonth || new Date(new Date().getFullYear(), new Date().getMonth(), 1);
        const step = btn.dataset.cal === 'prev' ? -1 : 1;
        calMonth = new Date(base.getFullYear(), base.getMonth() + step, 1);
        calPick = '';
        window.Router.reopen('calendar');
      });
    });

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-day]'), function (btn) {
      btn.addEventListener('click', function () {
        calPick = btn.dataset.day;
        window.Router.reopen('calendar');
      });
    });
  }

  /* ── 记忆 ── */
  let memPin = false;

  function memCard(item, i) {
    const date = String(item.date || '');
    return '<article class="mcard' + (item.pinned ? ' pinned' : '') + '">' +
        '<div class="mcard-top">' +
          '<span class="mstamp">' + esc(date) + '</span>' +
          '<button type="button" class="mdel" data-md="' + i + '" aria-label="删掉">×</button>' +
        '</div>' +
        '<p class="mtext">' + esc(String(item.text || '')) + '</p>' +
      '</article>';
  }

  function memory() {
    const list = Array.isArray(XW.S.notes) ? XW.S.notes : [];
    const pinned = [];
    const rest = [];

    list.forEach(function (item, i) {
      const row = { item: item, index: i };
      if (item && item.pinned) pinned.push(row);
      else rest.push(row);
    });

    rest.sort(function (a, b) { return (b.item.t || 0) - (a.item.t || 0); });

    const sub = list.length
      ? '共 ' + list.length + ' 条 · 钉住 ' + pinned.length + ' 条'
      : '还空着。你说过的，我都记在这里。';

    const pinnedBlock = pinned.length
      ? '<div class="album-date-band">钉住的</div>' + pinned.map(function (r) { return memCard(r.item, r.index); }).join('')
      : '';

    const restBlock = rest.length
      ? '<div class="album-date-band">全部</div>' + rest.map(function (r) { return memCard(r.item, r.index); }).join('')
      : (pinned.length ? '' : '<div class="empty-state" style="margin-top:1rem">还没记下什么。<br>往上面写一句，我就存着。</div>');

    return hero('MEMORY', '记忆', sub) +
      '<div class="sheet">' +
        '<label class="field"><span>记一条</span>' +
          '<textarea id="mem-input" rows="3" placeholder="想让我一直记得的…"></textarea>' +
        '</label>' +
        '<div class="row-actions">' +
          '<button type="button" id="mem-pin" class="btn-glass">钉永久</button>' +
          '<button type="button" id="mem-save" class="btn-solid">记下</button>' +
        '</div>' +
        '<div class="sheet-note">钉住的那几条会置顶，提醒我别忘了。</div>' +
      '</div>' +
      pinnedBlock + restBlock;
  }

  function memoryBind(bodyEl) {
    const input = D.getElementById('mem-input');
    const save = D.getElementById('mem-save');
    const pin = D.getElementById('mem-pin');

    if (pin) {
      pin.addEventListener('click', function () {
        memPin = !memPin;
        pin.textContent = memPin ? '已钉 ✓' : '钉永久';
        pin.classList.toggle('on', memPin);
      });
    }

    if (save && input) {
      save.addEventListener('click', function () {
        const text = (input.value || '').trim();
        if (!text) { UI.toast('空着的'); return; }
        const now = new Date();
        XW.S.notes = Array.isArray(XW.S.notes) ? XW.S.notes : [];
        XW.S.notes.push({
          text: text,
          date: UI.fmtYmd(now),
          pinned: memPin,
          t: Date.now()
        });
        XW.save('notes');
        memPin = false;
        UI.toast('记住了');
        window.Router.reopen('memory');
      });
    }

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-md]'), function (btn) {
      btn.addEventListener('click', function () {
        XW.S.notes.splice(Number(btn.dataset.md), 1);
        XW.save('notes');
        UI.toast('删了');
        window.Router.reopen('memory');
      });
    });
  }

  window.Pages = {
    diary: diary,
    diaryBind: diaryBind,
    album: album,
    albumBind: albumBind,
    calendar: calendar,
    calendarBind: calendarBind,
    calendarFocus: calendarFocus,
    memory: memory,
    memoryBind: memoryBind,
    hero: hero
  };
})();
