#!/usr/bin/env bash
# ==============================================================================
# MODULE: WORKFLOW EXPORT (DB -> JSON)
# Estrae i workflow dal database SQLite e li salva formattati in workflows/*.json
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_BOLD}📥  ESPORTAZIONE WORKFLOW DA DATABASE A FILE JSON${C_RESET}"
echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

mkdir -p "$WORKFLOWS_DIR"

python3 -c "
import sqlite3, json, os

db_path = '$LOCAL_DB'
out_dir = '$WORKFLOWS_DIR'

# Mappatura ID workflow a nome file standard
id_to_file = {
    'JoCpc5MdnB34L7pe': '01_subworkflow_core_ingestion.json',
    '6qVfQfqWC337JhCI': '02_telegram_capture_and_agent_polling.json',
    'kX7dailyDigest03': '03_daily_digest_interactive_tasks.json',
    'tFWW6lFWHs2dBUBK': '05_triggers_external_sources.json',
    'colorGcal06':      '06_colorize_university_calendar_events.json',
}

conn = sqlite3.connect(db_path)
c = conn.cursor()

c.execute('SELECT id, name, nodes, connections, settings, staticData, pinData, active FROM workflow_entity')
rows = c.fetchall()

print(f'\n🔍 Trovati {len(rows)} workflow nel database locale:\n')

for r in rows:
    wf_id, name, nodes_str, conn_str, sett_str, static_str, pin_str, active = r
    
    # Determina nome file
    filename = id_to_file.get(wf_id, f'{wf_id}_{name.lower().replace(\" \", \"_\")}.json')
    filepath = os.path.join(out_dir, filename)
    
    nodes = json.loads(nodes_str) if nodes_str else []
    connections = json.loads(conn_str) if conn_str else {}
    settings = json.loads(sett_str) if sett_str else {}
    staticData = json.loads(static_str) if static_str else {}
    pinData = json.loads(pin_str) if pin_str else {}
    
    payload = {
        'id': wf_id,
        'name': name,
        'active': bool(active),
        'nodes': nodes,
        'connections': connections,
        'settings': settings,
        'staticData': staticData,
        'pinData': pinData
    }
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(payload, f, indent=2, ensure_ascii=False)
        
    status_icon = '🟢 ATTIVO' if active else '⚪ DISATTIVO'
    print(f'  ✔ [{wf_id}] {name[:45]:<45} ({len(nodes)} nodi) ➔ {filename}')

conn.close()
print('\n📁 File esportati con successo in: ' + out_dir)
"

echo ""
