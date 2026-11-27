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
    photos: [],
    chat: [],
    notes: [],
    worldbooks: [],
    contacts: [],
    activeContactId: '',
    appOrder: [],

    /* 主连接：聊天用 */
    aiUrl: 'https://api.openai.com/v1/chat/completions',
    aiModel: 'gpt-4o-mini',
    aiKey: '',
    aiHeaders: '',
    ctxLimit: 128000,

    /* token 用量：{ rounds, input, cached, output } */
    usage: { rounds: 0, input: 0, cached: 0, output: 0 },

    /* 其它接口：生图 / 语音 / 识图 …… 每项独立一套 */
    apis: []
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
    catch (err) {
      console.warn('[store] write failed', key, err);
      if (window.UI && UI.toast) UI.toast('存不下了，删点旧内容试试');
    }
  }

  Object.keys(DEF).forEach(load);

  window.XW = { S: S, save: save, load: load, DEF: DEF };
})();
