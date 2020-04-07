/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT DISTINCT
	L.LoanNumber
	, em.FullNameFirstLast 'FSO UW'
INTO #bp
FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = L.LoanNumber	
		AND tif.TrackingItemID = 2966
		AND tif.StatusID = 11
		AND tif.StatusDtID BETWEEN 20170000 AND 20170899
		AND tif.DeleteFlg = 0
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = L.LoanUnderwriterFinalSignOffID

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

SELECT #bp.*
FROM #bp
	
