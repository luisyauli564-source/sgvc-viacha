-- =====================================================================
-- Script 03: consultas SELECT que responden preguntas reales del SGVC
-- =====================================================================
SET search_path TO sgvc;

-- Vista base para el motor de alertas (reutilizable desde el backend)
CREATE OR REPLACE VIEW vw_contratos_vigilancia AS
SELECT c.id_contrato, c.codigo, c.objeto, c.monto, c.fecha_fin,
       (c.fecha_fin - CURRENT_DATE) AS dias_restantes,
       p.razon_social AS proveedor,
       u.nombre       AS unidad,
       e.nombre       AS estado
FROM contrato c
JOIN proveedor p              ON p.id_proveedor = c.id_proveedor
JOIN unidad_organizacional u  ON u.id_unidad    = c.id_unidad
JOIN estado_contrato e        ON e.id_estado_contrato = c.id_estado_contrato;

-- Q1. ¿Que contratos vencen en los proximos 45 dias y a quien hay que avisar?
SELECT c.codigo, pr.razon_social AS proveedor,
       c.fecha_fin, (c.fecha_fin - CURRENT_DATE) AS dias_restantes,
       us.username AS responsable, us.email
FROM contrato c
JOIN proveedor pr ON pr.id_proveedor = c.id_proveedor
JOIN usuario  us  ON us.id_usuario   = c.id_responsable
WHERE c.fecha_fin BETWEEN CURRENT_DATE AND CURRENT_DATE + 45
ORDER BY c.fecha_fin;

-- Q2. ¿Cuantos contratos y que monto total hay en cada estado del ciclo de vida?
SELECT e.nombre AS estado, COUNT(c.id_contrato) AS cantidad,
       COALESCE(SUM(c.monto), 0) AS monto_total
FROM estado_contrato e
LEFT JOIN contrato c ON c.id_estado_contrato = e.id_estado_contrato
GROUP BY e.id_estado_contrato, e.nombre
ORDER BY e.id_estado_contrato;

-- Q3. ¿Que contratos vencidos o por vencer (<= 60 dias) NO tienen ninguna alerta enviada?
SELECT c.codigo, c.objeto, c.fecha_fin, e.nombre AS estado
FROM contrato c
JOIN estado_contrato e ON e.id_estado_contrato = c.id_estado_contrato
WHERE c.fecha_fin <= CURRENT_DATE + 60
  AND e.nombre NOT IN ('RENOVADO', 'BORRADOR')
  AND NOT EXISTS (SELECT 1 FROM alerta a
                  WHERE a.id_contrato = c.id_contrato
                    AND a.estado IN ('ENVIADA', 'LEIDA'))
ORDER BY c.fecha_fin;

-- Q4. ¿Que unidades concentran mas monto contratado? (solo contratos vigentes, > Bs 50.000)
SELECT u.nombre AS unidad, COUNT(*) AS contratos, SUM(c.monto) AS monto_total
FROM contrato c
JOIN unidad_organizacional u ON u.id_unidad = c.id_unidad
JOIN estado_contrato e       ON e.id_estado_contrato = c.id_estado_contrato
WHERE e.nombre IN ('ACTIVO', 'PROXIMO_A_VENCER')
GROUP BY u.nombre
HAVING SUM(c.monto) > 50000
ORDER BY monto_total DESC;

-- Q5. ¿Que sesiones siguen vigentes ahora? (equivale al metodo Sesion.esValida())
SELECT s.token, u.username, r.nombre AS rol, s.fecha_expiracion, s.ip_origen
FROM sesion s
JOIN usuario u ON u.id_usuario = s.id_usuario
JOIN rol r     ON r.id_rol     = u.id_rol
WHERE s.fecha_expiracion > now()
  AND u.id_estado_usuario = (SELECT id_estado_usuario FROM estado_usuario WHERE nombre = 'ACTIVO')
ORDER BY s.fecha_inicio DESC;

-- Q6. ¿Que permisos tiene cada rol? (RBAC)
SELECT r.nombre AS rol, string_agg(p.codigo, ', ' ORDER BY p.codigo) AS permisos
FROM rol r
JOIN rol_permiso rp ON rp.id_rol = r.id_rol
JOIN permiso p      ON p.id_permiso = rp.id_permiso
GROUP BY r.nombre
ORDER BY r.nombre;
