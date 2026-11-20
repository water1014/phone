/* profile.js · 个人信息卡
   头像 / 名字 / 第 N 天 / 一句签名 / 四个胶囊
   首页版可翻面；侧栏版（plain）是静态的 */
(function () {
  const D = document;
  const Q = String.fromCharCode(34);
  const CR = String.fromCharCode(13);
  const LF = String.fromCharCode(10);

  const K = {
    sign: 'xw_sign',
    mood: 'xw_mood',
    note: 'xw_note',
    his: 'xw_ava_his',
    her: 'xw_ava_her'
  };

  function lsGet(k) {
    try { const v = localStorage.getItem(k); return v == null ? '' : v; }
    catch (e) { return ''; }
  }

  function lsSet(k, v) {
    try { localStorage.setItem(k, v); } catch (e) {}
  }

  function esc(t) {
    return String(t == null ? '' : t)
      .split('&').join('&amp;')
      .split('<').join('&lt;')
      .split('>').join('&gt;');
  }

  function flat(t) {
    return String(t).split(CR).join('').split(LF).join(' ').trim();
  }

  function nameOf(who) {
    const raw = who === 'his' ? XW.S.hisName : XW.S.herName;
    const t = String(raw == null ? '' : raw).trim();
    return t || '他';
  }

  function days() {
    return UI.diffDay(new Date(XW.S.loveDate || '2025-01-01'), new Date());
  }

  function nowSong() {
    const list = Array.isArray(XW.S.songs) ? XW.S.songs : [];
    const id = Number(XW.S.nowSong) || 0;
    if (!id) return '';
    for (let i = 0; i < list.length; i++) {
      if (Number(list[i].id) === id) return String(list[i].title || '');
    }
    return '';
  }

  function avaHtml(who) {
    const url = lsGet(who === 'his' ? K.his : K.her);
    const inner = url
      ? '<img src=' + Q + url.split(Q).join('%22') + Q + ' alt=' + Q + Q + '>'
      : '+';
    return '<span class=' + Q + 'pf-ava' + Q + ' data-who=' + Q + who + Q + '>' + inner + '</span>';
  }

  function front() {
    const d = days();
    const song = nowSong();

    const heart = '<svg viewBox=' + Q + '0 0 24 24' + Q + '><path d=' + Q +
      'M12 20.3l-1.4-1.3C5.4 14.3 2.5 11.6 2.5 8.4 2.5 5.8 4.5 4 7 4c1.5 0 2.9.7 3.8 1.9l1.2 1.5 1.2-1.5C14.1 4.7 15.5 4 17 4c2.5 0 4.5 1.8 4.5 4.4 0 3.2-2.9 5.9-8.1 10.6z' +
      Q + '/></svg>';

    const note = '<svg viewBox=' + Q + '0 0 24 24' + Q + '><path d=' + Q +
      'M9 18V5.5l10-1.8v12' + Q + '/><path d=' + Q +
      'M6.5 20a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z' + Q + '/><path d=' + Q +
      'M16.5 18.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z' + Q + '/></svg>';

    return '<div class=' + Q + 'pf-front' + Q + '>' +
        '<div class=' + Q + 'pf-top' + Q + '>' +
          '<div class=' + Q + 'pf-avas' + Q + '>' +
            avaHtml('his') +
            '<span class=' + Q + 'pf-amp' + Q + '>&amp;</span>' +
            avaHtml('her') +
          '</div>' +
          '<div class=' + Q + 'pf-id' + Q + '>' +
            '<div class=' + Q + 'pf-name' + Q + '>' +
              esc(nameOf('his')) + ' &amp; ' + esc(nameOf('her')) + '</div>' +
            '<div class=' + Q + 'pf-live' + Q + '><i></i>第 ' + d + ' 天</div>' +
            '<div class=' + Q + 'pf-sign' + Q + ' contenteditable=' + Q + 'true' + Q +
              ' spellcheck=' + Q + 'false' + Q + ' data-k=' + Q + 'sign' + Q +
              ' data-ph=' + Q + '写一句此刻' + Q + '>' + esc(lsGet(K.sign)) + '</div>' +
          '</div>' +
        '</div>' +
        '<div class=' + Q + 'pf-pills' + Q + '>' +
          '<span class=' + Q + 'pf-pill pf-pink' + Q + '>' + heart +
            '在一起 ' + d + ' 天</span>' +
          '<span class=' + Q + 'pf-pill' + Q + ' contenteditable=' + Q + 'true' + Q +
            ' spellcheck=' + Q + 'false' + Q + ' data-k=' + Q + 'mood' + Q +
            ' data-ph=' + Q + '心情' + Q + '>' + esc(lsGet(K.mood)) + '</span>' +
          '<span class=' + Q + 'pf-pill' + Q + ' contenteditable=' + Q + 'true' + Q +
            ' spellcheck=' + Q + 'false' + Q + ' data-k=' + Q + 'note' + Q +
            ' data-ph=' + Q + '想说的话' + Q + '>' + esc(lsGet(K.note)) + '</span>' +
          '<span class=' + Q + 'pf-pill pf-mute' + Q + '>' + note +
            (song ? esc(song) : '还没挑歌') + '</span>' +
        '</div>' +
      '</div>';
  }

  function back() {
    const love = new Date(XW.S.loveDate || '2025-01-01');
    const d = days();
    const next = Math.ceil((d + 1) / 100) * 100;
    const left = next - d;
    const y = love.getFullYear();
    const m = ('0' + (love.getMonth() + 1)).slice(-2);
    const dd = ('0' + love.getDate()).slice(-2);

    return '<div class=' + Q + 'pf-back' + Q + '>' +
        '<div class=' + Q + 'pf-since' + Q + '>since ' + y + '.' + m + '.' + dd + '</div>' +
        '<div class=' + Q + 'pf-next' + Q + '><b>' + next + '</b><i>days</i></div>' +
        '<div class=' + Q + 'pf-left' + Q + '>还剩 ' + left + ' 天</div>' +
      '</div>';
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

          g.drawImage(img, (img.width - m) / 2, (img.height - m) / 2, m, m, 0, 0, S, S);

          let data = '';
          try { data = cv.toDataURL('image/jpeg', 0.82); } catch (e) { data = ''; }

          if (data) {
            lsSet(who === 'his' ? K.his : K.her, data);
            redraw(card);
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
    Array.prototype.forEach.call(card.querySelectorAll('[data-k]'), function (el) {
      el.addEventListener('blur', function () {
        lsSet(K[el.getAttribute('data-k')], flat(el.innerText));
      });

      el.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
          e.preventDefault();
          el.blur();
        }
      });
    });
  }

  function bindOnce(card) {
    card.addEventListener('click', function (e) {
      const ava = e.target.closest('.pf-ava');
      if (ava) {
        e.stopPropagation();
        pickAva(ava.getAttribute('data-who'), card);
        return;
      }

      if (e.target.closest('[data-k]')) {
        e.stopPropagation();
        return;
      }

      if (card.classList.contains('pf-plain')) return;
      card.classList.toggle('flip');
    });
  }

  function redraw(card) {
    card.classList.remove('flip');
    card.innerHTML = '<div class=' + Q + 'pf-in' + Q + '>' + front() + back() + '</div>';
    bindInner(card);
  }

  window.Profile = {
    html: function (plain) {
      const cls = plain ? 'pf pf-plain' : 'pf';
      return '<section class=' + Q + cls + Q + ' data-key=' + Q + 'profile' + Q + '>' +
        '<div class=' + Q + 'pf-in' + Q + '>' + front() + back() + '</div></section>';
    },
    bind: function (root) {
      if (!root) return;
      const card = root.classList && root.classList.contains('pf')
        ? root
        : root.querySelector('.pf');
      if (!card) return;
      bindOnce(card);
      bindInner(card);
    }
  };
})();
