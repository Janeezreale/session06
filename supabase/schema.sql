-- 새 실습 프로젝트에서 한 번 실행하세요. 기존 posts가 있으면 중단됩니다.
begin;

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  created_at timestamptz not null default now(),
  constraint posts_content_length check (char_length(content) between 1 and 500),
  constraint posts_content_not_blank check (
    content ~ '[^[:space:]　 ﻿]'
  )
);

alter table public.posts enable row level security;

-- 기본으로 부여될 수 있는 권한을 제거하고 조회·내용 입력만 허용합니다.
revoke all on table public.posts from public, anon, authenticated;
grant usage on schema public to anon;
grant select on table public.posts to anon;
grant insert (content) on table public.posts to anon;

create policy "Public can read posts" on public.posts
  for select to anon using (true);
create policy "Public can create posts" on public.posts
  for insert to anon with check (true);

-- UUID 기본값에는 시퀀스 권한이 필요 없습니다. 수정·삭제 정책은 없습니다.
commit;
