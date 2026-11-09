# Certificación manual

Recorridos que se hacen a mano sobre el APK final instalado en un teléfono real, conectado al servidor desplegado. Cada paso se marca y se deja una captura como evidencia. La columna Caso indica el caso de sistema del informe al que corresponde el paso.

Fecha:
Teléfono y versión de Android:
Versión del APK:

## 1. Flujo principal

| Paso | Resultado esperado | Caso | Ok | Evidencia |
|---|---|---|---|---|
| Descargar el APK desde la página web e instalarlo | La app se instala sin errores | | | |
| Abrir la app | Aparece la pantalla de carga y luego la bienvenida | | | |
| Crear una cuenta con los datos del cuidador y del paciente | Entra al panel principal con el nombre del paciente | PS-01 | | |
| Cerrar la app y volver a abrirla | Entra directo al panel sin pedir la contraseña | | | |
| Registrar signos vitales y síntomas | Aparece "Guardado correctamente" y el nivel de alerta | | | |
| Registrar una temperatura de 38,6 °C | Se clasifica como crítico y avisa que la fiebre es una urgencia | PS-02 | | |
| Revisar en la base de datos el registro recién creado | El nombre del paciente y la temperatura aparecen solo cifrados | PS-01 | | |
| Volver al panel | Muestra los signos del último registro | | | |

## 2. Biblioteca y navegación

| Paso | Resultado esperado | Caso | Ok | Evidencia |
|---|---|---|---|---|
| Recorrer las 5 pestañas de la barra inferior | Cada una abre su sección | | | |
| Esperar la descarga del contenido | La tarjeta llega al 100% | | | |
| Filtrar por tipo y por tema y buscar por título | La lista cambia según el filtro | | | |
| Activar modo avión y abrir un video, una guía y una infografía | Todo se ve sin conexión | | | |
| Ver un video en pantalla completa | La barra inferior se oculta | | | |

## 3. Evaluación completa

| Paso | Resultado esperado | Caso | Ok | Evidencia |
|---|---|---|---|---|
| Activar modo avión y crear un registro y un recordatorio | Se guardan y aparece "Sin conexión" | PS-03 | | |
| Desactivar modo avión | Los pendientes se envían solos y desaparece el aviso | PS-03 | | |
| Editar y eliminar un registro de hoy | Los cambios se ven al instante | | | |
| Exportar el historial a PDF y a Excel | Los archivos se abren y se pueden compartir | PS-05 | | |
| Crear un recordatorio para dentro de 2 minutos y cerrar la app | Llega la notificación y al tocarla abre Recordatorios | PS-06 | | |
| Usar el chat y las preguntas frecuentes | Responde y enlaza el material relacionado | | | |
| Elegir el tamaño de texto más grande y el modo oscuro | Se aplica en toda la app, ninguna pantalla se corta y se mantiene al reabrirla | PS-08 | | |
| Cambiar el correo principal | Queda "Pendiente de confirmar" hasta abrir el enlace | | | |
| Cambiar el paciente activo y abrir el historial | Solo aparecen los registros del paciente elegido | PS-04 | | |
| Cerrar sesión y entrar con otra cuenta | No se ve ningún dato de la cuenta anterior | PS-07 | | |
