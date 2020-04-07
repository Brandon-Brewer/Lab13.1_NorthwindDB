SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT
	  tif.LoanNumber 
	, TIF.StatusDtID
	, tid.TrackingItemDesc
	, em.FullNameFirstLast
	, em.JobTitle
	, em.JobGroup

FROM QLODS..LKWDTrackingItemFact tif 
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = tif.StatusUserID
	INNER JOIN QLODS..LKWDTrackingItemDim tid on tid.TrackingItemID = tif.TrackingItemID

WHERE tif.StatusId = 47 --RVP CART Exception Review
	AND tif.StatusDtID > 20170500
	AND tif.DeleteFlg = 0

ORDER BY tif.StatusDtID DESC