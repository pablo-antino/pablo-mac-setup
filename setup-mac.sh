#!/bin/zsh

# ============================================================
# PABLO MAC SETUP
# Instala aplicaciones y aplica preferencias personales.
# No modifica la ubicacion de screenshots.
# ============================================================

set -u
set -o pipefail

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
  echo "y luego vuelve a ejecutar este script."
  exit 0
fi

# ------------------------------------------------------------
# 2. Homebrew
# ------------------------------------------------------------

if ! command -v brew >/dev/null 2>&1; then
  echo "Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  BREW_SHELLENV='eval "$(/opt/homebrew/bin/brew shellenv)"'
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
  BREW_SHELLENV='eval "$(/usr/local/bin/brew shellenv)"'
else
  echo "ERROR: No se encontro Homebrew despues de la instalacion."
  exit 1
fi

touch "$HOME/.zprofile"
if ! grep -Fq 'brew shellenv' "$HOME/.zprofile"; then
  echo "$BREW_SHELLENV" >> "$HOME/.zprofile"
fi

echo ""
echo "Actualizando Homebrew..."
brew update

# ------------------------------------------------------------
# 3. Aplicaciones (Brewfile)
# ------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"

if [[ ! -f "$BREWFILE" ]]; then
  echo "ERROR: No se encontro el Brewfile en $SCRIPT_DIR."
  exit 1
fi

echo ""
echo "Instalando aplicaciones desde Brewfile..."
brew bundle --file="$BREWFILE"

# ------------------------------------------------------------
# 4. Finder
# ------------------------------------------------------------

echo ""
echo "Configurando Finder..."

defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# ------------------------------------------------------------
# 5. Dock
# ------------------------------------------------------------

echo "Configurando Dock..."
defaults write com.apple.dock autohide -bool true

# ------------------------------------------------------------
# 6. Barra de menus
# ------------------------------------------------------------

echo "Configurando barra de menus..."
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false

# ------------------------------------------------------------
# 7. Trackpad
# ------------------------------------------------------------

echo "Configurando trackpad..."
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# ------------------------------------------------------------
# 8. Teclado: U.S. International
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
# 9. Recargar preferencias
# ------------------------------------------------------------

echo ""
echo "Aplicando cambios..."

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

# ------------------------------------------------------------
# 10. Limpieza
# ------------------------------------------------------------

echo "Limpiando Homebrew..."
brew cleanup

# ------------------------------------------------------------
# 11. Resumen
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
echo "Aplicaciones:"
echo "  - NordVPN"
echo "  - Word"
echo "  - Excel"
echo "  - PowerPoint"
echo "  - Outlook"
echo "  - OneDrive"
echo "  - Pearcleaner"
echo "  - Figma"
echo "  - Tailscale"
echo "  - ChatGPT"
echo ""

echo "Despues inicia sesion donde corresponda:"
echo "  - Microsoft 365 / Outlook / OneDrive"
echo "  - NordVPN"
echo "  - Tailscale"
echo "  - Figma"
echo "  - ChatGPT"
echo ""
echo "Si algun ajuste de trackpad o barra de menus no aparece"
echo "inmediatamente, cierra sesion o reinicia la Mac."
echo ""
