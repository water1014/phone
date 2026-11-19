/* store.js · 本地状态（localStorage，前缀 xw_） */
(function () {
  const LS = localStorage;
  const PREFIX = 'xw_';

  const DEF = {
    theme: 'light',
    loveDate: '2025-01-01',
    hisName: '他',
    herName: '她',
    diary: [],
    notes: []
  };

  const S = {};

  function load(key) {
    let value = null;
    try { value = JSON.parse(LS.getItem(PREFIX + key) || 'null'); } catch (err) { value = null; }
    if (value === null || value === undefined) {
      S[key] = JSON.parse(JSON.stringify(DEF[key]));
    } else {
      S[key] = value;
    }
  }

  function save(key) {
    try { LS.setItem(PREFIX + key, JSON.stringify(S[key])); }
    catch (err) { console.warn('[store] write failed', key, err); }
  }

  Object.keys(DEF).forEach(load);

  window.XW = { S: S, save: save, load: load, DEF: DEF };
})();
