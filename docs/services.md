# Servicios principales

## Visión general

La lógica de acceso a datos y parte de la lógica de negocio del frontend se concentra en `lib/core/services/`. Estos servicios encapsulan la interacción con Firebase Authentication, Firestore, Firebase Storage y el backend de Sixin, reduciendo el acoplamiento entre la interfaz y la capa de datos.

```text
lib/core/services/
├── auth_service.dart
├── list_service.dart
├── profile_service.dart
├── services.dart
└── settings_service.dart
```

## Objetivo de esta capa

Los servicios de Sixin se utilizan para:

- centralizar el acceso a servicios externos
- evitar que la lógica de datos quede repartida por las pantallas
- facilitar la reutilización de operaciones comunes
- mantener una separación clara entre interfaz, modelos y lógica de negocio

---

## `AuthService`

Servicio encargado de la autenticación de usuarios mediante Firebase Authentication.

### Responsabilidades

- obtener el usuario autenticado actual
- escuchar cambios en el estado de autenticación
- registrar usuarios con email y contraseña
- iniciar sesión con email y contraseña
- enviar emails de recuperación de contraseña
- cerrar sesión

### Dependencias

- `FirebaseAuth`

### Métodos principales

- **`currentUser`**  
  Devuelve el usuario autenticado actualmente, o `null` si no hay sesión iniciada.

- **`authStateChanges()`**  
  Devuelve un stream que notifica cambios en el estado de autenticación. Se usa habitualmente para decidir si mostrar pantallas de login o la aplicación principal.

- **`signUpWithEmail(String email, String password)`**  
  Registra un nuevo usuario con email y contraseña. El email se normaliza con `trim()` antes de enviarlo a Firebase.

- **`signInWithEmail(String email, String password)`**  
  Inicia sesión con email y contraseña. También normaliza el email antes de autenticar.

- **`sendPasswordResetEmail(String email)`**  
  Envía un email de recuperación de contraseña al usuario.

- **`signOut()`**  
  Cierra la sesión actual.

### Observaciones de diseño

- Sigue un patrón singleton mediante `AuthService.instance`.
- Es un servicio pequeño y enfocado, con responsabilidad bien definida.
- La normalización del email evita errores por espacios accidentales en formularios.

---

## `ListService`

Servicio principal de gestión de listas de partido. Es el servicio más amplio de la aplicación y concentra gran parte de la lógica funcional de Sixin.

### Responsabilidades

- consultar listas públicas y listas del usuario
- crear listas nuevas
- generar y validar códigos de acceso
- gestionar entradas directas y solicitudes de acceso
- aprobar o rechazar solicitudes
- aceptar o rechazar invitaciones
- gestionar miembros y administradores
- abandonar listas
- invitar usuarios por nombre
- solicitar al backend la eliminación completa de una lista

### Dependencias

- `FirebaseFirestore`
- `FirebaseAuth`
- `http`
- `crypto`
- `dart:convert`
- `dart:math`

### Consultas principales

- **`watchPublicLists()`**  
  Devuelve un stream con las listas cuya visibilidad es `public`, ordenadas por fecha de inicio.

- **`watchMyLists(String uid)`**  
  Devuelve un stream con las listas en las que el usuario aparece dentro de `memberUids`, también ordenadas por fecha de inicio.

### Creación de listas

- **`createList(...)`**  
  Crea una nueva lista en Firestore y registra automáticamente al creador como administrador y miembro.

Además:
- guarda datos básicos como lugar, fecha, precio, niveles y sistemas
- registra al creador en `admins`
- registra al creador en `memberUids`
- crea un documento en `members/{uid}`
- si la lista es privada, genera un código de acceso y almacena su hash
- si la lista es privada, crea también una entrada índice en `list_codes/{hash}`

### Gestión de códigos

Internamente este servicio incluye utilidades privadas para trabajar con códigos de acceso:

- **`_generateJoinCode()`**  
  Genera códigos legibles y relativamente seguros con grupos separados por guiones.

- **`_normalizeCode(String code)`**  
  Normaliza el código eliminando espacios y forzando mayúsculas.

- **`_codeHash(String normalizedCode)`**  
  Aplica SHA-256 al código normalizado para no depender del valor en bruto durante la resolución.

### Unión y solicitudes de acceso

- **`joinList({listId, uid})`**  
  Añade directamente al usuario como miembro si la política de entrada es `open`.

- **`requestJoin({listId, uid})`**  
  Crea una solicitud pendiente en `requests/{uid}` si la política de entrada es `approval`.

- **`cancelJoinRequest({listId, uid})`**  
  Elimina una solicitud pendiente del usuario.

### Gestión de solicitudes

- **`approveRequest({listId, requesterUid})`**  
  Convierte una solicitud en membresía, creando el documento del miembro y añadiendo el UID al array `memberUids`.

- **`rejectRequest({listId, requesterUid})`**  
  Elimina la solicitud sin admitir al usuario.

### Gestión de miembros y administradores

- **`removeMember({listId, targetUid})`**  
  Elimina a un miembro de la lista. Si el usuario era administrador, también lo elimina del array `admins`. Incluye una protección importante: no permite expulsar al último administrador.

- **`makeAdmin({listId, targetUid})`**  
  Promociona a un miembro a administrador.

- **`demoteAdmin({listId, targetUid})`**  
  Revierte a un administrador al rol de miembro. También impide dejar la lista sin administradores.

- **`leaveList({listId, uid, wasAdmin})`**  
  Permite que un usuario abandone una lista. Si era el último administrador, se bloquea la salida hasta que otro admin sea designado.

### Invitaciones

- **`inviteByUsername({listId, usernameInput})`**  
  Resuelve el `uid` del usuario destinatario a partir del username, comprueba que el emisor sea administrador y crea una invitación pendiente en el buzón del destinatario.

Este flujo depende de:
- la colección `usernames/` para resolver usernames a `uid`
- la colección `users/{uid}/invites/` para almacenar la invitación

- **`acceptInvite({listId, uid})`**  
  Convierte una invitación en membresía y elimina la invitación del buzón.

- **`rejectInvite({listId, uid})`**  
  Elimina la invitación sin incorporar al usuario a la lista.

### Vista previa por código

- **`previewListByCode({rawCode})`**  
  Resuelve el `listId` a partir de un código introducido por el usuario.

Para ello:
- normaliza el código
- calcula su hash
- busca el documento correspondiente en `list_codes`
- crea un documento de acceso previo en `preview_access/{uid}` si todavía no existe

### Eliminación mediante backend

- **`deleteGroupViaBackend({listId})`**  
  Envía una petición HTTP `DELETE` al backend de Sixin para eliminar una lista.

Características importantes:
- requiere sesión activa
- obtiene un ID token del usuario autenticado
- lo envía como `Bearer token`
- interpreta la respuesta HTTP y lanza una excepción si falla

### Observaciones de diseño

- Sigue patrón singleton con `ListService.instance`.
- Utiliza transacciones de Firestore en operaciones críticas para mantener consistencia.
- Protege reglas de negocio importantes, como no dejar una lista sin administradores.
- Combina operaciones cliente-Firebase con llamadas al backend cuando la lógica requiere un proceso de servidor.
- Actualmente contiene mucha responsabilidad funcional, por lo que en el futuro podría dividirse en varios servicios más específicos.

---

## `ProfileService`

Servicio encargado de la lectura y actualización de información de perfil de usuario.

### Responsabilidades

- observar el documento de un usuario
- actualizar las posiciones habituales del jugador
- subir una foto de perfil
- actualizar el username garantizando unicidad

### Dependencias

- `FirebaseFirestore`
- `FirebaseStorage`
- `image_picker`
- `dart:io`

### Métodos principales

- **`watchUserDoc(String uid)`**  
  Devuelve un stream con el documento del usuario.

- **`updatePositions({uid, positions})`**  
  Limpia, deduplica y ordena la lista de posiciones antes de guardarla en Firestore.

Este método:
- elimina espacios sobrantes
- descarta valores vacíos
- elimina duplicados
- ordena el resultado antes de persistirlo

- **`uploadProfilePhoto({uid, file})`**  
  Sube una imagen a Firebase Storage y actualiza `photoUrl` en el documento del usuario.

Aspectos relevantes:
- utiliza siempre la misma ruta: `profile_photos/{uid}/avatar.jpg`
- sobrescribe la imagen anterior
- genera una URL con cache-buster para forzar refresco en cliente

- **`updateUsername({uid, newUsername})`**  
  Actualiza el username validando formato y asegurando unicidad mediante la colección `usernames`.

Reglas aplicadas:
- longitud entre 3 y 20 caracteres
- solo letras, números y `_`
- reserva el nuevo username si está libre
- evita duplicados entre usuarios
- elimina la reserva antigua si el cambio se completa

### Observaciones de diseño

- Sigue patrón singleton con `ProfileService.instance`.
- La estrategia `users + usernames` permite garantizar unicidad de nombre sin consultas ambiguas.
- El servicio incluye tanto actualización de datos de perfil como gestión de recursos en Storage.

---

## `SettingsService`

Servicio encargado de gestionar preferencias de interfaz del usuario.

### Responsabilidades

- observar la configuración de interfaz del usuario autenticado
- actualizar preferencias relacionadas con presentación y nomenclatura

### Dependencias

- `FirebaseFirestore`
- `FirebaseAuth`

### Métodos principales

- **`watchUi()`**  
  Observa el documento `users/{uid}/settings/ui` del usuario autenticado y devuelve su contenido como mapa. Si no hay sesión activa, devuelve un stream vacío.

- **`setPositionsLang(String lang)`**  
  Actualiza la preferencia `positionsLang` en la configuración del usuario.

### Estructura de datos utilizada

Este servicio trabaja sobre el documento:

```text
users/{uid}/settings/ui
```

Ahí se almacenan preferencias visuales o de interfaz, como el idioma o la nomenclatura usada para mostrar posiciones de voleibol.

### Observaciones de diseño

- Sigue patrón singleton con `SettingsService.instance`.
- Está preparado para crecer si en el futuro se añaden más ajustes de interfaz.
- Mantiene la configuración del usuario separada del documento principal de perfil.

---

## `services.dart`

Archivo agregador de servicios.

### Responsabilidad

Su función es centralizar exportaciones para simplificar imports en otras partes del proyecto.

En lugar de importar cada servicio por separado, otros módulos pueden importar `services.dart` como punto de acceso unificado a la capa de servicios.

---

## Decisiones de diseño destacables

La capa de servicios de Sixin refleja varias decisiones importantes:

- uso de **singletons** para acceder a servicios compartidos
- encapsulación de operaciones de Firebase fuera de la interfaz
- uso de **transacciones** para operaciones sensibles
- protección de reglas críticas del dominio, especialmente en la gestión de administradores
- separación entre autenticación, listas, perfil y ajustes
- apoyo en colecciones auxiliares como `usernames`, `list_codes` o `preview_access` para resolver restricciones del modelo de datos