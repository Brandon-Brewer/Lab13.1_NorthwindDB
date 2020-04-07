Set Transaction Isolation Level Read Uncommitted

SELECT
  L.LoanNumber
, [Month Name]			= MONTH(COALESCE(L.ClosingDt, L.FalloutDt))
, lpd.LoanPurpose
, pb.ProductBucket
, pb.Jumboflg
, [Total Time (min)]	= SUM(sf.SessionDuration)/60.0
, L.SelfEmployFlg

FROM QLODS..LKWD L 
	INNER JOIN BILoan.Loan.SessionFact sf ON sf.LoanNumber = L.LoanNumber
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = L.ProductID
	INNER JOIN QLODS..EmployeeMaster em ON em.CommonID = sf.AccessedByCommonId
		AND em.JobTitle IN ('Bilingual Suspense UW', 'Suspense Underwriter', 'Sr. Suspense Underwriter', 'Sr. Suspense UW QL CA')
		--AND em.Department IN (173, 373, 175, 400, 75, 157)

WHERE COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170599
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	
GROUP BY 
	  L.LoanNumber
	, MONTH(COALESCE(L.ClosingDt, L.FalloutDt))
	, lpd.LoanPurpose
	, pb.ProductBucket
	, pb.Jumboflg
	, L.SelfEmployFlg