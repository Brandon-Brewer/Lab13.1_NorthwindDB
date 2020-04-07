/*
This is the Suspense Aging Hotlist Report (daily)
Currently under construction
Last Updated: 3/28/2017
*/	
	
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Select LPC.LoanNumber
	, LPLD.PriorityListName 'Hotlist'
	, LPDD.SRCDisplayPriorityID 'Prioirty'
	, LPDD.PriorityDescription 'Prioirty Description'
	, LPCD.PriorityCategoryDescription 'Priority Type'
	, em.FirstName + ' ' + em.LastName 'Solution Consultant'
	, emdir.FirstName + ' ' + emdir.LastName 'Solution Consultant Director'

--also need:
--Solution Consultant Director
--Solution Consultant
--Loan Purpose
--Current Status
--Days in Priority
--Current Status Date

FROM QLODS..LKWD L
		INNER JOIN BILoan.DBO.LoanPriorityMovementFact_Current 
			LPC ON LPC.LoanNumber = L.LoanNumber --Want Current Hotlist status of each loan
		INNER JOIN BILoan.DBO.LoanPriorityListDim 
			LPLD ON LPLD.LoanPriorityListID = LPC.LoanPriorityListID --Want the Hotlist name
		INNER JOIN BILoan.DBO.LoanPriorityDisplayDim 
			LPDD ON LPDD.LoanPriorityDisplayID = LPC.DisplayPriorityID --Want the Priority and the Priority name
		INNER JOIN BILoan.DBO.LoanPriorityCategoryDim 
			LPCD ON LPCD.LoanPriorityCategoryID = LPC.PriorityCategoryID --Want the Priority type
		INNER JOIN QLODS.DBO.StatusDim 
			sd ON sd.StatusID = L.CurrentStatusID  --Loan Statuses
		INNER JOIN QLODS.DBO.EmployeeMaster
			em ON em.EmployeeDimID = L.SuspenseConsultantID  --Want the Solution Consultant
		INNER JOIN QLODS.DBO.EmployeeMaster
			emdir ON emdir.CommonID = em.TeamLeaderCommonID
		INNER JOIN QLODS.DBO.LKWDTrackingItemFact
			tif ON tif.LoanNumber = L.LoanNumber
			AND tif.TrackingItemID IN (4878,4883,4879) --TI 5200, 5201, 5202 respectively
			AND tif.StatusID IN (39, 25, 11) -- Attempted, Confirmed, Outstanding respectively

WHERE LPC.LoanPriorityListID IN (381,157) --LPLD.PriorityListName IN ('Purchase Solutions Consultant New', 'Refi Solution Consultant Hotlist')
		AND sd.StatusKey BETWEEN 21 AND 65
		AND LPC.PriorityCategoryID = 2  --Hotlist type of 'priority'.  Does not include Sections (i.e sleeping priorities)
		AND L.DeleteFlg = 0
		AND L.ReverseFlg = 0


																																																																																												