/* mods.js · 自己搓的小组件
   存在 localStorage['xw_mods']，每条 { id, title, text, span }
   span 是可占几列：1 / 2 / 4 */
(function () {
  const K = 'xw_mods';
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

  function html(id) {
    const m = find(id);
    if (!m) return '';

    const t = m.title ? '<div class="mod-t">' + esc(m.title) + '</div>' : '';
    const b = m.text ? '<div class="mod-b">' + esc(m.text).replace(/\n/g, '<br>') + '</div>' : '';
    const empty = (t || b) ? '' : '<div class="mod-b mod-ph">点「美化 → 小组件」写点什么</div>';

    return '<div class="mod" data-mod="' + esc(id) + '">' + t + b + empty + '</div>';
  }

  function create(data) {
    const id = 'm' + Date.now().toString(36) + Math.random().toString(36).slice(2, 5);
    list.push({
      id: id,
      title: data && data.title ? String(data.title) : '',
      text: data && data.text ? String(data.text) : '',
      span: data && data.span ? String(data.span) : '2'
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
    if (data.span !== undefined) m.span = String(data.span);
    write();
  }

  window.Mods = {
    all: all,
    find: find,
    span: span,
    html: html,
    create: create,
    remove: remove,
    update: update
  };
})();
