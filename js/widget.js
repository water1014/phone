/* widget.js · 桌面小组件：三格 / 月历 / 天气 / 摘句（都可点） */
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

  function statCell(num, label, app) {
    return '<button type="button" class="stat" data-app="' + app + '">' +
        '<b>' + num + '</b>' +
        '<span>' + label + '</span>' +
      '</button>';
  }

  function statsHtml() {
    const diary = (Array.isArray(XW.S.diary) ? XW.S.diary : []).length;
    const photos = (Array.isArray(XW.S.photos) ? XW.S.photos : []).length;
    const chat = (Array.isArray(XW.S.chat) ? XW.S.chat : []).filter(function (m) {
      return m.who !== 'sys';
    }).length;

    return '<section class="wdg wdg-stats">' +
        statCell(diary, '日记', 'diary') +
        statCell(photos, '相片', 'album') +
        statCell(chat, '对话', 'chat') +
      '</section>';
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
      cells += '<button type="button" class="' + cls + '" data-day="' + key + '"><i>' + day + '</i></button>';
    }

    return '<section class="wdg wdg-cal">' +
        '<div class="cal-head">' +
          '<span class="kicker">CALENDAR</span>' +
          '<span class="cal-ym">' + (month + 1) + '月</span>' +
        '</div>' +
        '<div class="cal-grid">' + head + cells + '</div>' +
      '</section>';
  }

  function weatherHtml() {
    return '<section class="wdg wdg-weather" data-app="weather" role="button" tabindex="0">' +
        '<div class="quote-head">' +
          '<span class="kicker">WEATHER</span>' +
          '<span class="quote-date" id="ww-sub">看一眼天</span>' +
        '</div>' +
        '<div class="ww-body">' +
          '<span class="ww-temp" id="ww-temp">--</span>' +
          '<span class="ww-text" id="ww-text"></span>' +
        '</div>' +
      '</section>';
  }

  function wmo(code) {
    if (code === 0) return '晴';
    if (code <= 2) return '少云';
    if (code === 3) return '阴';
    if (code === 45 || code === 48) return '雾';
    if (code >= 51 && code <= 57) return '毛毛雨';
    if (code >= 61 && code <= 67) return '雨';
    if (code >= 71 && code <= 77) return '雪';
    if (code >= 80 && code <= 82) return '阵雨';
    if (code >= 85 && code <= 86) return '阵雪';
    if (code >= 95) return '雷雨';
    return '—';
  }

  function loadWeather() {
    const tempEl = D.getElementById('ww-temp');
    const textEl = D.getElementById('ww-text');
    const subEl = D.getElementById('ww-sub');
    if (!tempEl || !textEl) return;

    const url = 'https://api.open-meteo.com/v1/forecast?latitude=26.88&longitude=112.67' +
      '&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Asia%2FShanghai';

    fetch(url).then(function (res) { return res.json(); }).then(function (data) {
      const cur = data && data.current;
      if (!cur || cur.temperature_2m === undefined) throw new Error('no data');
      tempEl.textContent = Math.round(cur.temperature_2m) + '°';
      textEl.textContent = wmo(cur.weather_code);
      if (subEl) subEl.textContent = '湿度 ' + Math.round(cur.relative_humidity_2m) + '%';
    }).catch(function () {
      tempEl.textContent = '—';
      textEl.textContent = '没接到天气';
      if (subEl) subEl.textContent = '';
    });
  }

  function quoteHtml() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary : [];
    const last = list.length ? list[list.length - 1] : null;
    const line = last ? String(last.text || '').split(/\n/)[0].slice(0, 48) : '';

    if (!line) {
      return '<section class="wdg wdg-quote" data-app="diary" role="button" tabindex="0">' +
          '<div class="quote-head"><span class="kicker">TODAY</span><span class="quote-date">去写</span></div>' +
          '<p class="quote-text">还没写下什么。今天也可以就这么过。</p>' +
        '</section>';
    }

    return '<section class="wdg wdg-quote" data-app="diary" role="button" tabindex="0">' +
        '<div class="quote-head">' +
          '<span class="kicker">NOTE</span>' +
          '<span class="quote-date">' + esc(String(last.date || '').slice(5)) + '</span>' +
        '</div>' +
        '<p class="quote-text">' + esc(line) + '</p>' +
      '</section>';
  }

  function bindCalendar(page) {
    Array.prototype.forEach.call(page.querySelectorAll('.cal-d[data-day]'), function (btn) {
      btn.addEventListener('click', function () {
        const day = btn.dataset.day;
        if (window.Pages && window.Pages.calendarFocus) window.Pages.calendarFocus(day);
        window.Router.open('calendar');
      });
    });
  }

  function mount() {
    const page = D.querySelector('#desk-pages .page');
    if (!page) return;
    if (page.querySelector('.wdg-cal')) return;

    const grid = page.querySelector('.grid');
    if (!grid) return;
    grid.insertAdjacentHTML('beforebegin', calendarHtml() + weatherHtml() + quoteHtml());

    const days = page.querySelector('.wdg-days');
    if (days && !page.querySelector('.wdg-stats')) {
      days.insertAdjacentHTML('afterend', statsHtml());
    }

    bindCalendar(page);
    loadWeather();
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
