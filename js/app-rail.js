/* app-rail.js · App 内页也能拉出侧栏
   右边一条极细的竖条，点一下侧栏滑出来 */
(function () {
  const D = document;

  function railEl() {
    return D.querySelector('.rail');
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
    rail.classList.add('open');

    const s = scrimEl();
    s.hidden = false;
  }

  function closeRail() {
    const rail = railEl();
    if (rail) rail.classList.remove('open');

    const s = D.querySelector('.scrim');
    if (s) s.hidden = true;
  }

  function ensureBtn() {
    let b = D.getElementById('app-rail-btn');
    if (b) return;

    b = D.createElement('button');
    b.type = 'button';
    b.id = 'app-rail-btn';
    b.className = 'app-rail-btn';
    b.setAttribute('aria-label', '打开侧栏');
    b.innerHTML = '<i></i>';
    D.body.appendChild(b);
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#app-rail-btn')) {
      e.preventDefault();
      e.stopPropagation();
      openRail();
      return;
    }

    if (t.closest('.scrim')) {
      closeRail();
      return;
    }

    if (t.closest('.rail-row') || t.closest('.rail-act')) {
      setTimeout(closeRail, 120);
    }
  }, true);

  ensureBtn();
  setTimeout(ensureBtn, 500);
})();
