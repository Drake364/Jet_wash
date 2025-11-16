-- Sincroniza usuários do Auth (schema auth) para a tabela pública `users`
-- Crie este script no SQL Editor do Supabase para manter a tabela `users` consistente

create or replace function public.handle_auth_user_created()
returns trigger as $$
begin
  -- Insere na tabela public.users quando um novo usuario é criado no auth.users
  insert into public.users (id, email, name, created_at)
  values (new.id, new.email, new.raw_user_meta->>'full_name', now())
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger para criação de usuários
-- Observação: dependendo das permissões do seu projeto Supabase, você pode precisar executar como um usuário com privilégios.
create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_auth_user_created();

-- Opcional: quando o usuário for removido, marque como inativo
create or replace function public.handle_auth_user_deleted()
returns trigger as $$
begin
  update public.users set email = null where id = old.id;
  return old;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_deleted
after delete on auth.users
for each row
execute procedure public.handle_auth_user_deleted();
