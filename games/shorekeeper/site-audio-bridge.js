/* Optional parent-controlled output trim. Standalone game output remains unchanged. */
(() => {
  if(window.parent===window)return;
  // Embedded games start silent until the active parent explicitly grants audio.
  let gain=0,stopped=false;const masters=new Map(),nativeConnect=window.AudioNode?.prototype.connect;
  function master(context){
    if(masters.has(context))return masters.get(context);
    const node=context.createGain();node.gain.value=gain;nativeConnect.call(node,context.destination);masters.set(context,node);return node;
  }
  if(nativeConnect)window.AudioNode.prototype.connect=function(destination,...args){
    // Only reroute final speaker connections, leaving Godot's internal buses alone.
    const final=destination===this.context.destination;const result=nativeConnect.call(this,final?master(this.context):destination,...args);return final?destination:result;
  };
  addEventListener('message',event=>{
    if(event.origin!==location.origin||event.source!==window.parent)return;
    if(event.data?.type==='tepo-site-audio-stop'){shutdown();return;}
    if(event.data?.type!=='tepo-site-audio'||stopped||!Number.isFinite(event.data.gain))return;
    gain=event.data.active===false?0:Math.min(1,Math.max(0,event.data.gain));
    masters.forEach((node,context)=>{if(gain===0){node.gain.cancelScheduledValues(context.currentTime);node.gain.value=0;}else node.gain.setTargetAtTime(gain,context.currentTime,.04);});
    window.TepoMusic?.setSiteGain(gain);
    report();
  });
  function report(){const media=[...document.querySelectorAll('audio,video')];window.parent.postMessage({type:'tepo-site-audio-state',gain,audibleMedia:media.filter(a=>!a.paused&&!a.muted&&a.volume>0).length,stopped},location.origin);}
  function shutdown(){
    if(stopped)return;stopped=true;gain=0;window.TepoMusic?.setSiteGain(0);window.TepoMusic?.stop();
    document.querySelectorAll('audio,video').forEach(a=>{a.muted=true;a.pause();});
    masters.forEach((node,context)=>{try{node.gain.cancelScheduledValues(context.currentTime);node.gain.value=0;}catch{}try{if(context.state!=='closed')context.close().catch(()=>{});}catch{}});
    report();
  }
  addEventListener('pagehide',shutdown);
  window.TepoSiteAudio={gain:()=>gain,shutdown};
  window.parent.postMessage({type:'tepo-site-audio-ready'},location.origin);
})();
