# Pablo Mac Setup

Configuracion reproducible para una Mac nueva.

## Un solo comando

En una Mac nueva, abre Terminal y ejecuta solamente esto:

```bash
curl -fsSL https://raw.githubusercontent.com/pablo-antino/pablo-mac-setup/main/setup-mac.sh | zsh
```

No necesitas `git clone`, `cd`, `chmod`, `git pull` ni iniciar sesion en GitHub.

El mismo comando sirve tambien para volver a ejecutar el setup: salta lo que ya esta instalado y reintenta lo pendiente.

## Que hace automaticamente

- Comprueba la conexion a GitHub.
- Si falta Xcode Command Line Tools, abre su instalador y espera hasta que termine.
- Instala y configura Homebrew si hace falta.
- Descarga siempre el Brewfile actual desde GitHub, para no usar configuraciones locales antiguas.
- Corrige automaticamente `onedrive-cli` si una version anterior lo instalo por error.
- Detecta que aplicaciones ya estan instaladas.
- Instala todas las aplicaciones pendientes dentro de un unico proceso de Homebrew.
- Fuerza las descargas de Homebrew a una por una para reducir fallos con descargas grandes de Microsoft.
- Muestra un estado al menos cada 15 segundos mientras la instalacion sigue activa.
- Aplica las preferencias de macOS.

## Contrasena de administrador

Algunos casks de Homebrew usan instaladores `.pkg` de macOS y necesitan `sudo`.

El setup agrupa todas las aplicaciones pendientes en un unico proceso de Homebrew para evitar iniciar un comando separado por cada aplicacion. Si un instalador necesita privilegios, Homebrew puede pedir la contrasena durante ese proceso; no se intenta desactivar ni modificar la seguridad global de `sudo`.

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

## Configura macOS

- Finder: extensiones, barra de ruta y barra de estado
- Dock: ocultar automaticamente
- Barra de menus: ocultar automaticamente siempre
- Trackpad: clic secundario en la esquina inferior derecha
- Teclado: U.S. International
- Screenshots: no modifica su ubicacion ni configuracion

## Seguridad

Homebrew se ejecuta como tu usuario normal. El setup no crea reglas `NOPASSWD`, no modifica `sudoers` y no guarda contrasenas.

Este repositorio no debe contener contrasenas, tokens, claves API, licencias, certificados privados ni otras credenciales.
