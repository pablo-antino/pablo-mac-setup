# Pablo Mac Setup

Configuracion reproducible para una Mac nueva.

## Instalacion rapida

En una Mac nueva, abre Terminal y ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/pablo-antino/pablo-mac-setup/main/setup-mac.sh | zsh
```

No hace falta iniciar sesion en GitHub porque este repositorio es publico.

Si Xcode Command Line Tools no esta instalado, macOS abrira su instalacion. Cuando termine, vuelve a ejecutar exactamente el mismo comando.

## Instala

- NordVPN
- Microsoft Word
- Microsoft Excel
- Microsoft PowerPoint
- Microsoft Outlook
- OneDrive
- Pearcleaner
- Figma
- Tailscale
- ChatGPT

El setup instala las aplicaciones una por una y muestra salida detallada, para que puedas ver exactamente que aplicacion se esta descargando o instalando.

Las descargas grandes de Microsoft usan mas reintentos de Homebrew para tolerar cortes temporales del CDN.

## Homebrew

El setup agrega Homebrew a `~/.zprofile` y lo carga inmediatamente dentro del proceso de instalacion.

Si interrumpes el setup y tu Terminal actual todavia no reconoce `brew`, ejecuta:

```bash
source ~/.zprofile
```

## Si ya clonaste el repositorio antes

Actualiza tu copia local antes de volver a ejecutar el setup:

```bash
cd ~/pablo-mac-setup
git pull
source ~/.zprofile
./setup-mac.sh
```

Esto evita ejecutar una version antigua que todavia use `brew bundle`.

## Configura macOS

- Finder: extensiones, barra de ruta y barra de estado
- Dock: ocultar automaticamente
- Barra de menus: ocultar automaticamente siempre
- Trackpad: clic secundario en la esquina inferior derecha
- Teclado: U.S. International
- Screenshots: no modifica su ubicacion ni configuracion

## Instalacion mediante Git

Como alternativa al comando rapido:

```bash
git clone https://github.com/pablo-antino/pablo-mac-setup.git
cd pablo-mac-setup
chmod +x setup-mac.sh
./setup-mac.sh
```

El script tambien funciona con `curl | zsh`: si no encuentra un `Brewfile` local, lo descarga automaticamente desde este repositorio.

## Seguridad

Este repositorio no debe contener contrasenas, tokens, claves API, licencias, certificados privados ni otras credenciales.
