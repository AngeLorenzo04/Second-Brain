#!/usr/bin/env bash
# ==============================================================================
# SECOND BRAIN - ORCHESTRATORE PRINCIPALE (MICROKERNEL)
# Gestione centralizzata del runtime n8n e delle modifiche ai workflow
# ==============================================================================
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$PROJECT_ROOT/kernel"

source "$KERNEL_DIR/common.sh"

# Gestione argomenti da riga di comando per esecuzione rapida
case "$1" in
    dev|sviluppo|local)
        exec "$KERNEL_DIR/mod_dev.sh"
        ;;
    deploy|cloud|prod)
        exec "$KERNEL_DIR/mod_deploy.sh"
        ;;
    export|esporta)
        exec "$KERNEL_DIR/mod_workflow_export.sh"
        ;;
    import|importa)
        shift
        exec "$KERNEL_DIR/mod_workflow_import.sh" "$@"
        ;;
    logs|log)
        shift
        exec "$KERNEL_DIR/mod_logs.sh" "$@"
        ;;
    status|stato|info)
        exec "$KERNEL_DIR/mod_status.sh"
        ;;
    clean|pulisci)
        exec "$KERNEL_DIR/mod_clean.sh"
        ;;
    help|--help|-h)
        echo -e "${C_BOLD}Uso:${C_RESET} ./brain.sh [comando]"
        echo ""
        echo "Comandi disponibili:"
        echo "  dev      - Avvia n8n locale e mette in pausa il Cloud"
        echo "  deploy   - Sincronizza database pulito e attiva Cloud h24"
        echo "  export   - Esporta i workflow dal database SQLite a workflows/*.json"
        echo "  import   - Importa modifiche da workflows/*.json nel database con auto-publish"
        echo "  logs     - Mostra log in tempo reale (Cloud o Locale)"
        echo "  status   - Mostra stato diagnostico e risorse"
        echo "  clean    - Pulisce log di esecuzione e ottimizza database"
        echo ""
        echo "Se eseguito senza argomenti, avvia il menu interattivo."
        exit 0
        ;;
esac

# Menu Interattivo Principale
while true; do
    print_system_banner

    echo -e "  ${C_BOLD}── MODALITÀ DI LAVORO ──────────────────────────────────────────${C_RESET}"
    echo -e "  ${C_CYAN}1)${C_RESET} ${C_BOLD}🛠️  Sviluppo Locale${C_RESET}   (Pausa Cloud ➔ Avvia n8n su http://localhost:5678)"
    echo -e "  ${C_CYAN}2)${C_RESET} ${C_BOLD}🚀 Deploy su Cloud${C_RESET}   (Comprimi DB ➔ Sincronizza su GCP ➔ Avvia h24)"
    echo ""
    echo -e "  ${C_BOLD}── GESTIONE DEI WORKFLOW (MICROKERNEL) ─────────────────────────${C_RESET}"
    echo -e "  ${C_CYAN}3)${C_RESET} ${C_BOLD}📥 Esporta Workflow${C_RESET}  (Estrae da DB SQLite ➔ Salva in workflows/*.json)"
    echo -e "  ${C_CYAN}4)${C_RESET} ${C_BOLD}📤 Importa Workflow${C_RESET}  (Applica workflows/*.json ➔ Auto-Publish nel DB)"
    echo ""
    echo -e "  ${C_BOLD}── DIAGNOSTICA & MANUTENZIONE ──────────────────────────────────${C_RESET}"
    echo -e "  ${C_CYAN}5)${C_RESET} ${C_BOLD}📜 Visualizza Log${C_RESET}    (Streaming in tempo reale Cloud o Locale)"
    echo -e "  ${C_CYAN}6)${C_RESET} ${C_BOLD}📊 Stato Diagnostico${C_RESET} (Verifica RAM, CPU, Container e Versioni)"
    echo -e "  ${C_CYAN}7)${C_RESET} ${C_BOLD}🧹 Pulizia Database${C_RESET}  (Rimuove vecchie esecuzioni ➔ Zero spreco)"
    echo ""
    echo -e "  ${C_RED}0)${C_RESET} Esci"
    echo ""
    read -rp "  Seleziona un'operazione [0-7]: " choice

    case "$choice" in
        1)
            "$KERNEL_DIR/mod_dev.sh"
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        2)
            "$KERNEL_DIR/mod_deploy.sh"
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        3)
            "$KERNEL_DIR/mod_workflow_export.sh"
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        4)
            echo ""
            echo -e "  Vuoi importare ${C_BOLD}tutti i workflow${C_RESET} o uno specifico?"
            echo -e "  ${C_BOLD}1)${C_RESET} Tutti i workflow da workflows/*.json"
            echo -e "  ${C_BOLD}2)${C_RESET} 01_subworkflow_core_ingestion.json"
            echo -e "  ${C_BOLD}3)${C_RESET} 02_telegram_capture_and_agent_polling.json"
            echo -e "  ${C_BOLD}4)${C_RESET} 03_daily_digest_interactive_tasks.json"
            echo -e "  ${C_BOLD}5)${C_RESET} 05_triggers_external_sources.json"
            echo -e "  ${C_BOLD}6)${C_RESET} 06_colorize_university_calendar_events.json"
            echo -e "  ${C_BOLD}0)${C_RESET} Annulla"
            read -rp "  Scelta [1-6]: " wf_choice
            case "$wf_choice" in
                1) "$KERNEL_DIR/mod_workflow_import.sh" ;;
                2) "$KERNEL_DIR/mod_workflow_import.sh" "01_subworkflow_core_ingestion.json" ;;
                3) "$KERNEL_DIR/mod_workflow_import.sh" "02_telegram_capture_and_agent_polling.json" ;;
                4) "$KERNEL_DIR/mod_workflow_import.sh" "03_daily_digest_interactive_tasks.json" ;;
                5) "$KERNEL_DIR/mod_workflow_import.sh" "05_triggers_external_sources.json" ;;
                6) "$KERNEL_DIR/mod_workflow_import.sh" "06_colorize_university_calendar_events.json" ;;
                *) echo "Operazione annullata." ;;
            esac
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        5)
            "$KERNEL_DIR/mod_logs.sh"
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        6)
            "$KERNEL_DIR/mod_status.sh"
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        7)
            "$KERNEL_DIR/mod_clean.sh"
            read -rp "Premi INVIO per tornare al menu principale..." _
            ;;
        0|q|quit|exit)
            echo -e "\n${C_GREEN}Chiusura completata. Arrivederci!${C_RESET}\n"
            exit 0
            ;;
        *)
            echo -e "\n${C_RED}Opzione non valida. Riprova.${C_RESET}"
            sleep 1
            ;;
    esac
done
