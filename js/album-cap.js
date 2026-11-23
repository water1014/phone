/* album-cap.js · 在大图里给照片写一句话（不碰 album-pro.js） */
(function () {
  const D = document;

  function norm(p) {
    if (typeof p === 'string') return { u: p, t: 0, c: '' };
    if (p && typeof p === 'object' && p.u) {
      return { u: String(p.u), t: Number(p.t) || 0, c: String(p.c || '') };
    }
    return null;
  }

  function idxOf(src) {
    const arr = Array.isArray(XW.S.photos) ? XW.S.photos : [];
    for (let i = arr.length - 1; i >= 0; i--) {
      const n = norm(arr[i]);
      if (n && n.u === src) return i;
    }
    return -1;
  }

  function inject() {
    const v = D.getElementById('ap-view');
    if (!v) return;
    if (v.querySelector('#ap-capin')) return;

    const stage = v.querySelector('.ap-stage');
    const img = v.querySelector('.ap-img');
    if (!stage || !img) return;

    const src = img.getAttribute('src') || '';
    const i = idxOf(src);
    if (i < 0) return;

    const n = norm(XW.S.photos[i]);
    if (!n) return;

    const inp = D.createElement('input');
    inp.id = 'ap-capin';
    inp.className = 'ap-capin';
    inp.type = 'text';
    inp.maxLength = 120;
    inp.placeholder = '\u7ed9\u8fd9\u5f20\u5199\u4e00\u53e5\u2026';
    inp.value = n.c || '';
    inp.setAttribute('data-k', String(i));

    stage.parentNode.insertBefore(inp, stage.nextSibling);
  }

  function save(i, text) {
    const arr = (Array.isArray(XW.S.photos) ? XW.S.photos : []).slice();
    const n = norm(arr[i]);
    if (!n) return;

    const c = String(text || '').trim();
    if (c === n.c) return;

    arr[i] = { u: n.u, t: n.t, c: c };
    XW.S.photos = arr;

    try { XW.save('photos'); } catch (e) {}
    UI.toast(c ? '\u8bb0\u4e0b\u4e86' : '\u5b57\u6ca1\u4e86');
  }

  D.addEventListener('blur', function (e) {
    const t = e.target;
    if (!t || t.id !== 'ap-capin') return;
    save(Number(t.getAttribute('data-k')), t.value);
  }, true);

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      inject();
    }, 60);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  inject();
})();
