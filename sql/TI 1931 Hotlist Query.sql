SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT top 10 ltf.LoanNumber
	, tid.TrackingItem
	, tsd.StatusDescription
	, pmf.LoanPriorityListID
	, pld.PriorityListName
	, pld.InsertDtDW
	, pmf.StartDateID
	--, ltf.StatusDtID
	--, ltf.StatusTmID

FROM QLODS..LKWDTrackingItemFact ltf
	--QLODS..LKWD L
	--inner join QLODS..LKWDTrackingItemFact ltf ON ltf.LoanNumber = L.LoanNumber
	inner join QLODS..LKWDTrackingItemStatusDim tsd ON tsd.StatusId = ltf.StatusID
	inner join QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = ltf.TrackingItemID
	inner join BILoan..LoanPriorityMovementFact pmf ON pmf.LoanNumber = ltf.LoanNumber
	inner join BILoan..LoanPriorityListDim pld ON pld.LoanPriorityListID = pmf.LoanPriorityListID

WHERE ltf.StatusID <= 20160609
	and tid.TrackingItem = 1931
	and tsd.StatusDescription LIKE '%receive%'
	and pld.PriorityListName LIKE '%collateral%'
	and pmf.StartDateID = 20170310