window.TEPO_INQUIRIES.mount(document.querySelector('#contact-form'),{source:'contact_page',type:new URLSearchParams(location.search).get('type')==='production'?'production':'general'});
