(() => {
  'use strict';
  const progressKey = 'tepo-lighthouse-visit-v2';
  const visitKey = 'tepo-world-visit-v2';
  const navigation = performance.getEntriesByType('navigation')[0];
  let internal = false;
  try {
    const from = new URL(document.referrer);
    const root = new URL('.', location.href);
    internal = from.origin === root.origin &&
      [root.pathname, root.pathname + 'index.html', root.pathname + 'house.html'].includes(from.pathname);
  } catch {}
  try {
    // A refresh or a new arrival starts over; moving between map and room does not.
    const continuing = sessionStorage.getItem(visitKey) && internal &&
      navigation?.type !== 'reload';
    const old=JSON.parse(sessionStorage.getItem(progressKey)||'{}');
    if(old.radio){if(old.radioHistory?.length&&!sessionStorage.getItem('tepo-radio-chat-v1'))sessionStorage.setItem('tepo-radio-chat-v1',JSON.stringify({history:old.radioHistory,context:old.radioContext||{},buttons:[],checkpoints:[],open:false,panel:'chat'}));}
    if (!continuing) sessionStorage.removeItem(progressKey);
    if(sessionStorage.getItem('tepo-radio-received-v33')==='1'){const restored=JSON.parse(sessionStorage.getItem(progressKey)||'{}');restored.radio=true;sessionStorage.setItem(progressKey,JSON.stringify(restored));}
    else {const restored=JSON.parse(sessionStorage.getItem(progressKey)||'{}');delete restored.radio;sessionStorage.setItem(progressKey,JSON.stringify(restored));}
    sessionStorage.setItem(visitKey, 'active');
  } catch {}
})();
