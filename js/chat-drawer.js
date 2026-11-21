/* chat-drawer.js · 聊天设置改成右侧栏
   顶上多一块：日历（按天跳）+ 找聊天记录 */
(function () {
  const D = document;

  let month = null;

  function ymd(d) {
    return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
  }

  function dayMap() {
    const map = {};
    (XW.S.chat || []).forEach(function (m) {
      if (!m || !m.t || m.who === 'sys') return;
      const k = ymd(new Date(m.t));
      map[k] = (map[k] || 0) + 1;
    });
    return map;
  }

  function close() {
    const p = D.getElementById('cset');
    if (p) p.classList.remove('on');
    const m = D.getElementById('xv-mask');
    if (m) m.remove();
  }

  function mask() {
    if (D.getElementById('xv-mask')) return;
    const m = D.createElement('div');
    m.id = 'xv-mask';
    m.className = 'xv-mask';
    m.addEventListener('click', close);
    D.body.appendChild(m);
  }

  function goTo(i) {
    close();
    setTimeout(function () {
      const row = D.querySelector('#chat-scroll .msg-row[data-i="' + i + '"]');
      if (row && row.scrollIntoView) row.scrollIntoView({ block: 'center', behavior: 'smooth' });
    }, 70);
  }

  function jumpDay(k) {
    const list = XW.S.chat || [];
    for (let i = 0; i < list.length; i++) {
      const m = list[i];
      if (!m || !m.t) continue;
      if (ymd(new Date(m.t)) === k) { goTo(i); return; }
    }
  }

  function arrow(txt, fn) {
    const b = D.createElement('button');
    b.type = 'button';
    b.className = 'xv-ar';
    b.textContent = txt;
    b.addEventListener('click', fn);
    return b;
  }

  function drawCal(box) {
    box.textContent = '';

    const now = new Date();
    if (!month) month = { y: now.getFullYear(), m: now.getMonth() };

    const head = D.createElement('div');
    head.className = 'xv-cal-head';

    const lab = D.createElement('span');
    lab.textContent = month.y + ' 年 ' + (month.m + 1) + ' 月';

    head.appendChild(arrow('\u2039', function () {
      month.m -= 1;
      if (month.m < 0) { month.m = 11; month.y -= 1; }
      drawCal(box);
    }));
    head.appendChild(lab);
    head.appendChild(arrow('\u203a', function () {
      month.m += 1;
      if (month.m > 11) { month.m = 0; month.y += 1; }
      drawCal(box);
    }));

    box.appendChild(head);

    const week = D.createElement('div');
    week.className = 'xv-cal-week';
    ['\u65e5', '\u4e00', '\u4e8c', '\u4e09', '\u56db', '\u4e94', '\u516d'].forEach(function (w) {
      const s = D.createElement('span');
      s.textContent = w;
      week.appendChild(s);
    });
    box.appendChild(week);

    const grid = D.createElement('div');
    grid.className = 'xv-cal-grid';

    const first = new Date(month.y, month.m, 1).getDay();
    const days = new Date(month.y, month.m + 1, 0).getDate();
    const map = dayMap();

    for (let i = 0; i < first; i++) grid.appendChild(D.createElement('span'));

    for (let d = 1; d <= days; d++) {
      const k = month.y + '-' + (month.m + 1) + '-' + d;
      const cell = D.createElement('button');
      cell.type = 'button';
      cell.className = 'xv-cal-d';
      cell.textContent = String(d);
      if (map[k]) cell.classList.add('has');
      if (now.getFullYear() === month.y && now.getMonth() === month.m && now.getDate() === d) {
        cell.classList.add('now');
      }
      (function (kk) {
        cell.addEventListener('click', function () { jumpDay(kk); });
      })(k);
      grid.appendChild(cell);
    }

    box.appendChild(grid);
  }

  function searchBlock() {
    const box = D.createElement('div');
    box.className = 'xv-search';

    const input = D.createElement('input');
    input.type = 'search';
    input.placeholder = '\u627e\u4e00\u53e5\u8bdd\u2026';
    box.appendChild(input);

    const hits = D.createElement('div');
    hits.className = 'xv-hits';
    box.appendChild(hits);

    const hint = D.createElement('div');
    hint.className = 'xv-hint';
    box.appendChild(hint);

    input.addEventListener('input', function () {
      const q = String(input.value || '').trim().toLowerCase();
      hits.textContent = '';
      if (!q) { hint.textContent = ''; return; }

      const list = XW.S.chat || [];
      const found = [];

      list.forEach(function (m, i) {
        if (!m || !m.text) return;
        if (String(m.text).toLowerCase().indexOf(q) < 0) return;
        found.push({ i: i, m: m });
      });

      hint.textContent = found.length ? '\u547d\u4e2d ' + found.length + ' \u6761' : '\u6ca1\u6709';

      found.slice(0, 30).forEach(function (it) {
        const b = D.createElement('button');
        b.type = 'button';
        b.className = 'xv-hit';
        const who = it.m.who === 'me' ? (XW.S.herName || '\u6211') : (XW.S.hisName || '\u4ed6');
        b.textContent = who + '\uff1a' + String(it.m.text).slice(0, 60);
        b.addEventListener('click', function () { goTo(it.i); });
        hits.appendChild(b);
      });
    });

    return box;
  }

  function top() {
    const wrap = D.createElement('div');
    wrap.className = 'xv-top';

    const head = D.createElement('div');
    head.className = 'xv-title';

    const b = D.createElement('b');
    b.textContent = '\u804a\u5929';
    head.appendChild(b);

    const x = D.createElement('button');
    x.type = 'button';
    x.className = 'xv-x';
    x.textContent = '\u2715';
    x.addEventListener('click', close);
    head.appendChild(x);

    wrap.appendChild(head);

    const cal = D.createElement('div');
    cal.className = 'xv-cal';
    drawCal(cal);
    wrap.appendChild(cal);

    wrap.appendChild(searchBlock());

    const sep = D.createElement('div');
    sep.className = 'xv-sep';
    wrap.appendChild(sep);

    return wrap;
  }

  function build() {
    const p = D.getElementById('cset');
    if (!p || p.querySelector('.xv-top')) return;
    p.insertBefore(top(), p.firstChild);
  }

  function refresh() {
    const p = D.getElementById('cset');
    if (!p) return;
    if (!p.classList.contains('on')) {
      const m = D.getElementById('xv-mask');
      if (m) m.remove();
      return;
    }
    mask();
    build();
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;
    if (t.closest('#cs-more')) {
      setTimeout(refresh, 40);
      setTimeout(refresh, 220);
    }
  }, true);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      refresh();
    }, 140);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }
})();
