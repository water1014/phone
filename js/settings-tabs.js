/* settings-tabs.js · 设置页拆成几个分类，上面一条横滑 */
(function () {
  const D = document;
  const K = 'xw_st_tab';
  const TABS = [
    ['name', '称呼'],
    ['api', '接口'],
    ['other', '其它'],
    ['house', '小窝']
  ];

  function bodyEl() {
    const body = D.getElementById('app-body');
    if (!body) return null;
    if (!body.querySelector('#set-ai-provider')) return null;
    return body;
  }

  function kindOf(el) {
    if (el.id === 'set-extra') return 'house';
    if (el.querySelector && el.querySelector('#set-his')) return 'name';
    if (el.querySelector && el.querySelector('#set-ai-provider')) return 'api';
    return 'other';
  }

  function build(body) {
    if (body.querySelector('.st-tabs')) return;

    const sheets = Array.prototype.slice.call(body.children).filter(function (el) {
      return el.classList && el.classList.contains('sheet');
    });
    if (!sheets.length) return;

    const tabs = D.createElement('div');
    tabs.className = 'st-tabs';

    const wrap = D.createElement('div');
    wrap.className = 'st-body';

    TABS.forEach(function (p) {
      const b = D.createElement('button');
      b.type = 'button';
      b.className = 'st-tab';
      b.setAttribute('data-st', p[0]);
      b.textContent = p[1];
      tabs.appendChild(b);

      const pane = D.createElement('div');
      pane.className = 'st-pane';
      pane.setAttribute('data-st', p[0]);
      wrap.appendChild(pane);
    });

    sheets.forEach(function (s) {
      const pane = wrap.querySelector('.st-pane[data-st=' + kindOf(s) + ']');
      if (pane) pane.appendChild(s);
    });

    body.appendChild(tabs);
    body.appendChild(wrap);
  }

  function sweep(body) {
    const wrap = body.querySelector('.st-body');
    if (!wrap) return;

    Array.prototype.slice.call(body.children).forEach(function (el) {
      if (!el.classList || !el.classList.contains('sheet')) return;
      const pane = wrap.querySelector('.st-pane[data-st=' + kindOf(el) + ']');
      if (pane) pane.appendChild(el);
    });
  }

  function currentTab() {
    let v = 'name';
    try { v = localStorage.getItem(K) || 'name'; } catch (e) { v = 'name'; }
    return v;
  }

  function mark(body) {
    const cur = currentTab();

    Array.prototype.forEach.call(body.querySelectorAll('.st-tab'), function (b) {
      b.classList.toggle('on', b.getAttribute('data-st') === cur);
    });

    Array.prototype.forEach.call(body.querySelectorAll('.st-pane'), function (p) {
      p.classList.toggle('on', p.getAttribute('data-st') === cur);
    });
  }

  function tick() {
    const body = bodyEl();
    if (!body) return;

    build(body);
    sweep(body);
    mark(body);
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    const b = t.closest('.st-tab');
    if (!b) return;

    try { localStorage.setItem(K, b.getAttribute('data-st')); } catch (err) {}

    const body = bodyEl();
    if (body) {
      mark(body);
      const sc = body.closest('.app-body') || body;
      if (sc) sc.scrollTop = 0;
    }
  }, false);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; tick(); }, 80);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  tick();
  setTimeout(tick, 400);
  setTimeout(tick, 900);
})();
