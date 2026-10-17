-- Execute UMA VEZ no SQL Editor do Supabase após a V5.
alter table public.locations add column if not exists pin_color text not null default '#ff4fa3';
alter table public.locations add column if not exists pin_emoji text not null default '💖';
alter table public.locations add column if not exists love_note text;
create table if not exists public.location_requests (
 id uuid primary key default gen_random_uuid(),
 couple_id uuid not null references public.couples(id) on delete cascade,
 sender_id uuid not null references auth.users(id),
 recipient_id uuid not null references auth.users(id),
 status text not null default 'pending' check (status in ('pending','accepted','declined')),
 created_at timestamptz not null default now(),
 constraint request_distinct_users check (sender_id<>recipient_id)
);
alter table public.location_requests enable row level security;
drop policy if exists location_request_read on public.location_requests;
create policy location_request_read on public.location_requests for select to authenticated using(public.is_couple_member(couple_id) and (sender_id=auth.uid() or recipient_id=auth.uid()));
drop policy if exists location_request_create on public.location_requests;
create policy location_request_create on public.location_requests for insert to authenticated with check(
 public.is_couple_member(couple_id) and sender_id=auth.uid() and status='pending' and
 exists(select 1 from public.couples c where c.id=couple_id and ((c.partner_a=sender_id and c.partner_b=recipient_id) or(c.partner_b=sender_id and c.partner_a=recipient_id)))
);
drop policy if exists location_request_reply on public.location_requests;
create policy location_request_reply on public.location_requests for update to authenticated using(public.is_couple_member(couple_id) and recipient_id=auth.uid() and status='pending') with check(public.is_couple_member(couple_id) and recipient_id=auth.uid() and status in ('accepted','declined'));
revoke all on public.location_requests from anon,authenticated;
grant select,insert on public.location_requests to authenticated;
grant update(status) on public.location_requests to authenticated;
-- A opção Realtime pode exigir inclusão manual da tabela na publication supabase_realtime no Dashboard.
