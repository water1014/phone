/* usage-card.js · 设置里的一块本地记账
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
      ? '入 ' + k(s.i) + ' · 出 ' + k(s.o) + ' · 命中 ' + k(s.c) + '·' + ratio + '% · ' + s.n + ' 轮'
      : '还没有';
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
    head.textContent = '用量';
    box.appendChild(head);

    box.appendChild(line('今天', sum(keys(1))));
    box.appendChild(line('七天', sum(keys(7))));
    box.appendChild(line('累计', sum(Object.keys(log()))));

    box.appendChild(chart());

    const note = D.createElement('div');
    note.className = 'uc-note';
    note.textContent = '订阅的月额度在这儿看不到，要去 Operit 的 OpenCode 那边看。这里只是这个网页自己花的账。';
    box.appendChild(note);
  }

  let timer = null;

  function render() {
    const anchor = D.getElementById('set-ai-model');
    if (!anchor) return;
    const sheet = anchor.closest('.sheet');
    if (!sheet) return;

    const old = sheet.querySelector('.uc-card');
    if (old) { paint(old); return; }

    const box = D.createElement('div');
    box.className = 'uc-card';
    paint(box);

    const ap = sheet.querySelector('.ap-block');
    if (ap && ap.parentNode === sheet) {
      sheet.insertBefore(box, ap.nextSibling);
    } else {
      sheet.appendChild(box);
    }
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 140);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  setTimeout(render, 800);
})();
