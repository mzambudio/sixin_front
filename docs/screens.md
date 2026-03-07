# Pantallas del frontend

## Visión general

Este documento describe las pantallas principales del frontend de Sixin y su papel dentro de la experiencia de usuario.

Mientras que `architecture.md` documenta la estructura del proyecto a nivel técnico y `flows.md` describe procesos funcionales, este documento se centra en la **capa de presentación**: qué pantallas existen, para qué sirven y cómo se relacionan entre sí.

---

## Objetivos de esta capa

La capa de pantallas de Sixin tiene varias responsabilidades:

- mostrar la información relevante al usuario
- recoger datos mediante formularios e interacciones
- conectar la interfaz con la capa de servicios
- organizar la navegación entre flujos
- reflejar el estado de autenticación y membresía del usuario

---

## Organización general

La carpeta `lib/screens/` está organizada por dominios funcionales:

```text
lib/screens/
├── auth/
├── home/
├── inbox/
├── list/
│   ├── create/
│   └── detail/
├── options/
├── profile/
│   ├── member/
│   └── self/
├── widgets/
└── screens.dart
```

Esta estructura busca separar los distintos flujos de la aplicación:

- autenticación
- navegación principal
- gestión de listas
- perfiles
- configuración
- componentes visuales ligados a pantallas

---

## Relación con otras capas

Las pantallas no deberían concentrar lógica de datos compleja. Su función principal es coordinar la interacción del usuario y apoyarse en otras capas:

- **services** para autenticación, acceso a Firestore y operaciones de negocio
- **models** para representar datos
- **widgets** para reutilizar componentes visuales
- **theme/settings** para apariencia y configuración

De forma simplificada:

```text
Pantallas -> Servicios -> Firebase / backend
Pantallas -> Widgets
Pantallas -> Models
```

---

## Módulo `auth/`

Contiene las pantallas relacionadas con el acceso a la aplicación.

Archivos observados:

```text
auth/
├── auth_gate.dart
├── forgot_password_screen.dart
├── login_screen.dart
├── register_screen.dart
└── reset_password_screen.dart
```

### Responsabilidad general

Gestionar el ciclo de autenticación del usuario:

- entrada a la aplicación
- inicio de sesión
- registro
- recuperación de contraseña
- redirección según el estado de sesión

---

### `auth_gate.dart`

#### Propósito

Actuar como punto de entrada lógico para decidir qué parte de la app debe mostrarse según el estado de autenticación.

#### Responsabilidades

- escuchar cambios de sesión
- detectar si existe usuario autenticado
- mostrar la rama de pantallas adecuada
- evitar que la lógica de acceso quede repartida por toda la app

#### Relación con servicios

- `AuthService.authStateChanges()`

#### Importancia arquitectónica

Es una pantalla o componente clave porque centraliza la transición entre:

- estado no autenticado
- estado autenticado

---

### `login_screen.dart`

#### Propósito

Permitir a un usuario existente iniciar sesión.

#### Responsabilidades

- recoger email y contraseña
- validar entrada básica
- invocar el servicio de autenticación
- mostrar feedback de errores
- disparar el acceso al resto de la aplicación

#### Relación con servicios

- `AuthService.signInWithEmail(...)`

---

### `register_screen.dart`

#### Propósito

Permitir la creación de una cuenta nueva con perfil inicial.

#### Responsabilidades

- recoger email, contraseña, username y posiciones
- validar datos del formulario
- crear cuenta en Firebase Authentication
- crear perfil en Firestore
- reservar username único
- gestionar rollback si el alta queda incompleta

#### Particularidades

Esta pantalla hace más que una simple alta visual: también participa directamente en la creación del perfil inicial del usuario.

#### Datos gestionados

- email
- contraseña
- username
- posiciones iniciales

#### Resultado esperado

- usuario autenticado
- perfil creado en `users/{uid}`
- username reservado en `usernames/{usernameLower}`

---

### `forgot_password_screen.dart`

#### Propósito

Permitir que el usuario solicite un correo de recuperación de contraseña.

#### Responsabilidades

- recoger email
- validar que tenga formato razonable
- invocar el envío de reset

#### Relación con servicios

- `AuthService.sendPasswordResetEmail(...)`

---

### `reset_password_screen.dart`

#### Propósito

Dar soporte visual al flujo de restablecimiento de contraseña.

#### Observación

Según cómo esté implementado exactamente, puede servir como pantalla informativa, pantalla de confirmación o paso adicional de un flujo ligado a Firebase.

---

## Módulo `home/`

### Propósito general

Representa la entrada principal de la aplicación una vez el usuario ha iniciado sesión.

### Responsabilidades esperadas

- mostrar contenido principal
- servir como punto de navegación al resto de áreas
- presentar listas públicas o listas del usuario
- integrar drawer, accesos rápidos o acciones principales

### Papel dentro de la app

La pantalla Home funciona como centro de operaciones de Sixin. Desde ella el usuario puede iniciar la mayoría de flujos importantes:

- explorar listas
- acceder a su buzón
- abrir perfil
- entrar en opciones
- crear nuevas listas

---

## Módulo `inbox/`

### Propósito general

Gestionar el buzón de invitaciones y otras notificaciones relacionadas con listas.

### Responsabilidades

- mostrar invitaciones pendientes
- permitir aceptar invitaciones
- permitir rechazar invitaciones
- reflejar el estado del buzón en tiempo real

### Origen de datos

- `users/{uid}/invites/{listId}`

### Relación con servicios

- `ListService.acceptInvite(...)`
- `ListService.rejectInvite(...)`

### Papel dentro de la experiencia

El inbox permite convertir una invitación en acción directa, evitando depender de mensajes externos o coordinación manual.

---

## Módulo `list/`

Es uno de los módulos centrales del frontend, ya que en Sixin el concepto principal de negocio es la **lista de partido**.

```text
list/
├── create/
└── detail/
```

---

## Submódulo `list/create/`

Archivos observados:

```text
create/
├── widgets/
└── create_list_screen.dart
```

### `create_list_screen.dart`

#### Propósito

Permitir al usuario crear una nueva lista de partido.

#### Responsabilidades

- mostrar el formulario de creación
- recoger y validar los campos de la lista
- permitir configurar:
  - lugar
  - fecha y hora
  - niveles
  - sistemas
  - precio
  - descripción
  - visibilidad
  - política de acceso
- llamar al servicio de creación
- mostrar el código de acceso si la lista es privada

#### Relación con servicios

- `ListService.createList(...)`

#### Resultado esperado

- nueva lista creada en Firestore
- creador convertido en admin y miembro
- código generado si la lista es privada

### `list/create/widgets/`

#### Propósito

Contener componentes específicos del flujo de creación de lista.

#### Ventaja

Evita que `create_list_screen.dart` crezca demasiado y permite reutilizar partes del formulario o sus secciones.

---

## Submódulo `list/detail/`

Archivos observados:

```text
detail/
├── logic/
├── widgets/
└── list_detail_screen.dart
```

### `list_detail_screen.dart`

#### Propósito

Mostrar el detalle completo de una lista concreta y permitir interacciones sobre ella.

#### Responsabilidades esperadas

- mostrar información principal del partido
- mostrar miembros y administradores
- mostrar acciones disponibles según contexto
- permitir unirse, solicitar acceso o abandonar la lista
- permitir administración de miembros y solicitudes
- permitir gestionar invitaciones si el usuario es admin

#### Importancia funcional

Es una de las pantallas más complejas de la aplicación porque concentra gran parte de la lógica visible de negocio.

#### Posibles contextos de uso

La misma pantalla puede comportarse de forma distinta según el usuario sea:

- visitante de lista pública
- usuario con acceso por código
- solicitante pendiente
- invitado
- miembro
- administrador

### `list/detail/logic/`

#### Propósito

Separar parte de la lógica específica del detalle de lista para que no viva entera dentro de la pantalla o los widgets visuales.

#### Utilidad

Esta carpeta ayuda a contener la complejidad de un flujo especialmente rico en estados y permisos.

### `list/detail/widgets/`

#### Propósito

Agrupar widgets específicos del detalle de lista.

#### Ejemplos esperables

Aquí pueden vivir componentes como:

- cabecera de lista
- barra de acciones
- listado de miembros
- panel de solicitudes
- controles de invitación
- selectores de posición preferida

---

## Módulo `options/`

### Propósito general

Permitir al usuario ajustar preferencias de comportamiento o presentación de la aplicación.

### Responsabilidades observadas o esperadas

- cambiar tema visual
- configurar idioma o nomenclatura de posiciones
- centralizar ajustes de experiencia de usuario

### Relación con servicios

- `SettingsService.watchUi()`
- `SettingsService.setPositionsLang(...)`

### Papel dentro de la app

Esta pantalla da soporte a la personalización y ayuda a adaptar Sixin a diferentes preferencias de uso.

---

## Módulo `profile/`

Gestiona la visualización y edición de perfiles.

```text
profile/
├── member/
└── self/
```

Separa claramente dos casos:

- ver el perfil propio
- ver el perfil de otro usuario

---

## Submódulo `profile/self/`

Archivos observados:

```text
self/
├── edit_profile_screen.dart
└── self_profile_screen.dart
```

### `self_profile_screen.dart`

#### Propósito

Mostrar el perfil del usuario autenticado.

#### Responsabilidades

- presentar username
- mostrar posiciones habituales
- mostrar foto de perfil si existe
- servir de punto de acceso a la edición del perfil

#### Relación con servicios

- `ProfileService.watchUserDoc(uid)`

---

### `edit_profile_screen.dart`

#### Propósito

Permitir modificar la información del perfil propio.

#### Responsabilidades observadas o esperadas

- editar username
- editar posiciones
- seleccionar imagen de perfil
- subir foto a Storage
- persistir cambios en Firestore
- mostrar errores de validación o conflictos de username

#### Relación con servicios

- `ProfileService.updatePositions(...)`
- `ProfileService.updateUsername(...)`
- `ProfileService.uploadProfilePhoto(...)`

#### Importancia funcional

Es una pantalla clave porque condensa la personalización principal del usuario y sus datos visibles para otros.

---

## Submódulo `profile/member/`

Archivo observado:

```text
member/
└── user_profile_screen.dart
```

### `user_profile_screen.dart`

#### Propósito

Mostrar el perfil de otro usuario.

#### Responsabilidades

- mostrar username
- mostrar posiciones habituales
- mostrar otros datos públicos del perfil si existen

#### Relación con servicios

- `ProfileService.watchUserDoc(uid)`

#### Papel dentro del producto

Esta pantalla es útil para que los jugadores consulten qué posiciones suele desempeñar otra persona antes o durante la organización de partidos.

---

## Módulo `screens/widgets/`

### Propósito general

Contener widgets compartidos dentro de la capa de pantallas.

### Diferencia respecto a `lib/widgets/`

- **`lib/widgets/`**: widgets globales y reutilizables a nivel de app
- **`lib/screens/widgets/`**: widgets reutilizables pero más ligados al comportamiento o contexto de pantallas concretas

Esta separación ayuda a no mezclar componentes muy genéricos con otros que siguen perteneciendo a la capa de presentación de ciertos flujos.

---

## Archivo `screens.dart`

### Propósito

Centralizar exportaciones de pantallas para simplificar imports.

### Ventaja

Permite que otras partes del proyecto importen un único archivo en lugar de una ruta individual por pantalla, mejorando legibilidad y mantenimiento.

---

## Navegación de alto nivel

Aunque la implementación exacta de navegación no se detalla aquí, a nivel conceptual la experiencia de usuario sigue este esquema:

```text
AuthGate
├── No autenticado
│   ├── Login
│   ├── Registro
│   └── Recuperación de contraseña
└── Autenticado
    ├── Home
    ├── Inbox
    ├── Create List
    ├── List Detail
    ├── Self Profile
    ├── User Profile
    └── Options
```

---

## Estados de pantalla importantes

Algunas pantallas de Sixin tienen un comportamiento especialmente dependiente del estado del usuario o del contexto:

### `auth_gate.dart`
Depende de si existe sesión iniciada o no.

### `list_detail_screen.dart`
Puede cambiar mucho según el usuario sea:

- visitante
- usuario con acceso por código
- invitado
- solicitante
- miembro
- administrador

### `edit_profile_screen.dart`
Depende de validaciones, cambios locales, subida de imagen y conflictos de username.

### `inbox/`
Depende del contenido del buzón y del estado de cada invitación.

---

## Fortalezas de la organización actual

- agrupación clara por dominios funcionales
- separación entre perfil propio y ajeno
- subdivisión útil en flujos complejos como listas
- apoyo en carpetas `widgets/` y `logic/` para contener complejidad
- estructura coherente con una app que crecerá por features

---

## Aspectos a vigilar

### Pantallas con mucha lógica
Algunas pantallas, especialmente las relacionadas con listas y perfil, pueden crecer rápido si absorben demasiada lógica de validación o transformación.

### Posible necesidad de view models o controladores
Si la complejidad sigue aumentando, podría resultar útil introducir una capa intermedia de estado o presentación para descargar ciertas pantallas.

### Riesgo de dispersión de widgets
Conviene mantener criterio claro sobre cuándo un widget va a:

- `lib/widgets/`
- `lib/screens/widgets/`
- `screens/<feature>/widgets/`

---

## Posible evolución futura

Si el proyecto sigue creciendo, la organización de pantallas podría evolucionar hacia una estructura todavía más orientada por feature, por ejemplo:

```text
lib/features/
├── auth/
├── inbox/
├── lists/
├── profile/
└── settings/
```

Aun así, la estructura actual ya ofrece una base bastante buena y comprensible.

---

## Resumen

La carpeta `screens/` representa la capa de presentación principal del frontend de Sixin.

Su organización actual separa con claridad los grandes dominios funcionales de la aplicación:

- autenticación
- navegación principal
- listas
- buzón
- perfiles
- configuración

Esta estructura permite mantener una interfaz relativamente modular y preparada para crecer, especialmente si la lógica de datos sigue concentrándose en servicios y la complejidad visual se reparte entre widgets específicos.