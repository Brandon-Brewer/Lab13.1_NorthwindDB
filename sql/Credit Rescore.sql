--Find loans that have specific TIs statused Cleared by Underwriter between 3/13 and 3/17

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT tif.LoanNumber
	--, tid.TrackingItem
	--, tid.TrackingItemDesc
	--, tisd.StatusDescription
	--, tif.StatusDateTime


FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif.StatusID
	--INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = tif.LoanNumber

WHERE tid.TrackingItem = 2327
	AND tif.StatusDtID = 20170321
	AND tisd.StatusDescription IN ('Outstanding', 'Ordered')
	AND tif.DeleteFlg = 0

GROUP BY tif.loanNumber
