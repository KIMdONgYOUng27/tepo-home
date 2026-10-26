# v38 — 게임 오디오 수명과 재질별 효과음

## 게임 음악이 남지 않도록

- 게임은 기본 음량 0으로 시작하고, 같은 출처의 부모가 열린 게임 화면임을 확인한 뒤에만 현재 게임 음량을 전달한다. 게임 화면이 아니면 정책상 게임 출력은 항상 0이다.
- `TepoMusic.setSiteGain(0)`에서 두 HTML 음악 플레이어의 mute/volume/pause를 즉시 적용한다. 다음 animation frame을 기다리지 않는다. pointerdown/keydown 자동 재개도 외부 음량 0일 때는 차단한다.
- 전체 음소거는 메인 HTML 오디오와 게임 HTML 오디오, 게임의 최종 Web Audio 출력, 이미 예약된 세계 효과음을 함께 정지한다.
- 게임 종료 시 `stopGame()` 및 `TepoSiteAudio.shutdown()`을 먼저 실행한다. 음악 플레이어를 멈추고 소스를 해제하며, 게임 최종 출력 gain을 0으로 만들고 AudioContext를 닫은 뒤 iframe을 about:blank로 바꾸고 제거한다. pagehide에서도 종료한다.
- 실제 브라우저에서 게임 준비 완료 후 게임 음량 0 → 100 → 전체 음소거 → 종료를 검증했다. 실제 자식 프레임이 보고한 재생 중 음악 트랙 수는 음소거 시 0, 음량 100일 때 1, 전체 음소거 시 다시 0이었다. 메인 음악은 게임 중 paused 상태이고 종료 후 iframe은 제거됐다.
- 검증 뒤 사용자 기존 설정인 게임 음량 0%, 배경음 45%, 효과음 55%, 전체 음소거 해제 상태로 복원했다.

## 물건별 다른 소리

합성 톤만 바꾸는 대신 Kenney의 CC0 RPG/Impact/Interface 팩에서 선택한 소스를 편집했다. 현재 42개 효과음 중 27개가 재질 샘플 또는 그 조합이다.

- 일기장: bookOpen / bookFlip2 / bookClose.
- 나무 방망이: impactWood_medium_002.
- 삼단봉: metalClick → metalLatch → 가벼운 금속 고정음.
- 곡날 무기: drawKnife2 + 작은 금속 공명.
- 메이스: 무거운 금속 + 걸쇠 및 판금 울림.
- 자물쇠: metalLatch + 가벼운 금속 접촉. 파괴 장면은 별도의 무거운 타격과 금속 파편 조합.
- 테포: 일반 단단한 충격/채광 충격/콘크리트 접촉을 동작별로 구분.
- 가방·지갑: 실제 버클/가죽. 서랍·액자: 나무. 컴퓨터·통역기는 전용 전자음 유지.
- 획득 시에는 실제 고유 효과음 길이가 끝난 뒤 가방 수집음을 재생한다.
- 공통 버튼 소리를 고유 오브젝트에 덧씌우지 않는다.

## 이동음

걸음 샘플을 반복하지 않고, `area_enter` / `area_exit`의 짧은 오리지널 8비트 지역 전환음으로 교체했다. 포켓몬 원곡·효과음 녹음은 복사하지 않았다.

## 파일과 재생 확인

- 현재 카탈로그: assets/audio/sound-bank-v38.json. 원본 파일명·팩·gain·길이가 기록돼 있다.
- 출처/라이선스: assets/audio/licenses/SOURCES.md 및 CC0 라이선스 세 파일.
- 제작 재현: scripts/build-foley-v38.py. 다운로드한 원본 팩은 audio-source-v38에 로컬 보관하며 배포 목록에 포함하지 않는다.
- 개별 청취: audio-review.html. 비교 모음: assets/audio/material-preview-v38.wav.
- 캐시 갱신: 부모 사운드/정책/이동 JS, 게임 브리지 및 음악 JS, iframe audio=38.
- 게임 PCK/WASM·그래픽·조작·밸런스는 변경하지 않았다.

현재 로컬 변경이다. 공개 사이트에는 아직 푸시하지 않았다.
