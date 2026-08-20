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
ACTIVE_PID=""

cleanup() {
  if [[ -n "$TEMP_BREWFILE" && -f "$TEMP_BREWFILE" ]]; then
    rm -f "$TEMP_BREWFILE"
  fi
}

on_interrupt() {
  echo ""
  if [[ -n "$ACTIVE_PID" ]] && kill -0 "$ACTIVE_PID" 2>/dev/null; then
    echo "Deteniendo la instalacion activa..."
    kill "$ACTIVE_PID" 2>/dev/null || true
    wait "$ACTIVE_PID" 2>/dev/null || true
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

wait_with_heartbeat() {
  local pid="$1"
  local label="$2"
  local elapsed=0

  ACTIVE_PID="$pid"
  while kill -0 "$pid" 2>/dev/null; do
    sleep 15
    if kill -0 "$pid" 2>/dev/null; then
      elapsed=$((elapsed + 15))
      echo "[$(format_elapsed "$elapsed")] $label sigue en proceso..."
    fi
  done

  wait "$pid"
  local result=$?
  ACTIVE_PID=""
  return "$result"
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

install_cask_once() {
  local token="$1"
  "$BREW_BIN" install --cask "$token" --verbose &
  local pid=$!
  wait_with_heartbeat "$pid" "${token##*/}"
}

install_cask() {
  local token="$1"
  local app_name="${token##*/}"
  local attempt=1
  local max_attempts=3

  if "$BREW_BIN" list --cask "$app_name" >/dev/null 2>&1; then
    echo "OK: $app_name ya esta instalado."
    return 0
  fi

  while (( attempt <= max_attempts )); do
    echo "Intento $attempt/$max_attempts para $app_name"
    echo "[00:00] $app_name iniciado."

    if install_cask_once "$token"; then
      echo "OK: $app_name instalado."
      return 0
    fi

    if (( attempt < max_attempts )); then
      echo "AVISO: fallo $app_name. Reintentando..."
      sleep 5
    fi
    attempt=$((attempt + 1))
  done

  echo "AVISO: no se pudo instalar $app_name despues de $max_attempts intentos."
  return 1
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
  NONINTERACTIVE=1 /bin/bash -c "$HOMEBREW_INSTALLER"

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

# Aplicaciones
echo ""
echo "Instalando aplicaciones una por una..."
echo "El estado se actualizara al menos cada 15 segundos."

for app in "${CASKS[@]}"; do
  app_name="${app##*/}"
  echo ""
  echo "----------------------------------------"
  echo "Procesando: $app_name"
  echo "----------------------------------------"
  if ! install_cask "$app"; then
    FAILED_APPS+=("$app_name")
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
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

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
  echo "No se pudieron instalar:"
  for app in "${FAILED_APPS[@]}"; do
    echo "  - $app"
  done
  echo ""
  echo "Ejecuta exactamente el mismo comando otra vez:"
  echo "saltara lo ya instalado y reintentara solo lo pendiente."
else
  echo "Todas las aplicaciones y preferencias quedaron aplicadas."
fi

echo ""
echo "Screenshots: SIN CAMBIOS"
echo ""
