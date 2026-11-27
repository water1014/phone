/* personas.js · Mio contact book: groups, profile cards, import/export */
(function () {
  const D = document;
  let query = '', groupFilter = '*';
  const esc = v => window.UI && UI.esc ? UI.esc(v) : String(v == null ? '' : v).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const list = () => Array.isArray(XW.S.contacts) ? XW.S.contacts : (XW.S.contacts = []);
  const groups = () => Array.isArray(XW.S.contactGroups) ? XW.S.contactGroups : (XW.S.contactGroups = []);
  const save = () => { XW.save('contacts'); XW.save('contactGroups'); };
  const uid = () => 'contact-' + Date.now().toString(36) + Math.random().toString(36).slice(2,7);
  const avatar = c => c.avatar ? '<img src="' + esc(c.avatar) + '" alt="">' : '<span>' + esc((c.name || '人').trim().slice(0,1) || '人') + '</span>';
  function page() {
    const all = list();
    const rows = all.filter(c => (!query || [c.name,c.note,c.profile,c.handle].join(' ').toLowerCase().includes(query.toLowerCase())) && (groupFilter === '*' || (c.group || '') === groupFilter));
    const active = XW.S.activeContactId;
    const chips = ['*', ...groups()].map(g => '<button type="button" class="ctc-chip' + (groupFilter === g ? ' on' : '') + '" data-group="' + esc(g) + '">' + (g === '*' ? '全部' : esc(g)) + '</button>').join('');
    const sections = [];
    if (groupFilter === '*') {
      const keys = [...groups(), ''];
      keys.forEach(g => { const part = rows.filter(c => (c.group || '') === g); if (part.length) sections.push('<div class="ctc-group-title">' + (g ? esc(g) : '未分组') + '<small>' + part.length + '</small></div>' + renderRows(part, active)); });
      rows.filter(c => c.group && !groups().includes(c.group)).forEach(c => sections.push(renderRows([c], active)));
    } else if (rows.length) sections.push(renderRows(rows, active));
    return '<div class="personas-page mio-contacts">' +
      '<div class="ctc-page-head"><div><div class="kicker">PEOPLE &amp; PERSONAS</div><h2>联系人</h2><p>角色资料、人物设定与当前聊天对象</p></div><button class="ctc-add" id="persona-add" type="button" aria-label="添加联系人">＋</button></div>' +
      '<label class="ctc-search"><span>⌕</span><input id="persona-search" type="search" value="' + esc(query) + '" placeholder="搜索联系人" autocomplete="off"></label>' +
      '<div class="ctc-tools"><div class="ctc-chips">' + chips + '</div><button type="button" id="persona-group-manage">管理分组</button></div>' +
      '<div class="ctc-section-label">我的联系人 <small>' + rows.length + ' / ' + all.length + '</small></div>' +
      (rows.length ? '<div class="ctc-list">' + sections.join('') + '</div>' : '<div class="ctc-empty">' + (query ? '没有找到相关联系人' : '这个分组还没有联系人。点击 ＋ 添加一位角色。') + '</div>') +
      '<div class="ctc-bottom-tools"><button type="button" id="persona-import">导入联系人</button><button type="button" id="persona-export">导出联系人</button><input id="persona-import-file" type="file" accept=".json,application/json" hidden></div>' +
      '</div>';
  }
  function renderRows(rows, active) {
    return rows.map(c => '<article class="ctc-person' + (active === c.id ? ' is-active' : '') + '" data-contact="' + esc(c.id) + '">' +
      '<div class="ctc-person-main"><div class="ctc-avatar">' + avatar(c) + '</div><div class="ctc-person-copy"><b>' + esc(c.name || '未命名联系人') + '</b><span>' + esc(c.note || '还没有填写简介') + (c.group ? ' · ' + esc(c.group) : '') + '</span></div>' +
      (active === c.id ? '<i class="ctc-current">当前</i>' : '<i class="ctc-chevron">›</i>') + '</div>' +
      '<div class="ctc-person-tools"><button type="button" data-edit="' + esc(c.id) + '">编辑资料</button><button type="button" data-chat="' + esc(c.id) + '">进入聊天</button><button type="button" data-del="' + esc(c.id) + '">删除</button></div></article>').join('');
  }
  function modal(item) {
    const c = item || { id: uid(), name: '', note: '', avatar: '', profile: '', group: '' };
    const mask = D.createElement('div'); mask.className = 'ctc-edit-mask';
    mask.innerHTML = '<section class="ctc-edit-sheet" role="dialog" aria-modal="true" aria-label="联系人资料">' +
      '<header><button type="button" data-cancel>取消</button><b>' + (item ? '编辑联系人' : '添加联系人') + '</b><button type="button" class="ctc-save" data-save>保存</button></header>' +
      '<div class="ctc-edit-body"><div class="ctc-avatar-edit"><button type="button" class="ctc-avatar large" id="persona-avatar">' + avatar(c) + '</button><span>点击头像更换</span><input id="persona-file" type="file" accept="image/*" hidden></div>' +
      '<label>名字<input id="persona-name" maxlength="60" value="' + esc(c.name) + '" placeholder="给这位联系人取个名字"></label>' +
      '<label>账号<input id="persona-handle" maxlength="60" value="' + esc(c.handle || '') + '" placeholder="可选，类似 @name"></label>' +
      '<label>简介<input id="persona-note" maxlength="120" value="' + esc(c.note) + '" placeholder="一句话介绍"></label>' +
      '<label>分组<select id="persona-group"><option value="">未分组</option>' + groups().map(g => '<option value="' + esc(g) + '"' + (c.group === g ? ' selected' : '') + '>' + esc(g) + '</option>').join('') + '<option value="__new">＋ 新建分组…</option></select></label>' +
      '<label>角色设定<textarea id="persona-profile" rows="8" placeholder="外貌、性格、说话方式、与你的关系……">' + esc(c.profile) + '</textarea></label>' +
      '<p class="ctc-edit-hint">角色设定会保存到本机联系人资料。</p></div></section>';
    D.body.appendChild(mask);
    const close = () => mask.remove(), q = sel => mask.querySelector(sel);
    mask.addEventListener('click', e => { if (e.target === mask || e.target.closest('[data-cancel]')) close(); });
    const file = q('#persona-file'), ava = q('#persona-avatar'), group = q('#persona-group');
    ava.addEventListener('click', () => file.click());
    file.addEventListener('change', () => {
      const f = file.files && file.files[0]; if (!f) return;
      if (!/^image\//.test(f.type)) return UI.toast('请选择图片文件');
      if (f.size > 12*1024*1024) return UI.toast('头像原图请小于 12MB');
      const reader = new FileReader();
      reader.onload = () => {
        const img = new Image();
        img.onload = () => {
          const scale = Math.min(1, 320 / Math.max(img.width, img.height));
          const canvas = D.createElement('canvas');
          canvas.width = Math.max(1, Math.round(img.width * scale));
          canvas.height = Math.max(1, Math.round(img.height * scale));
          const ctx = canvas.getContext('2d');
          if (!ctx) return UI.toast('头像处理失败');
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
          c.avatar = canvas.toDataURL('image/jpeg', 0.78);
          ava.innerHTML = avatar(c);
        };
        img.onerror = () => UI.toast('无法读取这张图片');
        img.src = reader.result;
      };
      reader.onerror = () => UI.toast('头像读取失败');
      reader.readAsDataURL(f);
    });
    group.addEventListener('change', () => { if (group.value !== '__new') return; const name = (prompt('新分组名称') || '').trim(); if (!name) { group.value = c.group || ''; return; } if (!groups().includes(name)) { groups().push(name); save(); const opt = D.createElement('option'); opt.value = name; opt.textContent = name; group.insertBefore(opt, group.lastElementChild); } group.value = name; });
    q('[data-save]').addEventListener('click', () => {
      const name = q('#persona-name').value.trim(); if (!name) return UI.toast('先填写联系人名字');
      Object.assign(c, { name, handle:q('#persona-handle').value.trim(), note:q('#persona-note').value.trim(), group:group.value === '__new' ? '' : group.value, profile:q('#persona-profile').value.trim() });
      const rows = list(), at = rows.findIndex(x => x.id === c.id); if (at >= 0) rows[at] = c; else rows.push(c);
      save(); close(); window.Router.reopen('personas'); UI.toast('联系人资料已保存');
    });
  }
  function manageGroups() {
    const current = groups();
    const action = prompt('分组管理：输入新分组名称；输入已有分组名称可重命名；留空取消。\n现有分组：' + (current.join('、') || '无'));
    if (action === null) return;
    const value = action.trim(); if (!value) return;
    if (current.includes(value)) {
      const next = prompt('将「' + value + '」重命名为：', value);
      if (next === null || !next.trim()) return;
      const name = next.trim(); if (current.includes(name)) return UI.toast('这个分组已存在');
      XW.S.contactGroups = current.map(g => g === value ? name : g);
      list().forEach(c => { if (c.group === value) c.group = name; });
    } else XW.S.contactGroups.push(value);
    save(); window.Router.reopen('personas'); UI.toast('分组已更新');
  }
  function exportContacts() {
    const data = JSON.stringify({ type:'phone-mio-contacts', version:1, groups:groups(), contacts:list() }, null, 2);
    const blob = new Blob([data], {type:'application/json'}), url = URL.createObjectURL(blob), a = D.createElement('a');
    a.href = url; a.download = 'contacts-' + new Date().toISOString().slice(0,10) + '.json'; a.click(); URL.revokeObjectURL(url);
    UI.toast('联系人已导出');
  }
  function importContacts(file) {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const data = JSON.parse(reader.result), incoming = Array.isArray(data) ? data : (data.contacts || data.personas || []);
        if (!Array.isArray(incoming)) throw new Error('格式不正确');
        const merged = list().slice(), ids = new Set(merged.map(c => c.id));
        incoming.forEach(c => { if (!c || typeof c !== 'object') return; const row = { id: c.id && !ids.has(c.id) ? c.id : uid(), name:String(c.name || c.title || '未命名联系人'), handle:String(c.handle || ''), note:String(c.note || c.bio || ''), profile:String(c.profile || c.prompt || c.description || ''), avatar:typeof c.avatar === 'string' ? c.avatar : '', group:String(c.group || '') }; merged.push(row); ids.add(row.id); });
        XW.S.contacts = merged;
        (Array.isArray(data.groups) ? data.groups : []).forEach(g => { if (typeof g === 'string' && g.trim() && !groups().includes(g.trim())) groups().push(g.trim()); });
        incoming.forEach(c => { if (c && c.group && !groups().includes(c.group)) groups().push(c.group); });
        save(); window.Router.reopen('personas'); UI.toast('导入完成：' + incoming.length + ' 位联系人');
      } catch (e) { UI.toast('导入失败：JSON 格式不正确'); }
    };
    reader.readAsText(file);
  }
  function bind(body) {
    const add = body.querySelector('#persona-add'); if (add) add.addEventListener('click', () => modal(null));
    const search = body.querySelector('#persona-search');
    if (search) search.addEventListener('input', () => { query = search.value; const pos = search.selectionStart; window.Router.reopen('personas'); const next = D.querySelector('#app-body #persona-search'); if (next) { next.focus(); next.setSelectionRange(pos,pos); } });
    body.querySelectorAll('[data-group]').forEach(b => b.addEventListener('click', () => { groupFilter = b.dataset.group; window.Router.reopen('personas'); }));
    const gm = body.querySelector('#persona-group-manage'); if (gm) gm.addEventListener('click', manageGroups);
    body.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click', e => { e.stopPropagation(); modal(list().find(x => x.id === b.dataset.edit)); }));
    body.querySelectorAll('[data-del]').forEach(b => b.addEventListener('click', e => { e.stopPropagation(); const c = list().find(x => x.id === b.dataset.del); if (!c || !confirm('确定删除联系人「' + c.name + '」吗？')) return; XW.S.contacts = list().filter(x => x.id !== c.id); if (XW.S.activeContactId === c.id) { XW.S.activeContactId = ''; XW.save('activeContactId'); } save(); window.Router.reopen('personas'); UI.toast('联系人已删除'); }));
    body.querySelectorAll('[data-chat]').forEach(b => b.addEventListener('click', e => { e.stopPropagation(); XW.S.activeContactId = b.dataset.chat; XW.save('activeContactId'); window.Router.open('chat'); }));
    body.querySelectorAll('[data-contact]').forEach(card => {
      card.addEventListener('click', e => { if (e.target.closest('button') || card.classList.contains('swiped') || main && main.dataset.swipeMoved) return; XW.S.activeContactId = card.dataset.contact; XW.save('activeContactId'); window.Router.reopen('personas'); UI.toast('已设为当前联系人'); });
      let sx = 0, sy = 0, moved = false;
      const main = card.querySelector('.ctc-person-main');
      if (!main) return;
      main.addEventListener('touchstart', e => { const t=e.touches[0]; sx=t.clientX; sy=t.clientY; moved=false; }, {passive:true});
      main.addEventListener('touchmove', e => {
        const t=e.touches[0], dx=t.clientX-sx, dy=t.clientY-sy;
        if (Math.abs(dx)>12 && Math.abs(dx)>Math.abs(dy)*1.25) { moved=true; if(dx < -24) card.classList.add('swiped'); else if(dx > 24) card.classList.remove('swiped'); }
      }, {passive:true});
      main.addEventListener('touchend', () => { if(moved) { const clear=()=>{main.dataset.swipeMoved='1'; setTimeout(()=>delete main.dataset.swipeMoved,250);}; clear(); } }, {passive:true});
    });
    const exp = body.querySelector('#persona-export'); if (exp) exp.addEventListener('click', exportContacts);
    const imp = body.querySelector('#persona-import'), inp = body.querySelector('#persona-import-file');
    if (imp && inp) { imp.addEventListener('click', () => inp.click()); inp.addEventListener('change', () => { const f = inp.files && inp.files[0]; if (f) importContacts(f); inp.value = ''; }); }
  }
  window.Pages = window.Pages || {};
  window.Pages.personas = page;
  window.Pages.personasBind = bind;
})();
