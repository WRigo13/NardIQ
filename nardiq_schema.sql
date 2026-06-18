-- NardIQ Schema para Supabase (LogIQ project)
-- Execute no SQL Editor do Supabase

-- Perfis de alunos
create table if not exists nardiq_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  avatar_emoji text default '🧠',
  total_points integer default 0,
  total_correct integer default 0,
  total_answered integer default 0,
  current_streak integer default 0,
  best_streak integer default 0,
  level integer default 1,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Progresso por questão
create table if not exists nardiq_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references nardiq_profiles(id) on delete cascade,
  puzzle_id text not null,
  ano text not null,
  categoria text not null,
  correct boolean not null,
  points_earned integer default 0,
  answered_at timestamptz default now()
);

-- Ranking global (view calculada)
create or replace view nardiq_ranking as
select
  p.id,
  p.username,
  p.avatar_emoji,
  p.total_points,
  p.total_correct,
  p.total_answered,
  p.level,
  p.best_streak,
  case when p.total_answered > 0
    then round((p.total_correct::numeric / p.total_answered) * 100)
    else 0
  end as accuracy,
  rank() over (order by p.total_points desc) as position
from nardiq_profiles p
order by p.total_points desc;

-- RLS
alter table nardiq_profiles enable row level security;
alter table nardiq_progress enable row level security;

create policy "Perfil público visível" on nardiq_profiles for select using (true);
create policy "Usuário edita próprio perfil" on nardiq_profiles for all using (auth.uid() = id);

create policy "Progresso público visível" on nardiq_progress for select using (true);
create policy "Usuário insere próprio progresso" on nardiq_progress for insert with check (auth.uid() = user_id);

-- Trigger para atualizar updated_at
create or replace function update_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger nardiq_profiles_updated_at
  before update on nardiq_profiles
  for each row execute function update_updated_at();

