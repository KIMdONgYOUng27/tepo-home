# Local audio revision v39

Not published. Runtime and preview both load sound-bank-v39.json.

- Metal: locks, mace and blade now use artisticdude CC0 recorded metal/unsheathing, no melody overlay. Baton uses distinct short metal contacts.
- Bat: real baseball bat hit, martinimeniscus CC0; not a generic wood knock.
- Drawer: wood contact only; removed creaking door recording.
- Radio: brief band-limited crackle on connection; clean quiet short beep on disconnect.
- Stone, frame, select: increased gains and restored clipped attack. Foley body compressed gently to remain audible at the normal 55% SFX setting.
- Fixed prior 8.3ms fade erasing short impacts: 0.25ms attack fade, normalize after fading, 0.78 peak headroom. No clipping.
- Existing mute, game shutdown and single-event routing preserved.

Build: Python scripts/build-foley-v39.py (requires existing ffmpeg and source packs).
Sources: assets/audio/licenses/SOURCES.md. Source archives stay local; only selected PCM files and credits deploy.
