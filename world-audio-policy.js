/* Pure mixing rules, shared by runtime and regression tests. */
(() => {
  const defaults={muted:false,bgm:.28,sfx:.55,game:.85};
  const bounded=(value,fallback)=>Number.isFinite(Number(value))?Math.min(1,Math.max(0,Number(value))):fallback;
  function settings(raw={}){return {muted:raw.muted===true,bgm:bounded(raw.bgm,defaults.bgm),sfx:bounded(raw.sfx,defaults.sfx),game:bounded(raw.game,defaults.game)};}
  function mix(prefs,state){
    const p=settings(prefs),silent=p.muted||state.hidden;
    const base=state.house ? .72 : 1,duck=state.dialogue ? .38 : 1;
    return {bgm:!state.armed||silent||state.game||state.video?0:p.bgm*base*duck,sfx:silent?0:p.sfx,game:silent||!state.game?0:p.game};
  }
  const weaponCue=id=>({baton:'weapon_baton',bat:'weapon_bat',unknown:'weapon_unknown',mace:'weapon_mace'})[id];
  const collectSequence=(id,sounds={})=>[{name:weaponCue(id)||({translator:'device_pickup',radio:'radio_on',course:'page_turn'})[id]||'ui_click',delay:0},{name:'bag_collect',delay:typeof sounds[weaponCue(id)||({translator:'device_pickup',radio:'radio_on',course:'page_turn'})[id]]?.seconds==='number'?sounds[weaponCue(id)||({translator:'device_pickup',radio:'radio_on',course:'page_turn'})[id]].seconds+.05:({baton:.47,bat:.32,unknown:.55,mace:.67,translator:.42,radio:.47,course:.40})[id]||.3}];
  window.TEPO_AUDIO_POLICY={defaults,settings,mix,weaponCue,collectSequence};
})();
