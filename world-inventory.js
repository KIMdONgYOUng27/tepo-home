(() => {
  'use strict';
  const bag=document.createElement('dialog');
  bag.id='world-bag-dialog';bag.setAttribute('aria-label','내 가방');
  const host=document.createElement('div');host.className='world-bag-content';bag.append(host);document.body.append(bag);
  let opener;
  const icon='<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M11 10V7a5 5 0 0 1 10 0v3M7 10h18l3 19H4L7 10Z M10 19h12v7H10Z"/></svg><span>가방</span>';
  function launcher(parent){
    if(parent.querySelector(':scope > .world-bag-toggle'))return;
    const button=document.createElement('button');button.className='bag-toggle world-bag-toggle';button.dataset.worldBag='';button.setAttribute('aria-label','가방 열기');button.innerHTML=icon;parent.append(button);
  }
  function sync(){
    launcher(document.body);
    document.querySelectorAll('dialog[open]:not(#world-bag-dialog):not(#world-welcome):not(#tepo-radio-dialog):not(.world-travel)').forEach(dialog=>launcher(dialog.querySelector('.game-player')||dialog));
    const active=[...document.querySelectorAll('dialog[open]')].at(-1);
    document.querySelectorAll('.world-bag-toggle').forEach(button=>{button.hidden=bag.open||!!active&&(active.id==='world-welcome'||active.classList.contains('world-travel')||!active.contains(button));});
  }
  document.addEventListener('click',async event=>{
    const target=event.target.closest('[data-world-bag]');if(!target||bag.open)return;
    opener=target;try{await window.TEPO_STORY_READY;}catch{return;}if(bag.open)return;bag.className='view-bag';window.TEPO_STORY.renderBag(host);
    const close=host.querySelector('.close-view');close.textContent='← 돌아가기';close.setAttribute('aria-label','현재 장소로 돌아가기');close.onclick=()=>bag.close();
    bag.showModal();close.focus();
  });
  bag.addEventListener('close',()=>{host.replaceChildren();if(opener?.isConnected)opener.focus({preventScroll:true});});
  new MutationObserver(sync).observe(document.body,{subtree:true,childList:true,attributes:true,attributeFilter:['open']});sync();
})();
