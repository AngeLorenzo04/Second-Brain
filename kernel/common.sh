#!/usr/bin/env bash
# ==============================================================================
# SECOND BRAIN - MICROKERNEL COMMON MODULE
# ==============================================================================

# Percorsi di sistema
export PROJECT_ROOT="/home/angelo/Desktop/Personal/Second_Brain"
export WORKFLOWS_DIR="$PROJECT_ROOT/workflows"
export LOCAL_N8N_DIR="$HOME/.n8n"
export LOCAL_DB="$LOCAL_N8N_DIR/database.sqlite"
export LOCAL_CONFIG="$LOCAL_N8N_DIR/config"

# Carica variabili d'ambiente da .env se presente
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Configurazione VPS Google Cloud (configurabile da .env con fallback)
export VPS_USER="${VPS_USER:-dicandiangelorenzo}"
export VPS_IP="${VPS_IP:-34.30.128.123}"
export VPS_SSH_KEY="${VPS_SSH_KEY:-$HOME/.ssh/gcp_vps}"
export VPS_N8N_DIR="/home/$VPS_USER/.n8n"
export VPS_DB="$VPS_N8N_DIR/database.sqlite"

# Colori terminale
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_RED="\033[1;31m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[1;34m"
C_MAGENTA="\033[1;35m"
C_CYAN="\033[1;36m"
C_GRAY="\033[0;90m"

# Funzione wrapper SSH verso VPS con socket riutilizzabile ultra-veloce
ssh_vps() {
    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -o ControlMaster=auto \
        -o ControlPath=/tmp/ssh_mux_%h_%p_%r \
        -o ControlPersist=10m \
        -i "$VPS_SSH_KEY" "$VPS_USER@$VPS_IP" "$@"
}

# Funzione wrapper SCP verso VPS con socket riutilizzabile
scp_to_vps() {
    scp -o StrictHostKeyChecking=no \
        -o ConnectTimeout=8 \
        -o ControlMaster=auto \
        -o ControlPath=/tmp/ssh_mux_%h_%p_%r \
        -o ControlPersist=10m \
        -i "$VPS_SSH_KEY" "$1" "$VPS_USER@$VPS_IP:$2"
}

# Verifica se il container locale è attivo
is_local_running() {
    if docker ps -q -f "name=^n8n$" 2>/dev/null | grep -q .; then
        return 0
    else
        return 1
    fi
}

# Verifica se il container cloud è attivo (timeout rapido)
is_cloud_running() {
    local res
    res=$(ssh_vps "sudo -n docker ps -q -f 'name=^n8n$'" 2>/dev/null || true)
    if [ -n "$res" ]; then
        return 0
    else
        return 1
    fi
}

# Calcola dimensione leggibile del DB
get_db_size() {
    local file="$1"
    if [ -f "$file" ]; then
        ls -lh "$file" | awk '{print $5}'
    else
        echo "0B"
    fi
}

# Stampa intestazione stato del sistema (immediata, senza blocchi)
print_system_banner() {
    clear 2>/dev/null || true
    echo -e "${C_CYAN}${C_BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════════════╗"
    echo "  ║                   🧠 SECOND BRAIN - MICROKERNEL                   ║"
    echo "  ║                 Gestione Workflow & Runtime n8n                   ║"
    echo "  ╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"

    # Controllo stato locale (istantaneo)
    local local_status
    if is_local_running; then
        local_status="${C_GREEN}● ATTIVO${C_RESET} ${C_DIM}(http://localhost:5678)${C_RESET}"
    else
        local_status="${C_GRAY}○ SPENTO${C_RESET}"
    fi

    local local_size
    local_size=$(get_db_size "$LOCAL_DB")

    echo -e "  💻 ${C_BOLD}Ambiente Locale:${C_RESET} $local_status  ${C_DIM}[DB: $local_size]${C_RESET}"
    echo -e "  ☁️  ${C_BOLD}Ambiente Cloud:${C_RESET}  ${C_CYAN}GCP e2-micro (34.30.128.123)${C_RESET} ${C_DIM}[Opzione 6 per diagnostica]${C_RESET}"
    echo -e "  ${C_GRAY}─────────────────────────────────────────────────────────────────────${C_RESET}"
    echo ""
}
