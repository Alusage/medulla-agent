# Dépôt APT Medulla pour Zorin OS

Ce dépôt contient les packages Medulla compilés nativement pour Zorin OS.

## Structure

```
zorin/
├── 17/          # Packages pour Zorin OS 17 (basé sur Ubuntu 22.04)
│   ├── Packages
│   ├── Packages.gz
│   ├── Release
│   ├── pulse-agent-installers_2.1.5-1_all.deb
│   ├── pulse-xmpp-agent-relay_2.1.5-1_all.deb
│   ├── pulse-xmppmaster-agentplugins_2.1.5-1_all.deb
│   ├── pulse-xmpp-master-substitute_2.1.5-1_all.deb
│   └── pulse-agent-linux_*.deb (À AJOUTER)
├── 18/          # Packages pour Zorin OS 18 (À BUILDER)
└── README.md
```

## Packages actuels

### Zorin 17 ✓
- ✅ `pulse-agent-installers` - Scripts de génération d'agents
- ✅ `pulse-xmpp-agent-relay` - Agent relay
- ✅ `pulse-xmppmaster-agentplugins` - Plugins master
- ✅ `pulse-xmpp-master-substitute` - Services master substitute
- ⚠️  `pulse-agent-linux` - **MANQUANT** (doit être généré sur le serveur)

### Zorin 18
- ❌ Aucun package encore (à builder sur machine Zorin 18)

## Comment ajouter pulse-agent-linux

Le package `pulse-agent-linux` contient les fichiers de configuration avec les credentials XMPP.
Il doit être généré **sur le serveur Medulla** car il utilise `/var/lib/pulse2/clients/config/`.

### Sur le serveur Medulla :

```bash
# 1. Aller dans le dossier de build du package
ssh debian@192.168.10.27
cd /var/lib/pulse2/clients/lin/deb/pulse-agent-linux

# 2. Builder le package
dpkg-buildpackage -b -uc -us

# 3. Le package est créé dans le dossier parent
ls -la ../*.deb
```

### Sur ta machine locale :

```bash
# 1. Récupérer le package depuis le serveur
scp debian@192.168.10.27:/var/lib/pulse2/clients/lin/deb/pulse-agent-linux_*.deb \
    /home/njeudy/dev/medulla/zorin/17/

# 2. Mettre à jour l'index du dépôt
./add-pulse-agent-linux.sh 17
```

## Déploiement sur le serveur

Une fois le dépôt complet (avec pulse-agent-linux), déploie-le sur le serveur :

```bash
# Copier tout le dépôt zorin sur le serveur
scp -r /home/njeudy/dev/medulla/zorin debian@192.168.10.27:/tmp/

# Sur le serveur, déplacer dans le bon emplacement
ssh debian@192.168.10.27
sudo mv /tmp/zorin /var/www/html/downloads/lin/deb/
sudo chown -R www-data:www-data /var/www/html/downloads/lin/deb/zorin
```

## Vérification

Le dépôt sera accessible à :
- Zorin 17 : `http://medulla.97.alusage.fr/downloads/lin/deb/zorin/17/`
- Zorin 18 : `http://medulla.97.alusage.fr/downloads/lin/deb/zorin/18/`

Test depuis une machine Zorin :

```bash
# Ajouter le dépôt
echo "deb [trusted=yes] http://medulla.97.alusage.fr/downloads/lin/deb/zorin/17/ ./" | \
    sudo tee /etc/apt/sources.list.d/medulla-zorin.list

# Mettre à jour et vérifier
sudo apt update
apt-cache search pulse-agent
```

## Construction pour Zorin 18

Pour créer les packages Zorin 18, répète les mêmes étapes sur une machine Zorin 18 :

```bash
cd /home/njeudy/dev/medulla/medulla-agent
dpkg-buildpackage -b -uc -us
cp ../*.deb /home/njeudy/dev/medulla/zorin/18/
cd /home/njeudy/dev/medulla/zorin/18
apt-ftparchive packages . > Packages
gzip -k Packages
apt-ftparchive release . > Release
```

## Notes de sécurité

⚠️ **IMPORTANT** : Le package `pulse-agent-linux` contient :
- Les credentials XMPP (password)
- La clé AES de chiffrement
- Les configurations serveur

Ce dépôt doit être protégé par :
- Authentification HTTP (htaccess)
- Accès restreint au réseau local uniquement
- Firewall sur le serveur web

## Script d'installation

Le script `Medulla-Linux-Agent-installer.sh` utilise automatiquement ce dépôt pour Zorin OS.
