/* chat-img.js · 聊天里的图点开看大 */
(function () {
  const D = document;

  function box() {
    let v = D.getElementById('cs-imgview');
    if (v) return v;

    v = D.createElement('div');
    v.id = 'cs-imgview';
    v.className = 'cs-imgview';
    v.innerHTML = '<img alt><button type=button class=cs-imgview-x id=cs-imgview-x>×</button>';
    D.body.appendChild(v);
    return v;
  }

  function open(src) {
    if (!src) return;
    const v = box();
    const im = v.querySelector('img');
    if (im) im.src = src;
    v.classList.add('on');
  }

  function close() {
    const v = D.getElementById('cs-imgview');
    if (!v) return;
    v.classList.remove('on');
    const im = v.querySelector('img');
    if (im) im.removeAttribute('src');
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    if (t.closest('#cs-imgview-x')) { close(); return; }

    if (t.closest('.cs-imgview')) {
      if (t.tagName !== 'IMG') close();
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
