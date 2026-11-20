# Project Manager Tree

A one-page tree of the Project Manager's four main folders, with what each one holds and its next steps.

Live: https://reservetempo.github.io/project-manager-tree/

Run locally: `python -m http.server 8000`, then open http://localhost:8000/.

## Editing next steps (Supabase)

Next steps and their priorities (low, medium, high; unmarked is low) are stored in Supabase. Anyone can read them; only users listed in `public.editors` can change them.

1. Make a Supabase project, then run `supabase/setup.sql` in its SQL Editor.
2. Authentication → Users → Add user (your email and a password). Then run the last line of `setup.sql` with your email to make yourself the editor.
3. Optional: Authentication → Sign In / Providers → turn off "Allow new users to sign up".
4. Put the project URL and anon (publishable) key in `config.js`. Never put the service_role key there.

Until `config.js` is filled in, the page shows its built-in steps and hides the Sign in button.
