-- Private storage bucket for the one best-effort profile-photo backup per
-- student (see data/repositories/profile_photo_remote_sync.dart). Always
-- stored as <uid>/photo.jpg, since there's only ever one. Same RLS-scoping
-- pattern as the note-files bucket.
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', false)
on conflict (id) do nothing;

create policy "Users can read their own profile photo"
on storage.objects for select
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can upload their own profile photo"
on storage.objects for insert
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can update their own profile photo"
on storage.objects for update
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can delete their own profile photo"
on storage.objects for delete
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
