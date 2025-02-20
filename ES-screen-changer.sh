#!/bin/bash

#-----------------------------------
# Script réalisé a l'aide du script de Sucharek233
# Script réalisé par Jason
#-----------------------------------

# Configuration du terminal
CURR_TTY="/dev/tty1"  # Assurez-vous que le terminal est bien défini
sudo chmod 666 $CURR_TTY
reset

# Masquer le curseur
printf "\e[?25l" > $CURR_TTY
dialog --clear

# Définition des variables
SVG_DIR="/roms/tools/ES-screen-changer"
BACKUP_DIR="/roms/tools/ES-screen-changer"
TARGET_DIR="/bin/emulationstation/resources"
SVG_FILE="splash.svg"
BACKUP_FILE="$BACKUP_DIR/splash_backup.svg"
BACKUP_RESTAURE="$BACKUP_DIR/splash-original-with-text.svg"
GITHUB_REPO="https://github.com/Jason3x/ES-screen-changer-logo.git"

# Fonction pour quitter le script
ExitMenu() {
  printf "\033c" > $CURR_TTY
  if [[ ! -z $(pgrep -f gptokeyb) ]]; then
    pgrep -f gptokeyb | sudo xargs kill -9
  fi
  if [[ ! -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]]; then
    sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  fi
  
  exit 0
}


# Fonction pour mettre à jour les fichiers SVG
mettre_a_jour_svg() {
    dialog --infobox "Vérification de la connexion Internet..." 3 50 > $CURR_TTY
    sleep 2
    
    if ! wget -q --spider http://google.com; then
        dialog --msgbox "Aucune connexion Internet détectée!" 6 50 > $CURR_TTY
        return
    fi
    
    TEMP_DIR="/tmp/ES-screen-changer"
   sudo rm -rf "$TEMP_DIR"
    GITHUB_REPO="https://github.com/Jason3x/Test.git"  # URL correcte pour cloner le dépôt Git
   sudo git clone --depth 1 "$GITHUB_REPO" "$TEMP_DIR" >/dev/null 2>&1
    
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Erreur lors du téléchargement des fichiers." 6 50 > $CURR_TTY
        return
    fi
    
    CHANGED=0
    for file in "$TEMP_DIR"/*.svg; do
        filename=$(basename "$file")
        if [[ ! -f "$SVG_DIR/$filename" || $(diff "$file" "$SVG_DIR/$filename" 2>/dev/null) ]]; then
           sudo cp "$file" "$SVG_DIR/"
            CHANGED=1
        fi
    done
    
    sudo rm -rf "$TEMP_DIR"
    
    if [[ $CHANGED -eq 1 ]]; then
        dialog --msgbox "Mise à jour effectuée avec succès!" 6 50 > $CURR_TTY
    else
        dialog --msgbox "Aucune nouvelle mise à jour." 6 50 > $CURR_TTY
    fi
}


# Fonction pour appliquer le nouveau fichier SVG
ApplySVG() {
    local selected_file=$1
    sudo cp "$selected_file" "$TARGET_DIR/$SVG_FILE"
    sudo chmod 644 "$TARGET_DIR/$SVG_FILE"
    dialog --infobox "Fichier SVG remplacé avec succès!" 3 40 > $CURR_TTY
  sleep 2  # Attendre 2 secondes pour que le message soit visible
  
  # Afficher le message puis fermer automatiquement après 2 secondes
  dialog --infobox "Redémarrage d'EmulationStation..." 3 40 > $CURR_TTY
  sleep 2  # Attendre 2 secondes pour que le message soit visible

  # Redémarrer EmulationStation proprement
  sudo systemctl restart emulationstation &  # Lancer en arrière-plan pour éviter un blocage

  exit 0
}

# Fonction pour restaurer le fichier SVG
RestoreSVG() {
    if [[ -f "$BACKUP_RESTAURE" ]]; then
        sudo cp "$BACKUP_RESTAURE" "$TARGET_DIR/$SVG_FILE"
        sudo chmod 644 "$TARGET_DIR/$SVG_FILE"
        dialog --infobox "Fichier SVG restauré avec succès!" 3 40 > $CURR_TTY
  sleep 2  # Attendre 2 secondes pour que le message soit visible
  
  # Afficher le message puis fermer automatiquement après 2 secondes
  dialog --infobox "Redémarrage d'EmulationStation..." 3 40 > $CURR_TTY
  sleep 2  # Attendre 2 secondes pour que le message soit visible

  # Redémarrer EmulationStation proprement
  sudo systemctl restart emulationstation &  # Lancer en arrière-plan pour éviter un blocage

  exit 0
  
    else
        dialog --msgbox "Aucun fichier de sauvegarde trouvé." 6 40 > $CURR_TTY
    fi
}

# Fonction pour lister les fichiers SVG dans le répertoire
ListSVG() {
    local file_list=()
    
    # Vérifie si le répertoire existe
    if [ -d "$SVG_DIR" ]; then
        # Liste les fichiers .svg dans le répertoire
        for file in "$SVG_DIR"/*.svg; do
            if [ -f "$file" ]; then
                file_list+=("$(basename "$file")" "")
            fi
        done
    else
        dialog --msgbox "Répertoire '$SVG_DIR' introuvable!" 6 40 > $CURR_TTY
        return 1
    fi

    if [ ${#file_list[@]} -eq 0 ]; then
        dialog --msgbox "Aucun fichier SVG trouvé dans '$SVG_DIR'." 6 40 > $CURR_TTY
        return 1
    fi

    # Affiche la liste des fichiers SVG disponibles pour sélection
    selected_file=$(dialog --clear \
        --backtitle "ES screen changer by Jason" \
        --title "Sélectionner un fichier SVG" \
        --menu "" 15 55 10 \
        "${file_list[@]}" 2>&1 > $CURR_TTY)
    
    # Vérifie si un fichier a été sélectionné
    if [[ -n "$selected_file" ]]; then
        ApplySVG "$SVG_DIR/$selected_file"
    else
        dialog --msgbox "Aucun fichier sélectionné." 6 40 > $CURR_TTY
    fi
}

# Menu principal
MainMenu() {
      sudo chmod 666 /dev/uinput
    export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
    if [[ ! -z $(pgrep -f gptokeyb) ]]; then
        pgrep -f gptokeyb | sudo xargs kill -9
    fi
    /opt/inttools/gptokeyb -1 "svg-manager.sh" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &
  
  while true; do
    mainselection=(dialog \
        --backtitle "ES screen changer by Jason" \
        --title "Menu Principal" \
        --no-collapse \
        --clear \
        --cancel-label "Sortir" \
        --menu "Choisissez une option" 15 55 8)
    mainoptions=( 1 "Sélectionner un fichier SVG" \
                  2 "Restaurer le fichier SVG d'origine" \
                  3 "Mettre à jour les fichiers SVG" \
                  4 "Sortir" )
    mainchoices=$("${mainselection[@]}" "${mainoptions[@]}" 2>&1 > $CURR_TTY)
    if [[ $? != 0 ]]; then
      ExitMenu
    fi
    for mchoice in $mainchoices; do
      case $mchoice in
        1) 
          # Appeler la fonction ListSVG pour sélectionner un fichier SVG
          ListSVG;;
        2) 
          # Restaurer le fichier SVG
          RestoreSVG;;
        3)
          #Mettre a jour les fichiers svg
          mettre_a_jour_svg ;;
        4) 
          # Sortir
          ExitMenu;;
      esac
    done
  done
}

# Lancer le menu principal
MainMenu
