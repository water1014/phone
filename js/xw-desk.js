/* xw-desk.js v2 · 首页 + 底栏 + 侧栏 */
(function () {
  'use strict';

  var D = document;
  var DAY = 86400000;
  var done = false;

  function esc(t) {
    var s = String(t == null ? '' : t);
    s = s.split('&').join('&amp;');
    s = s.split('<').join('&lt;');
    s = s.split('>').join('&gt;');
    return s;
  }

  function n(v) { return Array.isArray(v) ? v.length : 0; }

  function days() {
    var raw = (XW.S && XW.S.loveDate) || '';
    if (!raw) return 0;
    var d = new Date(raw);
    if (isNaN(d.getTime())) return 0;
    return Math.max(0, Math.floor((Date.now() - d.getTime()) / DAY));
  }

  function pad2(v) { return ('0' + v).slice(-2); }

  var WD = ['日', '一', '二', '三', '四', '五', '六'];

  var ICON = {
    home: '<svg viewBox="0 0 24 24"><path d="M4 10.5 12 4l8 6.5V20H4z"/><path d="M9.5 20v-5.5h5V20"/></svg>',
    chat: '<svg viewBox="0 0 24 24"><path d="M4 6.5A2 2 0 0 1 6 4.5h12a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-7.5L7 19v-3.5H6a2 2 0 0 1-2-2z"/></svg>',
    diary: '<svg viewBox="0 0 24 24"><path d="M6 4.5h11a1.5 1.5 0 0 1 1.5 1.5v14H6z"/><path d="M6 4.5A1.5 1.5 0 0 0 4.5 6v13"/><path d="M9.5 9h6"/><path d="M9.5 13h4"/></svg>',
    settings: '<svg viewBox="0 0 24 24"><path d="M4.5 8.5h4"/><path d="M13 8.5h6.5"/><path d="M10.5 6.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z"/><path d="M4.5 15.5h4"/><path d="M13 15.5h6.5"/><path d="M16.5 13.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z"/></svg>',
    memory: '<svg viewBox="0 0 24 24"><path d="M7 4h10v16l-5-3.5-5 3.5z"/></svg>',
    album: '<svg viewBox="0 0 24 24"><path d="M4.5 5.5h15v13h-15z"/><path d="M15 15l-3.5-3.5L6.5 16.5"/></svg>',
    star: '<svg viewBox="0 0 24 24"><path d="M12 4.5l2.2 4.9 5.3.5-4 3.6 1.2 5.2L12 16l-4.7 2.7 1.2-5.2-4-3.6 5.3-.5z"/></svg>'
  };

  var DOCK = [
    { id: 'home', name: '首页' },
    { id: 'chat', name: '聊天' },
    { id: 'diary', name: '日记' },
    { id: 'settings', name: '设置' }
  ];

  var FALLBACK = [
    { id: 'chat', name: '聊天' },
    { id: 'album', name: '相册' },
    { id: 'memory', name: '记忆库' },
    { id: 'diary', name: '日记' },
    { id: 'music', name: '音乐' },
    { id: 'mcp', name: 'MCP' },
    { id: 'beautify', name: '美化' },
    { id: 'settings', name: '设置' }
  ];

  function avatar() {
    try { return localStorage.getItem('xw_ava_his') || ''; } catch (e) { return ''; }
  }

  function photos() {
    var p = (XW.S && XW.S.photos) || [];
    return Array.isArray(p) ? p.slice(-3).reverse() : [];
  }

  function lastChat() {
    var c = (XW.S && XW.S.chat) || [];
    if (!Array.isArray(c) || !c.length) return [];
    return c.slice(-3).reverse();
  }

  function bio() {
    return (XW.S && XW.S.bio) || '在这里，记录我们共同创造的日子。';
  }

  function quote() {
    return (XW.S && XW.S.quote) || 'Dos almas no se encuentran por casualidad.';
  }

  function apps() {
    var L = null;
    if (window.Apps) L = Apps.LIST || Apps.list || null;
    if (!Array.isArray(L) || !L.length) L = FALLBACK;
    return L;
  }

  function build() {
    var st = XW.S || {};
    var now = new Date();
    var clock = pad2(now.getHours()) + ':' + pad2(now.getMinutes());
    var ymd = now.getFullYear() + '年' + (now.getMonth() + 1) + '月' + now.getDate() + '日';
    var wd = '星期' + WD[now.getDay()];

    var av = avatar();
    var avStyle = av ? ' style="background-image:url(' + av + ')"' : '';

    var hisName = (st.hisName && st.hisName !== '他') ? st.hisName : '宋祁';
    var herName = (st.herName && st.herName !== '她') ? st.herName : '淼淼';

    var ps = photos();
    var th = '';
    if (ps.length) {
      ps.forEach(function (u) { th += '<i style="background-image:url(' + u + ')"></i>'; });
    } else {
      th = '<i></i><i></i><i></i>';
    }

    var chat = lastChat();
    var chatLi = '';
    if (chat.length) {
      chat.forEach(function (m) {
        var t = String(m.text || m.content || '').replace(/\s+/g, ' ').slice(0, 16);
        chatLi += '<div class="xd-li"><i></i><span>' + esc(t) + '</span><em>' + esc(String(m.time || '').slice(-5)) + '</em></div>';
      });
    } else {
      chatLi = '<div class="xd-li"><i></i><span>还没有消息</span><em></em></div>';
    }

    var h = [];

    h.push('<div class="xd-top">');
    h.push('<button type="button" class="xd-burger" id="xd-open-rail" aria-label="所有门"><i></i><i></i><i></i></button>');
    h.push('<div class="xd-head"><div class="xd-clock">' + clock + '</div></div>');
    h.push('<div class="xd-date">' + ymd + '<br>' + wd + '</div>');
    h.push('</div>');

    h.push('<section class="xd-card xd-id">');
    h.push('<div class="xd-ava"' + avStyle + '></div>');
    h.push('<div class="xd-idmain">');
    h.push('<div class="xd-name">' + esc(hisName) + ' & ' + esc(herName) + '<i>✓</i></div>');
    h.push('<div class="xd-handle">@xiaowo</div>');
    h.push('<p class="xd-bio">' + esc(bio()) + '</p>');
    h.push('<div class="xd-see">第 ' + days() + ' 天 · 从 ' + esc(String(st.loveDate || '—')) + ' 开始</div>');
    h.push('</div>');
    h.push('</section>');

    h.push('<div class="xd-stats">');
    h.push('<div><b>' + days() + '</b><span>天</span></div>');
    h.push('<div><b>' + n(st.notes) + '</b><span>记忆</span></div>');
    h.push('<div><b>' + n(st.diary) + '</b><span>日记</span></div>');
    h.push('<div><b>' + n(st.photos) + '</b><span>照片</span></div>');
    h.push('</div>');

    h.push('<div class="xd-2">');
    h.push('<div class="xd-card"><div class="xd-k">WEATHER</div>');
    h.push('<b class="xd-big" id="xd-wx">--°</b>');
    h.push('<div class="xd-sub" id="xd-wxs">去天气页看一眼</div></div>');
    h.push('<div class="xd-card"><div class="xd-k">MESSAGES</div>');
    h.push(chatLi);
    h.push('</div>');
    h.push('</div>');

    h.push('<section class="xd-card xd-hero">');
    h.push('<p class="xd-quote">' + esc(quote()) + '</p>');
    h.push('<p class="xd-qs">两个人不会随随便便就遇见的。</p>');
    h.push('<div class="xd-thumbs">' + th + '</div>');
    h.push('</section>');

    return '<div class="xd-page">' + h.join('') + '</div>';
  }

  function buildDock() {
    var old = D.getElementById('xd-dock');
    if (old) old.parentNode.removeChild(old);

    var el = D.createElement('div');
    el.id = 'xd-dock';

    var s = '';
    DOCK.forEach(function (it) {
      s += '<button type="button" data-go="' + it.id + '">' + (ICON[it.id] || '') + '<span>' + it.name + '</span></button>';
    });
    el.innerHTML = s;

    el.addEventListener('click', function (e) {
      var b = e.target;
      while (b && b !== el) {
        var go = b.getAttribute && b.getAttribute('data-go');
        if (go) {
          e.preventDefault();
          if (go === 'home') {
            var hm = D.getElementById('home');
            if (hm) hm.scrollTo({ top: 0, behavior: 'smooth' });
            mark(go);
          } else if (window.Router && Router.open) {
            Router.open(go);
          }
          return;
        }
        b = b.parentNode;
      }
    });

    D.body.appendChild(el);
    mark('home');
  }

  function mark(id) {
    var el = D.getElementById('xd-dock');
    if (!el) return;
    var bs = el.querySelectorAll('button');
    for (var i = 0; i < bs.length; i++) {
      bs[i].className = (bs[i].getAttribute('data-go') === id) ? 'on' : '';
    }
  }

  function buildRail() {
    if (D.getElementById('xd-rail')) return;

    var mask = D.createElement('div');
    mask.id = 'xd-mask';

    var rail = D.createElement('aside');
    rail.id = 'xd-rail';

    var list = apps();
    var s = '';
    s += '<div class="xd-rail-hd"><b>小窝</b><em>OUR SPACE · 所有门</em></div>';
    s += '<div class="xd-rail-list">';
    s += '<button type="button" data-go="home">' + ICON.home + '<span>首页</span><em>HOME</em></button>';
    list.forEach(function (a) {
      if (a.id === 'home') return;
      s += '<button type="button" data-go="' + a.id + '">' + (ICON[a.id] || ICON.star) + '<span>' + esc(a.name) + '</span><em>' + esc(String(a.id).toUpperCase()) + '</em></button>';
    });
    s += '</div>';
    rail.innerHTML = s;

    function close() {
      rail.className = '';
      mask.className = '';
    }

    mask.addEventListener('click', close);

    rail.addEventListener('click', function (e) {
      var b = e.target;
      while (b && b !== rail) {
        var go = b.getAttribute && b.getAttribute('data-go');
        if (go) {
          e.preventDefault();
          close();
          if (go === 'home') {
            var hm = D.getElementById('home');
            if (hm) hm.scrollTo({ top: 0, behavior: 'smooth' });
            mark('home');
          } else if (window.Router && Router.open) {
            Router.open(go);
          }
          return;
        }
        b = b.parentNode;
      }
    });

    D.body.appendChild(mask);
    D.body.appendChild(rail);
  }

  function openRail() {
    var rail = D.getElementById('xd-rail');
    var mask = D.getElementById('xd-mask');
    if (!rail || !mask) return;
    rail.className = 'on';
    mask.className = 'on';
  }

  function bindScroll(home) {
    var dock = D.getElementById('xd-dock');
    if (!dock) return;

    var last = home.scrollTop;
    var ticking = false;

    home.addEventListener('scroll', function () {
      if (ticking) return;
      ticking = true;

      requestAnimationFrame(function () {
        var y = home.scrollTop;
        var dy = y - last;

        if (y < 20) {
          dock.className = '';
        } else if (dy > 4) {
          dock.className = 'hide';
        } else if (dy < -4) {
          dock.className = '';
        }

        last = y;
        ticking = false;
      });
    }, { passive: true });
  }

  function weather() {
    var el = D.getElementById('xd-wx');
    var sub = D.getElementById('xd-wxs');
    if (!el || !sub) return;

    fetch('https://wttr.in/?format=j1', { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (j) {
        var c = j && j.current_condition && j.current_condition[0];
        if (!c) throw new Error('no');
        el.textContent = c.temp_C + '°';
        sub.textContent = (c.weatherDesc && c.weatherDesc[0] && c.weatherDesc[0].value) || '—';
      })
      .catch(function () { sub.textContent = '取不到天气'; });
  }

  function mount() {
    var home = D.getElementById('home');
    if (!home) return;
    if (home.getAttribute('data-xd') === '1') return;

    home.className = 'home xd-home';
    home.setAttribute('data-xd', '1');
    home.innerHTML = build();

    home.addEventListener('click', function (e) {
      if (e.target && e.target.id === 'xd-open-rail') {
        e.preventDefault();
        openRail();
      }
    });

    buildDock();
    buildRail();
    bindScroll(home);
    weather();

    done = true;
  }

  function tick() {
    if (done) return;
    mount();
  }

  var tries = 0;
  var iv = setInterval(function () {
    tries++;
    tick();
    if (done || tries > 40) clearInterval(iv);
  }, 150);

  if (window.MutationObserver && D.body) {
    new MutationObserver(function () {
      if (!done) setTimeout(tick, 30);
    }).observe(D.body, { childList: true, subtree: true });
  }

  setTimeout(tick, 300);
  setTimeout(tick, 900);
  setTimeout(tick, 1800);
})();
