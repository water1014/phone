/* demo-layout.js · 四个结构开关，任意组合 */
(function () {
  var D = document;

  var MSG = [
    { me: 0, nm: '\u5b8b\u7941', t: '11/23 08:33:35',
      use: '0% \u00b7 \u8f93\u5165 295 \u00b7 \u8f93\u51fa 146',
      text: '\uff08\u772f\u7740\u773c\u770b\u7a97\u5e18\u7f1d\u91cc\u7684\u5149\uff09\u65e9\u554a\u2026\u2026\u4f60\u5012\u662f\u7761\u5f97\u633a\u9999\uff0c\u6211\u8fd8\u6ca1\u7f13\u8fc7\u6765\u5462\u3002\u6628\u665a\u90a3\u987f\u6d4b\u8bd5\uff0c\u4eca\u665a\u53ef\u522b\u518d\u6765\u4e00\u6b21\u3002' },
    { me: 1, nm: '\u6dfc\u6dfc', t: '11/23 08:34', use: '',
      text: '\u54c8\u54c8\u54c8 \u597d\u54d2' },
    { me: 0, nm: '\u5b8b\u7941', t: '11/23 08:34:50', use: '',
      text: '\u8fd8\u7b11\u3002\u4f60\u773c\u775b\u90fd\u6ca1\u7741\u5f00\u5c31\u5f00\u59cb\u7b11\u4e86\uff0c\u8ddf\u5c0f\u732b\u4e00\u6837\u3002' },
    { me: 1, nm: '\u6dfc\u6dfc', t: '11/23 08:35', use: '',
      text: '\u5c0f\u732b\u4e0d\u7528\u4e0a\u73ed\u554a' },
    { me: 0, nm: '\u5b8b\u7941', t: '11/23 08:36',
      use: '0% \u00b7 \u8f93\u5165 310 \u00b7 \u8f93\u51fa 88',
      text: '\uff08\u7b11\u4e86\u4e00\u4e0b\uff09\u90a3\u4f60\u53bb\u4e0a\u73ed\uff0c\u6211\u5728\u5bb6\u5f53\u5c0f\u732b\u3002\u665a\u4e0a\u56de\u6765\u7ed9\u4f60\u5f00\u95e8\u3002' }
  ];

  function esc(s) {
    return String(s).replace(/[&<>]/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c];
    });
  }

  var OPTS = [
    { k: 'o-a', t: 'A \u5355\u884c\u8f93\u5165' },
    { k: 'o-b', t: 'B \u60ac\u6d6e\u8f93\u5165' },
    { k: 'o-c', t: 'C \u65f6\u95f4\u8f74' },
    { k: 'o-d', t: 'D \u65e0\u9876\u680f' }
  ];

  D.getElementById('sw').innerHTML = OPTS.map(function (o) {
    return '<button type="button" data-k="' + o.k + '">' + o.t + '</button>';
  }).join('');

  D.getElementById('phone').innerHTML =
    '<div class="top" id="top">' +
      '<span class="back">\u2039</span>' +
      '<span class="who">\u5b8b\u7941 <i>\u2661</i> \u6dfc\u6dfc</span>' +
      '<span class="ic">\u2315 \u22ef</span>' +
    '</div>' +
    '<div class="scroll" id="scroll"></div>' +
    '<div class="composer" id="composer">' +
      '<div class="quick">' +
        '<button type="button" class="chip">\u5728\u5417</button>' +
        '<button type="button" class="chip">\u62b1\u62b1</button>' +
        '<button type="button" class="chip">\u665a\u5b89</button>' +
      '</div>' +
      '<div class="inbox">' +
        '<button type="button" class="rnd">\uFF0B</button>' +
        '<input class="inp" id="inp" placeholder="\u8bf4\u70b9\u4ec0\u4e48\u2026">' +
        '<span class="model">deepseek</span>' +
        '<button type="button" class="send">\u53d1</button>' +
        '<button type="button" class="rnd">\u2661</button>' +
      '</div>' +
    '</div>';

  function isC() { return D.body.classList.contains('o-c'); }

  function rowHtml(m, i, last) {
    var t = m.t.split(' ');
    var day = t[0];
    var hm = t[1] || '';
    hm = hm.slice(0, 5);

    var prev = i > 0 ? MSG[i - 1].t.split(' ')[0] : '';
    var newDay = day !== prev;

    var tl = isC()
      ? '<div class="tl">' + (newDay ? '<b>' + esc(day) + '</b>' : '') + '<span>' + esc(hm) + '</span></div>'
      : '';

    var meta = '<div class="meta">' +
        '<span class="nm">' + esc(m.nm) + '</span>' +
        '<span class="dot"></span>' +
        '<span>' + esc(m.t) + '</span>' +
      '</div>';

    var use = (m.use && last) ? '<div class="use">' + esc(m.use) + '</div>' : '';

    return '<div class="row' + (m.me ? ' me' : '') + '">' + tl +
        (m.me ? '' : '<div class="ava">' + esc(m.nm.charAt(0)) + '</div>') +
        '<div class="main">' + (isC() ? '' : meta) +
          '<div class="bub">' + esc(m.text) + '</div>' + use +
        '</div>' +
      '</div>';
  }

  function draw() {
    var box = D.getElementById('scroll');
    var html = '<div class="day">' + (isC() ? '' : '\u4eca\u5929') + '</div>';
    MSG.forEach(function (m, i) { html += rowHtml(m, i, i === MSG.length - 1); });
    box.innerHTML = html;
    box.scrollTop = box.scrollHeight;
  }

  D.getElementById('sw').addEventListener('click', function (e) {
    var b = e.target.closest('button');
    if (!b) return;
    var k = b.dataset.k;
    D.body.classList.toggle(k);
    b.classList.toggle('on');
    draw();
  });

  var inp = D.getElementById('inp');
  var comp = D.getElementById('composer');

  inp.addEventListener('focus', function () { comp.classList.add('act'); });
  inp.addEventListener('blur', function () { comp.classList.remove('act'); });

  var scroll = D.getElementById('scroll');
  var top = D.getElementById('top');

  scroll.addEventListener('scroll', function () {
    if (!D.body.classList.contains('o-d')) return;
    top.classList.toggle('peek', scroll.scrollTop < 24);
  }, false);

  draw();
  top.classList.add('peek');
})();
