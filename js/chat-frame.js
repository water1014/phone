/* chat-frame.js · 气泡外头像 + 每条回复下面一行时间 */
(function () {
  const D = document;

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

    const i = Number(row.getAttribute('data-i'));
    const m = (XW.S.chat || [])[i];
    if (!m || !m.t) return;

    let line = row.querySelector('.cc-time');

    if (!line) {
      line = D.createElement('div');
      line.className = 'cc-time';

      const dot = D.createElement('span');
      dot.className = 'cc-dot';
      line.appendChild(dot);

      const s = D.createElement('span');
      s.className = 'cc-stamp';
      line.appendChild(s);

      const main = row.querySelector('.msg-main');
      if (!main) return;

      const tag = row.querySelector('.msg-tag');
      if (tag && tag.parentNode === main) main.insertBefore(line, tag);
      else main.appendChild(line);
    }

    const s = line.querySelector('.cc-stamp');
    const text = stamp(m.t);
    if (s && s.textContent !== text) s.textContent = text;
  }

  function tick() {
    if (!D.getElementById('chat-scroll')) return;
    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-row[data-i]'), function (row) {
      face(row);
      timeLine(row);
    });
  }

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      tick();
    }, 110);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  tick();
  setTimeout(tick, 600);
})();
