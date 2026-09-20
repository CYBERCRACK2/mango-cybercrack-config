#!/bin/sh

# 1. Escaneo dinámico del hardware
HWDIR=""
for dev in /sys/class/sound/hwC*D*; do
    if [ -f "$dev/chip_name" ]; then
        CHIP_NAME=$(cat "$dev/chip_name")
        VENDOR_NAME=$(cat "$dev/vendor_name" 2>/dev/null)
        if echo "$CHIP_NAME" | grep -qi "ALC897\|ALC"; then
            HWDIR="$dev"
            echo "--> ¡Códec encontrado!: $VENDOR_NAME $CHIP_NAME en la ruta $HWDIR"
            break
        fi
    fi
done

if [ -z "$HWDIR" ]; then
    echo "Error: No se pudo mapear el códec ALC automáticamente."
    exit 1
fi

echo "2. Deteniendo PipeWire y WirePlumber desde tu sesión de usuario..."
systemctl --user stop wireplumber.service pipewire-pulse.service pipewire.service pipewire-pulse.socket pipewire.socket
sleep 1

echo "3. Aplicando ÚNICAMENTE los 2 pines modificados de la imagen (Se solicitará sudo)..."
# Dejamos intactos los otros 12 pines para que el kernel use sus valores de fábrica mapeados en esta tarjeta.
sudo tee "$HWDIR/user_pin_configs" << 'EOF' > /dev/null
0x11 0x4037c040
0x12 0x411111f0
0x14 0x01214010
0x15 0x411111f0
0x16 0x411111f0
0x17 0x411111f0
0x18 0x01a19030
0x19 0x02a19040
0x1a 0x0111304f
0x1b 0x02214020
0x1c 0x411111f0
0x1d 0x4025c641
0x1e 0x411111f0
0x1f 0x411111f0
EOF

echo "4. Forzando la reconfiguración del hardware en el Kernel..."
if echo 1 | sudo tee "$HWDIR/reconfig" > /dev/null; then
    echo "¡El kernel ha aceptado la reconfiguración correctamente!"
else
    echo "Error: El kernel rechazó la reconfiguración."
fi

echo "5. Reactivando servicios de audio de PipeWire..."
systemctl --user start pipewire.socket pipewire-pulse.socket pipewire.service pipewire-pulse.service wireplumber.service

echo "¡Proceso completado con éxito! Comprueba pwcontrol."
