Set Transaction Isolation Level Read Uncommitted

DECLARE @StartDtId INT	= 20170400
DECLARE @EndDtId INT	= 20170500


/***Over 60 Day Old loans scrubed***/
SELECT 
	  COUNT(TIF.LoanNumber)				'Loans Scrubbed'
	, COUNT(DISTINCT TIF.LoanNumber)	'Distinct'
FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TIF.LoanNumber
WHERE TIF.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
	AND TIF.StatusID = 67 -- 125 Cleared By UW
	AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60


/***Over 60 Day Old loans scrubed Help Requested***/
SELECT 
	  COUNT(TIF.LoanNumber)				'Loans Help Requested'
	, COUNT(DISTINCT TIF.LoanNumber)	'Distinct'
FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TIF.LoanNumber
WHERE TIF.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
	AND TIF.StatusID = 127 -- 80 Help Requested
	AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60


/***Over 60 Day Old loans scrubed; Second Help Requested***/
--IF OBJECT_ID('tempdb..#mytemp','U') IS NOT NULL
  --     DROP TABLE #mytemp

DROP TABLE IF EXISTS #mytemp
SELECT 
	  TIF.LoanNumber
	, COUNT(*) 'Number of Help Requested'
INTO #mytemp
FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TIF.LoanNumber
WHERE TIF.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
	AND TIF.StatusID = 127 -- 80 Help Requested
	AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60
GROUP BY TIF.LoanNumber
HAVING Count(*) >= 2  --Not a love note, this is a troll

SELECT COUNT(*) 'Number of Second Help Requested' FROM #mytemp
DROP TABLE #mytemp


/***Over 60 Day Old loans scrubed; Current Statuses of Help Requested***/
SELECT 
	  sd.StatusFullDesc				'Current Status of Help Requested'
	, COUNT(DISTINCT L.LoanNumber)	'Count'
FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TIF.LoanNumber
	INNER JOIN QLODS..StatusDim
		sd ON sd.StatusID = L.CurrentStatusID
WHERE TIF.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
	AND TIF.StatusID = 127 -- 80 Help Requested
	AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60
GROUP BY sd.StatusFullDesc


/***Over 60 Day Old loans scrubed; How many Help Requested Hit Stat 40***/
SELECT 
	  COUNT(DISTINCT L.LoanNumber)	'Help Requested that hit Stat 40'
FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TIF.LoanNumber
			AND L.Stat40ID IS NOT NULL
WHERE TIF.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
	AND TIF.StatusID = 127 -- 80 Help Requested
	AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60


/***Over 60 Day Old loans escalated***/
SELECT 
	  COUNT(TIF.LoanNumber)				'Loans Escalated'
	, COUNT(DISTINCT TIF.LoanNumber)	'Distinct'
FROM QLODS..LKWDTrackingItemFact TIF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TIF.LoanNumber
WHERE TIF.DeleteFlg = 0
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TIF.TrackingItemID = 7126 -- 7631 UW Escalation Requested
	AND TIF.StatusID = 25 -- 26 Confirmed
	AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60


SELECT 
	  COUNT(L.LoanNumber)	'Refis In Pipe Not Escalated, Over 60 days'
FROM QLODS..LKWD L
	INNER JOIN QLODS..StatusDim 
		sd ON sd.StatusID = L.CurrentStatusID
	LEFT JOIN QLODS..TrackingItemCurrentStatusFact 
		ti ON ti.LoanNumber = L.LoanNumber 
			AND ti.TrackingItemID = 7126 
			AND ti.StatusID = 25
WHERE sd.StatusKey IN (21,33,35)	
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,GETDATE())) >= 60
	AND L.Stat21ID > 20160000
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND (L.ClosingID IS NULL 
		OR L.ClosingID > CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT))
	AND L.FalloutID IS NULL
	AND L.ArchiveFlg IS NULL
	AND ti.LoanNumber IS NULL -- Not Escalated
	AND L.LoanPurposeID = 7


SELECT 
	  COUNT(L.LoanNumber)	'Refis In Pipe Escalated, Over 60 days'
FROM QLODS..LKWD L
	INNER JOIN QLODS..StatusDim 
		SD ON SD.StatusID = L.CurrentStatusID
	INNER JOIN QLODS..TrackingItemCurrentStatusFact 
		TI ON TI.LoanNumber = L.LoanNumber 
			AND TI.TrackingItemID = 7126 
			AND TI.StatusID = 25 --Confirmed
WHERE SD.StatusKey IN (21,33,35)	
	AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,GETDATE())) >= 60
	AND L.Stat21ID > 20160000
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND (L.ClosingID IS NULL 
		OR L.ClosingID > CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT))
	AND L.FalloutID IS NULL
	AND L.ArchiveFlg IS NULL
	AND L.LoanPurposeID = 7


SELECT 
	  COUNT(DISTINCT LTF.LKWDTransFactID) 'Suspenses for "Aged Loan"'
	, COUNT(DISTINCT LTF.LoanNumber) 'Distinct Loans Suspended for "Aged Loan"'
FROM QLODS..LKWDTransFact LTF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = LTF.LoanNumber
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge 
		SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim 
		SRD ON SRD.ReasonID = SRGB.ReasonID
WHERE L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND LTF.DeleteFlg = 0
	AND LTF.RollBackFlg = 0
	AND LTF.EventTypeID = 2 -- Status Change
	AND LTF.StatusID = 117 -- Suspense
	AND SRD.ReasonText = 'Aged Loan'
	AND LTF.TransDtID BETWEEN @StartDtId AND @EndDtId


/**Current Status of Suspenses for Aged Loan**/
SELECT
	  SD.StatusFullDesc						'Current Status of Suspended Loan'
	, COUNT(DISTINCT LTF.LoanNumber)	'Count'
FROM QLODS..LKWDTransFact LTF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = LTF.LoanNumber
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge 
		SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim 
		SRD ON SRD.ReasonID = SRGB.ReasonID
	INNER JOIN QLODS..StatusDim
		SD ON SD.StatusID = L.CurrentStatusID
WHERE L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND LTF.DeleteFlg = 0
	AND LTF.RollBackFlg = 0
	AND LTF.EventTypeID = 2 -- Status Change
	AND LTF.StatusID = 117 -- Suspense
	AND SRD.ReasonText = 'Aged Loan'
	AND LTF.TransDtID BETWEEN @StartDtId AND @EndDtId
GROUP BY SD.StatusFullDesc


/**Of the Suspended loans, how many closed**/
SELECT 
	  COUNT(DISTINCT LTF.LoanNumber)	'Suspended then Closed'
FROM QLODS..LKWDTransFact LTF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = LTF.LoanNumber
			AND L.ClosingID IS NOT NULL
			AND L.ClosingID < CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT)
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge
		SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim 
		SRD ON SRD.ReasonID = SRGB.ReasonID
WHERE L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND LTF.DeleteFlg = 0
	AND LTF.RollBackFlg = 0
	AND LTF.EventTypeID = 2 -- Status Change
	AND LTF.StatusID = 117 -- Suspense
	AND SRD.ReasonText = 'Aged Loan'
	AND LTF.TransDtID BETWEEN @StartDtId AND @EndDtId


/**Of the Suspended, how many fell out**/
SELECT 
	  COUNT(DISTINCT LTF.LoanNumber)	'Suspended then Fallout'
FROM QLODS..LKWDTransFact LTF
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = LTF.LoanNumber
			AND L.FalloutID IS NOT NULL
	INNER JOIN QLODS..LKWDStatusReasonGroupBridge 
		SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
	INNER JOIN QLODS..LKWDStatusReasonDim 
		SRD ON SRD.ReasonID = SRGB.ReasonID
WHERE L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND LTF.DeleteFlg = 0
	AND LTF.RollBackFlg = 0
	AND LTF.EventTypeID = 2 -- Status Change
	AND LTF.StatusID = 117 -- Suspense
	AND SRD.ReasonText = 'Aged Loan'
	AND LTF.TransDtID BETWEEN @StartDtId AND @EndDtId



SELECT 
	L.LoanNumber
	, SD.StatusKey
	, CASE WHEN HR.[HR Date] IS NOT NULL AND AL.[Suspense Date] IS NOT NULL THEN 
			CASE WHEN HR.[HR Date] <= AL.[Suspense Date] THEN HR.[HR Date] ELSE AL.[Suspense Date] END
		WHEN HR.[HR Date] IS NOT NULL AND AL.[Suspense Date] IS NULL THEN HR.[HR Date]
		WHEN HR.[HR Date] IS NULL AND AL.[Suspense Date] IS NOT NULL THEN AL.[Suspense Date]
		ELSE 'WRONG!!!!!!' END 'Date'
	, CASE WHEN HR.[HR Date] IS NOT NULL AND AL.[Suspense Date] IS NOT NULL THEN
			CASE WHEN HR.[HR Date] <= AL.[Suspense Date] THEN 'Help Requested' ELSE 'Suspended' END
		WHEN HR.[HR Date] IS NOT NULL AND AL.[Suspense Date] IS NULL THEN 'Help Requested'
		WHEN HR.[HR Date] IS NULL AND AL.[Suspense Date] IS NOT NULL THEN 'Suspended'
		ELSE 'WRONG!!!!!!' END 'First Date Cause' 
FROM QLODS..TrackingItemCurrentStatusFact TI
	INNER JOIN QLODS..LKWD 
		L ON L.LoanNumber = TI.LoanNumber
	INNER JOIN QLODS..StatusDim 
		SD ON SD.StatusID = L.CurrentStatusID
		
	OUTER APPLY( 
				SELECT MIN(TIFH.StatusDtID) 'HR Date'
				FROM QLODS..LKWDTrackingItemFact TIFH
				WHERE TIFH.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
					AND TIFH.StatusID = 127
					AND TIFH.DeleteFlg = 0
					AND TIFH.LoanNumber = L.LoanNumber
					AND TIFH.StatusDtID >= 20170413
				GROUP BY TIFH.LoanNumber	
				) HR
		
	OUTER APPLY( 
				SELECT MIN(LTF.TransDtID) 'Suspense Date'
				FROM QLODS..LKWDTransFact LTF
					INNER JOIN QLODS..LKWDStatusReasonGroupBridge 
						SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
				WHERE LTF.DeleteFlg = 0
					AND LTF.RollBackFlg = 0
					AND LTF.EventTypeID = 2
					AND LTF.StatusID = 117
					AND SRGB.ReasonID = 142 -- 21  Aged Loan
					AND LTF.LoanNumber = TI.LoanNumber
					AND LTF.TransDtID > 20170413
				GROUP BY LTF.LoanNumber
				) AL

WHERE L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND TI.TrackingItemID = 7126 -- UW Escalated
	AND TI.StatusID = 25 -- Confirmed
	AND (HR.[HR Date] IS NOT NULL 
		OR AL.[Suspense Date] IS NOT NULL)