-- ================================================
-- ROW LEVEL SECURITY POLICIES
-- ================================================

create policy "Anyone can read carreras"
  on "public"."carreras"
  as permissive
  for select
  to public
using (true);



  

create policy "Anyone can read departamentos"
  on "public"."departamentos"
  as permissive
  for select
  to public
using (true);



  

create policy "Organizer/Admin insert event_interests"
  on "public"."event_interests"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_interests.event_id) AND ((e.organizer_id = auth.uid()) OR (( SELECT profiles.role
           FROM public.profiles
          WHERE (profiles.id = auth.uid())) = 'admin'::text))))));



  

create policy "Read all event_interests"
  on "public"."event_interests"
  as permissive
  for select
  to authenticated
using (true);



  

create policy "Organizadores y admins pueden ver registros"
  on "public"."event_registrations"
  as permissive
  for select
  to authenticated
using (((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))) OR (EXISTS ( SELECT 1
   FROM public.events
  WHERE ((events.id = event_registrations.event_id) AND (events.organizer_id = auth.uid()))))));



  

create policy "Users read own registrations"
  on "public"."event_registrations"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  

create policy "Users register themselves"
  on "public"."event_registrations"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  

create policy "Users unregister themselves"
  on "public"."event_registrations"
  as permissive
  for delete
  to authenticated
using ((auth.uid() = user_id));



  

create policy "Users update own registrations"
  on "public"."event_registrations"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  

create policy "Organizer/Admin delete own events"
  on "public"."events"
  as permissive
  for delete
  to authenticated
using (((organizer_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text)));



  

create policy "Organizer/Admin update own events"
  on "public"."events"
  as permissive
  for update
  to authenticated
using (((organizer_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text)))
with check (((organizer_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text)));



  

create policy "Organizers and admins create events"
  on "public"."events"
  as permissive
  for insert
  to authenticated
with check (((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = ANY (ARRAY['organizer'::text, 'admin'::text])) AND (organizer_id = auth.uid())));



  

create policy "Read all events"
  on "public"."events"
  as permissive
  for select
  to authenticated
using (true);



  

create policy "Public read interests"
  on "public"."interests"
  as permissive
  for select
  to public
using (true);



  

create policy "Admins delete locations"
  on "public"."locations"
  as permissive
  for delete
  to authenticated
using ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text));



  

create policy "Admins insert locations"
  on "public"."locations"
  as permissive
  for insert
  to authenticated
with check ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text));



  

create policy "Admins update locations"
  on "public"."locations"
  as permissive
  for update
  to authenticated
using ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text))
with check ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text));



  

create policy "Read all locations"
  on "public"."locations"
  as permissive
  for select
  to authenticated
using (true);



  

create policy "Usuarios autenticados pueden ver todos los perfiles"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using (true);



  

create policy "admins read profiles"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using (public.is_current_admin());



  

create policy "admins update profiles"
  on "public"."profiles"
  as permissive
  for update
  to public
using (public.is_current_admin())
with check (public.is_current_admin());



  

create policy "profiles insert own"
  on "public"."profiles"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = id));



  

create policy "profiles select own"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = id));



  

create policy "profiles update own"
  on "public"."profiles"
  as permissive
  for update
  to authenticated
using ((auth.uid() = id))
with check ((auth.uid() = id));



  

create policy "read own profile"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using ((id = auth.uid()));



  

create policy "Admins can view all history"
  on "public"."role_history"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));



  

create policy "Users can view own history"
  on "public"."role_history"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  

create policy "Admins can update requests"
  on "public"."role_requests"
  as permissive
  for update
  to public
using (((auth.jwt() ->> 'role'::text) = ANY (ARRAY['service_role'::text, 'admin'::text])));



  

create policy "Admins can update role requests"
  on "public"."role_requests"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));



  

create policy "Users can insert their own request"
  on "public"."role_requests"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  

create policy "Users can view their own requests"
  on "public"."role_requests"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  

create policy "admins read role requests"
  on "public"."role_requests"
  as permissive
  for select
  to authenticated
using (public.is_current_admin());



  

create policy "read own role requests"
  on "public"."role_requests"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  

create policy "Users can delete own user_carrera"
  on "public"."user_carrera"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  

create policy "Users can insert own user_carrera"
  on "public"."user_carrera"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  

create policy "Users can read own user_carrera"
  on "public"."user_carrera"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  

create policy "Users can update own user_carrera"
  on "public"."user_carrera"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  

create policy "Users can delete own user_departamento"
  on "public"."user_departamento"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  

create policy "Users can insert own user_departamento"
  on "public"."user_departamento"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  

create policy "Users can read own user_departamento"
  on "public"."user_departamento"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  

create policy "Users can update own user_departamento"
  on "public"."user_departamento"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  

create policy "Users can delete own interests"
  on "public"."user_interests"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  

create policy "Users can insert own interests"
  on "public"."user_interests"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  

create policy "Users can read own interests"
  on "public"."user_interests"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));


CREATE TRIGGER events_updated_at_trigger BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_role_change AFTER UPDATE OF role ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.track_role_changes();

CREATE TRIGGER role_requests_set_updated_at BEFORE UPDATE ON public.role_requests FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


  
