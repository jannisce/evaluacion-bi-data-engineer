-- =============================================================================
-- Script: 01_create_database.sql
-- Creación de la base de datos para el Data Warehouse
-- =============================================================================

USE master;
GO

-- Eliminar la base de datos si existe
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'BankChurnDW')
BEGIN
    ALTER DATABASE BankChurnDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankChurnDW;
END
GO

-- Crear la base de datos
CREATE DATABASE BankChurnDW
ON PRIMARY
(
    NAME = BankChurnDW_Data,
    FILENAME = '/var/opt/mssql/data/BankChurnDW_Data.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
)
LOG ON
(
    NAME = BankChurnDW_Log,
    FILENAME = '/var/opt/mssql/data/BankChurnDW_Log.ldf',
    SIZE = 50MB,
    MAXSIZE = 2048MB,
    FILEGROWTH = 32MB
);
GO

USE BankChurnDW;
GO

-- Crear esquemas para organizar los objetos
CREATE SCHEMA staging;
GO

CREATE SCHEMA dim;
GO

CREATE SCHEMA fact;
GO

PRINT 'Base de datos BankChurnDW creada exitosamente.';
GO
