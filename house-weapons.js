(() => {
  const source='assets/room-weapons-alpha-v18.png';
  const items=[
    {id:'baton',label:'삼단봉',description:'길이가 접히는 금속 곤봉. 손잡이에 테포의 손때가 묻어 있다.',box:[1012,173,17,202],points:'2,0 14,0 14,62 10,64 10,187 15,191 14,199 7,202 0,198 0,191 5,187 5,64 1,62'},
    {id:'bat',label:'야구방망이',description:'오래된 나무 야구방망이. 야구공은 어디에도 보이지 않는다.',box:[1083,153,30,223],points:'7,0 24,0 26,9 20,14 20,65 29,186 29,211 25,220 7,223 1,216 0,199 10,67 10,14 4,10'},
    {id:'unknown',label:'정체불명의 무기',description:'초승달 모양의 낯선 물건. 장식인지 무기인지 테포에게 물어봐야겠다.',box:[1149,178,73,185],points:'29,0 42,0 43,110 62,121 71,145 68,164 54,179 36,184 49,165 50,145 38,132 20,130 9,145 6,160 0,146 4,126 25,110 30,102'},
    {id:'mace',label:'메이스',description:'묵직한 쇠뭉치가 달린 철퇴. 손잡이에 테포의 손때가 묻어 있다.',box:[1242,178,75,185],points:'28,0 44,0 44,99 49,105 44,116 58,118 64,126 74,132 65,143 74,154 61,160 64,174 48,173 38,185 28,173 14,175 13,161 0,154 8,143 0,132 16,122 25,116 24,103 29,99'}
  ];
  const crops=[[240,37,77,704],[673,27,130,726],[1077,45,291,696],[1572,51,298,697]];
  items.forEach((item,index)=>{item.crop=crops[index];});
  let serial=0;
  function picture(item){
    const [x,y,w,h]=item.crop,id='weapon-cutout-'+serial++;
    return `<svg class="weapon-picture" viewBox="0 0 ${w} ${h}" aria-hidden="true"><defs><clipPath id="${id}"><rect width="${w}" height="${h}"/></clipPath></defs><image href="${source}" x="${-x}" y="${-y}" width="1999" height="787" clip-path="url(#${id})"/></svg>`;
  }
  const ready=(async()=>{
    const image=new Image();image.src=source;await image.decode();
    const canvas=document.createElement('canvas');canvas.width=image.naturalWidth;canvas.height=image.naturalHeight;const context=canvas.getContext('2d',{willReadFrequently:true});context.drawImage(image,0,0);
    items.forEach(item=>{const [x,y,w,h]=item.crop,pixels=context.getImageData(x,y,w,h).data,runs=[];
      for(let row=0;row<h;row+=2){let start=-1;for(let col=0;col<=w;col++){const solid=col<w&&pixels[(row*w+col)*4+3]>48;if(solid&&start<0)start=col;if(!solid&&start>=0){runs.push(`M${start} ${row}h${col-start}v${Math.min(2,h-row)}h${start-col}Z`);start=-1;}}}item.hit=runs.join('');
    });
  })();
  window.TEPO_WEAPONS={items,source,picture,ready};
})();
