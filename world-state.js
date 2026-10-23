(() => {
  const key='tepo-lighthouse-visit-v2';
  let memory={};
  function read(){try{return JSON.parse(sessionStorage.getItem(key)||'{}')||{};}catch{return memory;}}
  function update(patch){memory={...read(),...patch};try{sessionStorage.setItem(key,JSON.stringify(memory));}catch{}return memory;}
  window.TEPO_WORLD_STATE={read,update};
})();
