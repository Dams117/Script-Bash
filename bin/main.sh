#!/bin/bash



# 1. Définition des constantes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 2. Fonction d'affichage du titre
show_header() {
    clear
    echo -e "${BLUE}======================================================${NC}"
    echo -e "${BLUE}       PROJET DE FUSION - GROUPE DE 30       ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    echo ""
}

# 3. Importation des modules 
source ./src/utils/logger.sh
source ./src/projet_A/script_a.sh
source ./src/projet_B/script_b.sh

# 4. Menu Principal
while true; do
    show_header
    echo "Choisissez une option :"
    echo "1) Lancer le module Projet A"
    echo "2) Lancer le module Projet B"
    echo "3) Voir les logs"
    echo "q) Quitter"
    echo ""
    read -p "Votre choix : " choix

    case $choix in
        1)
            echo -e "${GREEN}Lancement du Projet A...${NC}"
            # run_projet_a 
            sleep 2
            ;;
        2)
            echo -e "${GREEN}Lancement du Projet B...${NC}"
            # run_projet_b 
            sleep 2
            ;;
        3)
            echo "Affichage des logs..."
            sleep 2
            ;;
        q)
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo -e "${RED}Option invalide !${NC}"
            sleep 1
            ;;
    esac
done
