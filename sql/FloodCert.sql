SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  tif.StatusDateTime
, tid.TrackingItemDesc
, tisd.StatusDescription
FROM QLODS.dbo.LKWDTrackingItemFact tif (NOLOCK)
	INNER JOIN QLODS.dbo.LKWDTrackingItemDim tid (NOLOCK) ON tid.TrackingItemID = tif.TrackingItemID
	INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim tisd (NOLOCK) ON tisd.StatusID = tif.StatusID
WHERE tif.LoanNumber = 3405426887
	AND tid.TrackingItem = 328
	AND tif.StatusID = 67
ORDER BY tif.StatusDateTime