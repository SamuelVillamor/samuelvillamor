-- ============================================================
-- PROJECT: PhilHealth PF Ledger Audit Trigger — psPHICLedgersPF
-- Author : Samuel Benedict H. Villamor
-- Source : Training/sandbox environment (TrainingDB_JKQMWC)
--          No real patient data is contained in this script.
-- Desc   : AFTER UPDATE trigger on the PhilHealth Professional
--          Fee (PF) ledger table. Logs column-level changes to
--          the centralized philhealthLogs audit table.
--          Links back to the main psPHICLedgers table via
--          FK_TRXNO_psPHICLedgers for full audit traceability.
-- Tracks : phictype, PFamount, phicservices
-- ============================================================

USE [TrainingDB_JKQMWC]
GO

ALTER TRIGGER [dbo].[PHICLogsPF]
ON [dbo].[psPHICLedgersPF] 
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- --------------------------------------------------------
    -- Log phictype changes
    -- phictype identifies the PhilHealth benefit type applied.
    -- NULL-safe comparison handles transitions to/from NULL.
    -- modifiedBy sourced from the parent psPHICLedgers.editby
    -- since PF table does not store its own editor reference.
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, PF_TRXNO, TriggerSource, tablename)
    SELECT
        i.FK_TRXNO_psPHICLedgers,
        'phictype',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        m.editby,
        ISNULL(d.phictype, 'NULL'),
        ISNULL(i.phictype, 'NULL'),
        i.PK_TRXNO,
        'PF',
        'psPHICLedgersPF'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN psPHICLedgers m 
        ON i.FK_TRXNO_psPHICLedgers = m.PK_TRXNO
    WHERE 
        (i.phictype IS NULL     AND d.phictype IS NOT NULL)
        OR (i.phictype IS NOT NULL AND d.phictype IS NULL)
        OR (i.phictype <> d.phictype);

    -- --------------------------------------------------------
    -- Log PFamount changes
    -- PFamount = Professional Fee amount billed under PhilHealth.
    -- ISNULL(..., 0) ensures NULL amounts are treated as zero.
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, PF_TRXNO, TriggerSource, tablename)
    SELECT
        i.FK_TRXNO_psPHICLedgers,
        'PFamount',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        m.editby,
        ISNULL(d.PFAmount, 0),
        ISNULL(i.PFAmount, 0),
        i.PK_TRXNO,
        'PF',
        'psPHICLedgersPF'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN psPHICLedgers m
        ON i.FK_TRXNO_psPHICLedgers = m.PK_TRXNO
    WHERE ISNULL(i.PFAmount, 0) <> ISNULL(d.PFAmount, 0);

    -- --------------------------------------------------------
    -- Log phicservices changes
    -- phicservices identifies specific PhilHealth-covered
    -- services rendered. Same NULL-safe pattern as phictype.
    -- --------------------------------------------------------
    INSERT INTO dbo.philhealthLogs 
        (FK_TRXNO, columnname, modifiedDate, modifiedBy, oldvalue, newvalue, PF_TRXNO, TriggerSource, tablename)
    SELECT
        i.FK_TRXNO_psPHICLedgers,
        'phicservices',
        FORMAT(DATEADD(HOUR, 8, SYSUTCDATETIME()), 'MMM dd yyyy h:mmtt'),
        m.editby,
        ISNULL(d.phicservices, 'NULL'),
        ISNULL(i.phicservices, 'NULL'),
        i.PK_TRXNO,
        'PF',
        'psPHICLedgersPF'
    FROM inserted i
    INNER JOIN deleted d 
        ON i.PK_TRXNO = d.PK_TRXNO
    INNER JOIN psPHICLedgers m 
        ON i.FK_TRXNO_psPHICLedgers = m.PK_TRXNO
    WHERE 
        (i.phicservices IS NULL     AND d.phicservices IS NOT NULL)
        OR (i.phicservices IS NOT NULL AND d.phicservices IS NULL)
        OR (i.phicservices <> d.phicservices);

END
GO
