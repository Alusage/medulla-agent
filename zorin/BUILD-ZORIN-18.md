# Build des packages Medulla pour Zorin OS 18

## Sur la machine Zorin 18

### 1. Installer les dépendances de build

```bash
sudo apt update
sudo apt install -y debhelper git python3-all python3-setuptools build-essential dpkg-dev
```

### 2. Cloner le dépôt medulla-agent

```bash
cd /home/njeudy/dev/medulla/
git clone https://github.com/medulla-project/medulla-agent.git
cd medulla-agent
```

Ou si le dépôt existe déjà :

```bash
cd /home/njeudy/dev/medulla/medulla-agent
git pull
```

### 3. Builder les packages

```bash
dpkg-buildpackage -b -uc -us
```

Les packages seront créés dans le dossier parent (`/home/njeudy/dev/medulla/`).

### 4. Copier les packages dans le dépôt Zorin 18

```bash
cp /home/njeudy/dev/medulla/*.deb /home/njeudy/dev/medulla/zorin/18/
cd /home/njeudy/dev/medulla/zorin/18
```

### 5. Générer les index du dépôt

```bash
apt-ftparchive packages . > Packages
gzip -k -f Packages
apt-ftparchive release . > Release
```

### 6. Vérifier le contenu

```bash
ls -lh *.deb
dpkg-scanpackages . /dev/null | grep Package:
```

## Retour sur la machine Zorin 17 (ou sur le serveur)

### Déployer le dépôt complet sur le serveur

```bash
# Depuis la machine Zorin 17
scp -r /home/njeudy/dev/medulla/zorin debian@192.168.10.27:/tmp/

# Sur le serveur Medulla
ssh debian@192.168.10.27
sudo mv /tmp/zorin /var/www/html/downloads/lin/deb/
sudo chown -R www-data:www-data /var/www/html/downloads/lin/deb/zorin
```

## Vérification

Les dépôts seront accessibles à :
- Zorin 17 : http://medulla.97.alusage.fr/downloads/lin/deb/zorin/17/
- Zorin 18 : http://medulla.97.alusage.fr/downloads/lin/deb/zorin/18/

## Test d'installation

Sur une machine Zorin 17 ou 18 :

```bash
# Télécharger l'installateur
wget http://medulla.97.alusage.fr/downloads/Medulla-Agent-linux-zorin-installer.sh

# Lancer l'installation
sudo bash Medulla-Agent-linux-zorin-installer.sh
```
