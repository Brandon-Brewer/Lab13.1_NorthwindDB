--Find loans that have specific TIs statused Cleared by Underwriter between 3/13 and 3/17

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT tif.LoanNumber
	, tid.TrackingItem
	, tisd.StatusDescription
	, tif.StatusDateTime


FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif.StatusID

WHERE tid.TrackingItem IN (1578,2095,2274,2892,3194,4435,5407,5617,5618,6074,6080,6372,6549,6555,7368)
	AND tif.StatusDtID BETWEEN 20170313 AND 20170317
	AND tisd.StatusDescription LIKE '%cleared%'
	AND tif.DeleteFlg = 0
