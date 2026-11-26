/* xw-desk.js v3 */
(function(){
'use strict';
var D=document,DAY=864e5,done=false;
function esc(t){var s=String(t==null?'':t);return s.split('&').join('&amp;').split('<').join('&lt;').split('>').join('&gt;');}
function one(s){
  s=String(s==null?'':s);
  var o='',sp=false,i,c,code;
  for(i=0;i<s.length;i++){
    c=s.charAt(i);code=s.charCodeAt(i);
    if(c===' '||code===9||code===10||code===13){if(!sp){o+=' ';sp=true;}}
    else{o+=c;sp=false;}
  }
  return o.replace(/^ +/,'').replace(/ +$/,'');
}
function n(v){return Array.isArray(v)?v.length:0;}
function gs(k){try{return localStorage.getItem(k)||'';}catch(e){return '';}}
function ss(k,v){try{localStorage.setItem(k,v);}catch(e){}}
function startDate(){var r=gs('xw_loveDate');if(!r){var d=(XW.S&&XW.S.loveDate)||'';if(d&&d!=='2025-01-01')r=d;}return r;}
function days(){var r=startDate();if(!r)return -1;var d=new Date(r);if(isNaN(d.getTime()))return -1;return Math.max(0,Math.floor((Date.now()-d.getTime())/DAY));}
function pad2(v){return ('0'+v).slice(-2);}
var WD=['ri','yi','er','san','si','wu','liu'];
var WDC=['\u65e5','\u4e00','\u4e8c','\u4e09','\u56db','\u4e94','\u516d'];
var ICON={
home:'<svg viewBox="0 0 24 24"><path d="M4 10.5 12 4l8 6.5V20H4z"/><path d="M9.5 20v-5.5h5V20"/></svg>',
chat:'<svg viewBox="0 0 24 24"><path d="M4 6.5A2 2 0 0 1 6 4.5h12a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2h-7.5L7 19v-3.5H6a2 2 0 0 1-2-2z"/></svg>',
diary:'<svg viewBox="0 0 24 24"><path d="M6 4.5h11a1.5 1.5 0 0 1 1.5 1.5v14H6z"/><path d="M6 4.5A1.5 1.5 0 0 0 4.5 6v13"/><path d="M9.5 9h6"/><path d="M9.5 13h4"/></svg>',
settings:'<svg viewBox="0 0 24 24"><path d="M4.5 8.5h4"/><path d="M13 8.5h6.5"/><path d="M10.5 6.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z"/><path d="M4.5 15.5h4"/><path d="M13 15.5h6.5"/><path d="M16.5 13.6a1.9 1.9 0 1 0 0 3.8 1.9 1.9 0 0 0 0-3.8z"/></svg>',
memory:'<svg viewBox="0 0 24 24"><path d="M7 4h10v16l-5-3.5-5 3.5z"/></svg>',
album:'<svg viewBox="0 0 24 24"><path d="M4.5 5.5h15v13h-15z"/><path d="M15 15l-3.5-3.5L6.5 16.5"/></svg>',
star:'<svg viewBox="0 0 24 24"><path d="M12 4.5l2.2 4.9 5.3.5-4 3.6 1.2 5.2L12 16l-4.7 2.7 1.2-5.2-4-3.6 5.3-.5z"/></svg>'};
var DOCK=[{id:'home',name:'首页'},{id:'chat',name:'聊天'},{id:'diary',name:'日记'},{id:'settings',name:'设置'}];
var FB=[{id:'chat',name:'聊天'},{id:'album',name:'相册'},{id:'memory',name:'记忆库'},{id:'diary',name:'日记'},{id:'music',name:'音乐'},{id:'mcp',name:'MCP'},{id:'beautify',name:'美化'},{id:'settings',name:'设置'}];
function avatar(){return gs('xw_ava_his');}
function photos(){var p=(XW.S&&XW.S.photos)||[];return Array.isArray(p)?p.slice(-3).reverse():[];}
function lastChat(){var c=(XW.S&&XW.S.chat)||[];return (Array.isArray(c)&&c.length)?c.slice(-3).reverse():[];}
function lastDiary(){var d=(XW.S&&XW.S.diary)||[];if(!Array.isArray(d)||!d.length)return null;var a=d.slice();a.sort(function(x,y){return String(y.date||y.time||'').localeCompare(String(x.date||x.time||''));});return a[0]||null;}
function apps(){var L=null;if(window.Apps)L=Apps.LIST||Apps.list||null;if(!Array.isArray(L)||!L.length)L=FB;return L;}
function build(){
var st=XW.S||{},now=new Date();
var clock=pad2(now.getHours())+':'+pad2(now.getMinutes());
var ymd=now.getFullYear()+'\u5e74'+(now.getMonth()+1)+'\u6708'+now.getDate()+'\u65e5';
var wd='\u661f\u671f'+WDC[now.getDay()];
var av=avatar(),avStyle=av?' style="background-image:url('+av+')"':'';
var his=(st.hisName&&st.hisName!=='\u4ed6')?st.hisName:'\u4ed6';
var her=(st.herName&&st.herName!=='\u5979')?st.herName:'\u5979';
var bio=gs('xw_bio'),quote=gs('xw_quote'),dd=days(),sd=startDate();
var ps=photos(),th='';
if(ps.length){ps.forEach(function(u){th+='<i style="background-image:url('+u+')"></i>';});}else{th='<i></i><i></i><i></i>';}
var chat=lastChat(),cli='';
if(chat.length){chat.forEach(function(m){var t=one(m.text||m.content||'').slice(0,16);cli+='<div class="xd-li"><i></i><span>'+esc(t)+'</span><em>'+esc(String(m.time||m.date||'').slice(-5))+'</em></div>';});}
else{cli='<div class="xd-li"><i></i><span>\u8fd8\u6ca1\u6709\u6d88\u606f</span><em></em></div>';}
var h=[];
h.push('<div class="xd-top">');
h.push('<button type="button" class="xd-burger" id="xd-open-rail"><i></i><i></i><i></i></button>');
h.push('<div class="xd-head"><div class="xd-clock">'+clock+'</div></div>');
h.push('<div class="xd-date">'+ymd+'<br>'+wd+'</div>');
h.push('</div>');
h.push('<section class="xd-card xd-id">');
h.push('<div class="xd-ava"'+avStyle+'></div>');
h.push('<div class="xd-idmain">');
h.push('<div class="xd-name">'+esc(his)+' &amp; '+esc(her)+'<i>\u2713</i></div>');
h.push('<div class="xd-handle">@xiaowo</div>');
if(bio){h.push('<p class="xd-bio" data-set="bio">'+esc(bio)+'</p>');}
else{h.push('<button type="button" class="xd-add" data-set="bio"><b>+</b>\u5199\u4e00\u53e5\u4ecb\u7ecd</button>');}
if(dd>=0){h.push('<div class="xd-see" data-set="start">\u7b2c '+dd+' \u5929 \u00b7 \u4ece '+esc(sd)+' \u5f00\u59cb</div>');}
else{h.push('<button type="button" class="xd-add" data-set="start"><b>+</b>\u8bbe\u4e00\u4e2a\u8d77\u7b97\u65e5</button>');}
h.push('</div>');
h.push('</section>');
h.push('<div class="xd-stats">');
h.push('<div><b>'+(dd>=0?dd:'\u2014')+'</b><span>\u5929</span></div>');
h.push('<div><b>'+n(st.notes)+'</b><span>\u8bb0\u5fc6</span></div>');
h.push('<div><b>'+n(st.diary)+'</b><span>\u65e5\u8bb0</span></div>');
h.push('<div><b>'+n(st.photos)+'</b><span>\u7167\u7247</span></div>');
h.push('</div>');
h.push('<div class="xd-2">');
h.push('<div class="xd-card"><div class="xd-k">WEATHER</div>');
h.push('<b class="xd-big" id="xd-wx">--</b>');
h.push('<div class="xd-sub" id="xd-wxs">\u53d6\u5929\u6c14\u2026</div></div>');
h.push('<div class="xd-card"><div class="xd-k">MESSAGES</div>');
h.push(cli);
h.push('</div>');
h.push('</div>');
h.push('<section class="xd-card xd-hero">');
if(quote){h.push('<p class="xd-quote" data-set="quote">'+esc(quote)+'</p>');}
else{h.push('<p class="xd-qs" style="margin-top:0">\u8fd9\u53e5\u8bdd\u8fd8\u6ca1\u5199\u3002</p>');h.push('<button type="button" class="xd-add" data-set="quote"><b>+</b>\u5199\u4e00\u53e5\u8bdd</button>');}
h.push('<div class="xd-thumbs">'+th+'</div>');
h.push('</section>');
var dj=lastDiary();
if(dj){h.push('<section class="xd-card xd-recent" data-go="diary">');h.push('<div class="xd-rdate">'+esc(String(dj.date||dj.time||'').slice(0,10))+' \u00b7 \u6700\u8fd1\u5199\u8fc7</div>');h.push('<p class="xd-rtext">'+esc(one(dj.text||dj.content||dj.body||''))+'</p>');h.push('</section>');}
return '<div class="xd-page">'+h.join('')+'</div>';
}
function mark(id){var el=D.getElementById('xd-dock');if(!el)return;var bs=el.querySelectorAll('button');for(var i=0;i<bs.length;i++){bs[i].className=(bs[i].getAttribute('data-go')===id)?'on':'';}}
function go(id){
if(id==='home'){var hm=D.getElementById('home');if(hm)hm.scrollTo({top:0,behavior:'smooth'});mark('home');}
else if(window.Router&&Router.open){Router.open(id);}
}
function buildDock(){
var old=D.getElementById('xd-dock');if(old)old.parentNode.removeChild(old);
var el=D.createElement('div');el.id='xd-dock';
var s='';DOCK.forEach(function(it){s+='<button type="button" data-go="'+it.id+'">'+(ICON[it.id]||'')+'<span>'+it.name+'</span></button>';});
el.innerHTML=s;
el.addEventListener('click',function(e){var b=e.target;while(b&&b!==el){var g=b.getAttribute&&b.getAttribute('data-go');if(g){e.preventDefault();go(g);return;}b=b.parentNode;}});
D.body.appendChild(el);mark('home');
}
function buildRail(){
if(D.getElementById('xd-rail'))return;
var mask=D.createElement('div');mask.id='xd-mask';
var rail=D.createElement('aside');rail.id='xd-rail';
var list=apps(),s='';
s+='<div class="xd-rail-hd"><b>\u5c0f\u7a9d</b><em>OUR SPACE</em></div>';
s+='<div class="xd-rail-list">';
s+='<button type="button" data-go="home">'+ICON.home+'<span>\u9996\u9875</span><em>HOME</em></button>';
list.forEach(function(a){if(a.id==='home')return;s+='<button type="button" data-go="'+a.id+'">'+(ICON[a.id]||ICON.star)+'<span>'+esc(a.name)+'</span><em>'+esc(String(a.id).toUpperCase())+'</em></button>';});
s+='</div><div class="xd-rail-ft" id="xd-rail-ft"></div>';
rail.innerHTML=s;
function close(){rail.className='';mask.className='';}
mask.addEventListener('click',close);
rail.addEventListener('click',function(e){var b=e.target;while(b&&b!==rail){var g=b.getAttribute&&b.getAttribute('data-go');if(g){e.preventDefault();close();go(g);return;}b=b.parentNode;}});
D.body.appendChild(mask);D.body.appendChild(rail);
var ft=D.getElementById('xd-rail-ft');
if(ft){var ver=D.documentElement.getAttribute('data-ver')||'';var d2=days();ft.textContent=(d2>=0?'\u7b2c '+d2+' \u5929 \u00b7 ':'')+ver;}
}
function openRail(){var r=D.getElementById('xd-rail'),m=D.getElementById('xd-mask');if(!r||!m)return;r.className='on';m.className='on';}
function bindScroll(home){
var dock=D.getElementById('xd-dock');if(!dock)return;
var last=home.scrollTop,tk=false;
home.addEventListener('scroll',function(){
if(tk)return;tk=true;
requestAnimationFrame(function(){var y=home.scrollTop,dy=y-last;if(y<20)dock.className='';else if(dy>4)dock.className='hide';else if(dy<-4)dock.className='';last=y;tk=false;});
},{passive:true});
}
function weather(){
var el=D.getElementById('xd-wx'),sub=D.getElementById('xd-wxs');if(!el||!sub)return;
fetch('https://wttr.in/?format=j1',{cache:'no-store'}).then(function(r){return r.json();}).then(function(j){
var c=j&&j.current_condition&&j.current_condition[0];if(!c)throw new Error('no');
el.textContent=c.temp_C+'\u00b0';
sub.textContent=(c.weatherDesc&&c.weatherDesc[0]&&c.weatherDesc[0].value)||'\u2014';
}).catch(function(){sub.textContent='\u53d6\u4e0d\u5230\u5929\u6c14';});
}
function isDate(v){var s=String(v);if(s.length!==10)return false;if(s.charAt(4)!=='-'||s.charAt(7)!=='-')return false;return isFinite(parseInt(s.slice(0,4),10))&&isFinite(parseInt(s.slice(5,7),10))&&isFinite(parseInt(s.slice(8,10),10));}
function ask(kind){
var cur='',tip='',key='';
if(kind==='bio'){cur=gs('xw_bio');tip='\u5199\u4e00\u53e5\u4ecb\u7ecd';key='xw_bio';}
else if(kind==='quote'){cur=gs('xw_quote');tip='\u5199\u4e00\u53e5\u8bdd';key='xw_quote';}
else if(kind==='start'){cur=startDate();tip='\u8d77\u7b97\u65e5\uff0c\u5982 2026-05-11';key='xw_loveDate';}
else return;
var v=window.prompt(tip,cur||'');
if(v===null)return;
v=String(v).replace(/^ +/,'').replace(/ +$/,'');
if(kind==='start'&&v&&!isDate(v)){window.alert('\u8981\u5199\u6210 2026-05-11 \u8fd9\u6837');return;}
if(v)ss(key,v);else{try{localStorage.removeItem(key);}catch(e){}}
if(kind==='start'&&v){try{XW.S.loveDate=v;XW.save('loveDate');}catch(e){}}
var home=D.getElementById('home');if(home)home.innerHTML=build();
weather();
}
function mount(){
var home=D.getElementById('home');
if(!home)return;
if(home.getAttribute('data-xd')==='1')return;
home.className='home xd-home';
home.setAttribute('data-xd','1');
home.innerHTML=build();
home.addEventListener('click',function(e){
var el=e.target;
while(el&&el!==home){
if(el.id==='xd-open-rail'){e.preventDefault();openRail();return;}
var set=el.getAttribute&&el.getAttribute('data-set');
if(set){e.preventDefault();ask(set);return;}
var g=el.getAttribute&&el.getAttribute('data-go');
if(g){e.preventDefault();go(g);return;}
el=el.parentNode;
}
});
buildDock();buildRail();bindScroll(home);weather();
done=true;
}
function tick(){if(done)return;mount();}
var tries=0;
var iv=setInterval(function(){tries++;tick();if(done||tries>40)clearInterval(iv);},150);
if(window.MutationObserver&&D.body){new MutationObserver(function(){if(!done)setTimeout(tick,30);}).observe(D.body,{childList:true,subtree:true});}
setTimeout(tick,300);setTimeout(tick,900);setTimeout(tick,1800);
})();
