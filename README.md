# Sixin

## Descripción general

Sixin es una aplicación pensada para organizar partidos de voleibol de forma más cómoda que los sistemas tradicionales basados en grupos de mensajería.

La aplicación permite a usuarios registrados crear y gestionar listas de jugadores para partidos, facilitando la incorporación de participantes, la visibilidad de la información relevante del encuentro y la organización interna de los miembros.

Su objetivo es ofrecer una alternativa más estructurada y eficiente a los grupos de WhatsApp, donde actualmente muchas listas se gestionan copiando y pegando mensajes en comunidades de más de 100 o 200 personas.

## Arquitectura general

Sixin está dividido en dos proyectos independientes, cada uno con su propio repositorio:

- **sixin_front**: aplicación móvil desarrollada con Flutter
- **sixin_back**: backend desarrollado con Next.js API Routes

Este repositorio corresponde únicamente a **`sixin_front`**.

El frontend se encarga de la interfaz de usuario, la navegación, la experiencia de uso y la comunicación con los servicios necesarios para la aplicación.

El backend de Sixin se mantiene en un repositorio separado y centraliza la lógica de servidor que no reside exclusivamente en el cliente.

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

### Frontend
- Flutter

### Infraestructura y servicios
- Firebase

### Backend relacionado
- Next.js API Routes

### Futuro
- Vercel

## Estado del proyecto

Proyecto en desarrollo activo.

Actualmente Sixin ya permite la creación y gestión de listas para partidos de voleibol, pero sigue evolucionando con nuevas funciones orientadas a mejorar la organización de jugadores y partidos.

## Roadmap

- Opción para borrar la cuenta
- Seguimiento de pagos entre miembros
- Sistema de amigos
- Mejoras en el perfil para mostrar experiencia
- Imágenes de perfil
- Mejoras en despliegue backend
- Nuevas herramientas de organización de partidos

## Instalación y ejecución

Este repositorio corresponde a **`sixin_front`**, el frontend móvil de Sixin desarrollado con Flutter.

Para el funcionamiento completo de la plataforma, Sixin también cuenta con un backend independiente en otro repositorio: **`sixin_back`**.

### Requisitos

Para trabajar con este proyecto se recomienda tener instalado:

- Flutter SDK
- Dart SDK
- Un emulador Android o dispositivo físico
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

Algunas funcionalidades pueden depender de servicios externos o del backend de Sixin, que se desarrolla y mantiene en un repositorio separado.

## Estructura del proyecto

A nivel general, este repositorio sigue esta organización:

```text
sixin_front/
├── android/
├── assets/
├── ios/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── services/
│   │   ├── settings/
│   │   ├── theme/
│   │   └── utils/
│   ├── models/
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── inbox/
│   │   ├── list/
│   │   ├── options/
│   │   ├── profile/
│   │   └── screens.dart
│   ├── widgets/
│   │   └── common/
│   ├── firebase_options.dart
│   └── main.dart
├── linux/
├── macos/
├── test/
├── web/
├── windows/
├── analysis_options.yaml
├── firebase.json
├── firestore.indexes.json
├── pubspec.yaml
└── README.md
```

### Organización principal

- **android/**, **ios/**, **linux/**, **macos/**, **web/**, **windows/**: plataformas soportadas por Flutter
- **assets/**: recursos estáticos de la aplicación
- **lib/**: código fuente principal del frontend
- **test/**: pruebas del proyecto
- **pubspec.yaml**: dependencias y configuración de Flutter
- **firebase.json**: configuración relacionada con Firebase
- **firestore.indexes.json**: definición de índices de Firestore
- **analysis_options.yaml**: reglas de análisis estático del proyecto

### Estructura de `lib/`

#### `core/`
Contiene elementos transversales reutilizables en distintas partes de la aplicación:

- **constants/**: constantes globales
- **services/**: servicios de acceso a datos o lógica compartida
- **settings/**: configuración funcional de la aplicación
- **theme/**: temas y estilos visuales
- **utils/**: utilidades generales

#### `models/`
Incluye los modelos de datos utilizados por la aplicación.

#### `screens/`
Agrupa las distintas pantallas organizadas por dominio funcional:

- **auth/**: autenticación
- **home/**: pantalla principal
- **inbox/**: buzón de invitaciones o notificaciones
- **list/**: gestión y visualización de listas
- **options/**: configuración de la aplicación
- **profile/**: perfil propio y de otros usuarios
- **screens.dart**: punto central de exportación o acceso a pantallas

#### `widgets/`
Contiene widgets reutilizables de la interfaz.

- **common/**: widgets compartidos entre varias pantallas

#### Archivos principales

- **main.dart**: punto de entrada principal de la aplicación
- **firebase_options.dart**: configuración de Firebase generada para las plataformas soportadas

## Visión de futuro

Sixin busca convertirse en una herramienta específica para la comunidad de voleibol aficionado, sustituyendo métodos improvisados de organización por un sistema claro, visual y estructurado.

Entre las mejoras previstas destaca la incorporación de funcionalidades relacionadas con el seguimiento de pagos y una organización social más completa entre jugadores.