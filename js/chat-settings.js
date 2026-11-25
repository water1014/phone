/* chat-settings.js */
const CHAT_SETTINGS={model:'gpt-4',temperature:0.7,maxTokens:2000,stream:true,think:true,showTime:true,compact:false};
function initChatSettings(){loadSettings();render();bind();}
function loadSettings(){const s=localStorage.getItem('xw_chat_settings');if(s)Object.assign(CHAT_SETTINGS,JSON.parse(s));}
function saveSettings(){localStorage.setItem('xw_chat_settings',JSON.stringify(CHAT_SETTINGS));}
function render(){
  const el=document.getElementById('app-body');if(!el)return;
  el.innerHTML='<div class="cs-wrap"><div class="cs-section"><h4>模型</h4><div id="cs-models"></div></div><div class="cs-section"><h4>参数</h4><div class="cs-row"><span class="txt"><span class="name">温度</span><span class="desc">控制回复的随机性</span></span><span class="val">'+CHAT_SETTINGS.temperature+'</span></div><div class="cs-row"><span class="txt"><span class="name">最大长度</span><span class="desc">单次回复最大token数</span></span><span class="val">'+CHAT_SETTINGS.maxTokens+'</span></div></div><div class="cs-section"><h4>功能</h4><div class="cs-row"><span class="txt"><span class="name">流式输出</span></span><button class="toggle '+(CHAT_SETTINGS.stream?'on':'')+'" id="cs-stream"></button></div><div class="cs-row"><span class="txt"><span class="name">显示思考过程</span></span><button class="toggle '+(CHAT_SETTINGS.think?'on':'')+'" id="cs-think"></button></div><div class="cs-row"><span class="txt"><span class="name">显示时间</span></span><button class="toggle '+(CHAT_SETTINGS.showTime?'on':'')+'" id="cs-time"></button></div><div class="cs-row"><span class="txt"><span class="name">紧凑模式</span></span><button class="toggle '+(CHAT_SETTINGS.compact?'on':'')+'" id="cs-compact"></button></div></div><div class="cs-actions"><button class="cancel">取消</button><button class="save">保存</button></div></div>';
  renderModels();bindToggles();
}
function renderModels(){
  const models=[{id:'gpt-4',name:'GPT-4'},{id:'gpt-4o',name:'GPT-4o'},{id:'claude-3',name:'Claude 3'},{id:'gemini',name:'Gemini'}];
  const el=document.getElementById('cs-models');if(!el)return;
  el.innerHTML=models.map(m=>`<div class="cs-row ${m.id===CHAT_SETTINGS.model?'on':''}" data-id="${m.id}"><span class="ico">${m.name[0]}</span><span class="txt"><span class="name">${m.name}</span></span><span class="tag">${m.id===CHAT_SETTINGS.model?'使用中':''}</span></div>`).join('');
  el.querySelectorAll('.cs-row').forEach(r=>r.onclick=()=>{CHAT_SETTINGS.model=r.dataset.id;saveSettings();renderModels();});
}
function bindToggles(){
  document.getElementById('cs-stream').onclick=function(){CHAT_SETTINGS.stream=!CHAT_SETTINGS.stream;this.classList.toggle('on');saveSettings();};
  document.getElementById('cs-think').onclick=function(){CHAT_SETTINGS.think=!CHAT_SETTINGS.think;this.classList.toggle('on');saveSettings();};
  document.getElementById('cs-time').onclick=function(){CHAT_SETTINGS.showTime=!CHAT_SETTINGS.showTime;this.classList.toggle('on');saveSettings();};
  document.getElementById('cs-compact').onclick=function(){CHAT_SETTINGS.compact=!CHAT_SETTINGS.compact;this.classList.toggle('on');saveSettings();};
  document.querySelector('.cs-actions .cancel').onclick=()=>history.back();
  document.querySelector('.cs-actions .save').onclick=()=>{saveSettings();showToast('已保存');};
}
function bind(){}
function showToast(msg){const t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');setTimeout(()=>t.classList.remove('show'),2000);}
initChatSettings();
