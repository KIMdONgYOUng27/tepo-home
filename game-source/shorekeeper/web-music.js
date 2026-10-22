/* Native browser music avoids decoding entire long Ogg tracks as Godot samples. */
(() => {
  'use strict';
  const names = ['title', 'combat', 'late', 'boss'];
  const voices = [0, 1].map(i => {
    const a = document.createElement('audio');
    a.id = `tepo-bgm-${i}`;
    a.hidden = true;
    a.loop = true;
    a.preload = 'metadata';
    a.volume = 0;
    document.body.append(a);
    return a;
  });
  const button = document.createElement('button');
  button.id = 'tepo-audio-enable';
  button.textContent = '♪ 소리 켜기';
  button.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:20;padding:10px 16px;border:2px solid #6b7152;border-radius:9px;background:#faf0d8;color:#334637;font:16px sans-serif;cursor:pointer';
  button.hidden = true;
  document.body.append(button);
  let active = -1, track = '', enabled = true, level = 0;
  let weights = [0, 0], targets = [0, 0], last = performance.now(), generation = 0;
  function tryPlay(i) {
    const a = voices[i];
    if (!a.getAttribute('src') || !enabled || !level || document.hidden) return;
    const token = generation;
    a.play().then(() => { if (token === generation) button.hidden = true; }).catch(e => {
      if (token === generation && e.name === 'NotAllowedError') button.hidden = false;
    });
  }
  function resume() {
    if (active >= 0) tryPlay(active);
    if (active >= 0 && weights[1-active] > 0) tryPlay(1-active);
  }
  function move(a, b, step) { return a < b ? Math.min(b, a+step) : Math.max(b, a-step); }
  function frame(now) {
    const dt = Math.min(.1, (now-last)/1000); last = now;
    voices.forEach((a, i) => {
      weights[i] = move(weights[i], targets[i], dt/1.2);
      a.volume = Math.min(1, Math.max(0, weights[i]*level));
      a.muted = !enabled;
      if ((targets[i] === 0 && weights[i] === 0) || !enabled || document.hidden || level === 0) {
        if (!a.paused) a.pause();
      }
    });
    requestAnimationFrame(frame);
  }
  window.TepoMusic = {
    sync(id, gain, on) {
      if (!names.includes(id)) return;
      const wasEnabled = enabled && level > 0;
      enabled = Boolean(on); level = Math.min(1, Math.max(0, Number(gain)||0));
      if (track !== id) {
        track = id; generation++;
        active = active === 0 ? 1 : 0;
        const a = voices[active];
        a.pause(); a.src = `music/${id}.ogg`; a.volume = 0; a.muted = !enabled;
        weights[active] = 0; targets = [0, 0]; targets[active] = 1;
        tryPlay(active);
      } else if (!wasEnabled && enabled && level > 0) resume();
      if (!enabled || !level) button.hidden = true;
    },
    stop() {
      voices.forEach(a => { a.pause(); a.removeAttribute('src'); a.load(); });
      targets = [0, 0]; weights = [0, 0]; active = -1; track = ''; button.hidden = true;
    }
  };
  button.addEventListener('click', resume);
  document.addEventListener('pointerdown', resume, {capture:true});
  document.addEventListener('keydown', resume, {capture:true});
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) voices.forEach(a => a.pause()); else resume();
  });
  requestAnimationFrame(frame);
})();
