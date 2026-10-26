(() => {
  'use strict';
  const state=window.TEPO_WORLD_STATE;
  const dialog=document.createElement('dialog');
  dialog.className='world-adventure';dialog.setAttribute('aria-labelledby','adventure-title');
  document.body.append(dialog);
  let opener=null,timers=[],frame=null,gameTimer=null,busy=false;
  const later=(fn,ms)=>{const id=setTimeout(fn,ms);timers.push(id);return id;};
  function cleanup(){timers.forEach(clearTimeout);timers=[];clearTimeout(gameTimer);if(frame){frame.remove();frame=null;}busy=false;}
  function scene(html,kind='paper'){cleanup();dialog.className='world-adventure '+kind;dialog.innerHTML='<button class="adventure-close" aria-label="지도로 돌아가기">← 지도</button>'+html;dialog.querySelector('.adventure-close').onclick=leaveArcade;}
  function leaveArcade(){window.TEPO_NAVIGATION.returnToMap('arcade',{close:()=>dialog.close(),surface:dialog.querySelector('.entrance-stage')||dialog.querySelector('.arcade-room')});}
  function button(label,fn,host=dialog.querySelector('.adventure-actions')){const b=document.createElement('button');b.textContent=label;b.onclick=fn;host.append(b);return b;}
  function paper(title,text){scene('<article class="adventure-paper"><p class="chapter-label">테포의 부산 · 작은 모험</p><h2 id="adventure-title">'+title+'</h2><p class="adventure-copy"></p><div class="adventure-actions"></div></article>');dialog.querySelector('.adventure-copy').textContent=text;}
  function home(){location.href='house.html';}
  function arcade(){
    if(state.read().arcadeUnlocked){arcadeRoom();return;}
    const owned=state.read().weapons?.includes('mace');
    scene(`<section class="entrance-scene"><div class="entrance-stage">
      <img class="entrance-background" src="assets/arcade-entrance-paper-v27.png" alt="종이 질감의 수채화로 그린 청록색 창틀과 크림색 벽의 바닷가 오락실">
      <div class="entrance-door-wrap">
        <button class="entrance-door" aria-label="오락실 문 열어 보기"><svg viewBox="69 42 745 1691" preserveAspectRatio="none" aria-hidden="true"><image href="assets/arcade-door-paper-alpha-v27.png" width="887" height="1774"/></svg></button>
        <svg class="entrance-chain" viewBox="0 0 360 70" aria-hidden="true"><defs><pattern id="chain-links" width="26" height="19" patternUnits="userSpaceOnUse"><ellipse cx="13" cy="10" rx="15" ry="7" fill="none" stroke="#69848a" stroke-width="7"/><ellipse cx="13" cy="9" rx="15" ry="6" fill="none" stroke="#e0ecea" stroke-width="3"/></pattern></defs><path d="M0 13 Q155 70 360 10" fill="none" stroke="url(#chain-links)" stroke-width="19"/></svg>
        <button class="entrance-lock" aria-label="문에 걸린 자물쇠 살펴보기"><svg viewBox="150 9 906 1287" preserveAspectRatio="xMidYMid meet" aria-hidden="true"><image href="assets/arcade-padlock-alpha-v23.png" width="1206" height="1305"/></svg></button>
      </div>
      <div class="entrance-mace" aria-hidden="true">${window.TEPO_WEAPONS.picture(window.TEPO_WEAPONS.items.find(i=>i.id==='mace'))}</div>
      <div class="entrance-impact" aria-hidden="true">✷</div>
    </div><h2 class="entrance-title" id="adventure-title">테포 오락실</h2>
    <section class="entrance-dialogue" hidden aria-label="입구에서의 생각"><p class="entrance-message" role="status" aria-live="polite"></p><div class="adventure-actions"></div></section></section>`,'entrance-view');
    const area=dialog.querySelector('.entrance-scene'),door=dialog.querySelector('.entrance-door'),lock=dialog.querySelector('.entrance-lock'),caption=dialog.querySelector('.entrance-dialogue'),line=dialog.querySelector('.entrance-message'),actions=dialog.querySelector('.adventure-actions');
    let attempted=false,inspected=false;
    area.classList.add('art-loading');
    Promise.all(['assets/arcade-entrance-paper-v27.png','assets/arcade-door-paper-alpha-v27.png','assets/arcade-padlock-alpha-v23.png'].map(src=>{const image=new Image();image.src=src;return image.decode();})).then(()=>{if(area.isConnected)area.classList.remove('art-loading');}).catch(()=>{if(area.isConnected){area.classList.remove('art-loading');caption.hidden=false;line.textContent='입구 그림을 불러오지 못했어. 잠시 후 다시 열어 줘.';}});
    door.onclick=()=>{
      if(busy)return;
      area.classList.remove('trying-door');void area.offsetWidth;area.classList.add('trying-door');
      attempted=true;lock.disabled=false;lock.classList.add('is-discovered');caption.hidden=false;
      if(!inspected)line.textContent='덜컥, 덜컥… 문이 열리지 않는다.';
      later(()=>area.classList.remove('trying-door'),650);
    };
    lock.onclick=()=>{
      if(busy)return;
      if(!attempted){door.onclick();return;}
      inspected=true;lock.classList.remove('is-discovered');caption.hidden=false;actions.replaceChildren();
      if(owned){
        busy=true;door.disabled=true;lock.disabled=true;
        area.classList.add('breaking-lock');line.textContent='메이스를 단단히 쥐고 들어 올렸다…';
        later(()=>{state.update({arcadeUnlocked:true});line.textContent='쾅! 자물쇠가 부서졌다.';},850);
        later(()=>{area.classList.add('opening-door');line.textContent='문 너머로 네온 불빛이 번진다.';},1400);
        later(arcadeRoom,2450);
        return;
      }
      line.textContent='자물쇠로 잠겨 있어서 들어갈 수가 없다…';
      button('대화 종료',()=>{caption.hidden=true;lock.focus();});
    };
  }
  function arcadeRoom(){
    scene('<section class="arcade-room"><img class="arcade-interior" src="assets/arcade-interior-paper-v27.png" alt="먹선과 수채화로 그린 밝은 오락실. 청록색 창틀과 테라코타 바닥, 중앙의 특별한 오락기 한 대"><header class="arcade-heading"><h2 id="adventure-title">테포 오락실</h2></header><button class="sacred-machine" aria-label="빛나는 오락기 살펴보기"><span>불빛에 다가가기</span></button></section>','room-scene-view');
    dialog.querySelector('.sacred-machine').onclick=()=>{
      const card=document.createElement('section');card.className='game-invitation';card.setAttribute('aria-label','게임 시작 확인');
      card.innerHTML='<p class="chapter-label">테포의 작은 오락실</p><h3>테포 · 파도를 지켜라</h3><p>게임을 하시겠습니까?</p><small>시작을 누르면 게임 파일을 불러와요.</small><div class="adventure-actions"></div>';
      dialog.querySelector('.sacred-machine').disabled=true;dialog.append(card);
      button('예, 게임 시작',()=>{if(busy)return;busy=true;card.remove();dialog.querySelector('.arcade-room').classList.add('entering-machine');later(startGame,650);},card.querySelector('.adventure-actions'));
      button('아니요',()=>{card.remove();dialog.querySelector('.sacred-machine').disabled=false;dialog.querySelector('.sacred-machine').focus();},card.querySelector('.adventure-actions'));
      card.querySelector('button').focus();
    };
  }
  function startGame(){
    scene('<section class="game-player"><header><h2 id="adventure-title">테포 · 파도를 지켜라</h2><div><button class="game-fullscreen">전체화면</button><button class="game-exit">종료하고 오락실로</button></div></header><div class="game-stage"><div class="game-loading" role="status"><span class="game-loader"></span><p>오락기에 불을 켜는 중…</p><progress max="100"></progress><button class="game-retry" hidden>다시 시도</button></div></div></section>','game-scene');
    dialog.querySelector('.adventure-close').hidden=true;
    const stage=dialog.querySelector('.game-stage'),loading=dialog.querySelector('.game-loading');
    const fail=message=>{loading.hidden=false;loading.querySelector('p').textContent=message;loading.querySelector('.game-loader').hidden=true;loading.querySelector('progress').hidden=true;loading.querySelector('.game-retry').hidden=false;};
    frame=document.createElement('iframe');frame.title='테포 · 파도를 지켜라 게임';frame.allow='autoplay; fullscreen; gamepad';frame.allowFullscreen=true;frame.src='games/shorekeeper/index.html?from=arcade&v=15.1';stage.prepend(frame);
    frame.addEventListener('load',()=>frame?.contentWindow.postMessage({type:'tepo-game-status-request'},location.origin));
    frame.addEventListener('error',()=>fail('게임을 불러오지 못했어. 다시 시도해 줘.'));
    gameTimer=setTimeout(()=>fail('로딩이 오래 걸리고 있어. 조금 더 기다리거나 다시 시도해 줘.'),90000);
    dialog.querySelector('.game-retry').onclick=startGame;
    dialog.querySelector('.game-exit').onclick=async()=>{if(document.fullscreenElement)try{await document.exitFullscreen();}catch{}arcadeRoom();};
    dialog.querySelector('.game-fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await dialog.querySelector('.game-player').requestFullscreen();}catch{dialog.querySelector('.game-fullscreen').textContent='브라우저 전체화면을 이용해 줘';}frame?.focus();};
    stage.onclick=()=>frame?.focus();
  }
  addEventListener('message',event=>{
    if(!frame||event.origin!==location.origin||event.source!==frame.contentWindow)return;
    const data=event.data;if(!data||data.type!=='tepo-game')return;
    const loading=dialog.querySelector('.game-loading');if(!loading)return;
    if(data.status==='ready'){clearTimeout(gameTimer);loading.hidden=true;frame.focus();}
    if(data.status==='progress'){loading.querySelector('p').textContent='파도를 불러오는 중… '+(data.percent||0)+'%';loading.querySelector('progress').value=data.percent||0;}
    if(data.status==='error'){clearTimeout(gameTimer);loading.querySelector('p').textContent='게임을 불러오지 못했어. 다시 시도해 줘.';loading.querySelector('.game-loader').hidden=true;loading.querySelector('progress').hidden=true;loading.querySelector('.game-retry').hidden=false;}
    if(data.status==='exit')arcadeRoom();
  });
  dialog.addEventListener('cancel',event=>{if(frame){event.preventDefault();if(document.fullscreenElement)document.exitFullscreen().catch(()=>{});arcadeRoom();}else{event.preventDefault();leaveArcade();}});dialog.addEventListener('close',()=>{cleanup();dialog.replaceChildren();opener?.focus({preventScroll:true});});
  window.TEPO_WORLD={open(place,from){opener=from;arcade();if(!dialog.open)dialog.showModal();dialog.querySelector('button:not([hidden])')?.focus();}};
})();
