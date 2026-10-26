/* JSON-driven routing; authored text and next-step buttons live in data/. */
(() => {
  const normalize=value=>value.normalize('NFKC').toLowerCase().replace(/\s+/g,'');
  const matches=(patterns,text)=>patterns?.some(pattern=>new RegExp(pattern).test(text));
  const data=()=>window.TEPO_DIALOGUE.data;
  const node=id=>data().nodes.find(item=>item.id===id);
  function response(item,extra={}){return {text:item.answer,suggestions:item.buttons.map(button=>button.label),buttons:item.buttons,intent:item.id,next:item.next,...extra};}
  function answer(input,context={},progress={},target){
    const d=data();if(!d)throw new Error('Dialogue data not ready');const text=normalize(input);
    const foodTravel=matches(d.travel.foodRequestKeywords,text)||context.trip&&matches(d.travel.foodChoiceKeywords,text);
    let item=target&&node(target);
    if(!item)item=d.nodes.find(item=>item.keywords.length&&(!item.requires||context[item.requires])&&!matches(item.exclude,text)&&!(item.food&&foodTravel&&!['meal','favorite-food'].includes(item.id))&&matches(item.keywords,text));
    if(!item&&context.trip&&matches(d.travel.continuationKeywords,text))item=node('travel');
    item=item||node('fallback');
    if(item.action==='travel'){
      const trip={type:null,duration:null,pace:null,...context.trip};
      for(const key of ['types','duration','pace']){const choice=d.travel[key].find(choice=>matches(choice.keywords,text));if(choice)trip[key==='types'?'type':key]=choice.value;}
      if(!trip.type)return response(node('trip-type'),{context:{trip}});
      if(!trip.duration)return response(node('trip-time'),{context:{trip}});
      if(!trip.pace)return response(node('trip-pace'),{context:{trip}});
      const route=window.TEPO_DIALOGUE.makeRoute(trip),result=node('trip-result');
      const values={...route,stops:route.stops.map((stop,index)=>(index+1)+'. '+stop.name+'\n'+stop.detail).join('\n\n')};
      return response(result,{text:result.answer.replace(/\{(\w+)\}/g,(_,key)=>values[key]||''),context:{lastTrip:trip},route});
    }
    if(item.action==='saveCourse')return context.lastTrip?response(item,{saveTrip:context.lastTrip}):answer(node('travel').question,{},progress,'travel');
    if(item.action==='lock')return response(item,{text:progress.arcadeUnlocked?item.answerUnlocked:item.answer});
    if(item.action==='faq')return response(item,{showFaq:true});
    if(item.action==='inquiry')return response(item,{showInquiry:item.inquiryType});
    return response(item,item.id==='fallback'&&context.trip?{context}:{});
  }
  window.TEPO_RADIO_DIALOGUE={answer,get suggestions(){return data()?.defaultButtons.map(button=>button.label)||[];},get buttons(){return data()?.defaultButtons||[];},get faq(){return data()?.faq||[];},get ui(){return data()?.ui||{};}};
})();
