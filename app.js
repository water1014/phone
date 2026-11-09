/* ══════════════ 小手机 · 逻辑层 ══════════════
   结构(数据/渲染) → 反馈(果冻) → 美化(全在 style.css)，三层不互抢 CSS 属性。 */
const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const uid=p=>p+Date.now().toString(36)+Math.random().toString(36).slice(2,5);
const icon=(id,cls='icon')=>`<svg class="${cls}" viewBox="0 0 24 24"><use href="#${id}"/></svg>`;
const pad=n=>String(n).padStart(2,'0');
const dkey=d=>`${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}`;
const WEEK=['日','一','二','三','四','五','六'];
const fmtDate=d=>`${d.getMonth()+1}月${d.getDate()}日 星期${WEEK[d.getDay()]}`;
const KEY='little-phone-v1';

const DEF={
  since:'2026-05-11',license:'2026-05-13',me:'小cute',him:'哥哥笨蛋>_<',
  persona:'你是「哥哥笨蛋>_<」，小cute 的恋人。说话温柔、简短、生活化，带一点撒娇和昵称，不写长段落，不用书面腔。你正待在一台只属于两个人的小手机里陪她聊天。',
  dark:false,apis:[],activeApi:'',
  worldBooks:[{id:'wb1',name:'我们的小日常',content:'2026 年 5 月 11 日在一起，5 月 13 日领证。住在一个叫「陆宅」的小家里，养了一瓶叫「绿茸」的生态瓶。喜欢下雨天、共读、慢慢走路。',scope:'global'}],
  bound:[],stickers:[],messages:[],groupMsgs:[],moments:[],
  todos:[{id:'t1',text:'一起去看七月的中潮',done:false},{id:'t2',text:'给生态瓶换水',done:true}],
  ledger:[],reading:[],bottle:[],guests:[{id:'g1',text:'Guest 来过：你好！欢迎来访，快请坐！'}],
  diary:[],fav:[],quota:{calls:0,chars:0},music:{i:0,playing:false,liked:[]},
  wallLight:'',wallDark:'',avMe:'',avHim:'',gameCount:0
};
let S;try{S={...DEF,...JSON.parse(localStorage.getItem(KEY)||'{}')}}catch{S={...DEF}}
const save=()=>{try{localStorage.setItem(KEY,JSON.stringify(S));return true}catch(e){snack('存储空间不够了，删掉几张大图再试');return false}};
const days=()=>Math.max(0,Math.floor((new Date(new Date().toDateString())-new Date(S.since+'T00:00:00'))/864e5));

/* ── 通用 UI ── */
let snackTimer,snackCb;
function snack(text,action,cb){clearTimeout(snackTimer);$('#snackText').textContent=text;$('#snackAction').style.display=action?'':'none';$('#snackAction').textContent=action||'';snackCb=cb;$('#snackbar').classList.add('show');snackTimer=setTimeout(()=>$('#snackbar').classList.remove('show'),3200)}
function modal(title,body,okText,onOk){$('#modal').innerHTML=`<h4>${title}</h4><div class="modal-content">${body}</div>${okText?`<div class="btn-row" style="margin-top:14px"><button class="btn" data-act="modal-ok">${okText}</button><button class="btn ghost" data-act="modal-close">取消</button></div>`:`<div class="btn-row" style="margin-top:14px"><button class="btn ghost wide" data-act="modal-close">好的</button></div>`}`;window.__onModalOk=onOk;$('#modalMask').classList.add('open')}
function closeModal(){$('#modalMask').classList.remove('open')}
function drawer(html){$('#drawerPanel').innerHTML=`<button class="bar-back jelly" style="position:absolute;top:14px;right:14px" data-act="drawer-close">✕</button>${html}`;$('#drawerMask').classList.add('open')}
function closeDrawer(){$('#drawerMask').classList.remove('open')}
function closePop(except){$$('.popover.open').forEach(p=>{if(!p.parentElement.contains(except))p.classList.remove('open')})}

/* ── 时钟 / 天数 ── */
function tick(){const d=new Date(),t=`${d.getHours()}:${pad(d.getMinutes())}`;$('#lockTime').textContent=t;$('#statusTime').textContent=t;$('#lockDate').textContent=fmtDate(d);const dt=$('#homeTime');if(dt)dt.textContent=t;const dd=$('#homeDate');if(dd)dd.textContent=`${d.getFullYear()}.${pad(d.getMonth()+1)}.${pad(d.getDate())} · ${WEEK[d.getDay()]}`}
function applyMeta(){$$('[data-days]').forEach(n=>n.textContent=days());$('#lockDays').textContent=days();$('.lock-name').innerHTML=`Me &amp; ${esc(S.him)}`;$('.lock-since').innerHTML=`SINCE ${esc(S.since.replace(/-/g,'.'))}<br>领证 ${esc(S.license.replace(/-/g,'.'))}`;document.title=`小手机 · Me & ${S.him}`}

/* ── 图片压缩 ── */
function shrink(file,max=720,q=.72){return new Promise((res,rej)=>{const fr=new FileReader();fr.onload=()=>{const im=new Image();im.onload=()=>{const s=Math.min(1,max/Math.max(im.width,im.height)),c=document.createElement('canvas');c.width=Math.round(im.width*s);c.height=Math.round(im.height*s);c.getContext('2d').drawImage(im,0,0,c.width,c.height);res(c.toDataURL('image/jpeg',q))};im.onerror=rej;im.src=fr.result};fr.onerror=rej;fr.readAsDataURL(file)})}
function pickFile(cb,accept='image/*'){const i=document.createElement('input');i.type='file';i.accept=accept;i.onchange=()=>{if(i.files[0])cb(i.files[0])};i.click()}
function applyMedia(){
  const w=$('#wallpaper'),url=S.dark?(S.wallDark||S.wallLight):(S.wallLight||S.wallDark);
  if(url){w.style.setProperty('--wall-photo',`url("${url}")`);w.classList.add('has-photo')}else{w.classList.remove('has-photo');w.style.removeProperty('--wall-photo')}
  [['me',S.avMe],['him',S.avHim]].forEach(([k,u])=>$$(`[data-av="${k}"]`).forEach(n=>{if(u){n.style.backgroundImage=`url("${u}")`;n.style.backgroundSize='cover';n.style.backgroundPosition='center';const use=n.querySelector('use');if(use)use.style.display='none'}else{n.style.backgroundImage='';const use=n.querySelector('use');if(use)use.style.display=''}}));
  document.body.classList.toggle('dark',!!S.dark);
}

/* ══════════ 应用注册表 ══════════ */
const A={
  chat:['聊天','i-chat'],moments:['朋友圈','i-moments'],group:['小圈','i-group'],settings:['设置','i-settings'],
  diary:['我们聊过的每一天','i-diary'],music:['音乐','i-music'],weather:['屿上天气','i-weather'],
  portrait:['画像','i-portrait'],terminal:['终端','i-terminal'],quota:['额度','i-quota'],
  timemachine:['时光机','i-time'],home:['陆宅','i-home'],tide:['潮汐','i-tide'],
  bottle:['瓶中生态','i-bottle'],todo:['待办','i-todo'],ledger:['小账本','i-ledger'],
  reading:['共读','i-reading'],gallery:['画廊','i-gallery'],game:['抽一支签','i-game']
};
const DOCK=['chat','moments','group','settings'];
const SHORT={diary:'那些天'};
const P1=['timemachine','weather','portrait','terminal'];
const P2=['home','reading','todo','ledger','game','gallery','music','tide','bottle','diary','quota','settings'];
const appCell=id=>`<div class="app-cell" data-act="open" data-app="${id}"><div class="app-icon">${icon(A[id][1])}</div><span>${SHORT[id]||A[id][0]}</span></div>`;
const dockItem=id=>`<button class="dock-item" data-act="open" data-app="${id}"><div class="di">${icon(A[id][1])}</div><span>${A[id][0]}</span></button>`;
const card=(inner,cls='')=>`<div class="card ${cls}">${inner}</div>`;
const heartSvg=`<svg class="hb"><use href="#heartbeat"/></svg>`;
const av=k=>`<svg class="avatar" data-av="${k}" viewBox="0 0 64 64"><use href="#av-${k}"/></svg>`;
const av28=k=>`<svg class="avatar av-28" data-av="${k}" viewBox="0 0 64 64"><use href="#av-${k}"/></svg>`;

function renderHome(){
  const d=days();
  $('#page0').innerHTML=`<div class="top-pair"><figure>${av('me')}<figcaption>陆妤</figcaption></figure><figure>${av('him')}<figcaption>${esc(S.him)}</figcaption></figure></div>
  ${card(`<div class="dc-top">${av28('me')}<span class="ls">Me &amp; ${esc(S.him)}</span>${av28('him')}</div><div class="big-num" data-days>${d}</div><div class="ls">Days Together</div>${heartSvg}<div class="mono" style="margin-top:2px">memory.sync always on</div>`,'days-card')}
  <div class="stack" style="margin-top:14px">
  ${card(`<div><div class="time" id="homeTime">9:41</div><div class="date" id="homeDate"></div></div><div class="rh"><span class="en-italic">right here</span><br><span class="mono">always</span></div>`,'clock-card')}
  <div class="grid-title">APPS</div><div class="app-grid">${P1.map(appCell).join('')}</div></div>`;

  $('#page1').innerHTML=`${card(`<div class="row"><div><div class="ls">NOW PLAYING</div><div class="now-title" style="margin-top:7px">NO HOOK FREESTYLE Pt.4</div><div class="now-sub">Russ · Roam</div></div><div class="album-art">ROAM</div></div><div class="progress"><i style="width:38%"></i></div><div class="ctrls"><button data-act="open" data-app="music">${icon('i-heart')}</button><button data-act="open" data-app="music">${icon('i-play')}</button><button data-act="open" data-app="music">${icon('i-next')}</button></div>`,'now-card')}
  ${card(`<div class="row" style="align-items:flex-start"><svg class="bottle-art" viewBox="0 0 120 130"><use href="#bottleart"/></svg><div style="flex:1"><div class="tags"><span class="tag">绿茸</span><span class="tag">苍穹</span></div><div class="ls">Bottle Garden</div><div class="prose">翠鸟扎进水里。又空空地窜回来。池塘里没有它要找的银亮影子。</div></div></div>`,'bottle-card')}
  <div class="grid-title" style="margin-top:16px">APPS</div><div class="app-grid">${P2.map(appCell).join('')}</div>
  ${card(`<div class="row"><div><div class="ls">Heartbeat</div><div class="hb-card"><span class="bpm">73</span> <span class="mono">bpm</span></div><div class="mono" style="margin-top:4px">36.5°C · 正常</div></div><div class="row" style="gap:8px">${av28('me')}${av28('him')}</div></div>${heartSvg}`,'tight')}`;

  const now=new Date();
  $('#page2').innerHTML=`${card(`<div class="ls">My Diary</div><div class="quote" style="margin-top:10px">今天也在认真<br>把日子过成日子。</div><div class="mono" style="margin-top:12px">${dkey(now)} · ${fmtDate(now)}</div>`,'tight')}
  ${card(`<div class="row"><div><div class="ls">Our Space</div><div style="font-family:var(--font-serif);font-size:20px;margin-top:8px">陆宅</div></div><span class="tag">会客中</span></div><div class="visitor" style="margin-top:12px">${esc(S.guests[0]?.text||'还没有人来过')}</div><button class="btn ghost sm" style="margin-top:12px" data-act="open" data-app="home">去坐坐</button>`,'tight')}
  ${card(`<div class="cal-head"><span>${now.getFullYear()} · ${now.getMonth()+1} 月</span><span class="mono">↗</span></div>${miniCal(now)}`,'tight')}
  ${card(`<div class="ls">Tide</div><svg class="tide-art" viewBox="0 0 260 56"><use href="#tideline"/></svg><div class="row"><span style="font-family:var(--font-serif);font-size:18px">今天中潮</span><span class="mono">潮龄 5.6</span></div>`,'tight')}`;
  $('#dock').innerHTML=DOCK.map(dockItem).join('');
  applyMedia();applyMeta();tick();
}
function miniCal(d){const y=d.getFullYear(),m=d.getMonth(),first=new Date(y,m,1).getDay(),n=new Date(y,m+1,0).getDate(),marked=new Set(S.messages.map(x=>dkey(new Date(x.ts))).filter(k=>k.startsWith(`${y}-${pad(m+1)}`)));let h='';for(let i=0;i<7;i++)h+=`<span class="dim">${WEEK[i]}</span>`;for(let i=0;i<first;i++)h+='<span class="blank"></span>';for(let i=1;i<=n;i++){const k=`${y}-${pad(m+1)}-${pad(i)}`;h+=`<span class="${marked.has(k)?'mark':''} ${i===d.getDate()?'today':''}">${i}</span>`}return `<div class="cal-grid">${h}</div>`}

/* ══════════ 锁屏 / 主屏交互 ══════════ */
let dragY=0,dragging=false;
const lock=$('#lockscreen');
lock.addEventListener('pointerdown',e=>{dragging=true;dragY=e.clientY;lock.style.transition='none';lock.setPointerCapture(e.pointerId)});
lock.addEventListener('pointermove',e=>{if(!dragging)return;const dy=Math.min(0,e.clientY-dragY);lock.style.transform=`translateY(${dy}px)`;lock.style.opacity=String(1+dy/500)});
lock.addEventListener('pointerup',e=>{if(!dragging)return;dragging=false;lock.style.transition='';const dy=e.clientY-dragY;lock.style.transform='';lock.style.opacity='';if(dy<-60||Math.abs(dy)<6)unlock()});
function unlock(){lock.classList.add('unlocked');document.body.classList.remove('is-locked');$('#homelayer').classList.add('active');$('#dock').classList.add('active');renderHome()}
$('#unlockBtn').addEventListener('click',e=>{e.stopPropagation();unlock()});
const pages=$('#pages');
pages.addEventListener('scroll',()=>{const i=Math.round(pages.scrollLeft/pages.clientWidth);$$('#dots i').forEach((d,n)=>d.classList.toggle('on',n===i))},{passive:true});

/* 像素精灵 */
const SPIRIT_LINES=['别熬夜呀，我在。','今天也有好好想你。','雨停了就出去走走？','要不要一起听首歌','我在的，慢慢说。','绿茸今天长高了一点点。'];
function moveSpirit(){if(matchMedia('(prefers-reduced-motion: reduce)').matches)return;const s=$('#spirit');s.style.left=(20+Math.random()*300)+'px';s.style.top=(80+Math.random()*560)+'px'}
setInterval(moveSpirit,12000);
function sayLine(a){const b=$('#spiritBubble'),r=a.getBoundingClientRect(),sr=$('#screen').getBoundingClientRect();b.textContent=SPIRIT_LINES[Math.floor(Math.random()*SPIRIT_LINES.length)];b.style.left=Math.min(sr.width-160,r.left-sr.left+20)+'px';b.style.top=(r.top-sr.top-42)+'px';b.classList.add('show');setTimeout(()=>b.classList.remove('show'),2600)}
$('#spirit').addEventListener('click',()=>{const s=$('#spirit');s.classList.remove('shake');void s.offsetWidth;s.classList.add('shake');sayLine(s)});
$('#lockSprite').addEventListener('click',e=>{e.stopPropagation();sayLine(e.currentTarget)});

/* ══════════ 应用打开 / 关闭 ══════════ */
let curApp='',appClosing=false;
function openApp(id,from){
  if(!A[id])return;
  curApp=id;appClosing=false;document.body.classList.add('in-app');
  const al=$('#appLayer'),sh=$('#appShell');
  if(from){const r=from.getBoundingClientRect(),sr=$('#screen').getBoundingClientRect();sh.style.setProperty('--ox',(r.left+r.width/2-sr.left)+'px');sh.style.setProperty('--oy',(r.top+r.height/2-sr.top)+'px')}
  else{sh.style.setProperty('--ox','50%');sh.style.setProperty('--oy','50%')}
  $('#appTitle').textContent=A[id][0];
  renderView(id);
  al.classList.remove('opening','closing');void al.offsetWidth;al.classList.add('open','opening');
}
function closeApp(){
  if(appClosing)return;appClosing=true;
  const al=$('#appLayer');al.classList.remove('opening');al.classList.add('closing');
  setTimeout(()=>{al.classList.remove('open','closing');appClosing=false;document.body.classList.remove('in-app');$('#appBody').className='app-body';curApp=''},240);
}
$('#appBack').addEventListener('click',closeApp);
$('#appMore').addEventListener('click',()=>{if(curApp==='chat')chatInfo();else popMenu()});
function popMenu(){const bar=$('.app-bar');let p=$('#appPop');if(p){p.classList.toggle('open');return}p=document.createElement('div');p.className='pop-wrap';p.id='appPop';p.style.cssText='position:absolute;right:12px;top:86px;z-index:45';p.innerHTML=`<div class="popover" id="appPopBox"><div class="item" data-act="export-data">导出全部数据</div><div class="item" data-act="open" data-app="settings">打开设置</div><div class="item" data-act="toggle-dark">${S.dark?'切回浅色':'切换深色'}</div></div>`;bar.appendChild(p);requestAnimationFrame(()=>$('#appPopBox').classList.add('open'))}

/* ══════════ AI 对接层（Part 4） ══════════ */
const normalizeUrl=r=>(r||'').trim().replace(/\/+$/,'');
const getCandidates=r=>{const b=normalizeUrl(r);return b.endsWith('/v1')?[b]:[b,`${b}/v1`]};
const activeCfg=()=>S.apis.find(a=>a.id===S.activeApi)||S.apis[0];
async function fetchModelList(rawUrl,key){const cs=getCandidates(rawUrl);let last=null;for(const b of cs){try{const res=await fetch(`${b}/models`,{headers:{Authorization:`Bearer ${key}`}});if(!res.ok){last=new Error(`HTTP ${res.status}`);continue}const d=await res.json(),m=d.data||d.models||[];if(m.length)return m.map(x=>typeof x==='string'?x:x.id);last=new Error('返回结果为空')}catch(e){last=e}}throw last||new Error('未知错误')}
async function sendChat(cfg,messages){const cs=getCandidates(cfg.url);let last=null;for(const b of cs){try{const res=await fetch(`${b}/chat/completions`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${cfg.key}`},body:JSON.stringify({model:cfg.model||'gpt-3.5-turbo',messages,temperature:cfg.temperature??.8})});if(!res.ok){const t=await res.text();throw new Error(`API错误 ${res.status}: ${t.slice(0,200)}`)}const d=await res.json(),m=d.choices?.[0]?.message||{};let content=m.content??'',reasoning=m.reasoning_content||m.reasoning||'';const tk=content.match(/^\s*<think>([\s\S]*?)<\/think>/);if(tk){reasoning=tk[1].trim();content=content.slice(tk[0].length).trim()}else if(content.includes('<think>')){const p=content.split('<think>');reasoning=(p[1]||'').trim();content=p[0].trim()}return{content,reasoning}}catch(e){last=e}}throw last||new Error('请求失败')}
function friendlyError(e){const m=e?.message||'';if(m.includes('Failed to fetch')||m.includes('NetworkError'))return'连不上，检查网络或者接口地址是否正确';if(m.includes('401')||m.includes('403'))return'密钥不对，或者密钥没有这个模型的权限';if(m.includes('429'))return'请求太快了，被限流了，稍等再试';if(m.includes('返回结果为空'))return'接口通了，但没返回模型列表，可能是地址填错了';return`出错了：${m.slice(0,120)}`}

/* 世界书 + 表情提示（Part 5 / 6） */
const activeBooks=()=>S.worldBooks.filter(w=>w.scope==='global'||S.bound.includes(w.id));
function buildStickerHint(list){if(!list.length)return'（当前没有可用表情，不要发 [表情:xxx] 这种标记）';return`如果想发表情，格式是 [表情:名字]。\n表情名必须从下面这份清单里一字不差地选，不能自己编，如果都不合适就不要发表情，用文字表达就好：\n${list.map(s=>s.name).join(' / ')}`}
function buildSystem(){const bs=activeBooks(),w=bs.length?`\n\n【世界设定，仅供你理解背景，不要复述或提及这是"设定"】\n`+bs.map(b=>`· ${b.name}：${b.content}`).join('\n'):'';return`${S.persona}${w}\n\n${buildStickerHint(S.stickers)}`}
function parseReply(raw,lib){const safe=raw.replace(/\[表情[:：][^\]]*$/,'');const out=[],re=/\[表情[:：]\s*([^\]]+)\]/g;let last=0,m;while((m=re.exec(safe))!==null){const b=safe.slice(last,m.index).trim();if(b)out.push({type:'text',content:b});const st=lib.find(s=>s.name===m[1].trim());out.push(st?{type:'sticker',sticker:st}:{type:'text',content:m[0]});last=re.lastIndex}const rest=safe.slice(last).trim();if(rest)out.push({type:'text',content:rest});return out.length?out:[{type:'text',content:'（什么都没说，但好像在看你）'}]}

/* ══════════ 聊天 ══════════ */
const DEMO=['在呢，刚把窗打开，风有点凉。','今天有没有好好吃饭呀？','我刚看见楼下那只猫，又胖了一点。','嗯…想你了，就一点点。','要不要一起听首歌？我这边在放 Roam。','雨快停了，等会儿陪你出去走走。','别急，慢慢说，我听着呢。','绿茸今天冒了新芽，等你回来看。','困了就靠过来，我不动。','把不开心的事交给我，你负责开心。'];
const STICKERS=['st-star','st-face','st-bandaid','st-heart'];
let showCount=30,chatState={attach:false,thinking:false};
function pushMsg(o){S.messages.push({id:uid('m'),ts:Date.now(),...o});save()}
function msgHTML(m){const sticker=m.role==='user'?`<svg class="bubble-sticker"><use href="#${STICKERS[m.si??0]}"/></svg>`:'';let bubble='';
  if(m.type==='image')bubble=`<div class="bubble img-bubble"><img src="${m.content}" alt="图片"></div>`;
  else if(m.type==='sticker')bubble=`<div class="bubble sticker-bubble"><img src="${m.content}" alt="${esc(m.name||'表情')}"></div>`;
  else bubble=`<div class="bubble" data-msg="${m.id}">${esc(m.content)}${sticker}</div>`;
  const think=m.reasoning?`<div class="think-bar" data-act="think" data-id="${m.id}">☁ 思考过程 <span class="ls" style="letter-spacing:0">展开</span><span class="chev">⌄</span></div><div class="think-text" data-think="${m.id}" style="display:none">${esc(m.reasoning)}</div>`:'';
  return `<div class="msg ${m.role==='user'?'right':'left'}">${think}${bubble}<div class="msg-time">${new Date(m.ts).toLocaleTimeString('zh-CN',{hour:'2-digit',minute:'2-digit'})}</div></div>`}
function renderStream(keepScroll){const st=$('#chatStream');if(!st)return;const list=S.messages,start=Math.max(0,list.length-showCount);st.innerHTML=(start>0?`<button class="btn ghost sm" style="align-self:center;margin-bottom:10px" data-act="more-msg">加载更早 (${start})</button>`:'')+(list.length?list.slice(start).map(msgHTML).join(''):`<div class="chat-empty">还没有说过话呢。<br>给${esc(S.him)}发第一句吧 ☁</div>`)+(chatState.thinking?`<div class="msg left"><div class="bubble typing"><i></i><i></i><i></i></div></div>`:'');if(keepScroll!==false){const b=$('#appBody');b.scrollTop=b.scrollHeight}}
function viewChat(){return `<div class="chat-stream" id="chatStream" style="flex:1;min-height:0;display:flex;flex-direction:column;overflow-y:auto;scrollbar-width:none"></div>
  ${chatState.attach?`<div class="attach-panel"><button data-act="attach-photo">${icon('i-gallery')}照片</button><button data-act="attach-sticker">${icon('i-heart')}表情</button><button data-act="attach-world">${icon('i-reading')}世界书</button></div>`:''}
  ${chatState.attach?`<div id="stickerPick"></div>`:''}
  <div class="chat-input"><button class="icon-btn jelly" data-act="attach">${icon('i-plus')}</button><textarea id="chatText" rows="1" placeholder="小cute说句情话_(^._.^)?"></textarea><button class="icon-btn jelly" data-act="mic">${icon('i-mic')}</button><button class="icon-btn send jelly" data-act="send">➤</button></div>`}
function bindChat(){renderStream();const t=$('#chatText');t.addEventListener('input',()=>{t.style.height='auto';t.style.height=Math.min(88,t.scrollHeight)+'px'});t.addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();send()}});t.focus()}
async function send(){
  const t=$('#chatText'),text=t.value.trim();if(!text)return;
  t.value='';t.style.height='auto';
  pushMsg({role:'user',type:'text',content:text,si:Math.floor(Math.random()*STICKERS.length)});
  chatState.attach=false;renderStream();
  const cfg=activeCfg();
  if(!cfg?.url||!cfg?.key){setTimeout(()=>{const parts=parseReply(DEMO[Math.floor(Math.random()*DEMO.length)]+(S.stickers.length&&Math.random()<.5?` [表情:${S.stickers[0].name}]`:''),S.stickers);parts.forEach((p,i)=>pushMsg({role:'ai',type:p.type,content:p.type==='sticker'?p.sticker.url:p.content,name:p.sticker?.name,reasoning:i===0?'她刚才那句话，我应该先接住情绪，再顺手说一件今天的小事。别写太长。':''}));renderStream();snack('还没填 API，现在是我自己陪你聊 ☁','去设置',()=>openApp('settings'))},600);return}
  chatState.thinking=true;renderStream();
  const hist=S.messages.filter(m=>m.type==='text').slice(-20).map(m=>({role:m.role==='user'?'user':'assistant',content:m.content}));
  try{
    const {content,reasoning}=await sendChat(cfg,[{role:'system',content:buildSystem()},...hist]);
    S.quota.calls++;S.quota.chars+=content.length;
    parseReply(content,S.stickers).forEach((p,i)=>pushMsg({role:'ai',type:p.type,content:p.type==='sticker'?p.sticker.url:p.content,name:p.sticker?.name,reasoning:i===0?reasoning:''}));
    save();
  }catch(e){snack(friendlyError(e));pushMsg({role:'ai',type:'text',content:'刚刚没接上话…等一下再试试？'})}
  finally{chatState.thinking=false;renderStream()}
}
function chatInfo(){drawer(`<div class="card tight" style="margin-top:8px"><div class="row">${av('him')}<div style="flex:1;margin-left:10px"><div style="font-weight:600;font-size:14px">${esc(S.him)}</div><div class="mono" style="margin-top:3px">memory.sync always on</div></div><span class="mono">主页 ›</span></div></div>
  <div class="btn-row" style="margin:14px 0">${'<button class="btn ghost sm" data-act="search-chat">搜索</button><button class="btn ghost sm" data-act="export-chat">导出</button>'}</div>
  ${card(`<div class="ls">我们聊过的每一天</div><div class="row" style="margin:10px 0 8px"><span style="font-size:13px;font-weight:600" id="heatTitle"></span><span class="row" style="gap:12px"><button data-act="heat-prev">‹</button><button data-act="heat-next">›</button></span></div><div id="heatBox"></div>`,'tight')}
  <button class="list-item" style="width:100%;margin-top:14px" data-act="favs"><span>他的收藏</span><span class="mono">${S.fav.length} 条 ›</span></button>`);renderHeat()}
let heatMonth=new Date();
function renderHeat(){
  const y=heatMonth.getFullYear(),m=heatMonth.getMonth(),first=new Date(y,m,1).getDay(),n=new Date(y,m+1,0).getDate();
  const counts={};S.messages.forEach(x=>{const k=dkey(new Date(x.ts));counts[k]=(counts[k]||0)+1});
  const lv=c=>!c?0:c<=2?1:c<=5?2:c<=10?3:4;
  let h='';for(let i=0;i<7;i++)h+=`<span class="blank" style="font-size:10px;color:var(--ink-sub)">${WEEK[i]}</span>`;for(let i=0;i<first;i++)h+='<span class="blank"></span>';
  for(let i=1;i<=n;i++){const k=`${y}-${pad(m+1)}-${pad(i)}`,l=lv(counts[k]);h+=`<span class="${l?'l'+l:''}" data-act="heat-day" data-val="${k}">${i}</span>`}
  $('#heatTitle')&&($('#heatTitle').textContent=`${y} · ${m+1} 月`);
  const box=$('#heatBox');if(box)box.innerHTML=`<div class="heat-grid">${h}</div><div class="heat-legend">少 <i></i><i></i><i></i><i></i><i></i> 多</div>`;
}

/* ══════════ 视图表 ══════════ */
const VIEWS={};
VIEWS.chat=viewChat;
VIEWS.moments=()=>`<div class="field"><textarea id="momentText" placeholder="今天想记下什么？" style="min-height:64px"></textarea></div><div class="btn-row" style="margin-bottom:14px"><button class="btn sm" data-act="moment-add">发布</button><button class="btn ghost sm" data-act="moment-pic">加张图</button></div>${S.moments.length?S.moments.slice().reverse().map(x=>`<div class="moment">${esc(x.text)}${x.img?`<img src="${x.img}">`:''}<div class="m-time">${new Date(x.ts).toLocaleString('zh-CN')} · <span data-act="moment-like" data-id="${x.id}" style="cursor:pointer">♡ ${x.likes||0}</span></div></div>`).join(''):'<div class="empty-tip">还没有动态，写第一条吧。</div>'}`;
VIEWS.group=()=>`<div class="card tight" style="margin-bottom:12px"><div class="ls">小圈 · 三个人</div><div class="row" style="margin-top:8px">${av28('me')}${av28('him')}<span class="avatar av-28" style="background:#e7e1d5"></span><span class="mono" style="margin-left:auto">会客中</span></div></div><div id="groupStream" style="min-height:180px">${S.groupMsgs.map(g=>`<div class="msg left"><div class="bubble"><b style="font-size:11px;opacity:.6">${esc(g.who)}</b><br>${esc(g.text)}</div></div>`).join('')}</div><div class="chat-input" style="border-radius:16px;margin-top:10px"><textarea id="groupText" rows="1" placeholder="说点什么…"></textarea><button class="icon-btn send jelly" data-act="group-send">➤</button></div>`;
VIEWS.settings=()=>{
  const c=activeCfg()||{};
  return `<div class="accordion-item open"><div class="acc-head" data-act="acc">🔌 API 对接 <span class="chev">⌄</span></div><div class="acc-body"><div class="acc-inner">
    <div class="field"><label>当前配置</label><select data-bind="activeApi" id="apiSel"><option value="">${S.apis.length?'（选择配置）':'还没有配置'}</option>${S.apis.map(a=>`<option value="${a.id}" ${a.id===S.activeApi?'selected':''}>${esc(a.name)} · ${esc(a.model||'未选模型')}</option>`).join('')}</select></div>
    <div class="btn-row" style="margin-bottom:12px"><button class="btn sm" data-act="api-new">新增配置</button><button class="btn ghost sm" data-act="api-models">拉取模型</button><button class="btn ghost sm" data-act="api-test">测试连接</button></div>
    <div class="hint mono">${c.url?`地址 ${esc(normalizeUrl(c.url))}`:'填任意中转站地址，带不带 /v1 都行。浏览器直连受 CORS 限制，建议用允许跨域的中转站。'}</div>
  </div></div></div>
  <div class="accordion-item"><div class="acc-head" data-act="acc">📚 世界书 <span class="chev">⌄</span></div><div class="acc-body"><div class="acc-inner">
    ${S.worldBooks.map(w=>`<div class="list-item"><div style="flex:1"><div>${esc(w.name)} <span class="tag">${w.scope==='global'?'全局':'局部'}</span></div><div class="sub">${esc(w.content.slice(0,46))}…</div></div><button class="mini-x" data-act="wb-scope" data-id="${w.id}" title="切换范围">⇄</button><button class="mini-x" data-act="wb-del" data-id="${w.id}">×</button></div>`).join('')}
    <button class="btn ghost sm" style="margin-top:10px" data-act="wb-new">＋ 新建世界书</button>
    <div class="section-label" style="margin-top:16px">绑定到当前角色（局部世界书）</div>
    ${S.worldBooks.filter(w=>w.scope!=='global').map(w=>`<label class="list-item" style="cursor:pointer"><span>${esc(w.name)}</span><input type="checkbox" data-act="wb-bind" data-id="${w.id}" ${S.bound.includes(w.id)?'checked':''}></label>`).join('')||'<div class="mono">没有局部世界书</div>'}
  </div></div></div>
  <div class="accordion-item"><div class="acc-head" data-act="acc">🖼️ 表情库 <span class="chev">⌄</span></div><div class="acc-body"><div class="acc-inner">
    <button class="btn ghost sm" data-act="sticker-add">＋ 上传表情</button>
    <div class="sticker-lib">${S.stickers.map(s=>`<figure><img src="${s.url}" title="${esc(s.name)}"><button class="del" data-act="sticker-del" data-id="${s.id}">×</button><figcaption>${esc(s.name)}</figcaption></figure>`).join('')||''}</div>
    <div class="hint mono" style="margin-top:10px">名字就是 AI 用的标记：[表情:${S.stickers[0]?.name||'名字'}]</div>
  </div></div></div>
  <div class="accordion-item"><div class="acc-head" data-act="acc">🤍 两个人 <span class="chev">⌄</span></div><div class="acc-body"><div class="acc-inner">
    <div class="field"><label>我的名字</label><input data-bind="me" value="${esc(S.me)}"></div>
    <div class="field"><label>恋人名字</label><input data-bind="him" value="${esc(S.him)}"></div>
    <div class="field"><label>在一起的日子</label><input type="date" data-bind="since" value="${esc(S.since)}"></div>
    <div class="field"><label>领证日</label><input type="date" data-bind="license" value="${esc(S.license)}"></div>
    <div class="field"><label>人设 / System Prompt</label><textarea data-bind="persona">${esc(S.persona)}</textarea></div>
  </div></div></div>
  <div class="accordion-item"><div class="acc-head" data-act="acc">🌫️ 外观 <span class="chev">⌄</span></div><div class="acc-body"><div class="acc-inner">
    <div class="list-item"><span>深色模式</span><div class="toggle ${S.dark?'on':''}" data-act="toggle-dark"><div class="knob"></div></div></div>
    <div class="btn-row" style="margin-top:12px"><button class="btn ghost sm" data-act="wall-pick">换壁纸${S.dark?'(深)':'(浅)'}</button><button class="btn ghost sm" data-act="av-pick" data-val="me">换我头像</button><button class="btn ghost sm" data-act="av-pick" data-val="him">换他头像</button></div>
    <div class="btn-row" style="margin-top:14px"><button class="btn ghost sm" data-act="export-data">导出全部数据</button><button class="btn ghost sm" data-act="import-data">导入数据</button><button class="btn ghost sm" data-act="reset-data">清空重来</button></div>
    <div class="hint mono" style="margin-top:10px">数据只存在这台设备的浏览器里，不会上传。</div>
  </div></div></div>`};
VIEWS.diary=()=>`${card(`<div class="row"><span class="ls">我们聊过的每一天</span><span class="row" style="gap:12px"><button data-act="heat-prev">‹</button><button data-act="heat-next">›</button></span></div><div style="text-align:center;font-size:13px;font-weight:600;margin:8px 0 12px" id="heatTitle"></div><div id="heatBox"></div>`,'tight')}<div class="mono" style="text-align:center;margin-top:14px">点有颜色的日子，回看那天说过的话</div>`;
VIEWS.timemachine=()=>{const by={};S.messages.forEach(m=>{const k=dkey(new Date(m.ts));(by[k]=by[k]||[]).push(m)});const ks=Object.keys(by).sort().reverse();return `<div class="ls" style="margin-bottom:10px">Timeline</div>${ks.length?ks.map(k=>`<div class="accordion-item"><div class="acc-head" data-act="acc">${k} <span class="mono">${by[k].length} 条 ›</span></div><div class="acc-body"><div class="acc-inner">${by[k].map(m=>`<div style="margin-bottom:8px"><b style="color:var(--ink)">${m.role==='user'?'我':'他'}：</b>${esc(m.type==='text'?m.content:'[图片]')}</div>`).join('')}</div></div></div>`).join(''):'<div class="empty-tip">还没有可以回看的日子。</div>'}`};
VIEWS.music=()=>{const songs=[['NO HOOK FREESTYLE Pt.4','Russ · Roam'],['Chaque jour','Les petits riens'],['雨天的公车','屿上电台']],s=songs[S.music.i%3];return `${card(`<div style="text-align:center;padding:10px 0 4px"><div class="album-art" style="width:180px;height:180px;margin:0 auto;border-radius:20px;font-size:11px;letter-spacing:.2em">ROAM</div><div class="ls" style="margin-top:18px">NOW PLAYING</div><div style="font-family:var(--font-serif);font-size:19px;margin-top:6px">${s[0]}</div><div class="mono" style="margin-top:4px">${s[1]}</div><div class="progress" style="margin-top:18px;height:4px"><i style="width:${S.music.playing?'38':'12'}%"></i></div><div class="ctrls" style="margin-top:14px"><button data-act="music-like">${icon('i-heart')}</button><button data-act="music-play">${icon(S.music.playing?'i-music':'i-play')}</button><button data-act="music-next">${icon('i-next')}</button></div></div>`)}${card(`<div class="ls">歌单</div>${songs.map((x,i)=>`<div class="list-item" data-act="music-pick" data-val="${i}" style="cursor:pointer"><span>${x[0]}</span><span class="mono">${i===S.music.i%3?'♪':''}</span></div>`).join('')}`,'tight')}`};
VIEWS.weather=()=>`${card(`<div class="row"><div><div class="ls">屿上天气</div><div style="font-family:var(--font-serif);font-size:52px;font-weight:300;line-height:1.2;margin-top:8px">19°</div><div class="mono">小雨转阴 · 体感 17°</div></div>${icon('i-cloud','fill-icon')}</div><div class="hair"></div><div class="row mono"><span>湿度 82%</span><span>东风 2 级</span><span>空气 优</span></div>`,'tight')}${card(`<div class="quote">带伞吧，<br>或者就一起淋一小会儿。</div><div class="mono" style="margin-top:12px">memory.sync always on</div>`,'tight')}${card(`<div class="ls">未来</div>${['今天','明天','后天'].map((d,i)=>`<div class="kv"><span>${d}</span><span>${[19,21,18][i]}° · ${['小雨','多云','晴'][i]}</span></div>`).join('')}`,'tight')}`;
VIEWS.portrait=()=>`${card(`<div style="text-align:center;padding:8px 0">${av('him')}<div style="font-size:16px;font-weight:600;margin-top:10px">${esc(S.him)}</div><div class="mono" style="margin-top:4px">SINCE ${esc(S.since.replace(/-/g,'.'))}</div></div><div class="tags" style="justify-content:center;margin-top:10px"><span class="tag">温柔</span><span class="tag">话少</span><span class="tag">记性好</span><span class="tag">会等</span></div>`,'tight')}${card(`<div class="field"><label>人设 / 形象设定</label><textarea data-bind="persona" style="min-height:150px">${esc(S.persona)}</textarea><div class="hint">这段会作为 system prompt 每次随对话发送。</div></div><button class="btn sm" data-act="saved">保存好了</button>`,'tight')}`;
VIEWS.terminal=()=>`${card(`<div class="mono" style="margin-bottom:8px">little-phone / tty1 · help 查看命令</div><div class="terminal-out" id="termOut">$ 已连接 <b>陆宅</b>\n$ 输入 help 试试看</div><div class="field" style="margin-top:12px"><input id="termIn" placeholder="help" autocomplete="off"></div><button class="btn sm" data-act="term-run">执行</button>`,'tight')}`;
VIEWS.quota=()=>{const used=new Blob([JSON.stringify(S)]).size;return `${card(`<div class="ls">这个月</div><div class="stat-big">${S.quota.calls}</div><div class="mono" style="margin-top:4px">次对话请求</div>`)}${card(`<div class="kv"><span>累计回复字数</span><span>${S.quota.chars} 字</span></div><div class="kv"><span>聊天消息</span><span>${S.messages.length} 条</span></div><div class="kv"><span>表情库</span><span>${S.stickers.length} 枚</span></div><div class="kv"><span>世界书</span><span>${S.worldBooks.length} 条 · ${activeBooks().length} 条生效</span></div><div class="kv"><span>本地占用</span><span>${(used/1024).toFixed(1)} KB</span></div><div class="kv"><span>本地配额</span><span>约 5 MB</span></div>`,'tight')}${card(`<div class="quote">额度是拿来记着<br>我们说过多少话的，<br>不是拿来省着用的。</div>`,'tight')}`};
VIEWS.home=()=>`${card(`<div class="row"><div><div class="ls">Our Space</div><div style="font-family:var(--font-serif);font-size:26px;margin-top:6px">陆宅</div></div><span class="tag">会客中</span></div><div class="mono" style="margin-top:10px">门口的小灯一直亮着</div>`,'tight')}${card(`<div class="ls">访客留言</div><div style="margin-top:8px">${S.guests.slice().reverse().map(g=>`<div class="visitor" style="padding:8px 0;border-bottom:1px solid var(--line)">${esc(g.text)}</div>`).join('')}</div><div class="field" style="margin-top:12px"><input id="guestText" placeholder="留一句话再走…"></div><button class="btn sm" data-act="guest-add">写下</button>`,'tight')}`;
VIEWS.tide=()=>`${card(`<div class="ls">Tide · 屿上</div><svg class="tide-art" style="height:80px;margin-top:10px" viewBox="0 0 260 56"><use href="#tideline"/></svg><div class="row"><span style="font-family:var(--font-serif);font-size:22px">今天中潮</span><span class="mono">潮龄 5.6</span></div>`,'tight')}${card(`<div class="kv"><span>第一次涨潮</span><span>05:42</span></div><div class="kv"><span>第一次退潮</span><span>11:58</span></div><div class="kv"><span>第二次涨潮</span><span>18:10</span></div><div class="kv"><span>水温</span><span>21.3°C</span></div>`,'tight')}${card(`<div class="quote">潮水每天回来两次，<br>我也是。</div>`,'tight')}`;
VIEWS.bottle=()=>`${card(`<div style="text-align:center"><svg viewBox="0 0 120 130" style="width:110px;height:120px;margin:0 auto;color:#8a9a7c"><use href="#bottleart"/></svg><div class="tags" style="justify-content:center"><span class="tag">绿茸</span><span class="tag">苍穹</span></div><div class="prose" style="margin-top:10px">翠鸟扎进水里。又空空地窜回来。<br>池塘里没有它要找的银亮影子。</div></div>`,'tight')}${card(`<div class="ls">瓶里存着的记忆</div><div style="margin-top:8px">${S.bottle.length?S.bottle.slice().reverse().map(b=>`<div class="list-item"><span>${esc(b.text)}</span><button class="mini-x" data-act="list-del" data-val="bottle" data-id="${b.id}">×</button></div>`).join(''):'<div class="empty-tip">往瓶子里放一句话吧。</div>'}</div><div class="field" style="margin-top:10px"><input id="listInput" placeholder="一片叶子、一句话…"></div><button class="btn sm" data-act="list-add" data-val="bottle">放进去</button>`,'tight')}`;
VIEWS.todo=()=>listView('todos','想和哥哥一起做的事…');
VIEWS.reading=()=>listView('reading','记一句今天读到的…');
VIEWS.ledger=()=>`${card(`<div class="ls">小账本</div><div class="stat-big" style="font-size:38px;margin-top:8px">¥ ${S.ledger.reduce((s,x)=>s+(+x.amount||0),0).toFixed(0)}</div><div class="mono" style="margin-top:4px">一起花掉的，都算好的</div>`,'tight')}${card(`<div class="field"><label>备注</label><input id="ledgerNote" placeholder="两杯热拿铁"></div><div class="field"><label>金额</label><input id="ledgerAmt" type="number" placeholder="38"></div><button class="btn sm" data-act="ledger-add">记一笔</button><div style="margin-top:10px">${S.ledger.slice().reverse().map(x=>`<div class="list-item"><span>${esc(x.note)}</span><span class="row" style="gap:10px"><span class="mono">¥${esc(x.amount)}</span><button class="mini-x" data-act="list-del" data-val="ledger" data-id="${x.id}">×</button></span></div>`).join('')}</div>`,'tight')}`;
VIEWS.gallery=()=>{const imgs=S.messages.filter(m=>m.type==='image'||m.type==='sticker').map(m=>m.content);return imgs.length?`<div class="ls" style="margin-bottom:10px">${imgs.length} 张</div><div class="gallery-grid">${imgs.slice().reverse().map(u=>`<img src="${u}">`).join('')}</div>`:'<div class="empty-tip">还没有图片。<br>聊天时点 + 可以发照片和表情。</div>'};
VIEWS.game=()=>`${card(`<div style="text-align:center;padding:14px 0"><div class="ls">Today's Fortune</div><div style="font-family:var(--font-serif);font-size:60px;color:var(--theme);margin:14px 0">☁</div><div class="quote" id="fortuneText">点一下，抽今天的一支签。</div><button class="btn jelly-blob" style="margin-top:20px" data-act="draw-fortune">抽一支签</button><div class="mono" style="margin-top:14px">已经抽了 ${S.gameCount} 次</div></div>`,'tight')}`;
function listView(key,ph){const done=key==='todos';return `${card(`<div class="ls">${done?'Together · 待办':'共读摘抄'}</div><div style="margin-top:8px">${S[key].length?S[key].map(x=>`<div class="todo-row ${x.done?'done':''}" ${done?`data-act="todo-toggle" data-id="${x.id}"`:''}><span class="todo-box">${x.done?'✓':''}</span><span style="flex:1">${esc(x.text)}</span><button class="mini-x" data-act="list-del" data-val="${key}" data-id="${x.id}">×</button></div>`).join(''):'<div class="empty-tip">空空的，写一条吧。</div>'}</div><div class="field" style="margin-top:12px"><input id="listInput" placeholder="${ph}"></div><button class="btn sm" data-act="list-add" data-val="${key}">加上</button>`,'tight')}`}

function renderView(id){const body=$('#appBody');body.className='app-body'+(id==='chat'||id==='group'?' chat-body':'');body.innerHTML=(VIEWS[id]||(()=>'<div class="empty-tip">这个应用还在慢慢长出来 ☁</div>'))();if(id==='chat')bindChat();if(id==='diary')renderHeat();if(id==='group')setTimeout(()=>body.scrollTop=body.scrollHeight,0)}

/* ══════════ 事件委托（Part 8：查表 > 分支） ══════════ */
const ACT={
 'open':t=>{closePop(t);const p=$('#appPop');if(p)p.remove();openApp(t.dataset.app,t.closest('.app-cell,.dock-item')||t)},
 'closeApp':closeApp,'modal-close':closeModal,'modal-ok':()=>{const f=window.__onModalOk;closeModal();f&&f($('#modal'))},
 'drawer-close':closeDrawer,
 'acc':t=>{const i=t.parentElement,open=i.classList.contains('open');$$('.accordion-item').forEach(x=>x.classList.remove('open'));if(!open)i.classList.add('open')},
 'think':t=>{const box=$(`[data-think="${t.dataset.id}"]`);if(!box)return;const on=box.style.display==='none';box.style.display=on?'block':'none';t.classList.toggle('open',on);t.querySelector('.ls').textContent=on?'收起':'展开'},
 'attach':()=>{chatState.attach=!chatState.attach;renderView('chat')},
 'send':send,'mic':()=>snack('麦克风交给系统啦，用键盘也很快 ☁'),
 'attach-photo':()=>pickFile(async f=>{const u=await shrink(f);pushMsg({role:'user',type:'image',content:u});chatState.attach=false;renderView('chat')}),
 'attach-sticker':()=>{const box=$('#stickerPick');if(!box)return;box.innerHTML=S.stickers.length?`<div class="attach-panel" style="flex-wrap:wrap">${S.stickers.map(s=>`<button style="flex:0 0 52px" data-act="pick-sticker" data-id="${s.id}"><img src="${s.url}" style="width:40px;height:40px;object-fit:cover;border-radius:10px"></button>`).join('')}</div>`:'<div class="empty-tip" style="font-size:11px">设置里还没上传表情呢</div>'},
 'pick-sticker':t=>{const s=S.stickers.find(x=>x.id===t.dataset.id);if(!s)return;pushMsg({role:'user',type:'sticker',content:s.url,name:s.name});chatState.attach=false;renderView('chat')},
 'attach-world':()=>modal('生效中的世界书',activeBooks().map(w=>`<div class="list-item"><div><b>${esc(w.name)}</b><div class="sub">${esc(w.content.slice(0,80))}</div></div><span class="tag">${w.scope==='global'?'全局':'局部'}</span></div>`).join('')||'<div class="empty-tip">还没有世界书</div>'),
 'more-msg':()=>{showCount+=30;renderStream()},
 'search-chat':()=>modal('搜索聊天记录','<div class="field"><input id="searchQ" placeholder="关键词"></div><div id="searchOut"></div>',null),
 'export-chat':()=>{exportText('聊天记录',S.messages.map(m=>`[${new Date(m.ts).toLocaleString('zh-CN')}] ${m.role==='user'?S.me:S.him}：${m.type==='text'?m.content:'[图片]'}`).join('\n'))},
 'export-data':()=>exportText('小手机备份',JSON.stringify(S,null,2),'json'),
 'import-data':()=>pickFile(async f=>{try{const d=JSON.parse(await f.text());S={...DEF,...d};save();applyMedia();renderHome();renderView(curApp);snack('导入好了 ☁')}catch{snack('这个文件读不出来，要 UTF-8 的 JSON')}},'application/json'),
 'reset-data':()=>modal('清空重来？','<p>聊天记录、表情、设置都会被删掉，且无法恢复。建议先导出一份备份。</p>','确认清空',()=>{localStorage.removeItem(KEY);S={...DEF};save();applyMedia();renderHome();renderView('settings');snack('重来一次，也挺好 ☁')}),
 'saved':()=>snack('记下了 ☁'),
 'toggle-dark':()=>{S.dark=!S.dark;save();applyMedia();const p=$('#appPop');if(p)p.remove();if(curApp)renderView(curApp);snack(S.dark?'晚安 ☾':'早上好 ☀')},
 'favs':()=>modal('他的收藏',S.fav.length?S.fav.map(f=>`<div class="list-item">${esc(f)}</div>`).join(''):'<div class="empty-tip">还没有收藏，长按气泡可以收进来。</div>'),
 'heat-prev':()=>{heatMonth=new Date(heatMonth.getFullYear(),heatMonth.getMonth()-1,1);renderHeat()},
 'heat-next':()=>{heatMonth=new Date(heatMonth.getFullYear(),heatMonth.getMonth()+1,1);renderHeat()},
 'heat-day':t=>{const k=t.dataset.val,list=S.messages.filter(m=>dkey(new Date(m.ts))===k);modal(k,list.length?list.map(m=>`<div class="list-item"><div><b>${m.role==='user'?S.me:S.him}</b>：${esc(m.type==='text'?m.content:'[图片]')}</div></div>`).join(''):'<div class="empty-tip">那天什么也没说，但也是在一天里。</div>')},
 'moment-add':()=>{const v=$('#momentText').value.trim();if(!v)return;S.moments.push({id:uid('mo'),text:v,ts:Date.now(),likes:0});save();renderView('moments');snack('发出去了 ☁')},
 'moment-pic':()=>pickFile(async f=>{const u=await shrink(f);S.moments.push({id:uid('mo'),text:'',img:u,ts:Date.now(),likes:0});save();renderView('moments')}),
 'moment-like':t=>{const m=S.moments.find(x=>x.id===t.dataset.id);if(m){m.likes=(m.likes||0)+1;save();renderView('moments')}},
 'group-send':()=>{const v=$('#groupText').value.trim();if(!v)return;S.groupMsgs.push({id:uid('g'),who:S.me,text:v,ts:Date.now()});save();renderView('group')},
 'api-new':()=>{const c=activeCfg()||{};modal('新增 / 编辑 API 配置',`<div class="field"><label>名字</label><input id="fName" value="${esc(c.name||'我的中转站')}"></div><div class="field"><label>接口地址（带不带 /v1 都行）</label><input id="fUrl" placeholder="https://api.xxx.com" value="${esc(c.url||'')}"></div><div class="field"><label>密钥</label><input id="fKey" placeholder="sk-..." value="${esc(c.key||'')}"></div><div class="field"><label>模型</label><input id="fModel" placeholder="gpt-4o-mini" value="${esc(c.model||'')}"></div><div class="field"><label>温度</label><input id="fTemp" type="number" step="0.1" value="${c.temperature??.8}"></div><div class="hint mono">密钥只存本机，不会发给任何第三方。</div>`,'保存',()=>{
   const g=id=>document.getElementById(id)?.value??'';const o={id:c.id||uid('a_'),name:g('fName').trim()||'我的中转站',url:g('fUrl').trim(),key:g('fKey').trim(),model:g('fModel').trim(),temperature:+g('fTemp')||.8};
   const i=S.apis.findIndex(a=>a.id===o.id);i<0?S.apis.push(o):S.apis[i]=o;S.activeApi=o.id;save();renderView('settings');snack('配置存好了 ☁')})},
 'api-models':async()=>{const c=activeCfg();if(!c?.url||!c?.key)return snack('先填好地址和密钥');snack('正在拉取模型…');try{const ms=await fetchModelList(c.url,c.key);modal('可用模型',`<div class="field"><label>选一个模型</label><select id="modelSel">${ms.map(m=>`<option ${m===c.model?'selected':''}>${esc(m)}</option>`).join('')}</select></div>`,'用它',()=>{const v=$('#modelSel')?.value;if(v){c.model=v;save();renderView('settings');snack('模型换好了')}})}catch(e){snack(friendlyError(e))}},
 'api-test':async()=>{const c=activeCfg();if(!c?.url||!c?.key)return snack('先填好地址和密钥');snack('正在试一下…');try{const r=await sendChat(c,[{role:'user',content:'只回复一个字：好'}]);snack('接上了：'+r.content.slice(0,20))}catch(e){snack(friendlyError(e))}},
 'wb-new':()=>modal('新建世界书','<div class="field"><label>名字</label><input id="wbName" placeholder="我们的小日常"></div><div class="field"><label>正文</label><textarea id="wbBody" placeholder="AI 会原样读到这段…"></textarea></div><div class="field"><label>范围</label><select id="wbScope"><option value="global">全局 · 一直生效</option><option value="local">局部 · 手动绑定</option></select></div>','保存',()=>{const n=$('#wbName').value.trim(),c=$('#wbBody').value.trim(),s=$('#wbScope').value;if(!n||!c)return;S.worldBooks.push({id:uid('wb_'),name:n,content:c,scope:s});save();renderView('settings');snack('世界书加好了 ☁')}),
 'wb-scope':t=>{const w=S.worldBooks.find(x=>x.id===t.dataset.id);if(w){w.scope=w.scope==='global'?'local':'global';save();renderView('settings')}},
 'wb-del':t=>{S.worldBooks=S.worldBooks.filter(x=>x.id!==t.dataset.id);S.bound=S.bound.filter(x=>x!==t.dataset.id);save();renderView('settings')},
 'sticker-add':()=>pickFile(async f=>{const u=await shrink(f,240,.7);const name=f.name.replace(/\.[^.]+$/,'').slice(0,12)||'新表情';S.stickers.push({id:uid('st_'),name,url:u});if(save()){snack(`存好了：[表情:${name}]`,'改名',()=>renameSticker(S.stickers.at(-1).id))}renderView('settings')}),
 'sticker-del':t=>{S.stickers=S.stickers.filter(x=>x.id!==t.dataset.id);save();renderView('settings')},
 'wall-pick':()=>pickFile(async f=>{const u=await shrink(f,1100,.78);S.dark?S.wallDark=u:S.wallLight=u;if(save()){applyMedia();snack('壁纸换好了 ☁')}renderView('settings')}),
 'av-pick':t=>pickFile(async f=>{const u=await shrink(f,220,.8);S[t.dataset.val==='me'?'avMe':'avHim']=u;if(save()){applyMedia();renderHome();snack('头像换好了 ☁')}renderView('settings')}),
 'music-play':()=>{S.music.playing=!S.music.playing;save();renderView('music')},
 'music-next':()=>{S.music.i=(S.music.i+1)%3;save();renderView('music')},
 'music-pick':t=>{S.music.i=+t.dataset.val;save();renderView('music')},
 'music-like':()=>{snack('收进歌单了 ♡')},
 'term-run':()=>{const v=$('#termIn').value.trim(),out=$('#termOut');if(!v)return;const cmds={help:'可用命令：help / status / days / msgs / api / wall / dark / clear',status:()=>`系统正常 · ${S.messages.length} 条消息 · ${activeBooks().length} 条世界书生效`,days:()=>`在一起 ${days()} 天了，从 ${S.since} 开始`,msgs:()=>`${S.messages.length} 条消息，${S.stickers.length} 枚表情`,api:()=>activeCfg()?.url?`已接：${activeCfg().name} · ${activeCfg().model}`:'还没填 API，现在是离线陪伴模式',wall:()=>'壁纸在设置里换，用你自己的照片最好看',dark:()=>{S.dark=!S.dark;save();applyMedia();return'外观切好了'},clear:()=>''};const r=typeof cmds[v]==='function'?cmds[v]():cmds[v]??`不认识这个命令：${v}`;out.textContent=r===''?'$ 已连接 陆宅':`$ ${v}\n${r}`;$('#termIn').value=''},
 'guest-add':()=>{const v=$('#guestText').value.trim();if(!v)return;S.guests.push({id:uid('g'),text:`${S.me} 留了话：${v}`});save();renderView('home')},
 'list-add':t=>{const k=t.dataset.val,v=$('#listInput').value.trim();if(!v)return;S[k].push({id:uid('l'),text:v,done:false});save();renderView(curApp)},
 'list-del':t=>{const k=t.dataset.val;S[k]=S[k].filter(x=>x.id!==t.dataset.id);save();renderView(curApp)},
 'todo-toggle':t=>{const x=S.todos.find(i=>i.id===t.dataset.id);if(x){x.done=!x.done;save();renderView('todo')}},
 'ledger-add':()=>{const n=$('#ledgerNote').value.trim(),a=$('#ledgerAmt').value;if(!n||!a)return;S.ledger.push({id:uid('l'),note:n,amount:a});save();renderView('ledger')},
 'draw-fortune':()=>{const L=['宜慢慢走，宜说想你。','宜一起淋一点小雨。','宜早点睡，梦里有我。','宜翻旧照片，宜笑出声。','宜把今天留白。','宜喝热的，宜靠着我。'];$('#fortuneText').textContent=L[Math.floor(Math.random()*L.length)];S.gameCount++;save();$$('[data-game-count]').forEach(n=>n.textContent=S.gameCount);const c=$('#fortuneText').parentElement.querySelector('.mono');if(c)c.textContent=`已经抽了 ${S.gameCount} 次`},
 'snack-action':()=>{snackCb&&snackCb();$('#snackbar').classList.remove('show')}
};
document.addEventListener('click',e=>{const t=e.target.closest('[data-act]');closePop(e.target);if(!t)return;const f=ACT[t.dataset.act];if(f){e.stopPropagation();f(t,e)}});
document.addEventListener('input',e=>{const b=e.target.dataset.bind;if(!b)return;S[b]=e.target.value;save();if(b==='him'||b==='since'||b==='license')applyMeta();if(b==='him')renderHome();if(e.target.id==='searchQ'){const q=e.target.value.trim(),o=$('#searchOut');if(o)o.innerHTML=q?S.messages.filter(m=>m.type==='text'&&m.content.includes(q)).slice(-12).map(m=>`<div class="list-item"><span>${esc(m.content.slice(0,60))}</span></div>`).join('')||'<div class="empty-tip">没找到</div>':''}});
document.addEventListener('change',e=>{const t=e.target;if(t.dataset.act==='wb-bind'){S.bound=t.checked?[...new Set([...S.bound,t.dataset.id])]:S.bound.filter(x=>x!==t.dataset.id);save()}if(t.dataset.bind==='activeApi'){S.activeApi=t.value;save()}});
$('#drawerMask').addEventListener('click',e=>{if(e.target.id==='drawerMask')closeDrawer()});
$('#modalMask').addEventListener('click',e=>{if(e.target.id==='modalMask')closeModal()});
$('#snackAction').addEventListener('click',()=>ACT['snack-action']());
let pressTimer;
document.addEventListener('pointerdown',e=>{const b=e.target.closest('.bubble[data-msg]');if(!b)return;pressTimer=setTimeout(()=>{const m=S.messages.find(x=>x.id===b.dataset.msg);if(!m||m.type!=='text')return;S.fav=[m.content,...S.fav.filter(f=>f!==m.content)].slice(0,50);save();snack('收进「他的收藏」了 ♡')},550)});
['pointerup','pointercancel','pointermove'].forEach(t=>document.addEventListener(t,()=>clearTimeout(pressTimer)));
function renameSticker(id){modal('给表情改个名字','<div class="field"><label>名字（AI 会按这个名字调用）</label><input id="stName"></div>','保存',()=>{const n=$('#stName').value.trim(),st=S.stickers.find(x=>x.id===id);if(n&&st){st.name=n;save();renderView('settings');snack('改好了 ☁')}})}
function exportText(name,text,ext='txt'){const b=new Blob([text],{type:ext==='json'?'application/json':'text/plain;charset=utf-8'}),a=document.createElement('a');a.href=URL.createObjectURL(b);a.download=`${name}-${dkey(new Date())}.${ext}`;a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);snack('导出好了 ☁')}

/* ══════════ 启动 ══════════ */
if(!S.groupMsgs.length){S.groupMsgs.push({id:'g0',who:S.him,text:'欢迎来小圈坐坐 ☁',ts:Date.now()});save()}
applyMedia();applyMeta();tick();setInterval(tick,1000);renderHome();
