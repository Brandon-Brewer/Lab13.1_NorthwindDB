Set Transaction Isolation Level Read Uncommitted

/*
First Ready to Order to the First Receive or Complete
Last Updated: 3/30/2017
*/

IF OBJECT_ID('tempdb..#data','U') IS NOT NULL
	DROP TABLE #data

Select 
	LK.LoanNumber
	, FRTO.TrackingItemID
	, FRTO.[First Ready to Order Date]
	, FRTO.[First Ready to Order Time]
	, FC.[Receive or Complete Date]
	, FC.[Receive or Complete Time]	

INTO #data
	  
FROM QLODS..LKWD LK
	INNER JOIN QLODS..LKWDTransFact LTF ON LTF.LoanNumber = LK.LoanNumber
	
	CROSS APPLY (
					SELECT TIF.LoanNumber
						, TIF.TrackingItemID
						, TIF.TrackingSeqNum
						, [First Ready to Order Date]	= MIN(TIF.StatusDtID)
						, [First Ready to Order Time]	= MIN(TIF.StatusTmID)
					FROM QLODS..LKWDTrackingItemFact TIF 
					WHERE LK.LoanNumber = TIF.LoanNumber
						AND TIF.TrackingItemID = 2813 --*Condo/attached PUD Walls in Content Insurance Dec Page
						AND TIF.StatusID = 9  --(9)Ready to Order  (11):Outstanding
					GROUP BY TIF.LoanNumber, TIF.TrackingItemID, TIF.TrackingSeqNum
				) FRTO
	
	CROSS APPLY (
					SELECT
						[Receive or Complete Date]		= MIN(TIF.StatusDtID)
						, [Receive or Complete Time]	= MIN(TIF.StatusTmID)
					FROM QLODS..LKWDTrackingItemFact TIF
					WHERE TIF.LoanNumber = FRTO.LoanNumber
						AND TIF.TrackingSeqNum = FRTO.TrackingSeqNum
						AND TIF.StatusID IN (7, 56, 58, 98, 177) --Received by Vendor, Received, Completed/Confirmed, Completed, 177-Covered By Master Policy
					GROUP BY TIF.LoanNumber, TIF.TrackingSeqNum
				) FC
		
WHERE LK.Stat21ID IS NOT NULL
	AND LK.DeleteFlg = 0
	AND LK.ReverseFlg = 0	
	AND COALESCE(LK.FalloutID, LK.ClosingID) BETWEEN 20170301 AND 20170400 --Fallout or Closing Date in Feb 2016
	AND LTF.CondoTypeID <> 1 -- (1)- To only look at loans that are Condos
	
GROUP BY
	LK.LoanNumber
	, FRTO.TrackingItemID
	, FRTO.[First Ready to Order Date]
	, FRTO.[First Ready to Order Time]
	, FC.[Receive or Complete Date]
	, FC.[Receive or Complete Time]	


/*
Calculate the Turn Times
*/
SELECT tid.TrackingItemDesc
	, [Turn Time Days]			= AVG(DATEDIFF(SECOND, DATEADD(SECOND, #data.[First Ready to Order Time]-1, CONVERT(VARCHAR(MAX), CAST(#data.[First Ready to Order Date] AS VARCHAR(10)),112))
										, DATEADD(SECOND, #data.[Receive or Complete Time]-1, CONVERT(VARCHAR(MAX), CAST(#data.[Receive or Complete Date] AS VARCHAR(10)),112)))/86400.0)
FROM #data
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = #data.TrackingItemID

GROUP BY tid.TrackingItemDesc
