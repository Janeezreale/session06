# 오늘의 한 줄 기록

**작성 → DB 저장 → 조회 → 새로고침 → 배포 → 코드 변경·재배포**를 경험하는 공개 게시판입니다. 완성 코드를 실행하고 각자 만든 Supabase 프로젝트에 연결합니다.

## 구조와 코드 읽기

```text
브라우저 화면 (app/page.tsx)
  → Supabase SDK 호출 (lib/supabase.ts의 연결 사용)
  → HTTPS로 Supabase Data API 요청
  → DB 권한·RLS·제약조건 검사 → PostgreSQL posts 저장/조회
  → API 응답 → React 상태 변경 → 화면 갱신
```

Vercel은 Next.js 화면과 JavaScript를 제공합니다. 데이터 요청은 브라우저에서 Supabase로 직접 갑니다. 새로고침하면 DB에서 다시 조회하므로 기록이 유지됩니다. React 상태는 현재 화면의 임시 상태이며, DB가 영구 저장소입니다. 별도 API 서버나 Server Actions는 없습니다.

```text
app/page.tsx         입력·조회(loadPosts)·저장(savePost)·상태 표시
app/layout.tsx       공통 HTML과 페이지 메타데이터
app/globals.css      반응형 화면 스타일
lib/supabase.ts      환경변수 확인과 SDK 연결
supabase/schema.sql posts 테이블·권한·RLS·입력 제약조건
.env.example        복사할 환경변수 양식
package.json        실행 명령과 의존성
package-lock.json   재현 가능한 설치 버전
```

최신 50개를 조회합니다. 시간은 한국 시간(Asia/Seoul)으로 표시합니다. 입력은 Unicode 코드 포인트 기준 최대 500자이며 앞뒤 공백을 제거해 저장합니다. 길이를 초과하면 등록이 비활성화됩니다. 저장 중에는 입력과 중복 클릭을 막고 실패하면 입력을 유지합니다. 연결 실패 시 임시 데이터나 로컬 저장으로 대체하지 않습니다.

## 실습 순서

### 1. 준비

Node.js **24 LTS**, npm, Git, GitHub·Supabase·Vercel 계정과 코드 편집기를 준비하세요. `node -v`, `npm -v`, `git --version`으로 확인합니다. nvm 사용자라면 `nvm install`과 `nvm use`로 `.nvmrc`를 적용할 수 있습니다.

### 2. 예제 레포지토리 Fork 및 clone

GitHub에서 강사가 제공한 예제 레포지토리를 열고 **Fork → Create fork**를 눌러 자신의 계정에 복사하세요. 참고 원본 harumukkum이 아니라 실습용 예제 레포지토리를 Fork합니다.

자신의 계정에 생성된 Fork에서 **Code** 버튼으로 URL을 복사하고, 아래 `<자신이 Fork한 GitHub 레포 URL>`을 해당 주소로 바꿔 실행하세요.

```bash
git clone <자신이 Fork한 GitHub 레포 URL> session06-diary
cd session06-diary
```

이후 명령은 이 폴더에서 실행합니다. 강사는 이 폴더의 `package.json`이 저장소 루트에 있도록 예제 레포지토리를 제공하는 것을 권장합니다.

### 3. 의존성 설치

```bash
npm install
```

### 4. 새 Supabase 프로젝트 생성

Supabase 대시보드에서 New project를 선택하고 **새 실습 전용 프로젝트**를 만드세요. 이름·DB 비밀번호·리전을 지정하고 준비될 때까지 기다립니다. 기존 서비스 프로젝트를 사용하지 마세요. DB 비밀번호는 이 프론트엔드에 입력하지 않습니다.

### 5. SQL 실행

새 프로젝트의 SQL Editor에서 New query를 열고 [supabase/schema.sql](supabase/schema.sql) 전체를 붙여 넣어 실행하세요. Table Editor에 `public.posts`가 생겼는지 확인합니다.

- `id`: 자동 생성 UUID 기본키 (시퀀스 권한 불필요)
- `content`: 필수, 공백만 있는 값 금지, 최대 500자
- `created_at`: 서버의 `now()` 기본값
- `(created_at DESC, id DESC)` 복합 인덱스: 최신 50개 조회에 사용
- RLS 활성화, 비로그인 역할 `anon`에 SELECT 및 `content` INSERT만 허용
- UPDATE·DELETE 권한과 정책 없음. 작성자가 id·created_at을 지정하는 것도 차단

SQL은 새 테이블 생성용이며 한 번 실행합니다. 다시 실행하면 이미 존재한다는 오류로 트랜잭션이 중단되고 기존 데이터를 초기화하지 않습니다. 오류가 나면 메시지를 확인하고 필요 시 `rollback;`으로 실패한 트랜잭션을 종료하세요. 기존 테이블을 삭제해서 해결하지 마세요.

**누구나 읽고 쓸 수 있는 공개 실습 정책**입니다. 실제 개인 일기 서비스에는 사용자 인증과 소유자별 접근 정책이 필요합니다. 화면에도 개인정보를 입력하지 말라는 안내를 표시합니다.

### 6. 자신의 환경변수 입력

macOS/Linux:

```bash
cp .env.example .env.local
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env.local
```

새 프로젝트의 Connect 또는 Settings의 API 관련 화면에서 Project URL과 **publishable key**를 찾고 `.env.local`의 두 빈 값을 채우세요. 키는 `sb_publishable_`로 시작합니다. 이 실습은 기본 호스팅 URL `https://<프로젝트 식별자>.supabase.co`를 사용합니다.

```dotenv
NEXT_PUBLIC_SUPABASE_URL=<자신의 새 프로젝트 URL>
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<자신의 publishable key>
```

꺾쇠괄호를 포함한 자리표시자는 실제 값으로 교체합니다. **secret 키, service_role 키는 사용하지 마세요.** 공개용 키는 브라우저 번들에 포함되며 데이터 보호는 권한과 RLS가 담당합니다. `.env.local`은 `.gitignore`로 제외되며 `.env.example`만 커밋할 수 있습니다.

### 7. 로컬 실행

```bash
npm run dev
```

터미널의 주소(기본 `http://localhost:3000`)를 여세요. 값이 없거나 형식이 잘못되면 설정 안내가 나타납니다. 형식이 맞아도 실제 키가 틀리면 조회 실패가 표시됩니다. 환경변수를 바꾼 후에는 Ctrl+C로 종료하고 다시 실행하세요.

### 8. 글 작성 → DB 확인

화면에서 “오늘은 브라우저와 DB를 연결했다.”를 등록하세요. 저장 메시지와 목록을 확인하고 Supabase Table Editor의 `posts`에서 내용·id·created_at을 확인합니다. 개발자 도구 Network에서 `/rest/v1/posts` 요청을 보면 POST(저장) 후 GET(조회)을 볼 수 있습니다.

### 9. 유지·공유 확인

새로고침 후 같은 기록이 보이는지 확인하세요. 다른 브라우저에서도 같은 주소로 조회합니다. 목록의 새로 불러오기로 다른 사람이 쓴 기록을 가져올 수 있습니다. 실시간 자동 동기화 기능은 없습니다.

### 10. Fork한 GitHub 레포 연결 확인

clone한 폴더에서 `origin`이 자신의 계정에 Fork한 레포지토리를 가리키는지 확인하세요.

```bash
git remote -v
```

Fork할 때 예제 코드가 자신의 GitHub 레포지토리에 복사되므로 바로 Vercel에 연결할 수 있습니다. 이후 코드 변경은 commit 후 `git push`로 이 레포지토리에 올립니다. `.env.local`과 `node_modules`는 커밋하지 마세요.

### 11. Vercel Import

Vercel에서 Add New → Project로 자신이 Fork한 GitHub 레포지토리를 Import합니다. Framework Preset은 Next.js, Node.js는 24.x를 사용합니다. 저장소 루트에 package.json이 있다면 Root Directory는 기본값입니다. 상위 폴더 전체를 올렸다면 Root Directory를 `session06-diary`로 지정하세요. 기본 build 명령은 `npm run build`입니다.

### 12. 첫 배포 전에 환경변수 등록

Import 설정의 Environment Variables에 `.env.local`의 **두 변수 이름과 자신의 값**을 입력하세요. Production에 적용하고 Preview를 쓸 경우 Preview에도 등록합니다. 이후 Deploy를 누릅니다. `.env.local` 파일을 업로드하는 방식이 아닙니다.

`NEXT_PUBLIC_` 값은 빌드할 때 JavaScript에 포함됩니다. 배포 후 값을 바꿨다면 재배포해야 적용됩니다. 환경변수가 없어도 빌드는 통과하고 설정 안내가 표시되므로, 빌드 성공만으로 DB 연결 성공을 판단하지 마세요.

### 13. 배포 URL 확인

배포된 URL에서 새 기록을 작성하고 새로고침·다른 브라우저 조회를 확인하세요. 같은 Supabase 프로젝트를 연결했다면 로컬과 배포 사이트가 같은 데이터를 봅니다.

### 14. 제목 변경 → 자동 재배포

`app/page.tsx`의 `<h1>` 제목을 변경하세요. 브라우저 탭 제목은 `app/layout.tsx`의 metadata에서 변경할 수 있습니다.

```bash
npm run typecheck
npm run lint
npm run build
git add app/page.tsx app/layout.tsx
git commit -m "Change board title"
git push
```

Vercel Deployments에서 해당 commit의 빌드가 완료되는지 확인하고 배포 URL을 새로고침해 제목 변경을 확인하세요.

## 문제 해결

| 증상                   | 확인할 항목                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 설정 안내 표시         | 파일이 package.json 옆의 `.env.local`인지, 두 변수 이름·URL·키 형식·공백·자리표시자 여부                          |
| 값을 바꿔도 그대로     | 개발 서버 재시작, Vercel 적용 환경(Production/Preview), 변경 후 재배포 여부                                       |
| 조회/저장 실패         | 네트워크, 프로젝트 준비·중지 상태, URL과 키가 같은 프로젝트인지, 테이블명·스키마, Data API 노출, 권한 및 RLS 정책 |
| 저장만 실패            | 공백·500자 조건, INSERT(content) 권한, INSERT 정책, Network 응답 내용                                             |
| 저장 성공 후 목록 오류 | 저장은 완료됐지만 후속 SELECT가 실패할 수 있음. 재등록 전에 목록과 Table Editor 확인                              |
| 시간 초과              | 요청은 15초 후 중단. 응답 유실 전에 DB 저장이 끝났을 수도 있으므로 재시도 전 목록 확인                            |
| 빌드 실패              | 첫 오류 메시지, Node 24.x, `npm install` 완료 여부, 타입/lint 결과, Vercel Root Directory와 빌드 로그             |

한 증상에는 여러 원인이 있을 수 있습니다. 브라우저 Network 응답과 Vercel 로그를 함께 확인하세요. SQL Editor는 높은 권한으로 실행되므로 그곳에서 조회 성공한 것만으로 anon RLS 검증을 대신할 수 없습니다.

## 수동 검증 체크리스트

- [ ] 최초 빈 목록, 조회 중 상태, 정상 작성·최신순·한국 시각
- [ ] 새로고침과 다른 브라우저에서 데이터 유지
- [ ] 공백만 입력 시 등록 불가, 500자 가능, 501자 불가
- [ ] 저장 중 연속 클릭해도 요청 하나, 실패 시 입력 유지
- [ ] Network를 Offline으로 전환하면 조회·저장 오류와 재시도 가능
- [ ] 390px 모바일과 데스크톱에서 가로 넘침 없이 사용 가능
- [ ] 자신의 publishable key로 Data API 호출 시 SELECT·INSERT 성공
- [ ] 같은 API 권한으로 공백/501자 INSERT 실패, UPDATE·DELETE 거부
- [ ] Vercel 작성·조회 및 commit·push 후 제목 변경 확인

RLS 검증은 자신의 새 프로젝트에만 실행하세요. 앱 화면은 수정·삭제를 제공하지 않으므로 API 수준의 거부를 별도로 확인해야 합니다. 예를 들어 임시 로컬 스크립트에서 `createClient(자신의_URL, 자신의_publishable_key)` 후 `.from('posts').update({ content: '수정 시도' }).eq('id', 실습_글_id)`와 `.delete().eq('id', 실습_글_id)`를 호출해 권한 오류와 원본 보존을 확인하세요. 실제 값은 공유 코드에 커밋하지 마세요.
