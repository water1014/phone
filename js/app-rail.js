/* app-rail.js · App 内页从左边缘往右拖，侧栏跟手滑出 */
(function () {
  const D = document;
  const EDGE = 28;
  const RATIO = 0.3;

  let tracking = false;
  let dragging = false;
  let sx = 0;
  let sy = 0;
  let sw = 280;

  function railEl() {
    return D.querySelector('.rail');
  }

  function isApp() {
    return D.documentElement.getAttribute('data-app') === '1';
  }

  function scrimEl() {
    let s = D.querySelector('.scrim');
    if (s) return s;

    s = D.createElement('div');
    s.className = 'scrim';
    s.hidden = true;
    D.body.appendChild(s);
    return s;
  }

  function openRail() {
    const rail = railEl();
    if (!rail) return;
    rail.style.transition = '';
    rail.style.transform = '';
    rail.classList.add('open');
    scrimEl().hidden = false;
  }

  function closeRail() {
    const rail = railEl();
    if (rail) {
      rail.style.transition = '';
      rail.style.transform = '';
      rail.classList.remove('open');
    }
    const s = D.querySelector('.scrim');
    if (s) s.hidden = true;
  }

  D.addEventListener('touchstart', function (e) {
    tracking = false;
    dragging = false;
    if (!isApp()) return;

    const t = e.touches && e.touches[0];
    if (!t) return;
    if (t.clientX > EDGE) return;

    const rail = railEl();
    if (!rail) return;

    tracking = true;
    sx = t.clientX;
    sy = t.clientY;
    sw = rail.offsetWidth || 280;
  }, { passive: true });

  D.addEventListener('touchmove', function (e) {
    if (!tracking) return;

    const t = e.touches && e.touches[0];
    if (!t) return;

    const dx = t.clientX - sx;
    const dy = t.clientY - sy;

    if (!dragging) {
      if (dx < 12) return;
      if (Math.abs(dy) > Math.abs(dx)) { tracking = false; return; }

      dragging = true;
      const r0 = railEl();
      if (r0) r0.style.transition = 'none';
      scrimEl().hidden = false;
    }

    try { e.preventDefault(); } catch (err) {}

    const rail = railEl();
    if (!rail) return;

    const p = Math.max(0, Math.min(1, dx / sw));
    rail.style.transform = 'translateX(' + (-104 + 104 * p) + '%)';
  }, { passive: false });

  D.addEventListener('touchend', function (e) {
    if (!tracking) return;
    tracking = false;

    if (!dragging) return;
    dragging = false;

    const t = e.changedTouches && e.changedTouches[0];
    const dx = t ? (t.clientX - sx) : 0;

    if (dx > sw * RATIO) openRail();
    else closeRail();
  }, { passive: true });

  D.addEventListener('touchcancel', function () {
    tracking = false;
    if (dragging) {
      dragging = false;
      closeRail();
    }
  }, { passive: true });

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('.scrim')) { closeRail(); return; }

    if (t.closest('.rail-row') || t.closest('.rail-act')) {
      setTimeout(closeRail, 120);
    }
  }, true);
})();
