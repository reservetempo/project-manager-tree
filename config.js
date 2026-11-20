/* Supabase project for the next steps.
   Both values are under Project Settings -> API (or Connect) in the Supabase dashboard.
   The anon (publishable) key is meant to be public: the database rules in supabase/setup.sql
   decide who can change what. Never put the service_role (secret) key here. */
window.PMT_CONFIG = {
  url: '',      // https://<project-ref>.supabase.co
  anonKey: ''   // anon / publishable key
};
