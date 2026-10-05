-- PIN recovery via security questions (see
-- lib/data/repositories/security_questions_remote_sync.dart). Lives
-- server-side, unlike the PIN itself, because recovery must work even when
-- local device storage -- the very thing holding the PIN -- is what's been
-- lost (new phone, reinstall, wiped app). Only salted answer hashes are
-- ever stored; plaintext answers never reach this table.
create table if not exists public.security_questions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  salt text not null,
  question_1 text not null,
  answer_1_hash text not null,
  question_2 text not null,
  answer_2_hash text not null,
  question_3 text not null,
  answer_3_hash text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.security_questions enable row level security;

create policy "security_questions_select_own" on public.security_questions
  for select using (auth.uid() = user_id);

create policy "security_questions_insert_own" on public.security_questions
  for insert with check (auth.uid() = user_id);

create policy "security_questions_update_own" on public.security_questions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "security_questions_delete_own" on public.security_questions
  for delete using (auth.uid() = user_id);
