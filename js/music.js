/* music.js · 音乐这间（接在 pages.js 之后加载，只往 Pages 上挂两件） */
(function () {
  const D = document;

  function esc(text) {
    if (window.UI && UI.esc) return UI.esc(text);
    return String(text == null ? '' : text).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  function findNow(list) {
    const id = Number(XW.S.nowSong) || 0;
    if (!id) return null;
    for (let i = 0; i < list.length; i++) {
      if (Number(list[i].id) === id) return list[i];
    }
    return null;
  }

  function music() {
    const list = Array.isArray(XW.S.songs) ? XW.S.songs : [];
    const now = findNow(list);

    const sub = list.length
      ? '共 ' + list.length + ' 首' + (now ? ' · 现在在听《' + now.title + '》' : ' · 还没挑哪首在听')
      : '还没加过歌。';

    const nowBlock = now
      ? '<section class="sheet now-card">' +
          '<div class="now-head">' +
            '<span class="kicker">NOW PLAYING</span>' +
            '<span class="now-artist">' + (now.artist ? esc(now.artist) : '—') + '</span>' +
          '</div>' +
          '<div class="now-title">' + esc(now.title) + '</div>' +
          '<div class="now-note">只是把名字摆在这儿，不假装有声音。</div>' +
        '</section>'
      : '';

    const rows = list.slice().reverse().map(function (song) {
      const on = Number(song.id) === Number(XW.S.nowSong);
      return '<article class="song-row' + (on ? ' on' : '') + '">' +
          '<button type="button" class="song-main" data-now="' + song.id + '">' +
            '<span class="song-name">' + esc(song.title) + '</span>' +
            '<span class="song-artist">' + (song.artist ? esc(song.artist) : '没写歌手') + '</span>' +
          '</button>' +
          (on ? '<span class="song-flag">在听</span>' : '<span class="song-hint">点一下换这首</span>') +
          '<button type="button" class="song-del" data-sd="' + song.id + '" aria-label="删掉">×</button>' +
        '</article>';
    }).join('');

    const body = list.length
      ? '<div class="album-date-band">歌单</div><div class="song-list">' + rows + '</div>'
      : '<div class="empty-state" style="margin-top:1rem">这里还空着。<br>加一首你们最近在听的就成。</div>';

    return Pages.hero('MUSIC', '音乐', sub) +
      '<section class="sheet">' +
        '<div class="sheet-head"><span class="sheet-title">加一首</span></div>' +
        '<label class="field song-field"><span>歌名</span>' +
          '<input id="song-title" type="text" placeholder="写歌名">' +
        '</label>' +
        '<label class="field song-field"><span>歌手</span>' +
          '<input id="song-artist" type="text" placeholder="可以不写">' +
        '</label>' +
        '<div class="row-actions">' +
          '<button type="button" id="song-add" class="btn-solid">加进来</button>' +
        '</div>' +
        '<div class="sheet-note">只存歌名和歌手，不放音频——没有版权，也不假装能放。</div>' +
      '</section>' +
      nowBlock + body;
  }

  function musicBind(bodyEl) {
    const titleEl = D.getElementById('song-title');
    const artistEl = D.getElementById('song-artist');
    const addEl = D.getElementById('song-add');

    if (addEl && titleEl) {
      addEl.addEventListener('click', function () {
        const title = (titleEl.value || '').trim();
        const artist = (artistEl && artistEl.value || '').trim();
        if (!title) { UI.toast('歌名还没写'); return; }

        XW.S.songs = Array.isArray(XW.S.songs) ? XW.S.songs : [];
        const id = Date.now();
        XW.S.songs.push({ id: id, title: title, artist: artist, t: id });
        XW.save('songs');

        if (!Number(XW.S.nowSong)) {
          XW.S.nowSong = id;
          XW.save('nowSong');
        }

        UI.toast('加上了');
        window.Router.reopen('music');
      });
    }

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-now]'), function (btn) {
      btn.addEventListener('click', function () {
        XW.S.nowSong = Number(btn.dataset.now);
        XW.save('nowSong');
        window.Router.reopen('music');
      });
    });

    Array.prototype.forEach.call(bodyEl.querySelectorAll('[data-sd]'), function (btn) {
      btn.addEventListener('click', function () {
        const id = Number(btn.dataset.sd);
        XW.S.songs = (Array.isArray(XW.S.songs) ? XW.S.songs : []).filter(function (s) {
          return Number(s.id) !== id;
        });
        XW.save('songs');
        if (Number(XW.S.nowSong) === id) {
          XW.S.nowSong = XW.S.songs.length ? Number(XW.S.songs[XW.S.songs.length - 1].id) : 0;
          XW.save('nowSong');
        }
        UI.toast('删了');
        window.Router.reopen('music');
      });
    });
  }

  window.Pages = window.Pages || {};
  window.Pages.music = music;
  window.Pages.musicBind = musicBind;
})();
