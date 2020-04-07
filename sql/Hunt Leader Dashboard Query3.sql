SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StartDateTime datetime = getdate()
DECLARE @EndDateTime datetime
DECLARE @Server varchar(max)
DECLARE @Catalog varchar(max)
DECLARE @EndDtID VARCHAR(8) = CONVERT(VARCHAR(8),getdate(),112)
DECLARE @StartDtID VARCHAR(8) 

SET  @StartDtID  = CONVERT(VARCHAR(8),DATEADD(Day,-11,getdate()),112) 

Select @Server = convert(NVARCHAR,ServerName), @Catalog = convert(NVARCHAR,CatalogName)
FROM BIG.List.CubeServers
WHERE CubeServerID = 1 --Avaya Cube

--Create MDX Script holder
DECLARE @MDX varchar(max) =
	'SELECT NON EMPTY { [Measures].[TTT], [Measures].[RONAs], [Measures].[StaffTime], [Measures].[Total AUX Time], [Measures].[AVAILTIME],[Measures].[ACD Calls] } ON COLUMNS
	, NON EMPTY { ([Date].[Date].[Date].ALLMEMBERS , [EmployeeAgent].[CommonID].[CommonID].ALLMEMBERS ) } ON ROWS 
	FROM ( SELECT ( ({[Skill].[SPLITNAME].&[162 - Lifesaver Purchase]
	,[Skill].[SPLITNAME].&[159 - Lifesaver Hunt]
	,[Skill].[SPLITNAME].&[152 - AZ Refi CCS]
	,[Skill].[SPLITNAME].&[154 - AZ PurchCCS]
	,[Skill].[SPLITNAME].&[160 - LifeSaverSchwabRefi]
	,[Skill].[SPLITNAME].&[421 - LS Refi DC]
	,[Skill].[SPLITNAME].&[421 - LS Refi Jaremba]
	,[Skill].[SPLITNAME].&[422 - LS Refi Hoener]
	,[Skill].[SPLITNAME].&[422 - LS RefiReferral HLBP]
	,[Skill].[SPLITNAME].&[423 - LS Refi Maynard]
	,[Skill].[SPLITNAME].&[424 - LS Refi TM Loans]
	,[Skill].[SPLITNAME].&[425 - LS Refi Recchia]
	,[Skill].[SPLITNAME].&[425 - LS Refi Halliday]
	,[Skill].[SPLITNAME].&[426 - LS Refi M Gray]}) ) ON COLUMNS  
	FROM ( SELECT ( [Date].[Date].&['+convert(VARCHAR(8),@StartDtID)+']:[Date].[Date].&['+CONVERT(VARCHAR(8),@EndDtID)+']  )  ON COLUMNS FROM [hCmsAgentGroup])) '

DECLARE @MDX2 varchar(max) =
	' SELECT NON EMPTY {[Measures].[STAFFTIME], [Measures].[TTT] } ON COLUMNS
	, NON EMPTY { ([Date].[Date].[Date].ALLMEMBERS , [EmployeeAgent].[CommonID].[CommonID].ALLMEMBERS ) }  ON ROWS 
	FROM ( SELECT ( { [OpsTeam].[Company].&[Quicken Loans] } ) ON COLUMNS 
	FROM ( SELECT ( { [Skill].[SPLITNAME].&[150 - Non Banking] } ) ON COLUMNS 
	FROM ( SELECT ( [Date].[Date].&['+convert(VARCHAR(8),@StartDtID)+']:[Date].[Date].&['+CONVERT(VARCHAR(8),@EndDtID)+'] ) ON COLUMNS 
	FROM [hCmsAgentGroup]))) WHERE ( [Skill].[SPLITNAME].&[150 - Non Banking], [OpsTeam].[Company].&[Quicken Loans] )'
			

CREATE TABLE #ResultsMDX  
		([Date] sql_variant, 
		CommonID sql_variant, 
		TTT sql_variant,
		RONAs sql_variant,			  
		StaffTime SQL_VARIANT,
		TotalAuxTime SQL_VARIANT,
		AvailTime SQL_VARIANT,
		InboundCalls SQL_VARIANT
		)

INSERT INTO #ResultsMDX
EXEC    [Reporting].[dbo].[QueryAnalysisServices]
		@server = @server,
		@database = @catalog,
		@command = @MDX  


CREATE TABLE #ResultsMDX2 
		([Date] sql_variant, 
		CommonID sql_variant, 
		StaffTime sql_variant,
		TTT	sql_variant
		)

INSERT INTO #ResultsMDX2
EXEC    [Reporting].[dbo].[QueryAnalysisServices]
		@server = @server,
		@database = @catalog,
		@command = @MDX2  



--#Status Counts, Distinct Loans, Confirmed Calls
SELECT
  em.CommonID      
, em.FullNameFirstLast
, tif.StatusDtID
, COUNT(*) 'StatusCount'
, COUNT(DISTINCT CASE WHEN tif.StatusID <> 39 THEN tif.LoanNumber END) 'DistinctLoans'
, COUNT(CASE WHEN TIF.StatusID <> 39 THEN 1 END) 'ConfirmedCalls'    
, COUNT(tif2.StatusID) 'ESC SC'
, COUNT(ome.LoanNumber) 'OME SC'
, COUNT(CASE WHEN ome.LoanNumber IS NULL AND tif2.LoanNumber IS NULL THEN 1 END) 'Non-OME SC'
INTO #DltScDcr
FROM QLODS.dbo.LKWDTrackingItemFact tif
	LEFT JOIN QLODS..EmployeeMaster em ON tif.StatusUserID = em.EmployeeDimID
	LEFT JOIN QLODS.dbo.LKWDTrackingItemDim id on tif.TrackingItemID = id.TrackingItemID
	LEFT JOIN QLODS.dbo.LKWDTrackingItemStatusDim sd on tif.StatusID = sd.StatusID
	LEFT JOIN QLODS.dbo.LKWD lk ON tif.LoanNumber = lk.LoanNumber
	LEFT JOIN QLODS.dbo.LKWDTrackingItemFact tif2 ON tif2.LoanNumber = lk.LoanNumber
		AND tif2.TrackingItemID = 7125
		AND tif2.StatusID = 25
		AND tif2.StatusDateTime <= tif.StatusDateTime
	LEFT JOIN Reporting.dbo.vw_OME ome ON ome.LoanNumber = lk.LoanNumber
		AND tif.StatusDateTime BETWEEN ome.StartDateTime AND ome.EndStatusDateTime
		AND tif2.LoanNumber IS NULL

WHERE ID.TrackingItem IN
                        ('1538'                                                --ICC
                        ,'2128'                                                --Follow Up Call to Client
                        ,'2132'                                                --Post Suspense Call --not used in qslice
                        ,'2146'                                                --Final Goals Goal
                        ,'2549'                                                --Final Goals Call - Purchase                                        
                        ,'3062'                                                --Terms and Structure Call
                        ,'4917'                                                --Initial Call to Seller's Realtor
                        ,'4919'                                                --Initial Call to Client's Realtor
                        ,'4920'                                                --Follow up Call to seller's realtor
                        ,'4921'                                                --Follow up call to client's realtor
                        ,'5266'                                                --folder received ICC
                        ,'5267'                                                --folder received follow up call to client
                        ,'5501'                                                --Terms and structure have changed -- ccs to communicate
                        ,'6000'                                                --M1 ICC
                        ,'6001'                                                --m1 Client follow up call                             
                        ,'6002'                                                --M1st Client Call -- Approved Waiting for Property
                        ,'6042'                                                --FR: Inbound Client Call
                        ,'6057'                                                --M1st Realtor Initial Call
                        ,'6058'                                                --M1st Realtor Follow up call
                        ,'6067'                                                --M1st Realtor Call -- Approved waiting for property
                        ,'6856'                                                --MyQL Chat Communication                        
                        )
	AND tif.StatusID IN 
						(39 
						,98 
						,58 
						,25 
						,572
						,571
						,573
						,42 
						,43 
						,41 
						,321
						,325
						,324
						,322
						,323
						,326
						,56
						)
                                                       
	AND tif.StatusDtID = @StartDtID
	AND tif.DeleteFlg = 0
	AND lk.ReverseFlg = 0 
	AND tif.StatusUserID <> 1
	AND EM.JOBTITLE IN ('PC Hunt Client Care Spec', 'Exec Hunt CCS')

GROUP BY em.CommonID, em.FullNameFirstLast, tif.StatusDtID
			 


--#AnsweredCalls    
SELECT  EM.CommonID, 
		CF.StartDateID,			
		COUNT(CASE WHEN COD.CallDesc = 'CONNECTED' AND CF.calldirectionid = 2 THEN 1 END) AS Answered,
		COUNT(CASE WHEN COD.CallDesc = 'MISSED OPPORTUNITY' AND CF.calldirectionid = 2 THEN 1 END) AS MissedOpp,
		COUNT(CASE WHEN COD.CallDesc = 'RONA' AND CF.calldirectionid = 2 THEN 1 END) AS CTIRONA,
		COUNT(CASE WHEN CF.calldirectionid = 1 THEN 1 END) AS OutboundCalls,
		COUNT(CASE WHEN CF.CallDirectionID =1 AND CF.Duration >= 180 THEN 1 END) AS OutboundOver3Mins

INTO #AnsweredCalls
FROM [BICallData].[dbo].[CallFact] cf
LEFT JOIN QLODS..EmployeeMaster em WITH (NOLOCK) ON cf.CallEmployeeID = em.EmployeeDimID 
LEFT JOIN BICallData.dbo.CalloutcomeDim COD WITH (NOLOCK) ON CF.CallOutComeID = COD.CallOutcomeID
WHERE  CF.CallFromPhoneNumberID <> 31999
AND CF.startdateid between @StartDtID AND @EndDtID
AND EM.JOBTITLE IN ('PC Hunt Client Care Spec', 'Exec Hunt CCS')
		 
AND NOT EXISTS 
(
	SELECT * FROM OADB.dbo.CmsVdnInfo VI WHERE VI.VDNID = CF.VDNID AND VI.VDN = '08373'
)
  
GROUP BY EM.CommonID, CF.StartDateID


--#SurveyResults    
SELECT  TM.CommonID
, CONVERT(DATE,R.CreateDate) AS Date
, COUNT(*) AS Surveys
, SUM(R.DialogResponse) AS SumSurveyScore
, COUNT(CASE WHEN R.DialogResponse IN (4,5) THEN 1 END) AS FoursandFives
INTO #SurveyResults
FROM  SRCIVR.DBO.DialogResult R WITH(NOLOCK)
LEFT JOIN SRCIVR.DBO.IvrDialogMap IM  WITH(NOLOCK) ON IM.IvrDialogMapCode = R.IvrDialogMapCode 
LEFT JOIN SRCIVR.DBO.DialogLookup DL  WITH(NOLOCK) ON DL.DialogCode = IM.DialogCode 
LEFT JOIN QLODS.DBO.LOLA lo WITH(NOLOCK) ON   LO.JacketNumber = CAST(R.LoanNumber AS VARCHAR(15))
LEFT JOIN BICOMMON.TeamMember.TeamMemberDim TM WITH(NOLOCK) ON TM.Extension = R.AgentExtension 
		AND TM.OriginalDateOfHire <= R.CreateDate AND (R.CreateDate <= CONVERT(date,CONVERT(VARCHAR(8),TerminationDtID), 112) OR Tm.TerminationDtID IS NULL)
LEFT JOIN BICommon.TeamMember.HierarchyFlat HF WITH (NOLOCK) ON TM.CommonID = HF.LeafCommonID 
	AND CONVERT(INT, CONVERT(VARCHAR(8),CONVERT(DATETIME,R.CreateDate),112))  BETWEEN HF.ActiveStartDTID AND HF.ActiveEndDtID
WHERE R.IvrDialogMapCode = '6'
AND   HF.L5CommonID IN (1002689,1002899,1003804 )
AND CONVERT(INT,CONVERT(VARCHAR(8),R.CreateDate,112)) BETWEEN @StartDtID AND @EndDtID
GROUP BY TM.CommonID, CONVERT(DATE,R.CreateDate)



--DECLARE @StartDtID AS INT = 20171211
--DECLARE @EndDtID AS INT = 20171211
SELECT    EM.CommonID AS CommonID
		, CAST(DD.Date AS DATE) AS [Date]
		, CAST(R.RONAs AS INT) AS AvayaRONAs
		, ISNULL(CAST(R.TTT AS INT),0) + ISNULL(CAST(R2.TTT AS INT),0) AS TotalTalkTime
		, ISNULL(CAST(R2.StaffTime AS INT),0) + ISNULL(CAST(R.StaffTime AS INT),0) AS StaffTime
		, CAST(R.TotalAuxTime AS INT)/86400.0 AS TotalAuxTime
		, CAST(R.AvailTime AS INT)/86400.0 AS AvailTime
		, CAST(R.InboundCalls AS INT) AS InboundCalls
		, EM.FullNameFirstLast
		, EM.ADAccount
		, EM.OpsTeamLeader
		, EM.OpsDirector
		, D.StatusCount AS SC
		, D.[ESC SC] AS [escSC]
		, D.[OME SC] AS [omeSC]
		, D.[Non-OME SC] AS [offlineSC]
		, D.DistinctLoans AS DLs
		, D.ConfirmedCalls AS CC
		, A.Answered
		, A.MissedOpp
		, A.CTIRONA
		, A.OutboundCalls
		, S.Surveys
		, S.FoursandFives
		, S.SumSurveyScore
		, WHF.HrsWorked

FROM QLODS.dbo.EmployeeMaster EM
	--LEFT JOIN BICommon.TeamMember.SpecialtyGroupDim SGD WITH (NOLOCK) ON SGD.SpecialtyGroupID = EM.SpecialtyGrpID
	CROSS JOIN QLODS.dbo.DateDim DD WITH (NOLOCK)
	
	LEFT JOIN (
				SELECT   
					 TMD.EmployeeDimID
					,WHF.[WorkDateID]
					,SUM(WHF.[MinutesWorked])/60.00 AS HrsWorked
				FROM [BICommon].[WorkHour].[TeamMemberWorkHourFact] WHF WITH (NOLOCK)
					LEFT JOIN BICommon.WorkHour.TimeCodeDim TID WITH (NOLOCK) ON TID.TimeCodeDimID = WHF.TimeCodeDimID
					LEFT JOIN BICommon.TeamMember.TeamMemberDim TMD WITH (NOLOCK) ON TMD.TeamMemberID = WHF.TeamMemberID
				WHERE TID.TimeCodeDesignation IN ('IO', 'OT', 'Reg')
					AND WHF.WorkDateID BETWEEN @StartDtID AND @EndDtid
					AND WHF.IsActive = 1
				GROUP BY TMD.EmployeeDimID,WHF.WorkDateID
			) WHF ON WHF.EmployeeDimID = EM.EmployeeDimID 
			AND WHF.WorkDateID = DD.DateID

	LEFT JOIN #ResultsMDX R ON EM.CommonID = CAST(R.CommonID AS INT) 
		AND CAST(R.Date AS DATE) = DD.Date
	LEFT JOIN #ResultsMDX2 R2 ON EM.CommonID = CAST(R2.CommonID AS INT) 
		AND CAST(R.Date AS Date) = CAST(R2.Date AS Date)
	LEFT JOIN #DltScDcr D ON EM.CommonID = D.CommonID 
		AND D.StatusDtID = DD.DateID                                                         
	LEFT JOIN #AnsweredCalls A ON EM.CommonID = A.CommonID 
		AND DD.DateID = A.StartDateID
	LEFT JOIN #SurveyResults S ON EM.CommonID = S.CommonID AND DD.Date = S.Date

WHERE 1=1
	AND DD.DateID BETWEEN @StartDtID AND @EndDtID
	--AND SGD.Description LIKE '%hunt%'
	--AND EM.Team = 'Client Experience'
	AND EM.OpsDirector IN ('Jason Halliday', 'Ryan Meyers')
	AND EM.JOBTITLE IN ('PC Hunt Client Care Spec', 'Exec Hunt CCS')




/*
DROP TABLE #ResultsMDX
DROP TABLE #DltScDcr
DROP TABLE #AnsweredCalls
DROP TABLE #SurveyResults
DROP TABLE #ResultsMDX2
*/
