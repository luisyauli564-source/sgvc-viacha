# Modelo relacional – SGVC (PostgreSQL)

Derivado del diagrama de clases de la Tarea 2 (Usuario, Rol, Sesion, EstadoUsuario)
y del diagrama de estados del Contrato (Borrador, Activo, Próximo a Vencer, Vencido, Renovado).

| Tabla | PK | FK |
|---|---|---|
| estado_usuario | id_estado_usuario | – |
| estado_contrato | id_estado_contrato | – |
| permiso | id_permiso | – |
| rol | id_rol | – |
| rol_permiso | (id_rol, id_permiso) | id_rol→rol, id_permiso→permiso |
| usuario | id_usuario | id_rol→rol, id_estado_usuario→estado_usuario |
| sesion | id_sesion | id_usuario→usuario |
| unidad_organizacional | id_unidad | – |
| proveedor | id_proveedor | – |
| contrato | id_contrato | id_proveedor, id_unidad, id_estado_contrato, id_responsable→usuario, id_contrato_origen→contrato |
| documento_contrato | id_documento | id_contrato, id_usuario |
| alerta | id_alerta | id_contrato, id_usuario |

Ver `diagrama-er.png`.
