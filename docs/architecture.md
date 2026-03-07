# Arquitectura del frontend

## Visión general

El frontend de Sixin está desarrollado con Flutter y organizado de forma modular dentro de `lib/`, separando responsabilidades entre lógica compartida, modelos de datos, pantallas y componentes reutilizables.

Este repositorio corresponde únicamente a **`sixin_front`**. La plataforma completa de Sixin se apoya también en un backend independiente, mantenido en otro repositorio, que centraliza parte de la lógica de servidor mediante Next.js API Routes.

La arquitectura del frontend busca facilitar:

- separación de responsabilidades
- reutilización de componentes
- mantenimiento progresivo del proyecto
- escalabilidad conforme crezcan las funcionalidades

---

## Principios de organización

La estructura del proyecto sigue varios criterios:

### 1. Separación entre interfaz y acceso a datos
La interacción con Firebase y otros servicios externos se encapsula en `core/services/`, evitando repartir lógica de acceso a datos dentro de las pantallas.

### 2. Organización por responsabilidad
Las carpetas principales de `lib/` separan:

- lógica compartida
- modelos
- pantallas
- widgets reutilizables

### 3. Modularidad por flujo funcional
Las pantallas se agrupan por dominios o flujos de uso, como autenticación, listas, perfil o configuración.

### 4. Escalabilidad progresiva
La estructura permite crecer sin necesidad de rehacer el proyecto entero, añadiendo nuevos módulos o subdividiendo servicios cuando el dominio lo requiera.

---

## Estructura general del proyecto

```text
sixin_front/
├── android/
├── assets/
├── ios/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── list_service.dart
│   │   │   ├── profile_service.dart
│   │   │   ├── services.dart
│   │   │   └── settings_service.dart
│   │   ├── settings/
│   │   ├── theme/
│   │   └── utils/
│   ├── models/
│   │   ├── models.dart
│   │   ├── sixin_list.dart
│   │   └── sixin_list_item.dart
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── auth_gate.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── reset_password_screen.dart
│   │   ├── home/
│   │   ├── inbox/
│   │   ├── list/
│   │   │   ├── create/
│   │   │   │   ├── widgets/
│   │   │   │   └── create_list_screen.dart
│   │   │   └── detail/
│   │   │       ├── logic/
│   │   │       ├── widgets/
│   │   │       └── list_detail_screen.dart
│   │   ├── options/
│   │   ├── profile/
│   │   │   ├── member/
│   │   │   │   └── user_profile_screen.dart
│   │   │   └── self/
│   │   │       ├── edit_profile_screen.dart
│   │   │       └── self_profile_screen.dart
│   │   ├── widgets/
│   │   └── screens.dart
│   ├── widgets/
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

---

## Capas principales

## `core/`

Contiene la base compartida del proyecto y la lógica transversal que no pertenece a una pantalla concreta.

### `core/constants/`
Agrupa constantes globales utilizadas en distintos puntos de la aplicación.

Aquí pueden residir, por ejemplo:

- claves de configuración
- nombres de colecciones
- valores fijos reutilizados
- nomenclaturas compartidas

### `core/services/`
Contiene la capa de acceso a datos y servicios de aplicación.

Su función principal es encapsular la interacción con:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- backend externo de Sixin

Servicios identificados actualmente:

- **`auth_service.dart`**: autenticación
- **`list_service.dart`**: gestión de listas, miembros, solicitudes e invitaciones
- **`profile_service.dart`**: perfil, username y foto de usuario
- **`settings_service.dart`**: ajustes de interfaz
- **`services.dart`**: archivo agregador de exportaciones

### `core/settings/`
Espacio para configuración funcional o parámetros globales de comportamiento de la aplicación.

### `core/theme/`
Contiene la configuración visual de Sixin:

- tema claro y oscuro
- colores
- estilos tipográficos
- apariencia general de componentes

### `core/utils/`
Utilidades auxiliares reutilizables en distintas partes del proyecto.

Aquí encajan funciones puras y helpers que no pertenecen claramente a servicios, modelos o widgets.

---

## `models/`

Contiene los modelos de datos usados por el frontend.

Modelos observados:

- **`sixin_list.dart`**
- **`sixin_list_item.dart`**
- **`models.dart`**

### Responsabilidad

Los modelos sirven para representar entidades del dominio de forma tipada dentro de la aplicación.

### Observación importante

Los modelos actuales parecen reflejar una fase más simple o anterior del proyecto, ya que la estructura real de Firestore y la lógica actual de listas manejan más campos que los representados en `SixinList` y `SixinListItem`.

Esto sugiere una de estas situaciones:

- los modelos todavía no se han actualizado al dominio actual
- parte de la app trabaja directamente con `Map<String, dynamic>` de Firestore
- los modelos actuales cubren solo una parte reducida del dominio

A medio plazo, sería recomendable alinear mejor los modelos Dart con la estructura real de datos.

---

## `screens/`

Agrupa las pantallas de la aplicación por dominios funcionales.

Esta carpeta representa la capa de presentación principal.

### `screens/auth/`

Módulo de autenticación.

Archivos observados:

- **`auth_gate.dart`**
- **`forgot_password_screen.dart`**
- **`login_screen.dart`**
- **`register_screen.dart`**
- **`reset_password_screen.dart`**

#### Responsabilidad

Gestiona todo el flujo de acceso a la aplicación:

- comprobación de sesión activa
- inicio de sesión
- registro
- recuperación de contraseña
- restablecimiento de contraseña

#### Papel de `auth_gate.dart`

`auth_gate.dart` actúa como punto de control del estado de autenticación y decide qué parte de la app mostrar según exista o no sesión iniciada.

---

### `screens/home/`

Módulo de la pantalla principal tras autenticación.

#### Responsabilidad

Concentra la experiencia principal del usuario una vez ha accedido a la aplicación.  
Desde aquí previsiblemente se accede a listas públicas, listas del usuario, drawer, perfil y otras áreas principales.

---

### `screens/inbox/`

Módulo relacionado con el buzón de invitaciones y notificaciones ligadas a listas.

#### Responsabilidad

Mostrar invitaciones pendientes y permitir acciones como aceptar o rechazar invitaciones recibidas.

---

### `screens/list/`

Módulo principal de listas de partido. Es uno de los núcleos funcionales de Sixin.

Se divide actualmente en dos subflujos:

- creación
- detalle

#### `screens/list/create/`

Archivos observados:

- **`create_list_screen.dart`**
- carpeta **`widgets/`**

##### Responsabilidad

Gestiona la creación de nuevas listas de partido, incluyendo:

- lugar
- fecha y hora
- nivel de juego
- sistemas
- precio
- descripción
- visibilidad
- política de acceso

La carpeta `widgets/` contiene componentes específicos reutilizados dentro del formulario o flujo de creación.

#### `screens/list/detail/`

Archivos observados:

- **`list_detail_screen.dart`**
- carpeta **`logic/`**
- carpeta **`widgets/`**

##### Responsabilidad

Gestiona la visualización y las interacciones de una lista concreta, incluyendo previsiblemente:

- información general de la lista
- miembros
- administradores
- solicitudes
- invitaciones
- acciones de unirse, salir o administrar

##### Subdivisión interna

- **`logic/`**: lógica específica del detalle de lista que no conviene dejar directamente incrustada en widgets
- **`widgets/`**: componentes visuales reutilizables dentro de la pantalla de detalle

Esta división es una buena señal de modularización interna en un flujo complejo.

---

### `screens/options/`

Módulo de configuración de la aplicación.

#### Responsabilidad

Permite gestionar preferencias del usuario, como:

- tema visual
- nomenclatura de posiciones de voleibol

---

### `screens/profile/`

Módulo de perfiles de usuario.

Se divide en dos áreas:

- perfil propio
- perfil de otros usuarios

#### `screens/profile/self/`

Archivos observados:

- **`self_profile_screen.dart`**
- **`edit_profile_screen.dart`**

##### Responsabilidad

Permite al usuario autenticado:

- ver su perfil
- editar datos de perfil
- actualizar posiciones
- cambiar username
- subir foto de perfil

#### `screens/profile/member/`

Archivo observado:

- **`user_profile_screen.dart`**

##### Responsabilidad

Mostrar el perfil de otro usuario, especialmente información útil para contexto deportivo, como sus posiciones habituales.

---

### `screens/widgets/`

Contiene widgets compartidos a nivel de pantallas o flujos concretos.

Esta carpeta se diferencia de `lib/widgets/` en que parece orientada a componentes ligados a la capa de screens, no necesariamente reutilizables a nivel global en toda la app.

---

### `screens.dart`

Archivo agregador para exportar pantallas y simplificar imports desde otras partes del proyecto.

---

## `widgets/`

Contiene widgets reutilizables de uso general, no ligados a un único flujo funcional.

### Responsabilidad

Sirve como capa de componentes compartidos de interfaz, reutilizables entre varias pantallas o módulos.

Aquí deberían residir widgets suficientemente genéricos como para no pertenecer solo a `auth`, `list`, `profile` o cualquier otro módulo concreto.

---

## Archivos principales

### `main.dart`

Punto de entrada principal de la aplicación.

### Responsabilidades habituales

- inicialización de Flutter
- inicialización de Firebase
- arranque de la aplicación
- configuración global de navegación o tema
- montaje del widget raíz

### `firebase_options.dart`

Archivo generado de configuración de Firebase para las distintas plataformas soportadas.

Su función es proporcionar la configuración necesaria para conectar la app con el proyecto de Firebase correspondiente.

---

## Infraestructura y configuración

Además del código fuente, hay varios archivos relevantes a nivel de arquitectura.

### `pubspec.yaml`
Define:

- dependencias del proyecto
- assets
- configuración general de Flutter

### `analysis_options.yaml`
Contiene reglas de análisis estático y estilo del proyecto.

### `firebase.json`
Configuración vinculada al ecosistema Firebase.

### `firestore.indexes.json`
Define índices compuestos necesarios para las consultas utilizadas por la aplicación.

---

## Relación entre capas

De forma simplificada, el flujo de dependencias esperado sería este:

```text
screens/widgets ──> services ──> Firebase / backend
       │
       └───────> models
```

Más detalladamente:

1. las **screens** representan la interfaz y coordinan la interacción del usuario
2. las **screens** usan **services** para ejecutar operaciones de negocio o acceso a datos
3. los **services** se apoyan en Firebase o en el backend de Sixin
4. los **models** sirven para representar datos del dominio dentro de la aplicación
5. los **widgets** encapsulan piezas reutilizables de interfaz

---

## Decisiones arquitectónicas destacables

### Uso de servicios singleton
Los servicios siguen un patrón singleton con acceso mediante `.instance`.  
Esto simplifica el acceso compartido desde distintas partes de la app.

### Separación entre perfil, listas, auth y settings
La división actual de servicios y pantallas sigue bastante bien los dominios principales del producto.

### Firestore como eje del estado persistente
Gran parte del comportamiento funcional de la aplicación depende directamente de Firestore, tanto para datos principales como para relaciones y permisos.

### Modularización interna en flujos complejos
El módulo `screens/list/detail/` ya introduce carpetas internas de `logic/` y `widgets/`, lo que ayuda a controlar la complejidad.

---

## Fortalezas actuales

- estructura clara y bastante legible
- buena separación inicial de responsabilidades
- organización por módulos funcionales
- integración razonable entre interfaz y servicios
- base adecuada para seguir creciendo

---

## Aspectos a vigilar

### `ListService` concentra demasiada responsabilidad
Actualmente agrupa muchas operaciones distintas:

- consultas
- creación
- miembros
- admins
- solicitudes
- invitaciones
- acceso por código
- borrado vía backend

A medio plazo podría convenir dividirlo.

### Modelos aparentemente desalineados con el dominio actual
Los modelos vistos no reflejan toda la complejidad actual de listas, usuarios y membresías.

### Posible crecimiento desigual entre carpetas
Si ciertos módulos siguen creciendo, convendrá aplicar una estructura más estricta por feature, especialmente en `screens/` y quizá también en `models/`.

---

## Posibles evoluciones futuras

Conforme Sixin crezca, esta arquitectura podría evolucionar hacia una organización todavía más orientada por dominio. Por ejemplo:

```text
lib/
├── features/
│   ├── auth/
│   ├── lists/
│   ├── profile/
│   └── settings/
├── core/
└── shared/
```

O bien, sin reorganización total, mantener la estructura actual pero subdividir servicios grandes y reforzar el uso de modelos tipados.

---

## Resumen

La arquitectura actual de `sixin_front` sigue una estructura modular clásica y razonablemente limpia para una aplicación Flutter apoyada en Firebase.

Su organización separa:

- lógica compartida en `core/`
- modelos en `models/`
- presentación en `screens/`
- componentes reutilizables en `widgets/`

Esto proporciona una base sólida para seguir desarrollando Sixin, aunque algunos elementos, como `ListService` y la capa de modelos, probablemente necesitarán refactorización progresiva conforme el proyecto gane complejidad.