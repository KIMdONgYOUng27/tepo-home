from pathlib import Path
import json, math, random, wave, struct

ROOT=Path(__file__).parent.parent/'shorekeeper'
# v11: muted analog rewards, low wooden UI, material-preserving high-frequency control.
# Offline original procedural foley. No external recordings or music samples.
ids='sand pearl bowl kelp chain shell snack wave rain stone tetra heat gull_white gull_dark gull_union feather gust wing_union anchor water hit kill pick hurt level drop chest evolve win lose ui warning impact_light impact_heavy wing_drop food magnet freeze wipe xp coin relic revive boss_down chest_open reel_tick reel_stop treasure_1 treasure_3 treasure_5 water_start water_end enemy_shot bug_die shell_die kelp_die quad_die jelly_die human_die'.split()
out=ROOT/'assets/audio'; out.mkdir(exist_ok=True)
manifest=[]
for idx,name in enumerate(ids):
    rng=random.Random(name); rate=22050
    reward=name in ['level','evolve','win','chest','treasure_1','treasure_3','treasure_5','relic','revive']
    water=name in ['wave','rain','water','water_start','water_end','wing_drop','magnet','wipe']
    metal=name in ['chain','bowl','anchor','stone','shell','chest_open','shell_die']
    duration=1.25 if name=='treasure_5' else (.95 if name in ['treasure_3','evolve','warning'] else (.65 if reward or water else .22))
    if name in ['reel_tick','ui','coin','pick','hit']: duration=.075
    if name=='reel_stop': duration=.35
    freq=90+idx*23.7; lp=0.; samples=[]
    for i in range(int(rate*duration)):
        t=i/rate; u=t/duration; n=rng.uniform(-1,1); lp+= (n-lp)*(.08 if water else .45)
        env=min(1,t/.004)*max(0,1-u)**1.5
        if reward:
            melodies={'level':[0,7,10], 'evolve':[0,7,10,12,19], 'win':[0,7,12,10,12], 'chest':[0,7,10,7], 'treasure_1':[0,7], 'treasure_3':[0,7,10,12], 'treasure_5':[0,7,10,12,19], 'relic':[7,10,12], 'revive':[0,3,7,12]}
            notes=melodies[name]; ni=min(len(notes)-1,int(u*len(notes)))
            f=220*2**(notes[ni]/12)
            note_time=(u*len(notes))%1; local=t-ni*duration/len(notes)
            note_env=min(1,note_time/.10)*min(1,(1-note_time)/.18)
            v=(math.sin(math.tau*f*local)*.35+math.sin(math.tau*f*2*local)*.045)*note_env
        elif water:
            v=lp*2.3*(.65+.35*math.sin(t*(31+idx)))+math.sin(math.tau*(55+idx)*t)*.13*math.exp(-t*15)
        elif metal:
            v=sum(math.sin(math.tau*(freq*k)*t)*a*math.exp(-t*d) for k,a,d in [(1,.42,14),(2.73,.25,23),(4.11,.16,31)])+n*.18*math.exp(-t*40)
        elif name=='warning':
            pulse=min(1,(t%0.34)/.025)*math.exp(-(t%0.34)*13)
            v=(math.sin(math.tau*185*t)*.35+math.sin(math.tau*277*t)*.18)*pulse
        elif name in ['reel_tick','reel_stop','coin','pick','ui','xp','freeze','pearl','food']:
            tone={'reel_tick':420,'reel_stop':510,'coin':880,'pick':760,'ui':480,'xp':690,'freeze':820,'pearl':620,'food':370}[name]
            v=math.sin(math.tau*tone*t)*.34*math.exp(-t*30)+math.sin(math.tau*tone*1.93*t)*.035*math.exp(-t*50)+lp*.10*math.exp(-t*65)
        elif name in ['tetra','impact_heavy','boss_down','drop','hurt','lose']:
            v=math.sin(math.tau*(100*t-80*t*t))*.5*math.exp(-t*10)+lp*.65
        else:
            v=lp*.7*(.6+.4*math.sin(t*(80+idx*7)))+math.sin(math.tau*(freq*t-160*t*t))*.23*math.exp(-t*17)
        samples.append(v*env)
    # Offline two-stage low-pass, with a DC blocker, keeps the runtime cost unchanged.
    cutoff=3500 if metal or name in ['sand','shell','snack'] else (2800 if water else 2400)
    alpha=1-math.exp(-math.tau*cutoff/rate); a=b=prev=dc=0.; softened=[]
    for value in samples:
        a+=alpha*(value-a); b+=alpha*(a-b)
        dc=b-prev+.995*dc; prev=b; softened.append(dc)
    peak=max(max(abs(x) for x in softened),.01)
    gain={'ui':.65,'pick':.65,'coin':.62,'reel_tick':.48,'reel_stop':.78,'food':.72,'xp':.8,'freeze':.85,'pearl':.9}.get(name,.72 if reward else 1.)
    data=b''.join(struct.pack('<h',round(x/peak*25000*gain)) for x in softened)
    with wave.open(str(out/(name+'.wav')),'wb') as w:
        w.setparams((1,2,rate,0,'NONE','not compressed')); w.writeframes(data)
    manifest.append({'id':name,'seconds':duration,'file':name+'.wav','original':True,'revision':'v11-muted-coastal','gain':gain,'lowpass_hz':cutoff})
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')


print('Generated',len(ids),'distinct original effects')
