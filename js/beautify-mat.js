/* beautify-mat.js · 单个组件的材质
   在 beautify.js 后面加载；往「材质」页补一组选择器
   状态单独存 xw_mat，不动 xw_look */
(function () {
  const D = document;
  const K = 'xw_mat';

  const KEYS = [
    { k: 'clg', cn: '照片墙', en: 'COLLAGE' },
    { k: 'days', cn: '天数卡', en: 'DAYS' },
    { k: 'pf', cn: '个人信息卡', en: 'PROFILE' },
    { k: 'mod', cn: '自制小组件', en: 'WIDGET' }
  ];

  const SEL = {
    clg: '#home .clg',
    days: '#home .dc-face',
    pf: '.pf-front',
    mod: '#home .mod'
  };

  const MATS = ['m-flat', 'm-frost', 'm-glass', 'm-liquid'];

  const OPTS = [
    { v: 'none', n: '随' },
    { v: 'flat', n: '素' },
    { v: 'frost', n: '砂' },
    { v: 'glass', n: '玻' },
    { v: 'liquid', n: '液' }
  ];

  let st = {};

  try { st = JSON.parse(localStorage.getItem(K) || '{}') || {}; }
  catch (e) { st = {}; }

  KEYS.forEach(function (o) { if (!st[o.k]) st[o.k] = 'none'; });

  function save() {
    try { localStorage.setItem(K, JSON.stringify(st)); } catch (e) {}
  }

  function paint() {
    KEYS.forEach(function (o) {
      const v = st[o.k];
      const nodes = D.querySelectorAll(SEL[o.k]);

      for (let i = 0; i < nodes.length; i++) {
        const el = nodes[i];
        for (let j = 0; j < MATS.length; j++) el.classList.remove(MATS[j]);
        if (v && v !== 'none') el.classList.add('m-' + v);
      }
    });
  }

  function row(o) {
    return '<div class="bz-sec">' +
        '<div class="bz-lab"><b>' + o.cn + '</b><i>' + o.en + '</i></div>' +
        '<div class="bz-opts">' +
          OPTS.map(function (p) {
            return '<button type="button" class="bz-opt' +
              (st[o.k] === p.v ? ' on' : '') + '"' +
              ' data-mat-c="' + o.k + '" data-mat-v="' + p.v + '">' + p.n + '</button>';
          }).join('') +
        '</div></div>';
  }

  function inject() {
    const pane = D.querySelector('.bz-pane[data-pane="mat"]');
    if (!pane || pane.querySelector('.bz-mat-own')) return;

    const box = D.createElement('div');
    box.className = 'bz-mat-own';
    box.innerHTML =
      '<div class="bz-lab" style="margin:22px 0 0"><b>单个组件</b><i>EACH</i></div>' +
      KEYS.map(row).join('') +
      '<div class="sheet-note">「随」就是跟着上面那一套走。只挑一件换，别的都不动。</div>';

    pane.appendChild(box);
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    const b = t.closest('[data-mat-c]');
    if (!b) return;

    const k = b.getAttribute('data-mat-c');
    const v = b.getAttribute('data-mat-v');
    if (!k || !v) return;

    st[k] = v;
    save();
    paint();

    const sibs = b.parentNode.querySelectorAll('[data-mat-c]');
    for (let i = 0; i < sibs.length; i++) {
      sibs[i].classList.toggle('on', sibs[i] === b);
    }
  }, false);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      paint();
      inject();
    }, 80);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  paint();
  inject();
  setTimeout(function () { paint(); inject(); }, 500);

  window.Beautify = window.Beautify || {};
  window.Beautify.matOwn = { state: function () { return st; }, paint: paint };
})();
