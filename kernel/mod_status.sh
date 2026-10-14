#!/usr/bin/env bash
# ==============================================================================
# MODULE: SYSTEM DIAGNOSTICS & STATUS
# Mostra lo stato completo di container locale, VPS, memoria, swap e workflow.
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_BOLD}📊  DIAGNOSTICA E STATO DEL SISTEMA SECOND BRAIN${C_RESET}"
echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

# 1. Stato Container Locale
echo -e "\n${C_BOLD}💻 CONTAINER LOCALE:${C_RESET}"
if is_local_running; then
    docker ps --filter "name=^n8n$" --format "  Stato: {{.Status}} | Porte: {{.Ports}} | Immagine: {{.Image}}"
else
    echo -e "  ${C_GRAY}Container n8n locale non in esecuzione.${C_RESET}"
fi

# 2. Stato Container Cloud & Risorse VPS
echo -e "\n${C_BOLD}☁️  CONTAINER CLOUD (GCP e2-micro 34.30.128.123):${C_RESET}"
ssh_vps "
    echo -n '  Stato Docker: '
    sudo -n docker ps --filter 'name=^n8n$' --format '{{.Status}} (Porte: {{.Ports}})' 2>/dev/null || echo 'Non attivo'
    echo ''
    echo '  Utilizzo Risorse:'
    sudo -n docker stats --no-stream --format '    CPU: {{.CPUPerc}} | RAM: {{.MemUsage}} ({{.MemPerc}})' n8n 2>/dev/null || true
    echo ''
    echo '  Memoria VPS Host:'
    free -h | awk 'NR==2{printf \"    RAM: Usata %s / Totale %s\\n\", \$3, \$2} NR==3{printf \"    SWAP: Usata %s / Totale %s\\n\", \$3, \$2}'
    echo ''
    echo '  Spazio Disco:'
    df -h / | awk 'NR==2{printf \"    Disco: Usato %s / Totale %s (%s libero)\\n\", \$3, \$2, \$4}'
" 2>/dev/null || echo -e "  ${C_RED}Impossibile raggiungere la VPS via SSH.${C_RESET}"

# 3. Stato Database Locale e Workflow Pubblicati
echo -e "\n${C_BOLD}📋 WORKFLOW PUBBLICATI NEL DATABASE LOCALE:${C_RESET}"
python3 -c "
import sqlite3, os
db = '$LOCAL_DB'
if os.path.exists(db):
    conn = sqlite3.connect(db)
    size = os.path.getsize(db) / (1024 * 1024)
    print(f'  Database: {db} ({size:.2f} MB)')
    print('  -------------------------------------------------------------')
    rows = conn.execute('''
        SELECT w.id, w.name, w.active, p.publishedVersionId 
        FROM workflow_entity w
        LEFT JOIN workflow_published_version p ON w.id = p.workflowId
    ''').fetchall()
    for r in rows:
        act = '🟢 ATTIVO' if r[2] else '⚪ DISATTIVO'
        v = (r[3][:8] + '...') if r[3] else 'Nessuna'
        print(f'  {act} | [{r[0]}] {r[1][:40]:<40} | Versione: {v}')
    conn.close()
else:
    print('  Database locale non trovato.')
"
echo ""
