# ~/.claude/commands/banner.md
---
name: banner
description: Affiche un banner ASCII art futuriste centré dans le terminal
argument-hint: <NOM_DU_PROJET>
arguments: text
disable-model-invocation: true
allowed-tools: Bash
---

!`python3 - << 'PYEOF'
import sys, os, shutil

text = "$text".upper() or "BANNER"
cols = shutil.get_terminal_size((80, 24)).columns

# Palette cyberpunk — cyan/magenta dégradé simulé par alternance
C = {
    "border":  "\033[38;5;39m",   # bleu électrique
    "glow":    "\033[38;5;51m",   # cyan vif
    "title":   "\033[38;5;201m",  # magenta/rose
    "dim":     "\033[38;5;238m",  # gris sombre
    "accent":  "\033[38;5;226m",  # jaune néon
    "reset":   "\033[0m",
    "bold":    "\033[1m",
}

# Glyphs FIGlet embarqués — police "small" custom 5 lignes, A-Z 0-9 espace
FONT = {
    ' ': ['   ', '   ', '   ', '   ', '   '],
    'A': [' /\\', '/  ', '/ /\\', '/__\\', ''],
    'B': ['|_)', '|_)', '|_)', '|_)', ''],
    'C': [' _', '/ ', '\\ ', ' \\', ''],
    'D': ['|\\ ', '| \\', '| /', '|/ ', ''],
    'E': ['|_', '|_ ', '|_ ', '|__', ''],
    'F': ['|_', '|_ ', '|_ ', '|  ', ''],
    'G': [' _ ', '/ _', '\\_ ', ' _/', ''],
    'H': ['| |', '|_|', '| |', '| |', ''],
    'I': ['|', '|', '|', '|', ''],
    'J': [' |', ' |', '\\ |', ' _/', ''],
    'K': ['|\\ ', '|/ ', '|\\ ', '| \\', ''],
    'L': ['|  ', '|  ', '|  ', '|__', ''],
    'M': ['|\\/|', '|  |', '|  |', '|  |', ''],
    'N': ['|\\ |', '| \\|', '|  |', '|  |', ''],
    'O': [' _ ', '/ \\', '\\ /', ' - ', ''],
    'P': ['|_)', '|_)', '|  ', '|  ', ''],
    'Q': [' _ ', '/ \\', '\\_/', ' \\_', ''],
    'R': ['|_)', '|_)', '| \\', '|  \\', ''],
    'S': [' _', '(_', ' _)', '__)' , ''],
    'T': ['___', ' | ', ' | ', ' | ', ''],
    'U': ['| |', '| |', '| |', '\\_/', ''],
    'V': ['\\  /', ' \\/ ', ' \\/ ', '  V ', ''],
    'W': ['\\    /', ' \\  / ', '  \\/  ', '   \\/  ', ''],
    'X': ['\\/', '/\\', '/\\', '\\/', ''],
    'Y': ['\\/', ' V ', ' | ', ' | ', ''],
    'Z': ['__', ' /', '/ ', '__', ''],
    '0': [' 0 ', '/ \\', '| 0 |', '\\_/', ''],
    '1': [' 1', '/1 ', ' 1 ', ' 1 ', ''],
    '2': [' 2_', '  _)', ' /  ', '/___', ''],
    '3': ['_3_', '  _)', ' _) ', '___)', ''],
    '4': ['4  4', '4__4', '   4', '   4', ''],
    '5': ['5_ ', '5_ ', ' _)', '__)' , ''],
    '6': [' 6 ', '/6_ ', '\\ 6)', ' 6) ', ''],
    '7': ['77_', '  /', ' / ', '/  ', ''],
    '8': [' 8 ', '(_)', '(_)', '(_)', ''],
    '9': [' 9 ', '(_9)', '  9 ', ' 9  ', ''],
    '-': ['   ', '---', '   ', '   ', ''],
    '_': ['   ', '   ', '   ', '___', ''],
    '.': [' ', ' ', ' ', '.', ''],
}

def render_text(text):
    rows = ['', '', '', '', '']
    for ch in text:
        g = FONT.get(ch, FONT.get('?', ['?','?','?','?','']))
        for i in range(4):
            rows[i] += (g[i] if i < len(g) else '') + ' '
    return rows[:4]

def center(s, width):
    visible = len(s)
    pad = max(0, (width - visible) // 2)
    return ' ' * pad + s

def box_line(char_l, char_m, char_r, fill, width):
    inner = fill * (width - 2)
    return C['border'] + char_l + inner + char_r + C['reset']

# ─── Calcul largeur ───────────────────────────────────────────────────────────
rows = render_text(text)
content_w = max(len(r) for r in rows)
box_w = min(cols, max(content_w + 8, 40))

# ─── Symboles box-drawing ─────────────────────────────────────────────────────
TL, TR, BL, BR = '╔', '╗', '╚', '╝'
H, V = '═', '║'
ML, MR = '╠', '╣'

print()

# top border
print(center(C['border'] + TL + H * (box_w - 2) + TR + C['reset'], cols))

# glow line
dots = '·' * ((box_w - 2))
print(center(C['border'] + V + C['dim'] + dots + C['reset'] + C['border'] + V + C['reset'], cols))

# separator
print(center(C['border'] + ML + H * (box_w - 2) + MR + C['reset'], cols))

# ascii art rows
for row in rows:
    padded = row.center(box_w - 4)
    print(center(C['border'] + V + ' ' + C['title'] + C['bold'] + padded + C['reset'] + C['border'] + V + C['reset'], cols))

# separator
print(center(C['border'] + ML + H * (box_w - 2) + MR + C['reset'], cols))

# tagline / metadata
tag = f"◈  {text}  ◈"
tag_line = tag.center(box_w - 2)
print(center(C['border'] + V + C['glow'] + tag_line + C['reset'] + C['border'] + V + C['reset'], cols))

# bottom dots
print(center(C['border'] + V + C['dim'] + dots + C['reset'] + C['border'] + V + C['reset'], cols))

# bottom border
print(center(C['border'] + BL + H * (box_w - 2) + BR + C['reset'], cols))

print()
PYEOF
`