/* beautify.js · MioWatery theme and material controls */
const THEMES = [
  { id: 'minimal', name: '雾白', accent: '#82AEB7', bg: '#F3F8F8', card: 'rgba(255,255,255,.82)' },
  { id: 'warm', name: '晨雾', accent: '#B99C91', bg: '#F8F4F1', card: 'rgba(255,255,255,.84)' },
  { id: 'cool', name: '湖光', accent: '#78A8B5', bg: '#EFF6F7', card: 'rgba(255,255,255,.80)' },
  { id: 'dark', name: '深海', accent: '#A8C9CE', bg: '#202D32', card: 'rgba(39,55,61,.86)' }
];
const WALLS = ['#F3F8F8','#EAF3F4','#F8F4F1','#F1F4F8','#FFFFFF','#E8EFF0','#202D32','#29383E'];
const DEFAULT_BEAUTIFY = { theme: 'minimal', wall: '#F3F8F8', blur: 18, radius: 22 };
let current = { ...DEFAULT_BEAUTIFY };

function initBeautify() {
  loadSettings();
  applyTheme();
  render();
}
function loadSettings() {
  try {
    const saved = JSON.parse(localStorage.getItem('xw_beautify') || 'null');
    if (saved && typeof saved === 'object') current = { ...DEFAULT_BEAUTIFY, ...saved };
  } catch (e) { current = { ...DEFAULT_BEAUTIFY }; }
  if (!THEMES.some(t => t.id === current.theme)) current.theme = 'minimal';
  current.blur = Math.max(0, Math.min(30, Number(current.blur) || 0));
  current.radius = Math.max(8, Math.min(32, Number(current.radius) || 22));
}
function saveSettings() {
  try { localStorage.setItem('xw_beautify', JSON.stringify(current)); } catch (e) {}
}
function render() {
  const el = document.getElementById('app-body');
  if (!el) return;
  el.innerHTML = '<div class="bf-wrap"><div class="bf-grid" id="bf-grid"></div><div class="bf-detail" id="bf-detail"></div></div>';
  renderGrid();
  renderDetail();
}
function renderGrid() {
  const grid = document.getElementById('bf-grid');
  if (!grid) return;
  grid.innerHTML = THEMES.map(t => `<button type="button" class="bf-card ${t.id === current.theme ? 'on' : ''}" data-id="${t.id}"><span class="thumb" style="background:linear-gradient(145deg,${t.bg},${t.card})"></span><span class="name">${t.name}</span><span class="desc">MioWatery</span></button>`).join('');
  grid.querySelectorAll('.bf-card').forEach(card => card.addEventListener('click', () => {
    current.theme = card.dataset.id;
    applyTheme();
    renderGrid();
    renderDetail();
    saveSettings();
  }));
}
function renderDetail() {
  const d = document.getElementById('bf-detail');
  if (!d) return;
  const theme = THEMES.find(t => t.id === current.theme) || THEMES[0];
  d.innerHTML = `
    <h3>当前主题：${theme.name}</h3>
    <div class="preview" id="bf-preview" style="background:${current.wall}">
      <div class="sample" style="background:${theme.card};border:1px solid rgba(255,255,255,.8);border-radius:${current.radius}px;backdrop-filter:blur(${current.blur}px)">水色卡片预览</div>
    </div>
    <div class="row"><label class="lab" for="bf-radius">卡片圆角</label><input type="range" min="8" max="32" value="${current.radius}" id="bf-radius"><span class="num" id="bf-radius-num">${current.radius}px</span></div>
    <div class="row"><label class="lab" for="bf-blur">玻璃模糊</label><input type="range" min="0" max="30" value="${current.blur}" id="bf-blur"><span class="num" id="bf-blur-num">${current.blur}px</span></div>
    <div class="row bf-wall-row"><span class="lab">页面底色</span><div class="swatches">${WALLS.map(w => `<button type="button" aria-label="背景色 ${w}" class="swatch ${w === current.wall ? 'on' : ''}" style="background:${w}" data-w="${w}"></button>`).join('')}</div></div>
    <div class="bf-actions"><button type="button" class="reset">恢复默认</button><button type="button" class="save">保存设置</button></div>`;
  const radius = d.querySelector('#bf-radius');
  const blur = d.querySelector('#bf-blur');
  radius.oninput = () => {
    current.radius = Number(radius.value);
    d.querySelector('#bf-radius-num').textContent = current.radius + 'px';
    applyTheme();
    updatePreview();
  };
  blur.oninput = () => {
    current.blur = Number(blur.value);
    d.querySelector('#bf-blur-num').textContent = current.blur + 'px';
    applyTheme();
    updatePreview();
  };
  d.querySelectorAll('.swatch').forEach(sw => sw.addEventListener('click', () => {
    current.wall = sw.dataset.w;
    applyTheme();
    renderDetail();
    saveSettings();
  }));
  d.querySelector('.reset').onclick = () => {
    current = { ...DEFAULT_BEAUTIFY };
    applyTheme();
    renderGrid();
    renderDetail();
    saveSettings();
  };
  d.querySelector('.save').onclick = () => {
    saveSettings();
    applyTheme();
    showToast('外观已保存');
  };
}
function updatePreview() {
  const sample = document.querySelector('#bf-preview .sample');
  if (sample) {
    sample.style.borderRadius = current.radius + 'px';
    sample.style.backdropFilter = 'blur(' + current.blur + 'px)';
  }
}
function applyTheme() {
  const theme = THEMES.find(t => t.id === current.theme) || THEMES[0];
  const root = document.documentElement;
  root.style.setProperty('--accent', theme.accent);
  root.style.setProperty('--accent-deep', theme.accent);
  root.style.setProperty('--bg', current.wall || theme.bg);
  root.style.setProperty('--card', theme.card);
  root.style.setProperty('--r-md', current.radius + 'px');
  root.style.setProperty('--r-lg', (current.radius + 4) + 'px');
  root.style.setProperty('--mio-user-bg', current.wall || theme.bg);
  root.style.setProperty('--mio-user-blur', current.blur + 'px');
  root.style.setProperty('--mio-radius', current.radius + 'px');
  root.classList.toggle('dark', theme.id === 'dark');
  document.body.style.backgroundColor = current.wall || theme.bg;
}
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2000);
}
window.Beautify = window.Beautify || {};
window.Beautify.theme = { state: () => ({ ...current }), apply: applyTheme };
initBeautify();
