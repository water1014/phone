/* beautify.js · MioWatery theme and material controls */
const THEMES = [
  { id: 'minimal', name: '雾白', accent: '#82AEB7', bg: '#F3F8F8', card: 'rgba(255,255,255,.82)' },
  { id: 'warm', name: '晨雾', accent: '#B99C91', bg: '#F8F4F1', card: 'rgba(255,255,255,.84)' },
  { id: 'cool', name: '湖光', accent: '#78A8B5', bg: '#EFF6F7', card: 'rgba(255,255,255,.80)' },
  { id: 'dark', name: '深海', accent: '#A8C9CE', bg: '#202D32', card: 'rgba(39,55,61,.86)' }
];
const WALLS = ['#F3F8F8','#EAF3F4','#F8F4F1','#F1F4F8','#FFFFFF','#E8EFF0','#202D32','#29383E'];
const DEFAULT_BEAUTIFY = { theme: 'minimal', wall: '#F3F8F8', blur: 18, radius: 22, wallpaper: '' };
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
  try { localStorage.setItem('xw_beautify', JSON.stringify(current)); return true; }
  catch (e) { return false; }
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
    <section class="bf-wallpaper"><div class="bf-wallpaper-head"><b>桌面壁纸</b><span>仅影响桌面背景，不改动卡片内容</span></div><div class="bf-wallpaper-preview" id="bf-wallpaper-preview" style="background-image:${current.wallpaper ? `url("${current.wallpaper}")` : 'none'}">${current.wallpaper ? '' : '<span>选择一张图片作为桌面背景</span>'}</div><div class="bf-wallpaper-actions"><button type="button" id="bf-wallpaper-pick">上传壁纸</button><button type="button" id="bf-wallpaper-clear" ${current.wallpaper ? '' : 'disabled'}>移除壁纸</button><input type="file" id="bf-wallpaper-file" accept="image/*" hidden></div><p class="bf-wallpaper-note">图片会压缩后保存在本机浏览器，不会上传到服务器。</p></section>
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
  const picker = d.querySelector('#bf-wallpaper-file');
  d.querySelector('#bf-wallpaper-pick').onclick = () => picker.click();
  picker.onchange = () => {
    const file = picker.files && picker.files[0];
    if (!file) return;
    if (!file.type || !file.type.startsWith('image/')) {
      showToast('请选择图片文件');
      picker.value = '';
      return;
    }
    const reader = new FileReader();
    reader.onerror = () => showToast('图片读取失败，请重试');
    reader.onload = () => compressWallpaper(reader.result, result => {
      if (!result) { showToast('图片处理失败，请换一张图片'); return; }
      if (result.length > 1800000) { showToast('图片仍然较大，请换一张图片'); return; }
      const previousWallpaper = current.wallpaper;
      current.wallpaper = result;
      if (!saveSettings()) { current.wallpaper = previousWallpaper; showToast('本机存储空间不足，壁纸未保存'); return; }
      applyTheme();
      renderDetail();
      showToast('桌面壁纸已应用');
    });
    reader.readAsDataURL(file);
  };
  d.querySelector('#bf-wallpaper-clear').onclick = () => {
    current.wallpaper = '';
    saveSettings();
    applyTheme();
    renderDetail();
    showToast('已移除桌面壁纸');
  };
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
function compressWallpaper(source, done) {
  const img = new Image();
  img.onerror = () => done('');
  img.onload = () => {
    const maxSide = 1440;
    const scale = Math.min(1, maxSide / Math.max(img.naturalWidth, img.naturalHeight));
    const canvas = document.createElement('canvas');
    canvas.width = Math.max(1, Math.round(img.naturalWidth * scale));
    canvas.height = Math.max(1, Math.round(img.naturalHeight * scale));
    const ctx = canvas.getContext('2d');
    if (!ctx) { done(''); return; }
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    try { done(canvas.toDataURL('image/jpeg', 0.76)); } catch (e) { done(''); }
  };
  img.src = source;
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
  const home = document.getElementById('home');
  if (home) {
    home.style.setProperty('background-color', current.wallpaper ? 'transparent' : (current.wall || theme.bg), 'important');
    home.style.setProperty('background-image', current.wallpaper ? 'linear-gradient(rgba(242,248,248,.10),rgba(242,248,248,.10)), url("' + current.wallpaper + '")' : 'none', 'important');
    home.style.setProperty('background-size', current.wallpaper ? 'cover' : 'auto', 'important');
    home.style.setProperty('background-position', current.wallpaper ? 'center center' : 'initial', 'important');
    home.style.setProperty('background-attachment', current.wallpaper ? 'fixed' : 'scroll', 'important');
  }
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
if (window.MutationObserver && document.body) {
  let wallpaperObserverTimer = null;
  new MutationObserver(() => {
    if (wallpaperObserverTimer) return;
    wallpaperObserverTimer = setTimeout(() => {
      wallpaperObserverTimer = null;
      const home = document.getElementById('home');
      if (home) applyTheme();
    }, 60);
  }).observe(document.body, { childList: true, subtree: true });
}
