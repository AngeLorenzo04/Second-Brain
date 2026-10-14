#!/usr/bin/env bash
# ==============================================================================
# MODULE: DEVELOP LOCAL (LABORATORIO SVILUPPO)
# Spegne il Cloud per evitare conflitti Telegram e avvia l'interfaccia locale.
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_BOLD}🛠️  ATTIVAZIONE MODALITÀ SVILUPPO LOCALE (LABORATORIO)${C_RESET}"
echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

# 1. Ferma il container sul Cloud
echo -e "\n${C_YELLOW}1/3${C_RESET} ⏸️  Messa in pausa dell'istanza Cloud per evitare conflitti Telegram..."
if ssh_vps "sudo -n docker stop n8n 2>/dev/null || true" >/dev/null 2>&1; then
    echo -e "    ${C_GREEN}✔${C_RESET} Cloud n8n messo in pausa con successo."
else
    echo -e "    ${C_YELLOW}!${C_RESET} Nessuna risposta dal Cloud o già fermato."
fi

# 2. Controllo directory locale
echo -e "\n${C_YELLOW}2/3${C_RESET} 📁 Verifica permessi database locale..."
mkdir -p "$LOCAL_N8N_DIR"
# Rimozione lock o file temporanei residui
rm -f "$LOCAL_N8N_DIR/crash.journal" 2>/dev/null || true

# 3. Avvio container locale
echo -e "\n${C_YELLOW}3/3${C_RESET} ⚡ Avvio n8n sul PC locale (http://localhost:5678)..."
if is_local_running; then
    echo -e "    ${C_GREEN}✔${C_RESET} n8n locale è già attivo e in esecuzione."
else
    if docker ps -a -q -f "name=^n8n$" | grep -q .; then
        docker start n8n >/dev/null
    else
        docker run -d \
            --name n8n \
            --restart always \
            -p 5678:5678 \
            -v "$LOCAL_N8N_DIR:/home/node/.n8n" \
            -e GENERIC_TIMEZONE="Europe/Rome" \
            -e TZ="Europe/Rome" \
            -e N8N_RUNNERS_GRANT_TOKEN_TTL=300 \
            -e N8N_RUNNERS_TASK_TIMEOUT=120 \
            docker.n8n.io/n8nio/n8n >/dev/null
    fi
    echo -e "    ${C_GREEN}✔${C_RESET} Container n8n locale avviato."
fi

echo -e "\n${C_GREEN}${C_BOLD}🎉 MODALITÀ SVILUPPO PRONTA!${C_RESET}"
echo -e "👉 Apri nel tuo browser: ${C_CYAN}${C_BOLD}http://localhost:5678${C_RESET}"
echo -e "💡 Puoi modificare i workflow via interfaccia grafica con reattività immediata."
echo -e "   Quando hai terminato, esegui il ${C_BOLD}Deploy su Cloud${C_RESET} dal menu."
echo ""
