/* daycard.js · 天数卡（由 layout.js 摆放）
   正面：Together / 两个头像 / 两个名字 / 688 days
   背面：since / 下一个整百天 / 还剩几天 / 可写一句
   点空白翻面；点头像换图；点名字就地改 */
(function () {
  const D = document;
  const K_HIS = 'xw_ava_his';
  const K_HER = 'xw_ava_her';
  const K_NOTE = 'xw_daynote';
  const CR = String.fromCharCode(13);
  const LF = String.fromCharCode(10);
  const Q = String.fromCharCode(34);

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

  function nameHtml(who) {
    return '<span class=' + Q + 'dc-name' + Q +
      ' contenteditable=' + Q + 'true' + Q +
      ' spellcheck=' + Q + 'false' + Q +
      ' data-who=' + Q + who + Q +
      ' data-ph=' + Q + '名字' + Q + '>' +
      esc(nameOf(who)) + '</span>';
  }

  function frontHtml() {
    const d = UI.diffDay(new Date(XW.S.loveDate || '2025-01-01'), new Date());
    const amp = '<span class=' + Q + 'dc-amp' + Q + '>&amp;</span>';

    return '<div class=' + Q + 'dc-face dc-front' + Q + '>' +
        '<div class=' + Q + 'dc-top' + Q + '>Together</div>' +
        '<div class=' + Q + 'dc-pair' + Q + '>' +
          avaHtml('his') + amp + avaHtml('her') +
        '</div>' +
        '<div class=' + Q + 'dc-names' + Q + '>' +
          nameHtml('his') + amp + nameHtml('her') +
        '</div>' +
        '<div class=' + Q + 'dc-rule' + Q + '></div>' +
        '<div class=' + Q + 'dc-num-row' + Q + '>' +
          '<span class=' + Q + 'dc-num' + Q + '>' + d + '</span>' +
          '<span class=' + Q + 'dc-unit' + Q + '>days</span>' +
        '</div>' +
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
        '<div class=' + Q + 'dc-since' + Q + '>since ' + y + '.' + m + '.' + dd + '</div>' +
        '<div class=' + Q + 'dc-next-row' + Q + '>' +
          '<span class=' + Q + 'dc-next' + Q + '>' + next + '</span>' +
          '<span class=' + Q + 'dc-unit-b' + Q + '>days</span>' +
        '</div>' +
        '<div class=' + Q + 'dc-left' + Q + '>还剩 ' + left + ' 天</div>' +
        '<div class=' + Q + 'dc-note' + Q + ' contenteditable=' + Q + 'true' + Q +
          ' spellcheck=' + Q + 'false' + Q +
          ' data-ph=' + Q + '点这儿写一句' + Q + '>' +
          esc(lsGet(K_NOTE)) +
        '</div>' +
      '</div>';
  }

  function inner() {
    return '<div class=' + Q + 'dc-in' + Q + '>' + frontHtml() + backHtml() + '</div>';
  }

  function pickAva(who, card) {
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
            paint(card);
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

  function bindInner(card) {
    Array.prototype.forEach.call(card.querySelectorAll('.dc-name'), function (el) {
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

    const note = card.querySelector('.dc-note');
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

  function bindOnce(card) {
    card.addEventListener('click', function (e) {
      const ava = e.target.closest('.dc-ava');
      if (ava) {
        e.stopPropagation();
        pickAva(ava.getAttribute('data-who'), card);
        return;
      }

      if (e.target.closest('.dc-name') || e.target.closest('.dc-note')) {
        e.stopPropagation();
        return;
      }

      card.classList.toggle('flip');
    });
  }

  function paint(card) {
    card.classList.remove('flip');
    card.innerHTML = inner();
    bindInner(card);
  }

  window.DayCard = {
    html: function () {
      return '<div class=' + Q + 'dcard' + Q + ' data-key=' + Q + 'days' + Q + '>' +
        '<div class=' + Q + 'dc-in' + Q + '>' + frontHtml() + backHtml() + '</div>' +
      '</div>';
    },
    bind: function (root) {
      if (!root) return;
      const card = root.classList && root.classList.contains('dcard')
        ? root
        : root.querySelector('.dcard');
      if (!card) return;
      bindOnce(card);
      bindInner(card);
    }
  };
})();
