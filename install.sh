#!/bin/bash
# Instalador de AutoPrint for Monday — agente Linux
# Uso: sudo bash install.sh
#
# Si hay un .tar.xz en el mismo directorio lo extrae automáticamente.
# Si no, busca el binario ya extraído.

set -euo pipefail

VERSION="1.0.0"
GITHUB_REPO="NachDark/autoprint-agent"
INSTALL_DIR="/opt/daruma-print-agent"
DATA_DIR="/var/lib/daruma-print-agent"
SERVICE_NAME="daruma-print-agent"
SERVICE_USER="daruma-print"
SERVICE_GROUP="daruma-print"

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    echo "Este instalador debe ejecutarse como root (usa: sudo bash install.sh)"
    exit 1
fi

echo "=========================================="
echo "AutoPrint for Monday — Agente Linux v${VERSION}"
echo "=========================================="
echo ""

# Detectar arquitectura
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_SUFFIX="x64"
    TARBALL="autoprint-agent-linux-x64.tar.xz"
    BINARY_NAME="autoprint-for-monday-agent-x64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH_SUFFIX="arm64"
    TARBALL="autoprint-agent-linux-arm64.tar.xz"
    BINARY_NAME="autoprint-for-monday-agent-arm64"
else
    echo "Error: arquitectura no soportada ($ARCH). Se requiere x86_64 o aarch64."
    exit 1
fi

echo "[1/6] Verificando requisitos..."
if ! command -v systemctl &> /dev/null; then
    echo "Error: systemd no está instalado. Se requiere systemd para gestionar el servicio."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH=""

# 1. Buscar binario ya extraído
for path in "$SCRIPT_DIR/$BINARY_NAME" "./$BINARY_NAME" "$BINARY_NAME"; do
    if [[ -f "$path" ]]; then
        BINARY_PATH="$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
        break
    fi
done

# 2. Si no está, buscar .tar.xz y extraer
if [[ -z "$BINARY_PATH" ]]; then
    TARBALL_PATH=""
    for path in "$SCRIPT_DIR/$TARBALL" "./$TARBALL"; do
        if [[ -f "$path" ]]; then
            TARBALL_PATH="$path"
            break
        fi
    done

    if [[ -n "$TARBALL_PATH" ]]; then
        echo "  → Extrayendo $TARBALL_PATH..."
        tar -xJf "$TARBALL_PATH" -C "$SCRIPT_DIR"
        BINARY_PATH="$SCRIPT_DIR/$BINARY_NAME"
    fi
fi

if [[ -z "$BINARY_PATH" ]] || [[ ! -f "$BINARY_PATH" ]]; then
    echo "Error: no se encontró el binario ni el archivo $TARBALL."
    echo "Descárgalo desde: https://github.com/${GITHUB_REPO}/releases/latest"
    exit 1
fi

echo "  ✓ systemd disponible"
echo "  ✓ Binario encontrado: $BINARY_PATH"
echo ""

echo "[2/6] Creando usuario y directorios..."
# Crear usuario del servicio (si no existe)
if ! id "$SERVICE_USER" &> /dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
    echo "  ✓ Usuario $SERVICE_USER creado"
else
    echo "  ✓ Usuario $SERVICE_USER ya existe"
fi

# Crear directorios
mkdir -p "$INSTALL_DIR" "$DATA_DIR"
chmod 755 "$INSTALL_DIR"
chmod 755 "$DATA_DIR"
chown "$SERVICE_USER:$SERVICE_GROUP" "$DATA_DIR"
echo "  ✓ Directorios creados"
echo ""

echo "[3/6] Instalando binario..."
cp "$BINARY_PATH" "$INSTALL_DIR/daruma-print-agent"
chmod 755 "$INSTALL_DIR/daruma-print-agent"
chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/daruma-print-agent"
echo "  ✓ Binario instalado: $INSTALL_DIR/daruma-print-agent ($ARCH_SUFFIX)"
echo ""

echo "[4/6] Registrando servicio systemd..."
SERVICE_FILE="$SCRIPT_DIR/daruma-print-agent.service"

if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "Error: archivo $SERVICE_FILE no encontrado."
    exit 1
fi

cp "$SERVICE_FILE" "/etc/systemd/system/daruma-print-agent.service"
systemctl daemon-reload
echo "  ✓ Servicio registrado"
echo ""

echo "[5/6] Iniciando servicio..."
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Esperar a que el servicio esté listo
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "  ✓ Servicio iniciado correctamente"
else
    echo "  ✗ Error al iniciar el servicio."
    echo "    Verifica con: systemctl status $SERVICE_NAME"
    exit 1
fi
echo ""

echo "[6/6] Verificando accesibilidad..."
# Intentar contactar el agente
for attempt in {1..10}; do
    if curl -s http://localhost:9123/health > /dev/null 2>&1; then
        echo "  ✓ Agente accesible en http://localhost:9123"
        break
    fi
    if [[ $attempt -lt 10 ]]; then
        sleep 1
    else
        echo "  ⚠ No se pudo contactar al agente en http://localhost:9123"
        echo "    El servicio está corriendo, pero aún se está inicializando."
        echo "    Intenta acceder en 10 segundos."
    fi
done
echo ""

echo "=========================================="
echo "✓ Instalación completada exitosamente"
echo "=========================================="
echo ""
echo "Panel web:  http://localhost:9123/"
echo "Datos:      $DATA_DIR"
echo "Servicio:   systemctl status $SERVICE_NAME"
echo ""
echo "Comandos útiles:"
echo "  Ver logs:      journalctl -u daruma-print-agent -f"
echo "  Reiniciar:     systemctl restart daruma-print-agent"
echo "  Desinstalar:   sudo systemctl stop daruma-print-agent && sudo systemctl disable daruma-print-agent && sudo rm -rf $INSTALL_DIR /etc/systemd/system/daruma-print-agent.service"
echo ""
echo "Para configurar el agente, abre http://localhost:9123/ en el navegador."
echo ""
