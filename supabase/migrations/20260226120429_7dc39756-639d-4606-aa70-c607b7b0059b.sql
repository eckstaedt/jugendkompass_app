CREATE TRIGGER on_video_insert
  BEFORE INSERT ON public.videos
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_video_content();