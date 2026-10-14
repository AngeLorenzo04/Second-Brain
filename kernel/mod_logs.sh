#!/usr/bin/env bash
# ==============================================================================
# MODULE: LOGS VIEWER (STREAMING LOCALE / CLOUD)
# Mostra i log del container n8n locale o sul Cloud GCP in tempo reale.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -e "${C_BOLD}📜  VISUALIZZATORE LOG N8N${C_RESET}"
    echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo ""
    echo -e "  ${C_BOLD}1)${C_RESET} Log Cloud GCP (34.30.128.123 - Produzione h24)"
    echo -e "  ${C_BOLD}2)${C_RESET} Log PC Locale (localhost:5678 - Sviluppo)"
    echo -e "  ${C_BOLD}0)${C_RESET} Annulla"
    echo ""
    read -rp "  Seleziona opzione [1-2]: " choice
    case "$choice" in
        1) TARGET="cloud" ;;
        2) TARGET="local" ;;
        *) exit 0 ;;
    esac
fi

if [ "$TARGET" = "cloud" ]; then
    echo -e "\n${C_GREEN}📡 Connessione ai log in streaming del Cloud GCP (Premi Ctrl+C per uscire)...${C_RESET}\n"
    ssh -tt -o StrictHostKeyChecking=no -i "$VPS_SSH_KEY" "$VPS_USER@$VPS_IP" "sudo docker logs -f --tail 30 n8n"
elif [ "$TARGET" = "local" ]; then
    echo -e "\n${C_GREEN}📡 Visualizzazione log in streaming di n8n Locale (Premi Ctrl+C per uscire)...${C_RESET}\n"
    docker logs -f --tail 30 n8n
fi
