# Rede Dor

Ambiente inicial do projeto compartilhado de APS e Banco de Dados 2.

- Java 21, Maven e Spring Boot 4.1.2.
- React 19 com Vite 8; build com Node 24 e publicação com Nginx.
- ORM: Spring Data JPA com Hibernate.
- PostgreSQL 18 em container Podman.
- Banco: `rede_dor`; usuário: `admin`; senha: `admin`.
- API: [http://localhost:8080/actuator/health](http://localhost:8080/actuator/health).
- Frontend: [http://localhost:5173](http://localhost:5173).
- PostgreSQL: `localhost:5432` (dentro da rede dos containers, `db:5432`).

As credenciais estão em `.env`, ignorado pelo Git. `.env.example` permite recriar a configuração local.

O código Java fica em `backend/` e o React em `frontend/`. O frontend usa `/api/` para acessar o backend pelo proxy, tanto no Nginx quanto no servidor Vite. A página inicial mostra o estado da conexão; os cadastros e as regras do domínio ainda serão implementados.

## Executar no Windows com o Podman do Debian/WSL

Neste ambiente, Podman e podman-compose estão instalados no Debian/WSL. Abra o terminal Debian, navegue até a pasta `PROJETOS/rede-dor` do clone local e execute:

```bash
podman compose up -d --build
podman compose logs -f app
```

Pelo PowerShell, também é possível executar os comandos por `wsl -d Debian -- ...`. O projeto precisa ser executado no diretório acima para que Compose encontre `compose.yml` e `.env`.

Para uma instalação nativa do Podman no Windows, use os mesmos comandos `podman` na pasta do projeto após iniciar a máquina Podman. É necessário ter um provedor Compose instalado.

## Build, teste e rebuild

```bash
podman compose build app frontend
bash scripts/test-integration.sh
```

O script verifica o endpoint de saúde e a conexão do Java com PostgreSQL; grava um registro de teste, executa `down`, rebuild e recriação dos containers, e confirma que o mesmo registro continua no banco. Também verifica a publicação do frontend e a comunicação pelo proxy até o banco. Ao final remove apenas a tabela de verificação e deixa a aplicação em execução. Requer `python3` no terminal Linux.

Para aplicar mudanças no código:

```bash
podman compose up -d --build --force-recreate app frontend
```

Para parar:

```bash
podman compose down
```

## Persistência

Os dados ficam no volume nomeado **rede_dor_postgres_data**, montado em `/var/lib/postgresql`, conforme o layout do PostgreSQL 18. O Compose cria o volume automaticamente quando ele não existe e reutiliza o volume nas próximas execuções.

Rebuilds, substituição dos containers e `podman compose down` preservam esse volume. O comando `podman compose down -v` remove o volume e seus dados. A remoção explícita do volume, limpeza global de volumes não utilizados ou exclusão da distribuição/máquina Podman também pode apagar os dados.

As variáveis `POSTGRES_USER`, `POSTGRES_PASSWORD` e `POSTGRES_DB` inicializam um volume vazio. Alterá-las no `.env` depois não altera automaticamente usuários, senhas ou bancos existentes.

Hibernate usa `ddl-auto: validate`: não cria, recria ou apaga o esquema automaticamente. As entidades e migrações do domínio serão adicionadas durante o desenvolvimento.

## Container de desenvolvimento

- `container.json`: configuração Dev Container solicitada, utilizável com a CLI e `--config container.json`.
- `.devcontainer/devcontainer.json`: mesma configuração, com caminhos relativos ajustados, no local reconhecido automaticamente pelo VS Code.
- `.devcontainer/compose.dev.yml`: usa o estágio com JDK e Maven, monta o código em `/workspace`, mantém o cache Maven em volume e inicia o React em um serviço Node separado com atualização durante a edição.

Com o VS Code e Dev Containers dentro do WSL, configure o mecanismo como Podman (`dev.containers.dockerPath: podman`), abra esta pasta e use **Dev Containers: Reopen in Container**. O Compose cria o volume do banco automaticamente na primeira execução. Pare a execução normal com `podman compose down` antes de trocar para o modo de desenvolvimento, para liberar as portas.

Dentro do container de desenvolvimento:

```bash
cd /workspace/backend
mvn spring-boot:run
```

O modo desenvolvimento mantém o container Java aberto para edição; a API só inicia ao executar o comando Maven. O React inicia automaticamente no serviço `frontend-dev`, na porta 5173. O serviço de aplicação normal, por sua vez, inicia o JAR automaticamente.

Para desenvolver React diretamente no Windows, com o backend em execução:

```powershell
cd frontend
npm ci
npm run dev
```

Pare antes o serviço `frontend` do Compose para liberar a porta 5173. O Vite encaminha as chamadas de `/api/` para `localhost:8080`.

## Descrição funcional e fontes

A documentação complementar fica na pasta local `md/`, ignorada pelo Git.

- [Spring Boot — requisitos](https://docs.spring.io/spring-boot/system-requirements.html)
- [PostgreSQL — volumes e persistência](https://docs.docker.com/guides/postgresql/)
- [Dev Containers com Compose](https://containers.dev/guide/dockerfile)
