#!/usr/bin/env bash
# ==============================================================================
# MODULE: DEPLOY TO CLOUD (PRODUZIONE H24)
# Checkpoint WAL, pulizia log esecuzioni, trasferimento SCP e riavvio VPS.
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_BOLD}🚀  DEPLOY SECOND BRAIN SU GOOGLE CLOUD (H24 ZERO-COST)${C_RESET}"
echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

# 1. Checkpoint WAL locale
echo -e "\n${C_YELLOW}1/5${C_RESET} 💾 Checkpoint WAL del database locale..."
python3 -c "
import sqlite3
try:
    conn = sqlite3.connect('$LOCAL_DB')
    conn.execute('PRAGMA wal_checkpoint(TRUNCATE);')
    conn.close()
    print('    ✔ WAL consolidato con successo.')
except Exception as e:
    print(f'    ! Attenzione WAL: {e}')
"

# 2. Creazione copia temporanea pulita (senza log pesanti di esecuzione)
echo -e "\n${C_YELLOW}2/5${C_RESET} 🧹 Ottimizzazione e compattazione database (rimozione log storici)..."
TEMP_DB="/tmp/second_brain_deploy.sqlite"
rm -f "$TEMP_DB"
cp "$LOCAL_DB" "$TEMP_DB"

python3 -c "
import sqlite3
conn = sqlite3.connect('$TEMP_DB')
c = conn.cursor()
for table in ['execution_entity', 'execution_data', 'execution_metadata', 'execution_annotations']:
    try:
        c.execute(f'DELETE FROM {table};')
    except Exception:
        pass
conn.commit()
c.execute('VACUUM;')
conn.close()
"
ORIG_SIZE=$(get_db_size "$LOCAL_DB")
CLEAN_SIZE=$(get_db_size "$TEMP_DB")
echo -e "    ${C_GREEN}✔${C_RESET} Database compresso: ${C_DIM}$ORIG_SIZE${C_RESET} ➔ ${C_BOLD}$CLEAN_SIZE${C_RESET}"

# 3. Trasferimento file su VPS Google Cloud
echo -e "\n${C_YELLOW}3/5${C_RESET} 📦 Trasferimento database e credenziali crittografate su GCP..."
scp_to_vps "$TEMP_DB" "$VPS_DB" >/dev/null
scp_to_vps "$LOCAL_CONFIG" "$VPS_N8N_DIR/config" >/dev/null
scp_to_vps "$PROJECT_ROOT/start_n8n.sh" "/home/$VPS_USER/start_n8n.sh" >/dev/null
if [ -f "$PROJECT_ROOT/.env" ]; then
    scp_to_vps "$PROJECT_ROOT/.env" "/home/$VPS_USER/.env" >/dev/null
fi
rm -f "$TEMP_DB"
echo -e "    ${C_GREEN}✔${C_RESET} File trasferiti correttamente su $VPS_IP."

# 4. Riavvio container sul Cloud
echo -e "\n${C_YELLOW}4/5${C_RESET} ⚙️  Riavvio del servizio n8n sul Cloud..."
ssh_vps "bash ~/start_n8n.sh" >/dev/null
echo -e "    ${C_GREEN}✔${C_RESET} Container n8n riavviato sul Cloud."

# 5. Spegnimento container locale
echo -e "\n${C_YELLOW}5/5${C_RESET} 🛑 Spegnimento container locale per cedere il polling Telegram al Cloud..."
docker stop n8n >/dev/null 2>&1 || true
echo -e "    ${C_GREEN}✔${C_RESET} Container locale spento."

echo -e "\n${C_GREEN}${C_BOLD}✅ DEPLOY COMPLETATO CON SUCCESSO!${C_RESET}"
echo -e "🤖 Il tuo Second Brain è attivo sul Cloud 24/7."
echo -e "💡 Puoi inviare messaggi al bot Telegram o visualizzare i log con l'opzione ${C_BOLD}Visualizza Log${C_RESET}."
echo ""
