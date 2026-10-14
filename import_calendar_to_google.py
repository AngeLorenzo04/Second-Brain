#!/usr/bin/env python3
"""
University Timetable Importer & Color Coder for Google Calendar
Parses university semester iCal and maps courses to distinct Google Calendar colors.
"""

import os
import re
from datetime import datetime

ICS_PATH = '/home/angelo/Downloads/Calendar_18.49.58.13.10.2026.ics'
OUTPUT_ICS = '/home/angelo/Desktop/Personal/Second_Brain/Orario_Semestre_Unizar_ColorCoded.ics'

COURSE_COLORS = {
    '30223': {'name': 'Inteligencia artificial', 'color_id': '3', 'color_name': 'Viola / Uva', 'hex': '#A47AE2'},
    '30239': {'name': 'Diseño y administración de redes', 'color_id': '6', 'color_name': 'Arancione / Mandarino', 'hex': '#FF887C'},
    '30232': {'name': 'Algoritmia para problemas difíciles', 'color_id': '10', 'color_name': 'Verde / Basilico', 'hex': '#51B749'},
    '30211': {'name': 'Redes de computadores', 'color_id': '9', 'color_name': 'Blu / Cobalto', 'hex': '#5484ED'},
    '30246': {'name': 'Ingeniería web', 'color_id': '5', 'color_name': 'Giallo / Banana', 'hex': '#FBD75B'},
    'FESTIVO': {'name': 'Día festivo', 'color_id': '8', 'color_name': 'Grigio / Grafite', 'hex': '#E1E1E1'}
}

def detect_course(summary):
    summary_lower = summary.lower()
    for code, info in COURSE_COLORS.items():
        if code in summary or info['name'].lower() in summary_lower:
            return code, info
    if 'festivo' in summary_lower or 'fiesta' in summary_lower:
        return 'FESTIVO', COURSE_COLORS['FESTIVO']
    return 'OTHER', {'name': 'Altro', 'color_id': '1', 'color_name': 'Lavanda', 'hex': '#7AE7BF'}

def parse_and_convert():
    if not os.path.exists(ICS_PATH):
        print(f"File non trovato: {ICS_PATH}")
        return

    with open(ICS_PATH, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    blocks = content.split('BEGIN:VEVENT')
    header = blocks[0]
    
    events_out = []
    stats = {}

    for i, b in enumerate(blocks[1:]):
        event_body = b.split('END:VEVENT')[0]
        
        summary_m = re.search(r'SUMMARY:(.*?)(?:\r?\n)', event_body)
        summary = summary_m.group(1).strip() if summary_m else 'Lezione Università'
        
        code, cinfo = detect_course(summary)
        stats[cinfo['name']] = stats.get(cinfo['name'], 0) + 1

        # Add Google Calendar color category and enhanced properties
        enhanced_block = event_body.strip()
        if 'CATEGORIES:' not in enhanced_block:
            enhanced_block += f"\r\nCATEGORIES:{cinfo['name']}"
        else:
            enhanced_block = re.sub(r'CATEGORIES:(.*?)(?:\r?\n)', f'CATEGORIES:{cinfo["name"]}\\r\\n', enhanced_block)

        # In standard iCal, X-APPLE-STRUCTURED-LOCATION or COLOR property can be injected
        enhanced_block += f"\r\nCOLOR:{cinfo['hex']}\r\nX-COLOR-ID:{cinfo['color_id']}\r\nX-GOOGLE-COLOR-ID:{cinfo['color_id']}"

        events_out.append(f"BEGIN:VEVENT\r\n{enhanced_block}\r\nEND:VEVENT")

    with open(OUTPUT_ICS, 'w', encoding='utf-8') as f:
        f.write(header)
        f.write('\r\n'.join(events_out))
        f.write('\r\nEND:VCALENDAR\r\n')

    print(f"✅ Generato file calendario con colori: {OUTPUT_ICS}")
    print(f"📊 Totale eventi convertiti: {len(events_out)}")
    print("Suddivisione per corso e colore:")
    for cname, count in sorted(stats.items(), key=lambda x: -x[1]):
        print(f"  • {cname}: {count} lezioni")

if __name__ == '__main__':
    parse_and_convert()
