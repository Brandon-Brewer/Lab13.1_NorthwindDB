Set Transaction Isolation Level Read Uncommitted

/*
This query retrieves the first "Ready to Order" status of various vendor TIs
*/ 

IF OBJECT_ID('tempdb..#FirstReadytoOrder','U') IS NOT NULL
	DROP TABLE #FirstReadytoOrder

Select LK.LoanNumber
	, [First Ready to Order Date]	= MIN(TIF.StatusDtID)
	, [FRTO StatusTmID]				= MIN(TIF.StatusTmID)	
	, TIF.TrackingSeqNum
	, TID.TrackingItemDesc

INTO #FirstReadytoOrder

FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		LK ON LK.LoanNumber = TIF.LoanNumber
	INNER JOIN QLODS..LKWDTrackingItemDim 
		TID ON TID.TrackingItemID = TIF.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim 
		TISD ON TISD.StatusID = TIF.StatusID
	--INNER JOIN QLODS..LKWDTrackingItemFact TIF2 ON LK.LoanNumber = TIF2.LoanNumber --To Grab TI 2454
	--INNER JOIN QLODS..LKWDTrackingItemDim TID2 ON TID2.TrackingItemID = TIF2.TrackingItemID  --To Grab TI 2454
	INNER JOIN QLODS..LKWDTransFact LTF ON LTF.LoanNumber = LK.LoanNumber  --To Grab the CondoTypeID

WHERE TID.TrackingItemID IN (128,685,2105,2810,2811,2812,2813,1035,1793,1964,1965,3563,3593,4138,4139,4130,5044,5280)
	AND LK.DeleteFlg = 0
	AND LK.ReverseFlg = 0	
	AND ((LK.FalloutID Between 20160201 AND 20160240) OR (LK.ClosingID Between 20160201 AND 20160300))
	AND TISD.StatusID = 9  --(9)Ready to Order  (11)Outstanding
	AND LK.Stat21ID IS NOT NULL
	--AND TID2.TrackingItemID = 1282 --TI 2454
	AND LTF.CondoTypeID = 1 --(1)- IS THIS CORRECT?
	

GROUP BY LK.LoanNumber
	, TIF.TrackingSeqNum
	, TID.TrackingItemDesc


/*
This query retrieves the first Received and Completed Status
*/

IF OBJECT_ID('tempdb..#Finaldata','U') IS NOT NULL
	DROP TABLE #Finaldata

Select FRTO.*
	, [First Received]		= FR.[First Received]
	, FR.StatusTmID

INTO #finaldata

FROM #FirstReadytoOrder FRTO
	CROSS APPLY (
					SELECT TOP 1 TIF.StatusDtID AS [First Received]
								, TIF.StatusTmID

					FROM   QLODS..LKWDTrackingItemFact TIF
									INNER JOIN QLODS..LKWD 
										LK ON LK.LoanNumber = TIF.LoanNumber
									INNER JOIN QLODS..LKWDTrackingItemDim 
										TID ON TID.TrackingItemID = TIF.TrackingItemID
									INNER JOIN QLODS..LKWDTrackingItemStatusDim 
										TISD ON TISD.StatusID = TIF.StatusID

					WHERE  TID.TrackingItemID IN (128,685,2105,2810,2811,2812,2813,1035,1793,1964,1965,3563,3593,4138,4139,4130,5044,5280)
									AND LK.DeleteFlg = 0
									AND LK.ReverseFlg = 0
									AND (TISD.StatusDescription LIKE '%Complete%' 
										OR TISD.StatusDescription LIKE '%Receive%')
									AND FRTO.LoanNumber = LK.LoanNumber
									AND FRTO.TrackingSeqNum = TIF.TrackingSeqNum
                           
					ORDER BY TIF.StatusDtID ASC
							, TIF.StatusTmID ASC
                     
				) FR

/*
The final query to get the Turn Time for each of the Tracking Items
*/

SELECT
	FD.TrackingItemDesc
	, [Turn Time Days]		= AVG(DATEDIFF(SECOND, DATEADD(SECOND, FD.[FRTO StatusTmID]-1, CONVERT(VARCHAR(MAX), CAST(FD.[First Ready to Order Date] AS VARCHAR(10)),112))
										, DATEADD(SECOND, FD.StatusTmID-1, CONVERT(VARCHAR(MAX), CAST(FD.[First Received] AS VARCHAR(10)),112)))/86400.0)

FROM #finaldata FD

GROUP BY FD.TrackingItemDesc

/*End*/










/*quick look into Ligation TI
SELECT *
FROM #finaldata fd 
WHERE fd.TrackingItemDesc LIKE '%Supporting%' 
*/
