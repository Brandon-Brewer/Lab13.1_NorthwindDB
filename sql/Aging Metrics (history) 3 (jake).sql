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
DROP TABLE IF EXISTS #bp2
DROP TABLE IF EXISTS #suspended
DROP TABLE IF EXISTS #fallout
DROP TABLE IF EXISTS #closed
DROP TABLE IF EXISTS #ClientReady
DROP TABLE IF EXISTS #final
DROP TABLE IF EXISTS #final2

SELECT DISTINCT 
  L.LoanNumber
, [StatusDescription]		= CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
									CASE WHEN TI.Dt < Sus.Sus THEN 'Scrubbed'
										 ELSE 'Suspensed' END
								WHEN Sus.Sus IS NULL THEN 'Scrubbed' ELSE 'Suspensed' END 
, [StatusDateTime]		= CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
									CASE WHEN TI.Dt < Sus.Sus THEN TI.Dt 
										ELSE Sus.Sus END
								WHEN Sus.Sus IS NULL THEN TI.Dt ELSE Sus.Sus END

INTO #bp
FROM QLODS..LKWD L
	Inner Join QLODS..StatusDim SD ON SD.StatusID = L.CurrentStatusID
    Cross Apply ( 
				Select DISTINCT S.LoanNumber
                FROM QLODS..LKWDTrackingItemFact S
                Where S.TrackingItemID = 7127 -- 7629 Re Uw Scrub
					AND S.LoanNumber = L.LoanNumber
                ) A

    Outer Apply ( 
				Select MIN(TIF.StatusDateTime) 'Dt' -- Find First Scrub TI Status since 4/13 when the loans was >= 60 days old
                FROM QLODS..LKWDTrackingItemFact TIF
                Where TIF.LoanNumber = L.LoanNumber
                    AND TIF.TrackingItemID = 7127 -- 7629 Re Uw Scrub
                    AND TIF.DeleteFlg = 0
                    AND TIF.StatusDtID >= 20170413
                    AND DATEDIFF(DAY,L.Stat21Dt,TIF.StatusDateTime) >= 60
                GROUP BY TIF.LoanNumber
                ) TI

    Outer Apply ( 
				Select MIN(LTF.TransDateTime) 'Sus' -- Find First Suspense since 4/13 where at least one reason was Aged Loan 
                FROM QLODS..LKWDTransFact LTF
                Inner Join QLODS..LKWDStatusReasonGroupBridge S ON S.ReasonGroupID = LTF.ReasonGroupID
                Where LTF.LoanNumber = L.LoanNumber
                        AND LTF.EventTypeID = 2
                        AND LTF.StatusID = 117
                        AND LTF.DeleteFlg = 0
                        AND S.ReasonID = 142 -- Aged Loan
                        AND LTF.TransDtID >= 20170413
                Group By LTF.LoanNumber
                ) Sus

Where L.DeleteFlg = 0
    AND L.ReverseFlg = 0
    AND L.Stat21ID > 20160000
    AND L.LoanPurposeID = 7
    AND (TI.Dt IS NOT NULL 
		OR Sus.Sus IS NOT NULL) 



/***********************************************************************************
Get all statuses on TI 7629 after the first CBU
	However, only the first CBU is kept
***********************************************************************************/
DROP TABLE IF EXISTS #bp2
SELECT 
  #bp.LoanNumber
, tisd.StatusDescription
, tif.StatusDateTime
INTO #bp2
FROM #bp
	INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = #bp.LoanNumber
		AND tif.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan
		AND tif.StatusDateTime > #bp.[StatusDateTime]  --Only return statuses after first CBU
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif.StatusID


/***********************************************************************************
Return all aging Suspenses on or after April 13
***********************************************************************************/
DROP TABLE IF EXISTS #suspended
SELECT DISTINCT
  #bp2.LoanNumber
, [StatusDescription]	= 'Suspended'
, [StatusDateTime]		= suspended.TransDateTime
INTO #suspended
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
						AND ltf.TransDTID > @StartDtId --Suspended on or after 4/13
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
						AND tif.StatusDtID > @StartDtId
					GROUP BY tif.StatusDtID, tif.StatusTmID
				) ClientReady


/***********************************************************************************
Glue all the temp tables together and add row numbers and current loan status
***********************************************************************************/
DROP TABLE IF EXISTS #final2
SELECT *
INTO #final2
FROM (
		SELECT #bp.LoanNumber, #bp.StatusDescription, #bp.[StatusDateTime]  FROM #bp
			UNION ALL
		SELECT #bp2.LoanNumber, #bp2.StatusDescription, #bp2.StatusDateTime FROM #bp2
			UNION ALL
		SELECT * FROM #suspended
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
********************************* METRICS ******************************************
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