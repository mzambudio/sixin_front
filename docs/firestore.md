# Modelo de datos en Firestore

## Visión general

El frontend de Sixin utiliza Cloud Firestore como base de datos principal para almacenar usuarios, listas, membresías, solicitudes de acceso, invitaciones y ajustes de interfaz.

El modelo está diseñado para cubrir varias necesidades del dominio:

- gestión de perfiles de usuario
- unicidad de nombres de usuario
- creación y consulta de listas de partido
- control de acceso a listas públicas y privadas
- gestión de miembros y administradores
- flujo de invitaciones directas
- acceso mediante código
- configuración personalizada de la interfaz

Además del documento principal de cada lista, se emplean subcolecciones y colecciones auxiliares para mantener reglas de negocio y consultas eficientes.

---

## Colecciones principales

La estructura principal observada es la siguiente:

```text
users/{uid}
users/{uid}/settings/{docId}
users/{uid}/invites/{listId}

usernames/{usernameLower}

lists/{listId}
lists/{listId}/members/{uid}
lists/{listId}/requests/{uid}
lists/{listId}/preview_access/{uid}

list_codes/{codeHash}
```

---

## Relación entre entidades

### Usuario
Cada usuario autenticado tiene un documento en `users/{uid}` con su información pública o semipública, como username y posiciones habituales.

### Username
La colección `usernames` actúa como índice de unicidad para resolver un nombre de usuario a un `uid`.

### Lista
Cada partido o lista se representa con un documento en `lists/{listId}`.

### Miembro
La pertenencia de usuarios a una lista se modela de dos formas:

- mediante el array `memberUids` en el documento principal de la lista
- mediante documentos detallados en `lists/{listId}/members/{uid}`

### Solicitud
Cuando una lista requiere aprobación, la petición se registra en `lists/{listId}/requests/{uid}`.

### Invitación
Las invitaciones directas se almacenan en el buzón del usuario receptor, dentro de `users/{uid}/invites/{listId}`.

### Acceso por código
Las listas privadas pueden resolverse a partir de un código hash almacenado en `list_codes/{codeHash}`.  
Cuando un usuario valida un código correctamente, se registra acceso temporal o contextual en `lists/{listId}/preview_access/{uid}`.

---

## Colección `users`

Ruta:

```text
users/{uid}
```

### Propósito

Almacena la información principal del perfil de usuario.

### Campos observados

Según el flujo de registro y actualización de perfil, un documento de usuario puede contener:

- **`username`**: nombre visible del usuario
- **`usernameLower`**: versión en minúsculas para unicidad y búsquedas
- **`positions`**: array de posiciones habituales del jugador
- **`createdAt`**: fecha de creación
- **`updatedAt`**: fecha de última actualización
- **`photoUrl`**: URL de la foto de perfil

### Ejemplo orientativo

```json
{
  "username": "ManuVolley",
  "usernameLower": "manuvolley",
  "positions": ["OH", "L"],
  "photoUrl": "https://.../avatar.jpg&v=1730000000000",
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>"
}
```

### Observaciones

- Actualmente las reglas permiten `read: if true`, por lo que el perfil completo queda públicamente legible.
- En el propio archivo de reglas ya aparece la advertencia de que, si en el futuro se quiere más privacidad, convendría separar el perfil público en otra colección como `public_profiles`.

---

## Subcolección `users/{uid}/settings`

Ruta:

```text
users/{uid}/settings/{docId}
```

### Propósito

Guardar preferencias de interfaz del usuario separadas del perfil principal.

### Documento usado actualmente

```text
users/{uid}/settings/ui
```

### Campos observados

- **`positionsLang`**: preferencia para mostrar la nomenclatura de posiciones de voleibol

### Ejemplo orientativo

```json
{
  "positionsLang": "es"
}
```

### Observaciones

- Esta estructura permite ampliar ajustes de interfaz sin sobrecargar `users/{uid}`.
- El acceso a esta subcolección está restringido al propio usuario autenticado.

---

## Subcolección `users/{uid}/invites`

Ruta:

```text
users/{uid}/invites/{listId}
```

### Propósito

Actúa como buzón de invitaciones a listas.

### Identificador del documento

El `docId` coincide con el `listId`, lo que evita invitaciones duplicadas a la misma lista para el mismo usuario.

### Campos observados

- **`listId`**: identificador de la lista
- **`listPlace`**: lugar del partido
- **`startAt`**: fecha y hora del partido
- **`fromUid`**: UID del usuario que invita
- **`fromUsername`**: username del emisor
- **`toUsername`**: username del destinatario
- **`status`**: estado de la invitación, actualmente `pending`
- **`createdAt`**: fecha de creación

### Ejemplo orientativo

```json
{
  "listId": "abc123",
  "listPlace": "PTS Granada",
  "startAt": "<timestamp>",
  "fromUid": "uid_admin",
  "fromUsername": "Carlos",
  "toUsername": "ManuVolley",
  "status": "pending",
  "createdAt": "<timestamp>"
}
```

### Observaciones

- El receptor puede leer y borrar sus propias invitaciones.
- Solo un administrador de la lista puede crear una invitación.
- No se permiten updates en estas invitaciones según las reglas actuales.

---

## Colección `usernames`

Ruta:

```text
usernames/{usernameLower}
```

### Propósito

Garantizar unicidad global de usernames y permitir resolver un username a `uid`.

### Campos observados

- **`uid`**: UID propietario del username
- **`createdAt`**: fecha de reserva

### Ejemplo orientativo

```json
{
  "uid": "user_123",
  "createdAt": "<timestamp>"
}
```

### Observaciones

- El `docId` es el username en minúsculas.
- Se usa en el registro y en el cambio de username.
- Solo puede crearlo el propio usuario autenticado para sí mismo.
- No se permite update; si cambia el username, se crea uno nuevo y se borra el anterior.

---

## Colección `lists`

Ruta:

```text
lists/{listId}
```

### Propósito

Representa una lista o partido organizado dentro de Sixin.

### Campos observados

A partir de `ListService`, un documento de lista puede contener:

- **`place`**: lugar del partido
- **`startAt`**: fecha y hora del partido
- **`totalPrice`**: precio total de la pista
- **`currency`**: moneda, actualmente `EUR`
- **`systems`**: sistemas de juego
- **`levels`**: niveles de juego permitidos
- **`description`**: descripción opcional
- **`createdBy`**: UID del creador
- **`admins`**: array de UIDs de administradores
- **`ownerUsername`**: username del creador
- **`visibility`**: `public` o `private`
- **`joinPolicy`**: `open` o `approval`
- **`memberUids`**: array de miembros
- **`createdAt`**: fecha de creación
- **`updatedAt`**: fecha de actualización
- **`joinCodeHash`**: hash del código de acceso, si la lista es privada
- **`joinCode`**: código de acceso en claro, si la lista es privada

### Ejemplo orientativo

```json
{
  "place": "PTS Granada",
  "startAt": "<timestamp>",
  "totalPrice": 24,
  "currency": "EUR",
  "systems": ["4x2", "5-1"],
  "levels": ["Intermedio", "Avanzado"],
  "description": "Llevad balón si podéis",
  "createdBy": "uid_creator",
  "admins": ["uid_creator"],
  "ownerUsername": "Carlos",
  "visibility": "private",
  "joinPolicy": "approval",
  "memberUids": ["uid_creator"],
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>",
  "joinCodeHash": "abc123hash",
  "joinCode": "ABCD-EF3K-9ZQ2"
}
```

### Observaciones

- `memberUids` existe para facilitar consultas como “mis listas”.
- `admins` se mantiene separado del rol dentro de `members/{uid}` para agilizar comprobaciones de permisos.
- Si la lista es privada, actualmente se guarda también `joinCode` en claro. Eso simplifica algunos usos, pero reduce privacidad frente a guardar solo el hash.
- Las reglas permiten listar `/lists`, lo que habilita queries globales, aunque la lectura individual de listas privadas queda restringida.

---

## Subcolección `lists/{listId}/members`

Ruta:

```text
lists/{listId}/members/{uid}
```

### Propósito

Guardar información detallada de cada miembro dentro de una lista.

### Campos observados

- **`role`**: `admin` o `member`
- **`username`**: username del miembro en el momento de entrar
- **`joinedAt`**: fecha de incorporación
- **`preferredPosition`**: posición preferida del usuario dentro de esa lista

### Ejemplo orientativo

```json
{
  "role": "member",
  "username": "ManuVolley",
  "joinedAt": "<timestamp>",
  "preferredPosition": "OH"
}
```

### Observaciones

- La colección `members` almacena el detalle que no cabe bien en el array `memberUids`.
- El propio usuario puede actualizar únicamente `preferredPosition`.
- Los administradores pueden crear, borrar y actualizar miembros.
- La lectura de miembros depende de la visibilidad de la lista y del contexto de acceso.

---

## Subcolección `lists/{listId}/requests`

Ruta:

```text
lists/{listId}/requests/{uid}
```

### Propósito

Registrar solicitudes de acceso a listas que requieren aprobación.

### Campos observados

- **`requestedAt`**: fecha de solicitud
- **`status`**: estado, actualmente `pending`
- **`username`**: username del solicitante

### Ejemplo orientativo

```json
{
  "requestedAt": "<timestamp>",
  "status": "pending",
  "username": "ManuVolley"
}
```

### Observaciones

- El documento se identifica por el `uid` del solicitante.
- El propio solicitante puede ver y borrar su solicitud.
- Los administradores pueden listar todas las solicitudes.
- No se permiten updates; la solicitud se crea y luego se elimina al aprobar o rechazar.

---

## Subcolección `lists/{listId}/preview_access`

Ruta:

```text
lists/{listId}/preview_access/{uid}
```

### Propósito

Registrar que un usuario ha validado correctamente el código de acceso de una lista privada y puede previsualizarla.

### Campos observados

- **`codeHash`**: hash del código utilizado
- **`createdAt`**: fecha de creación del acceso

### Ejemplo orientativo

```json
{
  "codeHash": "abc123hash",
  "createdAt": "<timestamp>"
}
```

### Observaciones

- No se usa como membresía real.
- Sirve para autorizar la lectura de una lista privada antes de entrar en ella.
- Solo el propio usuario puede crear su documento, y solo si el `codeHash` existe en `list_codes` y apunta a esa lista.
- No se permite update ni list.

---

## Colección `list_codes`

Ruta:

```text
list_codes/{codeHash}
```

### Propósito

Resolver un código de acceso privado hacia una lista concreta.

### Campos observados

- **`listId`**: lista asociada
- **`createdBy`**: UID del creador
- **`createdAt`**: fecha de creación

### Ejemplo orientativo

```json
{
  "listId": "list_001",
  "createdBy": "uid_creator",
  "createdAt": "<timestamp>"
}
```

### Observaciones

- El `docId` es el hash del código, no el código en claro.
- Permite buscar una lista a partir de un código introducido por el usuario.
- Puede crearse incluso cuando la lista aún no existe, lo que facilita batch writes durante la creación.
- Solo un administrador de la lista puede borrar el documento.

---

## Reglas de seguridad destacables

Las reglas de Firestore reflejan varias decisiones de negocio importantes.

### Usuarios

- cualquier persona puede leer `users/{uid}`
- solo el propio usuario puede crear, actualizar o borrar su documento
- los ajustes en `settings` solo pueden ser gestionados por el propio usuario

### Usernames

- solo usuarios autenticados pueden leer usernames
- un username solo puede ser creado si no existe y pertenece al usuario autenticado
- no se permite modificar usernames existentes
- el propietario puede borrar su reserva anterior

### Listas

- cualquier usuario puede hacer queries sobre `/lists`
- una lista pública puede leerse directamente
- una lista privada solo puede leerse si el usuario:
  - es admin
  - es miembro
  - tiene invitación
  - tiene solicitud pendiente
  - tiene `preview_access`

### Miembros

- en listas públicas, la información de miembros es visible
- en listas privadas, se necesita contexto de acceso
- un usuario puede crear o borrar su propio documento de miembro
- el usuario solo puede cambiar `preferredPosition`
- el administrador puede gestionar miembros libremente

### Solicitudes

- el usuario puede crear su propia solicitud si no es ya miembro
- el usuario puede ver o borrar su propia solicitud
- el administrador puede ver todas y eliminarlas

### Invitaciones

- solo un admin puede crear invitaciones
- el receptor puede leer y borrar sus invitaciones
- no se permiten modificaciones

### Preview access

- solo el propio usuario puede crear o borrar su acceso previo
- el acceso solo puede crearse con un `codeHash` válido y vinculado a la lista correcta

---

## Reglas de negocio reflejadas en el modelo

El diseño de Firestore recoge varias decisiones clave de Sixin.

### 1. Siempre debe quedar al menos un administrador
La lógica de aplicación impide expulsar, degradar o permitir la salida del último admin.

### 2. La pertenencia se modela de dos formas
Se mantiene tanto:

- un array `memberUids` para consultas rápidas
- una subcolección `members` para detalle por miembro

Esto duplica información, pero mejora rendimiento y flexibilidad.

### 3. El acceso privado tiene varios estados
Un usuario puede tener relación con una lista privada sin ser miembro todavía:

- invitado
- solicitante
- usuario con acceso por código validado
- administrador

### 4. El username no se resuelve con queries sobre users
Se usa una colección `usernames` específica para garantizar unicidad y búsqueda directa.

### 5. Las solicitudes e invitaciones son efímeras
No se actualizan: se crean y luego se eliminan cuando dejan de tener sentido.

---

## Flujo de registro de usuario

Durante el registro se realiza este proceso:

1. se crea el usuario en Firebase Authentication
2. se reserva el username en `usernames/{usernameLower}`
3. se crea el perfil en `users/{uid}`

Todo el paso 2 y 3 se ejecuta dentro de una transacción de Firestore para mantener consistencia.

### Datos iniciales del perfil

Actualmente, en el registro se guardan:

- `username`
- `usernameLower`
- `positions`
- `createdAt`

---

## Flujo de creación de lista

Cuando un usuario crea una lista:

1. se crea `lists/{listId}`
2. se añade el creador a `admins`
3. se añade el creador a `memberUids`
4. se crea `lists/{listId}/members/{uid}` con rol `admin`
5. si la lista es privada:
   - se genera un código
   - se calcula `joinCodeHash`
   - se crea `list_codes/{codeHash}`

Este flujo se ejecuta mediante batch write.

---

## Consultas e índices

Los índices definidos reflejan las consultas principales de la app.

### Listas públicas

Consulta observada:

- `visibility == "public"`
- orden por `startAt` o `createdAt`

### Mis listas

Consulta observada:

- `memberUids arrayContains uid`
- orden por `startAt` o `createdAt`

### Índices configurados

Se han definido índices compuestos para:

- `visibility + startAt`
- `visibility + createdAt`
- `memberUids + startAt`
- `memberUids + createdAt`

Esto permite soportar de forma eficiente las vistas principales del frontend.

---

## Decisiones de diseño destacables

### Fortalezas

- modelo bastante expresivo para el dominio real de la app
- reglas de acceso bien alineadas con los flujos funcionales
- soporte claro para listas privadas con varios caminos de entrada
- estrategia robusta para unicidad de usernames
- buen uso de subcolecciones para separar responsabilidades

### Aspectos a vigilar

- `users/{uid}` es totalmente público en lectura
- `lists/{listId}` guarda `joinCode` en claro además del hash
- existe duplicación entre `memberUids`, `admins` y `members/{uid}`
- parte de la consistencia depende de la lógica cliente, no solo de reglas

---

## Posibles mejoras futuras

- mover la parte pública del perfil a una colección específica si se quiere más privacidad
- dejar de almacenar `joinCode` en claro si no es necesario mostrarlo más adelante
- documentar formalmente qué campos son obligatorios en cada documento
- añadir estados más ricos si en el futuro invitaciones y solicitudes dejan de ser efímeras
- reforzar validaciones de esquema en reglas si el modelo se estabiliza más

---

## Resumen

El modelo de Firestore de Sixin combina:

- documentos principales para usuarios y listas
- subcolecciones para miembros, solicitudes, invitaciones y acceso temporal
- colecciones auxiliares para usernames y códigos

El resultado es un diseño orientado a cubrir con claridad los flujos principales de la aplicación, especialmente la gestión flexible de acceso a listas públicas y privadas.