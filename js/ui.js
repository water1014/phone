/* ui.js · 小工具：提示 / 日期 / 问候 / 图标 */
(function () {
  const D = document;

  let toastEl = null;
  let toastTimer = 0;

  function toast(message, duration) {
    if (!toastEl) {
      toastEl = D.createElement('div');
      toastEl.id = 'toast';
      D.body.appendChild(toastEl);
    }
    toastEl.textContent = String(message || '');
    toastEl.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove('show'); }, duration || 2000);
  }

  /* 归零到 0 点再取整，避开时区和小数误差 */
  function diffDay(from, to) {
    const a = new Date(from); a.setHours(0, 0, 0, 0);
    const b = new Date(to); b.setHours(0, 0, 0, 0);
    return Math.round((b - a) / 86400000);
  }

  function greetWord(hour) {
    if (hour < 5) return '夜深了';
    if (hour < 7) return '清晨';
    if (hour < 11) return '早安';
    if (hour < 13) return '午安';
    if (hour < 17) return '下午好';
    if (hour < 21) return '傍晚好';
    return '晚安';
  }

  const WEEK = ['日', '一', '二', '三', '四', '五', '六'];

  function fmtWeek(date) {
    return '星期' + WEEK[date.getDay()];
  }

  function fmtClock(date) {
    const d = date || new Date();
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  function fmtMonthDay(date) {
    return (date.getMonth() + 1) + '月' + date.getDate() + '日';
  }

  function fmtYmd(date) {
    return date.getFullYear() + '.' + String(date.getMonth() + 1).padStart(2, '0') + '.' + String(date.getDate()).padStart(2, '0');
  }

  function icon(paths) {
    const body = (paths || []).map(function (d) { return '<path d="' + d + '"/>'; }).join('');
    return '<svg viewBox="0 0 24 24" aria-hidden="true">' + body + '</svg>';
  }

  const ESC_MAP = { '&': '&amp;', '<': '&lt;', '>': '&gt;' };

  function esc(value) {
    return String(value == null ? '' : value).replace(/[&<>]/g, function (ch) { return ESC_MAP[ch]; });
  }

  window.UI = {
    toast: toast,
    diffDay: diffDay,
    greetWord: greetWord,
    fmtWeek: fmtWeek,
    fmtClock: fmtClock,
    fmtMonthDay: fmtMonthDay,
    fmtYmd: fmtYmd,
    icon: icon,
    esc: esc
  };
})();
