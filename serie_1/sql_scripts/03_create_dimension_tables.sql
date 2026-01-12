-- =============================================================================
-- Script: 03_create_dimension_tables.sql
-- Creación de tablas de dimensiones y sub-dimensiones
-- =============================================================================

USE BankChurnDW;
GO

-- =============================================================================
-- SUB-DIMENSIONES (Tablas normalizadas del esquema Snowflake)
-- =============================================================================

-- DIM_COUNTRY - Catálogo de países
IF OBJECT_ID('dim.Country', 'U') IS NOT NULL
    DROP TABLE dim.Country;
GO

CREATE TABLE dim.Country
(
    country_key     INT IDENTITY(1,1)   PRIMARY KEY,
    country_code    CHAR(3)             NOT NULL,
    country_name    NVARCHAR(100)       NOT NULL UNIQUE,
    continent       NVARCHAR(50)        NOT NULL,
    created_date    DATETIME            DEFAULT GETDATE(),
    updated_date    DATETIME            DEFAULT GETDATE()
);
GO

-- DIM_REGION - Catálogo de regiones
IF OBJECT_ID('dim.Region', 'U') IS NOT NULL
    DROP TABLE dim.Region;
GO

CREATE TABLE dim.Region
(
    region_key      INT IDENTITY(1,1)   PRIMARY KEY,
    region_name     NVARCHAR(100)       NOT NULL UNIQUE,
    region_code     VARCHAR(10)         NOT NULL,
    created_date    DATETIME            DEFAULT GETDATE(),
    updated_date    DATETIME            DEFAULT GETDATE()
);
GO

-- DIM_GENDER - Catálogo de géneros
IF OBJECT_ID('dim.Gender', 'U') IS NOT NULL
    DROP TABLE dim.Gender;
GO

CREATE TABLE dim.Gender
(
    gender_key          INT IDENTITY(1,1)   PRIMARY KEY,
    gender_code         CHAR(1)             NOT NULL UNIQUE,
    gender_description  NVARCHAR(20)        NOT NULL,
    created_date        DATETIME            DEFAULT GETDATE(),
    updated_date        DATETIME            DEFAULT GETDATE()
);
GO

-- DIM_AGE_RANGE - Rangos de edad
IF OBJECT_ID('dim.AgeRange', 'U') IS NOT NULL
    DROP TABLE dim.AgeRange;
GO

CREATE TABLE dim.AgeRange
(
    age_range_key           INT IDENTITY(1,1)   PRIMARY KEY,
    min_age                 INT                 NOT NULL,
    max_age                 INT                 NOT NULL,
    age_range_description   NVARCHAR(50)        NOT NULL UNIQUE,
    created_date            DATETIME            DEFAULT GETDATE(),
    updated_date            DATETIME            DEFAULT GETDATE()
);
GO

-- DIM_GENERATION - Generaciones demográficas
IF OBJECT_ID('dim.Generation', 'U') IS NOT NULL
    DROP TABLE dim.Generation;
GO

CREATE TABLE dim.Generation
(
    generation_key          INT IDENTITY(1,1)   PRIMARY KEY,
    generation_name         NVARCHAR(50)        NOT NULL UNIQUE,
    birth_year_start        INT                 NOT NULL,
    birth_year_end          INT                 NOT NULL,
    generation_description  NVARCHAR(200)       NULL,
    created_date            DATETIME            DEFAULT GETDATE(),
    updated_date            DATETIME            DEFAULT GETDATE()
);
GO

-- =============================================================================
-- DIMENSIONES PRINCIPALES
-- =============================================================================

-- DIM_GEOGRAPHY - Geografía (normalizada con Country y Region)
IF OBJECT_ID('dim.Geography', 'U') IS NOT NULL
    DROP TABLE dim.Geography;
GO

CREATE TABLE dim.Geography
(
    geography_key   INT IDENTITY(1,1)   PRIMARY KEY,
    country_key     INT                 NOT NULL,
    region_key      INT                 NULL,
    city            NVARCHAR(100)       NULL,
    created_date    DATETIME            DEFAULT GETDATE(),
    updated_date    DATETIME            DEFAULT GETDATE(),

    CONSTRAINT FK_Geography_Country FOREIGN KEY (country_key) REFERENCES dim.Country (country_key),
    CONSTRAINT FK_Geography_Region FOREIGN KEY (region_key) REFERENCES dim.Region (region_key)
);
GO

-- DIM_DEMOGRAPHICS - Demografía (normalizada con Gender, AgeRange, Generation)
IF OBJECT_ID('dim.Demographics', 'U') IS NOT NULL
    DROP TABLE dim.Demographics;
GO

CREATE TABLE dim.Demographics
(
    demographics_key    INT IDENTITY(1,1)   PRIMARY KEY,
    age                 INT                 NOT NULL,
    age_range_key       INT                 NOT NULL,
    gender_key          INT                 NOT NULL,
    generation_key      INT                 NOT NULL,
    created_date        DATETIME            DEFAULT GETDATE(),
    updated_date        DATETIME            DEFAULT GETDATE(),

    CONSTRAINT FK_Demographics_AgeRange FOREIGN KEY (age_range_key) REFERENCES dim.AgeRange (age_range_key),
    CONSTRAINT FK_Demographics_Gender FOREIGN KEY (gender_key) REFERENCES dim.Gender (gender_key),
    CONSTRAINT FK_Demographics_Generation FOREIGN KEY (generation_key) REFERENCES dim.Generation (generation_key)
);
GO

-- Índice único para evitar duplicados demográficos
CREATE UNIQUE INDEX UX_Demographics_Combo
ON dim.Demographics (age, gender_key, generation_key);
GO

-- DIM_CUSTOMER - Clientes
IF OBJECT_ID('dim.Customer', 'U') IS NOT NULL
    DROP TABLE dim.Customer;
GO

CREATE TABLE dim.Customer
(
    customer_key    INT IDENTITY(1,1)   PRIMARY KEY,
    customer_id     INT                 NOT NULL UNIQUE,
    customer_name   NVARCHAR(100)       NULL,
    created_date    DATETIME            DEFAULT GETDATE(),
    updated_date    DATETIME            DEFAULT GETDATE()
);
GO

-- DIM_PRODUCT - Productos
IF OBJECT_ID('dim.Product', 'U') IS NOT NULL
    DROP TABLE dim.Product;
GO

CREATE TABLE dim.Product
(
    product_key             INT IDENTITY(1,1)   PRIMARY KEY,
    products_number         INT                 NOT NULL UNIQUE,
    product_category        NVARCHAR(50)        NOT NULL,
    product_description     NVARCHAR(200)       NULL,
    created_date            DATETIME            DEFAULT GETDATE(),
    updated_date            DATETIME            DEFAULT GETDATE()
);
GO

-- DIM_DATE - Fechas
IF OBJECT_ID('dim.Date', 'U') IS NOT NULL
    DROP TABLE dim.Date;
GO

CREATE TABLE dim.Date
(
    date_key        INT                 PRIMARY KEY,
    full_date       DATE                NOT NULL UNIQUE,
    year            INT                 NOT NULL,
    quarter         INT                 NOT NULL,
    month           INT                 NOT NULL,
    day             INT                 NOT NULL,
    month_name      NVARCHAR(20)        NOT NULL,
    day_name        NVARCHAR(20)        NOT NULL,
    is_weekend      BIT                 NOT NULL,
    created_date    DATETIME            DEFAULT GETDATE()
);
GO

-- =============================================================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- =============================================================================

CREATE NONCLUSTERED INDEX IX_Geography_CountryKey ON dim.Geography (country_key);
CREATE NONCLUSTERED INDEX IX_Geography_RegionKey ON dim.Geography (region_key);
CREATE NONCLUSTERED INDEX IX_Demographics_GenderKey ON dim.Demographics (gender_key);
CREATE NONCLUSTERED INDEX IX_Demographics_GenerationKey ON dim.Demographics (generation_key);
CREATE NONCLUSTERED INDEX IX_Demographics_AgeRangeKey ON dim.Demographics (age_range_key);
CREATE NONCLUSTERED INDEX IX_Date_Year ON dim.Date (year);
CREATE NONCLUSTERED INDEX IX_Date_YearMonth ON dim.Date (year, month);
GO

PRINT 'Tablas de dimensiones creadas exitosamente.';
GO
