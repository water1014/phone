/* personas.js · Contact/persona book */
(function () {
  const D = document;
  function esc(v) { return window.UI && UI.esc ? UI.esc(v) : String(v == null ? '' : v).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
  function list() { return Array.isArray(XW.S.contacts) ? XW.S.contacts : (XW.S.contacts = []); }
  function save() { XW.save('contacts'); }
  function uid() { return 'contact-' + Date.now().toString(36) + Math.random().toString(36).slice(2,7); }
  function page() {
    const rows = list().map(c => '<article class="persona-card"><div class="persona-avatar">' + (c.avatar ? '<img src="' + esc(c.avatar) + '" alt="">' : esc((c.name || '人').slice(0,1))) + '</div><div class="persona-info"><strong>' + esc(c.name || '未命名联系人') + '</strong><small>' + esc(c.note || '还没有简介') + '</small><code>ID：' + esc(c.id) + '</code></div><div class="persona-actions"><button data-active="' + esc(c.id) + '">' + (XW.S.activeContactId === c.id ? '当前聊天对象' : '设为聊天对象') + '</button><button data-edit="' + esc(c.id) + '">编辑</button><button data-del="' + esc(c.id) + '">删除</button></div></article>').join('');
    return '<div class="personas-page"><div class="personas-head"><div><div class="kicker">PEOPLE & PERSONAS</div><h2>联系人</h2><p>管理角色资料，并选择聊天对象。</p></div><button class="btn-solid" id="persona-add">＋ 添加</button></div>' + (rows || '<div class="empty-state">还没有联系人，添加一位角色开始吧。</div>') + '</div>';
  }
  function edit(item) {
    const name = prompt('联系人名称', item ? item.name : ''); if (name === null) return;
    const note = prompt('角色简介', item ? item.note : ''); if (note === null) return;
    const avatar = prompt('头像图片 URL（可留空）', item ? item.avatar : ''); if (avatar === null) return;
    const profile = prompt('角色设定 / 人物描述', item ? item.profile : ''); if (profile === null) return;
    const next = { id: item ? item.id : uid(), name: name.trim() || '未命名联系人', note: note.trim(), avatar: avatar.trim(), profile: profile.trim() };
    const rows = list(), at = rows.findIndex(x => x.id === next.id); if (at >= 0) rows[at] = next; else rows.push(next);
    save(); window.Router.reopen('personas');
  }
  function bind(body) {
    const add = body.querySelector('#persona-add'); if (add) add.addEventListener('click', () => edit(null));
    body.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click', () => edit(list().find(x => x.id === b.dataset.edit))));
    body.querySelectorAll('[data-active]').forEach(b => b.addEventListener('click', () => { XW.S.activeContactId = b.dataset.active; XW.save('activeContactId'); UI.toast('聊天对象已切换'); window.Router.reopen('personas'); }));
    body.querySelectorAll('[data-del]').forEach(b => b.addEventListener('click', () => { const c = list().find(x => x.id === b.dataset.del); if (!c || !confirm('删除联系人「' + c.name + '」？')) return; XW.S.contacts = list().filter(x => x.id !== c.id); if (XW.S.activeContactId === c.id) { XW.S.activeContactId = ''; XW.save('activeContactId'); } save(); window.Router.reopen('personas'); }));
  }
  window.Pages = window.Pages || {};
  window.Pages.personas = page;
  window.Pages.personasBind = bind;
})();