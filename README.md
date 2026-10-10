# IceTrack · Aplicación móvil (Técnico) — Frontend

Frontend en Flutter de la app móvil de IceTrack para técnicos de mantenimiento.
Usa **datos simulados** (`lib/shared/data/mock_data.dart`) mientras se integra la API RESTful (TS-06).

## Pantallas
| Mockup | Archivo |
|---|---|
| 01 Iniciar sesión | `lib/iam/presentation/sign_in_page.dart` |
| 02 Crear cuenta | `lib/iam/presentation/sign_up_page.dart` |
| 03 Mis órdenes | `lib/service_requests/presentation/orders_page.dart` |
| 04–05 Detalle, aceptación y llegada | `lib/service_requests/presentation/order_detail_page.dart` |
| 06 Equipo y telemetría | `lib/monitoring/presentation/equipment_page.dart` |
| 07 Registrar intervención (offline) | `lib/service_requests/presentation/intervention_page.dart` |
| 08 Alerta push (simulada) | Perfil → "Simular alerta push" |
| 09 Notificaciones | `lib/notifications/presentation/notifications_page.dart` |
| 10 Perfil, idioma y sincronización | `lib/profiles/presentation/profile_page.dart` |
| 11 Sesión vencida (simulada) | Perfil → "Simular sesión vencida" |
| 12 Alertas activas | `lib/monitoring/presentation/alerts_page.dart` |

## Ejecutar
```
flutter pub get
flutter run
```
Requiere Flutter 3.22 o superior.
