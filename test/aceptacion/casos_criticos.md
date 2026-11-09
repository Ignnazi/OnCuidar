# Casos críticos

Casos elegidos por riesgo, los que protegen lo que más daño causaría si fallara. Son los que se citan en el anexo de pruebas del informe. Cada uno lleva su identificador en el nombre de la prueba, así que la tabla del anexo y la ejecución se pueden comparar directamente.

## Cómo correrlos

```
flutter test --tags criticos
docker compose -f docker-compose.pruebas.yml up -d
cd backend && npx jest --runInBand --verbose -t "PI-"
```

## Unidad

| ID | Qué verifica | Archivo |
|---|---|---|
| PU-01 | 38 °C, el límite de la fiebre, se clasifica como crítico | `unitarias/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas_test.dart` |
| PU-02 | Saturación de 95 %, el límite, da alerta | `unitarias/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas_test.dart` |
| PU-03 | Un síntoma con intensidad 10 es crítico | `unitarias/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas_test.dart` |
| PU-04 | Un signo crítico no baja de nivel por un síntoma moderado | `unitarias/caracteristicas/registro_clinico/dominio/motor_reglas_clinicas_test.dart` |
| PU-05 | El texto cifrado no deja ver el original y se recupera con la clave | `unitarias/nucleo/cifrado/servicio_cifrado_test.dart` |
| PU-06 | Lo cifrado con la clave de un usuario no se puede descifrar con la de otro | `unitarias/nucleo/cifrado/servicio_cifrado_test.dart` |
| PU-07 | Sin red no se envía nada y al volver la red se envía solo | `unitarias/nucleo/sincronizacion/orquestador_sincronizacion_test.dart` |
| PU-08 | Dos sincronizaciones a la vez no duplican | `unitarias/nucleo/sincronizacion/orquestador_sincronizacion_test.dart` |
| PU-09 | Lo guardado sin red sigue en la cola al cerrar y abrir la app | `unitarias/nucleo/sincronizacion/cola_escrituras_test.dart` |

## Integración

| ID | Qué verifica | Archivo |
|---|---|---|
| PI-01 | Un usuario no ve ni toca datos de otro | `integracion/datos.test.js` |
| PI-02 | Se rechazan los campos clínicos enviados fuera del bloque cifrado | `integracion/datos.test.js` |
| PI-03 | Guardar dos veces no duplica | `integracion/datos.test.js` |
| PI-04 | Un paciente borrado no vuelve a crearse | `integracion/pacientes_eliminados.test.js` |
| PI-05 | El enlace para restablecer sirve una sola vez | `integracion/auth.test.js` |

## Sistema y resiliencia

Los casos de sistema (PS) y de resiliencia (PC) se describen en el anexo del informe. Los PS se hacen a mano sobre el APK siguiendo certificacion.md, y los PC son los experimentos 01 a 07 de `caos/experimentos`, en el mismo orden.
