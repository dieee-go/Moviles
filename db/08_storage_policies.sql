-- ================================================
-- STORAGE POLICIES
-- ================================================

create policy "Admin deletes any event image"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'event-images'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'admin'::text))))));



  

create policy "Admin updates any event image"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'event-images'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'admin'::text))))))
with check ((bucket_id = 'event-images'::text));



  

create policy "Anyone can upload an avatar."
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'avatars'::text));



  

create policy "Avatar images are publicly accessible."
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'avatars'::text));



  

create policy "Organizer deletes own event images"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['organizer'::text, 'admin'::text])))))));



  

create policy "Organizer updates own event images"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['organizer'::text, 'admin'::text])))))))
with check (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)));



  

create policy "Public read event images"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'event-images'::text));



  

create policy "Upload event images to own folder (organizer/admin)"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['organizer'::text, 'admin'::text])))))));




