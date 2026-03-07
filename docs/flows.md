# Flujos principales

## Visión general

Este documento describe los principales flujos funcionales del frontend de Sixin y cómo interactúan con la capa de servicios y el modelo de datos en Firestore.

Su objetivo es explicar, de forma práctica, qué ocurre cuando el usuario realiza acciones clave dentro de la aplicación, como registrarse, crear una lista, unirse a ella o gestionar invitaciones.

---

## Resumen de flujos cubiertos

Actualmente se documentan los siguientes flujos:

- registro de usuario
- inicio de sesión
- recuperación de contraseña
- creación de lista
- consulta de listas públicas
- consulta de mis listas
- unión directa a una lista
- solicitud de acceso a una lista
- acceso a una lista privada mediante código
- invitación directa por username
- aceptación y rechazo de invitaciones
- aprobación y rechazo de solicitudes
- promoción y degradación de administradores
- salida o expulsión de miembros
- actualización de perfil
- cambio de username
- actualización de preferencias de interfaz
- eliminación de lista mediante backend

---

## 1. Registro de usuario

### Objetivo

Permitir que un usuario cree una cuenta en la aplicación con:

- email
- contraseña
- username único
- una o varias posiciones de voleibol

### Pantalla implicada

- `screens/auth/register_screen.dart`

### Servicios implicados

- `AuthService`
- Firestore directamente desde la pantalla de registro

### Flujo

1. El usuario introduce email, contraseña, username y posiciones.
2. Se validan los campos en cliente.
3. Se crea la cuenta en Firebase Authentication mediante `AuthService.signUpWithEmail(...)`.
4. Se inicia una transacción de Firestore.
5. La transacción comprueba si `usernames/{usernameLower}` ya existe.
6. Si no existe:
   - se crea `usernames/{usernameLower}`
   - se crea `users/{uid}`
7. Si la transacción falla porque el username ya está ocupado:
   - se revierte el alta de Authentication eliminando el usuario recién creado
   - o se cierra sesión como fallback
8. Si todo va bien, el usuario queda registrado y autenticado.

### Datos creados

```text
Firebase Authentication
users/{uid}
usernames/{usernameLower}
```

### Resultado

- el usuario queda registrado
- su username queda reservado de forma única
- su perfil inicial queda creado en Firestore

---

## 2. Inicio de sesión

### Objetivo

Permitir que un usuario existente acceda a la aplicación.

### Pantallas implicadas

- `screens/auth/login_screen.dart`
- `screens/auth/auth_gate.dart`

### Servicio implicado

- `AuthService`

### Flujo

1. El usuario introduce email y contraseña.
2. La pantalla invoca `AuthService.signInWithEmail(...)`.
3. Firebase Authentication valida las credenciales.
4. `authStateChanges()` emite el nuevo estado.
5. `auth_gate.dart` detecta que hay sesión iniciada.
6. La app redirige a la parte autenticada.

### Resultado

- el usuario accede a la app
- la interfaz cambia según el estado de autenticación

---

## 3. Recuperación de contraseña

### Objetivo

Permitir que un usuario solicite el restablecimiento de su contraseña.

### Pantallas implicadas

- `forgot_password_screen.dart`
- `reset_password_screen.dart`

### Servicio implicado

- `AuthService`

### Flujo

1. El usuario introduce su email.
2. Se llama a `sendPasswordResetEmail(email)`.
3. Firebase envía el correo de recuperación.
4. El usuario continúa el proceso desde el enlace recibido.

### Resultado

- se inicia el flujo de recuperación de contraseña a través de Firebase

---

## 4. Consulta de listas públicas

### Objetivo

Mostrar listas públicas disponibles para los usuarios.

### Servicio implicado

- `ListService.watchPublicLists()`

### Consulta

```text
lists
where visibility == "public"
orderBy startAt
```

### Flujo

1. La pantalla correspondiente se suscribe al stream de listas públicas.
2. Firestore devuelve las listas públicas ordenadas por fecha.
3. La UI se actualiza automáticamente ante cambios.

### Resultado

- el usuario puede explorar partidos públicos disponibles

---

## 5. Consulta de mis listas

### Objetivo

Mostrar las listas en las que participa el usuario.

### Servicio implicado

- `ListService.watchMyLists(uid)`

### Consulta

```text
lists
where memberUids arrayContains uid
orderBy startAt
```

### Flujo

1. La pantalla obtiene el `uid` actual.
2. Se suscribe al stream de `watchMyLists(uid)`.
3. Firestore devuelve las listas donde el usuario figura en `memberUids`.
4. La interfaz se mantiene sincronizada en tiempo real.

### Resultado

- el usuario ve sus listas activas o futuras

---

## 6. Creación de lista

### Objetivo

Permitir que un usuario cree una nueva lista para organizar un partido.

### Pantalla implicada

- `screens/list/create/create_list_screen.dart`

### Servicio implicado

- `ListService.createList(...)`

### Flujo

1. El usuario rellena el formulario:
   - lugar
   - fecha
   - precio
   - niveles
   - sistemas
   - visibilidad
   - política de acceso
   - descripción opcional
2. La pantalla llama a `createList(...)`.
3. El servicio genera un `docId` para la lista.
4. Se prepara un batch write.
5. Se crea `lists/{listId}` con sus campos principales.
6. Se crea `lists/{listId}/members/{uid}` con rol `admin`.
7. El creador se añade a:
   - `admins`
   - `memberUids`
8. Si la lista es privada:
   - se genera `joinCode`
   - se calcula `joinCodeHash`
   - se crea `list_codes/{joinCodeHash}`
9. Se ejecuta el batch.
10. El servicio devuelve el código de acceso si la lista era privada.

### Datos creados

```text
lists/{listId}
lists/{listId}/members/{creatorUid}
list_codes/{joinCodeHash}   (solo si la lista es privada)
```

### Resultado

- la lista queda disponible en el sistema
- el creador pasa a ser administrador y miembro
- las listas privadas tienen un código asociado

---

## 7. Unión directa a una lista

### Objetivo

Permitir que un usuario entre directamente en una lista con acceso abierto.

### Servicio implicado

- `ListService.joinList(...)`

### Condición

La lista debe tener:

```text
joinPolicy == "open"
```

### Flujo

1. El usuario pulsa la acción para unirse.
2. El servicio inicia una transacción.
3. Se comprueba que la lista existe.
4. Se comprueba que `joinPolicy` sea `open`.
5. Se comprueba que el usuario aún no sea miembro.
6. Se consulta `users/{uid}` para obtener el username.
7. Se crea `lists/{listId}/members/{uid}` con rol `member`.
8. Se añade el `uid` a `memberUids`.

### Resultado

- el usuario entra directamente como miembro

---

## 8. Solicitud de acceso a una lista

### Objetivo

Permitir que un usuario solicite acceso a una lista que requiere aprobación.

### Servicio implicado

- `ListService.requestJoin(...)`

### Condición

La lista debe tener:

```text
joinPolicy == "approval"
```

### Flujo

1. El usuario pulsa la acción de solicitar acceso.
2. El servicio inicia una transacción.
3. Se comprueba que la lista exista.
4. Se comprueba que `joinPolicy` sea `approval`.
5. Se verifica que el usuario no sea ya miembro.
6. Se comprueba que no exista ya una solicitud previa.
7. Se obtiene el username del usuario.
8. Se crea `lists/{listId}/requests/{uid}` con estado `pending`.

### Resultado

- la solicitud queda pendiente de revisión por un administrador

---

## 9. Cancelación de solicitud

### Objetivo

Permitir que el propio usuario retire su solicitud pendiente.

### Servicio implicado

- `ListService.cancelJoinRequest(...)`

### Flujo

1. El usuario elige cancelar su solicitud.
2. Se elimina `lists/{listId}/requests/{uid}`.

### Resultado

- la solicitud deja de existir

---

## 10. Aprobación de solicitud

### Objetivo

Permitir que un administrador admita a un usuario que solicitó acceso.

### Servicio implicado

- `ListService.approveRequest(...)`

### Flujo

1. Un administrador revisa solicitudes pendientes.
2. Selecciona aprobar una solicitud.
3. El servicio inicia una transacción.
4. Se comprueba que la lista exista.
5. Se comprueba que la solicitud siga existiendo.
6. Si el usuario aún no es miembro:
   - se obtiene su username
   - se crea `members/{requesterUid}`
   - se añade el `uid` a `memberUids`
7. Se elimina `requests/{requesterUid}`.

### Resultado

- el solicitante pasa a ser miembro
- la solicitud desaparece

---

## 11. Rechazo de solicitud

### Objetivo

Permitir que un administrador rechace una solicitud.

### Servicio implicado

- `ListService.rejectRequest(...)`

### Flujo

1. El administrador elige rechazar la solicitud.
2. Se elimina `lists/{listId}/requests/{uid}`.

### Resultado

- la solicitud desaparece
- el usuario no entra en la lista

---

## 12. Acceso a lista privada mediante código

### Objetivo

Permitir que un usuario valide un código de acceso privado y pueda previsualizar la lista.

### Servicio implicado

- `ListService.previewListByCode(...)`

### Flujo

1. El usuario introduce un código.
2. El servicio normaliza el valor.
3. Se calcula el hash del código.
4. Se busca `list_codes/{hash}`.
5. Si existe, se obtiene el `listId`.
6. Se crea `lists/{listId}/preview_access/{uid}` si todavía no existe.
7. El servicio devuelve el `listId`.

### Resultado

- el usuario obtiene contexto válido para ver la lista privada
- todavía no entra como miembro
- su acceso queda respaldado por `preview_access`

---

## 13. Invitación directa por username

### Objetivo

Permitir que un administrador invite directamente a otro usuario por su nombre de usuario.

### Servicio implicado

- `ListService.inviteByUsername(...)`

### Flujo

1. Un admin introduce el username del destinatario.
2. El servicio normaliza el valor.
3. Busca `usernames/{usernameLower}` para resolver el `uid`.
4. Comprueba que:
   - el username exista
   - no sea el propio admin
5. Carga `lists/{listId}`.
6. Comprueba que el emisor sea administrador.
7. Comprueba que el destinatario no sea ya miembro.
8. Lee el username del emisor desde `users/{fromUid}`.
9. Crea o actualiza `users/{toUid}/invites/{listId}` con estado `pending`.

### Resultado

- el usuario receptor ve la invitación en su buzón

---

## 14. Aceptación de invitación

### Objetivo

Permitir que un usuario entre en una lista a partir de una invitación directa.

### Servicio implicado

- `ListService.acceptInvite(...)`

### Flujo

1. El usuario abre su buzón.
2. Selecciona aceptar una invitación.
3. El servicio inicia una transacción.
4. Se comprueba que la invitación siga existiendo.
5. Se comprueba que la lista exista.
6. Si el usuario aún no es miembro:
   - se obtiene su username
   - se crea `members/{uid}`
   - se añade el `uid` a `memberUids`
7. Se elimina `users/{uid}/invites/{listId}`.

### Resultado

- el usuario entra como miembro
- la invitación desaparece del buzón

---

## 15. Rechazo de invitación

### Objetivo

Permitir que un usuario rechace una invitación recibida.

### Servicio implicado

- `ListService.rejectInvite(...)`

### Flujo

1. El usuario elige rechazar la invitación.
2. Se elimina `users/{uid}/invites/{listId}`.

### Resultado

- la invitación desaparece
- el usuario no entra en la lista

---

## 16. Promoción a administrador

### Objetivo

Permitir que un administrador otorgue permisos de admin a otro miembro.

### Servicio implicado

- `ListService.makeAdmin(...)`

### Flujo

1. Un administrador selecciona a un miembro.
2. Se inicia una transacción.
3. Se comprueba que la lista exista.
4. Se comprueba que el usuario objetivo sea miembro.
5. Se actualiza `members/{targetUid}.role` a `admin`.
6. Se añade `targetUid` al array `admins`.

### Resultado

- el miembro pasa a ser administrador

---

## 17. Degradación de administrador

### Objetivo

Permitir que un administrador deje de ser admin y vuelva a rol normal.

### Servicio implicado

- `ListService.demoteAdmin(...)`

### Flujo

1. Se inicia una transacción.
2. Se comprueba que la lista exista.
3. Se obtiene el array `admins`.
4. Si el usuario no está en `admins`, no se hace nada.
5. Si sería el último admin, se lanza error.
6. Se comprueba que siga siendo miembro.
7. Se actualiza `members/{uid}.role` a `member`.
8. Se elimina `uid` del array `admins`.

### Resultado

- el usuario deja de ser admin
- la lista conserva al menos un administrador

---

## 18. Expulsión de miembro

### Objetivo

Permitir que un administrador elimine a otro usuario de la lista.

### Servicio implicado

- `ListService.removeMember(...)`

### Flujo

1. Se inicia una transacción.
2. Se comprueba que la lista exista.
3. Se obtiene el array `admins`.
4. Si el objetivo es admin y sería el último admin, se bloquea la acción.
5. Si existe `members/{targetUid}`, se elimina.
6. Si existe `requests/{targetUid}`, se elimina también.
7. Se elimina el usuario de `memberUids`.
8. Si era admin, también se elimina de `admins`.

### Resultado

- el usuario deja de pertenecer a la lista
- la lista conserva coherencia de roles

---

## 19. Salida voluntaria de una lista

### Objetivo

Permitir que un usuario abandone una lista.

### Servicio implicado

- `ListService.leaveList(...)`

### Flujo

1. El usuario decide salir de la lista.
2. Se inicia una transacción.
3. Se comprueba que la lista exista.
4. Si era admin:
   - se comprueba si sigue en `admins`
   - si es el último admin, se bloquea la salida
5. Si existe `members/{uid}`, se elimina.
6. Se elimina el `uid` de `memberUids`.
7. Si era admin, también se elimina de `admins`.

### Resultado

- el usuario abandona la lista
- no se permite dejar la lista sin administradores

---

## 20. Actualización de posición preferida dentro de una lista

### Objetivo

Permitir que un miembro indique qué posición prefiere jugar en una lista concreta.

### Modelo afectado

- `lists/{listId}/members/{uid}`

### Flujo

1. El usuario modifica su posición preferida.
2. Se actualiza el campo `preferredPosition` de su documento de miembro.
3. Las reglas permiten esta actualización solo al propio usuario, y solo sobre ese campo.

### Resultado

- la preferencia queda visible dentro del contexto de esa lista

---

## 21. Consulta de perfil de usuario

### Objetivo

Permitir visualizar el perfil propio o el de otro usuario.

### Servicio implicado

- `ProfileService.watchUserDoc(uid)`

### Flujo

1. La pantalla solicita el documento del usuario.
2. Se abre un stream sobre `users/{uid}`.
3. La UI muestra username, posiciones y otros datos disponibles.
4. La vista se actualiza automáticamente si cambia el documento.

### Resultado

- el perfil se refleja en tiempo real

---

## 22. Actualización de posiciones del perfil

### Objetivo

Permitir que un usuario actualice las posiciones que suele jugar.

### Servicio implicado

- `ProfileService.updatePositions(...)`

### Flujo

1. El usuario selecciona posiciones.
2. El servicio limpia la lista:
   - hace `trim`
   - elimina vacíos
   - elimina duplicados
   - ordena
3. Se actualiza `users/{uid}` con:
   - `positions`
   - `updatedAt`

### Resultado

- el perfil refleja las posiciones habituales del usuario

---

## 23. Subida de foto de perfil

### Objetivo

Permitir que el usuario cambie su avatar.

### Servicio implicado

- `ProfileService.uploadProfilePhoto(...)`

### Flujo

1. El usuario selecciona una imagen.
2. El archivo se sube a:
   ```text
   profile_photos/{uid}/avatar.jpg
   ```
3. La imagen sobrescribe la anterior.
4. Se obtiene la URL pública.
5. Se añade un parámetro de cache-busting.
6. Se actualiza `users/{uid}` con:
   - `photoUrl`
   - `updatedAt`

### Resultado

- la nueva imagen queda disponible
- el cliente tiene más facilidad para refrescar la caché

---

## 24. Cambio de username

### Objetivo

Permitir que un usuario cambie su nombre visible manteniendo unicidad global.

### Servicio implicado

- `ProfileService.updateUsername(...)`

### Flujo

1. El usuario introduce un nuevo username.
2. El servicio valida formato:
   - 3 a 20 caracteres
   - letras, números o `_`
3. Se transforma a minúsculas para comparación.
4. Se inicia una transacción.
5. Se lee `users/{uid}` para obtener el username anterior.
6. Si no hay cambio real, se termina.
7. Se comprueba `usernames/{newLower}`.
8. Si el nuevo username pertenece a otro usuario, se lanza error.
9. Si está libre:
   - se crea `usernames/{newLower}`
10. Se actualiza `users/{uid}` con:
   - `username`
   - `usernameLower`
   - `updatedAt`
11. Se elimina `usernames/{oldLower}` si existía.

### Resultado

- el username cambia manteniendo unicidad y consistencia

---

## 25. Actualización de preferencias de interfaz

### Objetivo

Permitir que el usuario configure aspectos visuales o de nomenclatura.

### Servicio implicado

- `SettingsService`

### Flujos observados

#### Ver configuración actual
1. Se llama a `watchUi()`.
2. Si hay sesión, se observa:
   ```text
   users/{uid}/settings/ui
   ```
3. Si no hay sesión, se devuelve un stream vacío.

#### Cambiar nomenclatura de posiciones
1. El usuario selecciona un idioma o nomenclatura.
2. Se llama a `setPositionsLang(lang)`.
3. Se hace merge sobre `users/{uid}/settings/ui`.

### Resultado

- la preferencia del usuario queda persistida en Firestore

---

## 26. Eliminación de lista mediante backend

### Objetivo

Eliminar una lista delegando la operación en el backend.

### Servicio implicado

- `ListService.deleteGroupViaBackend(...)`

### Motivo

La eliminación completa de una lista puede requerir una operación de servidor más segura o más compleja que un simple `delete` del documento principal.

### Flujo

1. El usuario debe tener sesión iniciada.
2. El servicio obtiene el ID token del usuario autenticado.
3. Se construye una petición HTTP `DELETE` a:
   ```text
   /api/lists/{listId}
   ```
4. Se envía el token como cabecera `Authorization: Bearer ...`.
5. El backend valida la petición y ejecuta la lógica de borrado.
6. Si la respuesta no es satisfactoria, el servicio lanza una excepción.

### Resultado

- la eliminación queda delegada al backend
- el frontend no necesita conocer todo el detalle del borrado interno

---

## Relación entre flujos y colecciones

De forma resumida:

| Flujo | Colecciones implicadas |
|---|---|
| Registro | `users`, `usernames` |
| Login | Firebase Authentication |
| Crear lista | `lists`, `lists/{listId}/members`, `list_codes` |
| Unirse | `lists`, `lists/{listId}/members` |
| Solicitar acceso | `lists/{listId}/requests` |
| Invitar | `usernames`, `users/{uid}/invites`, `lists` |
| Aceptar invitación | `users/{uid}/invites`, `lists/{listId}/members`, `lists` |
| Perfil | `users`, `users/{uid}/settings` |
| Foto de perfil | Firebase Storage, `users` |
| Acceso por código | `list_codes`, `lists/{listId}/preview_access` |

---

## Reglas de negocio transversales

Los flujos del sistema respetan varias reglas importantes:

- un username debe ser único
- una lista no debe quedarse sin administradores
- una invitación no equivale a membresía hasta ser aceptada
- una solicitud no equivale a membresía hasta ser aprobada
- una lista privada puede ser visible en ciertos contextos sin conceder todavía acceso completo
- el propio usuario puede ajustar su perfil y preferencias
- ciertas operaciones críticas se resuelven con transacciones o batch writes

---

## Resumen

Los flujos principales de Sixin combinan:

- interacción del usuario desde pantallas Flutter
- lógica de negocio en la capa de servicios
- persistencia y reglas de acceso en Firestore
- apoyo puntual del backend para operaciones más sensibles

Esto permite modelar con bastante fidelidad la organización real de partidos de voleibol, incluyendo acceso flexible, control de miembros y personalización de perfil.