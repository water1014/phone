/* xw-mem.js · 记忆页增强

   不动 pages.js。页面渲染完在它上面再接一层：
   1. 搜索：找一条
   2. 置顶开关：钉上去之后能取下来（原来钉了永远钉着）
*/
(function () {
  const D = document;

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

  /* ── 搜索 ── */
  function filter(q) {
    const body = D.getElementById('app-body');
    if (!body) return;

    const key = q.toLowerCase();

    Array.prototype.forEach.call(body.querySelectorAll('.mcard'), function (card) {
      const hit = !key || (card.textContent || '').toLowerCase().indexOf(key) >= 0;
      card.style.display = hit ? '' : 'none';
    });

    /* 一组全被藏了就把它的小标也藏掉 */
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

  /* ── 置顶开关 ── */
  function addPins(body) {
    const list = notes();

    Array.prototype.forEach.call(body.querySelectorAll('.mcard'), function (card) {
      if (card.querySelector('.xw-mem-pin')) return;

      const del = card.querySelector('.mdel');
      if (!del) return;

      const i = Number(del.getAttribute('data-md'));
      const item = list[i];
      if (!item) return;

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

      const top = card.querySelector('.mcard-top');
      if (top) top.insertBefore(btn, del);
    });
  }

  function enhance() {
    /* #mem-input 是记忆页特有的，用它认页面 */
    if (!D.getElementById('mem-input')) return;

    const body = D.getElementById('app-body');
    if (!body) return;

    addSearch(body);
    addPins(body);
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
