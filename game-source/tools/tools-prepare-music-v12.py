from pathlib import Path
import sys,subprocess,json,wave
root=Path(__file__).parent.parent
sys.path.insert(0,str(root/'tools/audio-deps'))
import imageio_ffmpeg
exe=imageio_ffmpeg.get_ffmpeg_exe()
out=root/'shorekeeper/assets/music'
out.mkdir(exist_ok=True)
manifest=[]
for name,stem in [('타이틀','title'),('일반 전투','combat'),('후반 전투','late'),('보스전','boss')]:
    src=(Path(sys.argv[1]) if len(sys.argv)>1 else root/'music-input')/(name+'.wav')
    with wave.open(str(src)) as w: duration=w.getnframes()/w.getframerate()
    dest=out/(stem+'.ogg')
    filters=f'loudnorm=I=-18:TP=-2:LRA=9,afade=t=in:st=0:d=0.025,afade=t=out:st={duration-.08}:d=0.08'
    subprocess.run([exe,'-hide_banner','-loglevel','error','-y','-i',str(src),'-af',filters,'-ar','44100','-ac','2','-c:a','libvorbis','-q:a','4','-map_metadata','-1',str(dest)],check=True)
    manifest.append({'id':stem,'source':name+'.wav','seconds':duration,'bytes':dest.stat().st_size,'normalization_target':'-18 LUFS / -2dBTP / LRA9','edge_fades_ms':[25,80]})
    print(stem,dest.stat().st_size)
(out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
