Set Transaction Isolation Level Read Uncommitted

/***********************************************************************************
Date Range
First Day of new process was April 13.
***********************************************************************************/
DECLARE @StartDtId INT	= 20170413
DECLARE @EndDtId INT	= 20179999


/***********************************************************************************
Get the Base Population
	*TI 7629 is Cleared By UW and the loan was aging 60 days or more.
	*Aging Suspense on or after 4/13 has been added below since these won't be 
	re-srubbed.
***********************************************************************************/
DROP TABLE IF EXISTS #bp
SELECT
  scrubbed.statusdatetime
, suspended.TransDateTime
--INTO #bp
FROM QLODS..LKWD L
	OUTER APPLY(
				SELECT min(tif.StatusDateTime)'statusdatetime'
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND TIF.DeleteFlg = 0
					AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
					AND TIF.StatusID = 67 -- 125 Cleared By UW
					AND TIF.StatusDtID BETWEEN @StartDtId AND @EndDtId
					AND DATEDIFF(DAY,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,CONVERT(VARCHAR(8),TIF.StatusDtID,112))) >= 60 --Aging 60 days at the time of status
				GROUP BY tif.LoanNumber
				)scrubbed

	OUTER APPLY(
				SELECT min(ltf.TransDateTime) 'transdatetime'
				FROM QLODS..LKWDTransFact ltf
					INNER JOIN QLODS..LKWDStatusReasonGroupBridge 
						SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
					INNER JOIN QLODS..LKWDStatusReasonDim 
						SRD ON SRD.ReasonID = SRGB.ReasonID
				WHERE ltf.LoanNumber = L.LoanNumber
					AND ltf.DeleteFlg = 0
					AND ltf.RollBackFlg = 0
					AND ltf.EventTypeID = 2 -- Status Change
					AND ltf.StatusID = 117 -- Suspense
					AND SRD.ReasonID  = 142 --Reason Text = Age Loan
					AND ltf.TransDTID >= @StartDtId --Suspended on or after 4/13
				GROUP BY ltf.TransDateTime
				)suspended
WHERE L.DeleteFlg = 0 
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID = 7


/***********************************************************************************
Get all statuses on TI 7629 after the first CBU
	However, only the first CBU is kept
***********************************************************************************/
DROP TABLE IF EXISTS #bp2
SELECT 
  #bp.LoanNumber
, #bp.[First CBU in April]
, tisd.StatusDescription
, tif.StatusDateTime
INTO #bp2
FROM #bp
	INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = #bp.LoanNumber
		AND tif.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
		AND (CASE WHEN tif.StatusID = 67 AND tif.StatusDateTime > #bp.[First CBU in April] THEN 1 ELSE 0 END) = 0  --Does not return the CBUs after the first
		AND tif.StatusDateTime >= #bp.[First CBU in April]  --Only return statuses after first CBU
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif.StatusID


/***********************************************************************************
Return all aging Suspenses on or after April 13
***********************************************************************************/
DROP TABLE IF EXISTS #sus
SELECT DISTINCT
  #bp2.LoanNumber
, [StatusDescription]	= 'Suspended'
, [StatusDateTime]		= suspended.TransDateTime
INTO #sus
FROM #bp2
	OUTER APPLY (
					SELECT ltf.TransDateTime
					FROM QLODS..LKWDTransFact ltf
						INNER JOIN QLODS..LKWDStatusReasonGroupBridge 
							SRGB ON SRGB.ReasonGroupID = LTF.ReasonGroupID
						INNER JOIN QLODS..LKWDStatusReasonDim 
							SRD ON SRD.ReasonID = SRGB.ReasonID
					WHERE ltf.LoanNumber = #bp2.LoanNumber
						AND ltf.DeleteFlg = 0
						AND ltf.RollBackFlg = 0
						AND ltf.EventTypeID = 2 -- Status Change
						AND ltf.StatusID = 117 -- Suspense
						AND SRD.ReasonID  = 142 --Reason Text = Age Loan
						AND ltf.TransDTID >= @StartDtId --Suspended on or after 4/13
				)suspended
WHERE suspended.TransDateTime IS NOT NULL


/***********************************************************************************
Return all fallouts
***********************************************************************************/
DROP TABLE IF EXISTS #fallout
SELECT DISTINCT
  #bp2.LoanNumber
, [StatusDescription]	= 'Fallout'
, [StatusDateTime]		= L.FalloutDt
INTO #fallout
FROM #bp2
	INNER JOIN QLODS..LKWD L ON L.LoanNumber = #bp2.LoanNumber
WHERE L.FalloutDt IS NOT NULL


/***********************************************************************************
Return all closed
***********************************************************************************/
DROP TABLE IF EXISTS #closed
SELECT DISTINCT
  #bp2.LoanNumber
, [StatusDescription]	= 'Closed'
, [StatusDateTime]		= L.ClosingDt
INTO #closed
FROM #bp2
	INNER JOIN QLODS..LKWD L ON L.LoanNumber = #bp2.LoanNumber
WHERE L.ClosingDt IS NOT NULL


/***********************************************************************************
Return all client ready
***********************************************************************************/
DROP TABLE IF EXISTS #ClientReady
SELECT
  #bp2.LoanNumber
, [StatusDescription]	= 'Client Ready'
, [StatusDateTime]		= ClientReady.crdate
INTO #ClientReady
FROM #bp2
	CROSS APPLY (
					SELECT min(tif.StatusDateTime) 'crdate'
					FROM QLODS..LKWDTrackingItemFact tif
					WHERE tif.LoanNumber = #bp2.LoanNumber
						AND tif.TrackingItemID = 5659 -- All Client Conditions Cleared
						AND tif.StatusID = 67 --Cleared by UW
						AND tif.DeleteFlg = 0
						AND tif.StatusDateTime > #bp2.[First CBU in April]
					GROUP BY tif.StatusDtID, tif.StatusTmID
				) ClientReady


/***********************************************************************************
Glue all the temp tables together and add row numbers and current loan status
***********************************************************************************/
DROP TABLE IF EXISTS #final2
SELECT *
INTO #final2
FROM (
		SELECT #bp2.LoanNumber, #bp2.StatusDescription, #bp2.StatusDateTime FROM #bp2
			UNION ALL
		SELECT * FROM #sus
			UNION ALL
		SELECT * FROM #fallout
			UNION ALL
		SELECT * FROM #closed
			UNION
		SELECT * FROM #ClientReady
	)history

/*Add row numbers and current loan status*/
DROP TABLE IF EXISTS #final
SELECT
  ROW_NUMBER() OVER (PARTITION BY #final2.LoanNumber ORDER BY #final2.StatusDateTime ASC) AS rowNum
, #final2.*
, sd.StatusFullDesc 'Current Loan Status'
--, [Current Status]		= CASE WHEN #final.StatusDescription = 'Cleared by Underwriter' THEN sd.StatusFullDesc ELSE '' END
INTO #final
FROM #final2
	INNER JOIN QLODS..LKWD L ON L.LoanNumber = #final2.LoanNumber
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID
ORDER BY #final2.LoanNumber, #final2.StatusDateTime, #final2.StatusDescription



/***********************************************************************************
******************************* METRICS ********************************************
***********************************************************************************/

SELECT * FROM #final

SELECT count(DISTINCT #final.LoanNumber) 'Scrubbed then Help Requested'
FROM #final
WHERE #final.StatusDescription = 'Help Requested'

SELECT count(DISTINCT #final.LoanNumber) 'Scrubbed then Suspended'
FROM #final
WHERE #final.StatusDescription = 'Suspended'

DROP TABLE IF EXISTS #mytemp
SELECT 
#final.LoanNumber
, COUNT(*) '# of hr'
INTO #mytemp
FROM #final
WHERE #final.StatusDescription = 'Help Requested'
GROUP BY #final.LoanNumber
SELECT #mytemp.[# of hr] 'Round of HR', COUNT(*) 'Count' FROM #mytemp GROUP BY #mytemp.[# of hr]