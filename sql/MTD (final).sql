SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @startDt AS INT	= 20170712
DECLARE @endDt AS INT = 20170713

DROP TABLE IF EXISTS #bp
SELECT DISTINCT 
  tif.LoanNumber
, firstStatus.DateID
INTO #bp
FROM QLODS..LKWDTrackingItemFact tif
	CROSS APPLY(
				SELECT MIN(tif2.StatusDtID) 'DateID'
				FROM QLODS..LKWDTrackingItemFact tif2 
				WHERE tif2.LoanNumber = tif.LoanNumber
					AND tif2.DeleteFlg = 0
					AND tif2.TrackingItemID = 6195 --TI 6449 Pre Final Sign Off Review Needed
					AND tif2.StatusID IN (58, 100) --Completed/Confirmed, Cancelled Tracking Item
				GROUP BY tif2.LoanNumber
				) firstStatus

WHERE 1=1
	AND tif.DeleteFlg = 0
	AND tif.TrackingItemID = 6195 --TI 6449 Pre Final Sign Off Review Needed
	AND tif.StatusDtID BETWEEN @startDt AND @endDt
	AND tif.StatusID IN (58, 100) --Completed/Confirmed, Cancelled Tracking Item
	AND firstStatus.DateID BETWEEN @startDt AND @endDt


/************************************************************************************
Units
************************************************************************************/
DROP TABLE IF EXISTS #unitsData
SELECT
  #bp.LoanNumber		'Loan Number'
, #bp.DateID			'TI 6449 Status Date'
, pb.ProductBucket		'Product'
, pb.Jumboflg
, lpd.LoanPurpose		'Loan Purpose'
, em.FullNameFirstLast	'FSO UW'
, em.CommonID
, [Units]				=  CASE WHEN pb.Jumboflg = 0 THEN
								CASE WHEN pb.ProductBucket = 'Conventional' THEN 1.75
									 WHEN pb.ProductBucket = 'FHA' THEN 2.25
									 WHEN pb.ProductBucket = 'VA' THEN 2
									 ELSE 'Problem' END
						         ELSE 2.5 END
INTO #unitsData
FROM #bp
	INNER JOIN QLODS..LKWD L ON L.LoanNumber = #bp.LoanNumber
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = L.LoanUnderwriterFinalSignOffID
	INNER JOIN Reporting.dbo.vwProductBuckets pb ON pb.ProductId = L.ProductID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	
---------------------------- TOTAL UNITS BY FSO UW-------------------------------------
DROP TABLE IF EXISTS #statuses
SELECT
  #unitsData.[FSO UW]
, #unitsData.CommonID
, SUM(#unitsData.Units) 'Status Units'
INTO #statuses
FROM #unitsData
GROUP BY #unitsData.[FSO UW], #unitsData.CommonID



/************************************************************************************
Closings
************************************************************************************/
DROP TABLE IF EXISTS #closingdata
SELECT
  L.LoanNumber			'Loan Number'
, pb.ProductBucket		'Product'
, pb.Jumboflg
, lpd.LoanPurpose		'Loan Purpose'
, em.FullNameFirstLast	'FSO UW'
, em.CommonID
, [Units]				=  CASE WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) = '0PurchaseConventional' THEN 1.75
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) = '0PurchaseFHA' THEN 2.25
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) = '0PurchaseVA' THEN 2
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) = '0RefinanceConventional' THEN 1
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) LIKE '0RefinanceFHA%' THEN 1.25
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) LIKE '0RefinanceVA%' THEN 1.25
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) LIKE '1Purchase%' THEN 2.5
								WHEN CONCAT(pb.JumboFlg, lpd.LoanPurpose, pb.ProductBucket) LIKE '1Refinance%' THEN 2
								ELSE 9000000 END
								
INTO #closingdata
FROM QLODS..LKWD L
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = L.LoanUnderwriterFinalSignOffID
	INNER JOIN Reporting.dbo.vwProductBuckets pb ON pb.ProductId = L.ProductID
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID

WHERE 1=1
	AND L.ClosingID BETWEEN @startDt AND @endDt
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

---------------------------- TOTAL UNITS BY FSO UW-------------------------------------
DROP TABLE IF EXISTS #closings
SELECT
  #closingdata.[FSO UW]
, #closingdata.CommonID
, SUM(#closingdata.Units) 'Closing Units'
INTO #closings
FROM #closingdata
GROUP BY #closingdata.[FSO UW], #closingdata.CommonID


/************************************************************************************
Final Units
************************************************************************************/
DROP TABLE IF EXISTS #final
SELECT
  COALESCE(#closings.[FSO UW], #statuses.[FSO UW])			'FSO UW'
, em.OpsTeamLeader
, em.OpsDirector
, em.OpsDVP
, CAST((ISNULL(#statuses.[Status Units], 0)) AS FLOAT)		'Status Units'
, CAST((ISNULL(#closings.[Closing Units], 0)) AS FLOAT)		'Closing Units'
, [TOTAL]													= (ISNULL(#statuses.[Status Units], 0))*0.75
															+ (ISNULL(#closings.[Closing Units], 0))*0.25
INTO #final
FROM #closings
	FULL OUTER JOIN #statuses ON #statuses.[FSO UW] = #closings.[FSO UW]
	LEFT JOIN QLODS..EmployeeMaster em ON em.CommonID = coalesce(#closings.CommonID,#statuses.CommonID)



---------------------Final-----------------
DROP TABLE IF EXISTS #ds
SELECT 
  #unitsData.[FSO UW]
, COUNT(*) 'Distinct Statuses'
INTO #ds
FROM #unitsData
GROUP BY #unitsData.[FSO UW]

DROP TABLE IF EXISTS #cs
SELECT 
  #closingdata.[FSO UW]
, COUNT(*) 'Distinct Closings'
INTO #cs
FROM #closingdata
GROUP BY #closingdata.[FSO UW]

SELECT
  #final.[FSO UW]
, #final.OpsTeamLeader
, #final.OpsDirector
, #final.OpsDVP
, CASE WHEN #ds.[Distinct Statuses] IS NULL THEN 0 ELSE #ds.[Distinct Statuses] END 'Distinct Statuses'
, #final.[Status Units]
, CASE WHEN #cs.[Distinct Closings] IS NULL THEN 0 ELSE #cs.[Distinct Closings] END 'Distinct Closings'
, #final.[Closing Units]
, #final.TOTAL

FROM #final
	LEFT JOIN #ds ON #ds.[FSO UW] = #final.[FSO UW]
	LEFT JOIN #cs ON #cs.[FSO UW] = #final.[FSO UW]
ORDER BY #final.TOTAL DESC



----------------------------------------------------------
SELECT * FROM #unitsData
SELECT * FROM #closingdata