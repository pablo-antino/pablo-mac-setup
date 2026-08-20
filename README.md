# Pablo Mac Setup

Configuracion reproducible para una Mac nueva.

## Un solo comando

En una Mac nueva, abre Terminal y ejecuta solamente esto:

```bash
curl -fsSL https://raw.githubusercontent.com/pablo-antino/pablo-mac-setup/main/setup-mac.sh | zsh
```

No necesitas `git clone`, `cd`, `chmod`, `git pull` ni iniciar sesion en GitHub.

El mismo comando sirve tambien para volver a ejecutar el setup: salta lo que ya esta instalado, repara instalaciones incompletas y reintenta lo pendiente.

## Que hace automaticamente

- Comprueba la conexion a GitHub.
- Si falta Xcode Command Line Tools, abre su instalador y espera hasta que termine.
- Instala y configura Homebrew si hace falta.
- Descarga siempre el Brewfile actual desde GitHub, para no usar configuraciones locales antiguas.
- Corrige automaticamente `onedrive-cli` si una version anterior lo instalo por error.
- Verifica cada aplicacion por su `.app` real en `/Applications`, no solo por el registro de Homebrew.
- Si Homebrew dice que un cask esta instalado pero falta su `.app`, ejecuta `brew reinstall --cask` automaticamente.
- Instala las aplicaciones que realmente faltan.
- Mantiene Homebrew en primer plano para que los prompts de `sudo` puedan leer la contrasena correctamente.
- Fuerza las descargas de Homebrew a una por una para reducir fallos con descargas grandes de Microsoft.
- Ejecuta el indicador de progreso en segundo plano y evita imprimirlo mientras `sudo` esta esperando la contrasena.
- Hace una verificacion fisica final de todas las aplicaciones antes de declarar el setup completado.
- Aplica las preferencias de macOS.

## Contrasena de administrador

Algunos casks de Homebrew usan instaladores `.pkg` de macOS y necesitan `sudo`.

Homebrew se ejecuta en primer plano durante la instalacion para conservar el control del Terminal. Cuando aparezca `Password:`, escribe la contrasena normalmente; el indicador de progreso se pausa visualmente mientras el prompt esta activo para no interferir con la entrada.

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

## Verificacion fisica

El setup espera encontrar estas aplicaciones en `/Applications`:

- `/Applications/NordVPN.app`
- `/Applications/Microsoft Word.app`
- `/Applications/Microsoft Excel.app`
- `/Applications/Microsoft PowerPoint.app`
- `/Applications/Microsoft Outlook.app`
- `/Applications/OneDrive.app`
- `/Applications/Pearcleaner.app`
- `/Applications/Figma.app`
- `/Applications/Tailscale.app`
- `/Applications/ChatGPT.app`

Si falta una de estas rutas aunque Homebrew tenga el cask registrado, el setup la considera incompleta y la reinstala.

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
