-- =====================================================================
-- Script 02: datos de prueba (fechas relativas a CURRENT_DATE, para que
-- las consultas siempre devuelvan resultados al ejecutarlas)
-- Los password_hash son valores ficticios de demostracion.
-- =====================================================================
SET search_path TO sgvc;

INSERT INTO estado_usuario (id_estado_usuario, nombre) VALUES
 (1,'ACTIVO'), (2,'INACTIVO'), (3,'BLOQUEADO');

INSERT INTO estado_contrato (id_estado_contrato, nombre, descripcion) VALUES
 (1,'BORRADOR',         'Contrato registrado, aun no vigente'),
 (2,'ACTIVO',           'Contrato vigente'),
 (3,'PROXIMO_A_VENCER', 'Vence dentro del umbral de alerta'),
 (4,'VENCIDO',          'Fecha de fin superada sin renovacion'),
 (5,'RENOVADO',         'Reemplazado por un contrato de renovacion');

INSERT INTO permiso (codigo, descripcion) VALUES
 ('CONTRATO_VER',      'Consultar contratos'),
 ('CONTRATO_EDITAR',   'Crear y modificar contratos'),
 ('CONTRATO_ELIMINAR', 'Eliminar contratos'),
 ('ALERTA_GESTIONAR',  'Configurar y reenviar alertas'),
 ('USUARIO_ADMIN',     'Administrar usuarios y roles'),
 ('REPORTE_VER',       'Ver reportes gerenciales');

INSERT INTO rol (nombre) VALUES ('ADMINISTRADOR'), ('GERENTE'), ('OPERADOR');

INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM rol r, permiso p WHERE r.nombre = 'ADMINISTRADOR';
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM rol r JOIN permiso p
  ON p.codigo IN ('CONTRATO_VER','REPORTE_VER','ALERTA_GESTIONAR') WHERE r.nombre = 'GERENTE';
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM rol r JOIN permiso p
  ON p.codigo IN ('CONTRATO_VER','CONTRATO_EDITAR') WHERE r.nombre = 'OPERADOR';

INSERT INTO usuario (username, password_hash, email, id_rol, id_estado_usuario) VALUES
 ('admin',   'pbkdf2_sha256$demo$hash-admin',   'admin@viacha.gob.bo',   (SELECT id_rol FROM rol WHERE nombre='ADMINISTRADOR'), 1),
 ('gerente', 'pbkdf2_sha256$demo$hash-gerente', 'gerente@viacha.gob.bo', (SELECT id_rol FROM rol WHERE nombre='GERENTE'),       1),
 ('operador1','pbkdf2_sha256$demo$hash-op1',    'operador1@viacha.gob.bo',(SELECT id_rol FROM rol WHERE nombre='OPERADOR'),      1),
 ('operador2','pbkdf2_sha256$demo$hash-op2',    'operador2@viacha.gob.bo',(SELECT id_rol FROM rol WHERE nombre='OPERADOR'),      3);

INSERT INTO sesion (token, id_usuario, fecha_inicio, fecha_expiracion, ip_origen) VALUES
 ('tok-admin-001',  (SELECT id_usuario FROM usuario WHERE username='admin'),     now() - interval '10 minutes', now() + interval '50 minutes', '192.168.1.10'),
 ('tok-ger-001',    (SELECT id_usuario FROM usuario WHERE username='gerente'),   now() - interval '3 hours',    now() - interval '2 hours',    '192.168.1.22'),
 ('tok-op1-001',    (SELECT id_usuario FROM usuario WHERE username='operador1'), now() - interval '5 minutes',  now() + interval '55 minutes', '192.168.1.35');

INSERT INTO unidad_organizacional (nombre) VALUES
 ('Secretaria Municipal de Obras Publicas'),
 ('Secretaria Municipal Administrativa y Financiera'),
 ('Secretaria Municipal de Desarrollo Humano');

INSERT INTO proveedor (razon_social, nit, email, telefono) VALUES
 ('Constructora Altiplano S.R.L.',  '1020304050', 'contacto@altiplano.bo', '2-2810001'),
 ('Servicios Tecnologicos Andinos', '2030405060', 'ventas@andinos.bo',     '2-2810002'),
 ('Limpieza Integral El Alto',      '3040506070', 'info@limpieza.bo',      '2-2810003'),
 ('Suministros de Oficina Viacha',  '4050607080', 'pedidos@sumviacha.bo',  '2-2810004');

-- Contratos: fecha_fin relativa a hoy (vencidos, por vencer y vigentes)
INSERT INTO contrato (codigo, objeto, monto, fecha_inicio, fecha_fin,
                      id_proveedor, id_unidad, id_estado_contrato, id_responsable) VALUES
 ('CT-2025-001','Mantenimiento de vias urbanas',            250000.00, CURRENT_DATE - 330, CURRENT_DATE - 5,
   1, 1, 4, (SELECT id_usuario FROM usuario WHERE username='operador1')),
 ('CT-2025-002','Servicio de hosting y soporte del portal',  48000.00, CURRENT_DATE - 340, CURRENT_DATE + 12,
   2, 2, 3, (SELECT id_usuario FROM usuario WHERE username='operador1')),
 ('CT-2025-003','Limpieza de oficinas municipales',          36000.00, CURRENT_DATE - 300, CURRENT_DATE + 28,
   3, 2, 3, (SELECT id_usuario FROM usuario WHERE username='operador1')),
 ('CT-2026-004','Provision de material de escritorio',       15000.00, CURRENT_DATE - 100, CURRENT_DATE + 150,
   4, 2, 2, (SELECT id_usuario FROM usuario WHERE username='operador1')),
 ('CT-2026-005','Construccion de cancha polifuncional',     520000.00, CURRENT_DATE - 60,  CURRENT_DATE + 240,
   1, 1, 2, (SELECT id_usuario FROM usuario WHERE username='admin')),
 ('CT-2024-006','Licencias de software ofimatico',           22000.00, CURRENT_DATE - 700, CURRENT_DATE - 335,
   2, 2, 5, (SELECT id_usuario FROM usuario WHERE username='admin')),
 ('CT-2026-007','Renovacion de licencias de software',       24000.00, CURRENT_DATE - 330, CURRENT_DATE + 35,
   2, 2, 2, (SELECT id_usuario FROM usuario WHERE username='admin')),
 ('CT-2026-008','Campana de salud preventiva',               80000.00, CURRENT_DATE + 10,  CURRENT_DATE + 190,
   3, 3, 1, (SELECT id_usuario FROM usuario WHERE username='operador1'));

-- CT-2026-007 es la renovacion de CT-2024-006
UPDATE contrato SET id_contrato_origen = (SELECT id_contrato FROM contrato WHERE codigo='CT-2024-006')
 WHERE codigo = 'CT-2026-007';

INSERT INTO documento_contrato (id_contrato, nombre_archivo, ruta, id_usuario)
SELECT id_contrato, codigo || '.pdf', '/archivos/contratos/' || codigo || '.pdf',
       (SELECT id_usuario FROM usuario WHERE username='operador1')
FROM contrato WHERE codigo IN ('CT-2025-002','CT-2025-003','CT-2026-005');

INSERT INTO alerta (id_contrato, id_usuario, dias_anticipacion, fecha_programada, canal, estado, fecha_envio) VALUES
 ((SELECT id_contrato FROM contrato WHERE codigo='CT-2025-001'), (SELECT id_usuario FROM usuario WHERE username='gerente'),   30, CURRENT_DATE - 35, 'CORREO',  'ENVIADA', now() - interval '35 days'),
 ((SELECT id_contrato FROM contrato WHERE codigo='CT-2025-002'), (SELECT id_usuario FROM usuario WHERE username='gerente'),   30, CURRENT_DATE - 18, 'CHATBOT', 'ENVIADA', now() - interval '18 days'),
 ((SELECT id_contrato FROM contrato WHERE codigo='CT-2025-002'), (SELECT id_usuario FROM usuario WHERE username='operador1'), 15, CURRENT_DATE - 3,  'CORREO',  'PENDIENTE', NULL),
 ((SELECT id_contrato FROM contrato WHERE codigo='CT-2025-003'), (SELECT id_usuario FROM usuario WHERE username='gerente'),   30, CURRENT_DATE - 2,  'CORREO',  'LEIDA',   now() - interval '2 days');
