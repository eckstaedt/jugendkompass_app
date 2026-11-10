// Public client config (anon key is public by design; access is enforced via RLS + admin RPCs)
window.TP_CONFIG = {
  supabaseUrl: "https://vdcdibvclaulqxfjyzpq.supabase.co",
  supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkY2RpYnZjbGF1bHF4Zmp5enBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NTkxODksImV4cCI6MjA4MTAzNTE4OX0.cuJ5OKNauU_-mKQ3oX8Yi88kEJq2o5fpADlYquAkZLw",
  audioBucket: "audios",
  pollMs: 5000,
  billingUrl: "https://console.anthropic.com/settings/billing",
  usageUrl: "https://console.anthropic.com/usage",
};
