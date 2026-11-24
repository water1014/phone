/* xw-cloud.js · 云端同步（Supabase REST）

   不引 SDK，直接调 REST，省一个依赖、少一层缓存。
   key 只存在本机 localStorage，不进仓库、不进聊天。

   第一阶段只做两个手动动作：传到云 / 从云拉回。
   自动同步等这一版真机跑稳了再说。 */
(function () {
  const UK = 'xw_sb_url';
  const KK = 'xw_sb_key';

  function cfg() {
    let url = '';
    let key = '';
    try {
      url = String(localStorage.getItem(UK) || '').trim().replace(/\/+$/, '');
      key = String(localStorage.getItem(KK) || '').trim();
    } catch (e) {}
    return { url: url, key: key, ok: !!(url && key) };
  }

  function setCfg(url, key) {
    try {
      localStorage.setItem(UK, String(url || '').trim().replace(/\/+$/, ''));
      localStorage.setItem(KK, String(key || '').trim());
    } catch (e) {}
  }

  function clearCfg() {
    try {
      localStorage.removeItem(UK);
      localStorage.removeItem(KK);
    } catch (e) {}
  }

  function head() {
    const c = cfg();
    return {
      apikey: c.key,
      Authorization: 'Bearer ' + c.key,
      'Content-Type': 'application/json'
    };
  }

  function api(path, opt) {
    const c = cfg();
    if (!c.ok) return Promise.reject(new Error('\u8fd8\u6ca1\u914d\u7f6e\u4e91\u7aef'));

    const o = opt || {};
    o.headers = Object.assign(head(), o.headers || {});
    o.cache = 'no-store';

    return fetch(c.url + '/rest/v1/' + path, o).then(function (r) {
      if (!r.ok) {
        return r.text().then(function (t) {
          throw new Error(r.status + ' ' + String(t).slice(0, 140));
        });
      }
      if (r.status === 204) return null;
      return r.json().catch(function () { return null; });
    });
  }

  function isoDay(it) {
    const m = String(it.date || '').match(/\d{4}-\d{2}-\d{2}/);
    if (m) return m[0];
    if (it.t) {
      const d = new Date(it.t);
      const p = function (n) { return String(n).padStart(2, '0'); };
      return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
    }
    return null;
  }

  function toRow(it) {
    const row = {
      content: String(it.text || ''),
      status: it.status || 'ACTIVE',
      decay_class: it.decayClass || 'normal',
      pinned: !!it.pinned
    };
    if (it.event) row.event = String(it.event);
    if (it.feel) row.feel = String(it.feel);
    const day = isoDay(it);
    if (day) row.happened_on = day;
    return row;
  }

  function fromRow(r) {
    const t = r.created_at ? new Date(r.created_at).getTime() : Date.now();
    return {
      text: String(r.content || ''),
      date: String(r.happened_on || ''),
      pinned: !!r.pinned,
      status: r.status || 'ACTIVE',
      decayClass: r.decay_class || 'normal',
      act: Number(r.act) || 0,
      t: t,
      cloudId: r.id
    };
  }

  function list() {
    return api('memories?select=*&order=created_at.desc&limit=500');
  }

  function push(it) {
    return api('memories', {
      method: 'POST',
      headers: { Prefer: 'return=representation' },
      body: JSON.stringify(toRow(it))
    }).then(function (rows) {
      return Array.isArray(rows) && rows[0] ? rows[0].id : null;
    });
  }

  function patch(id, it) {
    return api('memories?id=eq.' + encodeURIComponent(id), {
      method: 'PATCH',
      headers: { Prefer: 'return=minimal' },
      body: JSON.stringify(toRow(it))
    });
  }

  function drop(id) {
    return api('memories?id=eq.' + encodeURIComponent(id), {
      method: 'DELETE',
      headers: { Prefer: 'return=minimal' }
    });
  }

  function ping() {
    return api('memories?select=id&limit=1');
  }

  window.XWCloud = {
    cfg: cfg,
    setCfg: setCfg,
    clearCfg: clearCfg,
    list: list,
    push: push,
    patch: patch,
    drop: drop,
    ping: ping,
    toRow: toRow,
    fromRow: fromRow
  };
})();
