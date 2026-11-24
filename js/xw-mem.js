/* xw-mem.js · 记忆页增强 v3

   不动 pages.js，渲染完在它上面接一层。

   参照 wanyingsun357-ship-it/pwa-location-guide 的 memory 文档：
     数据结构  {status, decayClass, event, feel, act}
     状态机    ACTIVE / PENDING / COMPLETED / SUPERSEDED / ARCHIVED
     衰减公式  2 ^ -(天数 / 半衰期)

   v3 增加：云端配置入口 + 两个手动同步动作。
*/

(function () {
  const D = document;
  const DAY = 86400000;

  const STATUS = {
    ACTIVE: '\u6709\u6548',
    PENDING: '\u672a\u5151\u73b0',
    COMPLETED: '\u5df2\u5151\u73b0',
    SUPERSEDED: '\u5df2\u88ab\u8986\u76d6',
    ARCHIVED: '\u5df2\u5f52\u6863'
  };

  const DECAY = {
    normal: '7\u5929\u534a\u8870\u671f',
    slow: '30\u5929\u534a\u8870\u671f',
    none: '\u4e0d\u8870\u51cf'
  };

  function notes() {
    return Array.isArray(XW.S.notes) ? XW.S.notes : [];
  }

  function save() {
    XW.S.notes = notes();
    XW.save('notes');
  }

  function rerender() {
    if (window.Router && Router.reopen) Router.reopen('memory');
  }

  function normalize() {
    let dirty = false;
    notes().forEach(function (it) {
      if (!it || typeof it !== 'object') return;
      if (!it.status) { it.status = 'ACTIVE'; dirty = true; }
      if (!it.decayClass) { it.decayClass = 'normal'; dirty = true; }
      if (typeof it.act !== 'number') { it.act = 0; dirty = true; }
    });
    if (dirty) save();
  }

  function born(it) {
    if (it.t) return new Date(it.t);
    const m = String(it.date || '').match(/(\d{4})-(\d{2})-(\d{2})/);
    if (m) return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
    return new Date();
  }

  function ageDays(it) {
    return Math.max(0, Math.floor((Date.now() - born(it).getTime()) / DAY));
  }

  function weight(it) {
    const cls = it.decayClass || 'normal';
    if (cls === 'none') return 1;
    const half = cls === 'slow' ? 30 : 7;
    return Math.pow(2, -ageDays(it) / half);
  }

  /* ── 搜索 ── */
  function filter(q) {
    const body = D.getElementById('app-body');
    if (!body) return;
    const key = q.toLowerCase();

    Array.prototype.forEach.call(body.querySelectorAll('.mcard'), function (card) {
      const hit = !key || (card.textContent || '').toLowerCase().indexOf(key) >= 0;
      card.style.display = hit ? '' : 'none';
    });

    Array.prototype.forEach.call(body.querySelectorAll('.album-date-band'), function (band) {
      let n = band.nextElementSibling;
      let shown = 0;
      while (n && n.classList && n.classList.contains('mcard')) {
        if (n.style.display !== 'none') shown++;
        n = n.nextElementSibling;
      }
      band.style.display = shown ? '' : 'none';
    });
  }

  function addSearch(body) {
    if (D.getElementById('xw-mem-q')) return;
    const hero = body.querySelector('.hero');
    if (!hero) return;

    const box = D.createElement('div');
    box.className = 'xw-mem-search';

    const input = D.createElement('input');
    input.id = 'xw-mem-q';
    input.type = 'search';
    input.autocomplete = 'off';
    input.placeholder = '\u627e\u4e00\u6761\u2026';
    box.appendChild(input);
    input.addEventListener('input', function () { filter(this.value.trim()); });

    hero.insertAdjacentElement('afterend', box);
  }

  /* ── 云端面板 ── */
  function addCloud(body) {
    if (D.getElementById('xw-cloud')) return;

    const anchor = D.getElementById('xw-mem-q');
    const host = anchor ? anchor.parentNode : body.querySelector('.hero');
    if (!host) return;

    const box = D.createElement('div');
    box.id = 'xw-cloud';
    box.className = 'xw-cloud';

    const c = window.XWCloud ? XWCloud.cfg() : { url: '', key: '', ok: false };

    box.innerHTML =
      '<div class="xw-cloud-hd">\u4e91\u7aef\u5907\u4efd</div>' +
      '<input id="xw-sb-url" type="url" placeholder="Project URL\uff08https://xxx.supabase.co\uff09">' +
      '<input id="xw-sb-key" type="password" placeholder="anon key\uff08eyJ\u5f00\u5934\u7684\u90a3\u4e32\uff09">' +
      '<div class="row">' +
        '<button type="button" id="xw-sb-save">\u5b58\u8d77\u6765</button>' +
        '<button type="button" id="xw-sb-test">\u8bd5\u4e00\u4e0b</button>' +
        '<button type="button" id="xw-sb-up">\u2191 \u4f20\u5230\u4e91</button>' +
        '<button type="button" id="xw-sb-down">\u2193 \u4ece\u4e91\u62c9\u56de</button>' +
      '</div>' +
      '<div class="msg" id="xw-sb-msg"></div>';

    host.insertAdjacentElement('afterend', box);

    const uEl = D.getElementById('xw-sb-url');
    const kEl = D.getElementById('xw-sb-key');
    const msg = D.getElementById('xw-sb-msg');

    uEl.value = c.url;
    kEl.value = c.key;

    function say(t, bad) {
      msg.textContent = t;
      msg.classList.toggle('bad', !!bad);
    }

    D.getElementById('xw-sb-save').addEventListener('click', function () {
      XWCloud.setCfg(uEl.value, kEl.value);
      say('\u5b58\u597d\u4e86');
    });

    D.getElementById('xw-sb-test').addEventListener('click', function () {
      XWCloud.setCfg(uEl.value, kEl.value);
      say('\u8fde\u7740\u2026');
      XWCloud.ping()
        .then(function () { say('\u901a\u4e86'); })
        .catch(function (e) { say('\u4e0d\u901a\uff1a' + e.message, true); });
    });

    D.getElementById('xw-sb-up').addEventListener('click', function () {
      XWCloud.setCfg(uEl.value, kEl.value);
      const list = notes();
      let n = 0;
      let fail = 0;

      say('\u4f20\u7740\u2026 0/' + list.length);

      const run = function (i) {
        if (i >= list.length) {
          save();
          say('\u4f20\u5b8c\u4e86 \u00b7 \u6210\u529f ' + n + '\uff0c\u5931\u8d25 ' + fail, fail > 0);
          return;
        }
        const it = list[i];
        if (it.cloudId) { run(i + 1); return; }

        XWCloud.push(it)
          .then(function (id) {
            if (id) it.cloudId = id;
            n++;
            save();
            say('\u4f20\u7740\u2026 ' + (i + 1) + '/' + list.length);
          })
          .catch(function () { fail++; })
          .then(function () { run(i + 1); });
      };

      run(0);
    });

    D.getElementById('xw-sb-down').addEventListener('click', function () {
      XWCloud.setCfg(uEl.value, kEl.value);
      say('\u62c9\u7740\u2026');

      XWCloud.list()
        .then(function (rows) {
          if (!Array.isArray(rows)) throw new Error('\u6ca1\u62ff\u5230\u6570\u636e');
          XW.S.notes = rows.map(XWCloud.fromRow);
          XW.save('notes');
          say('\u62c9\u56de\u6765 ' + rows.length + ' \u6761');
          rerender();
        })
        .catch(function (e) { say('\u62c9\u4e0d\u52a8\uff1a' + e.message, true); });
    });
  }

  /* ── 每张卡 ── */
  function dressCard(card, item, i) {
    const top = card.querySelector('.mcard-top');
    const del = card.querySelector('.mdel');

    if (top && del && !card.querySelector('.xw-mem-pin')) {
      const btn = D.createElement('button');
      btn.type = 'button';
      btn.className = 'xw-mem-pin' + (item.pinned ? ' on' : '');
      btn.textContent = item.pinned ? '\u9489\u7740' : '\u9489';

      btn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        const now = notes();
        if (!now[i]) return;
        now[i].pinned = !now[i].pinned;
        save();

        if (now[i].cloudId && window.XWCloud) {
          XWCloud.patch(now[i].cloudId, now[i]).catch(function () {});
        }

        if (window.UI && UI.toast) {
          UI.toast(now[i].pinned ? '\u9489\u4f4f\u4e86' : '\u53d6\u4e0b\u6765\u4e86');
        }

        rerender();
      });

      top.insertBefore(btn, del);
    }

    if (card.querySelector('.mmeta')) return;

    const w = Math.round(weight(item) * 100);
    const meta = D.createElement('div');
    meta.className = 'mmeta';
    meta.textContent =
      (STATUS[item.status] || item.status || '\u6709\u6548') + '\u00b7' +
      (DECAY[item.decayClass] || DECAY.normal) + '\u00b7\u7b2c ' +
      ageDays(item) + ' \u5929\u00b7\u5269 ' + w + '%' +
      (item.cloudId ? '\u00b7\u5df2\u4e0a\u4e91' : '');

    if (w <= 25) meta.classList.add('faint');
    card.appendChild(meta);
  }

  function enhance() {
    if (!D.getElementById('mem-input')) return;

    const body = D.getElementById('app-body');
    if (!body) return;

    normalize();
    addSearch(body);

    if (window.XWCloud) addCloud(body);

    const list = notes();

    Array.prototype.forEach.call(body.querySelectorAll('.mcard'), function (card) {
      const del = card.querySelector('.mdel');
      if (!del) return;
      const i = Number(del.getAttribute('data-md'));
      const item = list[i];
      if (!item) return;
      dressCard(card, item, i);
    });
  }

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      enhance();
    }, 120);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  enhance();
  setTimeout(enhance, 400);
  setTimeout(enhance, 1200);
})();
