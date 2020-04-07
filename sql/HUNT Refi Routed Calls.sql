/*********************************************************************************
This query returns the previous day's calls which were routed
to the Refi Hunt Team (Halliday and Meyers team).

The ask:
	-What loan statuses are routed calls in?
		-Are loans routing to Hunt that should route to servicing or the SC?
	-Who are the assigned CCS?
		-How many call does the average CCS have routed to Hunt?
		-Are some much higher than others? If so, why?
	-Are routed calls from OME clients?
		-Should they be pulled offline and re-assigned?

Stakeholders: Jason Halliday, Ryan Meyers

09.05.2017 - Brandon Brewer
11.08.2017 - Brandon Brewer -	Added cf.CallFromPhoneNumberID as we are trying to find more
								information about calls without Loan Numbers (in particular OME)
*********************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@previousDayID	INT	=	CONVERT(VARCHAR(8), GETDATE()-1, 112) --Yesterday's datetime converted to an ID.  Probably should change to previous QL day.

SELECT
  cf.JacketNumber				'Loan Number'
, loanStatus.StatusFullDesc		'Loan Status (at time of call)'
, [Loan Status (current)]		= CASE WHEN cf.JacketNumber = 0 THEN NULL ELSE sd.StatusFullDesc END
, ome.OnlineStatus				'Online Status (at time of call)'
, OMECurrent.OnlineStatus		'Online Status (current)'
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
, cf.CallFromPhoneNumberID

FROM BICallData.dbo.CallFact			cf
	INNER JOIN QLODS.dbo.LKWD			L	ON L.LoanNumber = cf.JacketNumber
	INNER JOIN QLODS.dbo.StatusDim		sd	ON sd.StatusID = L.CurrentStatusID
	INNER JOIN QLODS.dbo.EmployeeMaster	em	ON em.CommonID = cf.CallEmployeeCommonID
	INNER JOIN QLODS.dbo.EmployeeMaster	em2	ON em2.EmployeeDimID = L.LoanProcessorID
	OUTER APPLY(
				SELECT TOP 1 sd2.StatusFullDesc	--the loan status at the time of the call
				FROM QLODS.dbo.LKWDTransFact ltf
					INNER JOIN QLODS.dbo.StatusDim sd2 ON sd2.StatusID = ltf.StatusID
				WHERE ltf.LoanNumber = cf.JacketNumber
					AND ltf.TransDateTime < cf.StartDateTime --The most recent transdate before the call
					AND ltf.EventTypeID = 2	--Status Change
					AND cf.JacketNumber <> 0 --Only applies if a loan is attached to the call
					AND ltf.RollBackFlg = 0
					AND ltf.DeleteFlg = 0
				ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC --Most recent transactions on top
				) loanStatus
	LEFT JOIN Reporting.dbo.vw_OME ome ON ome.LoanNUmber = cf.JacketNumber
		AND cf.StartDateTime BETWEEN ome.StartDateTime and ome.EndStatusDateTime --Online status at time of the call
	OUTER APPLY(
				SELECT TOP 1 ome2.OnlineStatus
				FROM Reporting.dbo.vw_OME ome2
				WHERE ome2.LoanNumber = cf.JacketNumber
				ORDER BY ome2.EndDtID DESC
				) OMECurrent
				
WHERE 1=1
	AND cf.StartDateID = @previousDayID	--Only want yesterday's calls
	AND cf.CallDirectionID = 2	--Inbound calls
	AND cf.VDNID <> -1	--Exclude calls directly to the TM's extension, by definition these are not being routed
	AND em.OpsDirectorCommonID IN (2007344, 2013055) --OpsDirector is Jason Halliday or Ryan Meyers (The Hunt Refi team)
	AND cf.JacketNumber = 0

ORDER BY cf.StartTimeID