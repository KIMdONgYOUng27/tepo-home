window.TEPO_STORY_READY=(async() => {
  await window.TEPO_DIALOGUE.ready;
  const storageKey='tepo-lighthouse-visit-v2';
  const validCourse=course=>course&&Object.hasOwn(window.TEPO_DIALOGUE.types,course.type)&&['half','day'].includes(course.duration)&&['slow','full'].includes(course.pace);
  const courseKey=course=>[course.type,course.duration,course.pace].join('-');
  const weapons=window.TEPO_WEAPONS;
  let progress={awake:false,translator:false,courses:[],weapons:[]};
  try{const saved=JSON.parse(sessionStorage.getItem(storageKey)||'null');if(saved&&typeof saved==='object')progress={...saved,awake:saved.awake===true,translator:saved.translator===true,courses:Array.isArray(saved.courses)?[...new Map(saved.courses.filter(validCourse).map(course=>[courseKey(course),{type:course.type,duration:course.duration,pace:course.pace}])).values()].slice(0,16):[],weapons:Array.isArray(saved.weapons)?[...new Set(saved.weapons.filter(id=>weapons.items.some(item=>item.id===id)))]:[]};}catch{}
  function save(){try{const live=JSON.parse(sessionStorage.getItem(storageKey)||'{}');progress={...live,awake:progress.awake,translator:progress.translator,courses:progress.courses,weapons:progress.weapons,radio:progress.radio===true};sessionStorage.setItem(storageKey,JSON.stringify(progress));}catch{}window.dispatchEvent(new Event('tepo-inventory-change'));}
  function keepCourse(trip){
    const course={type:trip.type,duration:trip.duration,pace:trip.pace};
    progress.courses=[course,...progress.courses.filter(item=>courseKey(item)!==courseKey(course))].slice(0,16);save();
  }
  function openCoursePaper(host,trip){
    const route=window.TEPO_DIALOGUE.makeRoute(trip),dialog=host.closest('dialog');
    const previous=[...host.childNodes],previousClass=dialog.className,previousFocus=document.activeElement;
    dialog.className='view-course-paper';
    host.innerHTML='<section class="course-paper-view"><button class="course-return">← 돌아가기</button><article class="course-paper" aria-labelledby="dialog-title"><div class="paper-inner-rule" aria-hidden="true"></div><header><p class="paper-kicker">테포의 부산 탐험 기록</p><svg class="paper-compass" viewBox="0 0 80 80" aria-hidden="true"><circle cx="40" cy="40" r="25"/><path d="M40 4 48 32 76 40 48 48 40 76 32 48 4 40 32 32Z M40 14V66M14 40H66"/><path class="compass-needle" d="M40 16 47 40 40 36 33 40Z"/></svg><h2 id="dialog-title"></h2><p class="paper-preferences"></p><p class="paper-greeting">길 잃지 말라고 적어 뒀어.<br>마음에 드는 곳에서는 조금 더 쉬어 가!</p></header><ol class="paper-stops"></ol><aside class="paper-memo"><h3>테포의 한마디</h3><p></p></aside><footer><a target="_blank" rel="noopener noreferrer"></a><span class="paper-signature">테포가 적어 줌 ♡</span></footer></article><p class="paper-saved-note">가방에 보관된 코스 종이</p></section>';
    host.querySelector('#dialog-title').textContent=route.title;
    host.querySelector('.paper-preferences').textContent=route.summary;
    const list=host.querySelector('.paper-stops');
    route.stops.forEach((stop,index)=>{const li=document.createElement('li'),number=document.createElement('span'),body=document.createElement('div'),name=document.createElement('h3'),description=document.createElement('p');number.className='paper-stop-number';number.textContent=String(index+1).padStart(2,'0');name.textContent=stop.name;description.textContent=stop.detail;body.append(name,description);li.append(number,body);list.append(li);});
    host.querySelector('.paper-memo p').textContent=route.tip;
    const source=host.querySelector('footer a');source.href=route.source.url;source.textContent='장소 정보 · '+route.source.label+' ↗';
    const back=host.querySelector('.course-return');back.textContent=previousClass==='view-bag'?'← 가방으로':'← 대화로';
    back.addEventListener('click',()=>{dialog.className=previousClass;host.replaceChildren(...previous);previousFocus?.focus({preventScroll:true});});back.focus();
  }
  function conversation(){window.TEPO_RADIO?.openFace(document.querySelector('#tepo'));}
  function receiveRadio(){
    if(!progress.awake||!progress.translator)return false;
    progress.radio=true;window.TEPO_RADIO_SESSION.receive();save();return true;
  }
  function renderDrawer(host){
    host.innerHTML='<button class="close-view" aria-label="방으로 돌아가기">← 방으로</button><section class="drawer-view"><header><p>등대의 작은 서랍</p><h2 id="dialog-title">왼쪽 서랍</h2></header><div class="open-drawer"><div class="drawer-cavity"></div><div class="drawer-fascia"><span class="drawer-handle" aria-hidden="true"></span></div></div><div class="drawer-description" aria-live="polite"></div></section>';
    const cavity=host.querySelector('.drawer-cavity'),description=host.querySelector('.drawer-description');
    if(progress.translator){cavity.innerHTML='<p class="drawer-empty">기계가 있던 자리다.</p>';description.textContent='수상한 기계는 이미 챙겼다.';return;}
    cavity.innerHTML='<button class="mysterious-machine" aria-label="수상한 기계 살펴보기"><img src="assets/tepo-translator-device-v1.png" alt="초록 화면과 안테나가 달린 수상한 기계"></button>';
    description.textContent='서랍 안에서 작은 불빛이 깜빡인다.';
    cavity.querySelector('button').addEventListener('click',()=>{
      description.innerHTML='<h3>수상한 기계</h3><p>목소리에 반응하는 장치 같다. 테포에게 써 볼까?</p><button class="take-translator">챙긴다</button>';
      const take=description.querySelector('button');take.focus();
      take.addEventListener('click',()=>{
        progress.translator=true;save();cavity.replaceChildren();
        const empty=document.createElement('p');empty.className='drawer-empty';empty.textContent='기계가 있던 자리다.';cavity.append(empty);
        description.innerHTML='<h3>수상한 기계를 챙겼다.</h3><p>이제 테포에게 다시 말을 걸어 보자.</p><button class="return-to-room">방으로 돌아가기</button>';
        const back=description.querySelector('button');back.addEventListener('click',()=>host.closest('dialog').close());back.focus();
      },{once:true});
    });
  }
  function weaponDetail(container,item,onBack){
    const owned=progress.weapons.includes(item.id);
    container.innerHTML='<section class="weapon-detail">'+(onBack?'<button class="weapon-back">← 무기 모음으로</button>':'')+'<div class="weapon-large-art">'+weapons.picture(item)+'</div><h3></h3><p class="weapon-description"></p><button class="take-weapon"></button><p class="weapon-state" role="status"></p></section>';
    container.querySelector('h3').textContent=item.label;container.querySelector('.weapon-description').textContent=item.description;
    if(onBack)container.querySelector('.weapon-back').addEventListener('click',onBack);
    const take=container.querySelector('.take-weapon');take.disabled=owned;take.textContent=owned?'가방에 보관 중':'가방에 넣기';
    take.addEventListener('click',()=>{
      if(progress.weapons.includes(item.id))return;
      progress.weapons.push(item.id);save();
      if(onBack){onBack();(container.querySelector('.weapon-choice')||container.closest('dialog')?.querySelector('.close-view'))?.focus();return;}
      take.disabled=true;take.textContent='가방에 보관 중';container.querySelector('.weapon-state').textContent=item.label+' — 가방에 보관했어.';
    });
  }
  function renderWeapons(host){
    host.innerHTML='<button class="close-view" aria-label="방으로 돌아가기">← 방으로</button><section class="weapons-view"><header><p>벽에 걸려 있던 물건들</p><h2 id="dialog-title">테포의 무기 모음</h2></header><div class="weapons-stage"></div></section>';
    const stage=host.querySelector('.weapons-stage');
    function gallery(){
      stage.innerHTML='<p class="weapons-hint">궁금한 물건을 하나 골라 봐.</p><div class="weapon-grid"></div>';
      const remaining=weapons.items.filter(item=>!progress.weapons.includes(item.id));
      if(!remaining.length)stage.querySelector('.weapons-hint').textContent='벽에 걸려 있던 무기를 모두 챙겼다.';
      remaining.forEach(item=>{const button=document.createElement('button');button.className='weapon-choice';button.setAttribute('aria-label',item.label+' 살펴보기');button.innerHTML=weapons.picture(item)+'<span></span><small></small>';button.querySelector('span').textContent=item.label;button.querySelector('small').textContent='살펴보기';button.addEventListener('click',()=>{weaponDetail(stage,item,gallery);stage.querySelector('.weapon-back').focus();});stage.querySelector('.weapon-grid').append(button);});
    }gallery();
  }
  function renderBag(host){
    try{const live=JSON.parse(sessionStorage.getItem(storageKey)||'{}');progress={...progress,...live,weapons:Array.isArray(live.weapons)?live.weapons.filter(id=>weapons.items.some(item=>item.id===id)):[],courses:Array.isArray(live.courses)?live.courses.filter(validCourse):[]};}catch{}

    host.innerHTML='<button class="close-view" aria-label="방으로 돌아가기">← 방으로</button><section class="bag-view"><header><p>발견하고 챙긴 물건들</p><h2 id="dialog-title">내 가방</h2><span class="bag-total"></span></header><div class="bag-panel"><section class="bag-browser"><nav class="bag-filters" aria-label="가방 분류"></nav><div class="bag-slots"></div><nav class="bag-pagination" aria-label="가방 페이지"><button class="bag-prev" aria-label="가방 이전 페이지">←</button><span></span><button class="bag-next" aria-label="가방 다음 페이지">→</button></nav></section><section class="bag-inspection" aria-live="polite"></section></div></section>';
    const slots=host.querySelector('.bag-slots'),inspection=host.querySelector('.bag-inspection'),filters=host.querySelector('.bag-filters'),pager=host.querySelector('.bag-pagination');
    const items=[];let category='all',page=0,selected=null;
    if(window.TEPO_RADIO_SESSION.owned())items.push({id:'radio',category:'objects',label:'테포의 무전기',icon:window.TEPO_RADIO?.icon.replace('<svg ','<svg class="bag-radio-icon" ')||'',open:()=>{inspection.innerHTML='<h3>테포의 무전기</h3><p>테포가 건네준 별도의 통신 장치.<br>밖에서도 등대에 있는 테포에게 연락할 수 있다.</p><button class="radio-bag-connect">테포에게 무전하기</button>';inspection.querySelector('button').onclick=()=>window.TEPO_RADIO.open();}});
    if(progress.translator)items.push({id:'translator',category:'objects',label:'수상한 기계',icon:'<img src="assets/tepo-translator-device-v1.png" alt="">',open:()=>{inspection.innerHTML='<img src="assets/tepo-translator-device-v1.png" alt="초록 화면과 안테나가 달린 수상한 기계"><h3>수상한 기계</h3><p>테포의 말을 알아들을 수 있게 해 주는 장치.<br>가방에 넣어 두면 대화할 때 자동으로 작동한다.</p>';}});
    weapons.items.filter(item=>progress.weapons.includes(item.id)).forEach(item=>items.push({id:item.id,category:'weapons',label:item.label,icon:weapons.picture(item),open:()=>weaponDetail(inspection,item)}));
    progress.courses.forEach(course=>{const route=window.TEPO_DIALOGUE.makeRoute(course);items.push({id:courseKey(course),category:'courses',label:route.title,description:route.summary,icon:'<span class="bag-paper-icon" aria-hidden="true"><i></i><i></i><i></i></span>',open:()=>openCoursePaper(host,course)});});
    const capacity=Math.max(24,Math.ceil(items.length/12)*12);host.querySelector('.bag-total').textContent=items.length+' / '+capacity+'칸';
    [['all','전체'],['objects','물건'],['weapons','무기'],['courses','코스 종이']].forEach(([id,label])=>{const button=document.createElement('button');button.textContent=label;button.dataset.category=id;button.addEventListener('click',()=>{category=id;page=0;draw();});filters.append(button);});
    function draw(){
      const filtered=items.filter(item=>category==='all'||item.category===category),pages=category==='all'?capacity/12:Math.max(1,Math.ceil(filtered.length/12));
      page=Math.max(0,Math.min(page,pages-1));slots.replaceChildren();
      filtered.slice(page*12,page*12+12).forEach(item=>{const button=document.createElement('button');button.className='bag-item';button.setAttribute('aria-label',item.label+(item.description?' · '+item.description:'')+' 확인하기');button.setAttribute('aria-pressed',String(selected===item.id));button.innerHTML=item.icon+'<span class="bag-item-name"></span><small></small>';button.querySelector('.bag-item-name').textContent=item.label;button.querySelector('small').textContent=item.description||'';button.addEventListener('click',()=>{selected=item.id;slots.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));item.open();});slots.append(button);});
      for(let i=slots.children.length;i<12;i++){const empty=document.createElement('span');empty.className='bag-slot-empty';empty.setAttribute('aria-hidden','true');slots.append(empty);}
      filters.querySelectorAll('button').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.category===category)));
      pager.querySelector('span').textContent=(page+1)+' / '+pages;pager.querySelector('.bag-prev').disabled=page===0;pager.querySelector('.bag-next').disabled=page>=pages-1;
    }
    pager.querySelector('.bag-prev').addEventListener('click',()=>{page--;draw();});pager.querySelector('.bag-next').addEventListener('click',()=>{page++;draw();});
    inspection.innerHTML=items.length?'<p class="bag-empty">물건을 눌러 자세히 살펴보자.</p>':'<p class="bag-empty">아직 챙긴 물건이 없다.<br>이 동네를 조금 더 둘러볼까?</p>';draw();
  }
  window.TEPO_STORY={get awake(){return progress.awake;},get translated(){return progress.translator;},receiveRadio,wake(){progress.awake=true;save();},hasWeapon:id=>progress.weapons.includes(id),talk:conversation,keepCourse,renderDrawer,renderBag,renderWeapons};
})();

window.TEPO_STORY_READY.catch(()=>{});
