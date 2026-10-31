(() => {
  'use strict';
  const places={
    home:{title:'테포의 등대',category:'바닷가의 작은 집',description:'파도 소리가 들리는 등대 안에는 테포가 살고 있어. 테포를 만나 이야기를 나누고, 방 안에 놓인 물건들도 살펴봐.',note:'테포를 만나러 가 볼까?',destination:'house.html',assets:['assets/lighthouse-room-empty-hooks-v18.png']},
    arcade:{title:'오락실',category:'파도 너머 한 판',description:'바닷가에 조용히 자리 잡은 작은 오락실. 문 너머에는 특별한 오락기 한 대가 기다리고 있어.',note:'어떤 게임이 기다리고 있을까?',assets:['assets/arcade-entrance-paper-v27.png','assets/arcade-door-paper-alpha-v27.png','assets/arcade-padlock-alpha-v23.png']},
    popup:{title:'팝업',category:'테포의 작은 상점',description:'테포의 취향이 담긴 작은 팝업 공간이야. 이곳에서 만나게 될 물건과 이야기는 조금씩 채워지고 있어.',note:'팝업 안의 이야기는 준비 중이야.'},
    photo:{title:'포토존',category:'바다를 담는 한 장',description:'카메라나 내 사진 위에 테포와 엘펭이를 놓고, 바닷가의 추억을 한 장 남겨 봐. 포즈와 표정을 고르고 스티커처럼 자유롭게 꾸밀 수 있어.',note:'오늘은 어떤 친구와 사진을 남길까?'},
    mystery:{title:'??',category:'수상한 모래굴',description:'해변 한쪽에 낯선 모래굴이 있어. 안에서는 누군가 지내고 있는 것 같은데… 누가 사는 걸까?',note:'모래굴의 이야기는 아직 열리지 않았어.'}
  };
  const preview=document.createElement('dialog');preview.className='world-place-dialog';preview.setAttribute('aria-labelledby','place-title');document.body.append(preview);
  const travel=document.createElement('dialog');travel.className='world-travel';travel.setAttribute('aria-label','장소로 이동 중');travel.innerHTML='<div class="travel-veil"></div><div class="travel-caption" role="status"><span class="travel-footsteps" aria-hidden="true">· · ·</span><p></p></div>';document.body.append(travel);
  let opener,busy=false,zoom;
  function art(button){const visual=button.querySelector('.place-sprite').cloneNode(true);visual.className='place-preview-art';visual.dataset.place=button.dataset.place;const box=button.getBoundingClientRect();visual.style.aspectRatio=box.width+'/'+box.height;visual.style.setProperty('--place-ratio',box.width/box.height);visual.style.transformOrigin='center';return visual;}
  function open(place,button){
    if(busy||!places[place])return;opener=button;
    preview.className='world-place-dialog';preview.innerHTML='<article class="place-paper"><button class="place-dismiss" aria-label="지도 계속 보기">×</button><div class="place-preview"><span class="place-halo"></span></div><div class="place-information"><p class="place-category"></p><h2 id="place-title"></h2><p class="place-description"></p><p class="place-note"></p><p class="place-error" role="status" hidden></p><button class="place-go">이동하기 <span aria-hidden="true">↗</span></button><button class="place-stay">지도를 더 둘러볼래</button></div></article>';
    const info=places[place];preview.querySelector('.place-preview').append(art(button));
    preview.querySelector('.place-category').textContent=info.category;preview.querySelector('h2').textContent=info.title;preview.querySelector('.place-description').textContent=info.description;preview.querySelector('.place-note').textContent=info.note;
    preview.querySelector('.place-go').onclick=()=>move(place,button);preview.querySelector('.place-dismiss').onclick=()=>{if(!busy)preview.close();};preview.querySelector('.place-stay').onclick=()=>{if(!busy)preview.close();};
    preview.showModal();preview.querySelector('.place-go').focus();
  }
  preview.addEventListener('close',()=>{if(!busy)opener?.focus({preventScroll:true});});
  preview.addEventListener('cancel',event=>{if(busy)event.preventDefault();else if(preview.classList.contains('place-arrival')){event.preventDefault();leavePreview();}});
  preview.addEventListener('click',event=>{if(event.target===preview&&!busy){if(preview.classList.contains('place-arrival'))leavePreview();else preview.close();}});
  function delay(ms){return new Promise(resolve=>setTimeout(resolve,ms));}
  async function move(place,button){
    if(busy)return;busy=true;const info=places[place],go=preview.querySelector('.place-go');go.disabled=true;go.textContent='길을 살펴보는 중…';
    try{
      await Promise.race([Promise.all((info.assets||[]).map(src=>{const image=new Image();image.src=src;return image.decode();})),delay(12000).then(()=>{throw new Error('timeout');})]);
    }catch{busy=false;go.disabled=false;go.textContent='다시 이동하기';const error=preview.querySelector('.place-error');error.hidden=false;error.textContent='장소를 불러오지 못했어. 잠시 후 다시 눌러 줘.';return;}
    window.TEPO_AUDIO?.play('area_enter');preview.close();travel.querySelector('p').textContent=(place==='mystery'?'수상한 모래굴':info.title)+' 쪽으로 걸어가는 중…';travel.showModal();
    const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches,duration=reduced?160:1100;
    const scene=document.querySelector('#map-scene'),viewport=document.querySelector('#map-viewport');
    if(scene&&viewport&&!reduced){const s=scene.getBoundingClientRect(),v=viewport.getBoundingClientRect(),b=button.getBoundingClientRect(),scale=s.width/scene.offsetWidth,x=(b.left+b.width/2-s.left)/scale,y=(b.top+b.height*.65-s.top)/scale;zoom=scene.animate([{transform:scene.style.transform},{transform:`translate(${v.width/2-x*scale*2.8}px,${v.height/2-y*scale*2.8}px) scale(${scale*2.8})`}],{duration,easing:'cubic-bezier(.65,0,.35,1)',fill:'forwards'});}
    travel.classList.add('is-travelling');await delay(duration);
    if(info.destination){try{sessionStorage.setItem('tepo-place-arrival',place);}catch{}location.href=info.destination;return;}
    try{if(place==='arcade'){window.TEPO_WORLD.open(place,button);document.querySelector('.world-adventure').animate([{opacity:0},{opacity:1}],{duration:reduced?1:500});}else if(place==='photo'){await window.TEPO_PHOTO.open(button);}else arrive(place,button);}finally{zoom?.cancel();travel.close();travel.classList.remove('is-travelling');busy=false;}
  }
  function arrive(place,button){
    const info=places[place];preview.className='world-place-dialog place-arrival';preview.innerHTML='<section class="place-lookout"><div class="place-arrival-scenery"></div><div class="place-arrival-art"></div><article class="arrival-paper"><p class="place-category"></p><h2 id="place-title"></h2><p class="place-description"></p><button class="place-go">← 지도로 돌아가기</button></article></section>';
    preview.dataset.arrivalPlace=place;
    const scenery=preview.querySelector('.place-arrival-scenery');scenery.style.backgroundPosition=({popup:'68% 27%',photo:'52% 43%',mystery:'13% 43%'})[place];preview.querySelector('.place-arrival-art').append(art(button));preview.querySelector('.place-category').textContent=info.category;preview.querySelector('h2').textContent=info.title;preview.querySelector('.place-description').textContent=info.note;preview.querySelector('.place-go').onclick=leavePreview;preview.showModal();preview.querySelector('.place-go').focus();
  }
  function leavePreview(){returnToMap(preview.dataset.arrivalPlace,{close:()=>preview.close(),surface:preview.querySelector('.place-lookout')});}
  function mapTransforms(button){
    const scene=document.querySelector('#map-scene'),viewport=document.querySelector('#map-viewport');
    if(!scene||!viewport||!button||!scene.offsetWidth||!scene.getBoundingClientRect().width)return null;
    const s=scene.getBoundingClientRect(),v=viewport.getBoundingClientRect(),b=button.getBoundingClientRect(),scale=s.width/scene.offsetWidth,x=(b.left+b.width/2-s.left)/scale,y=(b.top+b.height*.65-s.top)/scale;
    return {scene,base:scene.style.transform,near:`translate(${v.width/2-x*scale*2.8}px,${v.height/2-y*scale*2.8}px) scale(${scale*2.8})`};
  }
  async function revealMap(place){
    zoom?.cancel();zoom=null;
    const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
    if(!document.querySelector('#map-loading')?.classList.contains('is-ready'))await Promise.race([new Promise(resolve=>addEventListener('tepo-map-ready',resolve,{once:true})),delay(6000)]);
    const target=document.querySelector(`.destination[data-place="${place}"]`),view=mapTransforms(target);
    if(view&&!reduced)zoom=view.scene.animate([{transform:view.near},{transform:view.base}],{duration:1200,easing:'cubic-bezier(.22,.65,.25,1)',fill:'forwards'});
    const fade=travel.animate([{opacity:1},{opacity:0}],{duration:reduced?180:650,fill:'forwards',easing:'ease-out'});
    await Promise.all([fade.finished,zoom?.finished].filter(Boolean));
    zoom?.cancel();zoom=null;travel.close();fade.cancel();travel.classList.remove('is-returning');busy=false;target?.focus({preventScroll:true});
  }
  async function returnToMap(place,{close,href,surface}={}){
    if(busy)return;busy=true;window.TEPO_AUDIO?.play('area_exit');
    const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches,duration=reduced?160:600;
    travel.classList.remove('is-travelling','is-revealing','reveal-ready');travel.classList.add('is-returning');travel.querySelector('p').textContent='밖으로 나와 지도로 돌아가는 중…';travel.showModal();
    const base=surface?getComputedStyle(surface).transform:'none';
    const retreat=surface&&!reduced?surface.animate([{transform:base,filter:'brightness(1)'},{transform:(base==='none'?'':base+' ')+'scale(.94)',filter:'brightness(.75)'}],{duration,easing:'ease-in',fill:'forwards'}):null;
    const curtain=travel.querySelector('.travel-veil').animate([{opacity:0},{opacity:1}],{duration,fill:'forwards'});await curtain.finished;curtain.cancel();
    if(href){try{sessionStorage.setItem('tepo-map-return',place);}catch{}location.href=href;return;}
    close?.();retreat?.cancel();await revealMap(place);
  }
  const back=document.querySelector('.back-link');
  if(back)back.addEventListener('click',event=>{if(event.button!==0||event.metaKey||event.ctrlKey||event.shiftKey||event.altKey)return;event.preventDefault();returnToMap('home',{href:back.href,surface:document.querySelector('#room-scene')});});
  let returning;try{returning=sessionStorage.getItem('tepo-map-return');sessionStorage.removeItem('tepo-map-return');}catch{}
  if(returning&&places[returning]&&document.querySelector('#map-scene')){busy=true;travel.classList.add('is-returning');travel.querySelector('p').textContent='다시, 테포의 부산.';travel.showModal();revealMap(returning);}
  travel.addEventListener('cancel',event=>event.preventDefault());
  // A new document reveals the room only once its main image is ready.
  let arrival;try{arrival=sessionStorage.getItem('tepo-place-arrival');sessionStorage.removeItem('tepo-place-arrival');}catch{}
  if(arrival&&document.querySelector('#room-image')){travel.querySelector('p').textContent='테포의 등대에 도착했어.';travel.classList.add('is-revealing');travel.showModal();Promise.all([...document.querySelectorAll('#room-image')].map(image=>image.decode().catch(()=>{}))).then(()=>{travel.classList.add('reveal-ready');setTimeout(()=>{travel.close();travel.classList.remove('is-revealing','reveal-ready');},650);});}
  addEventListener('pageshow',event=>{if(event.persisted){zoom?.cancel();if(travel.open)travel.close();travel.classList.remove('is-travelling','is-returning');busy=false;}});
  window.TEPO_NAVIGATION={open,returnToMap};
})();
