Set Transaction Isolation Level Read Uncommitted

/******************************
Pull Through
******************************/
SELECT 
  l.LoanNumber 'Loan Number'
, dd.[MonthName] 'Month'
, lpd.LoanPurpose 'Loan Purpose'
, pb.ProductBucket'Product'
, pb.Jumboflg
, [Product+]			= pb.ProductBucket + CASE WHEN pb.Jumboflg = 1 THEN ' Jumbo' ELSE '' END
, [Closedflg]				= CASE WHEN l.ClosingID IS NOT NULL THEN 1 ELSE 0 END
, [Falloutflg]			= CASE WHEN l.FalloutID IS NOT NULL THEN 1 ELSE 0 END
, l.SelfEmployFlg
FROM QLODS..LKWD l
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = l.ProductID
	INNER JOIN QLODS..DateDim dd ON dd.DateID = CASE WHEN l.ClosingID IS NOT NULL THEN l.CLosingID ELSE l.FalloutID END
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = l.LoanPurposeID
WHERE l.Stat21ID IS NOT NULL 
	AND (l.FalloutID BETWEEN 20170200 AND 20170499
		OR l.ClosingID BETWEEN 20170200 AND 20170499)
	AND l.DeleteFlg = 0
	AND l.ReverseFlg = 0



/******************************
Suspense Rates
******************************/
SELECT 
  l.LoanNumber 'Loan Number'
, dd.[MonthName] 'Month'
, lpd.LoanPurpose 'Loan Purpose'
, pb.ProductBucket 'Product'
, pb.Jumboflg
, [Suspendedflg]		= CASE WHEN l.[1stStat33ID] IS NOT NULL THEN 1 ELSE 0 END
, l.SelfEmployFlg
FROM QLODS..LKWD l
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = l.ProductID
	INNER JOIN QLODS..DateDim dd ON dd.DateID = l.Stat21ID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = l.LoanPurposeID
WHERE l.Stat21ID BETWEEN 20170200 AND 20170499
	AND l.DeleteFlg = 0
	AND l.ReverseFlg = 0



/******************************
Client Ready
******************************/
DROP TABLE IF EXISTS #CR
SELECT 
  l.LoanNumber 'Loan Number'
, MONTH(iur.[First IUR]) 'Month'
, lpd.LoanPurpose 'Loan Purpose'
, pb.ProductBucket 'Product'
, pb.Jumboflg
, iur.[first IUR]
, clientReady.[first CR]
, [Turn Time]				= DateDiff(SECOND,iur.[First IUR],clientReady.[First CR])/86400.0
, l.SelfEmployFlg
INTO #CR
FROM QLODS..LKWD l
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = l.ProductID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = l.LoanPurposeID
	CROSS APPLY(
				SELECT min(tif.StatusDateTime) 'first IUR'
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = l.LoanNumber
					AND tif.TrackingItemID = 5298 --TrackingItem = 5648 Initial Underwrite Review
					AND tif.StatusID = 98 --Completed
					AND tif.DeleteFlg = 0
					AND tif.StatusDtID BETWEEN 20170200 AND 20170499
				GROUP BY tif.LoanNumber
				) IUR
	CROSS APPLY(
				SELECT min(tif2.StatusDateTime) 'first cr'
				FROM QLODS..LKWDTrackingItemFact tif2
				WHERE tif2.LoanNumber = l.LoanNumber
					AND tif2.TrackingItemID = 5659 --TrackingItem = 5957 All Client Conditions Have Been Cleared
					AND tif2.StatusID = 67 --Cleared by Underwriter
					AND tif2.DeleteFlg = 0
				GROUP BY tif2.LoanNumber
				) clientReady
WHERE l.DeleteFlg = 0
	AND l.ReverseFlg = 0

SELECT * FROM #CR WHERE #CR.[Turn Time] > 0




/******************************
AMP TIME
******************************/
DROP TABLE IF EXISTS #time
SELECT
  sf.LoanNumber 'LoanNumber'
, SUM(sf.SessionDuration) 'Total Time (sec)'
, MONTH(sf.StartDt) 'Month Name'
, sf.StartDtID
INTO #time
FROM BILoan.Loan.SessionFact sf
	INNER JOIN QLODS..EmployeeMaster em ON em.CommonID = sf.AccessedByCommonId
WHERE sf.StartDtID BETWEEN 20170200 AND 20170499
	AND (em.JobTitle LIKE '%Underwriting%'
		OR em.JobTitle LIKE '%UW%')
GROUP BY 
	sf.LoanNumber
	, MONTH(sf.StartDt)
	, sf.StartDtID


SELECT 
  l.LoanNumber 'Loan Number'
, #time.[Month Name] 'Month'
, #time.StartDtID 
, lpd.LoanPurpose 'Loan Purpose'
, pb.ProductBucket 'Product'
, pb.Jumboflg
, #time.[Total Time (sec)]/60.0
, l.SelfEmployFlg
FROM #time 
	INNER JOIN QLODS..LKWD l ON l.LoanNumber = #time.LoanNumber
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = l.ProductID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = l.LoanPurposeID
WHERE l.DeleteFlg = 0
	AND l.ReverseFlg = 0
