/******************************
Client Ready Turn Time
*Finds the first client ready date
*then IUR date
*month is based on Client Ready date
******************************/
Set Transaction Isolation Level Read Uncommitted

DROP TABLE IF EXISTS #CR
SELECT 
  l.LoanNumber 'Loan Number'
, MONTH(clientReady.[last cr]) 'Month'
, lpd.LoanPurpose 'Loan Purpose'
, pb.ProductBucket 'Product'
, pb.Jumboflg
, iur.[first IUR]
, clientReady.[last CR]
, [Turn Time]				= DateDiff(SECOND,iur.[First IUR],clientReady.[last cr])/86400.0
, l.SelfEmployFlg
, l.ClosingID, l.FalloutID
INTO #CR
FROM QLODS..LKWD l
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = l.ProductID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = l.LoanPurposeID
	CROSS APPLY(
				SELECT max(tif2.StatusDateTime) 'last cr'
				FROM QLODS..LKWDTrackingItemFact tif2
				WHERE tif2.LoanNumber = l.LoanNumber
					AND tif2.TrackingItemID = 5659 --TrackingItem = 5957 All Client Conditions Have Been Cleared
					AND tif2.StatusID = 67 --Cleared by Underwriter
					AND tif2.DeleteFlg = 0
					AND tif2.StatusDtID BETWEEN 20170000 AND 20170599
				GROUP BY tif2.LoanNumber
				) clientReady
	CROSS APPLY(
			SELECT min(tif.StatusDateTime) 'first IUR'
			FROM QLODS..LKWDTrackingItemFact tif
			WHERE tif.LoanNumber = l.LoanNumber
				AND tif.TrackingItemID = 5298 --TrackingItem = 5648 Initial Underwrite Review
				AND tif.StatusID = 98 --Completed
				AND tif.DeleteFlg = 0
			GROUP BY tif.LoanNumber
			) IUR
WHERE l.DeleteFlg = 0
	AND l.ReverseFlg = 0
	AND COALESCE(l.ClosingID, l.FalloutID) IS NOT NULL

-------------------------------------------
SELECT * FROM #CR WHERE #CR.[Turn Time] > 0
-------------------------------------------
