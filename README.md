# Sixin Front

## Descripción general

Sixin es una aplicación pensada para organizar partidos de voleibol de forma más cómoda que los sistemas tradicionales basados en grupos de mensajería.

La aplicación permite a usuarios registrados crear y gestionar listas de jugadores para partidos, facilitando la incorporación de participantes, la visibilidad de la información relevante del encuentro y la organización interna de los miembros.

Su objetivo es ofrecer una alternativa más estructurada y eficiente a los grupos de WhatsApp, donde actualmente muchas listas se gestionan copiando y pegando mensajes en comunidades de más de 100 o 200 personas.

## Arquitectura general

Sixin está dividido en dos proyectos independientes, cada uno con su propio repositorio:

- **sixin_front**: frontend desarrollado con Flutter
- **sixin_back**: backend desarrollado con Next.js API Routes

Este repositorio corresponde únicamente a **`sixin_front`**.

## Problema que resuelve

En muchos entornos de voleibol aficionado, la organización de partidos se realiza mediante mensajes en grupos grandes de WhatsApp. Esto genera varios problemas:

- Dificultad para seguir quién se apunta realmente
- Poca claridad sobre quién administra cada lista
- Falta de control sobre invitaciones y accesos
- Ausencia de información estructurada sobre nivel, precio, sistemas de juego o posiciones
- Gestión manual y desordenada de pagos

Sixin nace para centralizar y simplificar este proceso en una aplicación específica.

## Público objetivo

La aplicación está orientada principalmente a jugadores de voleibol aficionados que organizan partidos frecuentes y necesitan una herramienta más clara y cómoda para gestionar la participación.

## Funcionalidades principales

- Creación de listas para partidos
- Listas públicas y privadas
- Acceso mediante invitación, código o aprobación
- Gestión de administradores y miembros
- Selección de posición de preferencia
- Consulta de perfiles
- Buzón de invitaciones
- Configuración de tema e idioma de posiciones

## Tecnologías utilizadas

- **Frontend:** Flutter
- **Infraestructura y servicios:** Firebase
- **Backend relacionado:** Next.js API Routes
- **Despliegue del backend:** Vercel

## Estado del proyecto

Proyecto en desarrollo activo.

Actualmente Sixin ya permite la creación y gestión de listas para partidos de voleibol, pero sigue evolucionando con nuevas funciones orientadas a mejorar la organización de jugadores y partidos.

## Roadmap

- Opción para borrar la cuenta
- Reset de contraseña funcional
- Seguimiento de pagos entre miembros
- Sistema de amigos
- Mejoras en el perfil para mostrar experiencia
- Imágenes de perfil
- Mejoras en despliegue backend
- Login con Google
- Nuevas herramientas de organización de partidos

## Instalación y ejecución

Este repositorio corresponde a **`sixin_front`**, el frontend de Sixin desarrollado con Flutter.

Para el funcionamiento completo de la plataforma, Sixin también cuenta con un backend independiente en otro repositorio: **`sixin_back`**.

### Requisitos

Para trabajar con este proyecto se recomienda tener instalado:

- Flutter SDK
- Dart SDK
- Un emulador Android o un dispositivo físico
- Visual Studio Code o Android Studio

### Instalación

1. Clonar este repositorio.
2. Entrar en la carpeta del proyecto.
3. Instalar dependencias:

```bash
flutter pub get
```

4. Configurar Firebase para el entorno local si es necesario.

### Ejecución

Para ejecutar la aplicación en desarrollo:

```bash
flutter run
```

Si hay varios dispositivos disponibles, se puede elegir uno con:

```bash
flutter devices
flutter run -d <device_id>
```

### Nota sobre el backend

Algunas funcionalidades dependen del backend de Sixin, desplegado de forma independiente. Para que esas funciones operen correctamente, el frontend debe apuntar a una URL válida del backend.

## Estructura resumida del proyecto

```text
sixin_front/
├── assets/
├── lib/
├── test/
├── android/
├── ios/
├── web/
├── windows/
├── linux/
├── macos/
├── pubspec.yaml
└── README.md
```

## Documentación adicional

- [Arquitectura del frontend](docs/architecture.md)
- [Servicios principales](docs/services.md)
- [Modelo de datos en Firestore](docs/firestore.md)
- [Flujos principales](docs/flows.md)
- [Pantallas del frontend](docs/screens.md)

## Visión de futuro

Sixin busca convertirse en una herramienta específica para la comunidad de voleibol aficionado, sustituyendo métodos improvisados de organización por un sistema claro, visual y estructurado.

Entre las mejoras previstas destaca la incorporación de funcionalidades relacionadas con el seguimiento de pagos y una organización social más completa entre jugadores.