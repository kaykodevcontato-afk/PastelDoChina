-- Execute uma única vez no SQL Editor do Supabase.
create extension if not exists pgcrypto;
create table public.couples (
 id uuid primary key default gen_random_uuid(),
 invite_code text unique not null default upper(encode(gen_random_bytes(6),'hex')),
 partner_a uuid not null references auth.users(id),
 partner_b uuid unique references auth.users(id),
 started_on date not null default current_date,
 created_at timestamptz not null default now(),
 constraint different_partners check(partner_b is null or partner_b <> partner_a)
);
create unique index couple_partner_a_unique on public.couples(partner_a);
create unique index couple_partner_b_unique on public.couples(partner_b) where partner_b is not null;

create function public.my_couple_id() returns uuid language sql stable security definer set search_path = '' as $$
 select id from public.couples where partner_a = (select auth.uid()) or partner_b = (select auth.uid()) limit 1;
$$;
create function public.is_couple_member(c uuid) returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.couples where id=c and (partner_a=(select auth.uid()) or partner_b=(select auth.uid())));
$$;
revoke all on function public.my_couple_id() from public;
revoke all on function public.is_couple_member(uuid) from public;
grant execute on function public.my_couple_id(),public.is_couple_member(uuid) to authenticated;

create function public.create_couple(p_started_on date) returns public.couples language plpgsql security definer set search_path = '' as $$
declare result public.couples;
begin
 if (select auth.uid()) is null then raise exception 'Entre na sua conta'; end if;
 if public.my_couple_id() is not null then raise exception 'Você já participa de um casal'; end if;
 insert into public.couples(partner_a,started_on) values ((select auth.uid()),coalesce(p_started_on,current_date)) returning * into result;
 return result;
end; $$;
create function public.join_couple(p_code text) returns public.couples language plpgsql security definer set search_path = '' as $$
declare result public.couples;
begin
 if (select auth.uid()) is null then raise exception 'Entre na sua conta'; end if;
 if public.my_couple_id() is not null then raise exception 'Você já participa de um casal'; end if;
 update public.couples set partner_b=(select auth.uid())
 where invite_code=upper(trim(p_code)) and partner_b is null and partner_a<>(select auth.uid()) returning * into result;
 if result.id is null then raise exception 'Código inválido ou já utilizado'; end if;
 return result;
end; $$;
revoke all on function public.create_couple(date), public.join_couple(text) from public;
grant execute on function public.create_couple(date),public.join_couple(text) to authenticated;

create table public.messages (
 id bigint generated always as identity primary key,
 couple_id uuid not null references public.couples(id) on delete cascade,
 sender_id uuid not null references auth.users(id),
 body text not null check (char_length(body) between 1 and 1000),
 created_at timestamptz not null default now()
);
create index messages_couple_time on public.messages(couple_id,created_at);
create table public.memories (
 id uuid primary key default gen_random_uuid(),
 couple_id uuid not null references public.couples(id) on delete cascade,
 user_id uuid not null references auth.users(id),
 caption text not null default '' check (char_length(caption)<=400),
 image_path text not null,
 created_at timestamptz not null default now()
);
create table public.pets (
 couple_id uuid primary key references public.couples(id) on delete cascade,
 name text not null default 'Pipoca' check (char_length(name) between 1 and 24),
 xp int not null default 0 check (xp >= 0),
 last_fed timestamptz
);
create table public.locations (
 couple_id uuid not null references public.couples(id) on delete cascade,
 user_id uuid not null references auth.users(id),
 lat double precision not null check(lat between -90 and 90),
 lng double precision not null check(lng between -180 and 180),
 shared_at timestamptz not null default now(),
 primary key(couple_id,user_id)
);
create table public.game_answers (
 couple_id uuid not null references public.couples(id) on delete cascade,
 user_id uuid not null references auth.users(id),
 question_id integer not null check(question_id between 1 and 8),
 answer text not null check(length(answer) between 1 and 120),
 created_at timestamptz not null default now(),
 primary key(couple_id,user_id,question_id)
);

alter table public.couples enable row level security;
alter table public.messages enable row level security;
alter table public.memories enable row level security;
alter table public.pets enable row level security;
alter table public.locations enable row level security;
alter table public.game_answers enable row level security;
create policy couples_read on public.couples for select to authenticated using(public.is_couple_member(id));
create policy couples_date_update on public.couples for update to authenticated using(public.is_couple_member(id)) with check(public.is_couple_member(id));
-- Não permitir modificar integrantes/código diretamente via API.
revoke insert,delete,update on public.couples from authenticated;
grant select,update(started_on) on public.couples to authenticated;

create policy messages_select on public.messages for select to authenticated using(public.is_couple_member(couple_id));
create policy messages_insert on public.messages for insert to authenticated with check(public.is_couple_member(couple_id) and sender_id=(select auth.uid()));
create policy memories_select on public.memories for select to authenticated using(public.is_couple_member(couple_id));
create policy memories_insert on public.memories for insert to authenticated with check(public.is_couple_member(couple_id) and user_id=(select auth.uid()));
create policy memories_delete on public.memories for delete to authenticated using(public.is_couple_member(couple_id) and user_id=(select auth.uid()));
create policy pets_select on public.pets for select to authenticated using(public.is_couple_member(couple_id));
create policy locations_select on public.locations for select to authenticated using(public.is_couple_member(couple_id));
create policy locations_insert on public.locations for insert to authenticated with check(public.is_couple_member(couple_id) and user_id=(select auth.uid()));
create policy locations_update on public.locations for update to authenticated using(public.is_couple_member(couple_id) and user_id=(select auth.uid())) with check(public.is_couple_member(couple_id) and user_id=(select auth.uid()));
create policy locations_delete on public.locations for delete to authenticated using(public.is_couple_member(couple_id) and user_id=(select auth.uid()));
create policy games_select on public.game_answers for select to authenticated using(public.is_couple_member(couple_id));
create policy games_insert on public.game_answers for insert to authenticated with check(public.is_couple_member(couple_id) and user_id=(select auth.uid()));
create policy games_update on public.game_answers for update to authenticated using(public.is_couple_member(couple_id) and user_id=(select auth.uid())) with check(public.is_couple_member(couple_id) and user_id=(select auth.uid()));

-- Pet: somente RPC altera XP e nome (sem INSERT/UPDATE direto).
create function public.feed_pet(p_couple uuid) returns public.pets language plpgsql security definer set search_path = '' as $$
declare result public.pets;
begin
 if not public.is_couple_member(p_couple) then raise exception 'Acesso negado'; end if;
 insert into public.pets(couple_id) values(p_couple) on conflict do nothing;
 update public.pets set xp=xp+10,last_fed=now()
 where couple_id=p_couple and (last_fed is null or last_fed<=now()-interval '1 hour') returning * into result;
 if result.couple_id is null then raise exception 'O pet já foi alimentado na última hora'; end if;
 return result;
end; $$;
create function public.rename_pet(p_couple uuid,p_name text) returns public.pets language plpgsql security definer set search_path = '' as $$
declare result public.pets;
begin
 if not public.is_couple_member(p_couple) then raise exception 'Acesso negado'; end if;
 if length(trim(p_name)) not between 1 and 24 then raise exception 'Nome inválido'; end if;
 insert into public.pets(couple_id,name) values(p_couple,trim(p_name)) on conflict(couple_id) do update set name=excluded.name returning * into result;
 return result;
end; $$;
revoke all on function public.feed_pet(uuid),public.rename_pet(uuid,text) from public;
grant execute on function public.feed_pet(uuid),public.rename_pet(uuid,text) to authenticated;
revoke insert,update,delete on public.pets from authenticated;
grant select on public.pets to authenticated;

-- Arquivos privados: nome do objeto sempre "UUID_DO_CASAL/UUID_DO_ARQUIVO.ext".
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('memories','memories',false,5242880,array['image/jpeg','image/png','image/webp'])
 on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
create policy memory_objects_read on storage.objects for select to authenticated
 using(bucket_id='memories' and public.is_couple_member((split_part(name,'/',1))::uuid));
create policy memory_objects_upload on storage.objects for insert to authenticated
 with check(bucket_id='memories' and public.is_couple_member((split_part(name,'/',1))::uuid));
create policy memory_objects_delete on storage.objects for delete to authenticated
 using(bucket_id='memories' and public.is_couple_member((split_part(name,'/',1))::uuid));

-- Habilitar eventos no Realtime (se já existir, ignore erro de duplicate_object).
do $$ begin
 alter publication supabase_realtime add table public.messages,public.memories,public.locations,public.pets,public.game_answers,public.couples;
exception when duplicate_object then null;
end $$;
