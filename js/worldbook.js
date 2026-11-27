/* worldbook.js · Mio-style worldbook manager, adapted to phone's XW store */
(function () {
  const D = document;
  let scope = 'global';
  let query = '';

  function esc(v) { return window.UI && UI.esc ? UI.esc(v) : String(v == null ? '' : v).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
  function all() { return Array.isArray(XW.S.worldbooks) ? XW.S.worldbooks : (XW.S.worldbooks = []); }
  function persist() { XW.save('worldbooks'); }
  function uid() { return 'wb-' + Date.now().toString(36) + Math.random().toString(36).slice(2,7); }
  function normalize(item, fallbackScope) {
    if (!item || typeof item !== 'object') return null;
    return {
      id: String(item.id || uid()), title: String(item.title || item.name || item.comment || '未命名世界书'),
      keys: Array.isArray(item.keys) ? item.keys.join(', ') : String(item.keys || item.key || ''),
      content: String(item.content || item.description || item.text || ''),
      scope: item.scope === 'contact' || fallbackScope === 'contact' ? 'contact' : 'global',
      category: String(item.category || item.cat || ''), enabled: item.enabled !== false && item.on !== false,
      position: String(item.position || 'after')
    };
  }
  function importPayload(data) {
    let list = [];
    if (Array.isArray(data)) list = data;
    else if (data && Array.isArray(data.worldbooks)) list = data.worldbooks;
    else if (data && Array.isArray(data.entries)) list = data.entries;
    else if (data && data.entries && typeof data.entries === 'object') {
      list = Object.keys(data.entries).map(k => Object.assign({title:k}, data.entries[k]));
    } else if (data && typeof data === 'object' && data.entries && data.name) list = [data];
    else if (data && typeof data === 'object') {
      list = Object.keys(data).filter(k => data[k] && typeof data[k] === 'object').map(k => Object.assign({title:k}, data[k]));
    }
    return list.map(x => normalize(x, scope)).filter(Boolean);
  }
  function page() {
    const list = all().filter(x => x.scope === scope && (!query || (x.title + ' ' + x.keys + ' ' + x.content + ' ' + x.category).toLowerCase().includes(query.toLowerCase())));
    const cats = [...new Set(all().filter(x => x.scope === scope).map(x => x.category).filter(Boolean))];
    return '<div class="wb-port">' +
      '<div class="wb-port-head"><div><div class="kicker">YOUR LIBRARY</div><h2>世界书</h2><p>收纳世界背景、人物关系与故事规则。</p></div><button class="btn-glass" id="wb-add">＋ 新建</button></div>' +
      '<input class="wb-port-search" id="wb-search" type="search" placeholder="搜索名称、关键词或内容" value="' + esc(query) + '">' +
      '<div class="wb-port-tabs"><button data-scope="global" class="' + (scope === 'global' ? 'on' : '') + '">全局世界书</button><button data-scope="contact" class="' + (scope === 'contact' ? 'on' : '') + '">局部世界书</button></div>' +
      '<div class="wb-port-tools"><button id="wb-import">导入 JSON / Tavern</button><button id="wb-export">导出当前范围</button><button id="wb-category">新建分类</button><input id="wb-file" type="file" accept=".json,application/json" hidden></div>' +
      (cats.length ? '<div class="wb-port-cats">' + cats.map(c => '<button data-category="' + esc(c) + '">' + esc(c) + '</button>').join('') + '<button data-category="">全部</button></div>' : '') +
      (list.length ? '<div class="wb-port-list">' + list.map(x => '<article class="wb-port-item"><div class="wb-port-item-top"><strong>' + esc(x.title) + '</strong><span>' + (x.enabled ? '已启用' : '已停用') + '</span></div>' +
        (x.category ? '<small>' + esc(x.category) + '</small>' : '') + (x.keys ? '<p class="wb-port-keys">关键词：' + esc(x.keys) + '</p>' : '') +
        '<p class="wb-port-content">' + esc(x.content || '暂无内容') + '</p><div class="wb-port-actions"><button data-edit="' + esc(x.id) + '">编辑</button><button data-toggle="' + esc(x.id) + '">' + (x.enabled ? '停用' : '启用') + '</button><button data-delete="' + esc(x.id) + '">删除</button></div></article>').join('') + '</div>' :
        '<div class="empty-state wb-port-empty">这里还没有世界书。<br>可以新建一条，或导入已有的 JSON。</div>') + '</div>';
  }
  function edit(item) {
    const title = prompt('世界书名称', item ? item.title : '');
    if (title === null) return;
    const keys = prompt('触发关键词（逗号分隔）', item ? item.keys : '');
    if (keys === null) return;
    const content = prompt('世界书正文', item ? item.content : '');
    if (content === null) return;
    const category = prompt('分类（可留空）', item ? item.category : '');
    if (category === null) return;
    const next = normalize(Object.assign({}, item || {}, { id: item ? item.id : uid(), title: title.trim() || '未命名世界书', keys, content, category, scope }), scope);
    const list = all(); const index = list.findIndex(x => x.id === next.id);
    if (index >= 0) list[index] = next; else list.push(next);
    persist(); window.Router.reopen('worldbook');
  }
  function bind(body) {
    const search = body.querySelector('#wb-search');
    if (search) search.addEventListener('input', () => { query = search.value; const pos = search.selectionStart; window.Router.reopen('worldbook'); const next = D.getElementById('wb-search'); if (next) { next.focus(); next.setSelectionRange(pos,pos); } });
    body.querySelectorAll('[data-scope]').forEach(b => b.addEventListener('click', () => { scope = b.dataset.scope; query = ''; window.Router.reopen('worldbook'); }));
    body.querySelectorAll('[data-category]').forEach(b => b.addEventListener('click', () => { query = b.dataset.category; window.Router.reopen('worldbook'); }));
    const add = body.querySelector('#wb-add'); if (add) add.addEventListener('click', () => edit(null));
    body.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click', () => edit(all().find(x => x.id === b.dataset.edit))));
    body.querySelectorAll('[data-toggle]').forEach(b => b.addEventListener('click', () => { const x = all().find(x => x.id === b.dataset.toggle); if (x) { x.enabled = !x.enabled; persist(); window.Router.reopen('worldbook'); } }));
    body.querySelectorAll('[data-delete]').forEach(b => b.addEventListener('click', () => { const x = all().find(x => x.id === b.dataset.delete); if (x && confirm('删除「' + x.title + '」？')) { XW.S.worldbooks = all().filter(y => y.id !== x.id); persist(); window.Router.reopen('worldbook'); } }));
    const category = body.querySelector('#wb-category'); if (category) category.addEventListener('click', () => { const c = prompt('新分类名称'); if (c && c.trim()) { query = c.trim(); window.Router.reopen('worldbook'); } });
    const file = body.querySelector('#wb-file'); const imp = body.querySelector('#wb-import');
    if (imp && file) { imp.addEventListener('click', () => file.click()); file.addEventListener('change', async () => { const f = file.files && file.files[0]; file.value = ''; if (!f) return; try { const data = JSON.parse(await f.text()); const rows = importPayload(data); if (!rows.length) throw new Error('没有识别到世界书条目'); all().push(...rows); persist(); UI.toast('导入 ' + rows.length + ' 条世界书'); window.Router.reopen('worldbook'); } catch (e) { UI.toast(e.message || '导入失败'); } }); }
    const exp = body.querySelector('#wb-export'); if (exp) exp.addEventListener('click', () => { const rows = all().filter(x => x.scope === scope); const blob = new Blob([JSON.stringify({worldbooks:rows}, null, 2)], {type:'application/json'}); const url = URL.createObjectURL(blob); const a = D.createElement('a'); a.href = url; a.download = 'worldbook-' + scope + '.json'; a.click(); URL.revokeObjectURL(url); });
  }
  window.Pages = window.Pages || {};
  window.Pages.worldbook = page;
  window.Pages.worldbookBind = bind;
})();