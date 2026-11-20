/* daycard.js — 首页天数卡 / 头像 / 名字 / 翻面 */
(function () {
  const D = document;
  const K_HIS = 'xw_ava_his';
  const K_HER = 'xw_ava_her';
  const K_NOTE = 'xw_daynote';
  const CR = String.fromCharCode(13);
  const LF = String.fromCharCode(10);
  const Q = String.fromCharCode(34);
  let queued = false;

  function esc(t) {
    return String(t == null ? '' : t)
      .split('&').join('&amp;')
      .split('<').join('&lt;')
      .split('>').join('&gt;');
  }

  function flat(t) {
    return String(t).split(CR).join('').split(LF).join(' ').trim();
  }

  function lsGet(k) {
    try { const v = localStorage.getItem(k); return v == null ? '' : v; }
    catch (e) { return ''; }
  }

  function lsSet(k, v) {
    try { localStorage.setItem(k, v); } catch (e) {}
  }

  function nameOf(who) {
    const raw = who === 'his' ? XW.S.hisName : XW.S.herName;
    return String(raw == null ? '' : raw).trim();
  }

  function setName(who, text) {
    if (who === 'his') {
      XW.S.hisName = text;
      XW.save('hisName');
    } else {
      XW.S.herName = text;
      XW.save('herName');
    }
  }

  function avaHtml(who) {
    const url = lsGet(who === 'his' ? K_HIS : K_HER);
    const inner = url
      ? '<img src=' + Q + url.split(Q).join('%22') + Q + ' alt=' + Q + Q + '>'
      : '<i>+</i>';
    return '<button type=' + Q + 'button' + Q + ' class=' + Q + 'dc-ava' + Q +
      ' data-who=' + Q + who + Q + '>' + inner + '</button>';
  }

  function frontHtml() {
    const d = UI.diffDay(new Date(XW.S.loveDate || '2025-01-01'), new Date());
    const Q2 = Q + Q;

    return '<div class=' + Q + 'dc-face dc-front' + Q + '>' +
        '<div class=' + Q + 'dc-kicker' + Q + '>TOGETHER</div>' +
        '<div class=' + Q + 'dc-pair' + Q + '>' +
          avaHtml('his') +
          '<span class=' + Q + 'dc-amp' + Q + '>&amp;</span>' +
          avaHtml('her') +
        '</div>' +
        '<div class=' + Q + 'dc-names' + Q + '>' +
          '<span class=' + Q + 'dc-name' + Q + ' contenteditable=' + Q + 'true' + Q +
            ' spellcheck=' + Q + 'false' + Q + ' data-who=' + Q + 'his' + Q +
            ' data-ph=' + Q + '名字' + Q + '>' + esc(nameOf('his')) + '</span>' +
          '<span class=' + Q + 'dc-amp' + Q + '>&amp;</span>' +
          '<span class=' + Q + 'dc-name' + Q + ' contenteditable=' + Q + 'true' + Q +
            ' spellcheck=' + Q + 'false' + Q + ' data-who=' + Q + 'her' + Q +
            ' data-ph=' + Q + '名字' + Q + '>' + esc(nameOf('her')) + '</span>' +
        '</div>' +
        '<div class=' + Q + 'dc-num' + Q + '>' + d +
          '<small>DAYS</small></div>' +
      '</div>';
  }

  function backHtml() {
    const love = new Date(XW.S.loveDate || '2025-01-01');
    const d = UI.diffDay(love, new Date());
    const next = Math.ceil((d + 1) / 100) * 100;
    const left = next - d;
    const y = love.getFullYear();
    const m = ('0' + (love.getMonth() + 1)).slice(-2);
    const dd = ('0' + love.getDate()).slice(-2);

    return '<div class=' + Q + 'dc-face dc-back' + Q + '>' +
        '<div class=' + Q + 'dc-since' + Q + '>SINCE ' + y + '.' + m + '.' + dd + '</div>' +
        '<div class=' + Q + 'dc-next' + Q + '>第 ' + next + ' 天</div>' +
        '<div class=' + Q + 'dc-left' + Q + '>还有 ' + left + ' 天</div>' +
        '<div class=' + Q + 'dc-note' + Q + ' contenteditable=' + Q + 'true' + Q +
          ' spellcheck=' + Q + 'false' + Q + ' data-ph=' + Q + '点这儿写一句' + Q + '>' +
          esc(lsGet(K_NOTE)) +
        '</div>' +
      '</div>';
  }

  function inner() {
    return '<div class=' + Q + 'dc-in' + Q + '>' + frontHtml() + backHtml() + '</div>';
  }

  function pickAva(who, root) {
    const inp = D.createElement('input');
    inp.type = 'file';
    inp.accept = 'image/*';
    inp.style.display = 'none';
    D.body.appendChild(inp);

    inp.addEventListener('change', function () {
      const f = inp.files && inp.files[0];

      function done() {
        if (inp.parentNode) inp.parentNode.removeChild(inp);
      }

      if (!f) { done(); return; }

      const reader = new FileReader();

      reader.onload = function () {
        const img = new Image();

        img.onload = function () {
          const S = 200;
          const cv = D.createElement('canvas');
          cv.width = S;
          cv.height = S;

          const g = cv.getContext('2d');
          const m = Math.min(img.width, img.height);

          g.drawImage(
            img,
            (img.width - m) / 2, (img.height - m) / 2, m, m,
            0, 0, S, S
          );

          let data = '';
          try { data = cv.toDataURL('image/jpeg', 0.82); } catch (e) { data = ''; }

          if (data) {
            lsSet(who === 'his' ? K_HIS : K_HER, data);
            paint(root);
          }

          done();
        };

        img.onerror = done;
        img.src = reader.result;
      };

      reader.onerror = done;
      reader.readAsDataURL(f);
    });

    inp.click();
  }

  function bindInner(root) {
    Array.prototype.forEach.call(root.querySelectorAll('.dc-name'), function (el) {
      el.addEventListener('blur', function () {
        const who = el.getAttribute('data-who');
        const t = flat(el.innerText);
        if (t === nameOf(who)) return;
        setName(who, t);
        el.innerHTML = esc(t);
      });

      el.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
          e.preventDefault();
          el.blur();
        }
      });
    });

    const note = root.querySelector('.dc-note');
    if (!note) return;

    note.addEventListener('blur', function () {
      lsSet(K_NOTE, flat(note.innerText));
    });

    note.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        note.blur();
      }
    });
  }

  function bindOnce(root) {
    root.addEventListener('click', function (e) {
      const ava = e.target.closest('.dc-ava');
      if (ava) {
        e.stopPropagation();
        pickAva(ava.getAttribute('data-who'), root);
        return;
      }

      if (e.target.closest('.dc-name') || e.target.closest('.dc-note')) {
        e.stopPropagation();
        return;
      }

      root.classList.toggle('flip');
    });
  }

  function paint(root) {
    root.classList.remove('flip');
    root.innerHTML = inner();
    bindInner(root);
  }

  function make() {
    const box = D.createElement('section');
    box.className = 'dcard';
    box.innerHTML = inner();
    bindOnce(box);
    bindInner(box);
    return box;
  }

  function mount() {
    if (!window.XW || !window.UI) return;

    const home = D.getElementById('home') || D.getElementById('screen');
    if (!home) return;

    const old = home.querySelector('.wdg-days');
    if (!old) return;

    old.parentNode.replaceChild(make(), old);
  }

  function schedule() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () {
      queued = false;
      mount();
    });
  }

  const screen = D.getElementById('screen');
  if (screen) {
    new MutationObserver(schedule).observe(screen, { childList: true });
  }

  schedule();
  D.addEventListener('DOMContentLoaded', schedule);
  setTimeout(schedule, 400);
})();
