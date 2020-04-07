
--Vendor Ready Loans
--Docs Rec Outstanding
--Oldest one

--These are not flowing to a hotlist

--Run this query each morning. 
--Send the data in a CSV file to Matt Underwood (CC Mark Gresham)
	--really loan number is the main thing needed

DROP TABLE IF EXISTS #VRLoans

SELECT
L.LoanNumber
, TID.TrackingItemDesc
, TIS.StatusDescription
, TIF.StatusDateTime
INTO #VRLoans
FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.StatusDim 
		S ON S.StatusID = L.CurrentStatusID 
			AND S.StatusKey IN (21,33,35)
    INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact	
		TIF ON TIF.LoanNumber = L.LoanNumber
    INNER JOIN QLODS.dbo.LKWDTrackingItemDim 
		TID ON TID.TrackingItemID = TIF.TrackingItemID 
			AND TID.TrackingItem = 8152
    INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim 
		TIS ON TIS.StatusID = TIF.StatusID 
			AND TIS.StatusDescription LIKE '%Cancelled%'

SELECT
L.*
, TIS.StatusDescription
FROM #VRLoans L
	INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact 
		TIF ON TIF.LoanNumber = L.LoanNumber
	INNER JOIN QLODS.dbo.LKWDTrackingItemDim
		TID ON TID.TrackingItemID = TIF.TrackingItemID 
		AND TID.TrackingItem = 8157
	INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim 
		TIS ON TIS.StatusID = TIF.StatusID 
		AND TIS.StatusDescription NOT LIKE '%Cancelled%'
