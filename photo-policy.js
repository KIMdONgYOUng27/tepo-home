/* Photo-only invitations never grant story items or complete an unplayed rescue. */
(() => {
  'use strict';
  function access(progress={}) {
    const invited=progress.photoFriendsInvited===true;
    const tepo=invited||progress.metTepo===true||progress.awake===true;
    const elpeng=invited||progress.elpengRescued===true;
    return {tepo,elpeng,any:tepo||elpeng,invited};
  }
  function cover(sw,sh,dx,dy,dw,dh) {
    const scale=Math.max(dw/sw,dh/sh),w=dw/scale,h=dh/scale;
    return [(sw-w)/2,(sh-h)/2,w,h,dx,dy,dw,dh];
  }
  function localPoint(item,x,y,width,height) {
    const angle=-item.angle*Math.PI/180,dx=x-item.x,dy=y-item.y;
    return {x:(Math.cos(angle)*dx-Math.sin(angle)*dy)*(item.flip?-1:1)/width+.5,
      y:(Math.sin(angle)*dx+Math.cos(angle)*dy)/height+.5};
  }
  function animationFrame(durations,elapsed,reduced=false) {
    if(reduced||!Array.isArray(durations)||!durations.length)return 0;
    const total=durations.reduce((a,b)=>a+b,0);if(total<=0)return 0;
    let time=Math.max(0,Number(elapsed)||0)%total;
    for(let i=0;i<durations.length;i++){if(time<durations[i])return i;time-=durations[i];}
    return durations.length-1;
  }
  window.TEPO_PHOTO_POLICY={access,cover,localPoint,animationFrame};
})();
