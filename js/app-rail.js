/* app-rail.js · App 内页拉出左侧栏
   两个入口：左边缘长按、左边缘往右拖
   都不依赖 html[data-app]，直接看 #app 是否打开 */
(function () {
  const D = document;
  const EDGE = 80;
  const HOLD = 340;

  let pressTimer = null;
  let startX = 0;
  let startY = 0;
  let moved = false;

  function railEl() {
    return D.querySelector('.rail');
  }

  function inApp() {
    const app = D.getElementById('app');
    return !!(app && app.classList.contains('show'));
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

  function buzz() {
    try { if (navigator.vibrate) navigator.vibrate(12); } catch (e) {}
  }

  function openRail() {
    const rail = railEl();
    if (!rail) return;

    rail.style.transition = '';
    rail.style.transform = '';
    rail.classList.add('open');
    scrimEl().hidden = false;
    buzz();
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

  function stopHold() {
    if (pressTimer) {
      clearTimeout(pressTimer);
      pressTimer = null;
    }
  }

  D.addEventListener('touchstart', function (e) {
    stopHold();
    moved = false;

    if (!inApp()) return;

    const t = e.touches && e.touches[0];
    if (!t) return;
    if (t.clientX > EDGE) return;

    startX = t.clientX;
    startY = t.clientY;

    pressTimer = setTimeout(function () {
      pressTimer = null;
      if (!moved) openRail();
    }, HOLD);
  }, { capture: true, passive: true });

  D.addEventListener('touchmove', function (e) {
    const t = e.touches && e.touches[0];
    if (!t) return;

    const dx = t.clientX - startX;
    const dy = t.clientY - startY;

    if (!moved && (Math.abs(dx) > 9 || Math.abs(dy) > 9)) {
      moved = true;
      stopHold();
    }

    if (moved && dx > 40 && Math.abs(dx) > Math.abs(dy) && inApp()) {
      if (!railEl()) return;
      openRail();
    }
  }, { capture: true, passive: true });

  D.addEventListener('touchend', stopHold, { capture: true, passive: true });
  D.addEventListener('touchcancel', stopHold, { capture: true, passive: true });

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('.scrim')) { closeRail(); return; }

    if (t.closest('.rail-row') || t.closest('.rail-act')) {
      setTimeout(closeRail, 120);
    }
  }, true);

  window.AppRail = { open: openRail, close: closeRail };
})();
