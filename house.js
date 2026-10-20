(() => {
  const art='assets/lighthouse-room-stable-v8.png';
  const scene=document.querySelector('#room-scene'),image=document.querySelector('#room-image');
  const config=window.TEPO_HOUSE_CONTENT||{stories:[],videos:{shorts:[],long:[]}};
  // Remove the old comparison URL; this room now has one approved art direction.
  if(location.search)history.replaceState(null,'',location.pathname);
  function layout(){const s=Math.min(innerWidth/1672,innerHeight/941);scene.style.transform=`translate(${(innerWidth-1672*s)/2}px,${(innerHeight-941*s)/2}px) scale(${s})`;}
  addEventListener('resize',layout);layout();image.decode().then(()=>scene.classList.add('ready')).catch(()=>scene.classList.add('ready'));
  const objects=[
    {id:'drawer',label:'벤치 아래 왼쪽 서랍 손잡이',box:[648,579,38,24],path:'M3 19 C5 7 10 3 19 3 C28 3 34 9 35 18 C28 21 10 22 3 19 Z'},
    {id:'baton',label:'삼단봉',box:[1012,173,17,202],points:'2,0 14,0 14,62 10,64 10,187 15,191 14,199 7,202 0,198 0,191 5,187 5,64 1,62'},
    {id:'bat',label:'야구방망이',box:[1083,153,30,223],points:'7,0 24,0 26,9 20,14 20,65 29,186 29,211 25,220 7,223 1,216 0,199 10,67 10,14 4,10'},
    {id:'unknown',label:'정체불명의 무기',box:[1149,178,73,185],points:'29,0 42,0 43,110 62,121 71,145 68,164 54,179 36,184 49,165 50,145 38,132 20,130 9,145 6,160 0,146 4,126 25,110 30,102'},
    {id:'mace',label:'메이스',box:[1242,178,75,185],points:'28,0 44,0 44,99 49,105 44,116 58,118 64,126 74,132 65,143 74,154 61,160 64,174 48,173 38,185 28,173 14,175 13,161 0,154 8,143 0,132 16,122 25,116 24,103 29,99'}
  ];
  const ns='http://www.w3.org/2000/svg';
  objects.forEach(item=>{
    const [x,y,w,h]=item.box,button=document.createElement('button');button.className='object';button.dataset.object=item.id;button.setAttribute('aria-label',item.label);Object.assign(button.style,{left:x+'px',top:y+'px',width:w+'px',height:h+'px'});
    const svg=document.createElementNS(ns,'svg');svg.setAttribute('viewBox',`0 0 ${w} ${h}`);svg.setAttribute('aria-hidden','true');
    // The drawer uses only the brass pull's curved edge, with no copied background.
    if(item.path){
      svg.innerHTML=`<path class="object-outline" d="${item.path}"/><path class="object-hit" d="${item.path}"/>`;
    }else{
      svg.innerHTML=`<defs><clipPath id="clip-${item.id}"><polygon points="${item.points}"/></clipPath></defs><image class="object-art" href="${art}" x="${-x}" y="${-y}" width="1672" height="941" clip-path="url(#clip-${item.id})"/><polygon class="object-outline" points="${item.points}"/><polygon class="object-hit" points="${item.points}"/>`;
    }
    button.append(svg);document.querySelector('#room-objects').append(button);
    const weapon=['baton','bat','unknown','mace'].includes(item.id);
    if(item.id==='drawer')button.classList.add('drawer');
    if(weapon){button.classList.add('weapon');button.setAttribute('aria-label',item.label+' · 무기 모음 보기');}
    button.addEventListener('click',()=>openObject(weapon?'weapons':item.id));
    if(weapon){['pointerenter','focus'].forEach(type=>button.addEventListener(type,()=>scene.classList.add('weapons-active')));['pointerleave','blur'].forEach(type=>button.addEventListener(type,()=>scene.classList.remove('weapons-active')));}
  });
  const cutouts=[
    {id:'computer',label:'컴퓨터',src:'assets/room-computer-alpha-v2.png',box:[183,339,280,165]},
    {id:'diary',label:'일기장',src:'assets/room-diary-alpha-v1.png',box:[1165,642,229,102]},
    {id:'hat',label:'테포의 뚝배기 모자',src:'assets/tepo-pot-hat-v1.png',box:[1045,454,117,49]},
    {id:'wallet',label:'바닥에 놓인 테포의 지갑',src:'assets/room-wallet-alpha-v1.png',box:[605,780,140,66]},
    {id:'photo',label:'테트라포드 액자',src:'assets/room-frame-alpha-v1.png',box:[537,78,248,313]}
  ];
  // The raster alpha itself defines both the visible edge and hit target.
  // No background pixels or hand-drawn approximation polygons are used here.
  async function mountCutout(item){
    const source=new Image();source.src=item.src;await source.decode();
    const canvas=document.createElement('canvas');canvas.width=source.naturalWidth;canvas.height=source.naturalHeight;
    const ctx=canvas.getContext('2d',{willReadFrequently:true});ctx.drawImage(source,0,0);const pixels=ctx.getImageData(0,0,canvas.width,canvas.height).data;
    let minX=canvas.width,minY=canvas.height,maxX=0,maxY=0;const runs=[];
    for(let y=0;y<canvas.height;y++){
      let start=-1;
      for(let x=0;x<=canvas.width;x++){
        const solid=x<canvas.width&&pixels[(y*canvas.width+x)*4+3]>48;
        if(solid&&start<0)start=x;
        if(!solid&&start>=0){runs.push(`M${start} ${y}h${x-start}v1h${start-x}Z`);minX=Math.min(minX,start);maxX=Math.max(maxX,x);minY=Math.min(minY,y);maxY=y+1;start=-1;}
      }
    }
    if(minX>=maxX)throw new Error('Empty object alpha: '+item.id);
    const [x,y,w,h]=item.box,button=document.createElement('button');button.className='object alpha-object';button.dataset.object=item.id;button.setAttribute('aria-label',item.label);Object.assign(button.style,{left:x+'px',top:y+'px',width:w+'px',height:h+'px'});
    const svg=document.createElementNS(ns,'svg');svg.setAttribute('viewBox',`${minX} ${minY} ${maxX-minX} ${maxY-minY}`);svg.setAttribute('preserveAspectRatio','none');svg.setAttribute('aria-hidden','true');
    const edgeRadius=1.8*(maxX-minX)/w;
    const defs=document.createElementNS(ns,'defs');
    defs.innerHTML=`<filter id="edge-${item.id}" x="-10%" y="-10%" width="120%" height="120%" color-interpolation-filters="sRGB"><feMorphology in="SourceAlpha" operator="dilate" radius="${edgeRadius}" result="expanded"/><feComposite in="expanded" in2="SourceAlpha" operator="out" result="edge"/><feFlood flood-color="#ffdb68" flood-opacity=".95" result="yellow"/><feComposite in="yellow" in2="edge" operator="in" result="outline"/><feMerge><feMergeNode in="outline"/><feMergeNode in="SourceGraphic"/></feMerge></filter>`;
    svg.append(defs);button.style.setProperty('--alpha-edge',`url(#edge-${item.id})`);
    const picture=document.createElementNS(ns,'image');picture.setAttribute('href',item.src);picture.setAttribute('width',canvas.width);picture.setAttribute('height',canvas.height);picture.classList.add('alpha-art');
    const path=document.createElementNS(ns,'path');path.setAttribute('d',runs.join(''));path.classList.add('object-hit');svg.append(picture,path);button.append(svg);document.querySelector('#room-objects').append(button);button.addEventListener('click',()=>openObject(item.id));
  }
  Promise.all(cutouts.map(mountCutout)).catch(error=>console.error('Object loading failed',error));
  const tepo=document.querySelector('#tepo'),status=document.querySelector('#wake-status'),story=window.TEPO_STORY;let clicks=[],stirTimer,chainTimer;
  function showAwake(){tepo.classList.add('awake');tepo.setAttribute('aria-pressed','true');tepo.setAttribute('aria-label','깨어난 테포에게 말 걸기');}
  if(story.awake)showAwake();
  function stopStir(){clearTimeout(stirTimer);tepo.classList.remove('is-stirring','is-restless');}
  tepo.addEventListener('click',()=>{
    if(tepo.classList.contains('awake')){story.talk();return;}const now=performance.now();if(clicks.length&&now-clicks.at(-1)>650)clicks=[];clicks=clicks.filter(t=>now-t<=2000);clicks.push(now);
    clearTimeout(chainTimer);
    if(clicks.length>=4){stopStir();showAwake();story.wake();status.textContent='테포가 잠에서 깼어요.';clicks=[];story.talk();return;}
    if(clicks.length===1)stopStir();
    if(clicks.length===2||clicks.length===3){
      clearTimeout(stirTimer);tepo.classList.add('is-stirring');tepo.classList.toggle('is-restless',clicks.length===3);
      status.textContent=clicks.length===2?'테포가 잠결에 움찔했지만 아직 자고 있어요.':'테포가 뒤척이며 깰 듯 말 듯해요.';
      stirTimer=setTimeout(stopStir,1100);
    }
    chainTimer=setTimeout(()=>{clicks=[];},650);
  });
  const dialog=document.querySelector('#object-dialog'),content=document.querySelector('#dialog-content');
  const closeButton='<button class="close-view" aria-label="방으로 돌아가기">← 방으로</button>';
  const safeUrl=value=>{try{const url=new URL(value,location.href);return ['http:','https:'].includes(url.protocol)?url.href:null;}catch{return null;}};
  function close(){dialog.close();content.replaceChildren();}
  function openObject(id){
    dialog.className='view-'+id;content.replaceChildren();
    if(id==='bag')story.renderBag(content);else if(id==='drawer')story.renderDrawer(content);else if(id==='computer')renderComputer();else if(id==='diary')renderDiary();else if(id==='wallet')window.renderTepoWallet(content);else if(id==='photo'){
      content.innerHTML=closeButton+'<section class="inspect"><h2 id="dialog-title">테트라포드</h2><img class="inspect-frame" src="assets/room-frame-alpha-v1.png" alt="장엄한 테트라포드가 담긴 액자"></section>';
    }else if(id==='hat'){
      content.innerHTML=closeButton+'<section class="inspect"><h2 id="dialog-title">테포의 뚝배기</h2><img class="inspect-cutout" src="assets/tepo-pot-hat-v1.png" alt="벗어 놓은 테포의 뚝배기 모자"></section>';
    }else{
      const item=id==='weapons'?{label:'테포의 무기 모음',box:[995,145,335,240]}:objects.find(o=>o.id===id);content.innerHTML=closeButton+'<section class="inspect"><h2 id="dialog-title"></h2><div class="inspect-art"></div></section>';content.querySelector('h2').textContent=item.label;
      const [x,y,w,h]=item.box,picture=content.querySelector('.inspect-art');picture.style.aspectRatio=`${w}/${h}`;picture.style.backgroundImage=`url(${art})`;picture.style.backgroundSize=`${1672/w*100}% ${941/h*100}%`;picture.style.backgroundPosition=`${x/(1672-w)*100}% ${y/(941-h)*100}%`;
    }
    content.querySelector('.close-view').addEventListener('click',close);dialog.showModal();
  }
  const bagButton=document.createElement('button');
  bagButton.className='bag-toggle';bagButton.setAttribute('aria-label','가방 열기');
  bagButton.innerHTML='<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M11 10V7a5 5 0 0 1 10 0v3M7 10h18l3 19H4L7 10Z M10 19h12v7H10Z"/></svg><span>가방</span>';
  bagButton.addEventListener('click',()=>openObject('bag'));document.querySelector('.room-viewport').append(bagButton);
  function renderComputer(){
    content.innerHTML=`<section class="monitor"><div class="monitor-shell"><div class="screen-rim"><div class="crt-screen"><header class="os-bar"><h2 id="dialog-title">TEPO OS</h2><span>등대 컴퓨터</span></header><div class="computer-desktop"><div class="desktop-folders"><button data-open-archive aria-label="직박구리 폴더 열기"><span class="folder-symbol" aria-hidden="true"></span>직박구리</button></div><section class="archive-window" aria-label="직박구리 폴더" hidden><header class="archive-header"><h3>직박구리</h3><button class="archive-close" aria-label="직박구리 폴더 닫기">×</button></header><div class="desktop-folders archive-folders"><button data-folder="shorts"><span class="folder-symbol" aria-hidden="true"></span>쇼츠</button><button data-folder="long"><span class="folder-symbol" aria-hidden="true"></span>롱폼</button></div><footer class="archive-footer">폴더 2개</footer></section><section class="video-window" hidden><header><h3></h3><button class="window-close" aria-label="영상 폴더 닫기">×</button></header><div class="video-list"></div></section></div><footer class="os-footer"><span>TEPO / HOME</span><span class="cursor" aria-hidden="true">▊</span></footer></div></div><div class="monitor-chin"><span class="monitor-brand">TEPO PERSONAL COMPUTER</span><span class="power-light"></span><button class="close-view power-button" aria-label="방으로 돌아가기">⏻</button></div></div></section>`;
    const win=content.querySelector('.video-window');
    const archive=content.querySelector('.archive-window');
    content.querySelector('[data-open-archive]').addEventListener('click',()=>{archive.hidden=false;archive.querySelector('[data-folder="shorts"]').focus();});
    content.querySelector('.archive-close').addEventListener('click',()=>{win.querySelector('.video-list').replaceChildren();win.hidden=true;archive.hidden=true;content.querySelector('[data-open-archive]').focus();});
    function youtubeId(value){
      try{const url=new URL(value);let id=null;if(url.hostname==='youtu.be')id=url.pathname.slice(1);else if(['youtube.com','www.youtube.com','m.youtube.com'].includes(url.hostname))id=url.pathname.startsWith('/shorts/')?url.pathname.split('/')[2]:url.searchParams.get('v');return /^[A-Za-z0-9_-]{11}$/.test(id||'')?id:null;}catch{return null;}
    }
    content.querySelectorAll('[data-folder]').forEach(button=>button.addEventListener('click',()=>{win.hidden=false;win.querySelector('h3').textContent=button.dataset.folder==='shorts'?'쇼츠':'롱폼';const list=win.querySelector('.video-list');list.replaceChildren();const videos=config.videos[button.dataset.folder]||[];
      win.classList.toggle('is-playing',videos.length>0);
      if(!videos.length){const p=document.createElement('p');p.className='empty-videos';p.textContent='아직 담아 둔 영상이 없어요.';list.append(p);return;}
      const files=document.createElement('nav');files.className='video-files';files.setAttribute('aria-label','영상 목록');const stage=document.createElement('div');stage.className='youtube-stage';stage.classList.toggle('is-shorts',button.dataset.folder==='shorts');const original=document.createElement('a');original.className='youtube-original';original.target='_blank';original.rel='noopener noreferrer';original.textContent='YouTube에서 보기 ↗';list.append(files,stage,original);
      function play(video,file,autoplay){const id=youtubeId(video.url);if(!id)return;stage.replaceChildren();const frame=document.createElement('iframe');frame.className='youtube-embed';frame.title=video.title;frame.allow='autoplay; encrypted-media; picture-in-picture; fullscreen';frame.allowFullscreen=true;frame.referrerPolicy='strict-origin-when-cross-origin';const embed=new URL('https://www.youtube.com/embed/'+id);embed.searchParams.set('playsinline','1');embed.searchParams.set('rel','0');embed.searchParams.set('autoplay',autoplay?'1':'0');embed.searchParams.set('origin',location.origin);frame.src=embed.href;stage.append(frame);original.href=safeUrl(video.url);files.querySelectorAll('button').forEach(item=>item.setAttribute('aria-pressed',String(item===file)));}
      videos.forEach((video,index)=>{if(!youtubeId(video.url))return;const file=document.createElement('button');file.textContent='▷ '+video.title;file.addEventListener('click',()=>play(video,file,true));files.append(file);if(index===0)play(video,file,false);});
    }));content.querySelector('.window-close').addEventListener('click',()=>{win.querySelector('.video-list').replaceChildren();win.hidden=true;});
  }
  function renderDiary(){
    content.innerHTML=closeButton+`<section class="diary-cover"><div class="open-book"><aside class="book-page contents-page"><p class="book-kicker">TEPO'S DIARY</p><h2 id="dialog-title">테포의<br>일기장</h2><div class="diary-rule"></div><nav class="story-list" aria-label="일기 목록"></nav><p class="book-note">바닷가에서 보낸<br>작고 시끄러운 하루들.</p><span class="page-number">기록</span></aside><section class="book-page reader-page"><header class="reader-heading"><h3></h3><a class="sns-link" hidden target="_blank" rel="noopener noreferrer">SNS 원본 ↗</a></header><div class="comic-frame" tabindex="0" aria-label="웹툰 읽기"></div><footer class="reader-footer"><button class="previous-page" aria-label="이전 장">←</button><span class="comic-count"></span><button class="next-page" aria-label="다음 장">→</button></footer></section></div></section>`;
    const stories=config.stories||[],list=content.querySelector('.story-list'),frame=content.querySelector('.comic-frame');let storyIndex=0,pageIndex=0;
    function show(){const story=stories[storyIndex];if(!story){frame.textContent='아직 쓰지 않은 첫 페이지.';return;}content.querySelector('.reader-heading h3').textContent=story.title;const url=safeUrl(story.sourceUrl||'');const link=content.querySelector('.sns-link');link.hidden=!story.sourceUrl||!url;if(!link.hidden)link.href=url;frame.replaceChildren();const src=story.pages[pageIndex];if(src&&safeUrl(src)){const img=document.createElement('img');img.src=src;img.alt=`${story.title} ${pageIndex+1}장`;frame.append(img);}frame.scrollTop=0;content.querySelector('.comic-count').textContent=`${pageIndex+1} / ${story.pages.length}`;content.querySelector('.previous-page').disabled=pageIndex===0;content.querySelector('.next-page').disabled=pageIndex>=story.pages.length-1;list.querySelectorAll('button').forEach((b,i)=>b.setAttribute('aria-current',String(i===storyIndex)));}
    stories.forEach((story,i)=>{const b=document.createElement('button');b.textContent=`${String(i+1).padStart(2,'0')}  ${story.title}`;b.addEventListener('click',()=>{storyIndex=i;pageIndex=0;show();});list.append(b);});
    content.querySelector('.previous-page').addEventListener('click',()=>{if(pageIndex>0){pageIndex--;show();}});content.querySelector('.next-page').addEventListener('click',()=>{if(stories[storyIndex]&&pageIndex<stories[storyIndex].pages.length-1){pageIndex++;show();}});show();
  }
  dialog.addEventListener('close',()=>content.replaceChildren());
})();
