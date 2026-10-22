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
    if (!continuing) sessionStorage.removeItem(progressKey);
    sessionStorage.setItem(visitKey, 'active');
  } catch {}
})();
