-- ============================================================
-- PROJECT: Health Information System – Analytical Queries
-- Author : Samuel Benedict H. Villamor
-- Desc   : Real-world reporting queries — admissions summary,
--          doctor workload, department occupancy, and patient
--          length-of-stay analysis.
-- ============================================================

USE HealthInfoSystem;
GO

-- ============================================================
-- QUERY 1: Active admissions with full patient & doctor info
-- ============================================================

SELECT
    a.AdmissionID,
    CONCAT(p.FirstName, ' ', p.LastName)  AS PatientName,
    DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
    p.PhilHealthNo,
    CONCAT(d.FirstName, ' ', d.LastName)  AS AttendingDoctor,
    d.Specialization,
    dep.DepartmentName,
    a.AdmissionDate,
    a.Diagnosis,
    a.Status,
    DATEDIFF(DAY, a.AdmissionDate, GETDATE()) AS DaysAdmitted
FROM Admissions a
INNER JOIN Patients   p   ON a.PatientID    = p.PatientID
INNER JOIN Doctors    d   ON a.DoctorID     = d.DoctorID
INNER JOIN Departments dep ON a.DepartmentID = dep.DepartmentID
WHERE a.Status IN ('Admitted', 'Under Observation')
ORDER BY a.AdmissionDate ASC;
GO

-- ============================================================
-- QUERY 2: Doctor workload summary (current active cases)
-- ============================================================

SELECT
    CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
    d.Specialization,
    dep.DepartmentName,
    COUNT(a.AdmissionID) AS ActiveCases,
    SUM(CASE WHEN a.Status = 'Admitted'           THEN 1 ELSE 0 END) AS Admitted,
    SUM(CASE WHEN a.Status = 'Under Observation'  THEN 1 ELSE 0 END) AS UnderObservation
FROM Doctors d
LEFT JOIN Admissions   a   ON d.DoctorID     = a.DoctorID
                           AND a.Status IN ('Admitted', 'Under Observation')
LEFT JOIN Departments  dep ON d.DepartmentID = dep.DepartmentID
WHERE d.IsActive = 1
GROUP BY d.DoctorID, d.FirstName, d.LastName, d.Specialization, dep.DepartmentName
ORDER BY ActiveCases DESC;
GO

-- ============================================================
-- QUERY 3: Department occupancy report
-- ============================================================

SELECT
    dep.DepartmentName,
    dep.Location,
    COUNT(a.AdmissionID)                                          AS TotalAdmissions,
    SUM(CASE WHEN a.Status = 'Admitted'          THEN 1 ELSE 0 END) AS CurrentlyAdmitted,
    SUM(CASE WHEN a.Status = 'Discharged'        THEN 1 ELSE 0 END) AS Discharged,
    SUM(CASE WHEN a.Status = 'Under Observation' THEN 1 ELSE 0 END) AS UnderObservation,
    SUM(CASE WHEN a.Status = 'Transferred'       THEN 1 ELSE 0 END) AS Transferred
FROM Departments dep
LEFT JOIN Admissions a ON dep.DepartmentID = a.DepartmentID
GROUP BY dep.DepartmentID, dep.DepartmentName, dep.Location
ORDER BY CurrentlyAdmitted DESC;
GO

-- ============================================================
-- QUERY 4: Patient length-of-stay analysis (discharged only)
-- ============================================================

SELECT
    CONCAT(p.FirstName, ' ', p.LastName)         AS PatientName,
    dep.DepartmentName,
    a.Diagnosis,
    a.AdmissionDate,
    a.DischargeDate,
    DATEDIFF(DAY, a.AdmissionDate, a.DischargeDate) AS LengthOfStay_Days
FROM Admissions a
INNER JOIN Patients    p   ON a.PatientID    = p.PatientID
INNER JOIN Departments dep ON a.DepartmentID = dep.DepartmentID
WHERE a.Status = 'Discharged'
  AND a.DischargeDate IS NOT NULL
ORDER BY LengthOfStay_Days DESC;
GO

-- ============================================================
-- QUERY 5: Monthly admissions trend (with running total)
-- ============================================================

WITH MonthlyAdmissions AS (
    SELECT
        FORMAT(AdmissionDate, 'yyyy-MM') AS AdmissionMonth,
        COUNT(*)                          AS TotalAdmissions
    FROM Admissions
    GROUP BY FORMAT(AdmissionDate, 'yyyy-MM')
)
SELECT
    AdmissionMonth,
    TotalAdmissions,
    SUM(TotalAdmissions) OVER (ORDER BY AdmissionMonth) AS RunningTotal
FROM MonthlyAdmissions
ORDER BY AdmissionMonth;
GO

-- ============================================================
-- QUERY 6: Stored Procedure — Get patient admission history
-- ============================================================

CREATE OR ALTER PROCEDURE usp_GetPatientHistory
    @PatientID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AdmissionID,
        a.AdmissionDate,
        a.DischargeDate,
        DATEDIFF(DAY, a.AdmissionDate, ISNULL(a.DischargeDate, GETDATE())) AS DaysStayed,
        CONCAT(d.FirstName, ' ', d.LastName) AS AttendingDoctor,
        dep.DepartmentName,
        a.Diagnosis,
        a.Status
    FROM Admissions a
    INNER JOIN Doctors     d   ON a.DoctorID     = d.DoctorID
    INNER JOIN Departments dep ON a.DepartmentID = dep.DepartmentID
    WHERE a.PatientID = @PatientID
    ORDER BY a.AdmissionDate DESC;
END;
GO

-- Test the stored procedure
EXEC usp_GetPatientHistory @PatientID = 1;
GO
