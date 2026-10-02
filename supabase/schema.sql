-- メモ帳 (memo-list) の Supabase スキーマ
-- Supabase ダッシュボード > SQL Editor > New query に貼って Run（何度実行しても安全）

create extension if not exists pgcrypto;

-- 本体：メモ1件=1行。本文(body)は合言葉から作った鍵でAES-GCM暗号化済み
create table if not exists public.memo_items (
  id uuid primary key default gen_random_uuid(),
  body text not null,                 -- 暗号化した本文
  iv text not null,                   -- 暗号化の初期ベクトル
  stage text not null default 'memo', -- memo / yaritai / todo / done
  map_id text,                        -- 将来：マインドマップとの紐づけ用
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 合言葉の検証用：salt と、正しい合言葉か確かめるための暗号化済み文字列
create table if not exists public.memo_meta (
  id text primary key,
  value text not null,
  iv text not null default ''
);

alter table public.memo_items enable row level security;
alter table public.memo_meta enable row level security;

-- ログイン機能なしの個人用。anon keyに全操作を許可（内容は暗号化済みなので平文は保存されない）
drop policy if exists "anon full access" on public.memo_items;
create policy "anon full access" on public.memo_items for all using (true) with check (true);
drop policy if exists "anon full access" on public.memo_meta;
create policy "anon full access" on public.memo_meta for all using (true) with check (true);

-- 端末間のリアルタイム同期
do $$
begin
  alter publication supabase_realtime add table public.memo_items;
exception when duplicate_object then null;
end $$;
