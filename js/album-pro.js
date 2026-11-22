/* album-pro.js · 相册：按天分组、点开看大图、大图里删 */
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

  function collect() {
    const raw = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    flat = [];
    raw.forEach(function (p, i) {
      const n = norm(p);
      if (n) flat.push({ u: n.u, t: n.t, c: n.c, i: i });
    });
    return flat;
  }

  function groups() {
    collect();
    const map = {};
    flat.forEach(function (x, k) {
      const key = x.t ? ymd(new Date(x.t)) : '';
      (map[key] = map[key] || []).push(k);
    });

    const keys = Object.keys(map).sort(function (a, b) {
      if (a === '') return 1;
      if (b === '') return -1;
      return a < b ? 1 : -1;
    });

    return keys.map(function (k) { return { k: k, idx: map[k] }; });
  }

  function album() {
    const gs = groups();
    const days = gs.filter(function (g) { return !!g.k; }).length;

    const sub = flat.length
      ? ('\u5171 ' + flat.length + ' \u5f20' + (days > 1 ? ' \u00b7 ' + days + ' \u5929' : ''))
      : '\u8fd8\u7a7a\u7740';

    let body = '';

    if (!flat.length) {
      body = '<div class="empty-state" style="margin-top:1.4rem">\u8fd8\u6ca1\u6709\u7167\u7247\u3002<br>\u56fe\u653e\u8fdb\u6765\uff0c\u6211\u4e00\u5f20\u5f20\u6446\u4e0a\u3002</div>';
    } else {
      gs.forEach(function (g) {
        const label = g.k
          ? g.k + ' \u00b7 ' + g.idx.length + ' \u5f20'
          : '\u66f4\u65e9 \u00b7 ' + g.idx.length + ' \u5f20';

        body += '<div class="ap-band">' + esc(label) + '</div>';
        body += '<div class="ap-grid album-grid">' + g.idx.map(function (k) {
          return '<button type="button" class="ap-cell" data-k="' + k + '">' +
            '<img src="' + flat[k].u + '" alt="" loading="lazy">' +
          '</button>';
        }).join('') + '</div>';
      });
    }

    return '<header class="hero">' +
        '<span class="kicker">ALBUM</span>' +
        '<h1 class="hero-title">\u76f8\u518c</h1>' +
        '<div class="hero-sub">' + esc(sub) + '</div>' +
      '</header>' +
      '<div class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">' +
          (flat.length ? '\u7167\u7247' : '\u7a7a\u7684') +
        '</span>' +
        '<button type="button" id="album-add" class="btn-glass">\uff0b \u653e\u7167\u7247</button></div>' +
        '<input id="album-file" type="file" accept="image/*" multiple hidden>' +
        '<div>' + body + '</div>' +
        '<div class="sheet-note">\u7167\u7247\u5b58\u5728\u8fd9\u53f0\u624b\u673a\u7684\u6d4f\u89c8\u5668\u91cc\uff0c\u6e05\u7f13\u5b58\u4f1a\u4e22\u3002\u6362\u624b\u673a\u4e4b\u524d\u5148\u5bfc\u4e00\u4efd\u5907\u4efd\u3002</div>' +
      '</div>';
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

    const cell = t.closest('.ap-cell');
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
