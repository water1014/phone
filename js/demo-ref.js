/* demo-ref.js · 四套排法，可交互：能输入、能发、能切 */
(function () {
  var D = document;
  var phone = D.getElementById('phone');
  var sw = D.getElementById('sw');

  var MODE = 'A';
  var draft = '';
  var hadFocus = false;
  var ri = 0;

  function mk(h, m) {
    var d = new Date();
    d.setHours(h, m, 0, 0);
    return d.getTime();
  }
  function hm(ts) {
    var d = new Date(ts), h = d.getHours(), m = d.getMinutes();
    return (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m;
  }
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function ps(a) { return a.map(function (x) { return '<p>' + esc(x) + '</p>'; }).join(''); }
  function sp(a) { return a.map(function (x) { return '<span>' + esc(x) + '</span>'; }).join(''); }

  var LOG = [
    { w: 'him', t: mk(8, 41), s: ['下雨了，出门带伞。'], th: '想到你上次淋了一场，回来打了三个喷嚏', u: '93% 输入 197.6k \u00B7 命中 78.6k(40%) \u00B7 输出 250 \u00B7 2 轮' },
    { w: 'her', t: mk(8, 43), s: ['带了带了。', '就是不想上课。'] },
    { w: 'him', t: mk(8, 44), s: ['一节大课而已。', '晚上给你带吃的。'], th: '想说带汤，又怕她嫌重' },
    { w: 'her', t: mk(8, 52), s: ['不要香菜。'], stk: 1 },
    { w: 'him', t: mk(8, 53), s: ['记住了。', '今天左边那扇窗你别开，风大。'], th: '昨天她在窗边坐了一下午，晚上说头疼' }
  ];

  var REPLIES = [
    ['\u55EF，我记住了。'],
    ['你发这句的时候我在看窗外。', '雨点砸在空调外机上，一格一格的。'],
    ['好。', '那就这样办。'],
    ['听到了。', '再忙也听。'],
    ['这句我留着了。'],
    ['别急。', '先把课上完，剩下的回来再说。']
  ];

  var NAME = { him: '祁', her: '淼' };
  var HEADS = [['A', 'A 清静'], ['B', 'B 顺手'], ['C', 'C 目录'], ['D', 'D 陪伴']];

  HEADS.forEach(function (h) {
    var b = D.createElement('button');
    b.textContent = h[1];
    b.setAttribute('data-k', h[0]);
    b.onclick = function () { go(h[0]); };
    sw.appendChild(b);
  });

  /* ---------- A 清静 ---------- */
  function drawA() {
    var h = '<div class="topA"><b class="ib">\u2039</b><div class="fa"><i>祁</i><em>\u2661</em><i>淼</i></div><b class="ib">\u22EF</b></div>';
    h += '<div class="flowA" id="sc">';
    var prev = 0;
    LOG.forEach(function (m) {
      if (!prev || m.t - prev > 300000) h += '<div class="tmA">' + hm(m.t) + '</div>';
      prev = m.t;
      h += '<div class="bA ' + m.w + '"><div class="avA">' + NAME[m.w] + '</div><div class="txA">';
      h += ps(m.s);
      if (m.stk) h += '<div class="stkA">表情包</div>';
      if (m.u) h += '<div class="useA">\u25AE ' + esc(m.u) + '</div>';
      h += '</div></div>';
    });
    h += '</div>';
    h += '<div class="footA">\u2299 1 次工具调用 \u00B7 \u2299 3 条记忆</div>';
    h += '<div class="inA"><b class="rb">\uFF0B</b><input class="inp" placeholder="输入消息\u2026"><b class="rb snd">\u25B6</b><b class="rb">\u2661</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mA';
    after();
  }

  /* ---------- B 顺手 ---------- */
  function drawB() {
    var h = '<div class="topB"><i class="avB">祁</i><div class="nmB"><b>宋祁</b><em>&gt; \u2297 &lt;</em></div><b class="ib">\u2261</b></div>';
    h += '<div class="flowB" id="sc">';
    LOG.forEach(function (m) {
      if (m.th) h += '<details class="thB"><summary>\u2726 思考 \u00B7 2 个动作</summary><p>' + esc(m.th) + '</p></details>';
      h += '<div class="rwB ' + m.w + '"><i class="avB">' + NAME[m.w] + '</i><div class="bubB">';
      h += sp(m.s);
      if (m.stk) h += '<div class="stkB">表情包</div>';
      h += '</div></div>';
    });
    h += '</div>';
    h += '<div class="inB"><b class="rb">\uFF0B</b><input class="inp" placeholder="Message\u2026"><b class="rb snd">\uD83C\uDFA4</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mB';
    after();
  }

  /* ---------- C 目录 ---------- */
  function drawC() {
    var h = '';
    h += '<div class="maskC"></div>';
    h += '<div class="railC">';
    h += '<div class="rhC">宋祁 \u00D7 淼淼<em>~/xiaowo</em></div>';
    h += '<div class="lgC">日常</div>';
    h += '<a>together/ <s>' + LOG.length + '</s></a>';
    h += '<a>his corner/ <s>8</s></a>';
    h += '<a>keepsakes/ <s>4</s></a>';
    h += '<div class="lgC">屋子</div>';
    h += '<a><i>\u2302</i>聊天</a><a><i>\u25A4</i>日记</a><a><i>\u25A6</i>相册</a><a><i>\u266B</i>音乐</a>';
    h += '<div class="lgC">设置</div>';
    h += '<a><i>\u25D4</i>用量</a><a><i>\u263E</i>夜间<b class="tg"></b></a><a><i>i</i>关于</a>';
    h += '</div>';
    h += '<div class="topC"><b class="ib ham">\u2261</b><div class="nmC">宋祁 \u2661 淼淼</div><b class="ib">\u2315</b></div>';
    h += '<div class="flowC" id="sc">';
    LOG.forEach(function (m) {
      h += '<div class="rwC ' + m.w + '"><i class="avC">' + NAME[m.w] + '</i><div class="bubC">';
      h += sp(m.s);
      if (m.stk) h += '<div class="stkC">表情包</div>';
      h += '</div></div>';
      if (m.u) h += '<details class="useC"><summary>输入 302,863 \u00B7 输出 245 \u00B7 命中 99.6%</summary><p>' + esc(m.u) + '</p></details>';
    });
    h += '</div>';
    h += '<div class="inC"><b class="rb">\uFF0B</b><input class="inp" placeholder="你说点\u2026"><b class="rb snd">\u266B</b></div>';
    h += '<div class="tabC"><b class="on">聊天</b><b>日记</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mC';
    after();
  }

  /* ---------- D 陪伴 ---------- */
  function drawD() {
    var h = '<div class="topD"><div class="nmD"><b>宋祁</b><em>deepseek-flash</em></div><b class="ib">\u2315</b></div>';
    h += '<div class="musD"><i>\u266B</i><div class="mi"><b>Mind Games</b><em>Sickick</em><div class="barD"><u></u></div></div></div>';
    h += '<div class="flowD" id="sc">';
    LOG.forEach(function (m) {
      h += '<div class="cdD">\u2726 Conducted ' + (m.d || (m.w === 'him' ? '2.9s' : '1.4s')) + '</div>';
      h += '<div class="rowD ' + m.w + '"><i class="avD">' + NAME[m.w] + '</i><div class="bubD">';
      h += sp(m.s);
      if (m.stk) h += '<div class="stkD">表情包</div>';
      h += '</div></div>';
    });
    h += '</div>';
    h += '<div class="inD"><b class="rb">\uFF0B</b><input class="inp" placeholder="Type something\u2026"><b class="mdD">Thinking</b><b class="rb snd">\u2191</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mD';
    after();
  }

  function after() {
    var sc = phone.querySelector('#sc');
    if (sc) sc.scrollTop = sc.scrollHeight;
    var i = phone.querySelector('.inp');
    if (i) {
      i.value = draft;
      if (hadFocus) {
        i.focus();
        try { i.setSelectionRange(i.value.length, i.value.length); } catch (e) {}
      }
    }
  }

  function draw() {
    if (MODE === 'A') drawA();
    else if (MODE === 'B') drawB();
    else if (MODE === 'C') drawC();
    else drawD();
  }

  function go(k) {
    MODE = k;
    Array.prototype.forEach.call(sw.children, function (b) {
      b.className = b.getAttribute('data-k') === k ? 'on' : '';
    });
    draw();
  }

  function send() {
    var t = draft.trim();
    if (!t) return;
    LOG.push({ w: 'her', t: Date.now(), s: [t] });
    draft = '';
    draw();
    setTimeout(function () {
      var r = REPLIES[ri++ % REPLIES.length];
      var msg = { w: 'him', t: Date.now(), s: r.slice(), d: (1 + Math.random() * 2).toFixed(1) + 's' };
      if (ri % 2) msg.th = '正想着怎么回你';
      LOG.push(msg);
      draw();
    }, 700);
  }

  phone.addEventListener('input', function (e) {
    if (e.target.classList.contains('inp')) draft = e.target.value;
  });
  phone.addEventListener('focusin', function (e) {
    if (e.target.classList.contains('inp')) hadFocus = true;
  });
  phone.addEventListener('keydown', function (e) {
    if (e.target.classList.contains('inp') && e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  });
  phone.addEventListener('click', function (e) {
    if (e.target.closest('.snd')) { send(); return; }
    if (e.target.closest('.musD')) { phone.querySelector('.musD').classList.toggle('ip'); return; }
    if (e.target.closest('.ham')) { phone.classList.toggle('show'); return; }
    if (e.target.closest('.maskC')) { phone.classList.remove('show'); return; }
    if (e.target.closest('.inp')) hadFocus = true;
  });

  go('A');
})();
