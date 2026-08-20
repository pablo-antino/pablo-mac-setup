#!/bin/zsh

# ============================================================
# PABLO MAC SETUP
# Instala aplicaciones y aplica preferencias personales.
# No modifica la ubicacion de screenshots.
# ============================================================

set -u
set -o pipefail

RAW_BASE="https://raw.githubusercontent.com/pablo-antino/pablo-mac-setup/main"
TEMP_BREWFILE=""
FAILED_APPS=()

cleanup() {
  if [[ -n "$TEMP_BREWFILE" && -f "$TEMP_BREWFILE" ]]; then
    rm -f "$TEMP_BREWFILE"
  fi
}

on_interrupt() {
  echo ""
  echo "Instalacion interrumpida."
  echo "Homebrew queda configurado en ~/.zprofile."
  echo "Para usar brew en esta misma Terminal, ejecuta:"
  echo "  source ~/.zprofile"
  exit 130
}

trap cleanup EXIT
trap on_interrupt INT TERM

echo ""
echo "========================================"
echo "          PABLO MAC SETUP"
echo "========================================"
echo ""

# ------------------------------------------------------------
# 0. Verificar macOS
# ------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: Este script solo funciona en macOS."
  exit 1
fi

# ------------------------------------------------------------
# 1. Xcode Command Line Tools
# ------------------------------------------------------------

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Instalando Xcode Command Line Tools..."
  xcode-select --install || true
  echo ""
  echo "Completa la instalacion de Xcode Command Line Tools"
  echo "y luego vuelve a ejecutar este mismo setup."
  exit 0
fi

# ------------------------------------------------------------
# 2. Homebrew
# ------------------------------------------------------------

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

if ! find_brew; then
  echo "Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! find_brew; then
    echo "ERROR: No se encontro Homebrew despues de la instalacion."
    exit 1
  fi
fi

# Cargar Homebrew inmediatamente para este proceso.
eval "$("$BREW_BIN" shellenv)"

# Persistir Homebrew para futuras sesiones de Terminal.
BREW_PROFILE_LINE="eval \"\$($BREW_BIN shellenv)\""
touch "$HOME/.zprofile"
if ! grep -Fqx "$BREW_PROFILE_LINE" "$HOME/.zprofile"; then
  print -r -- "$BREW_PROFILE_LINE" >> "$HOME/.zprofile"
fi

# Evitar que cada instalacion vuelva a ejecutar brew update.
export HOMEBREW_NO_AUTO_UPDATE=1

# Reintentar descargas cuando el CDN corta una conexion grande.
# Homebrew usa 3 reintentos por defecto; para este setup usamos 8.
export HOMEBREW_CURL_RETRIES=8

echo ""
echo "Homebrew listo: $($BREW_BIN --version | head -n 1)"
echo "Para usar brew en esta misma Terminal si interrumpes el setup:"
echo "  source ~/.zprofile"

echo ""
echo "Actualizando Homebrew..."
"$BREW_BIN" update

# ------------------------------------------------------------
# 3. Localizar Brewfile
# ------------------------------------------------------------

SCRIPT_DIR="${0:A:h}"

if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
  BREWFILE="$SCRIPT_DIR/Brewfile"
elif [[ -f "$PWD/Brewfile" ]]; then
  BREWFILE="$PWD/Brewfile"
else
  echo ""
  echo "Brewfile no encontrado localmente. Descargando desde GitHub..."
  TEMP_BREWFILE="$(mktemp /tmp/pablo-brewfile.XXXXXX)"

  if ! curl -fsSL "$RAW_BASE/Brewfile" -o "$TEMP_BREWFILE"; then
    echo "ERROR: No se pudo descargar el Brewfile desde GitHub."
    exit 1
  fi

  BREWFILE="$TEMP_BREWFILE"
fi

# ------------------------------------------------------------
# 4. Instalar aplicaciones una por una
# ------------------------------------------------------------

CASKS=("${(@f)$(sed -n 's/^[[:space:]]*cask "\([^"]*\)".*/\1/p' "$BREWFILE")}")

if (( ${#CASKS[@]} == 0 )); then
  echo "ERROR: El Brewfile no contiene aplicaciones cask."
  exit 1
fi

echo ""
echo "Instalando aplicaciones..."
echo "Se mostrara el detalle de cada instalacion."

for app in "${CASKS[@]}"; do
  echo ""
  echo "----------------------------------------"
  echo "Procesando: $app"
  echo "----------------------------------------"

  if "$BREW_BIN" list --cask "$app" >/dev/null 2>&1; then
    echo "OK: $app ya esta instalado."
    continue
  fi

  echo "Instalando $app..."
  if "$BREW_BIN" install --cask "$app" --verbose; then
    echo "OK: $app instalado."
  else
    echo "AVISO: No se pudo instalar $app. Continuando con las demas apps."
    FAILED_APPS+=("$app")
  fi
done

# ------------------------------------------------------------
# 5. Finder
# ------------------------------------------------------------

echo ""
echo "Configurando Finder..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# ------------------------------------------------------------
# 6. Dock
# ------------------------------------------------------------

echo "Configurando Dock..."
defaults write com.apple.dock autohide -bool true

# ------------------------------------------------------------
# 7. Barra de menus
# ------------------------------------------------------------

echo "Configurando barra de menus..."
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# ------------------------------------------------------------
# 8. Trackpad
# ------------------------------------------------------------

echo "Configurando trackpad..."
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# ------------------------------------------------------------
# 9. Teclado: U.S. International
# ------------------------------------------------------------

echo "Configurando teclado U.S. International..."

TMP_SOURCE="$(mktemp /tmp/pablo-keyboard.XXXXXX.m)"
TMP_BINARY="${TMP_SOURCE%.m}"

cat > "$TMP_SOURCE" <<'OBJC'
#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

int main(void) {
    @autoreleasepool {
        CFArrayRef sources = TISCreateInputSourceList(NULL, true);
        if (!sources) {
            fprintf(stderr, "No se pudo obtener la lista de input sources.\n");
            return 1;
        }

        TISInputSourceRef target = NULL;
        CFIndex count = CFArrayGetCount(sources);

        for (CFIndex i = 0; i < count; i++) {
            TISInputSourceRef source =
                (TISInputSourceRef)CFArrayGetValueAtIndex(sources, i);

            CFStringRef name =
                (CFStringRef)TISGetInputSourceProperty(
                    source,
                    kTISPropertyLocalizedName
                );

            if (!name) {
                continue;
            }

            NSString *sourceName = (__bridge NSString *)name;

            BOOL matches =
                [sourceName rangeOfString:@"U.S. International"
                                  options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [sourceName rangeOfString:@"US International"
                                  options:NSCaseInsensitiveSearch].location != NSNotFound;

            if (matches) {
                target = source;
                break;
            }
        }

        if (!target) {
            fprintf(stderr, "No se encontro U.S. International en este macOS.\n");
            CFRelease(sources);
            return 2;
        }

        OSStatus enableStatus = TISEnableInputSource(target);
        OSStatus selectStatus = TISSelectInputSource(target);

        CFStringRef selectedName =
            (CFStringRef)TISGetInputSourceProperty(
                target,
                kTISPropertyLocalizedName
            );

        if (selectedName) {
            NSLog(@"Input source seleccionado: %@", (__bridge NSString *)selectedName);
        }

        CFRelease(sources);

        if (enableStatus != noErr || selectStatus != noErr) {
            fprintf(stderr, "No se pudo activar o seleccionar el input source.\n");
            return 3;
        }

        return 0;
    }
}
OBJC

if clang -fobjc-arc \
  -framework Foundation \
  -framework Carbon \
  "$TMP_SOURCE" \
  -o "$TMP_BINARY" >/dev/null 2>&1; then

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

# ------------------------------------------------------------
# 10. Recargar preferencias
# ------------------------------------------------------------

echo ""
echo "Aplicando cambios..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

# ------------------------------------------------------------
# 11. Limpieza
# ------------------------------------------------------------

echo "Limpiando Homebrew..."
"$BREW_BIN" cleanup

# ------------------------------------------------------------
# 12. Resumen
# ------------------------------------------------------------

echo ""
echo "========================================"
echo "      PABLO MAC SETUP COMPLETADO"
echo "========================================"
echo ""
echo "Configuracion aplicada:"
echo "  - Finder: extensiones + barra de ruta + barra de estado"
echo "  - Dock: ocultar automaticamente"
echo "  - Barra de menus: ocultar automaticamente siempre"
echo "  - Trackpad: click secundario abajo a la derecha"
echo "  - Teclado: U.S. International"
echo "  - Screenshots: SIN CAMBIOS"
echo ""

if (( ${#FAILED_APPS[@]} > 0 )); then
  echo "Aplicaciones que no se pudieron instalar:"
  for app in "${FAILED_APPS[@]}"; do
    echo "  - $app"
  done
  echo ""
else
  echo "Todas las aplicaciones se instalaron correctamente."
  echo ""
fi

echo "Despues inicia sesion donde corresponda:"
echo "  - Microsoft 365 / Outlook / OneDrive"
echo "  - NordVPN"
echo "  - Tailscale"
echo "  - Figma"
echo "  - ChatGPT"
echo ""
echo "Homebrew quedo agregado a ~/.zprofile."
echo "Si esta Terminal aun no reconoce brew, ejecuta:"
echo "  source ~/.zprofile"
echo ""
echo "Si algun ajuste de trackpad o barra de menus no aparece"
echo "inmediatamente, cierra sesion o reinicia la Mac."
echo ""
