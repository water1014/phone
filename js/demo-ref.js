/* demo-ref.js · 四套排法，同一批假消息，只换结构 */
(function () {
  var D = document;
  var phone = D.getElementById('phone');
  var sw = D.getElementById('sw');

  var MSG = [
    { w: 'him', s: ['下雨了，出门带伞。'], th: '想到你上次淋了一场，回来打了三个喷嚏', u: '93% 输入 197.6k · 命中 78.6k(40%) · 输出 250 · 2 轮' },
    { w: 'her', s: ['带了带了。', '就是不想上课。'] },
    { w: 'him', s: ['一节大课而已。', '晚上给你带吃的。'], th: '想说带汤，又怕她嫌重' },
    { w: 'her', s: ['不要香菜。'], stk: 1 },
    { w: 'him', s: ['记住了。', '今天左边那扇窗你别开，风大。'], th: '昨天她在窗边坐了一下午，晚上说头疼' }
  ];

  var NAME = { him: '祁', her: '淼' };

  var heads = [
    ['A', 'A 清静'],
    ['B', 'B 顺手'],
    ['C', 'C 目录'],
    ['D', 'D 陪伴']
  ];

  heads.forEach(function (h) {
    var b = D.createElement('button');
    b.textContent = h[1];
    b.setAttribute('data-k', h[0]);
    b.onclick = function () { go(h[0]); };
    sw.appendChild(b);
  });

  function ps(arr) {
    return arr.map(function (x) { return '<p>' + x + '</p>'; }).join('');
  }
  function sp(arr) {
    return arr.map(function (x) { return '<span>' + x + '</span>'; }).join('');
  }

  /* ---------------- A 清静：无气泡，正文铺在底色上，时间偶尔居中 ---------------- */
  function drawA() {
    var h = '<div class="topA">';
    h += '<b class="ib">\u2039</b>';
    h += '<div class="fa"><i>祁</i><em>\u2661</em><i>淼</i></div>';
    h += '<b class="ib">\u22EF</b>';
    h += '</div>';

    h += '<div class="flowA">';
    h += '<div class="tmA">08:41</div>';
    MSG.forEach(function (m, i) {
      h += '<div class="bA ' + m.w + '">';
      h += '<div class="avA">' + NAME[m.w] + '</div>';
      h += '<div class="txA">';
      h += ps(m.s);
      if (m.stk) h += '<div class="stkA">表情包</div>';
      if (m.u) h += '<div class="useA">\u25AE ' + m.u + '</div>';
      h += '</div></div>';
      if (i === 2) h += '<div class="tmA">08:52</div>';
    });
    h += '</div>';

    h += '<div class="footA">\u2299 1 次工具调用 · \u2299 3 条记忆</div>';
    h += '<div class="inA"><b class="rb">\uFF0B</b><span>输入消息\u2026</span><b class="rb">\u25B6</b><b class="rb">\u2661</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mA';
  }

  /* ---------------- B 顺手：一条输入，思考一行标签，头像贴气泡外侧 ---------------- */
  function drawB() {
    var h = '<div class="topB">';
    h += '<i class="avB">祁</i>';
    h += '<div class="nmB"><b>宋祁</b><em>&gt; \u2297 &lt;</em></div>';
    h += '<b class="ib">\u2261</b>';
    h += '</div>';

    h += '<div class="flowB">';
    MSG.forEach(function (m) {
      if (m.th) {
        h += '<details class="thB"><summary>\u2726 思考 · 2 个动作</summary><p>' + m.th + '</p></details>';
      }
      h += '<div class="rwB ' + m.w + '"><i class="avB">' + NAME[m.w] + '</i><div class="bubB">';
      h += sp(m.s);
      if (m.stk) h += '<div class="stkB">表情包</div>';
      h += '</div></div>';
    });
    h += '</div>';

    h += '<div class="inB"><b class="rb">\uFF0B</b><span>Message\u2026</span><b class="rb">\uD83C\uDFA4</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mB';
  }

  /* ---------------- C 目录：侧栏抽屉，居中衬线名，用量折叠，底部胶囊页签 ---------------- */
  function drawC() {
    var h = '';

    h += '<div class="maskC"></div>';
    h += '<div class="railC">';
    h += '<div class="rhC">宋祁 \u00D7 淼淼<em>~/xiaowo</em></div>';
    h += '<div class="lgC">日常</div>';
    h += '<a>together/ <s>9</s></a>';
    h += '<a>his corner/ <s>8</s></a>';
    h += '<a>keepsakes/ <s>4</s></a>';
    h += '<div class="lgC">屋子</div>';
    h += '<a><i>\u2302</i>聊天</a>';
    h += '<a><i>\u25A4</i>日记</a>';
    h += '<a><i>\u25A6</i>相册</a>';
    h += '<a><i>\u266B</i>音乐</a>';
    h += '<div class="lgC">设置</div>';
    h += '<a><i>\u25D4</i>用量</a>';
    h += '<a><i>\u263E</i>夜间<b class="tg"></b></a>';
    h += '<a><i>i</i>关于</a>';
    h += '</div>';

    h += '<div class="topC">';
    h += '<b class="ib ham">\u2261</b>';
    h += '<div class="nmC">宋祁 \u2661 淼淼</div>';
    h += '<b class="ib">\u2315</b>';
    h += '</div>';

    h += '<div class="flowC">';
    MSG.forEach(function (m) {
      h += '<div class="rwC ' + m.w + '"><i class="avC">' + NAME[m.w] + '</i><div class="bubC">';
      h += sp(m.s);
      if (m.stk) h += '<div class="stkC">表情包</div>';
      h += '</div></div>';
      if (m.u) {
        h += '<details class="useC"><summary>输入 302,863 · 输出 245 · 命中 99.6%</summary><p>' + m.u + '</p></details>';
      }
    });
    h += '</div>';

    h += '<div class="inC"><b class="rb">\uFF0B</b><span>你说点\u2026</span><b class="rb">\u266B</b></div>';
    h += '<div class="tabC"><b class="on">聊天</b><b>日记</b></div>';

    phone.innerHTML = h;
    phone.className = 'phone mC';
  }

  /* ---------------- D 陪伴：顶上浮音乐卡，每轮一行耗时，表情包裸图 ---------------- */
  function drawD() {
    var h = '<div class="topD">';
    h += '<div class="nmD"><b>宋祁</b><em>deepseek-flash</em></div>';
    h += '<b class="ib">\u2315</b>';
    h += '</div>';

    h += '<div class="musD">';
    h += '<i>\u266B</i>';
    h += '<div class="mi"><b>Mind Games</b><em>Sickick</em><div class="barD"><u></u></div></div>';
    h += '</div>';

    h += '<div class="flowD">';
    MSG.forEach(function (m) {
      h += '<div class="cdD">\u2726 Conducted ' + (m.w === 'him' ? '2.9s' : '1.4s') + '</div>';
      h += '<div class="rowD ' + m.w + '"><i class="avD">' + NAME[m.w] + '</i><div class="bubD">';
      h += sp(m.s);
      if (m.stk) h += '<div class="stkD">表情包</div>';
      h += '</div></div>';
    });
    h += '</div>';

    h += '<div class="inD"><b class="rb">\uFF0B</b><span>Type something\u2026</span><b class="mdD">Thinking</b><b class="rb">\u2191</b></div>';
    phone.innerHTML = h;
    phone.className = 'phone mD';
  }

  function go(k) {
    Array.prototype.forEach.call(sw.children, function (b) {
      b.className = b.getAttribute('data-k') === k ? 'on' : '';
    });
    if (k === 'A') drawA();
    else if (k === 'B') drawB();
    else if (k === 'C') drawC();
    else drawD();
  }

  phone.addEventListener('click', function (e) {
    if (e.target.closest('.ham')) phone.classList.toggle('show');
    else if (e.target.closest('.maskC')) phone.classList.remove('show');
  });

  go('A');
})();
