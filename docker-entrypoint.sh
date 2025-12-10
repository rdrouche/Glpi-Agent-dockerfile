#!/bin/bash
set -e

# Var for Entrypoint
CONF_DIR="/etc/glpi-agent/conf.d"
ROOT_CONF_DIR="/etc/glpi-agent"

echo ""
echo ""
echo "------------------------------------------------------------"
echo "Merci d'utiliser le conteneur GLPI-AGENT de RDR-IT ! 🚀"
echo "Vous pouvez retrouver tous nos tutos et guides ici :"
echo "👉 https://rdr-it.com"
echo ""
echo "Pour toute question ou problème, consultez notre documentation."
echo "------------------------------------------------------------"
echo ""
echo ""
echo "================================================="
echo "Preparation de la configuration de GLPI-AGENT ..."
echo "================================================="

# Env variable
GLPI_SERVER="${GLPI_SERVER:-""}"
GLPI_SERVER_SSL_FINGER_PRINT="${GLPI_SERVER_SSL_FINGER_PRINT:-""}"
GLPI_SERVER_NO_SSL_CHECK="${GLPI_SERVER_NO_SSL_CHECK:-false}"

GLPI_TAG="${GLPI_TAG:-docker-glpi-agent}"
GLPI_DEBUG="${GLPI_DEBUG:-false}"

GLPI_HTTPD="${GLPI_HTTPD:-true}"
GLPI_HTTPD_PORT="${GLPI_HTTPD_PORT:-62354}"
GLPI_TOOLBOX_ENABLE="${GLPI_TOOLBOX_ENABLE:-1}"

GLPI_TOOLBOX_AUTH_PORT="${GLPI_TOOLBOX_AUTH_PORT:-62354}"
GLPI_TOOLBOX_AUTH_ENABLE="${GLPI_TOOLBOX_AUTH_ENABLE:-false}"
GLPI_TOOLBOX_AUTH_USER="${GLPI_TOOLBOX_AUTH_USER:-""}"
GLPI_TOOLBOX_AUTH_PASSWORD="${GLPI_TOOLBOX_AUTH_USER:-""}"

echo "🔍 Verification des variables d environnement..."

REQUIRED_VARS=(
    GLPI_SERVER
)

for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo "❌ Variable obligatoire manquante : $VAR"
    EXIT=1
  else
    echo "✔️  $VAR : ${!VAR}"
  fi
done

if [ "$EXIT" = 1 ]; then
  echo "⛔ Fin du script : certaines variables ne sont pas definies."
  exit 1
fi
echo "✅ Variables obligatoire OK"

# Suppression fichier de configuration existant
rm -f $ROOT_CONF_DIR/toolbox-plugin.local
rm -f $ROOT_CONF_DIR/basic-authentication-server-plugin.local

if [ "$GLPI_TOOLBOX_ENABLE" = "1" ] || [ "${GLPI_TOOLBOX_ENABLE}" = "true" ]; then
    echo "--- ✔️ Enable toolbox"
    echo "disabled = no" > "$ROOT_CONF_DIR/toolbox-plugin.local"
fi

if [ "$GLPI_TOOLBOX_AUTH_ENABLE" = "1" ] || [ "${GLPI_TOOLBOX_AUTH_ENABLE}" = "true" ]; then
    if [ -n "$GLPI_TOOLBOX_AUTH_USER" ] && [ -n "$GLPI_TOOLBOX_AUTH_PASSWORD" ]; then
        echo "--- 🔒 Enable toolbox Authentification"
        echo "disabled = no" > "$ROOT_CONF_DIR/basic-authentication-server-plugin.local"
        echo "user = ${GLPI_TOOLBOX_AUTH_USER}" >> "$ROOT_CONF_DIR/basic-authentication-server-plugin.local"
        echo "password = ${GLPI_TOOLBOX_AUTH_PASSWORD}" >> "$ROOT_CONF_DIR/basic-authentication-server-plugin.local"
    else
        echo ""
        echo ""
        echo "--- ⚠️ Toolbox auth enabled but user or password not defined, skipping configuration"
        echo ""
        echo ""
        sleep 3
    fi
fi

if [[ "$GLPI_TOOLBOX_AUTH_ENABLE" = "1" && "$GLPI_TOOLBOX_AUTH_PORT" != "$GLPI_HTTPD_PORT" ]]; then
    echo "--- Port Authentifiation =/= du port HTTPD"
    echo "port = ${GLPI_TOOLBOX_AUTH_PORT}" >> "$ROOT_CONF_DIR/basic-authentication-server-plugin.local"
fi

# Activer l'UI web si demandé
ARGS=()
if [ "$GLPI_HTTPD" = "1" ] || [ "${GLPI_HTTPD}" = "true" ]; then
    echo "--- 🌍 Enable Web Server on port : ${GLPI_HTTPD_PORT}"
    ARGS+=("--daemon" "--httpd-ip=0.0.0.0" "--httpd-port=${GLPI_HTTPD_PORT}")
fi

# Génération dynamique de fichiers de config
if [ -n "$GLPI_SERVER" ]; then
    echo "--- 🖥️  Serveur GLPI : ${GLPI_SERVER}"
    ARGS+=("--server=${GLPI_SERVER}")
fi

if [ "$GLPI_SERVER_NO_SSL_CHECK" = "1" ] || [ "${GLPI_SERVER_NO_SSL_CHECK}" = "true" ]; then
    echo "--- ❗ Disable check SSL on GLPI Server ${GLPI_SERVER}"
    ARGS+=("--no-ssl-check")
fi

if [ -n "$GLPI_SERVER_SSL_FINGER_PRINT" ]; then
    echo "--- Finger print configured"
    ARGS+=("--ssl-fingerprint=${GLPI_SERVER_SSL_FINGER_PRINT}")
fi

#if [ -n "$GLPI_LOCAL" ]; then
#    echo "local = $GLPI_LOCAL" > "$CONF_DIR/local.cfg"
#fi

if [ -n "$GLPI_TAG" ]; then
    echo "--- 🏷️ TAG for Inventory : ${GLPI_TAG}"
    ARGS+=("--tag=${GLPI_TAG}")
fi

if [ "$GLPI_DEBUG" = "1" ] || [ "${GLPI_DEBUG}" = "true" ]; then
    echo "--- 🐛 Enable verbose - only for debug ! "
    ARGS+=("--debug")
fi


ARGS+=("--no-fork")
ARGS+=("$@")

echo ""
echo ""
echo " ☑️  Parametres : ${ARGS[@]}"
echo ""
echo ""
echo "🚀 🚀 🚀 Demarrage de l agent dans 3 secondes ..."
echo ""
echo ""
sleep 3
exec /usr/bin/glpi-agent "${ARGS[@]}"