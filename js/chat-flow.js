/* chat-flow.js · 聊天页：按天分隔、进门提示上次说到哪、老消息先折起来 */
(function () {
  const D = document;
  const WEEK = ['\u661f\u671f\u65e5', '\u661f\u671f\u4e00', '\u661f\u671f\u4e8c', '\u661f\u671f\u4e09', '\u661f\u671f\u56db', '\u661f\u671f\u4e94', '\u661f\u671f\u516d'];
  const KEEP = 80;
  const FOLD_AT = 130;

  function p2(n) { return String(n).padStart(2, '0'); }
  function ymd(d) { return d.getFullYear() + '-' + p2(d.getMonth() + 1) + '-' + p2(d.getDate()); }

  function dayLabel(dk) {
    const now = new Date();
    const today = ymd(now);
    const y = new Date(now.getTime() - 86400000);

    if (dk === today) return '\u4eca\u5929';
    if (dk === ymd(y)) return '\u6628\u5929';

    const d = new Date(dk + 'T12:00:00');
    return dk + ' \u00b7 ' + WEEK[d.getDay()];
  }

  function divs(scroller) {
    const rows = Array.prototype.slice.call(scroller.querySelectorAll('.msg-row'));
    if (!rows.length) return;

    const have = {};
    Array.prototype.forEach.call(scroller.querySelectorAll('.cf-day'), function (e) {
      have[e.getAttribute('data-dk')] = true;
    });

    let last = '';

    rows.forEach(function (row) {
      const i = Number(row.getAttribute('data-i'));
      const m = (XW.S.chat || [])[i];
      if (!m || !m.t) return;

      const dk = ymd(new Date(m.t));
      if (dk === last) return;
      last = dk;

      if (have[dk]) return;

      const d = D.createElement('div');
      d.className = 'cf-day';
      d.setAttribute('data-dk', dk);
      d.textContent = dayLabel(dk);
      row.parentNode.insertBefore(d, row);
    });
  }

  function fold(scroller) {
    if (scroller.querySelector('.cf-more')) return;

    const rows = Array.prototype.slice.call(scroller.querySelectorAll('.msg-row'));
    if (rows.length < FOLD_AT) return;

    const cut = rows.length - KEEP;
    const old = rows.slice(0, cut);

    old.forEach(function (r) { r.classList.add('cf-folded'); });

    const btn = D.createElement('button');
    btn.type = 'button';
    btn.className = 'cf-more';
    btn.textContent = '\u5f80\u4e0a\u8fd8\u6709 ' + cut + ' \u6761\uff0c\u70b9\u5f00\u770b';
    btn.addEventListener('click', function () {
      Array.prototype.forEach.call(scroller.querySelectorAll('.cf-folded'), function (r) {
        r.classList.remove('cf-folded');
      });
      btn.remove();
    }, false);

    old[0].parentNode.insertBefore(btn, old[0]);
  }

  function fmtGap(t, gap) {
    const d = new Date(t);
    const hm = p2(d.getHours()) + ':' + p2(d.getMinutes());
    const h = Math.floor(gap / 3600000);

    let ago = '';
    if (h < 1) ago = '\u521a\u624d';
    else if (h < 24) ago = h + ' \u5c0f\u65f6\u524d';
    else ago = Math.floor(h / 24) + ' \u5929\u524d';

    return '\u4e0a\u6b21\u8bf4\u5230 ' + hm + '\uff0c' + ago;
  }

  let lastGreet = 0;

  function greet() {
    if (Date.now() - lastGreet < 60000) return;

    const arr = XW.S.chat || [];
    let hit = null;

    for (let i = arr.length - 1; i >= 0; i--) {
      const m = arr[i];
      if (m && m.t && m.who !== 'sys' && !m._typing) { hit = m; break; }
    }

    if (!hit) return;

    const gap = Date.now() - Number(hit.t);
    if (gap < 30 * 60 * 1000) return;

    lastGreet = Date.now();

    const bar = D.createElement('div');
    bar.className = 'cf-greet';
    bar.textContent = fmtGap(Number(hit.t), gap);
    D.body.appendChild(bar);

    setTimeout(function () { bar.classList.add('out'); }, 3600);
    setTimeout(function () { bar.remove(); }, 4300);
  }

  let timer = null;

  function tick() {
    const scroller = D.getElementById('chat-scroll');
    if (!scroller) return;

    divs(scroller);
    fold(scroller);
    greet();
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      tick();
    }, 260);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  tick();
  setTimeout(tick, 500);
  setTimeout(tick, 1200);
})();
