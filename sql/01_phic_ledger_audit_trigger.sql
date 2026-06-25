-- ============================================================
-- PROJECT: PhilHealth Ledger Audit Trigger — psPHICLedgers
-- Author : Samuel Benedict H. Villamor
-- Source : Training/sandbox environment (TrainingDB_JKQMWC)
--          No real patient data is contained in this script.
-- Desc   : AFTER UPDATE trigger on the PhilHealth main ledger
--          table. Logs field-level changes per column into a
--          centralized philhealthLogs audit table — capturing
--          who changed what and when, in Philippine time (UTC+8).
-- Tracks : isdelete, caseRateHBAmount1, caseRateHBAmount2,
--          caseRatePFAmount1, caseRatePFAmount2
-- ============================================================

USE [TrainingDB_JKQMWC]
GO

ALTER TRIGGER [dbo].[PHIClogs] 
ON [dbo].[psPHICLedgers] 
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- --------------------------------------------------------
    -- Log isdelete if changed
    -- Joins to appsysUsers and psPersonalData via deleteby
    -- to resolve who performed the soft-delete action.
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, TriggerSource, tablename)
    SELECT 
        i.PK_TRXNO,
        'isdelete',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename),
        ISNULL(CAST(d.isdelete AS VARCHAR(200)), 'NULL'),
        ISNULL(CAST(i.isdelete AS VARCHAR(200)), 'NULL'),
        'MAIN',
        'psPHICLedgers'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN appsysUsers au 
        ON i.deleteby = au.usercode
    INNER JOIN psPersonaldata pd 
        ON au.PK_appsysUsers = pd.PK_psPersonalData
    WHERE i.isdelete <> d.isdelete;

    -- --------------------------------------------------------
    -- Log caseRateHBAmount1 if changed
    -- HB = Hospital Bill case rate amount (first entry).
    -- Uses ISNULL(..., 0) to treat NULL as 0 for comparison.
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, TriggerSource, tablename)
    SELECT 
        i.PK_TRXNO,
        'caseRateHBAmount1',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename),
        ISNULL(d.caseRateHBAmount1, 0),
        ISNULL(i.caseRateHBAmount1, 0),
        'MAIN',
        'psPHICLedgers'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN appsysUsers au 
        ON i.editby = au.usercode
    INNER JOIN psPersonaldata pd 
        ON au.PK_appsysUsers = pd.PK_psPersonalData
    WHERE ISNULL(i.caseRateHBAmount1, 0) <> ISNULL(d.caseRateHBAmount1, 0);

    -- --------------------------------------------------------
    -- Log caseRateHBAmount2 if changed
    -- HB = Hospital Bill case rate amount (second entry).
    -- Cast to VARCHAR for consistent log storage.
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, TriggerSource, tablename)
    SELECT 
        i.PK_TRXNO,
        'caseRateHBAmount2',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename),
        ISNULL(CAST(d.caseRateHBAmount2 AS VARCHAR(200)), 'NULL'),
        ISNULL(CAST(i.caseRateHBAmount2 AS VARCHAR(200)), 'NULL'),
        'MAIN',
        'psPHICLedgers'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN appsysUsers au 
        ON i.editby = au.usercode
    INNER JOIN psPersonaldata pd 
        ON au.PK_appsysUsers = pd.PK_psPersonalData
    WHERE ISNULL(i.caseRateHBAmount2, 0) <> ISNULL(d.caseRateHBAmount2, 0);

    -- --------------------------------------------------------
    -- Log caseRatePFAmount1 if changed
    -- PF = Professional Fee case rate amount (first entry).
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, TriggerSource, tablename)
    SELECT 
        i.PK_TRXNO,
        'caseRatePFAmount1',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename),
        ISNULL(CAST(d.caseRatePFAmount1 AS VARCHAR(200)), 'NULL'),
        ISNULL(CAST(i.caseRatePFAmount1 AS VARCHAR(200)), 'NULL'),
        'MAIN',
        'psPHICLedgers'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN appsysUsers au 
        ON i.editby = au.usercode
    INNER JOIN psPersonaldata pd 
        ON au.PK_appsysUsers = pd.PK_psPersonalData
    WHERE ISNULL(i.caseRatePFAmount1, 0) <> ISNULL(d.caseRatePFAmount1, 0);

    -- --------------------------------------------------------
    -- Log caseRatePFAmount2 if changed
    -- PF = Professional Fee case rate amount (second entry).
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, TriggerSource, tablename)
    SELECT 
        i.PK_TRXNO,
        'caseRatePFAmount2',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename),
        ISNULL(CAST(d.caseRatePFAmount2 AS VARCHAR(200)), 'NULL'),
        ISNULL(CAST(i.caseRatePFAmount2 AS VARCHAR(200)), 'NULL'),
        'MAIN',
        'psPHICLedgers'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN appsysUsers au 
        ON i.editby = au.usercode
    INNER JOIN psPersonaldata pd 
        ON au.PK_appsysUsers = pd.PK_psPersonalData
    WHERE ISNULL(i.caseRatePFAmount2, 0) <> ISNULL(d.caseRatePFAmount2, 0);

END
GO
