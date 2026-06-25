-- ============================================================
-- PROJECT: Health Information System (HIS) Database
-- Author : Samuel Benedict H. Villamor
-- Desc   : Demonstrates table design, constraints, and
--          audit trail setup using triggers.
-- Tools  : SQL Server Management Studio (SSMS)
-- ============================================================

-- ============================================================
-- 1. SCHEMA SETUP
-- ============================================================

CREATE DATABASE HealthInfoSystem;
GO
USE HealthInfoSystem;
GO

-- Departments
CREATE TABLE Departments (
    DepartmentID   INT           IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    Location       NVARCHAR(100),
    IsActive       BIT           NOT NULL DEFAULT 1
);

-- Doctors
CREATE TABLE Doctors (
    DoctorID       INT           IDENTITY(1,1) PRIMARY KEY,
    FirstName      NVARCHAR(50)  NOT NULL,
    LastName       NVARCHAR(50)  NOT NULL,
    Specialization NVARCHAR(100),
    DepartmentID   INT           FOREIGN KEY REFERENCES Departments(DepartmentID),
    LicenseNumber  NVARCHAR(50)  UNIQUE NOT NULL,
    IsActive       BIT           NOT NULL DEFAULT 1
);

-- Patients
CREATE TABLE Patients (
    PatientID      INT           IDENTITY(1,1) PRIMARY KEY,
    FirstName      NVARCHAR(50)  NOT NULL,
    LastName       NVARCHAR(50)  NOT NULL,
    DateOfBirth    DATE          NOT NULL,
    Gender         CHAR(1)       CHECK (Gender IN ('M', 'F')),
    ContactNumber  NVARCHAR(20),
    Address        NVARCHAR(255),
    PhilHealthNo   NVARCHAR(30)  UNIQUE,
    RegisteredDate DATE          NOT NULL DEFAULT GETDATE()
);

-- Admissions
CREATE TABLE Admissions (
    AdmissionID    INT           IDENTITY(1,1) PRIMARY KEY,
    PatientID      INT           NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    DoctorID       INT           NOT NULL FOREIGN KEY REFERENCES Doctors(DoctorID),
    DepartmentID   INT           NOT NULL FOREIGN KEY REFERENCES Departments(DepartmentID),
    AdmissionDate  DATETIME      NOT NULL DEFAULT GETDATE(),
    DischargeDate  DATETIME,
    Diagnosis      NVARCHAR(255),
    Status         NVARCHAR(20)  NOT NULL DEFAULT 'Admitted'
                                 CHECK (Status IN ('Admitted', 'Discharged', 'Under Observation', 'Transferred'))
);

-- ============================================================
-- 2. AUDIT TABLE
-- ============================================================

CREATE TABLE AdmissionAuditLog (
    AuditID        INT           IDENTITY(1,1) PRIMARY KEY,
    AdmissionID    INT,
    Action         NVARCHAR(10)  NOT NULL,   -- INSERT / UPDATE / DELETE
    ChangedBy      NVARCHAR(100) DEFAULT SYSTEM_USER,
    ChangedAt      DATETIME      DEFAULT GETDATE(),
    OldStatus      NVARCHAR(20),
    NewStatus      NVARCHAR(20),
    OldDiagnosis   NVARCHAR(255),
    NewDiagnosis   NVARCHAR(255),
    Remarks        NVARCHAR(500)
);
GO

-- ============================================================
-- 3. SAMPLE DATA
-- ============================================================

INSERT INTO Departments (DepartmentName, Location) VALUES
('Emergency',         'Ground Floor - Wing A'),
('Internal Medicine', '2nd Floor - Wing B'),
('Pediatrics',        '3rd Floor - Wing C'),
('Surgery',           '4th Floor - Wing D'),
('OB-GYN',            '3rd Floor - Wing A');

INSERT INTO Doctors (FirstName, LastName, Specialization, DepartmentID, LicenseNumber) VALUES
('Maria',   'Santos',    'Emergency Medicine', 1, 'PRC-EM-00101'),
('Jose',    'Reyes',     'Internal Medicine',  2, 'PRC-IM-00202'),
('Ana',     'Dela Cruz', 'Pediatrics',         3, 'PRC-PD-00303'),
('Roberto', 'Garcia',    'General Surgery',    4, 'PRC-GS-00404'),
('Liza',    'Bautista',  'Obstetrics',         5, 'PRC-OB-00505');

INSERT INTO Patients (FirstName, LastName, DateOfBirth, Gender, ContactNumber, PhilHealthNo) VALUES
('Juan',     'Cruz',      '1985-03-12', 'M', '09171234567', 'PH-001-001'),
('Maria',    'Lim',       '1992-07-25', 'F', '09281234567', 'PH-001-002'),
('Pedro',    'Aquino',    '1978-11-05', 'M', '09391234567', 'PH-001-003'),
('Rosario',  'Mendoza',   '2001-01-18', 'F', '09501234567', 'PH-001-004'),
('Carlos',   'Villanueva','1965-06-30', 'M', '09611234567', 'PH-001-005'),
('Teresa',   'Ramos',     '1990-09-14', 'F', '09721234567', 'PH-001-006'),
('Antonio',  'Flores',    '2010-04-22', 'M', '09831234567', 'PH-001-007'),
('Gloria',   'Torres',    '1955-12-01', 'F', '09941234567', 'PH-001-008');

INSERT INTO Admissions (PatientID, DoctorID, DepartmentID, AdmissionDate, Diagnosis, Status) VALUES
(1, 2, 2, '2026-06-01 08:00', 'Hypertension Stage 2',        'Admitted'),
(2, 3, 3, '2026-06-02 09:30', 'Upper Respiratory Infection', 'Discharged'),
(3, 4, 4, '2026-06-03 14:00', 'Appendicitis',                'Under Observation'),
(4, 5, 5, '2026-06-04 10:00', 'Prenatal Check - High Risk',  'Admitted'),
(5, 1, 1, '2026-06-05 02:15', 'Acute Chest Pain',            'Admitted'),
(6, 2, 2, '2026-06-06 11:00', 'Diabetes Mellitus Type 2',    'Under Observation'),
(7, 3, 3, '2026-06-07 08:45', 'Bronchial Asthma',            'Discharged'),
(8, 4, 4, '2026-06-08 16:30', 'Gallbladder Stones',          'Admitted');
GO
