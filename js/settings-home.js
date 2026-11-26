/* settings-home.js · 设置页改成列表，点进去才展开 */
(function () {
  const D = document;

  const ICON = {
    name: "<svg viewBox='0 0 24 24'><circle cx='12' cy='8' r='3.4'/><path d='M5 20c0-3.5 3.1-6 7-6s7 2.5 7 6'/></svg>",
    house: "<svg viewBox='0 0 24 24'><path d='M4 20V4'/><path d='M9 6.5h11M9 12h11M9 17.5h7'/></svg>",
    api: "<svg viewBox='0 0 24 24'><rect x='7' y='7' width='10' height='10' rx='2'/><path d='M10 3.5V7M14 3.5V7M10 17v3.5M14 17v3.5M3.5 10H7M3.5 14H7M17 10h3.5M17 14h3.5'/></svg>",
    other: "<svg viewBox='0 0 24 24'><path d='M9 3.5v5M15 3.5v5'/><path d='M6.5 8.5h11V12a5.5 5.5 0 0 1-11 0z'/><path d='M12 17.5V21'/></svg>"
  };

  const ROWS = [
    { g: '个性化', k: 'name', t: '我的资料与关系', s: '头像称呼、彼此名字、相识日期' },
    { g: '连接与能力', k: 'api', t: '模型与 API', s: '服务商、模型、密钥、请求头与用量' },
    { g: '连接与能力', k: 'other', t: '其它接口', s: '图片生成、语音与其它服务' },
    { g: '系统', k: 'house', t: '数据与小窝', s: '安装到桌面、备份、清理与重置' }
  ];

  const LABELS = {
    name: '我们是谁',
    house: '这个小窝',
    api: '接线的地方',
    other: '其它接口'
  };

  function el(tag, cls, txt) {
    const n = D.createElement(tag);
    if (cls) n.className = cls;
    if (txt != null) n.textContent = txt;
    return n;
  }

  function body() { return D.getElementById('app-body'); }

  function setView(v) {
    const b = body();
    if (b) b.setAttribute('data-st-view', v);
  }

  function top() {
    const b = body();
    if (!b) return;
    const sc = b.closest('.app-body') || b;
    if (sc) sc.scrollTop = 0;
    const cs = b.closest('.app-body');
    if (cs && cs !== sc) cs.scrollTop = 0;
  }

  function buildHome() {
    const box = el('div', 'sh');
    box.id = 'st-home';

    const hero = el('div', 'sh-hero');
    hero.appendChild(el('span', 'sh-kicker', 'PREFERENCES'));
    hero.appendChild(el('h1', 'sh-title', '设置'));
    hero.appendChild(el('p', 'sh-sub', '把这个小窝，慢慢调成喜欢的样子。'));
    box.appendChild(hero);

    const profile = el('button', 'sh-account');
    profile.type = 'button';
    profile.setAttribute('data-go', 'name');
    const avatar = el('span', 'sh-account-avatar', String(XW.S.herName || '我').trim().charAt(0) || '我');
    const info = el('span', 'sh-account-info');
    info.appendChild(el('b', '', XW.S.herName || '我的资料'));
    info.appendChild(el('i', '', (XW.S.hisName || '他') + ' · ' + (XW.S.loveDate || '设置相识日期')));
    profile.appendChild(avatar);
    profile.appendChild(info);
    profile.appendChild(el('span', 'sh-arr', '\\u203a'));
    box.appendChild(profile);

    let last = '';
    ROWS.forEach(function (r) {
      if (r.g !== last) {
        last = r.g;
        box.appendChild(el('div', 'sh-label', r.g));
      }
      const row = el('button', 'sh-row');
      row.type = 'button';
      row.setAttribute('data-go', r.k);

      const ico = el('span', 'sh-ico');
      ico.innerHTML = ICON[r.k] || '';
      row.appendChild(ico);

      const txt = el('span', 'sh-txt');
      txt.appendChild(el('b', '', r.t));
      txt.appendChild(el('i', '', r.s));
      row.appendChild(txt);
      row.appendChild(el('span', 'sh-arr', '\\u203a'));
      box.appendChild(row);
    });

    return box;
  }

  function buildCrumb() {
    const c = el('div', 'sh-crumb');
    c.id = 'st-crumb';
    c.appendChild(el('span', 'sh-back', '\u2039'));
    c.appendChild(el('b', '', '设置'));
    return c;
  }

  function openPane(k) {
    const b = body();
    if (!b) return;

    try { localStorage.setItem('xw_st_tab', k); } catch (e) {}

    Array.prototype.forEach.call(b.querySelectorAll('.st-pane'), function (p) {
      p.classList.toggle('on', p.getAttribute('data-st') === k);
    });

    const crumb = b.querySelector('#st-crumb b');
    if (crumb) crumb.textContent = LABELS[k] || '设置';

    setView('pane');
    top();
  }

  function goHome() {
    setView('home');
    top();
  }

  D.addEventListener('click', function (e) {
    const t = e.target;
    if (!t || !t.closest) return;

    const row = t.closest('.sh-row');
    if (row) {
      openPane(row.getAttribute('data-go'));
      return;
    }

    if (t.closest('#st-crumb')) goHome();
  }, false);

  let timer = null;

  function render() {
    const b = body();
    if (!b) return;
    if (!b.querySelector('#set-ai-provider')) return;
    if (!b.querySelector('.st-body')) return;

    if (!b.querySelector('#st-home')) {
      b.insertBefore(buildHome(), b.firstChild);
      const crumb = buildCrumb();
      const home = b.querySelector('#st-home');
      b.insertBefore(crumb, home.nextSibling);
      setView('home');
    }
  }

  function later() {
    if (timer) return;
    timer = setTimeout(function () {
      timer = null;
      render();
    }, 90);
  }

  if (window.MutationObserver && D.body) {
    new MutationObserver(later).observe(D.body, { childList: true, subtree: true });
  }

  render();
  setTimeout(render, 500);
  setTimeout(render, 1100);
})();
