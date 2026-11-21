/* chat-img.js · 聊天里的图点开看大，可左右换 */
(function () {
  const D = document;

  let list = [];
  let idx = 0;
  let sx = 0;
  let sy = 0;
  let swiped = false;

  function box() {
    let v = D.getElementById('cs-imgview');
    if (v) return v;

    v = D.createElement('div');
    v.id = 'cs-imgview';
    v.className = 'cs-imgview';
    v.innerHTML =
      '<img alt>' +
      '<button type=button class=cs-imgview-prev id=cs-imgview-prev>‹</button>' +
      '<button type=button class=cs-imgview-next id=cs-imgview-next>›</button>' +
      '<span class=cs-imgview-n id=cs-imgview-n></span>' +
      '<button type=button class=cs-imgview-x id=cs-imgview-x>×</button>';
    D.body.appendChild(v);
    return v;
  }

  function collect() {
    const out = [];
    Array.prototype.forEach.call(D.querySelectorAll('#chat-scroll .msg-img img'), function (im) {
      const s = im.getAttribute('src');
      if (s) out.push(s);
    });
    return out;
  }

  function show(i) {
    if (!list.length) return;
    idx = ((i % list.length) + list.length) % list.length;

    const v = box();
    const im = v.querySelector('img');
    if (im) im.src = list[idx];

    const n = v.querySelector('#cs-imgview-n');
    if (n) n.textContent = (idx + 1) + ' / ' + list.length;

    const many = list.length > 1;
    const p = v.querySelector('#cs-imgview-prev');
    const q = v.querySelector('#cs-imgview-next');
    if (p) p.style.display = many ? '' : 'none';
    if (q) q.style.display = many ? '' : 'none';
  }

  function open(src) {
    list = collect();
    const i = list.indexOf(src);
    show(i < 0 ? 0 : i);
    box().classList.add('on');
  }

  function close() {
    const v = D.getElementById('cs-imgview');
    if (!v) return;
    v.classList.remove('on');
    const im = v.querySelector('img');
    if (im) im.removeAttribute('src');
  }

  D.addEventListener('touchstart', function (e) {
    const v = D.getElementById('cs-imgview');
    if (!v || !v.classList.contains('on')) return;
    const t = e.touches && e.touches[0];
    if (!t) return;
    sx = t.clientX;
    sy = t.clientY;
    swiped = false;
  }, { passive: true });

  D.addEventListener('touchmove', function (e) {
    const v = D.getElementById('cs-imgview');
    if (!v || !v.classList.contains('on')) return;
    const t = e.touches && e.touches[0];
    if (!t) return;
    if (Math.abs(t.clientX - sx) > 18) swiped = true;
  }, { passive: true });

  D.addEventListener('touchend', function (e) {
    const v = D.getElementById('cs-imgview');
    if (!v || !v.classList.contains('on')) return;
    const t = e.changedTouches && e.changedTouches[0];
    if (!t) return;
    const dx = t.clientX - sx;
    const dy = t.clientY - sy;
    if (Math.abs(dx) > 45 && Math.abs(dx) > Math.abs(dy)) show(idx + (dx < 0 ? 1 : -1));
  }, { passive: true });

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cs-imgview-x')) { close(); return; }
    if (t.closest('#cs-imgview-prev')) { show(idx - 1); return; }
    if (t.closest('#cs-imgview-next')) { show(idx + 1); return; }

    if (t.closest('.cs-imgview')) {
      if (t.tagName !== 'IMG' && !swiped) close();
      swiped = false;
      return;
    }

    const im = t.closest('.msg-img img');
    if (im) {
      e.preventDefault();
      e.stopPropagation();
      open(im.getAttribute('src'));
    }
  }, true);
})();
