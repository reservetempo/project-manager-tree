-- Project Manager Tree: next steps with priorities.
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Anyone can read the steps. Only users listed in public.editors can change them.

-- 1. Who may edit -------------------------------------------------------------
create table if not exists public.editors (
  user_id uuid primary key references auth.users (id) on delete cascade
);
alter table public.editors enable row level security;
-- No policies on purpose: the API can't read or change this table.

create or replace function public.is_editor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.editors where user_id = auth.uid());
$$;

-- 2. The steps ----------------------------------------------------------------
create table if not exists public.steps (
  id         bigint generated always as identity primary key,
  folder     text not null check (folder in ('data', 'idea-organizer', 'project-organizer', 'content-generation')),
  position   int  not null,
  body       text not null check (char_length(body) between 1 and 300),
  priority   text not null default 'low' check (priority in ('low', 'medium', 'high')),
  updated_at timestamptz not null default now()
);
create index if not exists steps_folder_position on public.steps (folder, position);
alter table public.steps enable row level security;

drop policy if exists "Anyone can read steps" on public.steps;
create policy "Anyone can read steps" on public.steps
  for select to anon, authenticated using (true);

drop policy if exists "Editors can add steps" on public.steps;
create policy "Editors can add steps" on public.steps
  for insert to authenticated with check (public.is_editor());

drop policy if exists "Editors can change steps" on public.steps;
create policy "Editors can change steps" on public.steps
  for update to authenticated using (public.is_editor()) with check (public.is_editor());

drop policy if exists "Editors can delete steps" on public.steps;
create policy "Editors can delete steps" on public.steps
  for delete to authenticated using (public.is_editor());

-- Newer projects don't grant table access to the API roles by default.
-- The policies above still decide which rows each role can touch.
grant usage on schema public to anon, authenticated;
grant select on public.steps to anon, authenticated;
grant insert, update, delete on public.steps to authenticated;

-- 3. Save one folder's list in one transaction ---------------------------------
-- Runs as the caller, so the policies above still apply.
create or replace function public.save_steps(p_folder text, p_items jsonb)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not public.is_editor() then
    raise exception 'Only editors can save steps' using errcode = '42501';
  end if;
  delete from public.steps where folder = p_folder;
  insert into public.steps (folder, position, body, priority)
  select p_folder,
         (t.ord - 1)::int,
         btrim(t.item ->> 'text'),
         coalesce(nullif(t.item ->> 'priority', ''), 'low')
  from jsonb_array_elements(p_items) with ordinality as t (item, ord)
  where btrim(coalesce(t.item ->> 'text', '')) <> '';
end;
$$;

revoke execute on function public.save_steps(text, jsonb) from public, anon;
grant execute on function public.save_steps(text, jsonb) to authenticated;
grant execute on function public.is_editor() to anon, authenticated;

-- 4. Starting steps (only if the table is empty) -------------------------------
insert into public.steps (folder, position, body)
select v.folder, v.position, v.body
from (values
  ('data', 0, 'Index the 200 books not yet searchable'),
  ('data', 1, 'Add Zotero and OpenAlex as paper sources'),
  ('data', 2, 'One skill to find, sort and index both'),
  ('data', 3, 'Add meaning search only if word search misses'),
  ('idea-organizer', 0, 'Build the input tracker skill'),
  ('idea-organizer', 1, 'Tag, score, then clean up each idea'),
  ('idea-organizer', 2, 'Score with the urgent/important grid'),
  ('idea-organizer', 3, 'Link ideas to books and papers'),
  ('idea-organizer', 4, 'Keep a list of every skill and its owner'),
  ('project-organizer', 0, 'Set one goal per project'),
  ('project-organizer', 1, 'Log work and review it weekly'),
  ('project-organizer', 2, 'Build "recently worked on" from file dates'),
  ('project-organizer', 3, 'Pull in scored ideas from the idea organizer'),
  ('content-generation', 0, 'Text skill: 1–2 pages with sources'),
  ('content-generation', 1, 'Wire up the existing /page skill'),
  ('content-generation', 2, 'Video skill (Remotion or Manim)'),
  ('content-generation', 3, 'Add a map of ideas with graphify')
) as v (folder, position, body)
where not exists (select 1 from public.steps);

-- 5. Make yourself the editor ----------------------------------------------------
-- First add your user: Authentication -> Users -> Add user -> Create new user.
-- Then put your email below, remove the two dashes, and run just this line:
-- insert into public.editors (user_id) select id from auth.users where email = 'you@example.com';
