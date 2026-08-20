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
- Instala las aplicaciones una por una.
- Reintenta cada aplicacion hasta 3 veces si falla.
- Muestra un estado al menos cada 15 segundos mientras una app sigue descargando o instalando.
- Aplica las preferencias de macOS.

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

Este repositorio no debe contener contrasenas, tokens, claves API, licencias, certificados privados ni otras credenciales.
