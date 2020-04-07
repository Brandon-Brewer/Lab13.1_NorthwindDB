Set Transaction Isolation Level Read Uncommitted

Select L.LoanNumber 'Loan Number'
, SD.StatusFullDesc 'Current Status'
, DATEDIFF(Day,CONVERT(DATE,CONVERT(VARCHAR(8),L.Stat21ID,112)),CONVERT(DATE,GETDATE())) 'Loan Age'
, CONVERT(DATE,TI.StatusDateTime) 'Current Cleared Date'
, HR.[Help Requested Count]
, CONVERT(DATE,CONVERT(VARCHAR(8),HR.MaxDtID,112)) 'Most Recent Help Requested'
, CONVERT(DATE,CONVERT(VARCHAR(8),BD.DateID,112)) 'Expiration Date'
, COALESCE(Reporting.dbo.fn_GetBusinessDays(CAST(CONVERT(VARCHAR(8),DATEADD(Day,1,CONVERT(DATE,CONVERT(Varchar(8),HR.MaxDtID,112))),112) AS INT)
		,CAST(Convert(VARCHAR(8),Convert(Date,GETDATE()),112) AS INT)),0) 'Business Days' -- add one to start
, UW.FullNameFirstLast 'Escalation UW'
, UW.OpsTeamLeader 'Escalation Leader'
, CCS.FullNameFirstLast 'Escalation CCS'
, CCS.OpsTeamLeader 'Escalation CCS Leader'
FROM QLODS..LKWD L
	Inner Join QLODS..StatusDim SD ON SD.StatusID = L.CurrentStatusID
	Inner Join QLODS..TrackingItemCurrentStatusFact TI ON TI.LoanNumber = L.LoanNumber -- Only Currently Cleared Escalation Scrubs
	Cross Apply ( Select TIF.LoanNumber
						, COUNT(*) 'Help Requested Count'
						, MAX(TIF.StatusDtID) 'MaxDtID'
						, MAX(DATEADD(Second,TIF.StatusTmID-1,CONVERT(DATETIME,CONVERT(VARCHAR(8),TIF.StatusDtID,112)))) 'Max Date Time'
 					FROM QLODS..LKWDTrackingItemFact TIF
						Where TIF.DeleteFlg = 0
							AND TIF.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan - UW Scrub
							AND TIF.StatusID = 127 -- 80 Help Requested
							AND TIF.DeleteFlg = 0
							AND TIF.LoanNumber = L.LoanNumber
								Group By TIF.LoanNumber
									) HR -- Count and Most Recent Help Requested Status
	Cross Apply ( Select D.DateID
						, ROW_NUMBER() OVER(Order By D.DateID ASC) 'RN'
					FROM QLODS..DateDim D
						Where D.DateID > HR.MaxDtID
							AND D.DateID < CAST(CONVERT(VARCHAR(8),DATEADD(Day,20,CONVERT(DATE,CONVERT(VARCHAR(8),D.DateID,112))),112) AS INT)
							AND D.HolidayFlg = 0
							AND D.WeekendFlg = 0
									) BD -- Finding 10 Business Days in the Future
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
			AND SD.StatusKey IN (21,35,40) -- Excluded Suspense
			AND L.LoanPurposeID = 7 -- Refi
			AND TI.TrackingItemID = 7127 -- 7629 Re-UW: Escalated Loan - UW Scrub
			AND TI.StatusID = 67 -- 125 Cleared by Underwriter
			AND BD.RN = 10 -- 10 Business Days in the Future
			AND L.Stat21ID <= CAST(CONVERT(VARCHAR(8),DATEADD(Day,-60,CONVERT(DATE,GETDATE())),112) AS INT) -- Loan Age Filter
				Order By HR.MaxDtID, UW.OpsTeamLeader, UW.FullNameFirstLast