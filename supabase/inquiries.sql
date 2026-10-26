-- Reference bootstrap SQL. Applied remotely as create_tepo_inquiries on 2026-10-26.
-- Project: ehqkdzxkgiyrunwssqgw (tepo's house). Inspect existing objects before reapplying.
create table if not exists public.inquiries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  inquiry_type text not null check (inquiry_type in ('general','production')),
  name text not null check (char_length(trim(name)) between 1 and 80),
  email text not null check (char_length(email) between 3 and 254 and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
  subject text not null default '' check (char_length(subject) <= 120),
  message text not null check (char_length(trim(message)) between 10 and 3000),
  source text not null check (source in ('chatbot','contact_page')),
  consent boolean not null check (consent = true)
);
alter table public.inquiries enable row level security;
revoke all on public.inquiries from public, anon, authenticated;
grant insert (inquiry_type,name,email,subject,message,source,consent) on public.inquiries to anon, authenticated;
drop policy if exists "public_inquiry_insert" on public.inquiries;
create policy "public_inquiry_insert" on public.inquiries for insert to anon, authenticated with check (consent = true);
-- No public SELECT/UPDATE/DELETE policy. Read messages in the protected Supabase dashboard.

create index if not exists inquiries_created_at_idx on public.inquiries (created_at desc);
