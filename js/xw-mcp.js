/* xw-mcp.js · MCP 连接器 v4 */
(function () {
  'use strict';

  var D = document;
  var KEY = 'xw_mcp_servers';
  var LOG = 'xw_mcp_log';

  var DEF = [
    { name: '小红书', kind: '本地插件', url: 'http://127.0.0.1:18061/mcp', on: true },
    { name: 'GitHub', kind: '官方 MCP', url: '', on: false },
    { name: '天气', kind: '开放接口', url: 'https://wttr.in', on: true },
    { name: 'Supabase', kind: '云端', url: '', on: false }
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
    if (!Array.isArray(raw) || !raw.length) raw = DEF.slice();
    return raw;
  }

  function save(list) {
    try { localStorage.setItem(KEY, JSON.stringify(list)); } catch (e) {}
  }

  function logs() {
    var raw = null;
    try { raw = JSON.parse(localStorage.getItem(LOG) || 'null'); } catch (e) { raw = null; }
    return Array.isArray(raw) ? raw : [];
  }

  function say(text) {
    var list = logs();
    var d = new Date();
    var t = ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2);
    list.unshift({ t: t, text: text });
    if (list.length > 24) list = list.slice(0, 24);
    try { localStorage.setItem(LOG, JSON.stringify(list)); } catch (e) {}
  }

  function card(s, i) {
    var on = !!(s.on && s.url);
    var a = [];

    a.push('<div class="xw-card' + (on ? ' on' : '') + '">');
    a.push('<i class="xw-ring"></i>');
    a.push('<div class="xw-main">');
    a.push('<div class="xw-name">' + esc(s.name) + '</div>');
    a.push('<div class="xw-stat">' + esc(s.kind || (on ? '已接入' : '尚未连接')) + '</div>');
    a.push('</div>');
    a.push('<button type="button" class="xw-act" data-act="open" data-i="' + i + '">' + (on ? '进入' : '连接') + '</button>');
    a.push('</div>');

    a.push('<div class="xw-panel" id="xw-panel-' + i + '">');
    a.push('<input id="xw-name-' + i + '" value="' + esc(s.name) + '" placeholder="名字" autocomplete="off">');
    a.push('<input id="xw-url-' + i + '" value="' + esc(s.url) + '" placeholder="地址" autocomplete="off" inputmode="url">');
    a.push('<div class="xw-row">');
    a.push('<button type="button" class="xw-tap" data-act="save" data-i="' + i + '">存</button>');
    if (s.url) a.push('<button type="button" class="xw-tap" data-act="test" data-i="' + i + '">测一下</button>');
    if (on) a.push('<button type="button" class="xw-tap plain" data-act="off" data-i="' + i + '">断开</button>');
    a.push('<button type="button" class="xw-tap plain" data-act="del" data-i="' + i + '">删掉</button>');
    a.push('</div>');
    a.push('</div>');

    return a.join('');
  }

  function view() {
    var list = load();
    var on = 0;
    var cards = '';
    var logHtml = '';
    var i = 0;

    for (i = 0; i < list.length; i++) {
      if (list[i].on && list[i].url) on++;
      cards += card(list[i], i);
    }

    var lg = logs();
    for (i = 0; i < lg.length; i++) {
      logHtml += '<div class="xw-log-item">' + esc(lg[i].text) + '<i>' + esc(lg[i].t) + '</i></div>';
    }

    if (!logHtml) logHtml = '<div class="xw-log-item">还没有记录。</div>';

    var a = [];
    a.push('<div class="xw-bar">');
    a.push('<button type="button" class="xw-plus" id="xw-mcp-add" aria-label="加一个">＋</button>');
    a.push('</div>');
    a.push('<div>' + cards + '</div>');
    a.push('<details class="xw-log"><summary>调用记录</summary>' + logHtml + '</details>');
    a.push('<div class="xw-foot"><b>' + on + ' 个接着，' + (list.length - on) + ' 个空着。</b><br>');
    a.push('这份名单只在你的浏览器里，不会去改 Operit 里的文件。真要让它们跑起来，还得把地址拄进 mcp_config.json。</div>');

    return a.join('');
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
    var body = D.getElementById('app-body');
    if (!body) return;

    body.addEventListener('click', function (e) {
      var el = e.target;
      var add = null;
      var t = null;

      while (el && el !== D) {
        if (el.id === 'xw-mcp-add') { add = el; break; }
        el = el.parentNode;
      }

      if (add) {
        var fresh = load();
        fresh.push({ name: '新的', kind: '', url: '', on: false });
        save(fresh);
        rerender();
        return;
      }

      t = pick(e.target);
      if (!t) return;

      var act = t.getAttribute('data-act');
      var i = Number(t.getAttribute('data-i'));
      var list = load();
      if (!list[i]) return;

      if (act === 'open') {
        var panel = D.getElementById('xw-panel-' + i);
        if (panel) panel.classList.toggle('on');
        return;
      }

      if (act === 'save') {
        var nm = D.getElementById('xw-name-' + i);
        var ur = D.getElementById('xw-url-' + i);

        list[i].name = String(nm ? nm.value : '').trim() || '没名字';
        list[i].url = String(ur ? ur.value : '').trim();
        if (list[i].url) list[i].on = true;
        if (!list[i].kind) list[i].kind = '自己填的';

        save(list);
        say(String(list[i].name) + ' · 存好了');
        rerender();
        return;
      }

      if (act === 'off') {
        list[i].on = false;
        save(list);
        say(String(list[i].name) + ' · 断开了');
        rerender();
        return;
      }

      if (act === 'del') {
        say(String(list[i].name) + ' · 删掉了');
        list.splice(i, 1);
        save(list);
        rerender();
        return;
      }

      if (act === 'test') {
        var url = list[i].url;
        if (!url) return;

        var old = t.textContent;
        var name = String(list[i].name);
        t.disabled = true;
        t.textContent = '测着…';

        fetch(url, { method: 'GET', mode: 'no-cors', cache: 'no-store' })
          .then(function () {
            say(name + ' · 地址能通');
            t.textContent = '通了';
          })
          .catch(function () {
            say(name + ' · 连不到');
            t.textContent = '连不到';
          })
          .then(function () {
            setTimeout(function () {
              t.disabled = false;
              t.textContent = old;
            }, 2000);
          });
      }
    });
  }

  window.Pages = window.Pages || {};
  window.Pages.mcp = view;
  window.Pages.mcpBind = bind;
})();
