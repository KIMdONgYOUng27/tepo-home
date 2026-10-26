"""Replace only drawer/door cues with CC0 recordings of the actual mechanisms."""
from pathlib import Path
import array, json, math, subprocess, wave

R = Path(__file__).resolve().parents[1]
FFMPEG = R.parent/'tools/audio-deps/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
RATE = 24000
bank = json.loads((R/'assets/audio/sound-bank-v39.json').read_text(encoding='utf-8'))

def render(name, label, source, gain, author, page):
    raw = subprocess.check_output([str(FFMPEG), '-v', 'error', '-i', str(R/source),
        '-af', 'highpass=f=65,lowpass=f=6500', '-ac', '1', '-ar', str(RATE), '-f', 's16le', '-'])
    pcm = array.array('h'); pcm.frombytes(raw)
    peak = max(map(abs, pcm)) or 1
    active = [i for i, v in enumerate(pcm) if abs(v) > peak*.008]
    start, end = max(0, active[0]-120), min(len(pcm), active[-1]+240)
    # Keep the complete wood slide/hinge creak, rather than a short wooden knock.
    x = [math.copysign((abs(v)/peak)**.78, v) for v in pcm[start:end]]
    x += [0.0]*240
    for i in range(min(36,len(x)//2)): x[i] *= i/36
    for i in range(min(240,len(x)//2)): x[-i-1] *= i/240
    peak = max(map(abs,x)) or 1
    x = [v/peak*.78 for v in x]
    target = R/'assets/audio/sfx'/f'{name}-v40.wav'
    with wave.open(str(target),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'))
        w.writeframes(array.array('h',(round(v*32767) for v in x)).tobytes())
    bank['sounds'][name] = dict(label=label, src=target.relative_to(R).as_posix(), gain=gain,
        seconds=len(x)/RATE, kind='foley', sources=[dict(file=Path(source).name,author=author,url=page,license='CC0')])

render('drawer_open','서랍 · 나무 레일 드르륵 열기','audio-source-v40/wooden-drawer-opening-1499.wav',.42,
       'Joseph SARDIN','https://bigsoundbank.com/wooden-drawer-opening-s1499.html')
render('drawer_close','서랍 · 나무 레일 밀어 닫기','audio-source-v40/wooden-drawer-closing-1500.wav',.38,
       'Joseph SARDIN','https://bigsoundbank.com/wooden-drawer-closing-s1500.html')
render('door_open','문 · 나무문 경첩 끼이익','audio-source-v39/artisticdude/RPG Sound Pack/world/door.wav',.36,
       'artisticdude','https://opengameart.org/content/rpg-sound-pack')
bank['version'] = 40
(R/'assets/audio/sound-bank-v40.json').write_bytes((json.dumps(bank,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:dict(seconds=v['seconds'],gain=v['gain']) for k,v in bank['sounds'].items() if k in ['drawer_open','drawer_close','door_open']}))
