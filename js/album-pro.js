/* album-pro.js · 相册：封面 + 按月/按天分组 + 顶上一绝时间条 + 大图 */
(function () {
  const D = document;
  const P = window.Pages;
  if (!P || typeof P.album !== 'function') return;

  const WEEK = ['\u661f\u671f\u65e5', '\u661f\u671f\u4e00', '\u661f\u671f\u4e8c', '\u661f\u671f\u4e09', '\u661f\u671f\u56db', '\u661f\u671f\u4e94', '\u661f\u671f\u516d'];

  function esc(t) {
    if (window.UI && UI.esc) return UI.esc(t);
    return String(t == null ? '' : t).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  function p2(n) { return String(n).padStart(2, '0'); }
  function ymd(d) { return d.getFullYear() + '-' + p2(d.getMonth() + 1) + '-' + p2(d.getDate()); }

  function norm(p) {
    if (typeof p === 'string') return { u: p, t: 0, c: '' };
    if (p && typeof p === 'object' && p.u) {
      return { u: String(p.u), t: Number(p.t) || 0, c: String(p.c || '') };
    }
    return null;
  }

  let flat = [];
  let viewAt = -1;
  let filterDay = '';

  function collect() {
    const raw = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    flat = [];
    raw.forEach(function (p, i) {
      const n = norm(p);
      if (n) flat.push({ u: n.u, t: n.t, c: n.c, i: i });
    });
    return flat;
  }

  function daysList() {
    const m = {};
    let older = 0;

    flat.forEach(function (x) {
      if (!x.t) { older++; return; }
      const k = ymd(new Date(x.t));
      m[k] = (m[k] || 0) + 1;
    });

    const out = Object.keys(m).sort(function (a, b) { return a < b ? 1 : -1; })
      .map(function (k) { return { k: k, n: m[k], label: k.slice(5) }; });

    if (older) out.push({ k: 'older', n: older, label: '\u66f4\u65e9' });

    return out;
  }

  function groupsFrom(seq) {
    const map = {};
    seq.forEach(function (x) {
      const key = x.t ? ymd(new Date(x.t)) : '';
      (map[key] = map[key] || []).push(x);
    });

    const keys = Object.keys(map).sort(function (a, b) {
      if (a === '') return 1;
      if (b === '') return -1;
      return a < b ? 1 : -1;
    });

    return keys.map(function (k) { return { k: k, items: map[k] }; });
  }

  function album() {
    collect();
    const days = daysList();
    const cover = flat.length ? flat[flat.length - 1] : null;

    const sub = flat.length
      ? ('<span class="ap-n">' + flat.length + '</span> \u5f20' +
         (days.length > 1 ? ' \u00b7 <span class="ap-n">' + days.length + '</span> \u5929' : ''))
      : '\u8fd8\u7a7a\u7740';

    const head = '<div class="ap-head">' +
        '<div class="hero">' +
          '<span class="kicker">ALBUM</span>' +
          '<h1 class="hero-title">\u76f8\u518c</h1>' +
          '<div class="hero-sub">' + sub + '</div>' +
        '</div>' +
        '<button type="button" id="album-add" class="ap-add" aria-label="\u653e\u7167\u7247">\uff0b</button>' +
      '</div>';

    let bar = '';
    if (flat.length && days.length > 1) {
      bar = '<div class="ap-track">' +
          '<button type="button" class="ap-t' + (filterDay === '' ? ' on' : '') + '" data-fd="">\u5168\u90e8 ' +
            '<i>' + flat.length + '</i></button>' +
          days.map(function (d) {
            return '<button type="button" class="ap-t' + (filterDay === d.k ? ' on' : '') + '" data-fd="' + d.k + '">' +
              esc(d.label) + ' <i>' + d.n + '</i></button>';
          }).join('') +
        '</div>';
    }

    let body = '';

    if (!flat.length) {
      body = '<div class="empty-state ap-empty">\u8fd8\u6ca1\u6709\u7167\u7247\u3002<br>\u56fe\u653e\u8fdb\u6765\uff0c\u6211\u4e00\u5f20\u5f20\u6446\u4e0a\u3002</div>';
    } else {
      const seq = filterDay === 'older'
        ? flat.filter(function (x) { return !x.t; })
        : filterDay
          ? flat.filter(function (x) { return x.t && ymd(new Date(x.t)) === filterDay; })
          : flat.filter(function (x) { return cover ? x !== cover : true; });

      if (!filterDay && cover) {
        body += '<button type="button" class="ap-cover" data-k="' + (flat.length - 1) + '">' +
            '<img src="' + cover.u + '" alt="">' +
          '</button>' +
          '<div class="ap-cap">\u6700\u8fd1\u653e\u8fdb\u6765\u7684\u4e00\u5f20</div>';
      }

      const gs = groupsFrom(seq);
      let lastMon = '';

      if (!gs.length) {
        body += '<div class="empty-state ap-empty">\u8fd9\u4e00\u5929\u6ca1\u6709\u7167\u7247\u3002</div>';
      }

      gs.forEach(function (g) {
        if (g.k) {
          const mon = g.k.slice(0, 7);
          if (mon !== lastMon) {
            body += '<div class="ap-mon">' + mon.replace('-', ' \u00b7 ') + '</div>';
            lastMon = mon;
          }
        }

        const label = g.k
          ? (g.k + ' \u00b7 ' + g.items.length)
          : ('\u66f4\u65e9 \u00b7 ' + g.items.length);

        body += '<div class="ap-band">' + esc(label) + '</div>' +
          '<div class="ap-grid">' + g.items.map(function (x) {
            return '<button type="button" class="ap-cell" data-k="' + x.i + '">' +
              '<img src="' + x.u + '" alt="" loading="lazy">' +
            '</button>';
          }).join('') + '</div>';
      });
    }

    return head +
      '<input id="album-file" type="file" accept="image/*" multiple hidden>' +
      bar +
      body +
      '<div class="ap-note">\u7167\u7247\u5b58\u5728\u8fd9\u53f0\u624b\u673a\u7684\u6d4f\u89c8\u5668\u91cc\uff0c\u6e05\u7f13\u5b58\u4f1a\u4e22\u3002\u6362\u624b\u673a\u4e4b\u524d\u5148\u5bfc\u4e00\u4efd\u5907\u4efd\u3002</div>';
  }

  function shrink(file, maxSide, quality) {
    return new Promise(function (resolve) {
      const reader = new FileReader();
      reader.onerror = function () { resolve(''); };
      reader.onload = function () {
        const img = new Image();
        img.onerror = function () { resolve(''); };
        img.onload = function () {
          const scale = Math.min(1, maxSide / Math.max(img.width, img.height));
          const canvas = D.createElement('canvas');
          canvas.width = Math.max(1, Math.round(img.width * scale));
          canvas.height = Math.max(1, Math.round(img.height * scale));
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
          try { resolve(canvas.toDataURL('image/jpeg', quality)); }
          catch (e) { resolve(''); }
        };
        img.src = String(reader.result || '');
      };
      reader.readAsDataURL(file);
    });
  }

  async function addFiles(list) {
    const before = (Array.isArray(XW.S.photos) ? XW.S.photos : []).slice();
    const added = [];

    for (let i = 0; i < list.length; i++) {
      const f = list[i];
      if (!f) continue;
      if (f.type && !/^image\//.test(f.type)) continue;
      const u = await shrink(f, 1000, 0.82);
      if (!u) continue;
      added.push({ u: u, t: Number(f.lastModified) || Date.now(), c: '' });
    }

    if (!added.length) {
      UI.toast('\u8fd9\u51e0\u5f20\u8bfb\u4e0d\u51fa\u6765');
      return;
    }

    XW.S.photos = before.concat(added);

    let ok = true;
    try { XW.save('photos'); } catch (e) { ok = false; }

    if (!ok) {
      XW.S.photos = before;
      try { XW.save('photos'); } catch (e) {}
      UI.toast('\u5b58\u4e0d\u4e0b\u4e86\uff0c\u5148\u5220\u51e0\u5f20');
      return;
    }

    UI.toast('\u653e\u8fdb\u6765 ' + added.length + ' \u5f20');
    filterDay = '';
    window.Router.reopen('album');
  }

  function bindFiles() {
    const f = D.getElementById('album-file');
    if (!f || f.getAttribute('data-bound') === '1') return;
    f.setAttribute('data-bound', '1');
    f.addEventListener('change', function () {
      const src = f.files;
      const arr = [];
      for (let i = 0; i < (src ? src.length : 0); i++) arr.push(src[i]);
      f.value = '';
      if (!arr.length) return;
      UI.toast('\u5904\u7406\u4e2d\u2026');
      addFiles(arr);
    }, false);
  }

  function open(k) {
    close();
    const x = flat[k];
    if (!x) return;
    viewAt = k;

    const d = x.t ? new Date(x.t) : null;
    const when = d
      ? ymd(d) + ' ' + p2(d.getHours()) + ':' + p2(d.getMinutes()) + ' \u00b7 ' + WEEK[d.getDay()]
      : '\u4e0d\u8bb0\u5f97\u54ea\u5929';

    const box = D.createElement('div');
    box.className = 'ap-view';
    box.id = 'ap-view';
    box.innerHTML =
      '<div class="ap-top">' +
        '<span class="ap-when">' + esc(when) + '</span>' +
        '<span class="ap-count">' + (k + 1) + ' / ' + flat.length + '</span>' +
        '<button type="button" class="ap-x" aria-label="\u5173\u4e0a">\u2715</button>' +
      '</div>' +
      '<div class="ap-stage"><img class="ap-img" src="' + x.u + '" alt=""></div>' +
      '<div class="ap-foot">' +
        '<button type="button" class="ap-nav" data-d="-1"' + (k <= 0 ? ' disabled' : '') + '>\u2039</button>' +
        '<button type="button" class="ap-del" id="ap-del">\u5220\u6389\u8fd9\u5f20</button>' +
        '<button type="button" class="ap-nav" data-d="1"' + (k >= flat.length - 1 ? ' disabled' : '') + '>\u203a</button>' +
      '</div>';

    D.body.appendChild(box);
    D.body.style.overflow = 'hidden';
  }

  function close() {
    const v = D.getElementById('ap-view');
    if (v) v.remove();
    D.body.style.overflow = '';
    viewAt = -1;
  }

  function step(d) {
    const n = viewAt + d;
    if (n < 0 || n >= flat.length) return;
    open(n);
  }

  function del(btn) {
    if (btn.getAttribute('data-armed') !== '1') {
      const old = btn.textContent;
      btn.setAttribute('data-armed', '1');
      btn.textContent = '\u518d\u70b9\u4e00\u4e0b\uff0c\u5220\u6389';
      setTimeout(function () {
        btn.removeAttribute('data-armed');
        btn.textContent = old;
      }, 4000);
      return;
    }

    const x = flat[viewAt];
    if (!x) return;

    const arr = (Array.isArray(XW.S.photos) ? XW.S.photos : []).slice();
    arr.splice(x.i, 1);
    XW.S.photos = arr;
    try { XW.save('photos'); } catch (e) {}

    close();
    UI.toast('\u5220\u6389\u4e86');
    window.Router.reopen('album');
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#album-add')) {
      const f = D.getElementById('album-file');
      if (f) f.click();
      return;
    }

    const chip = t.closest('.ap-t');
    if (chip) {
      filterDay = chip.getAttribute('data-fd') || '';
      window.Router.reopen('album');
      return;
    }

    const cell = t.closest('.ap-cell') || t.closest('.ap-cover');
    if (cell) {
      open(Number(cell.getAttribute('data-k')));
      return;
    }

    if (t.closest('.ap-x')) { close(); return; }

    const nav = t.closest('.ap-nav');
    if (nav) { step(Number(nav.getAttribute('data-d'))); return; }

    if (t.id === 'ap-del') { del(t); return; }
  }, false);

  let sx = 0, sy = 0;

  D.addEventListener('touchstart', function (e) {
    if (!D.getElementById('ap-view')) return;
    const p = e.touches && e.touches[0];
    if (!p) return;
    sx = p.clientX;
    sy = p.clientY;
  }, { passive: true });

  D.addEventListener('touchend', function (e) {
    if (!D.getElementById('ap-view')) return;
    const p = e.changedTouches && e.changedTouches[0];
    if (!p) return;
    const dx = p.clientX - sx;
    const dy = p.clientY - sy;
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy)) step(dx < 0 ? 1 : -1);
  }, { passive: true });

  function bind() {
    bindFiles();
    setTimeout(bindFiles, 120);
    setTimeout(bindFiles, 400);
  }

  P.album = album;
  P.albumBind = bind;
})();
