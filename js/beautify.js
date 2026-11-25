/* beautify.js */
const THEMES=[
  {id:'minimal',name:'极简',accent:'#333333',bg:'#FFFFFF',card:'#FFFFFF'},
  {id:'warm',name:'暖色',accent:'#333333',bg:'#FFFFFF',card:'#FFFFFF'},
  {id:'cool',name:'冷色',accent:'#333333',bg:'#FFFFFF',card:'#FFFFFF'},
  {id:'dark',name:'夜幕',accent:'#FFFFFF',bg:'#000000',card:'#111111'}
];
const WALLS=[
  '#FFFFFF','#F5F5F5','#EEEEEE','#E5E5E5',
  '#111111','#1A1A1A','#222222','#333333'
];
let current={theme:'minimal',wall:'#FFFFFF',blur:0,radius:16};
function initBeautify(){loadSettings();render();bind();}
function loadSettings(){const s=localStorage.getItem('xw_beautify');if(s)current=JSON.parse(s);}
function saveSettings(){localStorage.setItem('xw_beautify',JSON.stringify(current));}
function render(){
  const el=document.getElementById('app-body');if(!el)return;
  el.innerHTML='<div class="bf-wrap"><div class="bf-grid" id="bf-grid"></div><div class="bf-detail" id="bf-detail"></div></div>';
  renderGrid();renderDetail();
}
function renderGrid(){
  const grid=document.getElementById('bf-grid');if(!grid)return;
  grid.innerHTML=THEMES.map(t=>`<div class="bf-card ${t.id===current.theme?'on':''}" data-id="${t.id}"><div class="thumb" style="background:${t.bg}"></div><div class="name">${t.name}</div></div>`).join('');
  grid.querySelectorAll('.bf-card').forEach(c=>c.onclick=()=>{current.theme=c.dataset.id;saveSettings();applyTheme();renderGrid();renderDetail();});
}
function renderDetail(){
  const d=document.getElementById('bf-detail');if(!d)return;
  const t=THEMES.find(x=>x.id===current.theme)||THEMES[0];
  d.innerHTML=`<h3>当前主题: ${t.name}</h3><div class="preview" style="background:${current.wall}"><div class="sample" style="background:${t.card};border-radius:${current.radius}px">卡片预览</div></div><div class="row"><span class="lab">圆角</span><input type="range" min="0" max="24" value="${current.radius}" id="bf-radius"><span class="num">${current.radius}px</span></div><div class="row"><span class="lab">背景</span><div class="swatches">${WALLS.map(w=>`<div class="swatch ${w===current.wall?'on':''}" style="background:${w}" data-w="${w}"></div>`).join('')}</div></div><div class="bf-actions"><button class="reset">重置</button><button class="save">保存</button></div>`;
  const r=d.querySelector('#bf-radius');if(r)r.oninput=e=>{current.radius=+e.target.value;r.nextElementSibling.textContent=current.radius+'px';};
  d.querySelectorAll('.swatch').forEach(s=>s.onclick=()=>{current.wall=s.dataset.w;saveSettings();applyTheme();renderDetail();});
  d.querySelector('.reset').onclick=()=>{current={theme:'minimal',wall:'#FFFFFF',blur:0,radius:16};saveSettings();applyTheme();renderGrid();renderDetail();};
  d.querySelector('.save').onclick=()=>{saveSettings();applyTheme();showToast('已保存');};
}
function applyTheme(){
  const t=THEMES.find(x=>x.id===current.theme)||THEMES[0];
  document.documentElement.style.setProperty('--accent',t.accent);
  document.documentElement.style.setProperty('--bg',current.wall);
  document.documentElement.style.setProperty('--card',t.card);
  document.documentElement.style.setProperty('--r-md',current.radius+'px');
  document.documentElement.style.setProperty('--r-lg',(current.radius+4)+'px');
  if(t.id==='dark')document.documentElement.classList.add('dark');else document.documentElement.classList.remove('dark');
}
function bind(){}
function showToast(msg){const t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');setTimeout(()=>t.classList.remove('show'),2000);}
initBeautify();
