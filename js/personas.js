/* personas.js · Mio-style contact book adapted to the phone app shell */
(function () {
  const D = document;
  let query = '';
  function esc(v) { return window.UI && UI.esc ? UI.esc(v) : String(v == null ? '' : v).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
  function list() { if (!Array.isArray(XW.S.contacts)) XW.S.contacts = []; return XW.S.contacts; }
  function save() { XW.save('contacts'); }
  function uid() { return 'contact-' + Date.now().toString(36) + Math.random().toString(36).slice(2,7); }
  function avatar(c) { return c.avatar ? '<img src="' + esc(c.avatar) + '" alt="">' : '<span>' + esc((c.name || '人').trim().slice(0,1) || '人') + '</span>'; }
  function page() {
    const rows = list().filter(c => [c.name,c.note,c.profile].join(' ').toLowerCase().includes(query.toLowerCase()));
    const active = XW.S.activeContactId;
    return '<div class="personas-page mio-contacts">' +
      '<div class="ctc-page-head"><div><div class="kicker">PEOPLE &amp; PERSONAS</div><h2>联系人</h2><p>角色资料、人物设定与当前聊天对象</p></div><button class="ctc-add" id="persona-add" type="button" aria-label="添加联系人">＋</button></div>' +
      '<label class="ctc-search"><span>⌕</span><input id="persona-search" type="search" value="' + esc(query) + '" placeholder="搜索联系人" autocomplete="off"></label>' +
      '<div class="ctc-section-label">我的联系人 <small>' + rows.length + '</small></div>' +
      (rows.length ? '<div class="ctc-list">' + rows.map(c => '<article class="ctc-person' + (active === c.id ? ' is-active' : '') + '" data-contact="' + esc(c.id) + '">' +
        '<div class="ctc-person-main"><div class="ctc-avatar">' + avatar(c) + '</div><div class="ctc-person-copy"><b>' + esc(c.name || '未命名联系人') + '</b><span>' + esc(c.note || '还没有填写简介') + '</span></div>' +
        (active === c.id ? '<i class="ctc-current">当前</i>' : '<i class="ctc-chevron">›</i>') + '</div>' +
        '<div class="ctc-person-tools"><button type="button" data-edit="' + esc(c.id) + '">编辑资料</button><button type="button" data-chat="' + esc(c.id) + '">进入聊天</button><button type="button" data-del="' + esc(c.id) + '">删除</button></div></article>').join('') + '</div>' :
        '<div class="ctc-empty">' + (query ? '没有找到相关联系人' : '还没有联系人，点击右上角 ＋ 添加第一位角色。') + '</div>') +
      '</div>';
  }
  function modal(item) {
    const c = item || { id: uid(), name: '', note: '', avatar: '', profile: '' };
    const mask = D.createElement('div'); mask.className = 'ctc-edit-mask';
    mask.innerHTML = '<section class="ctc-edit-sheet" role="dialog" aria-modal="true" aria-label="联系人资料">' +
      '<header><button type="button" data-cancel>取消</button><b>' + (item ? '编辑联系人' : '添加联系人') + '</b><button type="button" class="ctc-save" data-save>保存</button></header>' +
      '<div class="ctc-edit-body"><div class="ctc-avatar-edit"><button type="button" class="ctc-avatar large" id="persona-avatar">' + avatar(c) + '</button><span>点击头像更换</span><input id="persona-file" type="file" accept="image/*" hidden></div>' +
      '<label>名字<input id="persona-name" maxlength="60" value="' + esc(c.name) + '" placeholder="给这位联系人取个名字"></label>' +
      '<label>简介<input id="persona-note" maxlength="120" value="' + esc(c.note) + '" placeholder="一句话介绍"></label>' +
      '<label>角色设定<textarea id="persona-profile" rows="8" placeholder="外貌、性格、说话方式、与你的关系……">' + esc(c.profile) + '</textarea></label>' +
      '<p class="ctc-edit-hint">角色设定会作为联系人资料保存，后续用于完善聊天上下文。</p></div></section>';
    D.body.appendChild(mask);
    const close = () => mask.remove();
    mask.addEventListener('click', e => { if (e.target === mask || e.target.closest('[data-cancel]')) close(); });
    const file = mask.querySelector('#persona-file'), ava = mask.querySelector('#persona-avatar');
    ava.addEventListener('click', () => file.click());
    file.addEventListener('change', () => {
      const f = file.files && file.files[0]; if (!f) return;
      if (f.size > 5 * 1024 * 1024) { UI.toast('头像图片请小于 5MB'); return; }
      const reader = new FileReader(); reader.onload = () => { c.avatar = reader.result; ava.innerHTML = avatar(c); }; reader.readAsDataURL(f);
    });
    mask.querySelector('[data-save]').addEventListener('click', () => {
      const name = mask.querySelector('#persona-name').value.trim();
      if (!name) { UI.toast('先填写联系人名字'); return; }
      c.name = name;
      c.note = mask.querySelector('#persona-note').value.trim();
      c.profile = mask.querySelector('#persona-profile').value.trim();
      const rows = list(), at = rows.findIndex(x => x.id === c.id);
      if (at >= 0) rows[at] = c; else rows.push(c);
      save(); close(); window.Router.reopen('personas'); UI.toast('联系人资料已保存');
    });
  }
  function bind(body) {
    const add = body.querySelector('#persona-add'); if (add) add.addEventListener('click', () => modal(null));
    const search = body.querySelector('#persona-search');
    if (search) search.addEventListener('input', () => { query = search.value; const pos = search.selectionStart; window.Router.reopen('personas'); const next = body.querySelector('#persona-search'); if (next) { next.focus(); next.setSelectionRange(pos,pos); } });
    body.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click', e => { e.stopPropagation(); modal(list().find(x => x.id === b.dataset.edit)); }));
    body.querySelectorAll('[data-del]').forEach(b => b.addEventListener('click', e => {
      e.stopPropagation(); const c = list().find(x => x.id === b.dataset.del); if (!c || !confirm('确定删除联系人「' + c.name + '」吗？')) return;
      XW.S.contacts = list().filter(x => x.id !== c.id);
      if (XW.S.activeContactId === c.id) { XW.S.activeContactId = ''; XW.save('activeContactId'); }
      save(); window.Router.reopen('personas'); UI.toast('联系人已删除');
    }));
    body.querySelectorAll('[data-chat]').forEach(b => b.addEventListener('click', e => {
      e.stopPropagation(); XW.S.activeContactId = b.dataset.chat; XW.save('activeContactId'); window.Router.open('chat');
    }));
    body.querySelectorAll('[data-contact]').forEach(card => card.addEventListener('click', e => {
      if (e.target.closest('button')) return;
      XW.S.activeContactId = card.dataset.contact; XW.save('activeContactId');
      window.Router.reopen('personas'); UI.toast('已设为当前联系人');
    }));
  }
  window.Pages = window.Pages || {};
  window.Pages.personas = page;
  window.Pages.personasBind = bind;
})();
