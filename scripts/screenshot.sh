#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

# Ejecutamos grim y slurp en el sistema anfitrión para capturar la pantalla "viva".
# Pasamos la imagen por la tubería (|) hacia dentro de Toolbox para que swappy la congele y procese.
#grim -g "$(slurp)" - | toolbox run -c default swappy -f - -o "$FILE"
grim -g "$(slurp -d)" - | satty --filename -



