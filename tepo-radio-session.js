/* Chat is a separate same-tab session, independent of game visit resets. */
(() => {
  const key='tepo-radio-chat-v1',ownedKey='tepo-radio-received-v33',progressKey='tepo-lighthouse-visit-v2';
  const json=key=>{try{return JSON.parse(sessionStorage.getItem(key)||'null');}catch{return null;}};
  const clone=value=>JSON.parse(JSON.stringify(value));
  function load(mode){
    const stored=json(key);if(!stored)return null;
    const selected=mode||stored.activeMode||stored.mode||'radio';
    const saved=stored.version===35?stored.conversations?.[selected]:(!mode||selected===(stored.mode||'radio'))?stored:null;
    if(!saved||!Array.isArray(saved.history))return null;
    return {history:saved.history.filter(item=>['visitor','tepo'].includes(item?.role)&&typeof item.text==='string').slice(-80),context:saved.context||{},buttons:Array.isArray(saved.buttons)?saved.buttons:[],checkpoints:Array.isArray(saved.checkpoints)?saved.checkpoints.slice(-25):[],pending:saved.pending||null,panel:saved.panel||'chat',mode:selected==='face'?'face':'radio',inquiryType:saved.inquiryType==='production'?'production':'general',draft:typeof saved.draft==='string'?saved.draft.slice(0,300):'',open:saved.open===true};
  }
  function save(state){try{
    const old=json(key),stored=old?.version===35?old:{version:35,conversations:{}};
    if(old?.history)stored.conversations[old.mode==='face'?'face':'radio']=old;
    const mode=state.mode==='face'?'face':'radio';stored.activeMode=mode;stored.conversations[mode]=clone({...state,mode});
    sessionStorage.setItem(key,JSON.stringify(stored));
  }catch{}}
  function receive(){try{sessionStorage.setItem(ownedKey,'1');}catch{}}
  function owned(){try{return sessionStorage.getItem(ownedKey)==='1';}catch{return false;}}
  function clear(){try{sessionStorage.removeItem(key);const progress=json(progressKey);if(progress){delete progress.radioHistory;delete progress.radioContext;sessionStorage.setItem(progressKey,JSON.stringify(progress));}}catch{}}
  function migrate(){if(load())return;const p=json(progressKey);if(p?.radioHistory?.length)save({history:p.radioHistory,context:p.radioContext||{},buttons:[],checkpoints:[],panel:'chat',open:false});if(p&&(p.radioHistory||p.radioContext)){delete p.radioHistory;delete p.radioContext;try{sessionStorage.setItem(progressKey,JSON.stringify(p));}catch{}}}
  window.TEPO_RADIO_SESSION={key,load,save,clear,receive,owned,migrate};
})();
