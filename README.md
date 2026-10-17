# LoveSpace V4 — GitHub Pages

O `config.js` já contém a **publishable key** fornecida pelo proprietário e a URL do projeto Supabase. Essa chave é pública, mas jamais use `service_role` ou `secret` no navegador.

**Atualização sobre banco:** as seis tabelas já foram criadas no Supabase. **Não execute `schema.sql` novamente** em seu banco atual. O arquivo está presente para instalações novas.

**Como instalar:** extraia o ZIP, envie todos os arquivos da pasta para a raiz do repositório GitHub (sem a pasta pai), verifique Settings > Pages > Deploy from a branch > main > /(root), e abra o link após o deploy. Em Supabase > Authentication > URL Configuration adicione a URL final do Pages em Site URL/Redirect URLs.

**Se carregar uma versão antiga:** remova o PWA instalado, ou em F12 > Application > Service Workers use Unregister e em Storage use Clear site data. Reabra após atualizar.

**Mapa:** tiles fornecidos pelo OpenStreetMap, Leaflet CSS via CDN com correções locais; requer internet e geolocalização permitida. Só compartilha quando a pessoa aperta o botão; a última posição continua visível até excluí-la.

# 💖 LoveSpace — Nosso Universo (V1)

Site **mobile-first / PWA** para **2 pessoas por universo**. HTML/CSS/JavaScript sem compilação, com autenticação, mensagens e sincronização via Supabase, álbuns privados, pet virtual, localização manual e oito perguntas para casais. É um MVP funcional **depois de configurar um Supabase** — não há simulação de chat ou banco.

## 1. Crie o banco gratuitamente
1. Abra https://supabase.com/dashboard e crie um projeto.
2. No **SQL Editor**, cole o conteúdo completo de `schema.sql`, e execute **uma vez**. Este SQL cria tabelas, funções RPC, políticas RLS, bucket privado e publicação Realtime.
3. Em **Project Settings > API / Data API**, copie a **Project URL** e a chave **publishable** (ou chave `anon` legada); edite `config.js`. A URL deste projeto já foi preenchida com o endereço público informado na conversa. **Você ainda precisa inserir sua chave pública.**
4. **Nunca use a `service_role`/`secret` key no JavaScript**. A publishable/anon foi projetada para uso no navegador, desde que o banco esteja protegido pelas políticas RLS.
5. Em **Authentication > Providers > Email**, habilite e-mail/senha. Se a confirmação de e-mail estiver ligada, confirme seu endereço de e-mail antes de entrar.
6. Em **Authentication > URL Configuration**, defina **Site URL** como a URL final do GitHub Pages e inclua essa URL na lista de Redirect URLs. Exemplo: `https://SEU_USUARIO.github.io/SEU_REPOSITORIO/`.

## 2. Publique no GitHub Pages
1. Crie repositório (por exemplo, `lovespace`) no GitHub.
2. Envie **todos os arquivos desta pasta** para a raiz do repositório (`index.html`, `style.css`, `app.js`, `config.js`, `schema.sql`, `icon.svg`, `manifest.webmanifest`, `sw.js`). Não publique chaves secretas nem senhas.
3. Vá em **Settings > Pages** → **Deploy from a branch** → `main` / `(root)` → Save.
4. Acesse `https://SEU_USUARIO.github.io/lovespace/`. Se fizer mudanças em scripts e não aparecerem, recarregue a página ignorando cache ou aumente a versão em `sw.js`.
5. No Android, abra no Chrome e escolha **Adicionar à tela inicial** / **Instalar app**. No iPhone, use Safari → compartilhar → **Adicionar à Tela de Início**.
6. Para teste local, execute `python -m http.server 8000` na pasta e abra `http://localhost:8000` (evite `file://`).

## 3. Como testar de verdade
- **Pessoa A**: cadastra, faz login, clica em *Criar universo*, escolhe data e copia código.
- **Pessoa B**: usa **outro e-mail**, cria conta, faz login e insere código em *Entrar no universo*.
- A e B testam **em navegadores/perfis/celulares separados**: enviar mensagens, inserir fotos, alimentar pet, responder às perguntas, compartilhar localização e apagar a posição.
- Chat, respostas, pet, álbum, data e localizações persistem no Supabase e são visíveis apenas aos usuários autorizados por RLS. Para mostrar mudanças automaticamente, habilite a publicação `supabase_realtime` conforme SQL e mantenha a página aberta.

## Limites e privacidade
- **Sem rastreamento contínuo**: o mapa envia um único ponto quando o usuário consente, usando a API Geolocation (requer HTTPS ou localhost). A última posição fica no banco até removida; a pessoa pode revogar a permissão do navegador separadamente.
- **Mapa**: tiles do OpenStreetMap via serviço público, adequados a protótipo e sujeitos à política de uso. Não envie tráfego elevado ao servidor público sem provedor de tiles apropriado.
- **Álbum**: bucket privado, URL assinada com expiração de 1 hora, formatos JPG/PNG/WebP e até 5 MB; lembre que membros podem salvar imagens que visualizam. Cada pessoa só pode apagar suas próprias lembranças pela interface.
- **Chat**: mostra as 100 mensagens mais recentes; o contador conta apenas estas, não o total histórico. Mesma limitação das primeiras 100 fotos exibidas.
- **Pet**: alimentado no máximo uma vez por hora *por casal* (aplicado no banco); nome compartilhado.
- **Jogos**: respostas sincronizadas e comparadas quando ambos responderem. Não há sorteio de perguntas nem sistema de moedas. Não é competição antifraude.
- **PWA**: shell básico com cache; funcionalidades que dependem da rede **não funcionam offline**. Notificações push e geolocalização em segundo plano não estão presentes.
- **Segurança**: conteúdo privado só é acessível mediante autenticação e associação ao casal; **mensagens e arquivos não têm criptografia ponta a ponta**. A plataforma de hospedagem pode acessá-los conforme as políticas do serviço. Códigos são convites de uso único (pareamento bloqueado depois da segunda conta). Não há excluir casal, trocar parceiro, recuperar fotos removidas ou bloquear abuso nesta primeira versão.
- **Importante**: este é um protótipo para avaliação e não foi submetido a auditoria externa de segurança. Antes de lançar para vários usuários, inclua testes automatizados de RLS, backup, LGPD/termos/privacidade, moderação/denúncia, exclusão de dados e restrições de uploads.

## Problemas comuns
- `Failed to fetch` / `Invalid API key`: revise URL e chave pública em `config.js`.
- `Email not confirmed`: confirme o e-mail no link recebido.
- `permission denied` / `row-level security`: execute o SQL todo em um projeto limpo; certifique-se de estar autenticado.
- Mensagem só aparece ao atualizar: confira **Database > Publications > supabase_realtime**; o SQL tenta habilitar as tabelas.
- Upload falha: verifique se bucket `memories` e políticas em `storage.objects` foram criados.
- Localização falha: use HTTPS, permita acesso ao local, e mantenha a aba aberta no momento do compartilhamento.

Criado para estudo e testes — sem afiliação com Couple2.

## Correção do mapa (V2)
Esta versão usa os arquivos Leaflet CSS e JS via jsDelivr, inclui regras CSS para impedir o desalinhamento dos tiles, invalida o tamanho do mapa após a exibição da aba, e aumenta a versão do cache do PWA. Se estiver vendo a versão antiga: no navegador abra DevTools > Application > Service Workers > Unregister e limpe dados de armazenamento deste site, depois atualize.


## Correção V3 do mapa
Foi incluído `leaflet-fix.css` local, para manter o posicionamento dos mosaicos mesmo se o CSS externo não carregar. O marcador agora usa `circleMarker` (não depende de imagens PNG). O cache do PWA foi atualizado para v3. Faça upload de TODOS os arquivos na raiz do repositório, aguarde o GitHub Actions e abra a página em uma janela anônima para conferir. No dispositivo com PWA antigo, remova o app instalado e reinstale após a atualização. Se persistir, use F12 → Network para checar `leaflet.js`, `leaflet-fix.css` e os tiles de OpenStreetMap.


## Novidades V5: localização e mensagens
- No Mapa do Amor há os botões **Ver minha posição** e **Ver posição do meu par**. Eles centralizam o mapa na **última posição compartilhada**; não há rastreamento contínuo. Cada pessoa deve tocar em **Compartilhar minha posição agora**, consentir e autorizar a geolocalização. É possível apagar a própria posição a qualquer momento.
- No Chat há **Ativar som** e **Permitir notificações**. Os avisos dependem de eventos Realtime (habilite a publicação de `messages` no Supabase se necessário). O som precisa ser ativado por interação; as notificações do sistema precisam de permissão do navegador e são disparadas somente quando o site está aberto. **Não há Push com app fechado** nesta versão (isso exige Web Push, assinaturas e backend/Edge Function).
- Não execute novamente `schema.sql` se seu banco já está configurado. Basta substituir os arquivos web.
- No GitHub Pages, aguarde o deploy e teste em aba anônima caso o service worker anterior persista.
