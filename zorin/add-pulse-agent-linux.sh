#!/bin/bash
#
# Script pour ajouter le package pulse-agent-linux au dépôt Zorin
# À exécuter APRÈS avoir généré le package sur le serveur
#

set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <zorin_version>"
    echo "Example: $0 17"
    exit 1
fi

REPO_DIR="/home/njeudy/dev/medulla/zorin/${VERSION}"

if [ ! -d "$REPO_DIR" ]; then
    echo "Erreur: Le dépôt Zorin ${VERSION} n'existe pas"
    exit 1
fi

echo "=========================================="
echo "Ajout de pulse-agent-linux au dépôt Zorin ${VERSION}"
echo "=========================================="
echo ""

# Vérifier si le package pulse-agent-linux existe
if [ ! -f "$REPO_DIR/pulse-agent-linux_"*.deb ]; then
    echo "⚠️  Le package pulse-agent-linux n'a pas été trouvé dans $REPO_DIR"
    echo ""
    echo "Pour générer ce package, sur le SERVEUR Medulla :"
    echo ""
    echo "  1. Aller dans le dossier scripts installer :"
    echo "     cd /var/lib/pulse2/clients/lin/deb/pulse-agent-linux"
    echo ""
    echo "  2. Builder le package :"
    echo "     dpkg-buildpackage -b -uc -us"
    echo ""
    echo "  3. Le package sera créé dans le dossier parent :"
    echo "     ls -la ../pulse-agent-linux_*.deb"
    echo ""
    echo "  4. Copier le package sur cette machine :"
    echo "     scp ../pulse-agent-linux_*.deb njeudy@192.168.10.X:${REPO_DIR}/"
    echo ""
    echo "  5. Relancer ce script pour mettre à jour l'index"
    echo ""
    exit 1
fi

echo "✓ Package pulse-agent-linux trouvé"
echo ""

# Regénérer les index
cd "$REPO_DIR"
echo "Génération des index du dépôt..."
apt-ftparchive packages . > Packages
gzip -k -f Packages
apt-ftparchive release . > Release

echo ""
echo "✓ Dépôt mis à jour !"
echo ""
echo "Packages disponibles dans le dépôt :"
dpkg-scanpackages . /dev/null | grep Package: | awk '{print "  - " $2}'
echo ""
echo "Pour déployer sur le serveur :"
echo "  scp -r $REPO_DIR debian@192.168.10.27:/var/www/html/downloads/lin/deb/zorin/"
echo ""
