-- Tracks one row per course-slip extraction attempt, used only to enforce
-- a per-user daily cap on the extract-course-slip Edge Function (which
-- calls a paid vision model). A row is inserted for every attempt,
-- successful or not, before the model is called -- so a broken/unreadable
-- photo still counts against the cap rather than being freely retryable.
create table if not exists public.extraction_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.extraction_requests enable row level security;

-- The Edge Function calls this table using the caller's own forwarded JWT
-- (never the service role key) -- these policies are what actually enforce
-- "only your own usage", both for the rate-limit count and the insert.
create policy "Users can view their own extraction requests"
  on public.extraction_requests for select
  using (auth.uid() = user_id);

create policy "Users can insert their own extraction requests"
  on public.extraction_requests for insert
  with check (auth.uid() = user_id);

create index if not exists extraction_requests_user_created_idx
  on public.extraction_requests (user_id, created_at desc);
