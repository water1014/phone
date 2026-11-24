/* xw-mem.js · 记忆页增强 v2

   不动 pages.js，渲染完在它上面接一层。

   参照 wanyingsun357-ship-it/pwa-location-guide 的 memory 文档：
     数据结构  {status, decayClass, event, feel, act, lastInjectedAt}
     状态机    ACTIVE / PENDING / COMPLETED / SUPERSEDED / ARCHIVED
     衰减公式  2 ^ -(天数 / 半衰期)，normal 7 天、slow 30 天、none 不衰减

   这套里的向量检索与筛选模型需要服务端，前端做不了。这里只做纯计算那四样。
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

  /* ── 给老数据补字段，不改顺序（索引不能乱） ── */
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

    input.addEventListener('input', function () {
      filter(this.value.trim());
    });

    hero.insertAdjacentElement('afterend', box);
  }

  /* ── 每张卡：置顶开关 + 状态与衰减 ── */
  function dressCard(card, item, i) {
    const top = card.querySelector('.mcard-top');
    const del = card.querySelector('.mdel');

    if (top && del && !card.querySelector('.xw-mem-pin')) {
      const btn = D.createElement('button');
      btn.type = 'button';
      btn.className = 'xw-mem-pin' + (item.pinned ? ' on' : '');
      btn.textContent = item.pinned ? '\u9489\u7740' : '\u9489';
      btn.setAttribute('aria-label', item.pinned ? '\u53d6\u4e0b\u7f6e\u9876' : '\u7f6e\u9876');

      btn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        const now = notes();
        if (!now[i]) return;

        now[i].pinned = !now[i].pinned;
        save();

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
      ageDays(item) + ' \u5929\u00b7\u5269 ' + w + '%';

    if (w <= 25) meta.classList.add('faint');

    card.appendChild(meta);
  }

  function enhance() {
    if (!D.getElementById('mem-input')) return;

    const body = D.getElementById('app-body');
    if (!body) return;

    normalize();
    addSearch(body);

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
