-- =============================================================================
-- Script: 06_stored_procedures.sql
-- Procedimientos almacenados para ETL
-- =============================================================================

USE BankChurnDW;
GO

-- =============================================================================
-- SP: Cargar datos desde archivo CSV a staging
-- =============================================================================
IF OBJECT_ID('staging.sp_LoadCustomerChurnFromCSV', 'P') IS NOT NULL
    DROP PROCEDURE staging.sp_LoadCustomerChurnFromCSV;
GO

CREATE PROCEDURE staging.sp_LoadCustomerChurnFromCSV
    @FilePath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE staging.CustomerChurn_Raw;

        -- Cargar datos desde CSV usando BULK INSERT
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            BULK INSERT staging.CustomerChurn_Raw
            FROM ''' + @FilePath + '''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''0x0a'',
                TABLOCK
            );';

        EXEC sp_executesql @SQL;

        -- Limpiar tabla staging
        TRUNCATE TABLE staging.CustomerChurn;

        -- Insertar a staging.CustomerChurn con conversiones de tipo
        INSERT INTO staging.CustomerChurn
        (
            customer_id, credit_score, country, gender, age, tenure,
            balance, products_number, credit_card, active_member,
            estimated_salary, churn
        )
        SELECT
            TRY_CONVERT(INT, customer_id),
            TRY_CONVERT(INT, credit_score),
            country,
            gender,
            TRY_CONVERT(INT, age),
            TRY_CONVERT(INT, tenure),
            TRY_CONVERT(DECIMAL(18,2), REPLACE(balance, CHAR(13), '')),
            TRY_CONVERT(INT, products_number),
            TRY_CONVERT(INT, credit_card),
            TRY_CONVERT(INT, active_member),
            TRY_CONVERT(DECIMAL(18,2), REPLACE(estimated_salary, CHAR(13), '')),
            TRY_CONVERT(INT, REPLACE(churn, CHAR(13), ''))
        FROM staging.CustomerChurn_Raw;

        -- Actualizar fecha de carga
        UPDATE staging.CustomerChurn
        SET load_date = GETDATE();

        COMMIT TRANSACTION;

        -- Retornar estadísticas
        SELECT
            'Carga completada' AS Estado,
            COUNT(*) AS RegistrosCargados,
            MIN(customer_id) AS MinCustomerID,
            MAX(customer_id) AS MaxCustomerID
        FROM staging.CustomerChurn;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

-- =============================================================================
-- SP: Transformar y cargar datos a dimensiones
-- =============================================================================
IF OBJECT_ID('dim.sp_ProcessDimensions', 'P') IS NOT NULL
    DROP PROCEDURE dim.sp_ProcessDimensions;
GO

CREATE PROCEDURE dim.sp_ProcessDimensions
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT 'Procesando dimensiones...';

        -- 1. Cargar nuevos países desde staging
        INSERT INTO dim.Country (country_code, country_name, continent)
        SELECT DISTINCT
            LEFT(UPPER(s.country), 3),
            s.country,
            N'Unknown'
        FROM staging.CustomerChurn s
        WHERE NOT EXISTS (
            SELECT 1
            FROM dim.Country c
            WHERE c.country_name = s.country
        );

        PRINT 'Países procesados (con continente Unknown si no está en catálogo).';

        -- 2. Cargar geografías
        INSERT INTO dim.Geography (country_key, region_key, city)
        SELECT DISTINCT
            c.country_key,
            NULL,
            NULL
        FROM staging.CustomerChurn s
        INNER JOIN dim.Country c ON c.country_name = s.country
        WHERE NOT EXISTS (
            SELECT 1 FROM dim.Geography g WHERE g.country_key = c.country_key
        );

        PRINT 'Geografías procesadas.';

        -- 3. Cargar clientes
        INSERT INTO dim.Customer (customer_id, customer_name)
        SELECT DISTINCT
            s.customer_id,
            'Customer ' + CAST(s.customer_id AS VARCHAR(20))
        FROM staging.CustomerChurn s
        WHERE NOT EXISTS (
            SELECT 1 FROM dim.Customer c WHERE c.customer_id = s.customer_id
        );

        PRINT 'Clientes procesados.';

        -- 4. Cargar demografías
        INSERT INTO dim.Demographics (age, age_range_key, gender_key, generation_key)
        SELECT DISTINCT
            s.age,
            ar.age_range_key,
            g.gender_key,
            gen.generation_key
        FROM staging.CustomerChurn s
        INNER JOIN dim.Gender g ON g.gender_code = LEFT(s.gender, 1)
        INNER JOIN dim.AgeRange ar ON s.age BETWEEN ar.min_age AND ar.max_age
        INNER JOIN dim.Generation gen ON
            (YEAR(GETDATE()) - s.age) BETWEEN gen.birth_year_start AND gen.birth_year_end
        WHERE NOT EXISTS (
            SELECT 1 FROM dim.Demographics d
            WHERE d.age = s.age
              AND d.gender_key = g.gender_key
              AND d.generation_key = gen.generation_key
        );

        PRINT 'Demografías procesadas.';

        COMMIT TRANSACTION;

        -- Estadísticas
        SELECT
            'dim.Customer' AS Tabla, COUNT(*) AS Registros FROM dim.Customer
        UNION ALL
        SELECT 'dim.Geography', COUNT(*) FROM dim.Geography
        UNION ALL
        SELECT 'dim.Demographics', COUNT(*) FROM dim.Demographics;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

-- =============================================================================
-- SP: Cargar tabla de hechos
-- =============================================================================
IF OBJECT_ID('fact.sp_LoadFactCustomerStatus', 'P') IS NOT NULL
    DROP PROCEDURE fact.sp_LoadFactCustomerStatus;
GO

CREATE PROCEDURE fact.sp_LoadFactCustomerStatus
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT 'Cargando tabla de hechos...';

        -- Obtener date_key para la fecha actual
        DECLARE @CurrentDateKey INT = CAST(FORMAT(GETDATE(), 'yyyyMMdd') AS INT);

        INSERT INTO fact.CustomerStatus (
            customer_key,
            geography_key,
            demographics_key,
            product_key,
            date_key,
            credit_score,
            balance,
            estimated_salary,
            tenure_years,
            is_active_member,
            has_credit_card,
            churn_flag
        )
        SELECT
            c.customer_key,
            geo.geography_key,
            demo.demographics_key,
            p.product_key,
            @CurrentDateKey,
            s.credit_score,
            s.balance,
            s.estimated_salary,
            s.tenure,
            CAST(s.active_member AS BIT),
            CAST(s.credit_card AS BIT),
            CAST(s.churn AS BIT)
        FROM staging.CustomerChurn s
        INNER JOIN dim.Customer c ON c.customer_id = s.customer_id
        INNER JOIN dim.Country co ON co.country_name = s.country
        INNER JOIN dim.Geography geo ON geo.country_key = co.country_key
        INNER JOIN dim.Gender g ON g.gender_code = LEFT(s.gender, 1)
        INNER JOIN dim.Generation gen ON
            (YEAR(GETDATE()) - s.age) BETWEEN gen.birth_year_start AND gen.birth_year_end
        INNER JOIN dim.Demographics demo ON
            demo.age = s.age
            AND demo.gender_key = g.gender_key
            AND demo.generation_key = gen.generation_key
        INNER JOIN dim.Product p ON p.products_number = s.products_number
        WHERE NOT EXISTS (
            SELECT 1 FROM fact.CustomerStatus f
            WHERE f.customer_key = c.customer_key
              AND f.date_key = @CurrentDateKey
        );

        COMMIT TRANSACTION;

        -- Estadísticas
        SELECT
            'Carga completada' AS Estado,
            COUNT(*) AS TotalRegistros,
            SUM(CAST(churn_flag AS INT)) AS TotalChurn,
            CAST(100.0 * SUM(CAST(churn_flag AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS PorcentajeChurn
        FROM fact.CustomerStatus;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

-- =============================================================================
-- SP: Proceso ETL completo
-- =============================================================================
IF OBJECT_ID('dbo.sp_ETL_Full', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ETL_Full;
GO

CREATE PROCEDURE dbo.sp_ETL_Full
    @FilePath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE();

    PRINT '=== INICIO DEL PROCESO ETL ===';
    PRINT 'Hora de inicio: ' + CONVERT(VARCHAR, @StartTime, 120);

    -- Paso 1: Cargar datos a staging
    PRINT '';
    PRINT '--- Paso 1: Cargando datos a staging ---';
    EXEC staging.sp_LoadCustomerChurnFromCSV @FilePath;

    -- Paso 2: Procesar dimensiones
    PRINT '';
    PRINT '--- Paso 2: Procesando dimensiones ---';
    EXEC dim.sp_ProcessDimensions;

    -- Paso 3: Cargar hechos
    PRINT '';
    PRINT '--- Paso 3: Cargando tabla de hechos ---';
    EXEC fact.sp_LoadFactCustomerStatus;

    PRINT '';
    PRINT '=== FIN DEL PROCESO ETL ===';
    PRINT 'Hora de fin: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT 'Duración: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR) + ' segundos';
END;
GO

PRINT 'Procedimientos almacenados creados exitosamente.';
GO
