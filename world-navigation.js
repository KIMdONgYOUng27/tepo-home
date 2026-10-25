(() => {
  'use strict';
  const places={
    home:{title:'테포의 등대',category:'바닷가의 작은 집',description:'파도 소리가 들리는 등대 안에는 테포가 살고 있어. 테포를 만나 이야기를 나누고, 방 안에 놓인 물건들도 살펴봐.',note:'테포를 만나러 가 볼까?',destination:'house.html',assets:['assets/lighthouse-room-empty-hooks-v18.png']},
    arcade:{title:'오락실',category:'파도 너머 한 판',description:'바닷가에 조용히 자리 잡은 작은 오락실. 문 너머에는 특별한 오락기 한 대가 기다리고 있어.',note:'어떤 게임이 기다리고 있을까?',assets:['assets/arcade-entrance-paper-v27.png','assets/arcade-door-paper-alpha-v27.png','assets/arcade-padlock-alpha-v23.png']},
    popup:{title:'팝업',category:'테포의 작은 상점',description:'테포의 취향이 담긴 작은 팝업 공간이야. 이곳에서 만나게 될 물건과 이야기는 조금씩 채워지고 있어.',note:'팝업 안의 이야기는 준비 중이야.'},
    photo:{title:'포토존',category:'바다를 담는 한 장',description:'부산 바다를 배경으로 테포와 추억을 남길 자리야. 친구들과 함께 사진을 찍는 공간을 준비하고 있어.',note:'사진 촬영은 준비 중이야.'},
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
  preview.addEventListener('cancel',event=>{if(busy)event.preventDefault();});
  preview.addEventListener('click',event=>{if(event.target===preview&&!busy)preview.close();});
  function delay(ms){return new Promise(resolve=>setTimeout(resolve,ms));}
  async function move(place,button){
    if(busy)return;busy=true;const info=places[place],go=preview.querySelector('.place-go');go.disabled=true;go.textContent='길을 살펴보는 중…';
    try{
      await Promise.race([Promise.all((info.assets||[]).map(src=>{const image=new Image();image.src=src;return image.decode();})),delay(12000).then(()=>{throw new Error('timeout');})]);
    }catch{busy=false;go.disabled=false;go.textContent='다시 이동하기';const error=preview.querySelector('.place-error');error.hidden=false;error.textContent='장소를 불러오지 못했어. 잠시 후 다시 눌러 줘.';return;}
    preview.close();travel.querySelector('p').textContent=(place==='mystery'?'수상한 모래굴':info.title)+' 쪽으로 걸어가는 중…';travel.showModal();
    const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches,duration=reduced?160:1100;
    const scene=document.querySelector('#map-scene'),viewport=document.querySelector('#map-viewport');
    if(scene&&viewport&&!reduced){const s=scene.getBoundingClientRect(),v=viewport.getBoundingClientRect(),b=button.getBoundingClientRect(),scale=s.width/scene.offsetWidth,x=(b.left+b.width/2-s.left)/scale,y=(b.top+b.height*.65-s.top)/scale;zoom=scene.animate([{transform:scene.style.transform},{transform:`translate(${v.width/2-x*scale*2.8}px,${v.height/2-y*scale*2.8}px) scale(${scale*2.8})`}],{duration,easing:'cubic-bezier(.65,0,.35,1)',fill:'forwards'});}
    travel.classList.add('is-travelling');await delay(duration);
    if(info.destination){try{sessionStorage.setItem('tepo-place-arrival',place);}catch{}location.href=info.destination;return;}
    try{if(place==='arcade'){window.TEPO_WORLD.open(place,button);document.querySelector('.world-adventure').animate([{opacity:0},{opacity:1}],{duration:reduced?1:500});}else arrive(place,button);}finally{zoom?.cancel();travel.close();travel.classList.remove('is-travelling');busy=false;}
  }
  function arrive(place,button){
    const info=places[place];preview.className='world-place-dialog place-arrival';preview.innerHTML='<section class="place-lookout"><div class="place-arrival-scenery"></div><div class="place-arrival-art"></div><article class="arrival-paper"><p class="place-category"></p><h2 id="place-title"></h2><p class="place-description"></p><button class="place-go">← 지도로 돌아가기</button></article></section>';
    const scenery=preview.querySelector('.place-arrival-scenery');scenery.style.backgroundPosition=({popup:'68% 27%',photo:'52% 43%',mystery:'13% 43%'})[place];preview.querySelector('.place-arrival-art').append(art(button));preview.querySelector('.place-category').textContent=info.category;preview.querySelector('h2').textContent=info.title;preview.querySelector('.place-description').textContent=info.note;preview.querySelector('.place-go').onclick=()=>preview.close();preview.showModal();preview.querySelector('.place-go').focus();
  }
  travel.addEventListener('cancel',event=>event.preventDefault());
  // A new document reveals the room only once its main image is ready.
  let arrival;try{arrival=sessionStorage.getItem('tepo-place-arrival');sessionStorage.removeItem('tepo-place-arrival');}catch{}
  if(arrival&&document.querySelector('#room-image')){travel.querySelector('p').textContent='테포의 등대에 도착했어.';travel.classList.add('is-revealing');travel.showModal();Promise.all([...document.querySelectorAll('#room-image')].map(image=>image.decode().catch(()=>{}))).then(()=>{travel.classList.add('reveal-ready');setTimeout(()=>{travel.close();travel.classList.remove('is-revealing','reveal-ready');},650);});}
  addEventListener('pageshow',event=>{if(event.persisted){zoom?.cancel();if(travel.open)travel.close();travel.classList.remove('is-travelling');busy=false;}});
  window.TEPO_NAVIGATION={open};
})();
