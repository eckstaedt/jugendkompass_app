-- Fallback for the translation worker: read the Anthropic API key from Vault
-- when the edge function secret ANTHROPIC_API_KEY is not set.
--
-- The key itself is NOT part of this migration. Store it once with:
--   select vault.create_secret('<key>', 'translation_anthropic_api_key',
--                              'Anthropic API key for process-translation-jobs');
-- As soon as ANTHROPIC_API_KEY is set as a function secret, that one wins
-- and the Vault entry can be deleted.

CREATE OR REPLACE FUNCTION public.get_translation_anthropic_key()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT decrypted_secret FROM vault.decrypted_secrets
  WHERE name = 'translation_anthropic_api_key' LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_translation_anthropic_key() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_translation_anthropic_key() TO service_role;
