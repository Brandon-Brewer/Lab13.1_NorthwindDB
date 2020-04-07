Select L.LoanNumber
, CONVERT(DATE,CONVERT(VARCHAR(8),
       CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
              CASE WHEN TI.Dt < Sus.Sus THEN TI.Dt
                     ELSE Sus.Sus END
              WHEN Sus.Sus IS NULL THEN TI.Dt ELSE Sus.Sus END
                     ,112)) 'First Entered Date'
, CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
       CASE WHEN TI.Dt < Sus.Sus THEN 'Scrub TI'
              ELSE 'Suspense' END
       WHEN Sus.Sus IS NULL THEN 'Scrub TI' ELSE 'Suspense' END 'First Entered Event'
, COALESCE(Help.[Count],0) 'Number of Help Requested''s'
, CASE WHEN Sus.Sus IS NOT NULL THEN 'True' ELSE 'False' END 'Ever Suspended'
, SD.StatusKey 'Current Status'
, CASE WHEN L.FalloutID IS NOT NULL THEN 'Fallout'
       WHEN L.ClosingID < CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT)
              AND SD.StatusKey > 35 THEN 'Closed'
       ELSE 'Pipeline' END 'Current Status Bucket'
, CASE WHEN HELP.[Count] IS NOT NULL AND Sus.Sus IS NOT NULL THEN 'HR and Suspended'
       WHEN HELP.[Count] IS NOT NULL AND Sus.Sus IS NULL THEN 'HR only'
       WHEN HELP.[Count] IS NULL AND Sus.Sus IS NOT NULL THEN 'Suspended Only'
       ELSE 'Not HR nor Suspended' END 'Sub Bucket'
, COALESCE(CASE WHEN TI.Dt IS NOT NULL AND SUS.Sus IS NOT NULL THEN
       CASE WHEN FirstHR.Dt < Sus.Sus THEN 'HR then Suspended'
       ELSE 'Suspended then HR' END END,'') 'Both HR and Suspended'
, COALESCE(L.ClosingDt, L.FalloutDt, GETDATE()) 'Exit Date'

FROM QLODS..LKWD L
       Inner Join QLODS..StatusDim SD ON SD.StatusID = L.CurrentStatusID
       Cross Apply ( Select DISTINCT S.LoanNumber
                                  FROM QLODS..LKWDTrackingItemFact S
                                         Where S.TrackingItemID = 7127 -- 7629 Re Uw Scrub
                                                AND S.LoanNumber = L.LoanNumber
                                                ) A
       Outer Apply ( Select MIN(TIF.StatusDateTime) 'Dt' -- Find First Scrub TI Status since 4/13 when the loans was >= 60 days old
                                  FROM QLODS..LKWDTrackingItemFact TIF
                                         Where TIF.LoanNumber = L.LoanNumber
                                                AND TIF.TrackingItemID = 7127 -- 7629 Re Uw Scrub
                                                AND TIF.DeleteFlg = 0
                                                AND TIF.StatusDtID >= 20170413
                                                AND DATEDIFF(DAY,L.Stat21Dt,TIF.StatusDateTime) >= 60
                                                       GROUP BY TIF.LoanNumber
                                                              ) TI
       Outer Apply ( Select MIN(TIF2.StatusDateTime) 'Dt' -- Find First Scrub TI Status since 4/13 when the loans was >= 60 days old
                                  FROM QLODS..LKWDTrackingItemFact TIF2
                                         Where TIF2.LoanNumber = L.LoanNumber
                                                AND TIF2.TrackingItemID = 7127 -- 7629 Re Uw Scrub
												AND TIF2.StatusID = 127 --help requested
                                                AND TIF2.DeleteFlg = 0
                                                AND TIF2.StatusDtID >= 20170413
                                                AND DATEDIFF(DAY,L.Stat21Dt,TIF2.StatusDateTime) >= 60
                                                       GROUP BY TIF2.LoanNumber
                                                              ) FirstHR
       Outer Apply ( Select MIN(LTF.TransDateTime) 'Sus' -- Find First Suspense since 4/13 where at least one reason was Aged Loan 
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
       Outer Apply ( Select COUNT(HR.LoanNumber) 'Count'
                                  FROM QLODS..LKWDTrackingItemFact HR
                                         Where HR.LoanNumber = L.LoanNumber
                                                AND HR.StatusID = 127 -- 80 Help Requested
                                                AND HR.DeleteFlg = 0
                                                AND HR.StatusDtID >= 20170413
												AND DATEDIFF(DAY,L.Stat21Dt, HR.StatusDateTime) >= 60
                                                       Group By HR.LoanNumber
                                                              ) Help
              Where L.DeleteFlg = 0
                     AND L.ReverseFlg = 0
                     AND L.Stat21ID > 20160000
                     AND L.LoanPurposeID = 7
                     AND (TI.Dt IS NOT NULL OR Sus.Sus IS NOT NULL) 
                           -- Scrubed or suspended for aging since 4/13
