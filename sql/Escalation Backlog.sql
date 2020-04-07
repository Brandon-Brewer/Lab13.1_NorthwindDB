Set Transaction Isolation Level Read Uncommitted

Select L.LoanNumber 'Loan Number'
, SD.StatusFullDesc 'Current Status'
, DATEDIFF(Day,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,GETDATE())) 'Loan Age'
, UW.FullNameFirstLast 'Escalation UW'
, UW.OpsTeamLeader 'Escalation Leader'
, CCS.FullNameFirstLast 'CCS'
, CCS.OpsTeamLeader 'CCS Leader'
FROM QLODS..LKWD L
	Inner Join QLODS..StatusDim SD ON SD.StatusID = L.CurrentStatusID
	Inner Join QLODS..TrackingItemCurrentStatusFact TI ON TI.LoanNumber = L.LoanNumber -- Only Currently Cleared Escalation Scrubs
	Outer Apply ( Select DISTINCT TIF.LoanNumber
 					FROM QLODS..LKWDTrackingItemFact TIF
						Where TIF.DeleteFlg = 0
							AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan - UW Scrub
							AND TIF.StatusID = 127 -- 80 Help Requested
							AND TIF.DeleteFlg = 0
							AND TIF.LoanNumber = L.LoanNumber
								) HR -- Count and Most Recent Help Requested Status
	Outer Apply ( Select TOP 1 C.SRCCommonID
					FROM SRCLKWD.SONIC.CNAMessageTable C
						Where C.ContactType = 'Loan Underwriter Escalation'
							AND C.MessageType IN ('InternalContactChangedEvent','Internalcontactaddedevent')
							AND C.LoanNumber = L.LoanNumber
								Order By C.SourceDtID DESC, C.SourceTmID DESC	
									) CNA -- Finding the Escalation UW						
	Left Join QLODS..EmployeeMaster UW ON UW.CommonID = CNA.SRCCommonID -- Escalated UW
	Left Join QLODS..EmployeeMaster CCS ON CCS.EmployeeDimID = L.LoanProcessorID -- CCS / Potentially Escalated CCS
		Where L.Deleteflg = 0
			AND L.Reverseflg = 0
			AND SD.StatusKey IN (21,33,35,40) -- Excluded Suspense
			AND L.LoanPurposeID = 7 -- Refi
			AND TI.TrackingItemID = 7126 -- 7631 UW Escalation
			AND TI.StatusID = 25 -- 26 Confirmed
			AND HR.LoanNumber IS NULL -- Never Help Requested
			AND L.Stat21ID <= CAST(CONVERT(VARCHAR(8),DATEADD(Day,-60,CONVERT(DATE,GETDATE())),112) AS INT) -- Loan Age Filter
				Order By L.Stat21ID