"""Build material-specific CC0 foley, keeping simple UI tones separate."""
from pathlib import Path
import array, hashlib, json, math, shutil, subprocess, wave
R=Path(__file__).resolve().parents[1]
F=R/'audio-source-v38'
OUT=R/'assets/audio/sfx'
FFMPEG=R.parent/'tools/audio-deps/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
RATE=24000
bank=json.loads((R/'assets/audio/sound-bank-v37.json').read_text(encoding='utf-8'))['sounds']
cache={}
def clip(pack,name):
    key=(pack,name)
    if key not in cache:
        raw=subprocess.check_output([str(FFMPEG),'-v','error','-i',str(F/pack/'Audio'/name),'-f','s16le','-ac','1','-ar',str(RATE),'-'])
        x=array.array('h');x.frombytes(raw);cache[key]=[v/32768 for v in x]
    return cache[key]
def save(name,label,parts,gain=.28):
    # Material tails may ring briefly; never truncate mid-wave or normalize each layer.
    end=max(at+len(clip(pack,file))/RATE for pack,file,at,level in parts)
    x=[0.0]*min(round((end+.025)*RATE),RATE*3)
    for pack,file,at,level in parts:
        for i,v in enumerate(clip(pack,file)):
            j=round(at*RATE)+i
            if j<len(x):x[j]+=v*level
    write(name,label,x,gain,{'kind':'foley','sources':[{'pack':p,'file':f} for p,f,_,_ in parts]})
def write(name,label,x,gain,extra):
    peak=max(abs(v) for v in x) or 1
    x=[v/peak*.68 for v in x]
    for i in range(min(200,len(x)//2)):x[i]*=i/200;x[-i-1]*=i/200
    file=OUT/(name+'-v38.wav')
    with wave.open(str(file),'wb') as w:w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(array.array('h',(round(v*32767) for v in x)).tobytes())
    bank[name]={'label':label,'src':str(file.relative_to(R)).replace('\\','/'),'gain':gain,'seconds':len(x)/RATE,**extra}
def one(name,label,pack,file,gain=.28):save(name,label,[(pack,file,0,1)],gain)
one('ui_click','버튼 · 짧은 선택음','interface','click_003.ogg',.14)
one('ui_back','뒤로가기 · 짧은 취소음','interface','back_001.ogg',.14)
one('map_select','지도 · 장소 선택음','interface','select_004.ogg',.16)
one('paper_open','일기장 · 책 펼치기','rpg','bookOpen.ogg',.25)
one('paper_close','일기장 · 책 덮기','rpg','bookClose.ogg',.23)
one('page_turn','일기장 · 실제 책장 넘기기','rpg','bookFlip2.ogg',.24)
one('card_slide','민증 · 카드 꺼내기','interface','switch_002.ogg',.18)
one('wallet_open','지갑 · 작은 가죽 물건','rpg','handleSmallLeather.ogg',.23)
save('bag_open','가방 · 버클과 가죽', [('rpg','metalClick.ogg',0,.5),('rpg','dropLeather.ogg',.10,.6)],.25)
one('bag_close','가방 · 버클 잠그기','rpg','beltHandle2.ogg',.23)
save('drawer_open','서랍 · 나무 손잡이 열기',[('rpg','creak1.ogg',0,.5),('impact','impactWood_light_001.ogg',.12,.4)],.22)
one('drawer_close','서랍 · 나무 닫힘','impact','impactWood_medium_001.ogg',.24)
one('frame_tap','액자 · 나무 프레임','impact','impactWood_light_004.ogg',.20)
one('stone_tap','테포 · 단단한 돌 접촉','impact','impactGeneric_light_002.ogg',.25)
save('stone_stir','테포 · 돌 몸을 뒤척임',[('impact','impactMining_002.ogg',0,.3),('impact','impactGeneric_light_003.ogg',.21,.5)],.24)
save('stone_wake','테포 · 돌 몸을 일으킴',[('impact','impactGeneric_light_004.ogg',0,.6),('impact','footstep_concrete_000.ogg',.17,.45)],.27)
one('pottery','뚝배기 · 가벼운 공명','impact','impactGlass_light_003.ogg',.20)
one('weapon_rack','벽걸이 무기 · 금속 접촉','impact','impactMetal_light_000.ogg',.24)
save('weapon_baton','삼단봉 · 철컥 펼침과 고정',[('rpg','metalClick.ogg',0,.6),('rpg','metalLatch.ogg',.14,.8),('impact','impactMetal_light_002.ogg',.26,.35)],.31)
one('weapon_bat','야구방망이 · 나무 울림','impact','impactWood_medium_002.ogg',.30)
save('weapon_unknown','곡날 무기 · 금속 스르릉',[('rpg','drawKnife2.ogg',0,.8),('impact','impactMetal_light_004.ogg',.20,.25)],.28)
save('weapon_mace','메이스 · 쇠뭉치와 걸쇠 금속',[('impact','impactMetal_heavy_002.ogg',0,.7),('rpg','metalLatch.ogg',.17,.45),('impact','impactPlate_light_004.ogg',.31,.25)],.33)
save('door_locked','잠긴 문 · 손잡이와 쇠 잠금장치',[('rpg','doorClose_2.ogg',0,.35),('rpg','metalLatch.ogg',.04,.65),('rpg','metalLatch.ogg',.26,.5)],.30)
save('lock_tap','자물쇠 · 철렁철렁',[('rpg','metalLatch.ogg',0,.6),('impact','impactMetal_light_001.ogg',.13,.45)],.28)
one('mace_swing','메이스 · 휘두름','rpg','knifeSlice.ogg',.24)
save('lock_break','자물쇠 · 금속 타격과 파편',[('impact','impactMetal_heavy_000.ogg',0,.7),('impact','impactPlate_medium_003.ogg',.06,.5),('rpg','metalClick.ogg',.32,.25)],.36)
one('door_open','문 · 나무문 열림','rpg','doorOpen_2.ogg',.25)
def region(name,freqs):
    x=[0.0]*round(.43*RATE)
    for k,f in enumerate(freqs):
        for i in range(round(.095*RATE)):
            t=i/RATE;at=round(k*.08*RATE)+i
            if at<len(x):
                # Original short pulse-wave regional transition, not a sampled game cue.
                v=math.sin(2*math.pi*f*t)+.20*math.sin(6*math.pi*f*t)+.06*math.sin(10*math.pi*f*t)
                x[at]+=v*min(1,t/.004)*math.exp(-t*31)*min(1,(.095-t)/.01)
    write(name,'地域',x,.22,{'kind':'original-synth','sources':[]})
region('area_enter',[493.88,659.25,880,1318.51]);bank['area_enter']['label']='이동 · 짧은 8비트 지역 전환'
region('area_exit',[1174.66,880,659.25,493.88]);bank['area_exit']['label']='복귀 · 짧은 8비트 지역 전환'
bank.pop('footsteps',None)
(R/'assets/audio/sound-bank-v38.json').write_text(json.dumps({'version':38,'sounds':bank},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
licenses=R/'assets/audio/licenses';licenses.mkdir(exist_ok=True)
for pack in ['interface','impact','rpg']:shutil.copy2(F/pack/'License.txt',licenses/('kenney-'+pack+'-CC0.txt'))
(licenses/'SOURCES.md').write_text('# Effect sources\n\nKenney CC0 packs, downloaded 2026-10-26. Only selected clips are shipped.\n\n- https://kenney.nl/assets/interface-sounds\n- https://kenney.nl/assets/impact-sounds\n- https://kenney.nl/assets/rpg-audio\n\nPer-cue original filenames, pack names, mix gain and duration are recorded in sound-bank-v38.json. Computer and radio electronics and regional transition cues are original synths. No Pokemon recording is used.\n',encoding='utf-8')
print(json.dumps({'effects':len(bank),'material_overrides':sum(v.get('kind')=='foley' for v in bank.values()),'max_seconds':max(v['seconds'] for v in bank.values())}))
