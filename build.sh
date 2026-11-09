#!/usr/bin/env bash
# Fabrique les fichiers à distribuer dans le dossier dist/ :
#   - doom-like-<version>.love
#   - doom-like-<version>-windows.zip

set -euo pipefail

NAME="doom-like"
VERSION="${1:-dev}"
LOVE_VERSION="11.5"
LOVE_WIN_DIR="/mnt/c/Program Files/LOVE"

[ -f main.lua ] && [ -f conf.lua ] || { echo "Lance ce script depuis la racine du projet."; exit 1; }
command -v zip >/dev/null || { echo "Commande zip manquante"; exit 1; }

rm -rf dist
mkdir -p dist

# Version avec le .love
LOVE_FILE="dist/$NAME-$VERSION.love"
zip -9 -q -r "$LOVE_FILE" main.lua conf.lua src assets levels
echo "Créé : $LOVE_FILE"

# Version avec le .exe
if [ -f "$LOVE_WIN_DIR/love.exe" ]; then
    SRC="$LOVE_WIN_DIR"
else
    echo "LÖVE pour Windows introuvable dans $LOVE_WIN_DIR : téléchargement de LÖVE $LOVE_VERSION..."
    curl -sfL -o dist/love-win64.zip \
        "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-win64.zip"
    unzip -q dist/love-win64.zip -d dist/love-win64
    SRC=$(dirname "$(find dist/love-win64 -name love.exe | head -1)")
fi

WIN_DIR="dist/$NAME-$VERSION-windows"
mkdir -p "$WIN_DIR"
cat "$SRC/love.exe" "$LOVE_FILE" > "$WIN_DIR/$NAME.exe"
cp "$SRC"/*.dll "$WIN_DIR/"
cp "$SRC/license.txt" "$WIN_DIR/LOVE-license.txt"

cat > "$WIN_DIR/LISEZMOI.txt" <<EOF
$NAME $VERSION

Pour jouer : double-cliquez sur $NAME.exe

Commandes : ZQSD pour bouger, souris pour viser, clic gauche pour tirer,
E pour ouvrir les portes, 2-3-4 ou molette pour changer d'arme, Échap pour le menu.

Moteur : LÖVE (https://love2d.org), voir LOVE-license.txt
Graphismes et sons : projet Freedoom (https://freedoom.github.io), licence BSD
EOF

(cd dist && zip -9 -q -r "$NAME-$VERSION-windows.zip" "$NAME-$VERSION-windows")
rm -rf dist/love-win64 dist/love-win64.zip "$WIN_DIR"
echo "Créé : dist/$NAME-$VERSION-windows.zip"
