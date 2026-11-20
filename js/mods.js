/* mods.js · 自己搓的小组件
   kind='text'  标题 + 正文
   kind='code'  一栏整段代码，跑在 sandbox iframe 里
   代码里可以用 {{HIS}} {{HER}} {{DAYS}} {{SINCE}} {{TODAY}}，渲染前会换成真值 */
(function () {
  const K = 'xw_mods';

  const HEIGHT = { '90': 90, '140': 140, '200': 200, '280': 280 };

  let list = read();

  function read() {
    try {
      const raw = localStorage.getItem(K);
      const arr = raw ? JSON.parse(raw) : [];
      if (!Array.isArray(arr)) return [];
      return arr.filter(function (m) { return m && m.id; });
    } catch (e) {
      return [];
    }
  }

  function write() {
    try { localStorage.setItem(K, JSON.stringify(list)); } catch (e) {}
  }

  function esc(text) {
    if (window.UI && UI.esc) return UI.esc(text);
    return String(text == null ? '' : text).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  function all() { return list; }

  function find(id) {
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === id) return list[i];
    }
    return null;
  }

  function span(id) {
    const m = find(id);
    if (!m) return '2';
    const v = String(m.span || '2');
    return (v === '1' || v === '2' || v === '4') ? v : '2';
  }

  function height(id) {
    const m = find(id);
    const v = m ? String(m.height || '140') : '140';
    return HEIGHT[v] || 140;
  }

  function pad2(n) { return String(n).padStart(2, '0'); }

  function tokens() {
    const S = (window.XW && XW.S) ? XW.S : {};
    const since = S.loveDate || '2025-01-01';
    const love = new Date(since);
    const now = new Date();

    let days = 0;
    if (window.UI && UI.diffDay) {
      days = UI.diffDay(love, now);
    } else {
      days = Math.max(0, Math.floor((now - love) / 86400000));
    }

    return {
      HIS: S.hisName || '他',
      HER: S.herName || '她',
      DAYS: String(days),
      SINCE: since,
      TODAY: now.getFullYear() + '-' + pad2(now.getMonth() + 1) + '-' + pad2(now.getDate())
    };
  }

  function fill(text) {
    const t = tokens();

    return String(text).replace(/\{\{\s*(HIS|HER|DAYS|SINCE|TODAY)\s*\}\}/g, function (m, k) {
      return t[k] !== undefined ? t[k] : m;
    });
  }

  function wrap(inner) {
    const base = '*{box-sizing:border-box}' +
      'html,body{margin:0;height:100%;background:transparent;' +
      'font-family:-apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;' +
      'color:#3a3733;-webkit-tap-highlight-color:transparent;}' +
      'img{max-width:100%}';

    return '<!DOCTYPE html><html><head><meta charset="utf-8">' +
      '<meta name="viewport" content="width=device-width,initial-scale=1">' +
      '<style>' + base + '</style></head><body>' + inner + '</body></html>';
  }

  function legacyCode(m) {
    const out = [];
    if (m.html) out.push(String(m.html));
    if (m.css) out.push('<style>\n' + m.css + '\n</style>');
    if (m.js) out.push('<script>\n' + m.js + '\n<\/script>');
    return out.join('\n');
  }

  function codeOf(m) {
    if (!m) return '';
    if (m.code) return String(m.code);
    return legacyCode(m);
  }

  function doc(m) {
    if (!m) return wrap('');

    const raw = fill(codeOf(m)).trim();
    if (!raw) return wrap('');

    if (/^\s*(<!doctype|<html)/i.test(raw)) return raw;
    return wrap(raw);
  }

  function html(id) {
    const m = find(id);
    if (!m) return '';

    if (m.kind === 'code') {
      const h = height(id);
      const enc = encodeURIComponent(doc(m));
      return '<div class="mod mod-code" style="height:' + h + 'px">' +
        '<iframe class="mod-fr" sandbox="allow-scripts" scrolling="no"' +
        ' data-src="' + enc + '"></iframe></div>';
    }

    const t = m.title ? '<div class="mod-t">' + esc(m.title) + '</div>' : '';
    const b = m.text ? '<div class="mod-b">' + esc(m.text).replace(/\n/g, '<br>') + '</div>' : '';
    const empty = (t || b) ? '' : '<div class="mod-b mod-ph">点「美化 → 小组件」写点什么</div>';

    return '<div class="mod" data-mod="' + esc(id) + '">' + t + b + empty + '</div>';
  }

  function mount(root) {
    if (!root || !root.querySelectorAll) return;

    Array.prototype.forEach.call(root.querySelectorAll('iframe.mod-fr[data-src]'), function (fr) {
      if (fr.getAttribute('data-ready') === '1') return;
      fr.setAttribute('data-ready', '1');
      try { fr.srcdoc = decodeURIComponent(fr.getAttribute('data-src')); } catch (e) {}
    });
  }

  function create(data) {
    const id = 'm' + Date.now().toString(36) + Math.random().toString(36).slice(2, 5);

    list.push({
      id: id,
      kind: (data && data.kind === 'code') ? 'code' : 'text',
      title: data && data.title ? String(data.title) : '',
      text: data && data.text ? String(data.text) : '',
      code: data && data.code ? String(data.code) : '',
      span: data && data.span ? String(data.span) : '2',
      height: data && data.height ? String(data.height) : '140'
    });

    write();
    return id;
  }

  function remove(id) {
    list = list.filter(function (m) { return m.id !== id; });
    write();
  }

  function update(id, data) {
    const m = find(id);
    if (!m || !data) return;

    if (data.title !== undefined) m.title = String(data.title);
    if (data.text !== undefined) m.text = String(data.text);
    if (data.code !== undefined) m.code = String(data.code);
    if (data.span !== undefined) m.span = String(data.span);
    if (data.height !== undefined) m.height = String(data.height);
    if (data.kind !== undefined) m.kind = (data.kind === 'code') ? 'code' : 'text';

    write();
  }

  window.Mods = {
    all: all,
    find: find,
    span: span,
    height: height,
    html: html,
    doc: doc,
    codeOf: codeOf,
    mount: mount,
    tokens: tokens,
    create: create,
    remove: remove,
    update: update
  };
})();
