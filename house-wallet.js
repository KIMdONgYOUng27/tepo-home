(() => {
  const stamps=Array.from({length:10},(_,i)=>`<span class="coupon-stamp ${i<8?'is-stamped':''}" aria-label="${i+1}번째 칸 ${i<8?'도장 있음':'비어 있음'}">${i<8?'국밥':i+1}</span>`).join('');
  const coupon=()=>`<article class="gukbap-coupon"><div class="coupon-topline">한 그릇의 행복</div><h3>국밥 쿠폰</h3><p class="coupon-subtitle">열 번의 따뜻한 한 끼</p><div class="coupon-stamps">${stamps}</div><footer><span>도장 10개를 모으면 국밥 한 그릇</span><strong>8 / 10</strong></footer></article>`;
  const identity=()=>`<article class="tepo-id"><header><h3>주민등록증</h3><span>TEPO</span></header><div class="id-main"><div class="id-portrait" role="img" aria-label="테포 증명사진"></div><dl><div><dt>이름</dt><dd>테포</dd></div><div><dt>주민등록번호</dt><dd class="masked-number">XXXXXX-XXXXXXX</dd></div><div><dt>거주지</dt><dd>XXXXXXXXXXXX</dd></div></dl></div><footer><span>발급일자 <b>—</b></span><span>발급기관 <b>—</b></span></footer></article>`;
  const items=[{id:'coupon',label:'국밥 쿠폰',render:coupon},{id:'identity',label:'민증',render:identity}];
  const notes=[{id:'won-one',label:'만원권 첫 번째 장',src:'assets/wallet-10000-won-real-v1.png'},{id:'won-two',label:'만원권 두 번째 장',src:'assets/wallet-10000-won-real-v1.png'},{id:'dollar',label:'10달러',src:'assets/wallet-10-dollar-real-v1.png'}];
  window.renderTepoWallet=host=>{
    host.innerHTML='<button class="close-view" aria-label="방으로 돌아가기">← 방으로</button><section class="wallet-view"><header class="wallet-heading"><p>TEPO’S POCKET</p><h2 id="dialog-title">테포의 지갑</h2></header><div class="wallet-stage"></div></section>';
    const stage=host.querySelector('.wallet-stage'),title=host.querySelector('#dialog-title');
    function overview(focusId){
      title.textContent='테포의 지갑';stage.innerHTML='<div class="leather-wallet pocket-wallet concealed-wallet"><button class="cash-compartment" aria-label="지폐 수납칸 열기"><span class="cash-slot-gap" aria-hidden="true"></span><span class="cash-slot-lip" aria-hidden="true"></span></button><div class="wallet-fold"></div><div class="wallet-contents"><div class="wallet-leaf wallet-leaf-left"><div class="leather-pocket-front"></div></div><div class="wallet-leaf wallet-leaf-right"><div class="leather-pocket-front"></div></div></div><span class="wallet-emboss" aria-hidden="true">TEPO</span></div><p class="wallet-hint">궁금한 곳을 눌러봐.</p>';
      items.forEach((item,index)=>{const button=document.createElement('button');button.className='wallet-item wallet-item-'+item.id;button.dataset.walletItem=item.id;button.setAttribute('aria-label',(index===0?'왼쪽':'오른쪽')+' 물건 꺼내 보기');button.innerHTML='<span class="wallet-peek" aria-hidden="true"><span class="peek-paper blank-card-back"></span></span>';button.addEventListener('click',()=>detail(item));stage.querySelector(index===0?'.wallet-leaf-left':'.wallet-leaf-right').append(button);});
      stage.querySelector('.cash-compartment').addEventListener('click',cash);
      if(focusId==='cash')stage.querySelector('.cash-compartment').focus();else if(focusId)stage.querySelector(`[data-wallet-item="${focusId}"]`).focus();
    }
    function detail(item){
      title.textContent=item.label;stage.innerHTML=`<div class="wallet-detail wallet-detail-${item.id}"><button class="wallet-return">← 지갑 안으로</button><div class="wallet-detail-card extracted-paper">${item.render()}</div></div>`;
      stage.querySelector('.wallet-return').addEventListener('click',()=>overview(item.id));stage.querySelector('.wallet-return').focus();
    }
    function cash(){
      title.textContent='지폐 수납칸';stage.innerHTML='<div class="wallet-detail cash-detail"><button class="wallet-return">← 지갑 안으로</button><div class="cash-lining"><div class="cash-bills"></div></div></div>';
      stage.querySelector('.wallet-return').addEventListener('click',()=>overview('cash'));
      const tray=stage.querySelector('.cash-bills');notes.forEach(note=>{const button=document.createElement('button');button.className='cash-bill cash-bill-'+note.id;button.dataset.note=note.id;button.setAttribute('aria-label',note.label+' 살펴보기');const img=document.createElement('img');img.src=note.src;img.alt=note.label;button.append(img);button.addEventListener('click',()=>noteDetail(note));tray.append(button);});
      stage.querySelector('.wallet-return').focus();
    }
    function noteDetail(note){
      title.textContent=note.label;stage.innerHTML='<div class="wallet-detail note-detail"><button class="wallet-return">← 지폐 수납칸으로</button><div class="cash-single"></div></div>';
      const img=document.createElement('img');img.src=note.src;img.alt=note.label;stage.querySelector('.cash-single').append(img);stage.querySelector('.wallet-return').addEventListener('click',cash);stage.querySelector('.wallet-return').focus();
    }
    overview();
  };
})();
