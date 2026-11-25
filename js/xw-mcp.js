/* xw-mcp.js · 连线页（MCP）v2 */
(function () {
  'use strict';

  var D = document;
  var DAY = 86400000;

  var PROVIDERS = [
    { id: 'deepseek', name: 'DeepSeek' },
    { id: 'opencode', name: 'OpenCode Go' },
    { id: 'openai', name: 'OpenAI 兼容' }
  ];

  var BUILTIN = { chat: 1, settings: 1 };

  function esc(t) {
    if (window.UI && UI.esc) return UI.esc(t);
    var s = String(t == null ? '' : t);
    s = s.split('&').join('&amp;');
    s = s.split('<').join('&lt;');
    s = s.split('>').join('&gt;');
    return s;
  }

  function stripSlash(u) {
    var s = String(u || '');
    while (s.length && s.charAt(s.length - 1) === '/') s = s.slice(0, -1);
    return s;
  }

  function hostOf(url) {
    var s = String(url || '').trim();
    var i = s.indexOf('//');
    if (i >= 0) s = s.slice(i + 2);
    return s.split('/')[0] || '';
  }

  function n(v) { return Array.isArray(v) ? v.length : 0; }

  function daysTogether() {
    var raw = (XW.S && XW.S.loveDate) || '';
    if (!raw) return 0;
    var d = new Date(raw);
    if (isNaN(d.getTime())) return 0;
    return Math.max(0, Math.floor((Date.now() - d.getTime()) / DAY));
  }

  function dot(kind) { return '<i class="xw-dot ' + kind + '"></i>'; }

  function item(html, key, value, kind, sub, extra) {
    return '<div class="xw-item">' +
        '<div class="xw-k">' + esc(key) + '</div>' +
        '<div class="xw-v">' + esc(value) + dot(kind) + '</div>' +
        (sub ? '<div class="xw-sub">' + esc(sub) + '</div>' : '') +
        (extra || '') +
      '</div>';
  }

  function statsBar() {
    var st = XW.S || {};

    var cells = [
      ['天', daysTogether()],
      ['记忆', n(st.notes)],
      ['日记', n(st.diary)],
      ['照片', n(st.photos)],
      ['消息', n(st.chat)]
    ];

    var out = '';
    cells.forEach(function (c) {
      out += '<div><b>' + c[1] + '</b><span>' + c[0] + '</span></div>';
    });

    return '<div class="xw-stats">' + out + '</div>';
  }

  function providerBlock() {
    var st = XW.S || {};
    var pf = st.profiles || {};
    var out = '';

    PROVIDERS.forEach(function (p) {
      var one = pf[p.id] || {};
      var url = String(one.url || '').trim();
      var model = String(one.model || '').trim();
      var key = String(one.key || '').trim();

      var kind = 'off';
      var word = '没接';

      if (url && key) { kind = 'ok'; word = '接好了'; }
      else if (url) { kind = 'warn'; word = '缺钥匙'; }

      var sub = (model || '没填模型') + (url ? ' · ' + hostOf(url) : '') +
        (key ? ' · 钥匙 ' + key.length + ' 位' : '');

      var extra = url
        ? '<button type="button" class="xw-tap" id="xw-probe-' + p.id + '">测一下</button>'
        : '';

      out += '<div class="xw-item" id="xw-row-' + p.id + '">' +
          '<div class="xw-k">' + esc(p.name) + '</div>' +
          '<div class="xw-v" id="xw-state-' + p.id + '">' + esc(word) + dot(kind) + '</div>' +
          '<div class="xw-sub">' + esc(sub) + '</div>' +
          extra +
        '</div>';
    });

    return out;
  }

  function cloudBlock() {
    var c = (window.XWCloud && XWCloud.cfg) ? XWCloud.cfg() : { ok: false, url: '' };

    if (c.ok) {
      return '<div class="xw-item">' +
          '<div class="xw-k">Supabase</div>' +
          '<div class="xw-v" id="xw-state-cloud">接上了' + dot('ok') + '</div>' +
          '<div class="xw-sub">' + esc(hostOf(c.url)) + '</div>' +
          '<button type="button" class="xw-tap" id="xw-probe-cloud">试一下这条线</button>' +
        '</div>';
    }

    return item('', 'Supabase', '还没填', 'off',
      '去记忆页的「云端备份」里填 URL 和 key');
  }

  function gateBlock() {
    if (!window.Apps) return '';

    var open = [];
    var shut = [];

    Apps.ALL.forEach(function (a) {
      var has = BUILTIN[a.id] || (window.Pages && typeof window.Pages[a.id] === 'function');
      if (has) open.push(a); else shut.push(a);
    });

    var html = '<div class="xw-gates">';

    open.forEach(function (a) {
      html += '<span class="xw-gate on">' + esc(a.name) + '</span>';
    });

    shut.forEach(function (a) {
      html += '<span class="xw-gate">' + esc(a.name) + '</span>';
    });

    html += '</div>';

    return html;
  }

  function view() {
    var st = XW.S || {};
    var apps = (window.Apps && Apps.ALL) ? Apps.ALL.length : 0;

    return '<header class="hero">' +
        '<span class="kicker">CONNECTIONS</span>' +
        '<h1 class="hero-title">连线</h1>' +
        '<div class="hero-sub">这个家伸出去的几条线</div>' +
      '</header>' +

      statsBar() +

      '<div class="xw-sec">' +
        '<div class="xw-hd"><em>说话</em></div>' +
        '<div class="xw-list">' + providerBlock() + '</div>' +
      '</div>' +

      '<div class="xw-sec">' +
        '<div class="xw-hd"><em>记忆</em></div>' +
        '<div class="xw-list">' + cloudBlock() + '</div>' +
      '</div>' +

      '<div class="xw-sec">' +
        '<div class="xw-hd"><em>别处</em></div>' +
        '<div class="xw-list">' +
          item('', '天气', '按需取', 'ok', 'wttr.in · 打开天气页才去问一次') +
          item('', '标题字体', '接好了', 'ok', 'fonts.loli.net · Cormorant Garamond') +
          item('', '这个家', '在线', 'ok', location.host + ' · ' + apps + ' 个格子') +
        '</div>' +
      '</div>' +

      '<div class="xw-sec">' +
        '<div class="xw-hd"><em>门</em><em>亮的能进，灰的还没开</em></div>' +
        gateBlock() +
      '</div>' +

      '<div class="xw-foot">' +
        '<b>钥匙都放在这台手机上。</b><br>' +
        '模型的 key、云端的 key，存在这个浏览器里；清缓存会丢。<br>' +
        'GitHub 的 token 不在这里，它在 Operit 的 mcp_config.json 里。' +
      '</div>' +

      '<div class="xw-who">会话 ' + esc(String(st.sessionId || '—').slice(-10)) + '</div>';
  }

  /* ── 测：GET /models，不花额度 ── */
  function probe(base, key, sid) {
    var url = stripSlash(base);
    if (!url) return Promise.resolve({ code: -2 });

    var headers = {};
    if (key) headers.Authorization = 'Bearer ' + key;
    if (sid) headers['x-opencode-session'] = sid;

    var opt = { headers: headers, cache: 'no-store' };
    var ctl = null;

    try {
      ctl = new AbortController();
      opt.signal = ctl.signal;
    } catch (e) {}

    var timer = setTimeout(function () {
      if (ctl) { try { ctl.abort(); } catch (e) {} }
    }, 7000);

    return fetch(url + '/models', opt)
      .then(function (r) { clearTimeout(timer); return { code: r.status }; })
      .catch(function () { clearTimeout(timer); return { code: -1 }; });
  }

  function verdict(code) {
    if (code === 200) return { kind: 'ok', word: '通' };
    if (code === 401 || code === 403) return { kind: 'warn', word: '钥匙不对' };
    if (code === 404 || code === 405) return { kind: 'warn', word: '地址通，没这个接口' };
    if (code === -1) return { kind: 'off', word: '连不到' };
    if (code === -2) return { kind: 'off', word: '没填地址' };
    return { kind: 'warn', word: 'HTTP ' + code };
  }

  function paint(el, v) {
    if (!el) return;
    el.innerHTML = esc(v.word) + dot(v.kind);
  }

  function bind() {
    var st = XW.S || {};
    var pf = st.profiles || {};
    var sid = st.sessionId || '';

    PROVIDERS.forEach(function (p) {
      var btn = D.getElementById('xw-probe-' + p.id);
      var out = D.getElementById('xw-state-' + p.id);
      if (!btn) return;

      var one = pf[p.id] || {};

      btn.addEventListener('click', function () {
        btn.disabled = true;
        btn.textContent = '测着…';

        probe(one.url, one.key, sid).then(function (r) {
          var v = verdict(r.code);
          paint(out, v);
          btn.textContent = v.word;
          setTimeout(function () {
            btn.disabled = false;
            btn.textContent = '再测一次';
          }, 2200);
        });
      });
    });

    var cb = D.getElementById('xw-probe-cloud');
    var co = D.getElementById('xw-state-cloud');

    if (cb && window.XWCloud) {
      cb.addEventListener('click', function () {
        cb.disabled = true;
        cb.textContent = '连着…';

        XWCloud.ping()
          .then(function () {
            paint(co, { kind: 'ok', word: '接上了' });
            cb.textContent = '通了';
          })
          .catch(function (e) {
            paint(co, { kind: 'off', word: '不通' });
            cb.textContent = '不通：' + (e && e.message ? e.message : '未知');
          })
          .then(function () {
            setTimeout(function () {
              cb.disabled = false;
              cb.textContent = '再试一次';
            }, 2400);
          });
      });
    }
  }

  window.Pages = window.Pages || {};
  window.Pages.mcp = view;
  window.Pages.mcpBind = bind;
})();
