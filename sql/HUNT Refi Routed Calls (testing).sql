/****************************************************************
This query returns the previous day's calls which were routed
to the Refi Hunt Team (Halliday and Meyers team).

Stakeholders: Jason Halliday, Ryan Meyers

Updated - 09.05.2017 - Brandon Brewer
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@previousDayID	INT	=	CONVERT(VARCHAR(8), GETDATE()-1, 112) --Yesterday's datetime converted to an ID

SELECT
	  cf.JacketNumber				'Loan Number'
	--, [OME]							= CASE WHEN ticsf.StatusID IS NOT NULL THEN 'YES' ELSE
	--									   CASE WHEN cf.JacketNumber = 0 THEN NULL ELSE 'NO' END END
	--, cf.LastStatusID				'what is this?'
	, loanStatus.StatusFullDesc		'Loan Status (at time of call)'
	, [Loan Status (current)]		= CASE WHEN cf.JacketNumber = 0 THEN NULL ELSE sd.StatusFullDesc END
	, ome.OnlineStatus				'Online Status (at time of call)'
	, onlineStatus.OnlineStatus		'Online Status (current)'
	, em2.FullNameFirstLast			'Loan CCS'
	, em2.OpsTeamLeader				'Loan CCS TL'
	, em2.OpsDirector				'Loan CCS OD'
	, em2.OpsDVP					'Loan CCS DVP'
	, em.FullNameFirstLast			'Call Routed to'
	, em.OpsTeamLeader				'Ops Team Leader'
	, em.OpsDirector				'Ops Director'
	, cf.StartDateTime				'Call Start Time'
	, cf.EndDateTime				'Call End Time'
	, cf.Duration					'Call Duration (seconds)'
	--, [OME (at time of call)]		= CASE WHEN cf.JacketNumber = 0 THEN NULL ELSE
	--									CASE WHEN ome.OnlineStatus IS NULL THEN 'No' ELSE 
	--										CASE WHEN ome.OnlineStatus = 'Online' THEN 'Yes' ELSE 'No' END END END

FROM BICallData.dbo.CallFact cf
	INNER JOIN QLODS.dbo.LKWD L ON L.LoanNumber = cf.JacketNumber
	INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = L.CurrentStatusID
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.CommonID = cf.CallEmployeeCommonID
	INNER JOIN QLODS.dbo.EmployeeMaster em2 ON em2.EmployeeDimID = L.LoanProcessorID
	--LEFT JOIN QLODS.dbo.TrackingItemCurrentStatusFact ticsf ON ticsf.LoanNumber = cf.JacketNumber
	--	AND ticsf.TrackingItemID = 6472	--TI 7149 (Online Mortgage Experience Loan)
	OUTER APPLY(
				SELECT TOP 1 sd2.StatusFullDesc	--the loan status at the time of the call
				FROM QLODS.dbo.LKWDTransFact ltf
					INNER JOIN QLODS.dbo.StatusDim sd2 ON sd2.StatusID = ltf.StatusID
				WHERE ltf.LoanNumber = cf.JacketNumber
					AND ltf.TransDateTime < cf.StartDateTime --The most recent transdate before the call
					AND ltf.EventTypeID = 2	--Status Change
					AND cf.JacketNumber <> 0 --Only apply to actual loans
					AND ltf.RollBackFlg = 0
					AND ltf.DeleteFlg = 0
				ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC --Most recent transactions on top
				) loanStatus
	LEFT JOIN Reporting.dbo.vw_OME ome ON ome.LoanNUmber = cf.JacketNumber
		AND cf.StartDateTime BETWEEN ome.StartDateTime and ome.EndStatusDateTime
	OUTER APPLY(
				SELECT TOP 1 ome2.OnlineStatus
				FROM Reporting.dbo.vw_OME ome2
				WHERE ome2.LoanNumber = cf.JacketNumber
				ORDER BY ome2.EndDtID DESC
				)onlineStatus
				
WHERE 1=1
	AND cf.StartDateID = @previousDayID	--Only looking at yesterday's calls
	AND cf.CallDirectionID = 2	--Inbound calls
	AND cf.VDNID <> -1	--Exclude calls directly to the TM's extension since these are not being routed
	AND em.OpsDirectorCommonID IN (2007344, 2013055) --Only include Jason Halliday and Ryan Meyers teams (The Hunt Refi team)

ORDER BY cf.StartTimeID