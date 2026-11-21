/* chat-think.js · 让「思考」真的点得开
   聊天页的长按会抣点击，在捕获阶段拦下来 */
(function () {
  const D = document;

  function inThink(t) {
    return !!(t && t.closest && t.closest('details.think'));
  }

  ['touchstart', 'touchmove', 'touchend', 'touchcancel'].forEach(function (name) {
    D.addEventListener(name, function (e) {
      if (inThink(e.target)) e.stopPropagation();
    }, true);
  });

  D.addEventListener('contextmenu', function (e) {
    if (inThink(e.target)) e.stopPropagation();
  }, true);

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;
    const sum = t.closest('details.think > summary');
    if (!sum) return;
    e.preventDefault();
    e.stopPropagation();
    const det = sum.parentNode;
    if (det) det.open = !det.open;
  }, true);

  function paint() {
    const list = D.querySelectorAll('details.think > summary');
    Array.prototype.forEach.call(list, function (s) {
      if (s.getAttribute('data-tap') === '1') return;
      s.setAttribute('data-tap', '1');
      s.style.cursor = 'pointer';
      s.style.webkitTapHighlightColor = 'transparent';
      s.style.pointerEvents = 'auto';
    });
  }

  let timer = null;

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      paint();
    }, 100);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  paint();
  setTimeout(paint, 600);
})();
