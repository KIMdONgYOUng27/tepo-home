(() => {
  'use strict';
  const background=document.querySelector('.map-background');
  const viewport=document.querySelector('#map-viewport');
  const scene=document.querySelector('#map-scene');
  const loading=document.querySelector('#map-loading');
  const destinations=[...document.querySelectorAll('.destination')];
  // Original artwork is shown through separate, tightly traced alpha masks.
  // The clean plate underneath contains no duplicated destination drawings.
  const places={
    arcade:{"rect":[365,218,285,232],"origin":[0.48,0.78],"mask":"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%22365%20218%20285%20232%22%20width%3D%22285%22%20height%3D%22232%22%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M377%20282%20L409%20263%20L425%20255%20L489%20245%20L489%20240%20L498%20239%20L504%20243%20L543%20237%20L545%20227%20L553%20222%20L560%20228%20L562%20241%20L577%20246%20L598%20276%20L594%20284%20L591%20285%20L592%20301%20L622%20308%20L638%20320%20L631%20326%20L631%20359%20L638%20367%20L638%20380%20L628%20384%20L618%20381%20L613%20367%20L604%20367%20L606%20382%20L600%20387%20L590%20390%20L581%20385%20L582%20377%20L568%20380%20L562%20390%20L427%20399%20L397%20388%20L393%20376%20L384%20376%20L382%20361%20L376%20359%20L374%20342%20L367%20338%20L367%20326%20L375%20318%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M423%20400%20Q475%20388%20594%20382%20Q604%20386%20603%20398%20L607%20426%20Q605%20430%20596%20428%20Q528%20430%20455%20441%20L445%20444%20L436%20442%20L432%20437%20L432%20429%20L428%20419%20Z%22%2F%3E%3C%2Fsvg%3E"},
    popup:{"rect":[960,248,285,204],"origin":[0.48,0.78],"mask":"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%22960%20248%20285%20204%22%20width%3D%22285%22%20height%3D%22204%22%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M1034%20254%20L1170%20259%20L1184%20265%20L1218%20302%20L1216%20351%20L1225%20354%20L1228%20365%20L1238%20369%20L1235%20393%20L1218%20399%20L1205%20397%20L1190%20403%20L1178%20402%20L1175%20409%20L1158%20410%20L1153%20395%20L1135%20398%20L994%20388%20L978%20380%20L975%20369%20L968%20366%20L968%20309%20L972%20290%20L1001%20283%20L1032%20277%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M987%20397%20Q1006%20389%201033%20393%20L1154%20403%20Q1164%20407%201160%20419%20L1155%20442%20Q1149%20446%201137%20441%20Q1079%20432%201004%20440%20Q988%20441%20988%20432%20L991%20416%20Z%22%2F%3E%3C%2Fsvg%3E"},
    photo:{"rect":[746,438,181,184],"origin":[0.5,0.76],"mask":"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%22746%20438%20181%20184%22%20width%3D%22181%22%20height%3D%22184%22%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M756%20463%20L886%20443%20L891%20553%20L759%20576%20Z%20M777%20478%20L871%20462%20L875%20541%20L780%20558%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M779%20534%20C775%20525%20780%20517%20789%20517%20C795%20517%20799%20521%20799%20526%20C809%20522%20812%20530%20814%20535%20C823%20532%20827%20539%20834%20541%20C849%20545%20858%20532%20866%20532%20L874%20520%20L876%20543%20L781%20562%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M823%20494%20L829%20493%20L830%20490%20L846%20489%20L852%20493%20L853%20505%20L847%20511%20L844%20516%20L846%20524%20L859%20567%20L854%20569%20L841%20534%20L842%20570%20L837%20573%20L835%20537%20L821%20573%20L816%20572%20L831%20523%20L833%20514%20L825%20511%20L822%20504%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M754%20579%20Q785%20569%20814%20575%20Q853%20577%20911%20568%20Q922%20570%20920%20581%20L924%20609%20Q918%20612%20908%20612%20Q842%20618%20779%20614%20L752%20610%20L754%20599%20Z%22%2F%3E%3C%2Fsvg%3E"},
    home:{"rect":[1374,382,169,240],"origin":[0.3,0.67],"mask":"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%221374%20382%20169%20240%22%20width%3D%22169%22%20height%3D%22240%22%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M1418%20385%20Q1426%20388%201423%20396%20L1421%20399%20L1436%20410%20Q1442%20416%201440%20419%20L1435%20423%20L1439%20444%20L1435%20450%20L1440%20526%20L1455%20533%20L1455%20546%20Q1424%20560%201382%20549%20L1377%20542%20L1380%20533%20L1392%20527%20L1398%20452%20L1391%20447%20L1393%20423%20L1396%20418%20L1397%20415%20L1413%20399%20Q1409%20389%201418%20385%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M1397%20573%20Q1456%20562%201522%20546%20Q1529%20546%201532%20556%20L1538%20587%20Q1538%20594%201530%20597%20Q1469%20605%201398%20618%20L1389%20616%20L1396%20602%20L1394%20584%20Z%22%2F%3E%3C%2Fsvg%3E"},
    mystery:{"rect":[170,430,180,155],"origin":[0.5,0.65],"mask":"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%22170%20430%20180%20155%22%20width%3D%22180%22%20height%3D%22155%22%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M192%20507%20C189%20482%20208%20448%20241%20437%20C267%20428%20291%20439%20307%20457%20Q324%20477%20326%20517%20L303%20525%20L277%20527%20L232%20527%20L211%20522%20L197%20524%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M261%20517%20Q266%20510%20272%20511%20L283%20521%20L281%20526%20L266%20528%20L258%20525%20Z%22%2F%3E%3Cpath%20fill%3D%22white%22%20fill-rule%3D%22evenodd%22%20d%3D%22M179%20535%20Q211%20526%20243%20531%20Q286%20533%20333%20526%20Q345%20525%20344%20536%20L341%20550%20L345%20565%20Q344%20573%20333%20572%20Q270%20580%20199%20578%20L176%20573%20L177%20565%20L181%20551%20Z%22%2F%3E%3C%2Fsvg%3E"}
  };
  function layoutScene(){
    if(!background.naturalWidth)return;
    const iw=background.naturalWidth,ih=background.naturalHeight;
    const w=viewport.clientWidth,h=viewport.clientHeight;
    const margin=Math.min(20,w*.012);
    const scale=Math.min((w-margin*2)/iw,(h-margin*2)/ih);
    scene.style.width=iw+'px';scene.style.height=ih+'px';
    scene.style.transform='translate('+((w-iw*scale)/2)+'px,'+((h-ih*scale)/2)+'px) scale('+scale+')';
    destinations.forEach(button=>{
      const {rect:[x,y,bw,bh],origin,mask}=places[button.dataset.place];
      Object.assign(button.style,{left:x+'px',top:y+'px',width:bw+'px',height:bh+'px'});
      const art=button.querySelector('.place-sprite');
      Object.assign(art.style,{backgroundSize:'1672px 941px',backgroundPosition:-x+'px '+-y+'px',maskImage:'url("'+mask+'")',webkitMaskImage:'url("'+mask+'")',transformOrigin:origin[0]*100+'% '+origin[1]*100+'%'});
    });
  }
  // SVG paths also define pointer hit areas; transparent holes never trigger hover.
  destinations.forEach(button=>{
    const data=places[button.dataset.place];
    const svg=new DOMParser().parseFromString(decodeURIComponent(data.mask.split(',').slice(1).join(',')),'image/svg+xml').documentElement;
    svg.classList.add('hit-area');
    svg.setAttribute('width','100%');svg.setAttribute('height','100%');
    svg.setAttribute('aria-hidden','true');svg.setAttribute('focusable','false');
    svg.querySelectorAll('path').forEach(path=>{path.setAttribute('fill','transparent');path.style.pointerEvents='fill';});
    button.append(svg);
  });
  background.addEventListener('load',layoutScene);
  new ResizeObserver(layoutScene).observe(viewport);
  let selectedTimer;
  destinations.forEach(button=>button.addEventListener('click',()=>{
    clearTimeout(selectedTimer);
    destinations.forEach(item=>item.classList.toggle('is-selected',item===button));
    selectedTimer=setTimeout(()=>button.classList.remove('is-selected'),900);
  }));
  const sourceArt=new Image();sourceArt.src='assets/busan-parchment-map-v1.png';
  Promise.all([background.decode(),sourceArt.decode()]).then(()=>{layoutScene();loading.classList.add('is-ready');}).catch(()=>{
    loading.classList.add('is-ready');
    console.error('Map asset loading failed.');
  });
})();
