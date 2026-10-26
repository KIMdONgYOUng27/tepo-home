(() => {
  'use strict';
  const session=window.TEPO_RADIO_SESSION,dialog=document.createElement('dialog');
  dialog.id='tepo-radio-dialog';dialog.setAttribute('aria-labelledby','radio-title');document.body.append(dialog);
  const icon='<svg viewBox="0 0 40 48" aria-hidden="true"><path d="M11 17 5 3M8 2l-4 2"/><rect x="8" y="15" width="25" height="30" rx="6"/><path d="M25 15v-5h5v5M14 25h13M14 30h13M14 35h8"/><circle cx="27" cy="21" r="2" class="radio-light"/></svg>';
  const clone=value=>JSON.parse(JSON.stringify(value));
  const progress=()=>{try{return JSON.parse(sessionStorage.getItem('tepo-lighthouse-visit-v2')||'{}');}catch{return {};}};
  session.migrate();let state,opener,timer,busy=false,currentPanel='chat',form,cleanReset=false,mode='radio',untranslated=false,gifting=false,signalTimer;
  const fresh=()=>({history:[],context:{},buttons:clone(window.TEPO_RADIO_DIALOGUE.buttons),checkpoints:[],pending:null,panel:'chat',mode,draft:'',open:true});
  function launcher(parent){if(parent.querySelector(':scope > .radio-toggle'))return;const button=document.createElement('button');button.className='radio-toggle';button.dataset.tepoRadio='';button.setAttribute('aria-label','테포에게 무전하기');button.innerHTML=icon+'<span>무전</span>';parent.append(button);}
  function sync(){
    const owned=session.owned();if(owned){launcher(document.body);document.querySelectorAll('dialog[open]:not(#tepo-radio-dialog):not(#world-bag-dialog):not(#world-welcome):not(.world-travel)').forEach(modal=>launcher(modal.querySelector('.game-player')||modal));}
    const active=[...document.querySelectorAll('dialog[open]')].at(-1);document.querySelectorAll('.radio-toggle').forEach(button=>button.hidden=!owned||dialog.open||!!active&&(!active.contains(button)||['world-bag-dialog','world-welcome'].includes(active.id)||active.classList.contains('world-travel')));
  }
  function persist(){if(untranslated||!state||cleanReset&&!state.history.length)return;state.panel=currentPanel;state.mode=mode;state.open=dialog.open;session.save(state);}
  function message(role,text){const line=document.createElement('p');line.className='radio-message from-'+role;const who=document.createElement('span');who.className='radio-speaker';who.textContent=role==='tepo'?'테포':'나';const body=document.createElement('span');body.textContent=text;line.append(who,body);dialog.querySelector('.radio-log').append(line);}
  function scroll(){const log=dialog.querySelector('.radio-log');log.scrollTop=log.scrollHeight;}
  function controls(){const back=dialog.querySelector('[data-control=previous]');if(back)back.disabled=!state.checkpoints.length&&currentPanel==='chat';}
  function panel(name,save=true){currentPanel=name;state.panel=name;for(const [selector,visible] of [['.radio-faq',name==='faq'],['.radio-inquiry',name==='inquiry'],['.radio-log',name==='chat'],['.radio-suggestions',name==='chat'],['.radio-compose',name==='chat'&&!untranslated&&!gifting]])dialog.querySelector(selector).hidden=!visible;dialog.querySelectorAll('[data-radio-panel]').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.radioPanel===name)));dialog.querySelector('.radio-bottom-menu').hidden=untranslated||gifting;dialog.querySelector('.radio-controls').hidden=untranslated||gifting;controls();if(name==='chat')scroll();if(save)persist();}
  function suggestions(){const host=dialog.querySelector('.radio-suggestions');host.replaceChildren();state.buttons.forEach(item=>{const button=document.createElement('button');button.type='button';button.textContent=item.label;button.onclick=()=>send(item.question||item.label,item.next);button.disabled=busy;host.append(button);});}
  function available(value){busy=!value;dialog.querySelector('textarea#radio-input').disabled=!value||untranslated;dialog.querySelector('.radio-send').disabled=!value||untranslated;dialog.querySelectorAll('.radio-suggestions button,.radio-faq button').forEach(button=>button.disabled=!value);controls();}
  function snapshot(){state.checkpoints.push({length:state.history.length,context:clone(state.context),buttons:clone(state.buttons),panel:currentPanel});state.checkpoints=state.checkpoints.slice(-25);}
  function redraw(){const log=dialog.querySelector('.radio-log');log.replaceChildren();state.history.forEach(item=>message(item.role,item.text));suggestions();scroll();controls();}
  function previous(){
    if(currentPanel!=='chat'){panel('chat');return;}const before=state.checkpoints.pop();if(!before)return;clearTimeout(timer);state.pending=null;state.history=state.history.slice(0,before.length);state.context=before.context;state.buttons=before.buttons;state.draft='';dialog.querySelector('#radio-input').value='';available(true);redraw();panel(before.panel);connection();persist();
  }
  function home(){if(state.pending)previous();snapshot();state.context={};state.buttons=clone(window.TEPO_RADIO_DIALOGUE.buttons);state.history.push({role:'tepo',text:window.TEPO_RADIO_DIALOGUE.ui.root});redraw();panel('chat');persist();}
  function reset(){clearTimeout(timer);session.clear();state=fresh();cleanReset=true;build();message('tepo',window.TEPO_RADIO_DIALOGUE.ui.reset);available(true);connection();}
  function complete(){
    const pending=state.pending;if(!pending)return;
    try{const result=window.TEPO_RADIO_DIALOGUE.answer(pending.question,state.context,progress(),pending.target);if(result.saveTrip)window.TEPO_STORY.keepCourse(result.saveTrip);state.context=result.context||{};state.buttons=result.buttons;state.history.push({role:'tepo',text:result.text});state.pending=null;
      const removed=Math.max(0,state.history.length-80);if(removed){state.history.splice(0,removed);state.checkpoints=state.checkpoints.filter(item=>item.length>=removed).map(item=>({...item,length:item.length-removed}));}
      redraw();available(true);connection();if(result.showFaq)panel('faq');else if(result.showInquiry){state.inquiryType=result.showInquiry;form.setType(result.showInquiry);panel('inquiry');}else{panel('chat');dialog.querySelector('#radio-input').focus({preventScroll:true});}persist();
    }catch{available(true);dialog.querySelector('.radio-connection').textContent='응답을 불러오지 못했어. 이전으로 돌아가 다시 물어봐 줘.';persist();}
  }
  function send(text,target){if(busy||untranslated||gifting||!dialog.open)return;const clean=text.trim().slice(0,300);if(!clean)return;cleanReset=false;snapshot();state.draft='';dialog.querySelector('#radio-input').value='';state.history.push({role:'visitor',text:clean});state.pending={question:clean,target};panel('chat');redraw();available(false);dialog.querySelector('.radio-connection').textContent='테포가 응답하는 중…';persist();timer=setTimeout(complete,400);}
  function build(){
    const ui=window.TEPO_RADIO_DIALOGUE.ui;
    dialog.innerHTML='<section class="radio-shell"><header><div><p>TEPO · LIGHTHOUSE CHANNEL</p><h2 id="radio-title">테포에게 무전</h2></div><button class="radio-close" aria-label="무전 닫기">×</button></header><div class="radio-portrait"><img src="assets/tepo-radio-answer-v30.png" alt="무전기로 반갑게 응답하는 테포"><div><span class="radio-signal" aria-label="무전 신호 4칸"><i></i><i></i><i></i><i></i></span><p class="radio-connection" role="status">치직… 등대로 연결하는 중…</p></div></div><section class="radio-faq" aria-label="자주 묻는 질문" hidden></section><section class="radio-inquiry" aria-label="관리자 문의 작성" hidden><div class="radio-inquiry-form"></div><a href="contact.html">문의 페이지에서 작성하기 ↗</a></section><div class="radio-log" role="log" aria-label="테포와 무전 대화" aria-live="polite" aria-relevant="additions"></div><nav class="radio-suggestions" aria-label="추천 질문"></nav><nav class="radio-bottom-menu" aria-label="대화 메뉴"><button type="button" data-radio-panel="chat">대화</button><button type="button" data-radio-panel="faq">자주 묻는 질문</button><button type="button" data-radio-panel="inquiry">관리자 문의</button></nav><form class="radio-compose"><label class="radio-input-label" for="radio-input">테포에게 물어보기</label><textarea id="radio-input" rows="2" maxlength="300" placeholder="테포야, 궁금한 게 있어…"></textarea><button class="radio-send" type="submit">보내기</button></form><nav class="radio-controls" aria-label="대화 이동"><button type="button" data-control="previous"></button><button type="button" data-control="home"></button><button type="button" data-control="reset"></button></nav></section>';
    for(const [id,label,fn] of [['previous',ui.previous,previous],['home',ui.home,home],['reset',ui.resetButton,reset]]){const button=dialog.querySelector('[data-control='+id+']');button.textContent=label;button.onclick=fn;}
    const faq=dialog.querySelector('.radio-faq');window.TEPO_RADIO_DIALOGUE.faq.forEach(group=>{const section=document.createElement('section'),title=document.createElement('h3');title.textContent=group.title;section.append(title);group.questions.forEach(question=>{const button=document.createElement('button');button.type='button';button.textContent=question;button.onclick=()=>send(question);section.append(button);});faq.append(section);});
    form=window.TEPO_INQUIRIES.mount(dialog.querySelector('.radio-inquiry-form'),{source:'chatbot',type:state.inquiryType||'general',onTypeChange:value=>{state.inquiryType=value;persist();}});
    dialog.querySelectorAll('[data-radio-panel]').forEach(button=>button.onclick=()=>panel(button.dataset.radioPanel));dialog.querySelector('.radio-close').onclick=finish;dialog.querySelector('.radio-compose').onsubmit=event=>{event.preventDefault();send(dialog.querySelector('#radio-input').value);};
    const input=dialog.querySelector('#radio-input');input.value=state.draft||'';input.oninput=()=>{state.draft=input.value;persist();};input.addEventListener('keydown',event=>{if(event.key==='Enter'&&!event.shiftKey&&!event.isComposing){event.preventDefault();send(input.value);}});
    dialog.classList.toggle('face-conversation',mode==='face');
    dialog.querySelector('#radio-title').textContent=mode==='face'?'테포와 이야기':'테포에게 무전';
    dialog.querySelector('.radio-shell header p').textContent=mode==='face'?'TEPO · LIGHTHOUSE HOME':'TEPO · LIGHTHOUSE CHANNEL';
    const portrait=dialog.querySelector('.radio-portrait>img');portrait.src=mode==='face'?'assets/tepo-dialogue-front-v1.png':'assets/tepo-radio-face-v33.png';portrait.alt=mode==='face'?'직접 마주한 테포':'무전기를 귀에 대고 응답하는 테포의 얼굴';
    dialog.querySelector('.radio-close').setAttribute('aria-label',mode==='face'?'대화 마치기':'무전 닫기');
    dialog.querySelector('.radio-signal').hidden=mode==='face';
    const end=document.createElement('button');end.className='radio-finish';end.textContent=mode==='face'?ui.finish:'무전 마치기';end.onclick=finish;dialog.querySelector('.radio-shell').append(end);
    redraw();panel(untranslated?'chat':state.panel||'chat',false);connection();
    if(untranslated){dialog.querySelector('.radio-suggestions').replaceChildren();const close=document.createElement('button');close.textContent='주변을 살펴본다';close.onclick=()=>dialog.close();dialog.querySelector('.radio-suggestions').append(close);}

  }
  function connection(){dialog.querySelector('.radio-connection').textContent=mode==='face'?(untranslated?'낯선 목소리 · 말이 통하지 않는다':'등대에서 마주 앉아 이야기 중'):'등대 채널 · 연결됨';}
  function signal(){
    clearTimeout(signalTimer);if(!dialog.open||mode!=='radio')return;
    const level=Math.random()<.6?4:3,el=dialog.querySelector('.radio-signal');el.dataset.level=level;el.setAttribute('aria-label','무전 신호 '+level+'칸');
    signalTimer=setTimeout(signal,1400+Math.random()*1900);
  }
  function finish(){
    if(mode==='face'&&!untranslated&&!session.owned()&&!gifting){
      gifting=true;clearTimeout(timer);if(state.pending)complete();state.pending=null;available(true);panel('chat');
      message('tepo',window.TEPO_RADIO_DIALOGUE.ui.gift);const host=dialog.querySelector('.radio-suggestions');host.replaceChildren();
      for(const [label,receive] of [[window.TEPO_RADIO_DIALOGUE.ui.giftReceive,true],[window.TEPO_RADIO_DIALOGUE.ui.giftLater,false]]){
        const button=document.createElement('button');button.textContent=label;button.onclick=()=>{
          if(receive&&!window.TEPO_STORY.receiveRadio())return;
          if(receive){state.history.push({role:'tepo',text:window.TEPO_RADIO_DIALOGUE.ui.giftTaken});persist();}
          dialog.close();
        };host.append(button);
      }
      dialog.querySelector('.radio-finish').hidden=true;scroll();host.querySelector('button').focus();return;
    }
    dialog.close();
  }
  async function open(from,options={}){
    if(dialog.open)return;
    try{await window.TEPO_DIALOGUE.ready;await window.TEPO_STORY_READY;}catch{alert('대화 데이터를 불러오지 못했어. 잠시 후 다시 시도해 줘.');return;}
    const nextMode=options.mode==='face'?'face':'radio';
    if(nextMode==='radio'&&!session.owned())return;
    if(nextMode==='face'&&(!window.TEPO_STORY.awake||!document.querySelector('#tepo')))return;
    mode=nextMode;opener=from||document.activeElement;gifting=false;untranslated=mode==='face'&&!window.TEPO_STORY.translated;
    state=untranslated?fresh():session.load()||fresh();state.mode=mode;
    if(!state.buttons.length)state.buttons=clone(window.TEPO_RADIO_DIALOGUE.buttons);cleanReset=false;
    if(untranslated){state.history=[{role:'tepo',text:window.TEPO_RADIO_DIALOGUE.ui.untranslated},{role:'visitor',text:window.TEPO_RADIO_DIALOGUE.ui.untranslatedThought}];}
    else if(!state.history.length)state.history.push({role:'tepo',text:mode==='face'?window.TEPO_RADIO_DIALOGUE.ui.directHello:window.TEPO_RADIO_DIALOGUE.ui.hello});
    build();dialog.showModal();scroll();dialog.querySelector('.radio-close').focus();available(true);persist();signal();sync();
    if(state.pending&&!untranslated)timer=setTimeout(complete,400);
  }
  document.addEventListener('click',event=>{const button=event.target.closest('[data-tepo-radio]');if(button)open(button);});
  dialog.addEventListener('close',()=>{clearTimeout(timer);clearTimeout(signalTimer);persist();busy=false;gifting=false;if(opener?.isConnected)opener.focus({preventScroll:true});sync();});
  new MutationObserver(sync).observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['open']});addEventListener('tepo-inventory-change',sync);sync();window.TEPO_RADIO={open,openFace:from=>open(from,{mode:'face'}),icon};
  dialog.addEventListener('cancel',event=>{event.preventDefault();finish();});
  if(session.load()?.open&&session.load()?.mode!=='face'&&session.owned())open();
})();
