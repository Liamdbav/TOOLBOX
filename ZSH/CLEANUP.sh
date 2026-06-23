#!/usr/bin/env bash
# =============================================================================
# CLEANUP.sh — Remise à zéro complète de la config ZSH
# Usage  : bash CLEANUP.sh
# Effet  : supprime plugins, .zshrc, restaure le shell d'origine
# =============================================================================

set -e

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; NC=''
fi

info()    { printf "${CYAN}▸ %s${NC}\n" "$*"; }
success() { printf "${GREEN}✅ %s${NC}\n" "$*"; }
warn()    { printf "${YELLOW}⚠️  %s${NC}\n" "$*"; }
error()   { printf "${RED}❌ %s${NC}\n" "$*" >&2; }
header()  { printf "\n${CYAN}══════════════════════════════════════════\n  %s\n══════════════════════════════════════════${NC}\n\n" "$*"; }

# -----------------------------------------------------------------------------
# Suppression des plugins
# -----------------------------------------------------------------------------
remove_plugins() {
    if [ -d ~/.zsh/plugins ]; then
        info "Suppression des plugins Zsh..."
        rm -rf ~/.zsh/plugins/zsh-syntax-highlighting
        rm -rf ~/.zsh/plugins/zsh-autosuggestions
        rm -rf ~/.zsh/plugins/zsh-completions
        rm -rf ~/.zsh/plugins/git
        success "Plugins supprimés"

        # Supprimer le dossier plugins s'il est vide
        if [ -z "$(ls -A ~/.zsh/plugins 2>/dev/null)" ]; then
            rmdir ~/.zsh/plugins
            info "Dossier ~/.zsh/plugins supprimé (vide)"
        else
            warn "Dossier ~/.zsh/plugins conservé (contient d'autres fichiers)"
        fi

        # Supprimer ~/.zsh si vide
        if [ -d ~/.zsh ] && [ -z "$(ls -A ~/.zsh 2>/dev/null)" ]; then
            rmdir ~/.zsh
            info "Dossier ~/.zsh supprimé (vide)"
        fi
    else
        info "Aucun plugin à supprimer (~/.zsh/plugins absent)"
    fi
}

# -----------------------------------------------------------------------------
# Suppression / restauration du .zshrc
# -----------------------------------------------------------------------------
remove_zshrc() {
    if [ ! -f ~/.zshrc ]; then
        info ".zshrc absent, rien à faire"
        return
    fi

    # Chercher la sauvegarde la plus récente produite par SETUP.sh
    local latest_backup
    latest_backup=$(ls -t ~/.zshrc.backup.* 2>/dev/null | head -1)

    if [ -n "$latest_backup" ]; then
        info "Sauvegarde trouvée : $latest_backup"
        printf "Restaurer cet ancien .zshrc ? (Y/n) : "
        read -r REPLY
        case "$REPLY" in
            [Nn]*)
                rm -f ~/.zshrc
                success ".zshrc supprimé (aucune restauration)"
                ;;
            *)
                cp "$latest_backup" ~/.zshrc
                success ".zshrc restauré depuis $latest_backup"
                ;;
        esac
    else
        info "Aucune sauvegarde trouvée — suppression du .zshrc"
        rm -f ~/.zshrc
        success ".zshrc supprimé"
    fi

    # Proposer de purger toutes les sauvegardes
    local backups
    backups=$(ls ~/.zshrc.backup.* 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backups" -gt 0 ]; then
        printf "Supprimer les %s fichier(s) de sauvegarde .zshrc.backup.* ? (y/N) : " "$backups"
        read -r REPLY
        case "$REPLY" in
            [Yy]*)
                rm -f ~/.zshrc.backup.*
                success "Sauvegardes supprimées"
                ;;
            *)
                info "Sauvegardes conservées"
                ;;
        esac
    fi
}

# -----------------------------------------------------------------------------
# Restauration du shell par défaut
# -----------------------------------------------------------------------------
restore_shell() {
    local current_shell
    current_shell=$(basename "$SHELL")

    if [ "$current_shell" != "zsh" ]; then
        info "Shell par défaut actuel : $current_shell (pas Zsh, rien à faire)"
        return
    fi

    info "Shell par défaut actuel : zsh"

    # Proposer bash comme cible par défaut (présent partout)
    local bash_bin
    bash_bin=$(command -v bash 2>/dev/null || echo "")

    if [ -z "$bash_bin" ]; then
        warn "bash introuvable — impossible de proposer un shell de remplacement"
        return
    fi

    printf "Restaurer bash (%s) comme shell par défaut ? (Y/n) : " "$bash_bin"
    read -r REPLY
    case "$REPLY" in
        [Nn]*)
            info "Shell par défaut conservé (zsh)"
            ;;
        *)
            if ! grep -qF "$bash_bin" /etc/shells 2>/dev/null; then
                echo "$bash_bin" | sudo tee -a /etc/shells >/dev/null
            fi
            if [ "$(uname)" = "Darwin" ]; then
                chsh -s "$bash_bin"
            else
                sudo chsh -s "$bash_bin" "$USER" 2>/dev/null || sudo usermod -s "$bash_bin" "$USER"
            fi
            success "Shell par défaut → $bash_bin (effectif à la prochaine connexion)"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Nettoyage de l'historique zsh (optionnel)
# -----------------------------------------------------------------------------
clean_history() {
    if [ -f ~/.zsh_history ]; then
        printf "Supprimer également ~/.zsh_history ? (y/N) : "
        read -r REPLY
        case "$REPLY" in
            [Yy]*)
                rm -f ~/.zsh_history
                success "Historique Zsh supprimé"
                ;;
            *)
                info "Historique conservé"
                ;;
        esac
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    header "CLEANUP ZSH"

    printf "Ce script va supprimer :\n"
    printf "  • ~/.zsh/plugins/ (syntax-highlighting, autosuggestions, completions)\n"
    printf "  • ~/.zshrc (avec option de restauration depuis sauvegarde)\n"
    printf "  • Optionnellement : ~/.zsh_history\n"
    printf "  • Optionnellement : restaurer bash comme shell par défaut\n\n"

    printf "${RED}Cette opération est partiellement irréversible.${NC}\n"
    printf "Continuer ? (Y/n) : "
    read -r REPLY
    case "$REPLY" in
        [Nn]*) info "Annulé."; exit 0 ;;
    esac

    echo
    remove_plugins
    echo
    remove_zshrc
    echo
    restore_shell
    echo
    clean_history

    header "NETTOYAGE TERMINÉ"
    printf "${GREEN}Terminal remis à zéro.${NC}\n"
    printf "Ouvrez un nouveau terminal ou tapez : ${CYAN}exec \$SHELL${NC}\n\n"
}

trap 'error "Erreur ligne $LINENO."; exit 1' ERR

main "$@"
