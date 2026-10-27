# Matriz de trazabilidad

Relaciona cada historia de usuario con las pruebas que verifican sus criterios de aceptación. Lo que depende de la vista o de un teléfono real se revisa en la certificación manual (certificacion.md).

Las rutas son relativas a la carpeta `test/`: `integracion/` son las del servidor, `sistema/` las de la app completa en un emulador, `caos/` las de resiliencia y `unitarias/` y `widgets/` las de la app.

| HU | Historia | Pruebas automáticas | Certificación |
|---|---|---|---|
| HU-01 | Onboarding y bienvenida | | Flujo principal |
| HU-02 | Registro de cuenta | `unitarias/caracteristicas/autenticacion/dominio/validaciones_registro_test`, `unitarias/caracteristicas/autenticacion/datos/servicio_alta_cuenta_test`, `integracion/auth.test.js`, `sistema/flujo_principal_test` | Flujo principal |
| HU-03 | Inicio de sesión y persistencia | `integracion/auth.test.js` (login, recuperación de contraseña) | Flujo principal |
| HU-04 | Encriptación de datos sensibles | `unitarias/nucleo/cifrado/servicio_cifrado_test`, `integracion/datos.test.js` (campos en claro), `sistema/flujo_principal_test` | |
| HU-05 | Perfil del cuidador | `integracion/auth.test.js` (cambio y verificación de correo), `integracion/correos.test.js` | Evaluación completa |
| HU-06 | Gestión de pacientes (CRUD) | `unitarias/caracteristicas/pacientes/dominio/ciclo_de_vida_paciente_test`, `unitarias/caracteristicas/pacientes/presentacion/proveedores_pacientes_test`, `integracion/datos.test.js` (archivados y borrado en cascada) | Flujo principal |
| HU-07 | Lista y selección de pacientes | `unitarias/caracteristicas/pacientes/presentacion/proveedores_pacientes_test` | Flujo principal |
| HU-08 | Panel principal | `widgets/caracteristicas/panel_principal/presentacion/pantalla_panel_principal_test` | Flujo principal |
| HU-09 | Formulario de registro clínico | `unitarias/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas_test`, `unitarias/caracteristicas/registro_clinico/dominio/registro_clinico_test`, `unitarias/caracteristicas/registro_clinico/dominio/rangos_signos_test`, `unitarias/caracteristicas/registro_clinico/dominio/conteo_registros_test`, `sistema/flujo_principal_test` | Flujo principal |
| HU-10 | Historial de registros | `unitarias/caracteristicas/historial/dominio/filtro_historial_test`, `integracion/datos.test.js` (paginación y rango de fechas) | Evaluación completa |
| HU-11 | Edición y eliminación de registros | `widgets/caracteristicas/historial/presentacion/widgets/cabecera_tarjeta_registro_test` | Evaluación completa |
| HU-12 | Registro clínico PDF | `unitarias/caracteristicas/historial/datos/exportadores_test` | Evaluación completa |
| HU-13 | Registro clínico Excel | `unitarias/caracteristicas/historial/datos/exportadores_test`, `widgets/caracteristicas/historial/presentacion/pantalla_vista_excel_test` | Evaluación completa |
| HU-14 | Asistente de orientación (chat) | `unitarias/caracteristicas/chat/dominio/respuestas_chat_test`, `widgets/caracteristicas/chat/presentacion/widgets/burbujas_chat_test` | Evaluación completa |
| HU-15 | Carpetas de conversaciones | `unitarias/caracteristicas/chat/dominio/conversacion_test`, `integracion/datos.test.js` (conversaciones) | Evaluación completa |
| HU-16 | Preguntas frecuentes | `widgets/caracteristicas/preguntas_frecuentes/presentacion/pantalla_preguntas_frecuentes_test` | Biblioteca y navegación |
| HU-17 | Creación de recordatorios | `unitarias/caracteristicas/recordatorios/dominio/recordatorio_test`, `unitarias/nucleo/notificaciones/calendario_avisos_test`, `integracion/datos.test.js` (recordatorios) | Evaluación completa |
| HU-18 | Notificaciones locales | `unitarias/nucleo/notificaciones/calendario_avisos_test`, `unitarias/nucleo/notificaciones/silencio_avisos_test` | Evaluación completa |
| HU-19 | Biblioteca educativa | `unitarias/caracteristicas/biblioteca/dominio/*`, `widgets/caracteristicas/biblioteca/presentacion/widgets/tarjeta_material_test`, `integracion/datos.test.js` (biblioteca y favoritos) | Biblioteca y navegación |
| HU-20 | Contenido inicial y carga automática | `unitarias/caracteristicas/biblioteca/datos/descarga_completa_test`, `unitarias/caracteristicas/biblioteca/datos/servicio_cache_contenido_test`, `unitarias/caracteristicas/biblioteca/dominio/progreso_descarga_test`, `widgets/caracteristicas/biblioteca/presentacion/widgets/tarjeta_descarga_contenido_test` | Biblioteca y navegación |
| HU-21 | Reproductor de video | `widgets/caracteristicas/biblioteca/presentacion/pantalla_video_test`, `unitarias/caracteristicas/biblioteca/presentacion/avance_video_test` | Biblioteca y navegación |
| HU-22 | Guías e infografías | `widgets/caracteristicas/biblioteca/presentacion/pantalla_visor_pdf_test`, `widgets/compartido/widgets/visor_con_zoom_test`, `unitarias/compartido/widgets/controles_zoom_test` | Biblioteca y navegación |
| HU-23 | Ajustes de la app | `unitarias/caracteristicas/configuracion/dominio/escala_texto_test`, `unitarias/caracteristicas/configuracion/dominio/modo_tema_test`, `unitarias/app/tema/*`, `widgets/app/tema/*` | Evaluación completa |
| HU-24 | Datos transversales | `integracion/datos.test.js` (pacienteId inconsistente, mismo id en otro usuario) | |
| HU-25 | Aislamiento de datos por usuario | `integracion/datos.test.js` (aislamiento y campos en claro), `integracion/auth.test.js` (rutas protegidas) | |
| HU-26 | Navegación y enlaces directos | `widgets/app/navegacion_principal_test`, `widgets/app/enrutador/fundido_ramas_test` | Biblioteca y navegación |
| HU-27 | Soporte y sincronización sin conexión | `unitarias/nucleo/sincronizacion/cola_escrituras_test`, `unitarias/nucleo/sincronizacion/orquestador_sincronizacion_test`, `unitarias/nucleo/conectividad/servicio_conectividad_test`, `widgets/compartido/widgets/aviso_sin_conexion_test` | Evaluación completa |
| HU-28 | Servidor propio con API y base de datos | Todo `integracion/` | |
| HU-29 | Despliegue y descarga del APK | | Flujo principal |
| HU-30 | Pruebas de caos | `caos/experimentos/01` a `07`, `unitarias/nucleo/sincronizacion/orquestador_sincronizacion_test` (sesión vencida) | |
