/* xw-desk.js · 首页重搓版
   把 #home 里那套 .gpage/.gi 整块换成新的一屏。
   不动 layout.js / desktop.js，只在它渲染完之后接手。 */
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
    var s = (XW.S && XW.S.bio) || '';
    if (s) return s;
    return '在这里，记录我们共同创造的日子。';
  }

  function quote() {
    var s = (XW.S && XW.S.quote) || '';
    if (s) return s;
    return 'Dos almas no se encuentran por casualidad.';
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

    var html = [];

    html.push('<div class="xd-top">');
    html.push('<div class="xd-clock">' + clock + '</div>');
    html.push('<div class="xd-date">' + ymd + '<br>' + wd + '</div>');
    html.push('</div>');

    html.push('<section class="xd-card xd-id">');
    html.push('<div class="xd-ava"' + avStyle + '></div>');
    html.push('<div class="xd-idmain">');
    html.push('<div class="xd-name">' + esc(hisName) + ' & ' + esc(herName) + '<i>✓</i></div>');
    html.push('<div class="xd-handle">@xiaowo</div>');
    html.push('<p class="xd-bio">' + esc(bio()) + '</p>');
    html.push('<div class="xd-see">第 ' + days() + ' 天 · 从 ' + esc(String(st.loveDate || '—')) + ' 开始</div>');
    html.push('</div>');
    html.push('</section>');

    html.push('<div class="xd-stats">');
    html.push('<div><b>' + days() + '</b><span>天</span></div>');
    html.push('<div><b>' + n(st.notes) + '</b><span>记忆</span></div>');
    html.push('<div><b>' + n(st.diary) + '</b><span>日记</span></div>');
    html.push('<div><b>' + n(st.photos) + '</b><span>照片</span></div>');
    html.push('</div>');

    html.push('<div class="xd-2">');
    html.push('<div class="xd-card">');
    html.push('<div class="xd-k">WEATHER</div>');
    html.push('<b class="xd-big" id="xd-wx">--°</b>');
    html.push('<div class="xd-sub" id="xd-wxs">去天气页看一眼</div>');
    html.push('</div>');
    html.push('<div class="xd-card">');
    html.push('<div class="xd-k">MESSAGES</div>');
    html.push(chatLi);
    html.push('</div>');
    html.push('</div>');

    html.push('<section class="xd-card xd-hero">');
    html.push('<p class="xd-quote">' + esc(quote()) + '</p>');
    html.push('<p class="xd-qs">两个人不会随随便便就遇见的。</p>');
    html.push('<div class="xd-thumbs">' + th + '</div>');
    html.push('</section>');

    html.push('<div class="xd-4">');
    html.push('<button type="button" data-go="chat"><svg viewBox="0 0 24 24"><path d="M4 6.5A2 2 0 0 1 6 4.5h12a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-7.5L7 19v-3.5H6a2 2 0 0 1-2-2z"/></svg><span>聊天</span></button>');
    html.push('<button type="button" data-go="memory"><svg viewBox="0 0 24 24"><path d="M7 4h10v16l-5-3.5-5 3.5z"/></svg><span>记忆</span></button>');
    html.push('<button type="button" data-go="album"><svg viewBox="0 0 24 24"><path d="M4.5 5.5h15v13h-15z"/><path d="M15 15l-3.5-3.5L6.5 16.5"/></svg><span>相册</span></button>');
    html.push('<button type="button" data-go="settings"><svg viewBox="0 0 24 24"><path d="M4.5 8.5h4.5"/><path d="M13 8.5h6.5"/><path d="M10.5 6.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z"/><path d="M4.5 15.5h4.5"/><path d="M13 15.5h6.5"/><path d="M16.5 13.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z"/></svg><span>设置</span></button>');
    html.push('</div>');

    return '<div class="xd-page">' + html.join('') + '</div>';
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
      var el = e.target;
      while (el && el !== home) {
        var go = el.getAttribute && el.getAttribute('data-go');
        if (go) {
          e.preventDefault();
          if (window.Router && Router.open) Router.open(go);
          return;
        }
        el = el.parentNode;
      }
    });

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
