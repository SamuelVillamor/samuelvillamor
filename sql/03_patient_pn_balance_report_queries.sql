-- ============================================================
-- PROJECT: Patient Promissory Note (PN) Balance Report
-- Author : Samuel Benedict H. Villamor
-- Source : Training/sandbox environment (TrainingDB_JKQMWC)
--          No real patient data is contained in this script.
-- Desc   : Three parameterized queries used as SSRS datasets
--          for a report showing a patient's total Promissory
--          Note balance, broken down into PN summary, Official
--          Receipt (cash) payments, and Credit Memo payments.
-- Param  : @MRN — Patient Medical Record Number
-- ============================================================


-- ============================================================
-- DATASET 1: PATIENT PN SUMMARY
-- ============================================================
-- Displays the patient's total Promissory Note amount,
-- latest due date, latest admission date, and latest
-- discharge date. Uses a subquery to pre-aggregate PN credits
-- from psPatLedgers before joining to the main patient tables.
-- HAVING clause ensures only patients with PN balances appear.
-- ============================================================

SELECT
    MAX(ep.patid)                                               AS MRN,
    CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename) AS [NAME OF PATIENT],
    ISNULL(pn.TotalPNAmount, 0)                                 AS [TOTAL PN AMOUNT],
    FORMAT(MAX(fa.duedate),        'MMMM dd, yyyy')             AS [LATEST DUE DATE],
    FORMAT(MAX(pr.registrydate),   'MMMM dd, yyyy')             AS [LASTEST ADMISSION DATE],
    FORMAT(MAX(pr.dischdate),      'MMMM dd, yyyy')             AS [LATEST DISCHARGE DATE]

FROM emdPatients AS ep

INNER JOIN psPersonalData AS pd
    ON pd.PK_psPersonalData = ep.PK_emdPatients

LEFT JOIN (
    -- Subquery: aggregate total PN credits per patient
    -- billtrancode filters only Promissory Note transactions:
    --   PNHB  = PN for Hospital Bill
    --   PNPF  = PN for Professional Fee
    --   PNPR  = PN for Pharmacy
    --   PNADJ = PN Adjustment
    SELECT
        FK_emdPatients,
        SUM(credit) AS TotalPNAmount
    FROM psPatLedgers
    WHERE billtrancode IN ('PNHB', 'PNPF', 'PNPR', 'PNADJ')
    GROUP BY FK_emdPatients
) AS pn
    ON pn.FK_emdPatients = ep.PK_emdPatients

LEFT JOIN psPatRegisters AS pr
    ON pr.FK_emdPatients = ep.PK_emdPatients

LEFT JOIN faArinv AS fa
    ON fa.FK_psPatRegisters = pr.PK_psPatRegisters

WHERE
    pr.cancelflag = 0
    AND fa.FK_mscCustomerTypes = 1005   -- Self-pay / private patient type
    AND ep.patid = @MRN

GROUP BY
    pd.lastname, pd.firstname, pd.middlename, pn.TotalPNAmount

HAVING
    pn.TotalPNAmount > 0;   -- Only show patients with outstanding PN balance


-- ============================================================
-- DATASET 2: OFFICIAL RECEIPT (CASH) PAYMENTS
-- ============================================================
-- Displays individual Official Receipt (OR) payments made
-- by the patient. Linked through Accounts Receivable (faArinv)
-- to the patient registry, then filtered to only patients
-- who have Promissory Note ledger entries via a subquery.
-- ============================================================

SELECT DISTINCT
    ep.patid                                                        AS MRN,
    CONCAT(cm.FK_mscORSeries, ' - ', cm.orno)                      AS [SALES INVOICE NO.],
    cm.cashinput                                                    AS [PAYMENT BREAKDOWN (CASH)],
    CONCAT(pd.lastname, ', ', pd.firstname, ' ', pd.middlename)     AS [NAME OF PATIENT],
    cm.FK_mscCustomerTypes                                          AS [CUSTOMER TYPE],
    FORMAT(cm.ordate, 'MMMM dd, yyyy')                             AS DATE

FROM faCRMstr AS cm

INNER JOIN faArinv AS fa
    ON cm.FK_faCustomers = fa.FK_faCustomers

INNER JOIN emdPatients AS ep
    ON fa.FK_emdPatients = ep.PK_emdPatients

INNER JOIN psPersonalData AS pd
    ON pd.PK_psPersonalData = ep.PK_emdPatients

WHERE
    cm.cancelflag = 0
    AND fa.cancelflag = 0
    AND cm.FK_mscCustomerTypes = 1005
    AND ep.patid = @MRN
    AND ep.PK_emdPatients IN (
        -- Only include patients who have PN-type ledger entries
        SELECT DISTINCT FK_emdPatients
        FROM psPatLedgers
        WHERE billtrancode IN ('PNHB', 'PNPF', 'PNPR', 'PNADJ')
    );


-- ============================================================
-- DATASET 3: CREDIT MEMO PAYMENTS
-- ============================================================
-- Displays Credit Memo (CM) payments applied to the patient's
-- account. Joins faDMCMPayer to psDatacenter for payer name
-- and to emdPatients for the MRN. Grouped by document type
-- and CM number to aggregate multiple payment lines per memo.
-- ============================================================

SELECT
    MAX(ep.patid)                                   AS [MRN],
    CONCAT(dp.doctype, ' - ', dp.dmcmno)            AS [SALES INVOICE NO.],
    SUM(dp.amount)                                  AS [TOTAL PAYMENT (CREDIT MEMO)],
    MAX(CAST(pd.fullname AS NVARCHAR(MAX)))         AS [PAYER NAME],
    MAX(CAST(dp.remarks  AS NVARCHAR(MAX)))         AS REMARKS,
    MAX(dp.FK_mscCustomerTypes)                     AS [CUSTOMER TYPE],
    FORMAT(MAX(dp.docdate), 'MMMM dd, yyyy')        AS DATE

FROM faDMCMPayer AS dp

INNER JOIN psDatacenter AS pd
    ON dp.FK_faCustomers = pd.PK_psDatacenter

INNER JOIN emdPatients AS ep
    ON dp.FK_faCustomers = ep.PK_emdPatients

WHERE
    dp.doctype LIKE '%CM%'      -- Filter Credit Memo document types
    AND dp.cancelflag = 0
    AND dp.deleteflag = 0
    AND dp.FK_mscCustomerTypes = 1005
    AND ep.patid = @MRN

GROUP BY
    dp.doctype, dp.dmcmno;
