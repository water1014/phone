/* widget.js · 桌面组件块 */
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

  function clockHtml() {
    return '<section class="wdg-clock">' +
        '<div class="dclock" id="desk-clock">--:--</div>' +
        '<div class="ddate" id="desk-date"></div>' +
      '</section>';
  }

  function daysHtml() {
    const love = new Date(XW.S.loveDate || '2025-01-01');
    const days = UI.diffDay(love, new Date());
    return '<section class="wdg wdg-days">' +
        '<div class="days-top">' +
          '<span class="kicker">TOGETHER</span>' +
          '<span class="days-since">SINCE ' + UI.fmtYmd(love) + '</span>' +
        '</div>' +
        '<div class="days-num">' + days + '<small>DAYS</small></div>' +
        '<div class="days-rule"></div>' +
        '<div class="wdg-names">' + UI.esc(XW.S.hisName) + ' &amp; ' + UI.esc(XW.S.herName) + '</div>' +
      '</section>';
  }

  /* 三格：三个真数字 */
  function trioHtml() {
    function cell(appId, num, label) {
      return '<button type="button" data-app="' + appId + '">' +
          '<b>' + num + '</b>' +
          '<i>' + label + '</i>' +
        '</button>';
    }

    const diary = (Array.isArray(XW.S.diary) ? XW.S.diary : []).length;
    const photos = (Array.isArray(XW.S.photos) ? XW.S.photos : []).length;
    const notes = (Array.isArray(XW.S.notes) ? XW.S.notes : []).length;

    return '<section class="trio">' +
        cell('diary', diary, 'DIARY') +
        cell('album', photos, 'ALBUM') +
        cell('memory', notes, 'MEMORY') +
      '</section>';
  }

  function weatherCardHtml() {
    return '<section class="wdg wdg-wx" data-app="weather" role="button" tabindex="0">' +
        '<span class="kicker">WEATHER</span>' +
        '<div class="wx-big" id="wx-temp">—</div>' +
        '<div class="wx-sub" id="wx-sub">没接到天气</div>' +
      '</section>';
  }

  function quotaHtml() {
    const usage = XW.S.usage || { input: 0 };
    const limit = Number(XW.S.ctxLimit) || 128000;
    const used = Number(usage.input) || 0;
    const pct = Math.min(999, Math.round(used / limit * 100));
    const kw = (used / 1000).toFixed(1);
    const lw = Math.round(limit / 1000);

    return '<section class="wdg wdg-quota" data-app="chat" role="button" tabindex="0">' +
        '<span class="kicker">QUOTA</span>' +
        '<div class="q-big">' + pct + '<small>%</small></div>' +
        '<div class="q-bar"><i style="width:' + Math.min(100, pct) + '%"></i></div>' +
        '<div class="wx-sub">' + kw + 'k / ' + lw + 'k</div>' +
      '</section>';
  }

  function rowItem(appId, cn, en, value) {
    const app = window.Apps.find(appId);
    const icon = app ? UI.icon(app.icon) : '';
    return '<button type="button" class="row" data-app="' + appId + '">' +
        '<span class="row-ico">' + icon + '</span>' +
        '<span class="row-main"><b>' + cn + '</b><i>' + en + '</i></span>' +
        '<span class="row-val">' + value + '</span>' +
        '<span class="row-arrow">›</span>' +
      '</button>';
  }

  function rowsHtml() {
    const now = new Date();
    const today = (now.getMonth() + 1) + '/' + now.getDate();
    const chat = (Array.isArray(XW.S.chat) ? XW.S.chat : []).length;

    return '<section class="rows">' +
        rowItem('calendar', '日历', 'CALENDAR', today) +
        rowItem('chat', '聊天', 'CONVERSATION', chat + ' 条') +
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
    const big = D.getElementById('wx-temp');
    const sub = D.getElementById('wx-sub');
    if (!big || !sub) return;

    const url = 'https://api.open-meteo.com/v1/forecast?latitude=26.88&longitude=112.67' +
      '&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Asia%2FShanghai';

    fetch(url).then(function (res) { return res.json(); }).then(function (data) {
      const cur = data && data.current;
      if (!cur || cur.temperature_2m === undefined) throw new Error('no data');
      big.textContent = Math.round(cur.temperature_2m) + '°';
      sub.textContent = wmo(cur.weather_code) + ' · 湿度 ' + cur.relative_humidity_2m + '%';
    }).catch(function () {
      big.textContent = '—';
      sub.textContent = '没接到天气';
    });
  }

  function quoteHtml() {
    const list = Array.isArray(XW.S.diary) ? XW.S.diary : [];
    const last = list.length ? list[list.length - 1] : null;
    const text = last ? String(last.text || '') : '';
    const line = text.split(/\n/)[0].slice(0, 80);

    if (!line) {
      return '<section class="wdg wdg-quote" data-app="diary" role="button" tabindex="0">' +
          '<div class="quote-head"><span class="kicker">NOTE</span><span class="quote-date">还没写</span></div>' +
          '<p class="quote-text">今天也可以就这么过。<br>想写的时候点这里。</p>' +
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

  function bindCalendar(root) {
    Array.prototype.forEach.call(root.querySelectorAll('.cal-d[data-day]'), function (btn) {
      btn.addEventListener('click', function () {
        const day = btn.dataset.day;
        if (window.Pages && window.Pages.calendarFocus) window.Pages.calendarFocus(day);
        window.Router.open('calendar');
      });
    });
  }

  window.Widgets = {
    clock: clockHtml,
    days: daysHtml,
    trio: trioHtml,
    weatherCard: weatherCardHtml,
    quota: quotaHtml,
    rows: rowsHtml,
    calendar: calendarHtml,
    quote: quoteHtml,
    after: function (root) {
      bindCalendar(root);
      loadWeather();
    }
  };
})();
