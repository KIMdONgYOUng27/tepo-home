"""Build material-specific CC0 foley, keeping simple UI tones separate."""
from pathlib import Path
import array, hashlib, json, math, random, shutil, subprocess, wave
R=Path(__file__).resolve().parents[1]
F=R/'audio-source-v38'
OUT=R/'assets/audio/sfx'
FFMPEG=R.parent/'tools/audio-deps/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
RATE=24000
bank=json.loads((R/'assets/audio/sound-bank-v37.json').read_text(encoding='utf-8'))['sounds']
cache={}
def source_path(pack,name):
    if pack=='artisticdude': return R/'audio-source-v39/artisticdude/RPG Sound Pack'/name
    if pack=='baseball': return R/'audio-source-v39'/name
    return F/pack/'Audio'/name
def clip(pack,name):
    key=(pack,name)
    if key not in cache:
        raw=subprocess.check_output([str(FFMPEG),'-v','error','-i',str(source_path(pack,name)),'-f','s16le','-ac','1','-ar',str(RATE),'-'])
        x=array.array('h');x.frombytes(raw)
        samples=[v/32768 for v in x]
        peak=max(map(abs,samples)) or 1
        active=[i for i,v in enumerate(samples) if abs(v)>peak*.009]
        if active: samples=samples[max(0,active[0]-48):min(len(samples),active[-1]+240)]
        cache[key]=[v/peak for v in samples]
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
    if extra.get('kind')=='foley':
        # Lift the body of brief impacts instead of only making their peak louder.
        p=max(map(abs,x)) or 1
        power=.55 if name=='weapon_bat' else .66
        x=[math.copysign((abs(v)/p)**power,v) for v in x]
    # Preserve recorded impact attack. Fade first, then normalize; never erase a 7ms click.
    for i in range(min(6,len(x)//2)): x[i]*=i/6
    for i in range(min(120,len(x)//2)): x[-i-1]*=i/120
    peak=max(abs(v) for v in x) or 1
    x=[v/peak*.78 for v in x]
    file=OUT/(name+'-v39.wav')
    with wave.open(str(file),'wb') as w:w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(array.array('h',(round(v*32767) for v in x)).tobytes())
    bank[name]={'label':label,'src':str(file.relative_to(R)).replace('\\','/'),'gain':gain,'seconds':len(x)/RATE,**extra}
def one(name,label,pack,file,gain=.28):save(name,label,[(pack,file,0,1)],gain)
one('ui_click','버튼 · 짧은 선택음','interface','click_001.ogg',.40)
one('ui_back','뒤로가기 · 짧은 취소음','interface','back_001.ogg',.14)
one('map_select','지도 · 장소 선택음','interface','select_004.ogg',.16)
one('paper_open','일기장 · 책 펼치기','rpg','bookOpen.ogg',.25)
one('paper_close','일기장 · 책 덮기','rpg','bookClose.ogg',.23)
one('page_turn','일기장 · 실제 책장 넘기기','rpg','bookFlip2.ogg',.24)
one('card_slide','민증 · 카드 꺼내기','interface','switch_002.ogg',.18)
one('wallet_open','지갑 · 작은 가죽 물건','rpg','handleSmallLeather.ogg',.23)
save('bag_open','가방 · 버클과 가죽', [('rpg','metalClick.ogg',0,.5),('rpg','dropLeather.ogg',.10,.6)],.25)
one('bag_close','가방 · 버클 잠그기','rpg','beltHandle2.ogg',.23)
save('drawer_open','서랍 · 나무 손잡이 열기',[('artisticdude','inventory/wood-small.wav',0,.8),('impact','footstep_wood_002.ogg',.14,.25),('impact','impactWood_light_001.ogg',.32,.35)],.38)
one('drawer_close','서랍 · 나무 닫힘','impact','impactWood_medium_001.ogg',.36)
one('frame_tap','액자 · 나무 프레임','impact','impactWood_light_004.ogg',.46)
one('stone_tap','테포 · 단단한 돌 접촉','impact','impactGeneric_light_002.ogg',.50)
save('stone_stir','테포 · 돌 몸을 뒤척임',[('impact','impactMining_002.ogg',0,.3),('impact','impactGeneric_light_003.ogg',.21,.5)],.50)
save('stone_wake','테포 · 돌 몸을 일으킴',[('impact','impactGeneric_light_004.ogg',0,.6),('impact','footstep_concrete_000.ogg',.17,.45)],.50)
one('pottery','뚝배기 · 가벼운 공명','impact','impactGlass_light_003.ogg',.20)
one('weapon_rack','벽걸이 무기 · 금속 접촉','impact','impactMetal_light_000.ogg',.24)
save('weapon_baton','삼단봉 · 철컥 펼침과 고정',[('artisticdude','inventory/metal-small1.wav',0,.6),('artisticdude','inventory/metal-small2.wav',.10,1),('impact','impactMetal_light_002.ogg',.21,.4)],.40)
one('weapon_bat','야구방망이 · 공을 치는 타격음','baseball','baseball-bat-martinimeniscus.mp3',.48)
save('weapon_unknown','곡날 무기 · 금속 스르릉',[('artisticdude','battle/sword-unsheathe.wav',0,1)],.42)
save('weapon_mace','메이스 · 쇠뭉치와 걸쇠 금속',[('artisticdude','inventory/metal-ringing.wav',0,1),('impact','impactMetal_heavy_004.ogg',0,.65)],.46)
save('door_locked','잠긴 문 · 손잡이와 쇠 잠금장치',[('artisticdude','inventory/metal-small1.wav',0,.9),('artisticdude','inventory/metal-small3.wav',.17,.7),('artisticdude','inventory/chainmail1.wav',.29,.3)],.42)
save('lock_tap','자물쇠 · 철렁철렁',[('artisticdude','inventory/metal-small2.wav',0,1),('artisticdude','inventory/metal-small1.wav',.14,.65)],.42)
one('mace_swing','메이스 · 휘두름','rpg','knifeSlice.ogg',.24)
save('lock_break','자물쇠 · 금속 타격과 파편',[('impact','impactMetal_heavy_004.ogg',0,.9),('artisticdude','inventory/metal-ringing.wav',.025,.6),('artisticdude','inventory/metal-small3.wav',.24,.4)],.46)
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

# Radio tuning is non-pitched band-limited crackle, while disconnect is a clean short beep.
rng=random.Random(39)
x=[];low=0.;smooth=0.
for i in range(round(.34*RATE)):
    t=i/RATE
    white=rng.uniform(-1,1);low+=.10*(white-low);smooth+=.70*(white-low-smooth)
    burst=sum(a*math.exp(-((t-c)/w)**8) for c,w,a in [(.055,.04,.65),(.15,.045,1),(.25,.045,.75)])
    crack=(rng.uniform(-1,1) if rng.random()<.008 else 0)*.8
    x.append((smooth*burst+crack)*min(1,t/.006)*min(1,(.34-t)/.025))
write('radio_on','무전 연결 · 짧은 치지직',x,.30,{'kind':'original-noise','sources':[]})
x=[]
for i in range(round(.16*RATE)):
    t=i/RATE
    x.append((math.sin(2*math.pi*880*t)+.12*math.sin(2*math.pi*1760*t))*min(1,t/.006)*math.exp(-t*24))
write('radio_off','무전 종료 · 짧은 수신 종료음',x,.27,{'kind':'original-synth','sources':[]})

bank.pop('footsteps',None)
(R/'assets/audio/sound-bank-v39.json').write_text(json.dumps({'version':39,'sounds':bank},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'effects':len(bank),'version':39}))
