SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

SELECT 
	  ticsf.LoanNumber
	, ticsf.StatusDateTime
	, tid.TrackingItemDesc
	, sd.StatusDescription
	, ticsf.TrackingSeqNum
	--, tid.TrackingItemDesc

FROM QLODS..TrackingItemCurrentStatusFact ticsf
	INNER JOIN QLODS..LKWDTrackingItemDim
		tid ON tid.TrackingItemID = ticsf.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim 
		sd ON sd.StatusID = ticsf.StatusID

WHERE ticsf.TrackingItemID IN (7253, 7100) -- "Pre-FSOI Audit" and "FSOI Audit" respectively
	AND ticsf.StatusID <> 100
	AND ticsf.LoanNumber = 3363278154




