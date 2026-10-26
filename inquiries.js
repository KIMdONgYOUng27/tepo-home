(() => {
  let config;
  async function settings(){if(config)return config;const r=await fetch(new URL('config/inquiries.json?v=34',document.baseURI));if(!r.ok)throw new Error('문의 설정을 불러오지 못했어요.');config=await r.json();return config;}
  function validate(input){
    const item={inquiry_type:input.inquiry_type,name:String(input.name||'').trim(),email:String(input.email||'').trim(),subject:String(input.subject||'').trim(),message:String(input.message||'').trim(),source:input.source,consent:input.consent===true};
    if(!['general','production'].includes(item.inquiry_type)||!['chatbot','contact_page'].includes(item.source))throw new Error('문의 유형을 확인해 주세요.');
    if(!item.name||item.name.length>80)throw new Error('이름을 80자 이내로 입력해 주세요.');
    if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(item.email)||item.email.length>254)throw new Error('답변받을 이메일을 확인해 주세요.');
    if(item.subject.length>120||item.message.length<10||item.message.length>3000)throw new Error('내용은 10~3,000자, 제목은 120자 이내로 입력해 주세요.');
    if(!item.consent)throw new Error('문의 답변을 위한 정보 전달에 동의해 주세요.');return item;
  }
  async function submit(input){
    const item=validate(input),c=await settings();
    if(!c.enabled||!c.supabaseUrl||!c.publishableKey)return {ok:false,code:'NOT_CONFIGURED',message:'아직 문의 전송 연결 전이에요. 입력한 내용은 전송되거나 저장되지 않았어요.'};
    const url=new URL(c.supabaseUrl);if(url.protocol!=='https:'||!/^sb_publishable_/.test(c.publishableKey)||!/^[a-z][a-z0-9_]*$/.test(c.table))throw new Error('문의 연결 설정을 확인해 주세요.');
    const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),15000);
    try{const response=await fetch(url.origin+'/rest/v1/'+c.table,{method:'POST',headers:{apikey:c.publishableKey,'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify(item),signal:controller.signal});if(!response.ok)throw new Error('문의가 전송되지 않았어요. 잠시 후 다시 시도해 주세요.');return {ok:true,message:'문의가 접수됐어요. 남겨 주신 이메일로 답변드릴게요.'};}finally{clearTimeout(timeout);}
  }
  function mount(host,{source='chatbot',type='general',onTypeChange=()=>{}}={}){
    host.innerHTML='<form class="inquiry-form"><div class="inquiry-types"><button type="button" data-type="general">관리자 문의</button><button type="button" data-type="production">제작 문의</button></div><p class="inquiry-setup" role="status">문의 연결 상태를 확인하는 중…</p><label>이름<input name="name" autocomplete="name" maxlength="80" required></label><label>답변받을 이메일<input name="email" type="email" autocomplete="email" maxlength="254" required></label><label>제목<input name="subject" maxlength="120"></label><label>문의 내용<textarea name="message" rows="5" minlength="10" maxlength="3000" required placeholder="궁금한 점이나 제작 문의 내용을 남겨 주세요."></textarea></label><label class="inquiry-consent"><input name="consent" type="checkbox" required>이름·이메일·문의 내용을 문의 처리와 답변을 위해 전달하는 데 동의합니다.</label><input name="website" class="inquiry-honeypot" tabindex="-1" autocomplete="off" aria-hidden="true"><button type="submit" class="inquiry-submit">문의 보내기</button><p class="inquiry-result" role="status" aria-live="polite"></p></form>';
    const form=host.querySelector('form');let active=type;
    function setType(value){active=value;form.querySelectorAll('[data-type]').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.type===value)));onTypeChange(value);}
    form.querySelectorAll('[data-type]').forEach(button=>button.onclick=()=>setType(button.dataset.type));setType(type);
    settings().then(c=>form.querySelector('.inquiry-setup').textContent=c.enabled&&c.supabaseUrl&&c.publishableKey?'관리자에게 문의를 남겨 주세요.':'현재 전송 연결 전입니다. 입력한 정보는 서버에 저장되지 않습니다.').catch(error=>form.querySelector('.inquiry-setup').textContent=error.message);
    form.onsubmit=async event=>{event.preventDefault();const result=form.querySelector('.inquiry-result'),button=form.querySelector('[type=submit]');if(form.elements.website.value)return;button.disabled=true;result.textContent='전송 상태를 확인하는 중…';try{const response=await submit({inquiry_type:active,name:form.elements.name.value,email:form.elements.email.value,subject:form.elements.subject.value,message:form.elements.message.value,consent:form.elements.consent.checked,source});result.textContent=response.message;if(response.ok){window.TEPO_AUDIO?.play('notice_success');form.reset();setType(active);}}catch(error){window.TEPO_AUDIO?.play('error');result.textContent=error.name==='AbortError'?'연결 시간이 길어져 전송하지 못했어요. 내용을 확인한 뒤 다시 시도해 주세요.':error.message;}finally{button.disabled=false;}};
    return {setType};
  }
  window.TEPO_INQUIRIES={mount,submit,validate,settings};
})();
