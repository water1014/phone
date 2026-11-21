/* chat-stream.js · 把普通请求改成流式，边收边显示
   不动 router.js：在外面包一层 window.fetch
   网关不吃流式就原样退回，不影响原来的路径 */
(function () {
  const D = document;
  if (!window.fetch || !window.Response) return;
  const orig = window.fetch.bind(window);
  const RAF = window.requestAnimationFrame || function (fn) { return setTimeout(fn, 16); };

  let liveEl = null;
  let thinkBox = null;
  let bufText = '';
  let bufThink = '';
  let stick = true;
  let raf = 0;

  function ymd(d) {
    const p = function (n) { return String(n).padStart(2, '0'); };
    return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
  }

  function logUsage(u) {
    try {
      const all = (XW.S.usageLog && typeof XW.S.usageLog === 'object') ? XW.S.usageLog : {};
      const key = ymd(new Date());
      const cur = all[key] || { i: 0, o: 0, c: 0, n: 0 };
      const hit = Number(u.prompt_cache_hit_tokens) ||
        Number(u.prompt_tokens_details && u.prompt_tokens_details.cached_tokens) || 0;
      cur.i += Number(u.prompt_tokens) || 0;
      cur.o += Number(u.completion_tokens) || 0;
      cur.c += hit;
      cur.n += 1;
      all[key] = cur;
      const keys = Object.keys(all).sort();
      while (keys.length > 60) {
        delete all[keys.shift()];
      }
      XW.S.usageLog = all;
      XW.save('usageLog');
    } catch (e) {}
  }

  function lsNum(k, d) {
    try {
      const v = localStorage.getItem(k);
      if (v == null || v === '') return d;
      const n = Number(v);
      return isNaN(n) ? d : n;
    } catch (e) { return d; }
  }

  function scroller() { return D.getElementById('chat-scroll'); }

  function atBottom() {
    const sc = scroller();
    if (!sc) return false;
    return sc.scrollHeight - sc.scrollTop - sc.clientHeight < 160;
  }

  function tailBub() {
    const sc = scroller();
    if (!sc) return null;
    const list = sc.querySelectorAll('.bub');
    if (!list.length) return null;
    const el = list[list.length - 1];
    const row = el.closest ? el.closest('.msg-row') : null;
    if (row && row.classList.contains('me')) return null;
    return el;
  }

  function begin() {
    if (liveEl && D.contains(liveEl)) return;
    const el = tailBub();
    if (!el) return;
    stick = atBottom();
    el.classList.remove('typing');
    el.classList.add('cs-live');
    el.textContent = '';
    liveEl = el;
    thinkBox = null;
  }

  function ensureThink() {
    if (!liveEl || !D.contains(liveEl)) return null;
    if (thinkBox && D.contains(thinkBox)) return thinkBox;
    const holder = liveEl.parentNode;
    if (!holder) return null;
    let det = holder.querySelector('details.think');
    if (!det) {
      det = D.createElement('details');
      det.className = 'think';
      det.open = true;
      const sum = D.createElement('summary');
      sum.textContent = '思考';
      const box = D.createElement('div');
      box.className = 'think-body';
      det.appendChild(sum);
      det.appendChild(box);
      holder.insertBefore(det, liveEl);
    }
    det.open = true;
    thinkBox = det.querySelector('.think-body');
    return thinkBox;
  }

  function flush() {
    raf = 0;
    if (!liveEl || !D.contains(liveEl)) return;
    if (bufThink) {
      const box = ensureThink();
      if (box) box.textContent = bufThink;
      if (!bufText) return;
    }
    if (bufText) {
      liveEl.textContent = bufText;
      if (thinkBox && D.contains(thinkBox)) {
        const det = thinkBox.closest ? thinkBox.closest('details') : null;
        if (det) det.open = false;
      }
      const sc = scroller();
      if (sc && stick) sc.scrollTop = sc.scrollHeight;
    }
  }

  async function run(input, init, data) {
    const body = Object.assign({}, data, {
      stream: true,
      stream_options: { include_usage: true }
    });

    const t = lsNum('xw_ai_temp', -1);
    if (t >= 0 && t <= 2 && body.temperature === undefined && !/reason/i.test(String(data.model || ''))) {
      body.temperature = t;
    }

    const mo = lsNum('xw_ai_maxout', 0);
    if (mo > 0 && body.max_tokens === undefined) {
      body.max_tokens = mo;
    }

    let res = null;
    try {
      res = await orig(input, Object.assign({}, init, { body: JSON.stringify(body) }));
    } catch (e) {
      return orig(input, init);
    }
    if (!res || !res.ok) return orig(input, init);

    const ct = (res.headers && res.headers.get('content-type')) || '';
    if (ct.indexOf('event-stream') < 0 || !res.body || !res.body.getReader) return res;

    const reader = res.body.getReader();
    const dec = new TextDecoder('utf-8');
    let rest = '';
    let content = '';
    let think = '';
    let usage = null;
    let model = data.model || '';
    let started = false;

    function push(dt, cc) {
      if (dt) {
        think += dt;
        bufThink = think;
      }
      if (cc) {
        content += cc;
        bufText = content;
      }
      if (!started) {
        started = true;
        begin();
      }
      if (!raf) raf = RAF(flush);
    }

    function line(raw) {
      const s = String(raw || '').replace(/\r$/, '').trim();
      if (s.slice(0, 5) !== 'data:') return;
      const p = s.slice(5).trim();
      if (!p || p === '[DONE]') return;
      let j = null;
      try { j = JSON.parse(p); } catch (e) { return; }
      if (j.model) model = j.model;
      if (j.usage) usage = j.usage;
      const ch = j.choices && j.choices[0];
      if (!ch) return;
      const dl = ch.delta || ch.message || {};
      let dt = dl.reasoning_content || dl.reasoning || '';
      if (typeof dt !== 'string') dt = '';
      let cc = dl.content;
      if (Array.isArray(cc)) {
        cc = cc.map(function (p2) {
          if (typeof p2 === 'string') return p2;
          return (p2 && p2.text) || '';
        }).join('');
      }
      if (typeof cc !== 'string') cc = '';
      if (dt || cc) push(dt, cc);
    }

    try {
      while (true) {
        const r = await reader.read();
        if (r.done) break;
        rest += dec.decode(r.value, { stream: true });
        let i = rest.indexOf('\n');
        while (i >= 0) {
          const one = rest.slice(0, i);
          rest = rest.slice(i + 1);
          line(one);
          i = rest.indexOf('\n');
        }
      }
      if (rest) line(rest);
    } catch (e) {}

    if (raf) {
      try { window.cancelAnimationFrame(raf); } catch (e) {}
      raf = 0;
    }
    flush();

    if (liveEl && D.contains(liveEl)) liveEl.classList.remove('cs-live');
    if (thinkBox && D.contains(thinkBox)) {
      const det = thinkBox.closest ? thinkBox.closest('details') : null;
      if (det) det.open = false;
    }
    liveEl = null;
    thinkBox = null;
    bufText = '';
    bufThink = '';

    const out = {
      id: 'xw-stream',
      object: 'chat.completion',
      created: Math.floor(Date.now() / 1000),
      model: model,
      choices: [{
        index: 0,
        message: { role: 'assistant', content: content, reasoning_content: think },
        finish_reason: 'stop'
      }]
    };
    if (usage) {
      out.usage = usage;
      logUsage(usage);
    }

    return new Response(JSON.stringify(out), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  window.fetch = function (input, init) {
    let data = null;
    try {
      if (init && typeof init.body === 'string') {
        const t = JSON.parse(init.body);
        if (t && Array.isArray(t.messages)) data = t;
      }
    } catch (e) { data = null; }
    if (!data || data.stream) return orig(input, init);
    const u = typeof input === 'string' ? input : (input && input.url) || '';
    if (u.indexOf('chat/completions') < 0) return orig(input, init);
    return run(input, init, data);
  };
})();
