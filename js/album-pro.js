/* album-pro.js · 相册（仿 iOS 相册）：年/月/日 + 多选 + 黑底全屏 */
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
  let segView = 'month';
  let selMode = false;
  let sel = {};
  let pendingScroll = '';

  function collect() {
    const raw = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    flat = [];
    raw.forEach(function (p, i) {
      const n = norm(p);
      if (n) flat.push({ u: n.u, t: n.t, c: n.c, i: i });
    });
    return flat;
  }

  function keyOf(t, level) {
    if (!t) return '';
    const d = new Date(t);
    if (level === 'year') return String(d.getFullYear());
    if (level === 'month') return d.getFullYear() + '-' + p2(d.getMonth() + 1);
    return ymd(d);
  }

  function groupsBy(seq, level) {
    const map = {};
    seq.forEach(function (x) {
      const k = keyOf(x.t, level);
      (map[k] = map[k] || []).push(x);
    });

    const keys = Object.keys(map).sort(function (a, b) {
      if (a === '') return 1;
      if (b === '') return -1;
      return a < b ? 1 : -1;
    });

    return keys.map(function (k) { return { k: k, items: map[k] }; });
  }

  function titleOf(k, level) {
    if (!k) return '\u66f4\u65e9';
    if (level === 'year') return k + ' \u5e74';
    if (level === 'month') return k.slice(0, 4) + ' \u5e74 ' + Number(k.slice(5)) + ' \u6708';
    const d = new Date(k + 'T12:00:00');
    return (d.getMonth() + 1) + ' \u6708 ' + d.getDate() + ' \u65e5 \u00b7 ' + WEEK[d.getDay()];
  }

  function cellHtml(x) {
    return '<button type="button" class="ap-cell' + (sel[x.i] ? ' picked' : '') + '" data-k="' + x.i + '">' +
      '<img src="' + x.u + '" alt="" loading="lazy">' +
      (selMode ? '<span class="ap-pick"></span>' : '') +
    '</button>';
  }

  function yearBody() {
    let out = '';

    groupsBy(flat, 'year').forEach(function (yg) {
      out += '<div class="ap-sec"><span class="ap-sec-t">' + esc(titleOf(yg.k, 'year')) +
        '</span><span class="ap-sec-n">' + yg.items.length + '</span></div>';

      groupsBy(yg.items, 'month').forEach(function (mg) {
        const thumbs = mg.items.slice(0, 4).map(function (x) {
          return '<img src="' + x.u + '" alt="" loading="lazy">';
        }).join('');

        out += '<button type="button" class="ap-yrow" data-mv="' + mg.k + '">' +
            '<span class="ap-ymon">' + (mg.k ? Number(mg.k.slice(5)) : '\u66f4\u65e9') + '</span>' +
            '<span class="ap-ythumbs">' + thumbs + '</span>' +
            '<span class="ap-ycount">' + mg.items.length + '</span>' +
          '</button>';
      });
    });

    return out;
  }

  function album() {
    collect();

    const daySet = {};
    flat.forEach(function (x) { if (x.t) daySet[ymd(new Date(x.t))] = 1; });
    const dayCount = Object.keys(daySet).length;

    const sub = flat.length
      ? ('<span class="ap-n">' + flat.length + '</span> \u5f20' +
         (dayCount > 1 ? ' \u00b7 <span class="ap-n">' + dayCount + '</span> \u5929' : ''))
      : '\u8fd8\u7a7a\u7740';

    const tools = '<div class="ap-tools">' +
        (flat.length ? '<button type="button" class="ap-sel' + (selMode ? ' on' : '') + '" id="ap-selmode">' +
          (selMode ? '\u53d6\u6d88' : '\u9009\u62e9') + '</button>' : '') +
        '<button type="button" id="album-add" class="ap-add" aria-label="\u653e\u7167\u7247">\uff0b</button>' +
      '</div>';

    const head = '<div class="ap-head">' +
        '<div class="hero">' +
          '<span class="kicker">ALBUM</span>' +
          '<h1 class="hero-title">\u76f8\u518c</h1>' +
          '<div class="hero-sub">' + sub + '</div>' +
        '</div>' +
        tools +
      '</div>';

    let seg = '';
    if (flat.length) {
      seg = '<div class="ap-seg">' +
          [['year', '\u5e74'], ['month', '\u6708'], ['day', '\u65e5']].map(function (it) {
            return '<button type="button" class="ap-sg' + (segView === it[0] ? ' on' : '') +
              '" data-sv="' + it[0] + '">' + it[1] + '</button>';
          }).join('') +
        '</div>';
    }

    let body = '';

    if (!flat.length) {
      body = '<div class="empty-state ap-empty">\u8fd8\u6ca1\u6709\u7167\u7247\u3002<br>\u56fe\u653e\u8fdb\u6765\uff0c\u6211\u4e00\u5f20\u5f20\u6446\u4e0a\u3002</div>';
    } else if (segView === 'year') {
      body = yearBody();
    } else {
      groupsBy(flat, segView).forEach(function (g) {
        body += '<div class="ap-sec"' + (segView === 'month' ? ' data-mk="' + g.k + '"' : '') + '>' +
            '<span class="ap-sec-t">' + esc(titleOf(g.k, segView)) + '</span>' +
            '<span class="ap-sec-n">' + g.items.length + '</span>' +
          '</div>' +
          '<div class="ap-grid">' + g.items.map(cellHtml).join('') + '</div>';
      });
    }

    const bar = selMode
      ? '<div class="ap-selbar">' +
          '<button type="button" id="ap-selall">\u5168\u9009</button>' +
          '<button type="button" id="ap-seldel">\u5220\u9664</button>' +
        '</div>'
      : '';

    return head +
      '<input id="album-file" type="file" accept="image/*" multiple hidden>' +
      seg +
      body +
      (selMode ? '<div class="ap-selpad"></div>' : '') +
      bar +
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

  function updateBar() {
    const n = Object.keys(sel).length;
    const del = D.getElementById('ap-seldel');
    const all = D.getElementById('ap-selall');

    if (del) {
      del.textContent = n ? ('\u5220\u9664 ' + n) : '\u5220\u9664';
      del.removeAttribute('data-armed');
      del.disabled = !n;
      del.style.opacity = n ? '1' : '.4';
    }

    if (all) {
      all.textContent = (n && n >= flat.length) ? '\u53d6\u6d88\u5168\u9009' : '\u5168\u9009';
    }
  }

  function paintPick() {
    Array.prototype.forEach.call(D.querySelectorAll('#app-body .ap-cell'), function (c) {
      const k = Number(c.getAttribute('data-k'));
      c.classList.toggle('picked', !!sel[k]);
    });
    updateBar();
  }

  function open(k) {
    close();
    const x = flat[k];
    if (!x) return;
    viewAt = k;

    const d = x.t ? new Date(x.t) : null;
    const when = d
      ? ymd(d) + ' ' + p2(d.getHours()) + ':' + p2(d.getMinutes())
      : '\u4e0d\u8bb0\u5f97\u54ea\u5929';

    const box = D.createElement('div');
    box.className = 'ap-view';
    box.id = 'ap-view';
    box.innerHTML =
      '<div class="ap-top">' +
        '<button type="button" class="ap-back" aria-label="\u8fd4\u56de">\u2039</button>' +
        '<span class="ap-when">' + esc(when) + '</span>' +
        '<span class="ap-count">' + (k + 1) + '/' + flat.length + '</span>' +
      '</div>' +
      '<div class="ap-stage"><img class="ap-img" src="' + x.u + '" alt=""></div>' +
      '<div class="ap-foot">' +
        '<button type="button" class="ap-tool" data-d="-1"' + (k <= 0 ? ' disabled' : '') + '>\u2039</button>' +
        '<button type="button" class="ap-tool wide" id="ap-del">\u5220\u6389</button>' +
        '<button type="button" class="ap-tool" data-d="1"' + (k >= flat.length - 1 ? ' disabled' : '') + '>\u203a</button>' +
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
      btn.textContent = '\u518d\u70b9\u4e00\u4e0b';
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

  function delSelected(btn) {
    const keys = Object.keys(sel);
    if (!keys.length) return;

    if (btn.getAttribute('data-armed') !== '1') {
      btn.setAttribute('data-armed', '1');
      btn.textContent = '\u518d\u70b9\u4e00\u4e0b\uff0c\u5220 ' + keys.length + ' \u5f20';
      setTimeout(function () { updateBar(); }, 4000);
      return;
    }

    const drop = {};
    keys.forEach(function (k) { drop[Number(k)] = 1; });

    const arr = (Array.isArray(XW.S.photos) ? XW.S.photos : []).filter(function (p, i) {
      return !drop[i];
    });

    XW.S.photos = arr;
    try { XW.save('photos'); } catch (e) {}

    sel = {};
    selMode = false;
    UI.toast('\u5220\u6389 ' + keys.length + ' \u5f20');
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

    if (t.closest('#ap-selmode')) {
      selMode = !selMode;
      sel = {};
      window.Router.reopen('album');
      return;
    }

    if (t.closest('#ap-selall')) {
      const n = Object.keys(sel).length;
      sel = {};
      if (n < flat.length) {
        flat.forEach(function (x) { sel[x.i] = 1; });
      }
      paintPick();
      return;
    }

    if (t.closest('#ap-seldel')) {
      delSelected(t.closest('#ap-seldel'));
      return;
    }

    const sg = t.closest('.ap-sg');
    if (sg) {
      segView = sg.getAttribute('data-sv') || 'month';
      selMode = false;
      sel = {};
      window.Router.reopen('album');
      return;
    }

    const yrow = t.closest('.ap-yrow');
    if (yrow) {
      segView = 'month';
      pendingScroll = yrow.getAttribute('data-mv') || '';
      window.Router.reopen('album');
      return;
    }

    const cell = t.closest('.ap-cell');
    if (cell) {
      const k = Number(cell.getAttribute('data-k'));
      if (selMode) {
        if (sel[k]) delete sel[k]; else sel[k] = 1;
        cell.classList.toggle('picked');
        updateBar();
      } else {
        open(k);
      }
      return;
    }

    if (t.closest('.ap-back')) { close(); return; }

    if (t.closest('.ap-stage')) {
      const v = D.getElementById('ap-view');
      if (v) v.classList.toggle('ap-hide');
      return;
    }

    const tool = t.closest('.ap-tool');
    if (tool && tool.getAttribute('data-d')) {
      step(Number(tool.getAttribute('data-d')));
      return;
    }

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

    if (dy > 90 && Math.abs(dy) > Math.abs(dx) * 1.3) { close(); return; }
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy)) step(dx < 0 ? 1 : -1);
  }, { passive: true });

  function bind() {
    bindFiles();
    updateBar();
    setTimeout(bindFiles, 120);
    setTimeout(bindFiles, 400);

    if (pendingScroll) {
      const k = pendingScroll;
      pendingScroll = '';
      setTimeout(function () {
        const el = D.querySelector('#app-body .ap-sec[data-mk="' + k + '"]');
        if (el && el.scrollIntoView) el.scrollIntoView({ block: 'start' });
      }, 80);
    }
  }

  P.album = album;
  P.albumBind = bind;
})();
