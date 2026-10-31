(() => {
  'use strict';
  const policy=window.TEPO_PHOTO_POLICY,world=window.TEPO_WORLD_STATE;
  const zone=document.createElement('dialog');
  zone.id='tepo-photo-zone';zone.className='photo-zone';zone.setAttribute('aria-labelledby','photo-title');
  document.body.append(zone);
  const sheet=document.createElement('dialog');sheet.className='photo-sheet';sheet.dataset.photoSheet='';
  sheet.setAttribute('aria-labelledby','photo-sheet-title');document.body.append(sheet);
  const pictures=new Map(),backgrounds=new Map(),reduceMotion=matchMedia('(prefers-reduced-motion: reduce)');
  let backdrop='day',backdropToken=0;
  const mobileLayout=matchMedia('(max-width:760px), (max-height:500px) and (max-width:1000px)');
  const backgroundFiles={day:'assets/photo/gwangalli-day-v42.png',night:'assets/photo/gwangalli-night-v42.png'};
  async function loadBackground(key){if(backgrounds.has(key))return backgrounds.get(key);const img=new Image();img.src=backgroundFiles[key];await img.decode();backgrounds.set(key,img);return img;}
  let catalog=[],opening=null,from=null,canvas,ctx,video,stream=null,source='postcard',upload=null,frame='sea';
  let items=[],selected=null,serial=0,raf=0,counting=false,countToken=0,cameraToken=0,uploadToken=0,filter='all',drag=null,sceneToken=0;
  const W=1200,H=900,box={x:26,y:26,w:1148,h:784};
  const controls=()=>zone.querySelector('.photo-controls');
  const access=()=>policy.access(world.read());
  const status=text=>{const line=zone.querySelector('.photo-status');if(line)line.textContent=text;};
  function sound(name='ui_click'){window.TEPO_AUDIO?.play(name);}
  function picker(show,focus=true) {
    const album=zone.querySelector('.photo-album');if(!album)return;
    const active=show&&mobileLayout.matches;zone.classList.toggle('photo-picker-open',active);
    zone.querySelectorAll('.photo-header,.photo-workbench').forEach(el=>el.inert=active);
    zone.querySelectorAll('.photo-sticker-open').forEach(b=>b.setAttribute('aria-expanded',String(active)));
    if(active){album.setAttribute('role','dialog');album.setAttribute('aria-modal','true');album.querySelector('.photo-picker-close').focus();}
    else{album.removeAttribute('role');album.removeAttribute('aria-modal');if(focus&&zone.open)zone.querySelector('.photo-sticker-open').focus({preventScroll:true});}
  }
  mobileLayout.addEventListener('change',()=>{if(!mobileLayout.matches)picker(false,false);});
  async function picture(src,animation) {
    if(pictures.has(src))return pictures.get(src);
    const promise=(async()=>{
      if(animation){
        const atlas=new Image(),mask=new Image();atlas.src=animation.atlas;mask.src=animation.mask;await Promise.all([atlas.decode(),mask.decode()]);
        const c=document.createElement('canvas');c.width=animation.width;c.height=animation.height;const mc=c.getContext('2d',{willReadFrequently:true});mc.drawImage(mask,0,0,c.width,c.height);
        return {img:atlas,crop:[0,0,c.width,c.height],alpha:mc.getImageData(0,0,c.width,c.height).data,aw:c.width,ah:c.height,limit:1,animation};
      }
      const img=new Image();img.src=src;await img.decode();
      // Alpha bounds are measured once; no white rectangle or baked background is duplicated.
      const c=document.createElement('canvas'),limit=Math.min(1,512/Math.max(img.width,img.height));
      c.width=Math.ceil(img.width*limit);c.height=Math.ceil(img.height*limit);
      const context=c.getContext('2d',{willReadFrequently:true});context.drawImage(img,0,0,c.width,c.height);
      const data=context.getImageData(0,0,c.width,c.height).data;
      let x0=c.width,y0=c.height,x1=0,y1=0;
      for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++)if(data[(y*c.width+x)*4+3]>24){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
      if(x0>x1)throw Error('empty sticker');
      return {img,crop:[x0/limit,y0/limit,(x1-x0+1)/limit,(y1-y0+1)/limit],alpha:data,aw:c.width,ah:c.height,limit};
    })();pictures.set(src,promise);
    try{return await promise;}catch(e){pictures.delete(src);throw e;}
  }
  function showSheet(title,text,buttons,onDismiss) {
    if(sheet.open)sheet.close();sheet.innerHTML='<article><p class="photo-eyebrow">작은 바닷가 사진관</p><h2 id="photo-sheet-title"></h2><p class="photo-sheet-copy"></p><div class="photo-sheet-actions"></div></article>';
    sheet.querySelector('h2').textContent=title;sheet.querySelector('.photo-sheet-copy').textContent=text;
    buttons.forEach(({label,action,primary})=>{const b=document.createElement('button');b.textContent=label;b.className=primary?'primary':'';b.dataset.sound='ui_click';b.onclick=()=>{sheet.close();action?.();};sheet.querySelector('.photo-sheet-actions').append(b);});
    sheet.oncancel=()=>{onDismiss?.();};sheet.showModal();sheet.querySelector('button').focus();
  }
  function invite() {
    if(counting)return;
    showSheet('친구들을 부를까?','스토리를 진행하지 않고 친구들을 부르실 건가요? 포토존에서 테포와 엘펭이의 모든 스티커를 사용할 수 있어요. 다른 지역의 이야기는 그대로 이어져요.',[
      {label:'아니요',action:()=>zone.querySelector('.photo-invite').focus()},
      {label:'예, 친구들 부르기',primary:true,action:()=>{world.update({photoFriendsInvited:true});refresh();status('테포와 엘펭이가 도착했어! 같이 사진을 남겨 보자.');seed();}}
    ]);
  }
  function dimensions(item){const width=W*item.scale;return {width,height:width*item.asset.crop[3]/item.asset.crop[2]};}
  function localImage(item){return {x:item.x*W,y:item.y*H,angle:item.angle,flip:item.flip};}
  function drawSticker(item,clock) {
    const {width,height}=dimensions(item),p=localImage(item);
    ctx.save();ctx.translate(p.x,p.y);ctx.rotate(item.angle*Math.PI/180);ctx.scale(item.flip?-1:1,1);
    const anim=item.asset.animation;
    const crop=anim?(()=>{const index=policy.animationFrame(anim.durations,clock-item.startedAt,reduceMotion.matches);return [(index%anim.columns)*anim.width,Math.floor(index/anim.columns)*anim.height,anim.width,anim.height];})():item.asset.crop;
    ctx.drawImage(item.asset.img,...crop,-width/2,-height/2,width,height);ctx.restore();
  }
  function postcard() {
    const img=backgrounds.get(backdrop);
    if(img)ctx.drawImage(img,...policy.cover(img.width,img.height,box.x,box.y,box.w,box.h));
    else{ctx.fillStyle='#dbe4df';ctx.fillRect(box.x,box.y,box.w,box.h);}
  }
  function render(selection=true,clock=performance.now()) {
    if(!ctx)return;
    const colors={sea:['#f9f0d9','#346965'],rose:['#f7e7df','#975c53'],ink:['#e8eadf','#344e55']},[paper,ink]=colors[frame];
    ctx.fillStyle=paper;ctx.fillRect(0,0,W,H);ctx.save();ctx.beginPath();ctx.rect(box.x,box.y,box.w,box.h);ctx.clip();
    const image=source==='camera'&&video?.readyState>=2?video:source==='upload'?upload:null;
    if(image){const sw=image.videoWidth||image.naturalWidth,sh=image.videoHeight||image.naturalHeight;
      if(source==='camera'){ctx.translate(W,0);ctx.scale(-1,1);}
      ctx.drawImage(image,...policy.cover(sw,sh,box.x,box.y,box.w,box.h));
      if(source==='camera'){ctx.scale(-1,1);ctx.translate(-W,0);}
    }else postcard();
    items.forEach(item=>drawSticker(item,clock));ctx.restore();
    ctx.strokeStyle=ink;ctx.lineWidth=2;ctx.strokeRect(16,16,W-32,H-32);
    ctx.fillStyle=ink;ctx.textAlign='left';ctx.font='24px "Malgun Gothic",sans-serif' ;ctx.fillText('A little moment in BUSAN',38,859);
    ctx.textAlign='right';ctx.font='23px "Malgun Gothic",sans-serif';ctx.fillText('테포의 부산  ·  우리, 여기서',W-38,859);
    if(selection){const item=items.find(i=>i.id===selected);if(item){const {width,height}=dimensions(item);ctx.save();ctx.translate(item.x*W,item.y*H);ctx.rotate(item.angle*Math.PI/180);ctx.strokeStyle='#d3a049';ctx.lineWidth=3;ctx.setLineDash([10,7]);ctx.strokeRect(-width/2-8,-height/2-8,width+16,height+16);ctx.restore();}}
  }
  function loop(){if(!zone.open)return;render();raf=requestAnimationFrame(loop);}
  function updateControls() {
    const item=items.find(i=>i.id===selected),host=controls();if(!host)return;
    host.querySelectorAll('input,button').forEach(el=>el.disabled=!item||counting);
    host.querySelector('.photo-selected-name').textContent=item?item.name:'스티커를 고르면 여기서 조절할 수 있어';
    if(item){host.querySelector('[data-adjust=size]').value=Math.round(item.scale*100);host.querySelector('[data-adjust=angle]').value=item.angle;}
    zone.querySelector('.photo-capture').disabled=!access().any||counting||!items.length;
    zone.querySelectorAll('[data-photo-source],.photo-reset').forEach(b=>b.disabled=counting||!access().any&&b.hasAttribute('data-photo-source'));
    zone.querySelector('.photo-invite').disabled=counting||access().invited;
    zone.querySelector('.photo-sticker-open').disabled=counting;
  }
  async function add(def,position) {
    if(counting||!access()[def.friend])return;
    if(items.length>=8){status('스티커는 한 장에 8개까지 놓을 수 있어. 하나를 지우고 다시 골라 줘.');return;}
    try{const scene=sceneToken,asset=await picture(def.src,def.animation);if(scene!==sceneToken||!zone.open||counting||!access()[def.friend]||items.length>=8)return;
      const i={id:++serial,name:def.name,friend:def.friend,asset,startedAt:performance.now(),x:position?.x??(def.friend==='elpeng'?.78:.22),y:position?.y??.66,scale:.24,angle:0,flip:false};items.push(i);selected=i.id;updateControls();status(def.name+' 스티커를 놓았어. 드래그해서 위치를 바꿔 봐.');if(zone.classList.contains('photo-picker-open')){picker(false,false);canvas.scrollIntoView({block:'center',behavior:reduceMotion.matches?'auto':'smooth'});canvas.focus({preventScroll:true});}
    }catch{status('스티커 그림을 불러오지 못했어. 잠시 후 다시 골라 줘.');}
  }
  function seed(){if(items.length)return;const a=access();if(a.tepo)add(catalog.find(i=>i.id==='tepo-gif-disco')||catalog.find(i=>i.id==='tepo-wave'),{x:.22,y:.67});if(a.elpeng)add(catalog.find(i=>i.id==='elpeng-wave'),{x:.78,y:.67});}
  function refresh() {
    const a=access(),grid=zone.querySelector('.photo-stickers');if(!grid)return;
    zone.querySelector('.photo-invite').textContent=a.invited?'친구들 모두 도착!':'친구들 부르기';zone.querySelector('.photo-invite').disabled=a.invited||counting;
    zone.querySelector('.photo-availability').textContent=a.invited?'테포 & 엘펭이와 함께':a.tepo?'테포와 함께 · 엘펭이는 아직 기다리는 중':a.elpeng?'엘펭이와 함께':'아직 만나지 못한 친구들';
    grid.replaceChildren();
    catalog.filter(def=>filter==='all'||filter==='tiny'&&def.style==='tiny'||filter==='tepo'&&def.friend==='tepo'&&def.style==='2d'||filter==='elpeng'&&def.friend==='elpeng'||filter==='gif'&&def.style==='gif'||filter==='real'&&def.style==='real').forEach(def=>{
      const b=document.createElement('button');b.className='photo-sticker';b.disabled=!a[def.friend]||counting;b.dataset.sound='ui_click';
      const img=document.createElement('img');img.src=def.animation&&reduceMotion.matches?def.animation.poster:def.src;img.alt='';img.draggable=false;img.loading='lazy';
      const title=document.createElement('span');title.textContent=def.name+(def.animation?' · GIF':def.style==='real'?' · 실사':'');const lock=document.createElement('small');
      lock.textContent=a[def.friend]?'＋ 사진에 놓기':def.friend==='elpeng'?'잠김 · 엘펭이 구해오기':'잠김 · 테포 만나기';
      b.setAttribute('aria-label',def.name+' · '+lock.textContent);b.append(img,title,lock);b.onclick=()=>add(def);grid.append(b);
    });
    updateControls();zone.querySelector('.photo-invite').disabled=a.invited||counting;
  }
  function stopCamera() {cameraToken++;stream?.getTracks().forEach(track=>track.stop());stream=null;if(video)video.srcObject=null;}
  function setSource(value){source=value;zone.querySelectorAll('[data-photo-source]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.photoSource===value)));}
  async function camera() {
    if(counting||!access().any)return;
    if(!navigator.mediaDevices?.getUserMedia){status('카메라를 사용할 수 없는 환경이야. 사진 올리기로 촬영할 수 있어.');return;}
    stopCamera();const token=cameraToken;status('카메라 사용 허용을 기다리는 중…');
    try{const next=await navigator.mediaDevices.getUserMedia({video:{width:{ideal:1600},height:{ideal:1200},facingMode:'user'},audio:false});
      if(!zone.open||token!==cameraToken){next.getTracks().forEach(t=>t.stop());return;}
      stream=next;video.srcObject=next;await video.play();if(!zone.open||token!==cameraToken){next.getTracks().forEach(t=>t.stop());return;}
      setSource('camera');status('카메라가 켜졌어. 보이는 모습 그대로 사진으로 남겨 줄게.');
      next.getVideoTracks()[0]?.addEventListener('ended',()=>{if(stream===next){stopCamera();setSource('postcard');status('카메라 연결이 끝났어. 다시 켜거나 사진을 올려 줘.');}});
    }catch(e){if(token!==cameraToken)return;stopCamera();setSource('postcard');status(e.name==='NotAllowedError'?'카메라 권한이 허용되지 않았어. 사진 올리기를 이용해도 좋아.':'카메라를 켜지 못했어. 다른 앱에서 사용 중인지 확인하거나 사진을 올려 줘.');}
  }
  async function loadUpload(file) {
    if(!file||counting||!access().any)return;
    if(!['image/jpeg','image/png','image/webp'].includes(file.type)){status('JPG, PNG, WebP 사진을 골라 줘.');return;}
    if(file.size>20*1024*1024){status('사진은 20MB 이하로 골라 줘.');return;}
    const token=++uploadToken,url=URL.createObjectURL(file),image=new Image();
    try{image.src=url;await image.decode();if(image.width*image.height>40000000)throw Error('large');
      if(token!==uploadToken||!zone.open)return;stopCamera();upload=image;setSource('upload');status('사진을 올렸어. 친구들을 원하는 곳에 놓아 봐.');
    }catch{status('사진을 읽지 못했어. 4천만 화소 이하의 다른 사진을 골라 줘.');}finally{URL.revokeObjectURL(url);}
  }
  async function capture() {
    if(counting||!access().any||!items.length)return;
    counting=true;const token=++countToken;refresh();const counter=zone.querySelector('.photo-countdown');
    for(let n=3;n>0;n--){if(token!==countToken||!zone.open)return;counter.textContent=String(n);counter.hidden=false;sound();await new Promise(r=>setTimeout(r,850));}
    if(token!==countToken||!zone.open)return;counter.hidden=true;
    render(false);const still=document.createElement('canvas');still.width=W;still.height=H;still.getContext('2d').drawImage(canvas,0,0);
    const blob=await new Promise(resolve=>still.toBlob(resolve,'image/png'));counting=false;refresh();
    if(!zone.open||token!==countToken)return;if(!blob){status('사진 저장본을 만들지 못했어. 다시 찍어 줘.');return;}
    const url=URL.createObjectURL(blob);showSheet('우리의 한 장','이 순간은 브라우저 안에서만 만들어졌어. 마음에 들면 사진을 저장해 줘.',[
      {label:'다시 꾸미기'},
      {label:'사진 저장하기',primary:true,action:()=>{const a=document.createElement('a');a.href=url;a.download='테포의-부산-'+new Date().toISOString().slice(0,10)+'.png';a.click();setTimeout(()=>URL.revokeObjectURL(url),30000);}}
    ]);
    const preview=document.createElement('img');preview.className='photo-result';preview.src=url;preview.alt='사진과 선택한 친구 스티커를 합친 최종 사진';sheet.querySelector('article').insertBefore(preview,sheet.querySelector('.photo-sheet-copy'));
    sheet.addEventListener('close',()=>setTimeout(()=>URL.revokeObjectURL(url),35000),{once:true});
  }
  function point(event){const r=canvas.getBoundingClientRect();return {x:(event.clientX-r.left)/r.width*W,y:(event.clientY-r.top)/r.height*H};}
  function hit(item,p){const d=dimensions(item),uv=policy.localPoint(localImage(item),p.x,p.y,d.width,d.height);if(uv.x<0||uv.y<0||uv.x>=1||uv.y>=1)return false;
    const a=item.asset,x=Math.min(a.aw-1,Math.floor((a.crop[0]+uv.x*a.crop[2])*a.limit)),y=Math.min(a.ah-1,Math.floor((a.crop[1]+uv.y*a.crop[3])*a.limit));return a.alpha[(y*a.aw+x)*4+3]>24;}
  function build() {
    zone.innerHTML=`<div class="photo-shell"><header class="photo-header"><button class="photo-leave" data-sound="none">← 지도로</button><div><p class="photo-eyebrow">A MOMENT BY THE SEA</p><h1 id="photo-title">우리, 여기서 한 장</h1></div><button class="photo-invite" data-sound="ui_click">친구들 부르기</button><div class="photo-utilities" aria-label="가방과 소리 설정"></div></header>
      <div class="photo-layout"><section class="photo-workbench" aria-label="사진 촬영 영역"><div class="photo-source"><button data-photo-source="camera" data-sound="ui_click">카메라 켜기</button><button data-photo-source="upload" data-sound="ui_click">사진 올리기</button><button data-photo-source="postcard" data-sound="ui_click" aria-pressed="true">부산 배경</button><input class="photo-file" type="file" accept="image/jpeg,image/png,image/webp" hidden></div>
      <div class="photo-backgrounds" aria-label="실사풍 부산 배경"><span>부산 한 장</span><button data-backdrop="day" aria-pressed="true" data-sound="ui_click">광안리 낮</button><button data-backdrop="night" data-sound="ui_click">광안리 밤</button><small>실사풍 생성 배경</small></div><div class="photo-canvas-wrap"><canvas width="1200" height="900" tabindex="0" aria-label="친구 스티커 사진. 선택한 스티커는 방향키로 이동, Delete로 삭제할 수 있어요."></canvas><span class="photo-countdown" role="status" hidden></span></div><p class="photo-status" role="status" aria-live="polite">스티커를 골라 드래그하고, 마음에 드는 순간을 찍어 봐.</p>
      <div class="photo-controls"><span class="photo-selected-name">스티커를 골라 줘</span><label>크기<input data-adjust="size" type="range" min="12" max="55" value="24" aria-label="스티커 크기"></label><label>기울기<input data-adjust="angle" type="range" min="-180" max="180" value="0" aria-label="스티커 회전"></label><button data-edit="flip" data-sound="ui_click">좌우 반전</button><button data-edit="front" data-sound="ui_click">맨 앞으로</button><button data-edit="remove" data-sound="ui_click">지우기</button></div>
      <div class="photo-frame-row"><div class="photo-frames" aria-label="사진 프레임"><button data-frame="sea" aria-pressed="true" data-sound="ui_click">바다빛</button><button data-frame="rose" data-sound="ui_click">노을빛</button><button data-frame="ink" data-sound="ui_click">잉크빛</button></div><button class="photo-reset" data-sound="ui_click">스티커 비우기</button></div><footer class="photo-footer"><button class="photo-sticker-open" data-sound="ui_click" aria-controls="photo-album" aria-expanded="false">＋ 스티커 고르기</button><button class="photo-capture" data-sound="none">사진 찍기 <span>3초 뒤, 찰칵</span></button></footer><p class="photo-privacy">카메라는 직접 켤 때만 사용해요. 사진은 서버에 전송하지 않으며, 나가면 카메라가 꺼져요.</p></section>
      <aside id="photo-album" class="photo-album" aria-label="친구 스티커 고르기"><button class="photo-picker-close" data-sound="ui_back" aria-label="스티커 선택 닫기">닫기 ×</button><header><p class="photo-eyebrow">FRIENDS' ALBUM</p><h2>오늘의 친구들</h2><p class="photo-availability"></p></header><nav class="photo-tabs" aria-label="스티커 종류"><button data-filter="all" aria-pressed="true" data-sound="ui_click">전체</button><button data-filter="tepo" data-sound="ui_click">테포 2D</button><button data-filter="tiny" data-sound="ui_click">하찮테포</button><button data-filter="elpeng" data-sound="ui_click">엘펭이</button><button data-filter="gif" data-sound="ui_click">움직이는 GIF</button><button data-filter="real" data-sound="ui_click">실사 장난</button></nav><div class="photo-stickers"></div><p class="photo-album-note">한 번 더 고르면 같은 친구도 또 놓을 수 있어.<br>최대 8개 · 드래그로 자유롭게 배치<br>GIF도 촬영 순간의 모습으로 담겨요</p></aside></div><button class="photo-picker-shade" aria-label="스티커 선택 닫기" tabindex="-1"></button></div>`;
    canvas=zone.querySelector('canvas');ctx=canvas.getContext('2d');video=document.createElement('video');video.muted=true;video.playsInline=true;
    zone.querySelector('.photo-sticker-open').onclick=()=>picker(true);zone.querySelector('.photo-picker-close').onclick=()=>picker(false);zone.querySelector('.photo-picker-shade').onclick=()=>picker(false);
    zone.querySelector('.photo-leave').onclick=leave;zone.querySelector('.photo-invite').onclick=invite;
    zone.querySelectorAll('[data-photo-source]').forEach(b=>b.onclick=()=>{if(counting)return;backdropToken++;if(b.dataset.photoSource==='camera')camera();else if(b.dataset.photoSource==='upload')zone.querySelector('.photo-file').click();else{stopCamera();setSource('postcard');status('실사풍 부산 바다를 배경으로 골랐어.');}});
    zone.querySelectorAll('[data-backdrop]').forEach(b=>b.onclick=async()=>{if(counting)return;const key=b.dataset.backdrop,token=sceneToken,request=++backdropToken;status('부산 바다를 불러오는 중…');try{await loadBackground(key);if(!zone.open||token!==sceneToken||request!==backdropToken||counting)return;backdrop=key;stopCamera();setSource('postcard');zone.querySelectorAll('[data-backdrop]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));status((key==='day'?'햇살 아래 광안리':'불빛이 반짝이는 광안리')+'를 골랐어.');}catch{status('배경을 불러오지 못했어. 다시 골라 줘.');}});
    zone.querySelector('.photo-file').onchange=e=>{loadUpload(e.target.files[0]);e.target.value='';};
    zone.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{filter=b.dataset.filter;zone.querySelectorAll('[data-filter]').forEach(t=>t.setAttribute('aria-pressed',String(t===b)));refresh();});
    zone.querySelectorAll('[data-frame]').forEach(b=>b.onclick=()=>{if(counting)return;frame=b.dataset.frame;zone.querySelectorAll('[data-frame]').forEach(t=>t.setAttribute('aria-pressed',String(t===b)));});
    zone.querySelectorAll('[data-adjust]').forEach(input=>input.oninput=()=>{const item=items.find(i=>i.id===selected);if(!item||counting)return;if(input.dataset.adjust==='size')item.scale=Number(input.value)/100;else item.angle=Number(input.value);});
    zone.querySelectorAll('[data-edit]').forEach(b=>b.onclick=()=>{if(counting)return;const item=items.find(i=>i.id===selected);if(!item)return;if(b.dataset.edit==='flip')item.flip=!item.flip;if(b.dataset.edit==='remove'){items=items.filter(i=>i!==item);selected=null;}if(b.dataset.edit==='front'){items=items.filter(i=>i!==item);items.push(item);}updateControls();});
    zone.querySelector('.photo-reset').onclick=()=>{if(counting)return;items=[];selected=null;updateControls();status('스티커를 비웠어. 다시 골라 줘.');};
    zone.querySelector('.photo-capture').onclick=capture;
    canvas.onpointerdown=e=>{if(counting||sheet.open||e.isPrimary===false)return;const p=point(e),item=[...items].reverse().find(i=>hit(i,p));selected=item?.id||null;updateControls();if(item){drag={pointerId:e.pointerId,id:item.id,dx:p.x-item.x*W,dy:p.y-item.y*H};canvas.setPointerCapture(e.pointerId);}canvas.focus({preventScroll:true});};
    canvas.onpointermove=e=>{if(!drag||drag.pointerId!==e.pointerId||counting)return;const item=items.find(i=>i.id===drag.id),p=point(e);if(item){item.x=Math.max(.05,Math.min(.95,(p.x-drag.dx)/W));item.y=Math.max(.05,Math.min(.85,(p.y-drag.dy)/H));}};
    canvas.onpointerup=canvas.onpointercancel=canvas.onlostpointercapture=e=>{if(drag?.pointerId===e.pointerId)drag=null;};
    canvas.onkeydown=e=>{const item=items.find(i=>i.id===selected);if(!item||counting)return;const step=e.shiftKey?15:5;if(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Delete','Backspace'].includes(e.key))e.preventDefault();if(e.key==='ArrowLeft')item.x=Math.max(.05,item.x-step/W);if(e.key==='ArrowRight')item.x=Math.min(.95,item.x+step/W);if(e.key==='ArrowUp')item.y=Math.max(.05,item.y-step/H);if(e.key==='ArrowDown')item.y=Math.min(.85,item.y+step/H);if(['Delete','Backspace'].includes(e.key)){items=items.filter(i=>i!==item);selected=null;updateControls();}};
  }
  function cleanup(){picker(false,false);sceneToken++;cancelAnimationFrame(raf);countToken++;counting=false;uploadToken++;stopCamera();upload=null;items=[];selected=null;if(sheet.open)sheet.close();video=null;}
  function leave(){if(sheet.open)sheet.close();cleanup();window.TEPO_NAVIGATION.returnToMap('photo',{close:()=>zone.close(),surface:zone.querySelector('.photo-shell')});}
  async function open(opener) {
    if(zone.open||opening)return opening;from=opener;
    opening=Promise.resolve().then(async()=>{try{
      if(!catalog.length){const response=await fetch('photo-stickers.json?v=2');if(!response.ok)throw Error('catalog');catalog=(await response.json()).stickers;}
      await loadBackground('day');backdrop='day';source='postcard';frame='sea';filter='all';items=[];selected=null;build();zone.showModal();refresh();loop();zone.querySelector('.photo-leave').focus();
      if(!access().any)showSheet('사진을 같이 찍을 친구가 없다…','아직 친구들을 만나지 못했어. 등대에서 테포를 만나거나, 포토존의 ‘친구들 부르기’로 먼저 함께할 수 있어.',[{label:'알겠어',primary:true}]);
      else seed();
    }catch{showSheet('잠시만 기다려 줘','포토존을 불러오지 못했어. 다시 들어와 줘.',[{label:'돌아가기'}]);}finally{opening=null;}});return opening;
  }
  zone.addEventListener('keydown',e=>{if(!zone.classList.contains('photo-picker-open'))return;if(e.key==='Escape'){e.preventDefault();e.stopPropagation();picker(false);return;}if(e.key==='Tab'){const buttons=[...zone.querySelector('.photo-album').querySelectorAll('button:not(:disabled)')],first=buttons[0],last=buttons.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last?.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first?.focus();}}});
  zone.addEventListener('cancel',e=>{e.preventDefault();if(zone.classList.contains('photo-picker-open'))picker(false);else leave();});zone.addEventListener('close',()=>{cleanup();zone.replaceChildren();from?.focus({preventScroll:true});});
  addEventListener('pagehide',cleanup);addEventListener('tepo-inventory-change',()=>{if(zone.open)refresh();});
  window.TEPO_PHOTO={open};
})();
