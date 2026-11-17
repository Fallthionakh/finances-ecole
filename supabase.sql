-- Application « Finances – École de Formation » : structure Supabase (tables préfixées fin_)
-- Déjà appliquée au projet WEBINAIRE. Conservée ici pour référence / réinstallation.

create table if not exists public.fin_membres (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nom text,
  role text not null default 'en_attente' check (role in ('admin','caissier','lecteur','en_attente')),
  cree_le timestamptz not null default now()
);
alter table public.fin_membres enable row level security;

create or replace function public.fin_role() returns text
language sql stable security definer set search_path = public as $$
  select role from public.fin_membres where user_id = auth.uid()
$$;
revoke all on function public.fin_role() from public, anon;
grant execute on function public.fin_role() to authenticated;

-- Le tout premier utilisateur devient administrateur, les suivants sont « en attente »
create or replace function public.fin_rejoindre(p_nom text default null) returns text
language plpgsql security definer set search_path = public as $$
declare r text;
begin
  if auth.uid() is null then raise exception 'non connecté'; end if;
  select role into r from public.fin_membres where user_id = auth.uid();
  if r is not null then return r; end if;
  lock table public.fin_membres in exclusive mode;
  insert into public.fin_membres(user_id, email, nom, role)
  values (auth.uid(), (select email from auth.users where id = auth.uid()), p_nom,
          case when exists(select 1 from public.fin_membres) then 'en_attente' else 'admin' end)
  returning role into r;
  return r;
end $$;
revoke all on function public.fin_rejoindre(text) from public, anon;
grant execute on function public.fin_rejoindre(text) to authenticated;

create policy fin_membres_select on public.fin_membres for select to authenticated
  using (user_id = auth.uid() or public.fin_role() = 'admin');
create policy fin_membres_update on public.fin_membres for update to authenticated
  using (public.fin_role() = 'admin') with check (public.fin_role() = 'admin');
create policy fin_membres_delete on public.fin_membres for delete to authenticated
  using (public.fin_role() = 'admin' and user_id <> auth.uid());

do $$
declare t text;
begin
  foreach t in array array['fin_etablissements','fin_formations','fin_apprenants','fin_paiements','fin_depenses'] loop
    execute format('create table if not exists public.%I (
      id text primary key,
      etablissement_id text,
      data jsonb not null default ''{}''::jsonb,
      maj_le timestamptz not null default now(),
      maj_par uuid default auth.uid()
    )', t);
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to authenticated using (public.fin_role() in (''admin'',''caissier'',''lecteur''))', t||'_select', t);
    if t = 'fin_etablissements' then
      execute format('create policy %I on public.%I for all to authenticated using (public.fin_role() = ''admin'') with check (public.fin_role() = ''admin'')', t||'_write', t);
    else
      execute format('create policy %I on public.%I for insert to authenticated with check (public.fin_role() in (''admin'',''caissier''))', t||'_insert', t);
      execute format('create policy %I on public.%I for update to authenticated using (public.fin_role() in (''admin'',''caissier'')) with check (public.fin_role() in (''admin'',''caissier''))', t||'_update', t);
      execute format('create policy %I on public.%I for delete to authenticated using (public.fin_role() in (''admin'',''caissier''))', t||'_delete', t);
      execute format('create index if not exists %I on public.%I (etablissement_id)', t||'_etab_idx', t);
    end if;
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;
revoke all on public.fin_membres from anon;

create unique index if not exists fin_paiements_numero_uidx on public.fin_paiements ((data->>'numero')) where (data->>'numero') is not null;

create or replace function public.fin_touch() returns trigger language plpgsql set search_path = public as $$
begin new.maj_le := now(); new.maj_par := auth.uid(); return new; end $$;
do $$
declare t text;
begin
  foreach t in array array['fin_etablissements','fin_formations','fin_apprenants','fin_paiements','fin_depenses'] loop
    execute format('create trigger %I before insert or update on public.%I for each row execute function public.fin_touch()', t||'_touch', t);
  end loop;
end $$;

alter publication supabase_realtime add table public.fin_etablissements, public.fin_formations, public.fin_apprenants, public.fin_paiements, public.fin_depenses, public.fin_membres;
