# 테포의 부산

종이 탐험 지도에서 등대로 들어가 테포의 방을 둘러보는 정적 웹사이트입니다.

공개 사이트: https://kimdongyoung27.github.io/tepo-home/

- 지도: 장소별 PNG 외곽에 반응하는 확대와 발광, 등대 입장
- 방: 컴퓨터 영상 폴더, 그림 일기장, 액자, 모자, 무기 모음과 지갑
- 테포: 네 번 연속 클릭해 깨우기, 서랍에서 얻는 소통 기계, 선택지 대화
- 여행: 취향·시간·속도별 부산 코스 추천, 손글씨 코스 종이 받기와 가방 보관
- 진행 상황은 현재 브라우저의 localStorage에 저장됩니다. 로컬 미리보기와 공개 사이트의 진행 상황은 서로 다릅니다.

HTML/CSS/JavaScript 정적 사이트로 별도 빌드 없이 실행됩니다. GitHub Pages는 main 브랜치의 루트(/)를 사용합니다. 영상은 YouTube 임베드입니다.

컴퓨터(Mona), 일기장(YoonChoWooSan), 코스 종이(Nanum Pen Script)는 각각 별도 폰트를 사용합니다. 폰트 출처와 해당 라이선스는 assets/fonts/에 포함되어 있습니다.


## 테포 · 파도를 지켜라

지도에서 오락실을 누르면 게임으로 이동합니다. 직접 실행: https://kimdongyoung27.github.io/tepo-home/games/shorekeeper/

게임은 브라우저에서 실행되는 Godot 4.7.2 20분 생존 액션입니다. 모바일은 가로 화면을 사용합니다. 첫 클릭 이후 소리가 재생되며, 설정에서 배경음·전투 효과음·보상 효과음 음량을 각각 조절할 수 있습니다.

배포 파일: games/shorekeeper/ 전체. 편집용 Godot 소스: game-source/shorekeeper/. 엔진 바이너리와 원본 WAV는 포함하지 않습니다. Godot 4.7.2와 공식 Web export templates 설치 후 GODOT_BIN을 지정하고 소스의 build.ps1을 실행합니다. 생성된 web 폴더 내용을 games/shorekeeper에 복사합니다.


## 20분 모드와 오늘의 기록

일반몹112·전체144상한, 군집 시 장식 자동 완화, 이동 예측/예고 돌진,20분 진행에 맞춘 웨이브와 경험치 보정을 적용했습니다. 보스는3/6/9/12/15/19분입니다. 오늘의 기록은 생존시간 우선, 완주 동률은 처치 수 순입니다.

GitHub Pages에서는 기기 내 기록입니다. 이 저장소를 나중에 Vercel에 연결하면 루트 api/ranking.js를 사용할 수 있고 *.vercel.app 게임은 자동 연결합니다. 실제 공유에는 Redis REST URL/서버 토큰 환경변수가 필요합니다. game-source/shorekeeper/vercel/README.md를 참고하세요. Vercel/DB 계정 생성이나 배포는 이번 작업에 포함하지 않습니다.
