Set Transaction Isolation Level Read Uncommitted

DROP TABLE IF EXISTS #time
SELECT
  sf.LoanNumber 'LoanNumber'
, SUM(sf.SessionDuration) 'Total Time (sec)'
, MONTH(sf.StartDt) 'Month Name'
--, sf.StartDtID
INTO #time
FROM BILoan.Loan.SessionFact sf
	INNER JOIN QLODS..EmployeeMaster em ON em.CommonID = sf.AccessedByCommonId
WHERE sf.StartDtID BETWEEN 20170100 AND 20170599
	AND em.JobGroup = 'tm'
	AND em.Company LIKE '%Quicken%'
	AND em.Department = 173
	AND (em.JobTitle LIKE '%UW%' OR em.JobTitle LIKE '%Underwrit%')
	
GROUP BY 
	sf.LoanNumber
	, MONTH(sf.StartDt)
	--, sf.StartDtID




SELECT 
  l.LoanNumber 'Loan Number'
, #time.[Month Name] 'Month'
--, #time.StartDtID 
, lpd.LoanPurpose 'Loan Purpose'
, pb.ProductBucket 'Product'
, pb.Jumboflg
, #time.[Total Time (sec)]/60.0 'Total Time (mins)'
, l.SelfEmployFlg
FROM #time 
	INNER JOIN QLODS..LKWD l ON l.LoanNumber = #time.LoanNumber
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = l.ProductID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = l.LoanPurposeID
WHERE l.DeleteFlg = 0
	AND l.ReverseFlg = 0
