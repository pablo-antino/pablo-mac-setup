#!/bin/zsh

# ============================================================
# PABLO MAC SETUP
# Un solo comando para preparar una Mac nueva.
# No modifica la ubicacion ni configuracion de screenshots.
# ============================================================

set -u
set -o pipefail

RAW_BASE="https://raw.githubusercontent.com/pablo-antino/pablo-mac-setup/main"
TEMP_BREWFILE=""
FAILED_APPS=()
HEARTBEAT_PID=""

cleanup() {
  if [[ -n "$HEARTBEAT_PID" ]] && kill -0 "$HEARTBEAT_PID" 2>/dev/null; then
    kill "$HEARTBEAT_PID" 2>/dev/null || true
    wait "$HEARTBEAT_PID" 2>/dev/null || true
  fi

  if [[ -n "$TEMP_BREWFILE" && -f "$TEMP_BREWFILE" ]]; then
    rm -f "$TEMP_BREWFILE"
  fi
}

on_interrupt() {
  echo ""
  if [[ -n "$HEARTBEAT_PID" ]] && kill -0 "$HEARTBEAT_PID" 2>/dev/null; then
    kill "$HEARTBEAT_PID" 2>/dev/null || true
    wait "$HEARTBEAT_PID" 2>/dev/null || true
    HEARTBEAT_PID=""
  fi
  echo "Setup interrumpido."
  exit 130
}

trap cleanup EXIT
trap on_interrupt INT TERM

format_elapsed() {
  local elapsed="$1"
  printf '%02d:%02d' "$((elapsed / 60))" "$((elapsed % 60))"
}

start_heartbeat() {
  local label="$1"

  (
    local elapsed=0
    while true; do
      sleep 15
      elapsed=$((elapsed + 15))

      # Durante un prompt de password, sudo desactiva echo en el TTY.
      # No imprimir el heartbeat en ese momento para no ensuciar el prompt.
      if stty -a </dev/tty 2>/dev/null | grep -Eq '(^|[[:space:]])-echo([[:space:]]|$)'; then
        continue
      fi

      echo "[$(format_elapsed "$elapsed")] $label sigue en proceso..."
    done
  ) &

  HEARTBEAT_PID=$!
}

stop_heartbeat() {
  if [[ -n "$HEARTBEAT_PID" ]] && kill -0 "$HEARTBEAT_PID" 2>/dev/null; then
    kill "$HEARTBEAT_PID" 2>/dev/null || true
    wait "$HEARTBEAT_PID" 2>/dev/null || true
  fi
  HEARTBEAT_PID=""
}

check_github() {
  echo "Comprobando conexion..."
  if ! curl -fsSIL --connect-timeout 10 --retry 3 --retry-delay 2 https://github.com >/dev/null; then
    echo "ERROR: No se puede acceder a GitHub."
    echo "Revisa Wi-Fi/DNS y vuelve a ejecutar el mismo comando."
    exit 1
  fi
  echo "OK: conexion disponible."
}

find_brew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
    return 0
  fi
  if [[ -x /usr/local/bin/brew ]]; then
    BREW_BIN="/usr/local/bin/brew"
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
    return 0
  fi
  return 1
}

expected_app_path() {
  local token="${1##*/}"

  case "$token" in
    nordvpn) echo "/Applications/NordVPN.app" ;;
    microsoft-word) echo "/Applications/Microsoft Word.app" ;;
    microsoft-excel) echo "/Applications/Microsoft Excel.app" ;;
    microsoft-powerpoint) echo "/Applications/Microsoft PowerPoint.app" ;;
    microsoft-outlook) echo "/Applications/Microsoft Outlook.app" ;;
    onedrive) echo "/Applications/OneDrive.app" ;;
    pearcleaner) echo "/Applications/Pearcleaner.app" ;;
    figma) echo "/Applications/Figma.app" ;;
    tailscale-app) echo "/Applications/Tailscale.app" ;;
    chatgpt) echo "/Applications/ChatGPT.app" ;;
    *) echo "" ;;
  esac
}

app_is_present() {
  local token="$1"
  local path="$(expected_app_path "$token")"
  local app_name="${token##*/}"

  if [[ -n "$path" ]]; then
    [[ -d "$path" ]]
    return $?
  fi

  "$BREW_BIN" list --cask "$app_name" >/dev/null 2>&1
}

run_brew_action() {
  local action="$1"
  shift
  local label="$1"
  shift

  start_heartbeat "$label"
  "$BREW_BIN" "$action" --cask "$@" --verbose
  local status=$?
  stop_heartbeat

  return "$status"
}

echo ""
echo "========================================"
echo "          PABLO MAC SETUP"
echo "========================================"
echo ""

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: Este script solo funciona en macOS."
  exit 1
fi

check_github

# Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  echo ""
  echo "Xcode Command Line Tools no esta instalado."
  echo "macOS abrira el instalador. Completalo; este proceso continuara solo."
  xcode-select --install 2>/dev/null || true

  elapsed=0
  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 15
    elapsed=$((elapsed + 15))
    echo "[$(format_elapsed "$elapsed")] Esperando Xcode Command Line Tools..."
  done
  echo "OK: Xcode Command Line Tools instalado."
fi

# Homebrew
if ! find_brew; then
  echo ""
  echo "Instalando Homebrew..."
  HOMEBREW_INSTALLER="$(curl -fsSL --retry 5 --retry-delay 2 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "ERROR: No se pudo descargar el instalador de Homebrew."
    exit 1
  }
  /bin/bash -c "$HOMEBREW_INSTALLER"

  if ! find_brew; then
    echo "ERROR: No se encontro Homebrew despues de la instalacion."
    exit 1
  fi
fi

eval "$("$BREW_BIN" shellenv)"
BREW_PROFILE_LINE="eval \"\$($BREW_BIN shellenv)\""
touch "$HOME/.zprofile"
if ! grep -Fqx "$BREW_PROFILE_LINE" "$HOME/.zprofile"; then
  print -r -- "$BREW_PROFILE_LINE" >> "$HOME/.zprofile"
fi

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_CURL_RETRIES=8
export HOMEBREW_DOWNLOAD_CONCURRENCY=1

echo ""
echo "Homebrew listo: $($BREW_BIN --version | head -n 1)"
echo "Actualizando Homebrew..."
if ! "$BREW_BIN" update; then
  echo "AVISO: brew update fallo. Continuare con la version instalada."
fi

# Descargar SIEMPRE el Brewfile actual para evitar copias locales viejas.
echo ""
echo "Descargando configuracion actual desde GitHub..."
TEMP_BREWFILE="$(mktemp /tmp/pablo-brewfile.XXXXXX)"
if ! curl -fsSL --retry 5 --retry-delay 2 "$RAW_BASE/Brewfile" -o "$TEMP_BREWFILE"; then
  echo "ERROR: No se pudo descargar el Brewfile actual."
  exit 1
fi

CASKS=("${(@f)$(sed -n 's/^[[:space:]]*cask "\([^"]*\)".*/\1/p' "$TEMP_BREWFILE")}")
if (( ${#CASKS[@]} == 0 )); then
  echo "ERROR: El Brewfile no contiene aplicaciones cask."
  exit 1
fi

# Corregir OneDrive CLI instalado por versiones antiguas.
if "$BREW_BIN" list --formula onedrive-cli >/dev/null 2>&1 && \
   ! "$BREW_BIN" list --cask onedrive >/dev/null 2>&1; then
  echo ""
  echo "Corrigiendo instalacion anterior de OneDrive..."
  "$BREW_BIN" uninstall --formula onedrive-cli || true
fi

# Detectar estado real: no basta con que Homebrew tenga el cask registrado.
MISSING_CASKS=()
REINSTALL_CASKS=()

echo ""
echo "Revisando aplicaciones..."
for app in "${CASKS[@]}"; do
  app_name="${app##*/}"
  app_path="$(expected_app_path "$app")"

  if app_is_present "$app"; then
    if [[ -n "$app_path" ]]; then
      echo "OK: $app_name presente en $app_path"
    else
      echo "OK: $app_name instalado."
    fi
    continue
  fi

  if "$BREW_BIN" list --cask "$app_name" >/dev/null 2>&1; then
    echo "REPARAR: $app_name figura instalado en Homebrew pero falta su aplicacion."
    REINSTALL_CASKS+=("$app")
  else
    echo "FALTA: $app_name"
    MISSING_CASKS+=("$app")
  fi
done

# Reparar casks registrados cuyo .app real no existe.
if (( ${#REINSTALL_CASKS[@]} > 0 )); then
  echo ""
  echo "Reinstalando ${#REINSTALL_CASKS[@]} aplicaciones incompletas..."
  echo "Si aparece Password:, escribe la contrasena normalmente."
  echo "[00:00] Reparacion de aplicaciones iniciada."

  if ! run_brew_action reinstall "Reparacion de aplicaciones" "${REINSTALL_CASKS[@]}"; then
    echo "AVISO: Homebrew reporto un fallo durante la reparacion."
  fi
fi

# Instalar casks que no estan registrados ni presentes.
if (( ${#MISSING_CASKS[@]} > 0 )); then
  echo ""
  echo "Instalando ${#MISSING_CASKS[@]} aplicaciones faltantes..."
  echo "Las descargas se haran una por una para evitar cortes del CDN."
  echo "Si aparece Password:, escribe la contrasena normalmente."
  echo "[00:00] Instalacion de aplicaciones iniciada."

  if ! run_brew_action install "Instalacion de aplicaciones" "${MISSING_CASKS[@]}"; then
    echo "AVISO: Homebrew reporto un fallo durante la instalacion."
  fi
fi

if (( ${#REINSTALL_CASKS[@]} == 0 && ${#MISSING_CASKS[@]} == 0 )); then
  echo "Todas las aplicaciones ya estaban presentes."
fi

# Verificacion fisica final de todas las aplicaciones.
echo ""
echo "Verificando aplicaciones instaladas..."
FAILED_APPS=()

for app in "${CASKS[@]}"; do
  app_name="${app##*/}"
  app_path="$(expected_app_path "$app")"

  if app_is_present "$app"; then
    if [[ -n "$app_path" ]]; then
      echo "OK: $app_name -> $app_path"
    else
      echo "OK: $app_name"
    fi
  else
    FAILED_APPS+=("$app_name")
    if [[ -n "$app_path" ]]; then
      echo "PENDIENTE: $app_name; no existe $app_path"
    else
      echo "PENDIENTE: $app_name"
    fi
  fi
done

# Finder
echo ""
echo "Configurando Finder..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Dock
echo "Configurando Dock..."
defaults write com.apple.dock autohide -bool true

# Barra de menus
echo "Configurando barra de menus..."
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# Trackpad
echo "Configurando trackpad..."

# Trackpad integrado: clic secundario en la esquina inferior derecha.
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
defaults -currentHost write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

# Trackpads Bluetooth / externos.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults -currentHost write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

# Preferencias globales que macOS consulta para el gesto de clic secundario.
defaults write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Forzar recarga de preferencias del usuario antes de continuar.
killall cfprefsd 2>/dev/null || true
sleep 1

# Verificacion basica de las claves principales.
TRACKPAD_CORNER="$(defaults read NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior 2>/dev/null || echo 0)"
TRACKPAD_SECONDARY="$(defaults read NSGlobalDomain com.apple.trackpad.enableSecondaryClick 2>/dev/null || echo 0)"
if [[ "$TRACKPAD_CORNER" == "1" && "$TRACKPAD_SECONDARY" == "1" ]]; then
  echo "OK: clic secundario configurado en la esquina inferior derecha."
else
  echo "AVISO: macOS no confirmo el ajuste de clic secundario."
fi

# Teclado: U.S. International
echo "Configurando teclado U.S. International..."
TMP_SOURCE="$(mktemp /tmp/pablo-keyboard.XXXXXX.m)"
TMP_BINARY="${TMP_SOURCE%.m}"

cat > "$TMP_SOURCE" <<'OBJC'
#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
int main(void) {
    @autoreleasepool {
        CFArrayRef sources = TISCreateInputSourceList(NULL, true);
        if (!sources) return 1;
        TISInputSourceRef target = NULL;
        CFIndex count = CFArrayGetCount(sources);
        for (CFIndex i = 0; i < count; i++) {
            TISInputSourceRef source = (TISInputSourceRef)CFArrayGetValueAtIndex(sources, i);
            CFStringRef name = (CFStringRef)TISGetInputSourceProperty(source, kTISPropertyLocalizedName);
            if (!name) continue;
            NSString *sourceName = (__bridge NSString *)name;
            BOOL matches =
                [sourceName rangeOfString:@"U.S. International" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [sourceName rangeOfString:@"US International" options:NSCaseInsensitiveSearch].location != NSNotFound;
            if (matches) { target = source; break; }
        }
        if (!target) { CFRelease(sources); return 2; }
        OSStatus enableStatus = TISEnableInputSource(target);
        OSStatus selectStatus = TISSelectInputSource(target);
        CFRelease(sources);
        return (enableStatus == noErr && selectStatus == noErr) ? 0 : 3;
    }
}
OBJC

if clang -fobjc-arc -framework Foundation -framework Carbon "$TMP_SOURCE" -o "$TMP_BINARY" >/dev/null 2>&1; then
  if "$TMP_BINARY"; then
    echo "OK: U.S. International seleccionado."
  else
    echo "AVISO: Revisa Keyboard > Text Input manualmente."
  fi
else
  echo "AVISO: No se pudo compilar el configurador del teclado."
  echo "Revisa Keyboard > Text Input manualmente."
fi
rm -f "$TMP_SOURCE" "$TMP_BINARY"

# Aplicar cambios
echo ""
echo "Aplicando cambios..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true
"$BREW_BIN" cleanup || true

# Resumen
echo ""
echo "========================================"
echo "      PABLO MAC SETUP COMPLETADO"
echo "========================================"
echo ""
if (( ${#FAILED_APPS[@]} > 0 )); then
  echo "Aplicaciones que siguen faltando fisicamente:"
  for app in "${FAILED_APPS[@]}"; do
    echo "  - $app"
  done
  echo ""
  echo "Ejecuta exactamente el mismo comando otra vez para reintentar."
else
  echo "Todas las aplicaciones fueron verificadas fisicamente en /Applications."
  echo "Todas las preferencias quedaron aplicadas."
fi

echo ""
echo "Screenshots: SIN CAMBIOS"
echo ""
