/* One JSON source for authored radio replies, house dialogue and curated routes. */
(() => {
  const api={nodes:{},types:{},data:null,ready:null};
  function makeRoute({type,duration,pace}){
    if(!api.types[type]||!['half','day'].includes(duration)||!['slow','full'].includes(pace))throw new Error('Invalid trip preferences');
    const item=api.types[type],t=api.data.routeText,count=duration==='half'?(pace==='slow'?2:3):(pace==='slow'?3:4);
    return {title:item.title+t.suffix,summary:t[duration]+' · '+t[pace],intro:duration==='half'?t.introHalf:t.introDay,stops:item.stops.slice(0,count).map(([name,detail])=>({name,detail})),tip:item.tip,source:item.source,closing:pace==='slow'?t.closingSlow:t.closingFull};
  }
  async function load(){
    const response=await fetch(new URL('data/tepo-chatbot.json?v=35',document.baseURI));if(!response.ok)throw new Error('Dialogue JSON unavailable');
    const data=await response.json();if(data.version!==35||!Array.isArray(data.nodes)||!data.houseDialogue)throw new Error('Invalid dialogue data');
    const ids=new Set(data.nodes.map(node=>node.id));if(ids.size!==data.nodes.length)throw new Error('Duplicate dialogue ID');
    for(const node of data.nodes){for(const keyword of node.keywords)new RegExp(keyword);for(const button of node.buttons)if(!ids.has(button.next))throw new Error('Unknown next step: '+button.next);}
    api.data=data;api.types=data.houseDialogue.types;api.nodes=Object.fromEntries(Object.entries(data.houseDialogue.nodes).map(([id,node])=>[id,{text:node.answer,choices:node.buttons.map(button=>({label:button.label,to:button.next}))}]));return data;
  }
  api.makeRoute=makeRoute;api.reload=()=>api.ready=load();window.TEPO_DIALOGUE=api;api.reload();api.ready.catch(()=>{});
})();
