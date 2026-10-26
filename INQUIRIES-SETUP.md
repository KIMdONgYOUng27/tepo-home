# Supabase 문의 저장 연결

2026-10-26에 연결 완료. 프로젝트: **tepo's house** (`ehqkdzxkgiyrunwssqgw`, Tokyo). API: https://ehqkdzxkgiyrunwssqgw.supabase.co

## 실제 적용 내용

- 원격 마이그레이션 `create_tepo_inquiries`: `public.inquiries` 테이블, 입력 제약, 생성 시각 인덱스, RLS 및 입력 전용 권한.
- `config/inquiries.json`에 공개용 publishable key와 프로젝트 주소 설정, enabled=true. 비밀 키/service_role은 사용하거나 저장하지 않았다.
- `inquiries.js` 공통 저장 모듈을 챗봇과 `contact.html`이 공유한다. `source`는 chatbot/contact_page, `inquiry_type`은 general/production.
- 문의 JSON 설정 및 JS의 캐시 버전을 v34로 갱신했다.
- 익명 및 일반 로그인 방문자는 명시된 문의 필드만 INSERT 가능하다. SELECT/UPDATE/DELETE 권한과 정책은 제공하지 않는다.
- 문의 내용·이메일은 채팅 sessionStorage에 기록하지 않는다. 챗봇 대화는 기존 sessionStorage/JSON 방식을 유지하며 Supabase로 전송하지 않는다.

## 관리자가 확인하는 곳

[Supabase Table Editor](https://supabase.com/dashboard/project/ehqkdzxkgiyrunwssqgw/editor)에서 `public.inquiries`를 선택한다. 관리 계정으로 로그인해야 한다. 공개 사이트에 문의 목록 조회 화면은 없다.

필드: id, created_at, inquiry_type, name, email, subject, message, source, consent. id와 생성 시각은 서버에서 생성한다.

## 검증

실제 브라우저의 문의 페이지와 챗봇 양식에서 가짜 테스트 이름 및 example.com 이메일로 문의를 제출했고, 관리 SQL로 같은 테이블에 저장됨을 확인했다. 일반/제작 문의 분류 및 source를 확인했다. 검증 후 테스트로 만든 세 행만 정확한 ID와 테스트 표식을 확인해 삭제했다. 역할별 권한과 RLS 활성화를 확인했고 Supabase security advisor는 경고 0건이었다. 사이트 단위 테스트도 별도로 실행한다.

## 배포와 운영

현재 연결은 로컬 웹사이트 파일에 반영했다. GitHub Pages의 공개 사이트에는 아직 배포하지 않았다. 사용자가 푸시를 요청하면 publish-manifest의 HTML/JS/설정 JSON을 함께 배포해야 한다. 이 설정의 publishable key는 공개 클라이언트용이며 secret/service_role 키로 교체하면 안 된다.

문의 양식은 현재 데이터를 접수할 수 있지만, 운영자의 실제 개인정보 처리 주체·보관 기간·삭제 요청 방법·답변 정책은 공개 운영 전에 확정해 안내해야 한다. 이메일 발송/답변 알림 기능은 별도 구현하지 않았다. 스팸 방지 서버 제한이나 CAPTCHA도 아직 없다. 현재 honeypot과 입력 제약은 기본 보조 수단이다.

[API keys 공식 문서](https://supabase.com/docs/guides/getting-started/api-keys) · [RLS 공식 문서](https://supabase.com/docs/guides/database/postgres/row-level-security)
