/* widget.js · 桌面小组件：月历 + 摘句 */
(function () {
  const D = document;

  function pad(n) { return (n < 10 ? '0' : '') + n; }

  function esc(text) {
    if (window.UI && UI.esc) return UI.esc(text);
    return String(text == null ? '' : text).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  function diaryMarks() {
    const marks = {};
    (Array.isArray(XW.S.diary) ? XW.S.diary : []).forEach(function (item) {
      const hit = String(item.date || '').match(/(\d{4})-(\d{2})-(\d{2})/);
      if (hit) marks[hit[1] + '-' + hit[2] + '-' + hit[3]] = true;
    });
    return marks;
  }

  function calendarHtml() {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const startDow = new Date(year, month, 1).getDay();
    const total = new Date(year, month + 1, 0).getDate();
    const marks = diaryMarks();

    const head = ['日', '一', '二', '三', '四', '五', '六'].map(function (w) {
      return '<span class="cal-dow">' + w + '</span>';
    }).join('');

    let cells = '';
    for (let i = 0; i < startDow; i++) cells += '<span class="cal-d out"></span>';
    for (let day = 1; day <= total; day++) {
      const key = year + '-' + pad(month + 1) + '-' + pad(day);
      let cls = 'cal-d';
      if (day === now.getDate()) cls += ' today';
      if (marks[key]) cls += ' has';
      cells += '<span class="' + cls + '"><i>' + day + '</i></span>';
    }

    return '<section class="wdg wdg-cal">' +
        '<div class="cal-head">' +
          '<span class="kicker">CALENDAR</span>' +
          '<span class="cal-ym">' + (month + 1) + '月</span>' +
        '</div>' +
        '<div class="cal-grid">' + head + cells + '</div>' +
      '</section>';
  }

  function quoteHtml() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary : [];
    const last = list.length ? list[list.length - 1] : null;
    const line = last ? String(last.text || '').split(/\n/)[0].slice(0, 48) : '';

    if (!line) {
      return '<section class="wdg wdg-quote">' +
          '<div class="quote-head"><span class="kicker">TODAY</span></div>' +
          '<p class="quote-text">还没写下什么。今天也可以就这么过。</p>' +
        '</section>';
    }

    return '<section class="wdg wdg-quote">' +
        '<div class="quote-head">' +
          '<span class="kicker">NOTE</span>' +
          '<span class="quote-date">' + esc(String(last.date || '').slice(5)) + '</span>' +
        '</div>' +
        '<p class="quote-text">' + esc(line) + '</p>' +
      '</section>';
  }

  function mount() {
    const page = D.querySelector('#desk-pages .page');
    if (!page) return;
    if (page.querySelector('.wdg-cal')) return;
    const grid = page.querySelector('.grid');
    if (!grid) return;
    grid.insertAdjacentHTML('beforebegin', calendarHtml() + quoteHtml());
  }

  function watch() {
    const box = D.getElementById('desk-pages');
    if (!box) return;
    mount();
    const observer = new MutationObserver(function () { mount(); });
    observer.observe(box, { childList: true, subtree: false });
  }

  if (D.readyState === 'loading') D.addEventListener('DOMContentLoaded', watch);
  else watch();
})();
