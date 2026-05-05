#!/usr/bin/env bash
# =============================================================================
# SETUP.sh — Installation complète ZSH
# Usage  : bash SETUP.sh
# Shells : lancé depuis bash, zsh, sh, ou tout POSIX-compatible
# OS     : macOS arm64 (cible principale) + Linux
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Couleurs (désactivées si le terminal ne les supporte pas)
# -----------------------------------------------------------------------------
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; PURPLE=''; NC=''
fi

info()    { printf "${CYAN}▸ %s${NC}\n" "$*"; }
success() { printf "${GREEN}✅ %s${NC}\n" "$*"; }
warn()    { printf "${YELLOW}⚠️  %s${NC}\n" "$*"; }
error()   { printf "${RED}❌ %s${NC}\n" "$*" >&2; }
header()  { printf "\n${CYAN}══════════════════════════════════════════\n  %s\n══════════════════════════════════════════${NC}\n\n" "$*"; }

# -----------------------------------------------------------------------------
# Détection du shell courant (le script est toujours lancé en bash/sh,
# mais on détecte aussi le shell par défaut de l'utilisateur)
# -----------------------------------------------------------------------------
detect_shell() {
    CURRENT_SHELL=$(basename "${SHELL:-unknown}")
    RUNNER_SHELL=$(basename "$(ps -p $$ -o comm= 2>/dev/null || echo unknown)")
    info "Script exécuté via : $RUNNER_SHELL"
    info "Shell par défaut actuel : $CURRENT_SHELL"

    if [ "$CURRENT_SHELL" = "zsh" ]; then
        warn "Zsh est déjà votre shell par défaut — on va juste mettre à jour la config."
    elif [ "$CURRENT_SHELL" = "bash" ]; then
        info "Bash détecté comme shell par défaut → sera remplacé par Zsh."
    else
        warn "Shell '$CURRENT_SHELL' détecté — le script configure Zsh indépendamment."
    fi
}

# -----------------------------------------------------------------------------
# Vérification et installation de Zsh si absent
# -----------------------------------------------------------------------------
ensure_zsh() {
    if command -v zsh >/dev/null 2>&1; then
        ZSH_BIN=$(command -v zsh)
        success "Zsh trouvé : $ZSH_BIN ($(zsh --version | head -1))"
        return
    fi

    info "Zsh absent — installation..."
    if [ "$(uname)" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install zsh
        else
            # macOS 12+ livre zsh natif dans /bin/zsh, normalement jamais absent
            error "Homebrew absent et zsh introuvable. Installez zsh manuellement."
            exit 1
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y zsh git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh git
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm zsh git
    else
        error "Gestionnaire de paquets non détecté. Installez zsh manuellement."
        exit 1
    fi
    ZSH_BIN=$(command -v zsh)
    success "Zsh installé : $ZSH_BIN"
}

# -----------------------------------------------------------------------------
# Installation des plugins (en parallèle)
# -----------------------------------------------------------------------------
install_plugins() {
    info "Installation des plugins Zsh..."
    mkdir -p ~/.zsh/plugins

    clone_if_absent() {
        local repo=$1 dest=$2 name=$3
        if [ ! -d "$dest" ]; then
            info "Clonage $name..."
            git clone --depth=1 "$repo" "$dest" 2>&1 | tail -1
            success "$name installé"
        else
            success "$name déjà présent"
        fi
    }

    # Clonages en parallèle
    clone_if_absent \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ~/.zsh/plugins/zsh-syntax-highlighting \
        "Syntax Highlighting" &

    clone_if_absent \
        https://github.com/zsh-users/zsh-autosuggestions \
        ~/.zsh/plugins/zsh-autosuggestions \
        "Autosuggestions" &

    clone_if_absent \
        https://github.com/zsh-users/zsh-completions \
        ~/.zsh/plugins/zsh-completions \
        "Enhanced Completions" &

    wait
    success "Plugins prêts"
}

# -----------------------------------------------------------------------------
# Écriture du .zshrc (version avec git_info intégrée)
# Le heredoc est en 'EOF' pour éviter l'expansion dans le script parent,
# mais les variables zsh à l'intérieur doivent rester littérales.
# -----------------------------------------------------------------------------
write_zshrc() {
    info "Écriture de ~/.zshrc..."

    # Sauvegarde horodatée si un zshrc existe déjà
    if [ -f ~/.zshrc ]; then
        local backup=~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
        cp ~/.zshrc "$backup"
        info "Ancien .zshrc sauvegardé → $backup"
    fi

    cat > ~/.zshrc << 'ZSHRC_EOF'
# Configuration ZSH — RAM/CPU/Git temps réel
# ========================================
# CONFIGURATION DE BASE
# ========================================

autoload -U colors && colors
setopt PROMPT_SUBST AUTO_CD CORRECT EXTENDED_GLOB

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

autoload -U compinit && compinit -u

# ========================================
# CONFIGURATION VISUELLE DES FICHIERS
# ========================================

export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.py=01;33:*.js=01;33:*.json=01;33:*.yml=01;33:*.yaml=01;33:*.toml=01;33:*.ini=01;33:*.cfg=01;33:*.conf=01;33:*.log=00;37:*.md=01;37:*.txt=00;37:*.sh=01;32:*.bash=01;32:*.zsh=01;32:*.fish=01;32'

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%F{blue}── %d ──%f%b'
zstyle ':completion:*:messages' format '%F{green}%d%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# ========================================
# FONCTIONS SYSTÈME TEMPS RÉEL
# ========================================

ram_usage() {
    local ram_used
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local pages_used=$(vm_stat | grep "Pages active\|Pages inactive\|Pages speculative\|Pages wired down" | awk '{sum += $3} END {print sum}' | sed 's/\.//')
        if [[ -n "$pages_used" && $pages_used -gt 0 ]]; then
            ram_used=$(echo "scale=1; $pages_used * 4096 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0.0")
        else
            ram_used="0.0"
        fi
    else
        if command -v free >/dev/null 2>&1; then
            ram_used=$(free -g | grep Mem | awk '{printf("%.1f", $3)}')
        else
            ram_used="0.0"
        fi
    fi
    echo "%{$fg[cyan]%}RAM: ${ram_used}Go%{$reset_color%}"
}

cpu_usage() {
    local cpu_percent
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cpu_percent=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        [[ -z "$cpu_percent" ]] && cpu_percent="0"
    else
        if command -v top >/dev/null 2>&1; then
            cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        else
            local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
            local num_cores=$(nproc 2>/dev/null || echo 1)
            cpu_percent=$(echo "scale=1; $load_avg * 100 / $num_cores" | bc 2>/dev/null || echo "0")
        fi
    fi
    local cpu_color="green"
    (( $(echo "$cpu_percent > 70" | bc -l 2>/dev/null || echo 0) )) && cpu_color="red"
    (( $(echo "$cpu_percent > 40" | bc -l 2>/dev/null || echo 0) )) && [[ "$cpu_color" != "red" ]] && cpu_color="yellow"
    echo "%{$fg[$cpu_color]%}CPU: ${cpu_percent}%%%{$reset_color%}"
}

command_status() {
    echo "%(?:%{$fg[green]%}✓:%{$fg[red]%}✗)%{$reset_color%}"
}

current_time() {
    echo "%{$fg[yellow]%}%D{%H:%M:%S}%{$reset_color%}"
}

# Informations Git : projet + statut en français + branche
git_info() {
    git rev-parse --git-dir >/dev/null 2>&1 || return

    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -z "$branch" ]] && return

    local project
    project=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")

    local git_status
    git_status=$(git status --porcelain 2>/dev/null)

    local status_label="" status_color="green"

    if [[ -n "$git_status" ]]; then
        local has_staged has_unstaged has_untracked
        has_staged=$(echo "$git_status" | grep -E '^[MADRC]' | wc -l | tr -d ' ')
        has_unstaged=$(echo "$git_status" | grep -E '^.[MD]' | wc -l | tr -d ' ')
        has_untracked=$(echo "$git_status" | grep -E '^\?\?' | wc -l | tr -d ' ')
        status_color="yellow"

        if [[ $has_staged -gt 0 && $has_unstaged -gt 0 ]]; then
            status_label="à commiter · modifié"
        elif [[ $has_staged -gt 0 ]]; then
            status_label="à commiter"
        elif [[ $has_unstaged -gt 0 && $has_untracked -gt 0 ]]; then
            status_label="modifié · non suivi"
        elif [[ $has_unstaged -gt 0 ]]; then
            status_label="modifié"
        elif [[ $has_untracked -gt 0 ]]; then
            status_label="non suivi"
        fi
    fi

    local status_part=""
    if [[ -n "$status_label" ]]; then
        status_part=" (%{$fg[$status_color]%}${status_label}%{$fg[magenta]%})"
    fi

    echo "%{$fg[magenta]%}[${project}${status_part} %{$fg[$status_color]%}${branch}%{$fg[magenta]%}]%{$reset_color%}"
}

# ========================================
# THÈMES
# ========================================

change_prompt() {
    case $1 in
        "light")
            PROMPT='%{$fg[green]%}%1~%{$reset_color%}$(git_info) %{$fg[blue]%}❯%{$reset_color%} '
            RPROMPT='$(current_time)'
            ;;
        "full")
            PROMPT='%{$fg[blue]%}╭─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[blue]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%} $(ram_usage) $(cpu_usage)
%{$fg[blue]%}╰─%{$reset_color%}$(command_status)$(git_info) %{$fg[blue]%}❯%{$reset_color%} '
            RPROMPT='$(current_time)'
            ;;
        *)
            echo "Usage: change_prompt [light|full]"
            ;;
    esac
}

# ========================================
# PLUGINS EXTERNES
# ========================================

[[ -d ~/.zsh/plugins/zsh-completions ]] && fpath=(~/.zsh/plugins/zsh-completions/src $fpath)

if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
    ZSH_HIGHLIGHT_STYLES[default]=none
    ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
    ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
    ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
    ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[path]=fg=blue,underline
    ZSH_HIGHLIGHT_STYLES[globbing]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
    ZSH_HIGHLIGHT_STYLES[arg0]=fg=green,bold
fi

if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,italic"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_USE_ASYNC=true
fi

# ========================================
# ENVIRONNEMENT
# ========================================

export EDITOR=nano
export PAGER=less
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.local/bin:$PATH"
[[ "$OSTYPE" == "darwin"* ]] && export PATH="/opt/homebrew/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# ========================================
# PROMPT PAR DÉFAUT (full)
# ========================================

PROMPT='%{$fg[blue]%}╭─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[blue]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%} $(ram_usage) $(cpu_usage)
%{$fg[blue]%}╰─%{$reset_color%}$(command_status)$(git_info) %{$fg[blue]%}❯%{$reset_color%} '
RPROMPT='$(current_time)'

# ========================================
# AIDE
# ========================================

zsh_help() {
    echo "🏠 ZSH — monitoring temps réel + Git"
    echo ""
    echo "📋 Commandes:"
    echo "  change_prompt light   Prompt minimaliste"
    echo "  change_prompt full    Prompt complet RAM/CPU (défaut)"
    echo "  zsh_help              Cette aide"
    echo ""
    echo "🌿 Git (automatique dans le prompt) :"
    echo "  [projet (statut) branche]"
    echo "  Statuts : à commiter · modifié · non suivi"
    echo "  Vert = propre, Jaune = modifications en cours"
    echo ""
    echo "📊 Monitoring :"
    echo "  RAM: XX.XGo   CPU: XX%   HH:MM:SS (droite)"
    echo "  CPU: vert <40% · jaune <70% · rouge >70%"
    echo ""
    echo "🔧 Plugins :"
    [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
        && echo "  ✅ Syntax Highlighting" || echo "  ❌ Syntax Highlighting"
    [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
        && echo "  ✅ Autosuggestions"    || echo "  ❌ Autosuggestions"
    [[ -d ~/.zsh/plugins/zsh-completions ]] \
        && echo "  ✅ Enhanced Completions" || echo "  ❌ Enhanced Completions"
}

echo "🏠 ZSH prêt — 'zsh_help' pour l'aide"
ZSHRC_EOF

    success ".zshrc écrit"
}

# -----------------------------------------------------------------------------
# Changement du shell par défaut vers Zsh
# -----------------------------------------------------------------------------
set_default_shell() {
    local zsh_bin
    zsh_bin=$(command -v zsh)

    # S'assurer que zsh est dans /etc/shells
    if ! grep -qF "$zsh_bin" /etc/shells 2>/dev/null; then
        info "Ajout de $zsh_bin dans /etc/shells..."
        echo "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
    fi

    if [ "$SHELL" = "$zsh_bin" ]; then
        success "Shell par défaut déjà Zsh"
        return
    fi

    info "Changement du shell par défaut vers $zsh_bin..."
    if [ "$(uname)" = "Darwin" ]; then
        chsh -s "$zsh_bin"
    else
        sudo chsh -s "$zsh_bin" "$USER" 2>/dev/null || sudo usermod -s "$zsh_bin" "$USER"
    fi
    success "Shell par défaut → Zsh (effectif à la prochaine connexion)"
}

# -----------------------------------------------------------------------------
# Vérification finale
# -----------------------------------------------------------------------------
run_checks() {
    info "Vérifications..."
    command -v zsh >/dev/null 2>&1         && success "Zsh binaire"       || error "Zsh binaire manquant"
    [ -f ~/.zshrc ]                         && success ".zshrc présent"    || error ".zshrc absent"
    [ -d ~/.zsh/plugins/zsh-syntax-highlighting ] && success "Plugin syntax-highlighting" || warn "Plugin syntax-highlighting absent"
    [ -d ~/.zsh/plugins/zsh-autosuggestions ]     && success "Plugin autosuggestions"     || warn "Plugin autosuggestions absent"
    [ -d ~/.zsh/plugins/zsh-completions ]         && success "Plugin completions"         || warn "Plugin completions absent"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    header "SETUP ZSH"
    detect_shell

    printf "\nCe script va :\n"
    printf "  • Installer Zsh si absent\n"
    printf "  • Cloner les 3 plugins (~/.zsh/plugins/)\n"
    printf "  • Écrire ~/.zshrc (sauvegarde auto si existant)\n"
    printf "  • Définir Zsh comme shell par défaut\n\n"

    printf "Continuer ? (Y/n) : "
    read -r REPLY
    case "$REPLY" in
        [Nn]*) info "Annulé."; exit 0 ;;
    esac

    ensure_zsh
    install_plugins
    write_zshrc
    set_default_shell
    run_checks

    header "INSTALLATION TERMINÉE"
    printf "${GREEN}✅ Tout est prêt.${NC}\n\n"
    printf "Lancez maintenant :\n"
    printf "  ${CYAN}exec zsh${NC}   → activation immédiate\n"
    printf "  ${CYAN}zsh_help${NC}   → voir toutes les options\n\n"

    printf "Activer Zsh maintenant ? (Y/n) : "
    read -r REPLY
    case "$REPLY" in
        [Nn]*) exit 0 ;;
        *) exec zsh ;;
    esac
}

trap 'error "Erreur ligne $LINENO — vérifiez les permissions et relancez."; exit 1' ERR

main "$@"
