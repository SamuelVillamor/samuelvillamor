-- ============================================================
-- PROJECT: Health Information System – Audit Triggers
-- Author : Samuel Benedict H. Villamor
-- Desc   : Demonstrates INSERT / UPDATE / DELETE triggers
--          that auto-log changes to AdmissionAuditLog.
--          Mirrors real-world audit trail work done at
--          One Document Corporation.
-- ============================================================

USE HealthInfoSystem;
GO

-- ============================================================
-- TRIGGER 1: Log every new admission (INSERT)
-- ============================================================

CREATE OR ALTER TRIGGER trg_Admission_Insert
ON Admissions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AdmissionAuditLog (AdmissionID, Action, NewStatus, NewDiagnosis, Remarks)
    SELECT
        i.AdmissionID,
        'INSERT',
        i.Status,
        i.Diagnosis,
        'New admission record created.'
    FROM inserted i;
END;
GO

-- ============================================================
-- TRIGGER 2: Log status and diagnosis changes (UPDATE)
-- ============================================================

CREATE OR ALTER TRIGGER trg_Admission_Update
ON Admissions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only log if Status or Diagnosis actually changed
    INSERT INTO AdmissionAuditLog
        (AdmissionID, Action, OldStatus, NewStatus, OldDiagnosis, NewDiagnosis, Remarks)
    SELECT
        i.AdmissionID,
        'UPDATE',
        d.Status,
        i.Status,
        d.Diagnosis,
        i.Diagnosis,
        CASE
            WHEN d.Status  <> i.Status    AND d.Diagnosis <> i.Diagnosis
                THEN 'Status and Diagnosis updated.'
            WHEN d.Status  <> i.Status
                THEN 'Status updated from [' + d.Status + '] to [' + i.Status + '].'
            WHEN d.Diagnosis <> i.Diagnosis
                THEN 'Diagnosis updated.'
            ELSE 'Record updated (no tracked field changes).'
        END
    FROM inserted i
    INNER JOIN deleted d ON i.AdmissionID = d.AdmissionID;
END;
GO

-- ============================================================
-- TRIGGER 3: Log deleted admissions (DELETE)
-- ============================================================

CREATE OR ALTER TRIGGER trg_Admission_Delete
ON Admissions
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AdmissionAuditLog (AdmissionID, Action, OldStatus, OldDiagnosis, Remarks)
    SELECT
        d.AdmissionID,
        'DELETE',
        d.Status,
        d.Diagnosis,
        'Admission record deleted.'
    FROM deleted d;
END;
GO

-- ============================================================
-- TEST: Simulate changes to verify triggers fire correctly
-- ============================================================

-- Test UPDATE: discharge patient 1
UPDATE Admissions
SET Status = 'Discharged', DischargeDate = GETDATE()
WHERE AdmissionID = 1;

-- Test UPDATE: refine diagnosis for patient 5
UPDATE Admissions
SET Diagnosis = 'Acute Myocardial Infarction (Confirmed)'
WHERE AdmissionID = 5;

-- Verify audit log captured both changes
SELECT * FROM AdmissionAuditLog ORDER BY ChangedAt DESC;
GO
