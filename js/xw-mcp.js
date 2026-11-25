/* xw-mcp.js · MCP 连接器 v3 */
(function () {
  'use strict';

  var D = document;
  var KEY = 'xw_mcp_servers';

  var DEF = [
    { name: '小红书', type: 'streamable_http', url: 'http://127.0.0.1:18061/mcp', on: true },
    { name: 'GitHub', type: 'streamable_http', url: '', on: false }
  ];

  function esc(t) {
    if (window.UI && UI.esc) return UI.esc(t);
    var s = String(t == null ? '' : t);
    s = s.split('&').join('&amp;');
    s = s.split('<').join('&lt;');
    s = s.split('>').join('&gt;');
    return s;
  }

  function load() {
    var raw = null;
    try { raw = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) { raw = null; }
    if (!Array.isArray(raw)) raw = DEF.slice();
    return raw;
  }

  function save(list) {
    try { localStorage.setItem(KEY, JSON.stringify(list)); } catch (e) {}
  }

  function jsonOf(list) {
    var obj = { mcpServers: {} };
    list.forEach(function (s) {
      if (!s.on || !s.url) return;
      obj.mcpServers[s.name] = { type: s.type, url: s.url };
    });
    return JSON.stringify(obj, null, 2);
  }

  function node(s, i) {
    var has = !!s.url;

    return '<div class="xw-node">' +
        '<div class="xw-node-top">' +
          '<span class="xw-node-name">' + esc(s.name) + '</span>' +
          '<span class="xw-node-type">' + esc(s.type) + '</span>' +
          '<button type="button" class="xw-switch' + (s.on ? ' on' : '') + '" data-act="sw" data-i="' + i + '" aria-label="开关"></button>' +
        '</div>' +
        '<div class="xw-node-url' + (has ? '' : ' empty') + '">' + esc(has ? s.url : '还没填地址') + '</div>' +
        '<div class="xw-node-acts">' +
          (has ? '<button type="button" class="xw-tap" data-act="test" data-i="' + i + '">测一下</button>' : '') +
          '<button type="button" class="xw-tap quiet" data-act="del" data-i="' + i + '">删掉</button>' +
        '</div>' +
      '</div>';
  }

  function view() {
    var list = load();
    var on = list.filter(function (s) { return s.on && s.url; }).length;

    var nodes = '';
    list.forEach(function (s, i) { nodes += node(s, i); });

    if (!list.length) {
      nodes = '<div class="xw-intro">一个都没有。下面加一个。</div>';
    }

    return '<header class="hero">' +
        '<span class="kicker">MCP</span>' +
        '<h1 class="hero-title">连接器</h1>' +
        '<div class="hero-sub">给模型装的手 · ' + on + ' / ' + list.length + ' 接着</div>' +
      '</header>' +

      '<div class="xw-intro">' +
        'MCP 是 <b>Model Context Protocol</b>。一个连接器就是一个外部工具服务，' +
        '接上之后模型能读它、用它。开关只管这份清单；真正让它们跑起来的，是 Operit 的 mcp_config.json。' +
      '</div>' +

      '<div class="xw-chain" id="xw-mcp-body">' + nodes + '</div>' +

      '<button type="button" class="xw-add" id="xw-mcp-add">＋ 加一个连接器</button>' +

      '<div class="xw-form" id="xw-mcp-form">' +
        '<input id="xw-f-name" placeholder="名字，比如 小红书" autocomplete="off">' +
        '<input id="xw-f-url" placeholder="地址，比如 http://127.0.0.1:18061/mcp" autocomplete="off" inputmode="url">' +
        '<select id="xw-f-type">' +
          '<option value="streamable_http">streamable_http（现在惯用）</option>' +
          '<option value="remote">remote（旧写法）</option>' +
          '<option value="sse">sse</option>' +
        '</select>' +
        '<div class="xw-row">' +
          '<button type="button" class="xw-tap" id="xw-f-save">存下来</button>' +
          '<button type="button" class="xw-tap quiet" id="xw-f-cancel">算了</button>' +
        '</div>' +
      '</div>' +

      '<div class="xw-json">' +
        '<div class="xw-intro" style="margin:0">粘进 mcp_config.json 的那段（只算开着的）</div>' +
        '<pre id="xw-mcp-json"></pre>' +
        '<button type="button" class="xw-tap" id="xw-mcp-copy">复制这段</button>' +
      '</div>' +

      '<div class="xw-foot">' +
        '<b>两条实话。</b><br>' +
        '一、这份清单存在这个浏览器里，只是给你自己看和抄的，不会去改 Operit 里的文件。<br>' +
        '二、在 https 页面上测 http://127.0.0.1 这种地址，浏览器会直接拦住，测不出来不代表它没跑。' +
      '</div>';
  }

  function pick(el) {
    while (el && el !== D) {
      if (el.getAttribute && el.getAttribute('data-act')) return el;
      el = el.parentNode;
    }
    return null;
  }

  function rerender() {
    if (window.Router && Router.reopen) Router.reopen('mcp');
  }

  function bind() {
    var body = D.getElementById('xw-mcp-body');
    var jsonEl = D.getElementById('xw-mcp-json');

    if (jsonEl) jsonEl.textContent = jsonOf(load());

    if (body) {
      body.addEventListener('click', function (e) {
        var t = pick(e.target);
        if (!t) return;

        var act = t.getAttribute('data-act');
        var i = Number(t.getAttribute('data-i'));
        var list = load();
        if (!list[i]) return;

        if (act === 'sw') {
          list[i].on = !list[i].on;
          save(list);
          rerender();
          return;
        }

        if (act === 'del') {
          list.splice(i, 1);
          save(list);
          rerender();
          return;
        }

        if (act === 'test') {
          var url = list[i].url;
          if (!url) return;

          var old = t.textContent;
          t.disabled = true;
          t.textContent = '测着…';

          fetch(url, { method: 'GET', mode: 'no-cors', cache: 'no-store' })
            .then(function () { t.textContent = '地址能通'; })
            .catch(function () { t.textContent = '连不到'; })
            .then(function () {
              setTimeout(function () {
                t.disabled = false;
                t.textContent = old;
              }, 2400);
            });
        }
      });
    }

    var add = D.getElementById('xw-mcp-add');
    var form = D.getElementById('xw-mcp-form');

    if (add && form) {
      add.addEventListener('click', function () {
        form.classList.toggle('on');
        if (form.classList.contains('on')) {
          var f = D.getElementById('xw-f-name');
          if (f) setTimeout(function () { f.focus(); }, 60);
        }
      });
    }

    var cancel = D.getElementById('xw-f-cancel');
    if (cancel && form) {
      cancel.addEventListener('click', function () { form.classList.remove('on'); });
    }

    var saveBtn = D.getElementById('xw-f-save');
    if (saveBtn) {
      saveBtn.addEventListener('click', function () {
        var name = String(D.getElementById('xw-f-name').value || '').trim();
        var url = String(D.getElementById('xw-f-url').value || '').trim();
        var type = D.getElementById('xw-f-type').value;

        if (!name) {
          if (window.UI && UI.toast) UI.toast('名字还没填');
          return;
        }

        var list = load();
        list.push({ name: name, type: type, url: url, on: !!url });
        save(list);
        rerender();
      });
    }

    var copy = D.getElementById('xw-mcp-copy');
    if (copy) {
      copy.addEventListener('click', function () {
        var text = jsonOf(load());
        var done = function () {
          var o = copy.textContent;
          copy.textContent = '复制好了';
          setTimeout(function () { copy.textContent = o; }, 1600);
        };

        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(done).catch(function () { fallback(text, done); });
        } else {
          fallback(text, done);
        }
      });
    }
  }

  function fallback(text, done) {
    var ta = D.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    D.body.appendChild(ta);
    ta.select();
    try { D.execCommand('copy'); } catch (e) {}
    if (ta.parentNode) ta.parentNode.removeChild(ta);
    done();
  }

  window.Pages = window.Pages || {};
  window.Pages.mcp = view;
  window.Pages.mcpBind = bind;
})();
