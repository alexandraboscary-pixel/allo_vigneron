-- Allô Vino — Lot 1 : stockage des fichiers (README section 5.4)
-- Chemins : {domaine_id}/{wine_id}/{fichier} ou appellations/{appellation_id}/{fichier}

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('medias-raw', 'medias-raw', false, 209715200, array['audio/*', 'video/*']),
  ('medias',     'medias',     true,  52428800,  array['audio/*', 'video/*', 'image/*']),
  ('labels',     'labels',     true,  5242880,  array['image/*']),
  ('avatars',    'avatars',    true,  5242880,  array['image/*'])
on conflict (id) do nothing;

-- Le premier dossier du chemin désigne le domaine (ou « appellations » puis l'appellation)
create or replace function public.can_write_object(object_name text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare
  parts text[] := storage.foldername(object_name);
begin
  if parts[1] = 'appellations' then
    return public.is_odg_member(parts[2]::uuid);
  end if;
  return public.is_member(parts[1]::uuid);
exception when invalid_text_representation then
  return false;
end $$;

-- medias-raw : privé, membres seulement (n8n lit avec la clé service)
create policy "raw_read" on storage.objects for select to authenticated
  using (bucket_id = 'medias-raw' and public.can_write_object(name));
create policy "raw_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'medias-raw' and public.can_write_object(name));
create policy "raw_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'medias-raw' and public.can_write_object(name));

-- labels et avatars : lecture publique (bucket public), écriture par les membres
create policy "images_insert" on storage.objects for insert to authenticated
  with check (bucket_id in ('labels', 'avatars') and public.can_write_object(name));
create policy "images_update" on storage.objects for update to authenticated
  using (bucket_id in ('labels', 'avatars') and public.can_write_object(name))
  with check (bucket_id in ('labels', 'avatars') and public.can_write_object(name));
create policy "images_delete" on storage.objects for delete to authenticated
  using (bucket_id in ('labels', 'avatars') and public.can_write_object(name));

-- medias : aucune écriture côté client, n8n y dépose les fichiers convertis et les aperçus
