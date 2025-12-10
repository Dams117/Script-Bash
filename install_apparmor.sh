#!/bin/bash

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un titre
afficher_titre() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Fonction pour afficher une question
poser_question() {
    echo -e "${YELLOW}$1${NC}"
}

# Fonction pour afficher un succès
afficher_succes() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Fonction pour afficher une erreur
afficher_erreur() {
    echo -e "${RED}✗ $1${NC}"
}

# Vérifier si le script est lancé en root
if [ "$EUID" -ne 0 ]; then 
    afficher_erreur "Ce script doit être exécuté avec sudo"
    exit 1
fi

# Introduction
clear
afficher_titre "Bienvenue dans l'assistant AppArmor"

echo "Ce script va vous aider à installer et configurer AppArmor"
echo "pour protéger vos applications."
echo ""

# Expliquer AppArmor
afficher_titre "Qu'est-ce qu'AppArmor ?"

echo "AppArmor est un système de sécurité Linux qui contrôle ce que"
echo "vos programmes peuvent faire sur votre ordinateur."
echo ""
echo "Par exemple, vous pouvez :"
echo "  - Empêcher un navigateur d'accéder à vos documents personnels"
echo "  - Bloquer l'accès aux fichiers de mots de passe"
echo "  - Limiter les programmes à certains dossiers seulement"
echo ""

read -p "Appuyez sur Entrée pour continuer..."

# Vérifier si AppArmor est installé
afficher_titre "Vérification d'AppArmor"

if command -v aa-status &> /dev/null; then
    afficher_succes "AppArmor est déjà installé !"
    aa-status | head -n 5
    echo ""
else
    afficher_erreur "AppArmor n'est pas installé."
    poser_question "Voulez-vous installer AppArmor ? (o/n)"
    read -r reponse
    
    if [[ "$reponse" =~ ^[Oo]$ ]]; then
        echo "Installation d'AppArmor en cours..."
        apt update
        apt install -y apparmor apparmor-utils
        
        if [ $? -eq 0 ]; then
            afficher_succes "AppArmor a été installé avec succès !"
        else
            afficher_erreur "Erreur lors de l'installation."
            exit 1
        fi
    else
        echo "Installation annulée."
        exit 0
    fi
fi

# ===== CRÉATION DE PROFIL PERSONNALISÉ =====

afficher_titre "Création d'un profil AppArmor personnalisé"

poser_question "Voulez-vous créer un profil de sécurité pour une application ? (o/n)"
read -r creer_profil

if [[ ! "$creer_profil" =~ ^[Oo]$ ]]; then
    echo "Au revoir !"
    exit 0
fi

# Demander le chemin du programme
echo ""
poser_question "Quel est le chemin complet du programme à protéger ?"
echo "Exemple: /usr/bin/firefox ou /home/user/mon_script.sh"
read -r chemin_programme

# Vérifier que le fichier existe
if [ ! -f "$chemin_programme" ]; then
    afficher_erreur "Le fichier $chemin_programme n'existe pas !"
    exit 1
fi

afficher_succes "Programme trouvé : $chemin_programme"

# Rendre le programme exécutable si ce n'est pas déjà le cas
chmod +x "$chemin_programme"

echo ""
afficher_titre "Configuration des permissions"

# Questions sur les permissions

# 1. Accès internet
echo ""
poser_question "Le programme doit-il avoir accès à Internet ? (o/n)"
read -r acces_internet

# 2. Accès aux documents personnels
echo ""
poser_question "Le programme doit-il accéder à vos documents personnels (dossier ~/Documents) ? (o/n)"
read -r acces_documents

# 3. Accès aux téléchargements
echo ""
poser_question "Le programme doit-il accéder à votre dossier Téléchargements (~/Downloads) ? (o/n)"
read -r acces_telechargements

# 4. Accès aux clés SSH
echo ""
poser_question "Le programme doit-il accéder à vos clés SSH privées (~/.ssh) ? (o/n)"
echo "(ATTENTION : donnez cet accès uniquement si nécessaire !)"
read -r acces_ssh

# 5. Accès aux fichiers système sensibles
echo ""
poser_question "Le programme doit-il lire les fichiers de mots de passe système (/etc/shadow) ? (o/n)"
echo "(ATTENTION : ceci est très sensible, refusez sauf si absolument nécessaire !)"
read -r acces_shadow

# 6. Dossiers supplémentaires
echo ""
poser_question "Y a-t-il d'autres dossiers spécifiques auxquels le programme doit accéder ? (o/n)"
read -r autres_dossiers

dossiers_supplementaires=""
if [[ "$autres_dossiers" =~ ^[Oo]$ ]]; then
    echo "Entrez les chemins des dossiers (un par ligne, tapez 'fin' pour terminer) :"
    while true; do
        read -r dossier
        if [ "$dossier" = "fin" ]; then
            break
        fi
        dossiers_supplementaires="$dossiers_supplementaires
  $dossier/** rw,"
    done
fi

# Générer le nom du profil
nom_profil=$(echo "$chemin_programme" | sed 's/\//_/g' | sed 's/^_//')
fichier_profil="/etc/apparmor.d/$nom_profil"

# Résumé des choix
echo ""
afficher_titre "Résumé de votre configuration"
echo "Programme : $chemin_programme"
echo "Accès Internet : $acces_internet"
echo "Accès Documents : $acces_documents"
echo "Accès Téléchargements : $acces_telechargements"
echo "Accès clés SSH : $acces_ssh"
echo "Accès /etc/shadow : $acces_shadow"
echo ""

poser_question "Voulez-vous créer ce profil ? (o/n)"
read -r confirmer

if [[ ! "$confirmer" =~ ^[Oo]$ ]]; then
    echo "Création annulée."
    exit 0
fi

# Vérifier si un profil existe déjà
if [ -f "$fichier_profil" ]; then
    echo ""
    afficher_erreur "Un profil existe déjà pour ce programme."
    poser_question "Voulez-vous le remplacer ? (o/n)"
    read -r remplacer
    
    if [[ "$remplacer" =~ ^[Oo]$ ]]; then
        # Désactiver l'ancien profil
        aa-disable "$chemin_programme" 2>/dev/null
        rm -f "$fichier_profil"
        afficher_succes "Ancien profil supprimé."
    else
        echo "Opération annulée."
        exit 0
    fi
fi

# Créer le profil AppArmor
echo ""
echo "Création du profil AppArmor..."

cat > "$fichier_profil" << EOF
#include <tunables/global>

$chemin_programme {
  #include <abstractions/base>
  #include <abstractions/bash>
  
  # Le programme lui-même
  $chemin_programme r,
  
  # Permissions réseau
EOF

# Ajouter les permissions réseau si demandées
if [[ "$acces_internet" =~ ^[Oo]$ ]]; then
    echo "  #include <abstractions/nameservice>" >> "$fichier_profil"
    echo "  network inet stream," >> "$fichier_profil"
    echo "  network inet6 stream," >> "$fichier_profil"
fi

# Ajouter les permissions pour les documents
if [[ "$acces_documents" =~ ^[Oo]$ ]]; then
    echo "  
  # Accès aux documents
  owner @{HOME}/Documents/** rw," >> "$fichier_profil"
fi

# Ajouter les permissions pour les téléchargements
if [[ "$acces_telechargements" =~ ^[Oo]$ ]]; then
    echo "  
  # Accès aux téléchargements
  owner @{HOME}/Downloads/** rw,
  owner @{HOME}/Téléchargements/** rw," >> "$fichier_profil"
fi

# Bloquer ou autoriser SSH
if [[ "$acces_ssh" =~ ^[Oo]$ ]]; then
    echo "  
  # Accès aux clés SSH
  owner @{HOME}/.ssh/** r," >> "$fichier_profil"
else
    echo "  
  # BLOQUER l'accès aux clés SSH
  deny @{HOME}/.ssh/** rw," >> "$fichier_profil"
fi

# Bloquer ou autoriser /etc/shadow
if [[ "$acces_shadow" =~ ^[Oo]$ ]]; then
    echo "  
  # Accès aux mots de passe système
  /etc/shadow r," >> "$fichier_profil"
else
    echo "  
  # BLOQUER l'accès aux mots de passe système
  deny /etc/shadow rw," >> "$fichier_profil"
fi

# Ajouter les dossiers supplémentaires
if [ -n "$dossiers_supplementaires" ]; then
    echo "$dossiers_supplementaires" >> "$fichier_profil"
fi

# Fermer le profil
echo "}" >> "$fichier_profil"

# Charger le profil
afficher_succes "Profil créé : $fichier_profil"
echo "Chargement du profil..."

apparmor_parser -r "$fichier_profil"

if [ $? -eq 0 ]; then
    afficher_succes "Profil chargé avec succès !"
    
    # Mettre en mode enforce
    aa-enforce "$chemin_programme" 2>/dev/null
    
    afficher_succes "Le profil est maintenant actif en mode strict (enforce) !"
    echo ""
    echo "Vous pouvez vérifier le statut avec : sudo aa-status"
else
    afficher_erreur "Erreur lors du chargement du profil."
    exit 1
fi

echo ""
afficher_succes "Configuration terminée !"