#!/usr/bin/env bash
# ==============================================================================
# MODULE: DATABASE MAINTENANCE & VACUUM (LOCALE & CLOUD)
# Rimuove le esecuzioni storiche per mantenere il database leggero (2-3 MB).
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_BOLD}🧹  PULIZIA E MANUTENZIONE DATABASE (ZERO-COST OPTIMIZATION)${C_RESET}"
echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

# 1. Pulizia Database Locale
echo -e "\n${C_BOLD}💻 1. Pulizia Database Locale:${C_RESET}"
OLD_SIZE=$(get_db_size "$LOCAL_DB")
python3 -c "
import sqlite3
conn = sqlite3.connect('$LOCAL_DB')
c = conn.cursor()
for table in ['execution_entity', 'execution_data', 'execution_metadata', 'execution_annotations']:
    try:
        c.execute(f'DELETE FROM {table};')
    except Exception:
        pass
conn.commit()
c.execute('PRAGMA wal_checkpoint(TRUNCATE);')
c.execute('VACUUM;')
conn.close()
"
NEW_SIZE=$(get_db_size "$LOCAL_DB")
echo -e "  ${C_GREEN}✔${C_RESET} Database locale ottimizzato: ${C_DIM}$OLD_SIZE${C_RESET} ➔ ${C_BOLD}$NEW_SIZE${C_RESET}"

# 2. Pulizia Database Cloud
echo -e "\n${C_BOLD}☁️  2. Pulizia Database Cloud (VPS):${C_RESET}"
ssh_vps "python3 -c \"
import sqlite3
try:
    conn = sqlite3.connect('$VPS_DB')
    c = conn.cursor()
    for table in ['execution_entity', 'execution_data', 'execution_metadata', 'execution_annotations']:
        try:
            c.execute(f'DELETE FROM {table};')
        except Exception:
            pass
    conn.commit()
    c.execute('PRAGMA wal_checkpoint(PASSIVE);')
    conn.close()
    print('  ✔ Database Cloud ripulito con successo.')
except Exception as e:
    print(f'  ! Errore pulizia Cloud: {e}')
\"" 2>/dev/null || echo -e "  ${C_YELLOW}! Impossibile connettersi al Cloud per la pulizia.${C_RESET}"

echo -e "\n${C_GREEN}${C_BOLD}✅ MANUTENZIONE COMPLETATA!${C_RESET}\n"
