/* One world theme, shared across locations; original short foley in a small bank. */
(() => {
  'use strict';
  const policy=window.TEPO_AUDIO_POLICY,base=new URL('.',document.currentScript.src);
  const settingsKey='tepo-sound-settings-v1',positionKey='tepo-music-position-v1',armedKey='tepo-sound-started-v1';
  const read=(store,key)=>{try{return JSON.parse(store.getItem(key)||'null');}catch{return null;}};
  let prefs=policy.settings(read(localStorage,settingsKey)||{}),armed=read(sessionStorage,armedKey)===true,context,sfxGain,opener;
  let target=0,current=0,last=performance.now(),scheduled=false,lastGameKey='',lastFrame=null,loading=false,failed=false,blocked=false;
  const music=document.createElement('audio');music.id='tepo-main-bgm';music.loop=true;music.preload='none';music.hidden=true;music.volume=0;document.body.append(music);
  const panel=document.createElement('dialog');panel.id='world-audio-settings';panel.setAttribute('aria-labelledby','audio-title');
  panel.innerHTML='<header><h2 id="audio-title">소리 설정</h2><button class="audio-close" aria-label="소리 설정 닫기">×</button></header><section class="audio-body"><p class="audio-song">♪ Tepo · 메인 테마</p><button class="audio-mute" type="button"></button><label class="audio-control"><span>배경음<output data-level="bgm"></output></span><input type="range" min="0" max="100" step="1" data-volume="bgm" aria-label="배경음 음량"></label><label class="audio-control"><span>효과음<output data-level="sfx"></output></span><input type="range" min="0" max="100" step="1" data-volume="sfx" aria-label="효과음 음량"></label><label class="audio-control"><span>게임 소리<output data-level="game"></output></span><input type="range" min="0" max="100" step="1" data-volume="game" aria-label="게임 소리 음량"></label><p class="audio-status" role="status"></p><button class="audio-preview" type="button">효과음 미리 듣기</button><p class="audio-note">지도·등대·오락실은 같은 곡으로 이어져요.<br>대화 중에는 작게, 게임·영상 재생 중에는 쉬어 가요.<br>처음에는 화면을 한 번 눌러 소리를 켜 주세요.</p></section>';
  document.body.append(panel);
  const status=panel.querySelector('.audio-status'),mute=panel.querySelector('.audio-mute');
  function storedPosition(){const value=read(sessionStorage,positionKey);return Number.isFinite(value)&&value>=0?value:0;}
  music.addEventListener('loadedmetadata',()=>{const saved=storedPosition();if(saved>0&&Number.isFinite(music.duration))music.currentTime=saved%music.duration;});
  music.addEventListener('error',()=>{failed=true;loading=false;refreshStatus();});
  music.addEventListener('playing',()=>{failed=false;blocked=false;loading=false;refreshStatus();});
  function savePosition(){if(music.getAttribute('src')&&Number.isFinite(music.currentTime))try{sessionStorage.setItem(positionKey,JSON.stringify(music.currentTime));}catch{}}
  function ensureContext(){
    if(context)return context;const Audio=window.AudioContext||window.webkitAudioContext;if(!Audio)return null;
    context=new Audio({latencyHint:'interactive'});sfxGain=context.createGain();const limiter=context.createDynamicsCompressor();limiter.threshold.value=-12;limiter.ratio.value=5;sfxGain.connect(limiter);limiter.connect(context.destination);sfxGain.gain.value=prefs.muted?0:prefs.sfx;return context;
  }
  const bankReady=fetch(new URL('assets/audio/sound-bank-v40.json',base)).then(r=>{if(!r.ok)throw Error('sound bank');return r.json();});bankReady.catch(()=>{});
  const buffers=new Map();
  const gameFrames=new Set(),sources=new Set();
  function buffer(name){if(buffers.has(name))return buffers.get(name);const promise=bankReady.then(async bank=>{const item=bank.sounds[name];if(!item)throw Error('Unknown sound');const res=await fetch(new URL(item.src,base));if(!res.ok)throw Error('Audio unavailable');return {item,audio:await ensureContext().decodeAudioData(await res.arrayBuffer())};});buffers.set(name,promise);promise.catch(()=>buffers.delete(name));return promise;}
  function play(name,{delay=0,gain=1}={}){
    if(!armed||prefs.muted||!prefs.sfx||document.hidden||!ensureContext())return;
    const requested=performance.now();
    buffer(name).then(({item,audio})=>{
      if(prefs.muted||document.hidden||performance.now()-requested>1600)return;
      const source=context.createBufferSource(),level=context.createGain();source.buffer=audio;level.gain.value=item.gain*gain;source.connect(level);level.connect(sfxGain);
      sources.add(source);source.start(context.currentTime+Math.max(0,delay));source.onended=()=>{sources.delete(source);source.disconnect();level.disconnect();};
      document.body.dataset.lastSound=name;document.dispatchEvent(new CustomEvent('tepo-sound-play',{detail:{name,delay}}));
    }).catch(()=>{});
  }
  function collect(id){bankReady.then(bank=>policy.collectSequence(id,bank.sounds).forEach(cue=>play(cue.name,{delay:cue.delay}))).catch(()=>{});}
  async function startMusic(){
    if(!armed||target<=0||document.hidden||loading||!music.paused)return;
    if(!music.getAttribute('src'))music.src=new URL('assets/audio/tepo-main-v1.mp3',base).href;
    loading=true;refreshStatus();try{await music.play();failed=false;blocked=false;}catch(error){if(error.name!=='AbortError'){blocked=error.name==='NotAllowedError';failed=!blocked;}}finally{loading=false;refreshStatus();}
  }
  function unlock(event){
    if(event?.type==='keydown'&&(event.metaKey||event.ctrlKey||event.altKey||!['Enter',' ','Spacebar'].includes(event.key)))return;
    armed=true;try{sessionStorage.setItem(armedKey,'true');}catch{}
    const ctx=ensureContext();if(ctx?.state==='suspended')ctx.resume().catch(()=>{});schedule();
    startMusic();['ui_click','paper_open','bag_collect'].forEach(name=>buffer(name).catch(()=>{}));
  }
  function refreshStatus(){const text=failed?'브금을 불러오지 못했어요. 소리 버튼으로 다시 시도해 주세요.':prefs.muted?'전체 소리를 껐어요.':!armed||blocked?'화면을 한 번 누르면 소리가 시작돼요.':loading?'브금을 불러오는 중이에요.':document.querySelector('.game-player,.entering-machine')?(prefs.game===0?'게임 소리를 껐어요.':'게임 음악으로 전환했어요.'):document.querySelector('.youtube-embed')?'영상 소리를 듣는 중이에요.':prefs.bgm===0?'배경음은 꺼져 있어요.':'메인 테마 재생 중';if(status.textContent!==text)status.textContent=text;if(status.classList.contains('audio-error')!==failed)status.classList.toggle('audio-error',failed);}
  function refreshControls(){
    const label=prefs.muted?'전체 소리 켜기':'전체 소리 끄기';if(mute.textContent!==label)mute.textContent=label;mute.setAttribute('aria-pressed',String(prefs.muted));
    for(const slider of panel.querySelectorAll('[data-volume]')){const key=slider.dataset.volume,value=Math.round(prefs[key]*100);slider.value=value;const output=panel.querySelector('[data-level='+key+']');if(output.textContent!==value+'%')output.textContent=value+'%';}
    document.querySelectorAll('[data-world-audio]').forEach(b=>{const text=b.parentElement===document.body?(!armed||blocked?'♪ 소리 켜기':prefs.muted?'♪ 소리 꺼짐':'♪ 소리'):(prefs.muted?'♩':'♪');if(b.textContent!==text)b.textContent=text;b.dataset.muted=String(prefs.muted);});refreshStatus();
  }
  function launcher(parent){if(parent.id==='tepo-photo-zone')parent=parent.querySelector('.photo-utilities')||parent;if(parent.querySelector(':scope > [data-world-audio]'))return;const b=document.createElement('button');b.type='button';b.className='world-audio-toggle';b.dataset.worldAudio='';b.setAttribute('aria-label','소리 설정 열기');parent.append(b);}
  function hidden(el,value){if(el.hidden!==value)el.hidden=value;}
  function stopGame(frame){
    if(!frame)return;gameFrames.delete(frame);
    try{frame.contentWindow?.postMessage({type:'tepo-site-audio-stop'},location.origin);frame.contentWindow?.TepoMusic?.setSiteGain(0);frame.contentWindow?.TepoSiteAudio?.shutdown();frame.contentDocument?.querySelectorAll('audio,video').forEach(a=>{a.muted=true;a.pause();});}catch{}
    if(frame===lastFrame){lastFrame=null;lastGameKey='';}
  }
  function sendGame(gain){
    const frame=document.querySelector('.world-adventure[open] .game-player iframe');const key=String(gain);
    gameFrames.forEach(old=>{if(old!==frame)stopGame(old);});
    if(frame){gameFrames.add(frame);if(frame!==lastFrame||key!==lastGameKey){frame.contentWindow?.postMessage({type:'tepo-site-audio',gain,active:true},location.origin);try{frame.contentWindow?.TepoMusic?.setSiteGain(gain);}catch{}lastGameKey=key;lastFrame=frame;}}
    if(!frame){lastFrame=null;lastGameKey='';}
  }
  function update(){
    scheduled=false;const game=!!document.querySelector('.world-adventure[open] .game-player,.world-adventure[open] .entering-machine');
    const mixed=policy.mix(prefs,{armed,hidden:document.hidden,house:!!document.querySelector('#room-scene'),game,video:!!document.querySelector('.youtube-embed'),dialogue:!!document.querySelector('#tepo-radio-dialog[open],.view-conversation[open]')});target=mixed.bgm;
    music.muted=prefs.muted;
    if(sfxGain){if(prefs.muted){sfxGain.gain.cancelScheduledValues(context.currentTime);sfxGain.gain.value=0;sources.forEach(source=>{try{source.stop();}catch{}});}else sfxGain.gain.setTargetAtTime(mixed.sfx,context.currentTime,.025);}
    if(prefs.muted||document.hidden||document.querySelector('.game-player,.youtube-embed')){current=0;music.volume=0;if(!music.paused){savePosition();music.pause();}}
    sendGame(mixed.game);launcher(document.body);
    const modals=[...document.querySelectorAll('dialog[open]')],top=modals.at(-1);
    modals.filter(m=>m!==panel&&!m.classList.contains('world-travel')&&m.id!=='world-welcome'&&!m.hasAttribute('data-photo-sheet')).forEach(launcher);
    document.querySelectorAll('[data-world-audio]').forEach(b=>hidden(b,panel.open||!!top&&b.parentElement!==top&&!(top.id==='tepo-photo-zone'&&top.contains(b))));
    refreshControls();if(target>0)startMusic();
  }
  function schedule(){if(scheduled)return;scheduled=true;requestAnimationFrame(update);}
  function savePrefs(){try{localStorage.setItem(settingsKey,JSON.stringify(prefs));}catch{}refreshControls();update();}
  panel.querySelectorAll('[data-volume]').forEach(slider=>slider.addEventListener('input',()=>{unlock();prefs[slider.dataset.volume]=Number(slider.value)/100;savePrefs();}));
  mute.onclick=()=>{unlock();prefs.muted=!prefs.muted;savePrefs();};
  panel.querySelector('.audio-close').onclick=()=>panel.close();
  panel.querySelector('.audio-preview').onclick=()=>{play('ui_click');play('page_turn',{delay:.3});play('weapon_mace',{delay:.75});play('bag_collect',{delay:1.25});};
  panel.addEventListener('close',()=>{opener?.focus({preventScroll:true});document.querySelector('.game-player iframe')?.focus();schedule();});
  document.addEventListener('click',event=>{const b=event.target.closest('[data-world-audio]');if(!b)return;opener=b;unlock();if(failed){music.removeAttribute('src');music.load();failed=false;}if(!panel.open)panel.showModal();refreshControls();panel.querySelector('.audio-close').focus();schedule();});
  function frame(now){const dt=Math.min(.1,(now-last)/1000);last=now;current+=(target-current)*Math.min(1,dt*5);if(Math.abs(target-current)<.001)current=target;music.volume=Math.max(0,Math.min(1,current));if(current===0&&target===0&&!music.paused){savePosition();music.pause();}requestAnimationFrame(frame);}
  document.addEventListener('pointerdown',unlock,{capture:true});document.addEventListener('keydown',unlock,{capture:true});
  document.addEventListener('visibilitychange',()=>{if(document.hidden){savePosition();music.pause();}schedule();});
  addEventListener('pagehide',()=>{savePosition();music.pause();gameFrames.forEach(stopGame);});addEventListener('pageshow',event=>{if(event.persisted&&music.getAttribute('src')&&Number.isFinite(music.duration))music.currentTime=storedPosition()%music.duration;schedule();});
  addEventListener('storage',e=>{if(e.key===settingsKey){prefs=policy.settings(read(localStorage,settingsKey)||{});schedule();}});
  addEventListener('message',e=>{const f=document.querySelector('.game-player iframe');if(e.origin!==location.origin||e.source!==f?.contentWindow)return;if(e.data?.type==='tepo-site-audio-state'){if(Number.isFinite(e.data.gain))f.dataset.gameAudioGain=String(e.data.gain);if(Number.isInteger(e.data.audibleMedia))f.dataset.gameAudibleMedia=String(e.data.audibleMedia);}else if(['tepo-game','tepo-site-audio-ready'].includes(e.data?.type)){lastGameKey='';schedule();}});
  document.addEventListener('load',e=>{if(e.target.matches?.('.game-player iframe')){lastGameKey='';schedule();}},true);
  new MutationObserver(schedule).observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['open','class','hidden']});
  setInterval(()=>{if(!music.paused)savePosition();},1200);
  window.TEPO_AUDIO={play,collect,stopGame,settings:()=>({...prefs})};
  requestAnimationFrame(frame);update();
})();
