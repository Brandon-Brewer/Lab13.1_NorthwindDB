/****************************************************************
Investigating the claim that there was an error on the SC Aging Report.
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	tif.LoanNumber
	, tid.TrackingItem
	, tid.TrackingItemDesc
	, tisd.StatusDescription
	, tif.StatusDateTime

FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif.StatusID

WHERE 1=1
	AND tif.LoanNumber = '3381938211'
	AND tid.TrackingItem IN (5200, 5201, 5202)
	AND tif.DeleteFlg = 0

ORDER BY tif.StatusDateTime DESC

	
