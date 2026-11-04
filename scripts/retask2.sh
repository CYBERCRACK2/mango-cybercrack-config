#!/bin/sh

# --- Configuración de Reintentos ---
MAX_ATTEMPTS=3
CURRENT_ATTEMPT=0
SUCCESS=0

# Función principal que contiene la lógica original del script
run_configuration() {
  echo "======================================================"
  echo "⚙️ INICIANDO PROCESO DE CONFIGURACIÓN (Intento $((CURRENT_ATTEMPT + 1)) de $MAX_ATTEMPTS)"
  echo "======================================================"

  # Pedir sudo al inicio, evitará esperas...
  sudo -v

  # Ruta confirmada de tu chip Realtek ALC897
  HWDIR="/sys/class/sound/hwC1D0"

  if [ ! -d "$HWDIR" ]; then
    echo "❌ ERROR FATAL: La ruta $HWDIR no existe." >&2
    return 1 # Retorna fallo
  fi

  echo "1. Deteniendo PipeWire y WirePlumber desde tu sesión de usuario..."
  systemctl --user stop wireplumber.service
  sleep 1

  echo "2. Aplicando los 14 pines de forma secuencial (Se solicitará sudo)..."
  # La primera línea activará el prompt de sudo, las siguientes se ejecutarán directo gracias a la caché de credenciales
  echo "0x11 0x4037c040" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x12 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x14 0x01214010" | sudo tee "$HWDIR/user_pin_configs" >/dev/null # <-- Tus Auriculares traseros
  echo "0x15 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x16 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x17 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x18 0x01a19030" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x19 0x02a19040" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x1a 0x0111304f" | sudo tee "$HWDIR/user_pin_configs" >/dev/null # <-- Tu Jack Azul mapeado como Altavoz
  echo "0x1b 0x02214020" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x1c 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x1d 0x4025c641" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x1e 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null
  echo "0x1f 0x411111f0" | sudo tee "$HWDIR/user_pin_configs" >/dev/null

  echo "3. Forzando la reconfiguración del hardware en el Kernel..."
  if ! echo 1 | sudo tee "$HWDIR/reconfig" >/dev/null; then
    echo "❌ ERROR: Falló la reconfiguración de hardware (Device or resource busy?)." >&2
    return 1 # Return failure immediately if reconfiguration fails
  fi

  echo "4. Reactivando servicios de audio de PipeWire..."
  systemctl --user restart wireplumber.service

  return 0 # Retorna éxito
}

# --- Bucle de Reintentos (Try-Catch) ---

while [ $CURRENT_ATTEMPT -lt $MAX_ATTEMPTS ]; do

  # Ejecutar la función principal
  run_configuration
  EXIT_STATUS=$?

  if [ $EXIT_STATUS -eq 0 ]; then
    # ÉXITO: Salir del bucle
    SUCCESS=1
    break
  else
    # FALLO: Incrementar contador y esperar antes de reintentar
    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
    if [ $CURRENT_ATTEMPT -lt $MAX_ATTEMPTS ]; then
      echo "------------------------------------------------------"
      echo "⚠️ EL PROCESO FALLÓ EN ESTE INTENTO. Reintentando en segundos..."
      echo "------------------------------------------------------"
      sleep 1
    fi
  fi
done

# --- Salida Final ---

# Al lanzarlo desde el menú (.desktop) cerramos la ventana de alacritty al terminar.
# Si falla, esperamos a que el usuario lea el error antes de cerrarla.
UI_MODE="${FIX_AUDIO_UI:-0}"

# Detección de respaldo: si el padre directo es alacritty, venimos del menú,
# aunque la entrada .desktop en caché no traiga FIX_AUDIO_UI.
if [ "$UI_MODE" != "1" ]; then
  parent_comm=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ')
  if [ "$parent_comm" = "alacritty" ]; then
    UI_MODE=1
  fi
fi

# Busca el alacritty que lanzó este script (subiendo por los procesos padre) y lo
# cierra. Así funciona aunque el .desktop se haya lanzado con --hold.
close_terminal_window() {
  pid="$PPID"
  depth=0
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] && [ "$depth" -lt 10 ]; do
    comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ "$comm" = "alacritty" ]; then
      kill -TERM "$pid" 2>/dev/null
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    depth=$((depth + 1))
  done
  return 1
}

if [ $SUCCESS -eq 1 ]; then
  echo ""
  echo "======================================================"
  echo "✅ ¡PROCESO COMPLETADO CON ÉXITO!"
  echo "El hardware se ha reconfigurado correctamente."
  echo "Comprueba pwcontrol para verificar los cambios."
  echo "======================================================"

  if [ "$UI_MODE" = "1" ]; then
    sleep 1
    close_terminal_window
  fi
else
  echo ""
  echo "======================================================"
  echo "❌ FALLO CRÍTICO: El script no pudo completarse después de $MAX_ATTEMPTS intentos."
  echo "Asegúrate de que el hardware está conectado y tienes permisos de sudo."
  echo "======================================================"

  if [ "$UI_MODE" = "1" ]; then
    printf "\nPresiona Enter para cerrar esta ventana..."
    read -r _
  fi
fi

# Salir del script con el código de éxito o fallo final
if [ "$SUCCESS" -eq 1 ]; then
  exit 0
fi
exit 1
