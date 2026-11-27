/* xw-chat.js · 给聊天页挂独立命名空间；思考与缓存率并作一行 */
(function () {
  const D = document;
  const GAP = 5 * 60 * 1000;

  (function () {
    if (D.getElementById('xw-chat-css')) return;
    const l = D.createElement('link');
    l.id = 'xw-chat-css';
    l.rel = 'stylesheet';
    l.href = 'css/xw-chat.css?v=2';
    D.head.appendChild(l);
  })();

  function p2(n) { return String(n).padStart(2, '0'); }

  function stamp(ts) {
    const d = new Date(Number(ts) || Date.now());
    return (d.getMonth() + 1) + '/' + p2(d.getDate()) + ' '
      + p2(d.getHours()) + ':' + p2(d.getMinutes()) + ':' + p2(d.getSeconds());
  }

  function ava() {
    try { return localStorage.getItem('xw_ava_his') || ''; } catch (e) { return ''; }
  }

  function face(row) {
    const av = row.querySelector('.msg-ava');
    if (!av) return;
    const src = ava();
    const img = av.querySelector('img');
    if (src && src.indexOf(' ') < 0) {
      if (!img) {
        av.textContent = '';
        const n = D.createElement('img');
        n.src = src;
        n.alt = '';
        av.appendChild(n);
      } else if (img.getAttribute('src') !== src) {
        img.src = src;
      }
      return;
    }
    if (img) img.remove();
    if (!av.textContent.trim()) {
      const name = String(XW.S.hisName || '\u4ed6').trim() || '\u4ed6';
      av.textContent = name.charAt(0);
    }
  }

  function timeLine(row) {
    if (!row.classList.contains('ta')) return;
    const main = row.querySelector('.msg-main');
    if (!main) return;
    const prefs = XW.S.chatPrefs || {};
    if (prefs.showTime === false) {
      const existing = row.querySelector('.cc-time');
      if (existing) existing.remove();
      return;
    }

    const i = Number(row.getAttribute('data-i'));
    const list = Array.isArray(XW.S.chat) ? XW.S.chat : [];
    const m = list[i];
    let line = row.querySelector('.cc-time');

    const cur = m && m.t ? Number(m.t) : 0;
    const prev = i > 0 ? list[i - 1] : null;
    const old = prev && prev.t ? Number(prev.t) : 0;
    const far = !!cur && (!old || cur - old > GAP);

    if (!far) {
      if (line) line.remove();
      return;
    }

    if (!line) {
      line = D.createElement('div');
      line.className = 'cc-time';
      const dot = D.createElement('span');
      dot.className = 'cc-dot';
      line.appendChild(dot);
      const s = D.createElement('span');
      s.className = 'cc-stamp';
      line.appendChild(s);
    }

    if (main.firstChild !== line) main.insertBefore(line, main.firstChild);
    const s = line.querySelector('.cc-stamp');
    const text = stamp(cur);
    if (s && s.textContent !== text) s.textContent = text;
  }

  function head(row) {
    const main = row.querySelector('.msg-main');
    if (!main) return;

    const i = Number(row.getAttribute('data-i'));
    const m = (Array.isArray(XW.S.chat) ? XW.S.chat : [])[i];
    const u = m && m.usage;

    const tag = main.querySelector('.msg-tag');
    const sum = main.querySelector('details.think > summary');
    if (!tag && !sum) return;

    if (!u) {
      if (tag) tag.style.display = 'none';
      return;
    }

    const input = Number(u.input) || 0;
    const cached = Number(u.cached) || 0;
    const pct = input > 0 ? Math.round(cached / input * 100) : 0;
    const label = '\u7f13\u5b58 ' + pct + '%';

    if (sum) {
      const txt = '\u601d\u8003 \u00B7 ' + label;
      if (sum.textContent !== txt) sum.textContent = txt;
      if (tag) tag.style.display = 'none';
      return;
    }

    if (!tag) return;
    tag.style.display = '';
    if (tag.textContent !== label) tag.textContent = label;
  }

  function work() {
    const sc = D.getElementById('chat-scroll');
    if (!sc) return;
    Array.prototype.forEach.call(sc.querySelectorAll('.msg-row[data-i]'), function (row) {
      face(row);
      timeLine(row);
      head(row);
    });
  }

  function tick() {
    const app = D.getElementById('app');
    const wrap = D.querySelector('#app-body .chat-wrap');
    const settings = D.querySelector('#app-body .chat-settings-page');
    const isChat = !!(app && app.classList.contains('show') && (wrap || settings));

    if (isChat) {
      if (!D.body.classList.contains('xw-chat-on')) D.body.classList.add('xw-chat-on');
      work();
    } else if (D.body.classList.contains('xw-chat-on')) {
      D.body.classList.remove('xw-chat-on');
    }
  }

  let timer = null;
  function later() {
    if (timer) return;
    timer = setTimeout(function () { timer = null; tick(); }, 80);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }
  D.addEventListener('click', later, true);

  tick();
  setTimeout(tick, 300);
  setTimeout(tick, 900);
  setTimeout(tick, 2000);
})();
