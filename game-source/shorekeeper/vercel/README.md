# 오늘의 생존 랭킹 서버 준비

현재 게임은 서버 연결 전에는 **이 기기의 오늘 기록**을 표시합니다. 온라인 순위를 꾸며서 표시하지 않습니다. 모드는 shore20-v14로 분리하고, 한국 날짜 기준 생존시간 내림차순·동률 처치 수 순으로 정렬합니다. 20분 완주 기록은 20:00으로 고정됩니다.

공개 저장소 루트에도 api/ranking.js와 Vercel 설정을 함께 준비합니다. 나중에 기존 저장소를 Vercel에 연결하면 /api/ranking 경로를 사용할 수 있습니다. Node 서버리스 + Upstash 호환 Redis REST를 사용하며 외부 npm 의존성은 없습니다. Vercel 배포·계정 생성·과금은 아직 수행하지 않습니다.

Vercel 환경 변수:

- UPSTASH_REDIS_REST_URL: Redis REST 주소
- UPSTASH_REDIS_REST_TOKEN: 서버 전용 토큰
- ALLOWED_ORIGIN: 게임의 정확한 origin (현재 사이트라면 https://kimdongyoung27.github.io)

*.vercel.app에서는 게임이 같은 origin의 /api/ranking으로 자동 연결합니다. 별도 서버나 커스텀 도메인이면 web-ranking.js의 endpoint를 설정합니다. 같은 origin은 자동 허용하며 GitHub Pages에서 별도 Vercel 서버를 호출할 경우 ALLOWED_ORIGIN을 설정합니다. 토큰은 웹 파일에 넣지 않습니다. CORS, 기록 형식·상한 검사, 분당 제출 제한, 동일 run ID 중복 방지, 한국 날짜별 분리, 3일 보관을 제공합니다.

이 서버는 클라이언트가 보고한 점수를 받는 **캐주얼 랭킹**입니다. 점수의 실제 플레이 여부를 증명하는 구조는 아니므로, 상금·경쟁용 운영 전에는 서버 세션 검증이나 리플레이 검증이 추가로 필요합니다. 서버 연결 실패 시 로컬 기록은 보존합니다.
