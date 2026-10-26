# Effect sources

Kenney CC0 packs, downloaded 2026-10-26. Only selected clips are shipped.

- https://kenney.nl/assets/interface-sounds
- https://kenney.nl/assets/impact-sounds
- https://kenney.nl/assets/rpg-audio

Per-cue original filenames, pack names, mix gain and duration are recorded in sound-bank-v38.json. Computer and radio electronics and regional transition cues are original synths. No Pokemon recording is used.

## v39 replacement recordings

- martinimeniscus, “Bat Hit 4 FF100.aif”, Freesound #162867. CC0. Source: https://freesound.org/people/martinimeniscus/sounds/162867/ . HQ preview converted to mono PCM, transient retained, dynamics compressed for short object playback.
- artisticdude, “RPG Sound Pack”, CC0. Source: https://opengameart.org/content/rpg-sound-pack . Selected sword-unsheathe, metal-ringing, metal-small and wood-small recordings. Mixes, silence trimming and dynamics edits are listed in scripts/build-foley-v39.py and sound-bank-v39.json.
- Radio connection: original deterministic band-limited noise bursts. Radio disconnect: original short clean 880Hz beep, no noise layer.

v39 uses real recorded material sounds for weapons and locks, rather than musical UI tones. Kenney CC0 sources above remain in use for books, stone, wood and UI.

## v40 wooden mechanisms

- Joseph SARDIN / BigSoundBank, Wooden drawer opening #1499 and closing #1500. CC0. https://bigsoundbank.com/wooden-drawer-opening-s1499.html and https://bigsoundbank.com/wooden-drawer-closing-s1500.html . Actual wooden rail sliding recordings, trimmed and gently compressed.
- artisticdude / RPG Sound Pack, world/door.wav. CC0. https://opengameart.org/content/rpg-sound-pack . Recorded creaky door, preserved hinge creak.

Edits and levels: scripts/build-foley-v40.py; final runtime cue metadata: sound-bank-v40.json.
