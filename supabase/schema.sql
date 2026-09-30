-- 오늘의 한 줄 기록 — Supabase PostgreSQL 스키마
-- 새 프로젝트의 SQL Editor에 이 파일 전체를 붙여 넣고 한 번 실행하세요.
-- 기존 posts가 있으면 중단됩니다. 기존 테이블과 데이터를 삭제하지 않습니다.
begin;

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  created_at timestamptz not null default now(),
  constraint posts_content_length check (char_length(content) between 1 and 500),
  constraint posts_content_not_blank check (
  -- content가 공백만으로 이루어지지 않도록 합니다. 공백에는 일반 공백, 일본어 공백, nbsp, BOM이 포함됩니다.
  -- 아래 특수문자 깨져 나올 수 있음. 오타 아님
    content ~ '[^[:space:]　 ﻿]'
  )
);

-- 화면의 최신 50개 조회: ORDER BY created_at DESC, id DESC LIMIT 50
create index posts_created_at_id_idx
  on public.posts (created_at desc, id desc);

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
