/**************************************************************************************************************
Aging Loan Metrics for Escalation Team
Stakeholders: Lindsay Villasenor, Jeanine Taylor, Debra Abrams, Eric Birk
Last Updated - 09.12.2017 - Brandon Brewer

Loan Level data for the New Aging Escalation Process.
	The process Started on April 13, 2017

This query looks at all loans that 'enters' the process defined as follows:
	*TI 7629 is statused AND the loan was aging 60 days or more, OR
	*Suspended for "aged loan" on or after 4/13.

Columns
	First Entered Date:			When the loan enters the process (as defined above).
	First Entered Event:		How did the loan enter the process (7629 scrubbed or loan Suspended).
	Number of Help Requested:	How many times 7629 was 'Help Requested'.
	Ever Suspended:				If the loan was ever suspended after entering the process.
	Current Status Bucket:		Where is the loan currently (closed, fallout or pipeline).
	Sub Bucket:					What order does the 'Help Requested' and/or Suspense happens.
	Exit Date:					The date that the loan leaves the process (closed/stat 41 or fallout date).
**************************************************************************************************************/
Set Transaction Isolation Level Read Uncommitted

SELECT 
  L.LoanNumber
, [First Entered Date]			= CONVERT(DATE,CONVERT(VARCHAR(8),
									CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
										 CASE WHEN TI.Dt < Sus.Sus THEN TI.Dt ELSE Sus.Sus END
											  WHEN Sus.Sus IS NULL THEN TI.Dt ELSE Sus.Sus END ,112))
, [First Entered Event]			= CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
									   CASE WHEN TI.Dt < Sus.Sus THEN 'Scrub TI' ELSE 'Suspense' END
									   WHEN Sus.Sus IS NULL THEN 'Scrub TI' ELSE 'Suspense' END
, [Number of Help Requested's]	= COALESCE(Help.[Count],0)
, [Ever Suspended]				= CASE WHEN Sus.Sus IS NOT NULL THEN 'True' ELSE 'False' END
, SD.StatusKey					'Current Status'
, [Current Status Bucket]		= CASE WHEN L.FalloutID IS NOT NULL THEN 'Fallout'
									   WHEN SD.StatusKey > 40 THEN 'Closed' --L.ClosingID < CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT)
										--AND SD.StatusKey > 40 THEN 'Closed' 
									   ELSE 'Pipeline' END---- --changed the pipeline status bucket to include stat 40
, [Sub Bucket]					= CASE WHEN HELP.[Count] IS NOT NULL AND Sus.Sus IS NOT NULL
									   THEN COALESCE(CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
														CASE WHEN FirstHR.Dt < Sus.Sus THEN 'HR then Suspended'
															 ELSE 'Suspended then HR' END END,'')
									   WHEN HELP.[Count] IS NOT NULL AND Sus.Sus IS NULL THEN 'HR only'
									   WHEN HELP.[Count] IS NULL AND Sus.Sus IS NOT NULL THEN 'Suspended Only'
									   ELSE 'Not HR nor Suspended' END
, [Exit Date]					= COALESCE(L.ClosingDt, L.Stat41Dt, L.FalloutDt, GETDATE())
, [Time in Process (days)]		= DATEDIFF(DAY, CONVERT(DATE,CONVERT(VARCHAR(8),
													CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
														 CASE WHEN TI.Dt < Sus.Sus THEN TI.Dt ELSE Sus.Sus END
														 WHEN Sus.Sus IS NULL THEN TI.Dt ELSE Sus.Sus END
														,112)), COALESCE(L.ClosingDt, L.Stat41Dt, L.FalloutDt, GETDATE()))
, [Aged When Entered]			= DATEDIFF(DAY, L.Stat21Dt, CONVERT(DATE,CONVERT(VARCHAR(8),
													CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
														 CASE WHEN TI.Dt < Sus.Sus THEN TI.Dt ELSE Sus.Sus END
														 WHEN Sus.Sus IS NULL THEN TI.Dt ELSE Sus.Sus END ,112)))						
, [IsNewYorkCemaFlg]			= CASE WHEN L.IsNewYorkCemaFlg = 1 THEN 'TRUE' ELSE 'FALSE' END
, [Is Co-op]					= CASE WHEN L.PropertyTypeID = 10 THEN 'TRUE' ELSE 'FALSE' END
, [Product]						= CASE WHEN pb.ProductBucket LIKE 'FHA%' THEN 'FHA'
									   WHEN pb.ProductBucket LIKE 'VA%' THEN 'VA'
									   ELSE pb.ProductBucket END

FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.StatusDim SD ON SD.StatusID = L.CurrentStatusID
	INNER JOIN Reporting.dbo.vwProductBuckets pb ON pb.ProductId = L.ProductID
	
	CROSS APPLY ( 
				Select DISTINCT S.LoanNumber
                FROM QLODS.dbo.LKWDTrackingItemFact S
                WHERE S.TrackingItemID = 7127 -- 7629 Re Uw Scrub
					AND S.LoanNumber = L.LoanNumber
				) Scrub
      
	OUTER APPLY ( 
				SELECT MIN(TIF.StatusDateTime) 'Dt' -- Find First Scrub TI Status since 4/13 when the loans was >= 60 days old
				FROM QLODS.dbo.LKWDTrackingItemFact TIF
				WHERE TIF.LoanNumber = L.LoanNumber
					AND TIF.TrackingItemID = 7127 -- 7629 Re Uw Scrub
					AND TIF.DeleteFlg = 0
					AND TIF.StatusDtID >= 20170413 -- Start date of the process
					AND DATEDIFF(DAY,L.Stat21Dt,TIF.StatusDateTime) >= 60 -- Aging for 60 days or more
				GROUP BY TIF.LoanNumber
				) TI
	
	OUTER APPLY ( 
				SELECT MIN(TIF2.StatusDateTime) 'Dt' -- Find First Scrub TI Status since 4/13 when the loans was >= 60 days old
                FROM QLODS.dbo.LKWDTrackingItemFact TIF2
                WHERE TIF2.LoanNumber = L.LoanNumber
                    AND TIF2.TrackingItemID = 7127 -- 7629 Re Uw Scrub
					AND TIF2.StatusID = 127 -- help requested
                    AND TIF2.DeleteFlg = 0
                    AND TIF2.StatusDtID >= 20170413 -- Start date of the process
                    AND DATEDIFF(DAY,L.Stat21Dt,TIF2.StatusDateTime) >= 60 -- Aging for 60 days or more
				GROUP BY TIF2.LoanNumber
                ) FirstHR
       
	OUTER APPLY ( 
				SELECT MIN(LTF.TransDateTime) 'Sus' -- Find First Suspense since 4/13 where at least one reason was Aged Loan 
                FROM QLODS.dbo.LKWDTransFact LTF
					INNER JOIN QLODS..LKWDStatusReasonGroupBridge S ON S.ReasonGroupID = LTF.ReasonGroupID
                WHERE LTF.LoanNumber = L.LoanNumber
                    AND LTF.EventTypeID = 2 --Status Change
                    AND LTF.StatusID = 117 --Suspense
                    AND LTF.DeleteFlg = 0
                    AND S.ReasonID = 142 -- Aged Loan
                    AND LTF.TransDtID >= 20170413 -- Start date of the process
				GROUP BY LTF.LoanNumber
				) Sus

	OUTER APPLY ( 
				SELECT COUNT(HR.LoanNumber) 'Count'
				FROM QLODS.dbo.LKWDTrackingItemFact HR
				WHERE HR.LoanNumber = L.LoanNumber
					AND HR.StatusID = 127 -- 80 Help Requested
					AND HR.DeleteFlg = 0
					AND HR.StatusDtID >= 20170413 -- Start date of the process
					AND DATEDIFF(DAY,L.Stat21Dt, HR.StatusDateTime) >= 60 --Aging for 60 days or more
				GROUP BY HR.LoanNumber
				) Help

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.Stat21ID > 20160400 -- Helps the query be a little more efficient
	AND L.LoanPurposeID = 7 -- Refinance
	AND (TI.Dt IS NOT NULL 
		OR Sus.Sus IS NOT NULL) -- Scrubed or suspended for aging since 4/13
	
/***************************************************************  The End  ***************************************************************/