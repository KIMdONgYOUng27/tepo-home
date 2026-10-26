"""Original offline layered coastal foley; no downloaded samples or runtime synthesis."""
from pathlib import Path
import math, random, struct, wave, json

ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
IDS='sand pearl bowl kelp chain shell snack wave rain stone tetra heat gull_white gull_dark gull_union feather gust wing_union anchor water hit kill pick hurt level drop chest evolve win lose ui warning impact_light impact_heavy wing_drop food magnet freeze wipe xp coin relic revive boss_down chest_open reel_tick reel_stop treasure_1 treasure_3 treasure_5 water_start water_end enemy_shot bug_die shell_die kelp_die quad_die jelly_die human_die dash xp_collect'.split()
RATE=22050
TAU=math.tau
manifest=[]
melodies={'level':[0,4,7,12], 'evolve':[0,7,12,16,19], 'win':[0,4,7,12,19], 'chest':[0,7,12], 'treasure_1':[0,7,12], 'treasure_3':[0,4,7,12,16], 'treasure_5':[0,7,12,16,19,24], 'relic':[0,7,14], 'revive':[0,4,7,12]}
wet={'wave','rain','water','water_start','water_end','magnet','wipe','dash','wing_drop'}
metal={'chain','bowl','anchor','stone','shell','chest_open','shell_die'}
heavy={'tetra','impact_heavy','boss_down','drop','hurt','lose','heat'}
bright={'xp_collect','pick','xp','pearl','freeze','coin','reel_tick','reel_stop','ui','food'}
for index,name in enumerate(IDS):
    rng=random.Random('tepo-v15-'+name)
    dur=1.25 if name=='treasure_5' else (.85 if name in melodies else (.62 if name in heavy else (.42 if name in wet else (.15 if name in bright else .30))))
    if name=='warning': dur=.90
    if name=='xp_collect': dur=.14
    if name=='dash': dur=.30
    data=[]; low=mid=0.
    base=110+(index%9)*19
    for i in range(int(RATE*dur)):
        t=i/RATE; u=t/dur
        noise=rng.uniform(-1,1)
        low+=(noise-low)*.045
        mid+=(noise-mid)*.30
        attack=min(1,t/.004)
        tail=max(0,1-u)**1.6
        if name in melodies:
            v=0.
            notes=melodies[name]
            for n,step in enumerate(notes):
                local=t-n*dur*.72/len(notes)
                if local<0: continue
                f=261.626*2**(step/12)
                env=min(1,local/.006)*math.exp(-local*7)
                v+=env*(math.sin(TAU*f*local)*.29+math.sin(TAU*f*2*local)*.09+math.sin(TAU*f*3*local)*.025)
            v+=low*.45*math.exp(-t*8)
        elif name in wet:
            sweep=math.sin(math.pi*min(1,u*1.4))**.8
            v=(mid-low)*.85*sweep + low*2.8*sweep
            v+=math.sin(TAU*(80*t+145*t*t))*.22*math.exp(-t*8)
            for n in range(3 if name!='rain' else 6):
                local=t-n*dur*.13
                if local>=0:
                    f=460+n*95+(120 if name=='magnet' else 0)
                    v+=math.sin(TAU*(f*local-260*local*local))*.12*math.exp(-local*25)
            if name=='dash': v+=math.sin(TAU*(190*t-170*t*t))*.36*math.exp(-t*14)
        elif name in metal:
            partials=[(1,.43,13),(2.71,.20,23),(4.13,.10,35),(6.31,.035,50)]
            v=sum(math.sin(TAU*base*k*t)*a*math.exp(-t*d) for k,a,d in partials)
            v+=(mid-low)*.50*math.exp(-t*40)+low*.9*math.exp(-t*16)
            if name=='chain':
                for n in [1,2,3]:
                    local=t-n*.042
                    if local>=0: v+=math.sin(TAU*780*local)*.18*math.exp(-local*40)
                v+=mid*.5*math.sin(math.pi*u)
        elif name in heavy:
            v=math.sin(TAU*(90*t-42*t*t))*.70*math.exp(-t*9)
            v+=math.sin(TAU*47*t)*.20*math.exp(-t*10)
            v+=low*2.7*math.exp(-t*5)+(mid-low)*.65*math.exp(-t*24)
            for n in [1,2,3]:
                local=t-n*.045
                if local>=0: v+=mid*.18*math.exp(-local*35)
        elif name in bright:
            f={'xp_collect':660,'pick':660,'xp':520,'pearl':450,'freeze':740,'coin':880,'reel_tick':440,'reel_stop':620,'ui':360,'food':390}[name]
            decay=25 if name in ['xp_collect','pick','ui'] else 16
            v=math.sin(TAU*f*t)*.43*math.exp(-t*decay)
            v+=math.sin(TAU*f*2*t)*.12*math.exp(-t*(decay+14))
            v+=math.sin(TAU*f*3*t)*.035*math.exp(-t*55)
            v+=low*.1*math.exp(-t*60)
        elif name=='warning':
            local=t%.30
            env=min(1,local/.012)*math.exp(-local*14)
            v=(math.sin(TAU*196*t)*.43+math.sin(TAU*294*t)*.19)*env
        else:
            # Dry granular launch, body and short airy tail, tuned per material.
            grit=.85 if name=='sand' else .55
            v=(mid-low)*grit*math.exp(-t*22)+low*1.5*math.exp(-t*11)
            v+=math.sin(TAU*(base*t-105*t*t))*.38*math.exp(-t*17)
            if name in ['feather','gust','wing_union']: v+=mid*.6*math.sin(math.pi*u)
        data.append(v*attack*tail)
    # Offline low-pass, DC blocking and a soft limiter; bounded polyphony in game.
    cutoff=4200 if name in metal else (3600 if name in wet else 3100)
    alpha=1-math.exp(-TAU*cutoff/RATE)
    a=b=previous=dc=0.; processed=[]
    for v in data:
        a+=alpha*(v-a); b+=alpha*(a-b)
        dc=b-previous+.995*dc;previous=b
        processed.append(math.tanh(dc*1.35))
    peak=max(.001,max(abs(v) for v in processed))
    target=.70 if name=='xp_collect' else (.64 if name in ['ui','reel_tick','coin'] else .88)
    pcm=[round(v/peak*target*32767) for v in processed]
    with wave.open(str(ROOT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'))
        w.writeframes(struct.pack('<'+'h'*len(pcm),*pcm))
    manifest.append({'id':name,'seconds':dur,'revision':'v15-layered-coastal','original':True,'peak':max(abs(v) for v in pcm)/32767,'rms':(sum((v/32767)**2 for v in pcm)/len(pcm))**.5})
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Generated {len(IDS)} original layered SFX, bounded peak <= 0.88, {RATE} Hz mono PCM.')
