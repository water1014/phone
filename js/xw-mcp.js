/* xw-mcp.js · 连线页（MCP） */
(function () {
  'use strict';

  var D = document;

  var PROVIDERS = [
    { id: 'deepseek', name: 'DeepSeek' },
    { id: 'opencode', name: 'OpenCode Go' },
    { id: 'openai', name: 'OpenAI 兼容' }
  ];

  function esc(t) {
    if (window.UI && UI.esc) return UI.esc(t);
    var s = String(t == null ? '' : t);
    s = s.split('&').join('&amp;');
    s = s.split('<').join('&lt;');
    s = s.split('>').join('&gt;');
    return s;
  }

  function hostOf(url) {
    var s = String(url || '');
    var i = s.indexOf('//');
    if (i >= 0) s = s.slice(i + 2);
    return s.split('/')[0] || '';
  }

  function dot(kind) {
    return '<i class="xw-dot ' + kind + '"></i>';
  }

  function item(key, value, kind, sub, extra) {
    return '<div class="xw-item">' +
        '<div class="xw-k">' + esc(key) + '</div>' +
        '<div class="xw-v">' + esc(value) + dot(kind) + '</div>' +
        (sub ? '<div class="xw-sub">' + esc(sub) + '</div>' : '') +
        (extra || '') +
      '</div>';
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

      var sub = (model || '没填模型') + (url ? ' · ' + hostOf(url) : '');

      out += item(p.name, word, kind, sub);
    });

    return out;
  }

  function cloudBlock() {
    var c = (window.XWCloud && XWCloud.cfg) ? XWCloud.cfg() : { ok: false, url: '' };

    if (c.ok) {
      return item('Supabase', '接上了', 'ok', hostOf(c.url),
        '<button type="button" class="xw-tap" id="xw-mcp-ping">试一下这条线</button>');
    }

    return item('Supabase', '还没填', 'off', '去记忆页的「云端备份」里填 URL 和 key');
  }

  function view() {
    var st = XW.S || {};
    var mem = Array.isArray(st.notes) ? st.notes.length : 0;
    var apps = (window.Apps && Apps.ALL) ? Apps.ALL.length : 0;

    return '<header class="hero">' +
        '<span class="kicker">CONNECTIONS</span>' +
        '<h1 class="hero-title">连线</h1>' +
        '<div class="hero-sub">这个家伸出去的几条线</div>' +
      '</header>' +

      '<div class="xw-sec"><div class="xw-list">' + providerBlock() + '</div></div>' +

      '<div class="xw-sec"><div class="xw-list">' + cloudBlock() + '</div></div>' +

      '<div class="xw-sec"><div class="xw-list">' +
        item('天气', '按需取', 'ok', 'wttr.in · 打开天气页才去问一次') +
        item('标题字体', '接好了', 'ok', 'fonts.loli.net · Cormorant Garamond') +
        item('这个家', '在线', 'ok', location.host + ' · ' + apps + ' 个格子') +
      '</div></div>' +

      '<div class="xw-foot">' +
        '<b>钥匙都放在这台手机上。</b><br>' +
        '模型的 key、云端的 key，存在这个浏览器里；清缓存会丢。<br>' +
        'GitHub 的 token 不在这里，它在 Operit 的 mcp_config.json 里。' +
      '</div>' +

      '<div class="xw-who">记忆 ' + mem + ' 条 · 会话 ' + esc(String(st.sessionId || '—').slice(-8)) + '</div>';
  }

  function bind() {
    var btn = D.getElementById('xw-mcp-ping');
    if (!btn) return;

    btn.addEventListener('click', function () {
      if (!window.XWCloud) return;

      var old = btn.textContent;
      btn.disabled = true;
      btn.textContent = '连着…';

      XWCloud.ping()
        .then(function () {
          btn.textContent = '通了';
          setTimeout(function () { btn.textContent = old; btn.disabled = false; }, 1600);
        })
        .catch(function (e) {
          btn.textContent = '不通：' + (e && e.message ? e.message : '未知');
          setTimeout(function () { btn.textContent = old; btn.disabled = false; }, 2600);
        });
    });
  }

  window.Pages = window.Pages || {};
  window.Pages.mcp = view;
  window.Pages.mcpBind = bind;
})();
