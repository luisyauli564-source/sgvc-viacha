-- =====================================================================
-- SGVC - Sistema de Gestion de Contratos y Control de Vencimientos
-- GAM Viacha | Hito 3 - Tarea 3 | Motor: PostgreSQL 14+
-- Script 01: esquema (DDL)
-- Autor: Luis Angel Yauli Huanca
-- =====================================================================

DROP SCHEMA IF EXISTS sgvc CASCADE;
CREATE SCHEMA sgvc;
SET search_path TO sgvc;

-- ---------------------------------------------------------------------
-- 1. Catalogos
-- ---------------------------------------------------------------------

-- Enumeracion EstadoUsuario del diagrama de clases (ACTIVO/INACTIVO/BLOQUEADO)
CREATE TABLE estado_usuario (
    id_estado_usuario SMALLINT    PRIMARY KEY,
    nombre            VARCHAR(20) NOT NULL UNIQUE
);

-- Estados del ciclo de vida del contrato (diagrama de estados, Figura 3.5)
CREATE TABLE estado_contrato (
    id_estado_contrato SMALLINT    PRIMARY KEY,
    nombre             VARCHAR(30) NOT NULL UNIQUE,
    descripcion        VARCHAR(120)
);

-- ---------------------------------------------------------------------
-- 2. Seguridad y autenticacion (clases Usuario, Rol, Sesion)
-- ---------------------------------------------------------------------

-- Rol.permisos : List<Permiso>  ->  tabla permiso + tabla puente rol_permiso
CREATE TABLE permiso (
    id_permiso  SMALLINT    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo      VARCHAR(40) NOT NULL UNIQUE,
    descripcion VARCHAR(120)
);

CREATE TABLE rol (
    id_rol SMALLINT    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE rol_permiso (
    id_rol     SMALLINT NOT NULL REFERENCES rol(id_rol)         ON DELETE CASCADE,
    id_permiso SMALLINT NOT NULL REFERENCES permiso(id_permiso) ON DELETE CASCADE,
    PRIMARY KEY (id_rol, id_permiso)
);

CREATE TABLE usuario (
    id_usuario        BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username          VARCHAR(50)  NOT NULL UNIQUE,
    password_hash     VARCHAR(255) NOT NULL,            -- password {encrypted}: nunca en texto plano
    email             VARCHAR(120) NOT NULL UNIQUE,
    id_rol            SMALLINT     NOT NULL REFERENCES rol(id_rol),
    id_estado_usuario SMALLINT     NOT NULL DEFAULT 1 REFERENCES estado_usuario(id_estado_usuario),
    fecha_creacion    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_usuario_email CHECK (email LIKE '%_@_%.__%')
);

CREATE TABLE sesion (
    id_sesion        BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token            VARCHAR(255) NOT NULL UNIQUE,
    id_usuario       BIGINT      NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    fecha_inicio     TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    ip_origen        INET,
    CONSTRAINT ck_sesion_fechas CHECK (fecha_expiracion > fecha_inicio)
);

-- ---------------------------------------------------------------------
-- 3. Gestion de contratos
-- ---------------------------------------------------------------------

CREATE TABLE unidad_organizacional (
    id_unidad SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre    VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE proveedor (
    id_proveedor BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    razon_social VARCHAR(150) NOT NULL,
    nit          VARCHAR(20)  NOT NULL UNIQUE,
    email        VARCHAR(120),
    telefono     VARCHAR(20)
);

CREATE TABLE contrato (
    id_contrato        BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo             VARCHAR(30)   NOT NULL UNIQUE,
    objeto             VARCHAR(250)  NOT NULL,
    monto              NUMERIC(14,2) NOT NULL,
    fecha_inicio       DATE          NOT NULL,
    fecha_fin          DATE          NOT NULL,
    id_proveedor       BIGINT        NOT NULL REFERENCES proveedor(id_proveedor),
    id_unidad          SMALLINT      NOT NULL REFERENCES unidad_organizacional(id_unidad),
    id_estado_contrato SMALLINT      NOT NULL DEFAULT 1 REFERENCES estado_contrato(id_estado_contrato),
    id_responsable     BIGINT        NOT NULL REFERENCES usuario(id_usuario),
    id_contrato_origen BIGINT        REFERENCES contrato(id_contrato),   -- renovacion de otro contrato
    fecha_registro     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT ck_contrato_monto  CHECK (monto > 0),
    CONSTRAINT ck_contrato_fechas CHECK (fecha_fin >= fecha_inicio)
);

CREATE TABLE documento_contrato (
    id_documento   BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_contrato    BIGINT       NOT NULL REFERENCES contrato(id_contrato) ON DELETE CASCADE,
    nombre_archivo VARCHAR(200) NOT NULL,
    ruta           VARCHAR(300) NOT NULL,
    id_usuario     BIGINT       NOT NULL REFERENCES usuario(id_usuario),
    fecha_subida   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE alerta (
    id_alerta         BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_contrato       BIGINT      NOT NULL REFERENCES contrato(id_contrato) ON DELETE CASCADE,
    id_usuario        BIGINT      NOT NULL REFERENCES usuario(id_usuario),
    dias_anticipacion SMALLINT    NOT NULL,
    fecha_programada  DATE        NOT NULL,
    canal             VARCHAR(10) NOT NULL,
    estado            VARCHAR(10) NOT NULL DEFAULT 'PENDIENTE',
    fecha_envio       TIMESTAMPTZ,
    CONSTRAINT ck_alerta_dias   CHECK (dias_anticipacion > 0),
    CONSTRAINT ck_alerta_canal  CHECK (canal  IN ('CORREO','CHATBOT')),
    CONSTRAINT ck_alerta_estado CHECK (estado IN ('PENDIENTE','ENVIADA','LEIDA'))
);

-- ---------------------------------------------------------------------
-- 4. Indices (columnas de busqueda frecuente y de claves foraneas)
-- ---------------------------------------------------------------------
CREATE INDEX idx_usuario_rol        ON usuario(id_rol);
CREATE INDEX idx_sesion_usuario     ON sesion(id_usuario);
CREATE INDEX idx_sesion_expiracion  ON sesion(fecha_expiracion);
CREATE INDEX idx_contrato_fecha_fin ON contrato(fecha_fin);       -- motor de alertas
CREATE INDEX idx_contrato_estado    ON contrato(id_estado_contrato);
CREATE INDEX idx_contrato_proveedor ON contrato(id_proveedor);
CREATE INDEX idx_contrato_unidad    ON contrato(id_unidad);
CREATE INDEX idx_contrato_resp      ON contrato(id_responsable);
CREATE INDEX idx_documento_contrato ON documento_contrato(id_contrato);
CREATE INDEX idx_alerta_contrato    ON alerta(id_contrato);
CREATE INDEX idx_alerta_pendientes  ON alerta(fecha_programada) WHERE estado = 'PENDIENTE';
