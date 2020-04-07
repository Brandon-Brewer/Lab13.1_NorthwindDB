SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT ltf.LoanNumber
	, tid.TrackingItem
	--, tid.TrackingItemDesc
	, tsd.StatusDescription
	, ltf.StatusDtID
	, ltf.StatusTmID

FROM QLODS..LKWDTrackingItemFact ltf
	inner join QLODS..LKWDTrackingItemStatusDim tsd ON tsd.StatusId = ltf.StatusID
	inner join QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = ltf.TrackingItemID

WHERE ltf.StatusDtID Between 20100100 AND 20161031
	and tid.TrackingItem =7277 -- Past Due Amount Will be Paid at Closing
	and ltf.StatusDTID = 20160401
	and tsd.StatusDescription LIKE '%outstanding%'

--GROUP BY ltf.loannumber, tsd.StatusDescription

ORDER BY 1 DESC