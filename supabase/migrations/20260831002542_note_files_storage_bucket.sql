-- Private storage bucket for best-effort note/flashcard/past-question file
-- backups (see data/repositories/note_remote_sync.dart). RLS-scoped so a
-- student can only ever read/write objects under their own uid folder --
-- objects are stored as <uid>/<noteId>.<ext> and <uid>/<noteId>.json.
insert into storage.buckets (id, name, public)
values ('note-files', 'note-files', false)
on conflict (id) do nothing;

create policy "Users can read their own note files"
on storage.objects for select
using (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can upload their own note files"
on storage.objects for insert
with check (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can update their own note files"
on storage.objects for update
using (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can delete their own note files"
on storage.objects for delete
using (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);
