/******************************
Client Ready Turn Time
*Finds the first client ready date
*then IUR date
*month is based on Client Ready date


------------------------------
NOTE:
	With the StatusDtID filter inside the cross apply it might not be the first
	Client Ready on the loan (it would just be the first CR in January for example).
	
	January numbers are inflated most likely because of this.
	Must check if the Client Ready is actually First
********************************
*******************************/
Set Transaction Isolation Level Read Uncommitted

DROP TABLE IF EXISTS #CR
SELECT 
  l.LoanNumber 'Loan Number'
, MONTH(clientReady.[first cr]) 'Month'
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
				SELECT min(tif2.StatusDateTime) 'first cr'
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

-------------------------------------------
SELECT * FROM #CR WHERE #CR.[Turn Time] > 0
-------------------------------------------
