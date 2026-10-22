(() => {
  'use strict';
  const welcome=document.querySelector('#world-welcome'),welcomeKey='tepo-world-welcome-session-v1';
  // Session-only: return trips from the house and reloads keep the map unobstructed.
  let welcomed=false;
  try{welcomed=sessionStorage.getItem(welcomeKey)==='shown';}catch{}
  let fromWorld=false;
  try{const ref=new URL(document.referrer);fromWorld=ref.origin===location.origin&&ref.pathname.startsWith(new URL('.',location.href).pathname);}catch{}
  if(welcome&&!welcomed&&!fromWorld){
    try{sessionStorage.setItem(welcomeKey,'shown');}catch{}
    welcome.showModal();
  }
  if(welcome){
    welcome.querySelector('.welcome-start').addEventListener('click',()=>welcome.close());
    welcome.addEventListener('close',()=>{document.querySelector('main').focus({preventScroll:true});});
  }
  const background=document.querySelector('.map-background');
  const viewport=document.querySelector('#map-viewport');
  const scene=document.querySelector('#map-scene');
  const loading=document.querySelector('#map-loading');
  const buttons=[...document.querySelectorAll('.destination')];
  const atlas=new Image();
  atlas.src='assets/destinations-varied-angles-v4.png';
  // Source rectangles contain real PNG alpha, with no background sampling.
  // Ground anchors keep every landmark planted during enlargement.
  const places={
    arcade:{crop:[210,60,470,445],width:265,ground:[548,365],anchor:[238/470,353/445]},
    // The atlas crop also catches the photo frame's top edge at bottom-left.
    // Mask that empty corner in both the artwork and the pointer silhouette.
    popup:{crop:[866,76,520,454],width:265,ground:[1090,383],anchor:[249/520,359/454],exclude:[0,420,100,34],clip:'polygon(0 0,100% 0,100% 100%,19.23% 100%,19.23% 92.51%,0 92.51%)'},
    photo:{crop:[653,499,445,401],width:190,ground:[850,548],anchor:[174/445,296/401],exclude:[311,0,134,36],clip:'polygon(0 0,69.89% 0,69.89% 8.98%,100% 8.98%,100% 100%,0 100%)'},
    home:{crop:[1300,330,320,555],width:150,ground:[1435,535],anchor:[187/320,450/555],exclude:[0,0,92,433],clip:'polygon(28.75% 0,100% 0,100% 100%,0 100%,0 78.02%,28.75% 78.02%)'},
    mystery:{crop:[98,550,397,330],width:185,ground:[268,495],anchor:[202/397,229/330]}
  };
  function layoutScene(){
    if(!background.naturalWidth)return;
    const iw=background.naturalWidth,ih=background.naturalHeight;
    const w=viewport.clientWidth,h=viewport.clientHeight,margin=Math.min(20,w*.012);
    const scale=Math.min((w-margin*2)/iw,(h-margin*2)/ih);
    scene.style.width=iw+'px';scene.style.height=ih+'px';
    scene.style.transform='translate('+((w-iw*scale)/2)+'px,'+((h-ih*scale)/2)+'px) scale('+scale+')';
    buttons.forEach(button=>{
      const {crop:[x,y,cw,ch],width,ground:[gx,gy],anchor:[ax,ay]}=places[button.dataset.place];
      const height=width*ch/cw;
      Object.assign(button.style,{left:(gx-ax*width)+'px',top:(gy-ay*height)+'px',width:width+'px',height:height+'px'});
      Object.assign(button.querySelector('.place-sprite').style,{
        backgroundSize:atlas.naturalWidth/cw*100+'% '+atlas.naturalHeight/ch*100+'%',
        backgroundPosition:x/(atlas.naturalWidth-cw)*100+'% '+y/(atlas.naturalHeight-ch)*100+'%',
        transformOrigin:ax*100+'% '+ay*100+'%',
        clipPath:places[button.dataset.place].clip||'none'
      });
    });
  }
  function createAlphaHitAreas(){
    const canvas=document.createElement('canvas');
    canvas.width=atlas.naturalWidth;canvas.height=atlas.naturalHeight;
    const ctx=canvas.getContext('2d',{willReadFrequently:true});
    ctx.drawImage(atlas,0,0);
    const ns='http://www.w3.org/2000/svg';
    buttons.forEach(button=>{
      const [x,y,w,h]=places[button.dataset.place].crop;
      const pixels=ctx.getImageData(x,y,w,h).data;
      const exclude=places[button.dataset.place].exclude;
      const runs=[];
      // Two-pixel alpha runs form an exact interactive silhouette, including holes.
      for(let row=0;row<h;row+=2){
        let start=-1;
        for(let col=0;col<=w;col++){
          const excluded=exclude&&col>=exclude[0]&&col<exclude[0]+exclude[2]&&row>=exclude[1]&&row<exclude[1]+exclude[3];
          const solid=col<w&&!excluded&&pixels[(row*w+col)*4+3]>48;
          if(solid&&start<0)start=col;
          if(!solid&&start>=0){runs.push('M'+start+' '+row+'h'+(col-start)+'v'+Math.min(2,h-row)+'h'+(start-col)+'Z');start=-1;}
        }
      }
      const svg=document.createElementNS(ns,'svg');
      svg.setAttribute('viewBox','0 0 '+w+' '+h);
      svg.setAttribute('aria-hidden','true');svg.setAttribute('focusable','false');
      svg.classList.add('hit-area');
      const path=document.createElementNS(ns,'path');
      path.setAttribute('d',runs.join(''));path.setAttribute('fill','transparent');
      path.style.pointerEvents='fill';
      svg.append(path);button.append(svg);
    });
  }
  let selectedTimer;
  buttons.forEach(button=>button.addEventListener('click',()=>{
    if(button.dataset.place==='home'){window.location.href='house.html';return;}
    clearTimeout(selectedTimer);
    buttons.forEach(item=>item.classList.toggle('is-selected',item===button));
    selectedTimer=setTimeout(()=>button.classList.remove('is-selected'),900);
  }));
  background.addEventListener('load',layoutScene);
  new ResizeObserver(layoutScene).observe(viewport);
  Promise.all([background.decode(),atlas.decode()]).then(()=>{
    layoutScene();createAlphaHitAreas();loading.classList.add('is-ready');
  }).catch(error=>{loading.classList.add('is-ready');console.error('Map asset loading failed.',error);});
})();
