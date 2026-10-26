/* General UI foley. Successful pickups and timed story actions have explicit hooks. */
(() => {
  function cue(button){
    if(button.dataset.sound)return button.dataset.sound==='none'?null:button.dataset.sound;
    if(button.matches('[data-world-audio]')||button.closest('#world-audio-settings'))return null;
    if(button.matches('#tepo,.take-weapon,.take-translator,.entrance-door,.entrance-lock,.radio-close,.radio-finish,.radio-send,.radio-suggestions button,.radio-faq button,[data-tepo-radio],.radio-bag-connect,.close-view,.adventure-close,.audio-close,.place-go'))return null;
    const object=button.dataset.object;
    if(object)return ({computer:'computer_boot',diary:'paper_open',wallet:'wallet_open',photo:'frame_tap',hat:'pottery',drawer:'drawer_open',baton:'weapon_baton',bat:'weapon_bat',unknown:'weapon_unknown',mace:'weapon_mace'})[object]||null;
    if(button.matches('[data-world-bag]'))return 'bag_open';
    if(button.matches('.mysterious-machine'))return 'device_pickup';
    if(button.matches('.wallet-item-identity'))return 'card_slide';
    if(button.matches('.wallet-return,.course-return,.weapon-back,.place-stay,.place-dismiss'))return 'ui_back';
    if(button.matches('.wallet-item,.cash-compartment,.cash-bill,.previous-page,.next-page,.story-list button'))return 'page_turn';
    if(button.matches('[data-open-archive],[data-folder],.video-files button,.archive-close,.window-close'))return 'folder_open';
    if(button.matches('.sacred-machine'))return 'arcade_ready';
    if(button.matches('.game-exit'))return 'game_exit';
    if(button.matches('.game-retry'))return 'ui_click';
    if(button.matches('.destination'))return 'map_select';
    if(button.matches('.radio-controls button,.radio-bottom-menu button,.talk-choice,.bag-filters button,.bag-pagination button,.adventure-actions button,.inquiry-types button,.inquiry-submit,#world-welcome button'))return 'ui_click';
    return null;
  }
  document.addEventListener('click',event=>{const button=event.target.closest('button');if(!button||button.disabled)return;const sound=cue(button);if(sound)window.TEPO_AUDIO?.play(sound);},true);
  document.addEventListener('close',event=>{
    const modal=event.target;if(modal.id==='world-bag-dialog')window.TEPO_AUDIO?.play('bag_close');
    else if(modal.id==='tepo-radio-dialog')window.TEPO_AUDIO?.play(modal.classList.contains('face-conversation')?'ui_back':'radio_off');
    else if(modal.id==='object-dialog')window.TEPO_AUDIO?.play(modal.classList.contains('view-computer')?'computer_off':modal.classList.contains('view-drawer')?'drawer_close':modal.classList.contains('view-wallet')?'wallet_open':modal.classList.contains('view-diary')?'paper_close':'ui_back');
  },true);
})();
