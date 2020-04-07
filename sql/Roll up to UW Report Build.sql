SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT lk.LoanNumber
	, em.FullNameFirstLast
	, tid.TrackingItemDesc
	, [Help Requested]		= SUM(CASE WHEN tif.StatusID = 127 THEN 1 ELSE 0 END)
	, [Completed]			= SUM(CASE WHEN tif.StatusID = 98 THEN 1 ELSE 0 END)
	, [Need Doc]			= SUM(CASE WHEN tif.StatusID = 78 THEN 1 ELSE 0 END)

FROM QLODS..LKWD lk
	INNER JOIN QLODS..LKWDTrackingItemFact
		tif ON tif.LoanNumber = lk.LoanNumber
	INNER JOIN QLODS..LKWDTrackingItemDIM
		tid ON tid.TrackingItemID = tif.TrackingItemID
	INNER JOIN QLODS..EmployeeMaster
		em ON em.EmployeeDimID = tif.StatusUserID

WHERE tif.TrackingItemID IN (4893,7086,7448)
	AND tif.StatusID IN (127,78,98) --,585)  --Help Requested, Need Documentation, Completed, Completed - Loan Was Escalated
	AND tif.StatusDtID BETWEEN 20170423 AND 20170427
	AND lk.ReverseFlg = 0
	AND lk.DeleteFlg = 0

GROUP BY lk.LoanNumber
	, em.FullNameFirstLast
	, tid.TrackingItemDesc

