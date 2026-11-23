/* usage-card.js · 本地记账
   ① App 设置（接口那块）  ② 聊天设置 → 记录
   真实配额看不到，这里只记这个家自己花掉的 */
(function () {
  const D = document;

  function p2(n) { return String(n).padStart(2, '0'); }

  function ymd(d) {
    return d.getFullYear() + '-' + p2(d.getMonth() + 1) + '-' + p2(d.getDate());
  }

  function log() {
    return (XW.S.usageLog && typeof XW.S.usageLog === 'object') ? XW.S.usageLog : {};
  }

  function k(n) {
    const v = Number(n) || 0;
    if (v < 1000) return String(v);
    if (v < 1000000) return (v / 1000).toFixed(1).replace(/\.0$/, '') + 'k';
    return (v / 1000000).toFixed(2).replace(/\.00$/, '') + 'M';
  }

  function sum(days) {
    const all = log();
    const out = { i: 0, o: 0, c: 0, n: 0 };
    days.forEach(function (key) {
      const v = all[key];
      if (!v) return;
      out.i += Number(v.i) || 0;
      out.o += Number(v.o) || 0;
      out.c += Number(v.c) || 0;
      out.n += Number(v.n) || 0;
    });
    return out;
  }

  function keys(back) {
    const list = [];
    for (let i = 0; i < back; i++) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      list.push(ymd(d));
    }
    return list;
  }

  function line(label, s) {
    const row = D.createElement('div');
    row.className = 'uc-row';

    const a = D.createElement('span');
    a.className = 'uc-k';
    a.textContent = label;
    row.appendChild(a);

    const b = D.createElement('span');
    b.className = 'uc-v';
    const ratio = s.i ? Math.round(s.c / s.i * 100) : 0;
    b.textContent = s.n
      ? '\u5165 ' + k(s.i) + ' \u00b7 \u51fa ' + k(s.o) + ' \u00b7 \u547d\u4e2d ' + ratio + '% \u00b7 ' + s.n + ' \u8f6e'
      : '\u8fd8\u6ca1\u6709';
    row.appendChild(b);

    return row;
  }

  function chart() {
    const all = log();
    const week = keys(7).reverse();
    const vals = week.map(function (key) {
      const v = all[key];
      return v ? (Number(v.i) || 0) + (Number(v.o) || 0) : 0;
    });

    let max = 1;
    vals.forEach(function (v) { if (v > max) max = v; });

    const box = D.createElement('div');
    box.className = 'uc-chart';

    week.forEach(function (key, i) {
      const col = D.createElement('div');
      col.className = 'uc-col';

      const bar = D.createElement('div');
      bar.className = 'uc-bar';
      bar.style.height = Math.max(3, Math.round(vals[i] / max * 46)) + 'px';
      if (!vals[i]) bar.style.opacity = '.22';
      col.appendChild(bar);

      const tip = D.createElement('i');
      tip.className = 'uc-tip';
      tip.textContent = key.slice(8) + (vals[i] ? ' ' + k(vals[i]) : '');
      col.appendChild(tip);

      box.appendChild(col);
    });

    return box;
  }

  function paint(box) {
    box.textContent = '';

    const head = D.createElement('div');
    head.className = 'uc-head';
    head.textContent = '\u7528\u91cf\u00b7\u672c\u5730\u8bb0\u7684';
    box.appendChild(head);

    box.appendChild(line('\u4eca\u5929', sum(keys(1))));
    box.appendChild(line('\u4e03\u5929', sum(keys(7))));

    const t = XW.S.usage || {};
    box.appendChild(line('\u5168\u90e8', {
      i: t.input,
      o: t.output,
      c: t.cached,
      n: t.rounds
    }));

    box.appendChild(chart());

    const note = D.createElement('div');
    note.className = 'uc-note';
    note.textContent = '\u8ba2\u9605\u7684\u6708\u989d\u5ea6\u5728\u8fd9\u513f\u770b\u4e0d\u5230\uff0c\u8981\u53bb OpenCode \u90a3\u8fb9\u770b\u3002\u4eca\u5929\u548c\u4e03\u5929\u662f\u4ece\u8fd9\u4e00\u7248\u5f00\u59cb\u8bb0\u7684\uff0c\u4e4b\u524d\u7684\u53ea\u8fdb\u4e86\u300c\u5168\u90e8\u300d\u3002';
    box.appendChild(note);
  }

  function mount(host) {
    if (!host) return;
    let card = host.querySelector('.uc-card');
    if (!card) {
      card = D.createElement('div');
      card.className = 'uc-card';
      host.appendChild(card);
    }
    paint(card);
  }

  function render() {
    mount(D.querySelector('.api-sheet'));

    const pane = D.querySelector('#cset .cset-pane[data-cp="more"]');
    if (!pane) return;

    let slot = pane.querySelector('.uc-slot');
    if (!slot) {
      slot = D.createElement('div');
      slot.className = 'uc-slot';
      pane.insertBefore(slot, pane.firstChild);
    }

    mount(slot);
  }

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 180);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  setTimeout(render, 900);
  setTimeout(render, 1500);
})();
