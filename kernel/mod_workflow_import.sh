#!/usr/bin/env bash
# ==============================================================================
# MODULE: WORKFLOW IMPORT (JSON -> DB con AUTO-PUBLISH)
# Carica le modifiche dai file workflows/*.json nel database SQLite e allinea
# automaticamente workflow_entity, workflow_history e workflow_published_version.
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_BOLD}📤  IMPORTAZIONE WORKFLOW DA FILE JSON A DATABASE${C_RESET}"
echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

TARGET_FILE="$1"

python3 -c "
import sqlite3, json, os, uuid, sys

db_path = '$LOCAL_DB'
wf_dir = '$WORKFLOWS_DIR'
target_arg = '$TARGET_FILE'

if not os.path.exists(db_path):
    print(f'❌ Errore: Database locale non trovato in {db_path}')
    sys.exit(1)

conn = sqlite3.connect(db_path)
c = conn.cursor()

# Lista file da elaborare
if target_arg and os.path.isfile(target_arg):
    files = [os.path.basename(target_arg)]
elif target_arg and os.path.isfile(os.path.join(wf_dir, target_arg)):
    files = [target_arg]
else:
    files = sorted([f for f in os.listdir(wf_dir) if f.endswith('.json')])

print(f'\n🔄 Importazione in corso per {len(files)} file:\n')

for filename in files:
    filepath = os.path.join(wf_dir, filename)
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f'  ❌ Errore lettura {filename}: {e}')
        continue

    wf_id = data.get('id')
    name = data.get('name', 'Workflow Senza Nome')
    nodes = json.dumps(data.get('nodes', []))
    connections = json.dumps(data.get('connections', {}))
    settings = json.dumps(data.get('settings', {}))
    active = 1 if data.get('active', True) else 0

    # Genera nuovo ID versione univoco
    new_version_id = str(uuid.uuid4())

    # 1. Verifica esistenza nel DB
    c.execute('SELECT id FROM workflow_entity WHERE id = ?', (wf_id,))
    exists = c.fetchone()

    if exists:
        # Aggiorna workflow_entity
        c.execute('''
            UPDATE workflow_entity 
            SET name = ?, nodes = ?, connections = ?, settings = ?, 
                versionId = ?, activeVersionId = ?, active = ?, updatedAt = datetime('now')
            WHERE id = ?
        ''', (name, nodes, connections, settings, new_version_id, new_version_id, active, wf_id))
    else:
        # Inserisci nuovo
        c.execute('''
            INSERT INTO workflow_entity (id, name, nodes, connections, settings, versionId, activeVersionId, active, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
        ''', (wf_id, name, nodes, connections, settings, new_version_id, new_version_id, active))

    # 2. Crea snapshot immutabile in workflow_history
    c.execute('''
        INSERT OR REPLACE INTO workflow_history (versionId, workflowId, nodes, connections, authors, createdAt)
        VALUES (?, ?, ?, ?, '[\"system\"]', datetime('now'))
    ''', (new_version_id, wf_id, nodes, connections))

    # 3. Allinea la versione pubblicata attiva per n8n v2
    c.execute('''
        INSERT OR REPLACE INTO workflow_published_version (workflowId, publishedVersionId, createdAt, updatedAt)
        VALUES (?, ?, datetime('now'), datetime('now'))
    ''', (wf_id, new_version_id))

    # 4. Pulizia trigger orfani (evita trigger fantasma come Gmail in WF05)
    if wf_id == 'tFWW6lFWHs2dBUBK':
        c.execute(\"DELETE FROM workflow_publication_trigger_status WHERE workflowId = ? AND nodeId LIKE '%gmail%'\", (wf_id,))
        c.execute(\"UPDATE workflow_entity SET staticData = '{}' WHERE id = ?\", (wf_id,))

    node_count = len(data.get('nodes', []))
    print(f'  ✔ [{wf_id}] {name[:45]:<45} ({node_count} nodi) ➔ v: {new_version_id[:8]}... (Pubblicato)')

conn.commit()
c.execute('PRAGMA wal_checkpoint(TRUNCATE);')
conn.close()

print('\n🎉 Database locale aggiornato e versioni sincronizzate con successo!')
"

echo ""
