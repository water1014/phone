/* api-panel.js · 设置页「接口」分类加强
   可点的模型列表 + 测试连接 + 当前生效状态 */
(function () {
  const D = document;

  const LABEL = { deepseek: 'DeepSeek', opencode: 'OpenCode Go', openai: 'OpenAI 兼容' };

  function val(id) {
    const el = D.getElementById(id);
    return el && el.value ? String(el.value).trim() : '';
  }

  function rawVal(id) {
    const el = D.getElementById(id);
    return el ? String(el.value || '') : '';
  }

  function base(u) {
    return String(u || '').trim().replace(/\/+$/, '').replace(/\/chat\/completions$/, '');
  }

  function endpoints(u) {
    const b = base(u);
    if (!b) return [];
    const out = [];
    if (/\/v\d+$/.test(b)) out.push(b + '/chat/completions');
    out.push(b + '/v1/chat/completions');
    out.push(b + '/chat/completions');
    return out;
  }

  function headersOf(key, raw, session) {
    const h = { 'Content-Type': 'application/json' };
    const k = String(key || '').trim();
    if (k) h.Authorization = 'Bearer ' + k;
    if (raw) {
      try {
        const o = JSON.parse(raw);
        if (o && typeof o === 'object' && !Array.isArray(o)) {
          Object.keys(o).forEach(function (n) {
            if (typeof o[n] === 'string') h[n] = o[n];
          });
        }
      } catch (e) {}
    }
    if (session && !h['x-opencode-session']) {
      h['x-opencode-session'] = 'xw-test-' + Date.now().toString(36);
    }
    return h;
  }

  function say(el, text, kind) {
    if (!el) return;
    el.textContent = text;
    el.className = 'ap-res' + (kind ? ' ' + kind : '');
  }

  async function test(btn, res) {
    const url = val('set-ai-url');
    const key = val('set-ai-key');
    const model = val('set-ai-model');
    const hdr = rawVal('set-ai-headers');
    const session = (XW.S.aiProvider === 'opencode');

    if (!url) { say(res, '先填接口地址', 'bad'); return; }
    if (!model) { say(res, '先填模型', 'bad'); return; }

    say(res, '正在试…');
    btn.disabled = true;

    const list = endpoints(url);
    const t0 = Date.now();
    let last = '';

    for (let i = 0; i < list.length; i++) {
      let r = null;
      try {
        r = await fetch(list[i], {
          method: 'POST',
          headers: headersOf(key, hdr, session),
          body: JSON.stringify({
            model: model,
            messages: [{ role: 'user', content: '在吗' }],
            max_tokens: 32,
            stream: false
          })
        });
      } catch (e) {
        last = '连不上（可能被跳域挡了）';
        continue;
      }

      if (r.status === 404) { last = '这个地址没有 chat 接口'; continue; }

      if (!r.ok) {
        const t = await r.text().catch(function () { return ''; });
        last = 'HTTP ' + r.status + (t ? '：' + t.slice(0, 110) : '');
        break;
      }

      const d = await r.json().catch(function () { return null; });
      const ch = d && d.choices && d.choices[0];
      const m = (ch && (ch.message || ch.delta)) || {};
      const hasThink = !!(m.reasoning_content || m.reasoning);
      const reply = String(m.content || '').trim().slice(0, 20);
      const sec = ((Date.now() - t0) / 1000).toFixed(1);

      let line = '通 · ' + sec + 's · ' + (hasThink ? '带思考链' : '不带思考链');
      if (reply) line += ' · 回「' + reply + '」';

      say(res, line, hasThink ? 'ok' : 'warn');
      btn.disabled = false;
      return;
    }

    say(res, last || '没试通', 'bad');
    btn.disabled = false;
  }

  function pick(id) {
    const el = D.getElementById('set-ai-model');
    if (el) el.value = id;

    XW.S.aiModel = id;
    XW.save('aiModel');

    XW.S.profiles = XW.S.profiles || {};
    const name = XW.S.aiProvider || 'deepseek';
    const old = XW.S.profiles[name] || {};
    XW.S.profiles[name] = Object.assign({}, old, { model: id });
    XW.save('profiles');

    const wrap = D.querySelector('.ap-chips');
    if (wrap) {
      Array.prototype.forEach.call(wrap.children, function (c) {
        if (!c.classList || !c.textContent) return;
        c.classList.toggle('on', c.textContent === id);
      });
    }

    mark();
    UI.toast('模型换成 ' + id);
  }

  function modelBlock() {
    const list = Array.isArray(XW.S.modelList) ? XW.S.modelList : [];
    const box = D.createElement('div');
    box.className = 'ap-models';

    if (!list.length) {
      const p = D.createElement('div');
      p.className = 'ap-note';
      p.textContent = '先点上面的「拉取模型」，拉回来这里就能直接挑，不用手打。';
      box.appendChild(p);
      return box;
    }

    const search = D.createElement('input');
    search.type = 'search';
    search.className = 'ap-search';
    search.placeholder = '找模型…';
    box.appendChild(search);

    const wrap = D.createElement('div');
    wrap.className = 'ap-chips';
    box.appendChild(wrap);

    function draw(kw) {
      wrap.textContent = '';
      const q = String(kw || '').trim().toLowerCase();
      const cur = val('set-ai-model');
      let n = 0;

      list.forEach(function (id) {
        if (q && String(id).toLowerCase().indexOf(q) < 0) return;
        const b = D.createElement('button');
        b.type = 'button';
        b.className = 'ap-chip' + (id === cur ? ' on' : '');
        b.textContent = id;
        b.addEventListener('click', function () { pick(id); });
        wrap.appendChild(b);
        n++;
      });

      if (!n) {
        const p = D.createElement('div');
        p.className = 'ap-note';
        p.textContent = '没有匹配的';
        wrap.appendChild(p);
      }
    }

    search.addEventListener('input', function () { draw(search.value); });
    draw('');
    return box;
  }

  function mark() {
    const live = D.getElementById('ap-live');
    if (!live) return;
    const p = String(XW.S.aiProvider || 'deepseek');
    const bits = [];
    bits.push(LABEL[p] || p);
    bits.push(val('set-ai-model') || '没填模型');
    bits.push(val('set-ai-key') ? '有 Key' : '没 Key');
    bits.push(val('set-ai-url') ? '有地址' : '没地址');
    live.textContent = bits.join(' · ');
  }

  function build() {
    const box = D.createElement('div');
    box.className = 'ap-block';

    const head = D.createElement('div');
    head.className = 'ap-head';
    head.textContent = '这台在用';
    box.appendChild(head);

    const live = D.createElement('div');
    live.className = 'ap-live';
    live.id = 'ap-live';
    box.appendChild(live);

    box.appendChild(modelBlock());

    const row = D.createElement('div');
    row.className = 'ap-row';

    const tb = D.createElement('button');
    tb.type = 'button';
    tb.className = 'ap-btn';
    tb.textContent = '测试一下';

    const res = D.createElement('span');
    res.className = 'ap-res';

    tb.addEventListener('click', function () { test(tb, res); });
    row.appendChild(tb);
    row.appendChild(res);
    box.appendChild(row);

    const note = D.createElement('div');
    note.className = 'ap-note';
    note.textContent = '测试会真的发一句话过去，花几个 token，比跑去聊天页试快。';
    box.appendChild(note);

    return box;
  }

  let timer = null;

  function render() {
    const anchor = D.getElementById('set-ai-model');
    if (!anchor) return;
    const sheet = anchor.closest('.sheet');
    if (!sheet) return;

    const old = sheet.querySelector('.ap-block');
    if (old) { mark(); return; }

    const box = build();
    const save = sheet.querySelector('#set-ai-save');
    const holder = save && save.closest('.row-actions');
    if (holder && holder.parentNode === sheet) {
      sheet.insertBefore(box, holder.nextSibling);
    } else {
      sheet.appendChild(box);
    }
    mark();
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 120);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  D.addEventListener('input', function (e) {
    const t = e.target;
    if (!t || !t.id) return;
    if (t.id === 'set-ai-model' || t.id === 'set-ai-key' || t.id === 'set-ai-url') mark();
  }, true);

  setTimeout(render, 700);
})();
