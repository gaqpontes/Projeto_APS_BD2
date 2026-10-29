#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v podman >/dev/null
command -v python3 >/dev/null
podman compose version
podman volume exists rede_dor_postgres_data || podman volume create rede_dor_postgres_data
podman compose up -d --build

# O Compose pode usar outra porta publicada, configurada em .env.
app_port="$(podman compose port app 8080 | tail -n 1 | awk -F: '{print $NF}')"
frontend_port="$(podman compose port frontend 80 | tail -n 1 | awk -F: '{print $NF}')"
health_url="http://127.0.0.1:${app_port}/actuator/health"
wait_health() {
  for attempt in {1..90}; do
    if python3 -c 'import json,sys,urllib.request; h=json.load(urllib.request.urlopen(sys.argv[1], timeout=3)); sys.exit(0 if h.get("status") == "UP" and h.get("components", {}).get("db", {}).get("status") == "UP" else 1)' "$health_url" 2>/dev/null; then
      echo "OK: aplicação Java e conexão PostgreSQL saudáveis."
      return 0
    fi
    sleep 2
  done
  podman compose logs --tail=80 app db
  echo "Falha: aplicação não ficou saudável." >&2
  return 1
}
psql_db() {
  podman compose exec -T db sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 "$@"' sh "$@"
}

table=""
cleanup() {
  if [ -n "$table" ]; then
    psql_db -c "DROP TABLE IF EXISTS $table;" || true
  fi
}
trap cleanup EXIT

wait_health
marker="infra_$(date +%s)_$$"
# Tabela temporária de verificação, isolada das futuras entidades do projeto.
table="_infra_persistence_$(date +%s)_$$"
psql_db -c "CREATE TABLE $table (marker text PRIMARY KEY); INSERT INTO $table VALUES ('$marker');"
before="$(podman ps --filter label=com.docker.compose.project=rede-dor --filter label=com.docker.compose.service=db --format '{{.ID}}')"
podman compose down
podman compose up -d --build --force-recreate
wait_health
after="$(podman ps --filter label=com.docker.compose.project=rede-dor --filter label=com.docker.compose.service=db --format '{{.ID}}')"
if [ "$before" = "$after" ]; then
  echo "Falha: o container do PostgreSQL não foi recriado." >&2
  exit 1
fi
actual="$(psql_db -Atc "SELECT marker FROM $table;")"
if [ "$actual" != "$marker" ]; then
  echo "Falha: o registro não persistiu após recriar os containers." >&2
  exit 1
fi
psql_db -c "DROP TABLE $table;"
table=""
echo "OK: registro preservado após down, rebuild e recriação do PostgreSQL."
echo "OK: login e senha do banco validados por conexão TCP autenticada."
python3 - "$frontend_port" <<'PY'
import json
import sys
import urllib.request

base = f"http://127.0.0.1:{sys.argv[1]}"
with urllib.request.urlopen(base, timeout=10) as response:
    html = response.read().decode()
assert '<div id="root"></div>' in html, "Página React não encontrada"
with urllib.request.urlopen(base + "/api/actuator/health", timeout=10) as response:
    health = json.load(response)
assert health["status"] == "UP", "Proxy do frontend não alcança backend saudável"
assert health["components"]["db"]["status"] == "UP", "Banco indisponível via frontend"
print("OK: frontend publicado e proxy React -> Java -> PostgreSQL validado.")
PY
