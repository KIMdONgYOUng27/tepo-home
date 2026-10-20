// Authored dialogue and curated routes. Add new topics here without changing the renderer.
(() => {
  const rootChoices=[
    {label:'너 왜 그렇게 생겼니?',to:'appearance'},
    {label:'나 부산 여행하려고 하는데, 어디가 좋아?',to:'travel'},
    {label:'대화를 종료한다',to:'exit'}
  ];
  const nodes={
    greeting:{text:'안녕, 반가워! 무슨 일로 우리 집에 왔니?',choices:rootChoices},
    more:{text:'더 할 이야기 있어?',choices:rootChoices},
    appearance:{text:'내 모습이 좀 특이하지? 바닷가에서 본 테트라포드랑 닮았을 거야.\n그래도 돌덩이 취급은 하지 마. 나름 표정도 풍부하다고!',choices:[{label:'테트라포드가 뭔데?',to:'tetrapod'},{label:'그 뚝배기는 왜 쓰고 다녀?',to:'hat'},{label:'그럼 왜 등대에 살아?',to:'home'},{label:'그렇구나. 다른 얘기 하자.',to:'more'}]},
    tetrapod:{text:'방파제 쪽에 모여 있는, 여러 방향으로 다리가 뻗은 콘크리트 블록 말이야. 파도의 힘을 줄이는 역할을 하지.\n내 사진 액자에도 있잖아. 꽤 멋있지?',choices:[{label:'그럼 너도 파도를 막아?',to:'wave'},{label:'모자 얘기도 들려줘.',to:'hat'},{label:'이제 알겠어.',to:'more'}]},
    wave:{text:'난 일단 내 낮잠을 방해하는 소리부터 막고 싶은데… 방금 누가 깨웠더라?\n아무튼 진짜 테트라포드는 멀리서 구경하자. 사진은 안전한 산책길에서 찍어도 멋지니까.',choices:[{label:'미안, 잠은 잘 잤어?',to:'sleep'},{label:'그럼 여행지 추천 좀 해줘.',to:'travel'},{label:'알겠어. 다른 얘기 하자.',to:'more'}]},
    hat:{text:'뚝배기처럼 보여도 내가 쓰고 다니는 모자야. 벗어 놓으면 머리가 좀 허전하거든.\n국밥 담는 용도로 빌려 달라는 말은 하지 마.',choices:[{label:'국밥 좋아하나 보네?',to:'gukbap'},{label:'그럼 집은 왜 등대야?',to:'home'},{label:'잘 어울리네.',to:'hatThanks'}]},
    hatThanks:{text:'그렇지? 역시 알아보는 사람이 있다니까.\n나갈 때 내 모자까지 챙겨 가는 건 아니지?',choices:[{label:'구경만 할게.',to:'more'}]},
    home:{text:'바다가 가까워서 좋아. 밖을 보면 파도가 있고, 안에는 컴퓨터랑 일기장이 있지.\n멀리 놀러 안 나가도 꽤 바쁜 집이야. 물론 낮잠 잘 시간은 꼭 남겨 둬야 하고.',choices:[{label:'컴퓨터로 뭐 해?',to:'computer'},{label:'일기장도 써?',to:'diary'},{label:'낮잠이 그렇게 좋아?',to:'sleep'},{label:'집 구경 잘할게.',to:'more'}]},
    computer:{text:'짧은 영상도 보고, 긴 영상도 봐. 내 컴퓨터의 직박구리 폴더를 열어 봐.\n뭘 기대하는지는 모르겠지만, 일단 내 영상이 들어 있어.',choices:[{label:'나중에 열어볼게.',to:'more'},{label:'일기장에는 뭐가 있는데?',to:'diary'}]},
    diary:{text:'먹고, 돌아다니고, 가끔은 좀 억울했던 날들?\n말로 하면 길어지니까 오른쪽 탁자 위 일기장을 봐. 그림으로 남겨 놨어.',choices:[{label:'그림 일기구나. 읽어볼게.',to:'more'},{label:'먹는 얘기라면 국밥?',to:'gukbap'}]},
    sleep:{text:'파도 소리를 듣다가 눈만 잠깐 감은 건데… 어느새 푹 잤네.\n이미 깼으니까 괜찮아. 이제 궁금한 거 물어봐.',choices:[{label:'그럼 부산 여행 얘기 좀 하자.',to:'travel'},{label:'다른 것도 물어볼게.',to:'more'}]},
    gukbap:{text:'뜨끈한 국물에 밥 말아 먹으면 든든하잖아. 쿠폰 도장도 괜히 모으는 게 아니라고.\n부산에서 뭘 먹을지 고민 중이면 먹거리 코스부터 골라 봐.',choices:[{label:'좋아, 여행 코스 추천해줘.',to:'travel'},{label:'쿠폰은 구경만 할게.',to:'more'}]},
    goodbye:{text:'그래 또 궁금한 게 있으면 물어보고 내 집이다 생각하고 편하게 있어~',choices:[{label:'대화 마치기',to:'close'}]}
  };
  const types={
    sea:{label:'바다 보면서 걷는 게 좋아.',title:'바다 산책',intro:'그럼 바다부터 보자! 해운대 쪽에서 시작해서, 욕심내기보다 해안 풍경을 천천히 보는 쪽으로 짜 줄게.',tip:'동백섬에는 해안 산책로가 있어. 광안리까지 가는 코스라면 마지막 구간은 버스나 택시 등으로 이동하자.',source:{label:'동백해안산책로 · 비짓부산',url:'https://visitbusan.net/index.do?contentsSid=22&lang_cd=ko&uc_seq=284'},stops:[
      ['해운대해수욕장','모래사장과 바다를 보며 가볍게 시작해.'],['동백섬 해안산책로','해운대 서쪽 끝에서 이어지는 해안 풍경을 걸어 봐.'],['마린시티 해안가','도시 건물과 바다가 함께 보이는 산책으로 이어 가자.'],['광안리해수욕장','교통편으로 이동해서 광안대교가 보이는 해변에서 마무리해.']
    ]},
    food:{label:'먹는 게 여행의 제일 큰 목적이야.',title:'원도심 먹거리',intro:'좋아, 배부터 채우자! 여기저기 멀리 다니기보다는 남포동과 시장 골목을 묶어 볼게. 처음부터 너무 많이 먹으면 안 된다?',tip:'국제시장과 부평깡통시장은 서로 붙어 있어. 낮 시장과 야시장 분위기는 다르니 가려는 점포의 영업시간은 따로 확인해.',source:{label:'부평깡통시장 · 비짓부산',url:'https://www.visitbusan.net/kr/index.do?lang_cd=ko&menuCd=DOM_000000201003001000&uc_seq=400'},stops:[
      ['BIFF광장 일대','주변 먹거리를 둘러보며 가볍게 시작해.'],['부평깡통시장','마음에 드는 분식과 간식을 골라 먹어 봐.'],['국제시장 골목','시장 구경을 하면서 잠깐 소화시키자.'],['용두산공원','식사 뒤에는 공원 쪽으로 산책하며 마무리해. 오르막 구간은 감안하고!']
    ]},
    photo:{label:'사진 찍고 예쁜 풍경 보는 게 좋아.',title:'영도 바다와 골목',intro:'사진파구나? 그럼 흰여울문화마을 쪽으로 가 보자. 바다랑 골목을 한 번에 담기 좋아. 주민들이 사는 동네라는 건 잊지 말고!',tip:'흰여울과 해안산책로 사이에는 계단과 경사가 있어. 편한 신발을 신고, 사유지와 주민의 집 앞은 조용히 지나가자.',source:{label:'흰여울문화마을 · 비짓부산',url:'https://www.visitbusan.net/index.do?lang_cd=ko&menuCd=DOM_000000201001001000&uc_seq=305'},stops:[
      ['흰여울문화마을 골목','골목을 천천히 걸으며 바다가 열리는 풍경을 찾아봐.'],['흰여울 바다 전망 카페','마음에 드는 카페에서 쉬면서 찍은 사진도 골라 보자.'],['절영해안산책로','계단으로 내려가 해안 풍경을 다른 높이에서 담아 봐.'],['남포동 일대','버스나 택시로 이동해서 도시 골목 풍경과 저녁 식사로 마무리하자.']
    ]},
    cafe:{label:'카페랑 소품 구경하면서 느긋하게 놀래.',title:'전포와 서면 골목',intro:'그럼 전포로 가자. 카페 하나 제대로 고르고, 근처 골목을 걸어 보는 거야. 오늘 커피 몇 잔 마실지는 네가 정하고!',tip:'전포는 옛 공구·철물 가게와 개성 있는 카페가 어우러진 동네야. 개별 카페와 가게의 휴무일은 방문 전에 확인해.',source:{label:'전포카페거리 · 부산관광공사',url:'https://www.visitbusan.net/archive/dataSearch/view.nm?dataSid=METADATA001738&lng=ko'},stops:[
      ['전포카페거리','취향에 맞는 카페를 골라 한 템포 쉬어 가자.'],['전포 골목의 작은 가게들','문을 연 소품 가게와 골목을 구경해 봐.'],['서면 일대','식사와 쇼핑을 더하고 싶으면 서면 쪽으로 이어 가자.'],['부전시장','시장 구경으로 동네의 다른 표정까지 보고 마무리해.']
    ]}
  };
  function makeRoute({type,duration,pace}){
    if(!types[type]||!['half','day'].includes(duration)||!['slow','full'].includes(pace))throw new Error('Invalid trip preferences');
    const item=types[type],count=duration==='half'?(pace==='slow'?2:3):(pace==='slow'?3:4);
    return {title:item.title+' 코스',summary:(duration==='half'?'반나절':'하루')+' · '+(pace==='slow'?'느긋하게':'알차게'),intro:duration==='half'?'반나절이면 한 동네에 집중하자. 이 순서로 둘러보면 어때?':'하루라면 식사와 쉬는 시간도 남겨 두자. 이 순서로 돌아보는 걸 추천해.',stops:item.stops.slice(0,count).map(([name,detail])=>({name,detail})),tip:item.tip,source:item.source,closing:pace==='slow'?'좋은 데서 오래 쉬어도 돼. 전부 도는 것보다 마음에 드는 순간을 남기는 게 좋지.':'순서는 이렇게 잡되, 피곤하면 마지막 장소는 빼도 돼. 여행이 숙제는 아니잖아!'};
  }
  window.TEPO_DIALOGUE={nodes,types,makeRoute};
})();
