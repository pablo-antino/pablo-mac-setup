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

## Seguridad

Este repositorio no debe contener contrasenas, tokens, claves API, licencias, certificados privados ni otras credenciales.
