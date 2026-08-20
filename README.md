# Pablo Mac Setup

Configuracion reproducible para una Mac nueva.

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

## Uso en una Mac nueva

```bash
git clone https://github.com/pablo-antino/pablo-mac-setup.git
cd pablo-mac-setup
chmod +x setup-mac.sh
./setup-mac.sh
```

Si Xcode Command Line Tools no esta instalado, la primera ejecucion abrira su instalacion. Al terminar, vuelve a ejecutar `./setup-mac.sh`.
