#!/bin/sh

# Pedir sudo al inicio, evitará esperas...
sudo -v

# Ruta confirmada de tu chip Realtek ALC897
HWDIR="/sys/class/sound/hwC1D0"

if [ ! -d "$HWDIR" ]; then
    echo "Error: La ruta $HWDIR no existe."
    exit 1
fi

echo "1. Deteniendo PipeWire y WirePlumber desde tu sesión de usuario..."
systemctl --user stop wireplumber.service
sleep 1

echo "2. Aplicando los 14 pines de forma secuencial (Se solicitará sudo)..."
# La primera línea activará el prompt de sudo, las siguientes se ejecutarán directo gracias a la caché de credenciales
echo "0x11 0x4037c040" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x12 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x14 0x01214010" | sudo tee "$HWDIR/user_pin_configs" > /dev/null # <-- Tus Auriculares traseros
echo "0x15 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x16 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x17 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x18 0x01a19030" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x19 0x02a19040" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x1a 0x0111304f" | sudo tee "$HWDIR/user_pin_configs" > /dev/null # <-- Tu Jack Azul mapeado como Altavoz
echo "0x1b 0x02214020" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x1c 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x1d 0x4025c641" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x1e 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null
echo "0x1f 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" > /dev/null

echo "3. Forzando la reconfiguración del hardware en el Kernel..."
echo 1 | sudo tee "$HWDIR/reconfig" > /dev/null

echo "4. Reactivando servicios de audio de PipeWire..."
systemctl --user restart wireplumber.service


echo "¡Proceso completado con éxito! Comprueba pwcontrol."
