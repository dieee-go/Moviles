CREATE TRIGGER events_updated_at_trigger BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER on_role_change AFTER UPDATE OF role ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.track_role_changes();
CREATE TRIGGER role_requests_set_updated_at BEFORE UPDATE ON public.role_requests FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
