/*****************************************************************************************
This query is to show loans that had a CCS/SPS respond to a client from the previous day 
*****************************************************************************************/
Set transaction isolation level read uncommitted

DROP TABLE IF EXISTS #bp
SELECT * INTO #bp
FROM
	(
	SELECT
		T.LoanNumber
		, T.ThreadId
		, CONVERT(date, p.Createddate) as d
		, p.CreatedDate
		, em.OpsDVP 'DVP' --the DVP at the time of p.CreatedDate
		, LPD.LoanPurpose
		, LCD.ChannelName
		, PBAT.ProductBucket
		, DATEDIFF(SECOND, A.CreatedDate, P.CreatedDate) 'Datediff'

	FROM SRC.MessageBoard.Post P
		INNER JOIN SRC.MessageBoard.poster Pr on Pr.posterid = P.PosterId
		LEFT JOIN QLODS.dbo.EmployeeMaster em ON em.CommonID = Pr.PosterReferenceId
		INNER JOIN SRC.messageboard.Thread T on T.ThreadId = P.ThreadId
		INNER JOIN QLODS..LKWD L on L.loannumber = T.LoanNumber
		INNER JOIN QLODS..LoanPurposeDim LPD on LPD.LoanPurposeID = L.LoanPurposeID
		INNER JOIN QLODS..LoanChannelDim LCD on LCD.LoanChannelID = L.LoanChannelGroupID
		INNER JOIN Reporting..vwProductBuckets PBAT on PBAT.ProductId = L.ProductID
		OUTER APPLY(
					SELECT TOP 1 
						  EM2.FullNameFirstLast
						, P2.CreatedDate
						, P2.updateddate ---Finds the last time a client posted on the message board.
					FROM SRC.Messageboard.post P2
						INNER JOIN SRC.MessageBoard.poster PR2 on PR2.PosterId = P2.posterid
						LEFT JOIN QLODS..employeemaster EM2 on EM2.commonid =  PR2.PosterReferenceId
						INNER JOIN SRC.messageboard.thread T2 on T2.ThreadId = P2.ThreadId
					WHERE 1=1
						AND T2.loannumber = T.loannumber
						AND p.threadid = p2.threadid --same thread as the thread the TM posted on yesterday
						AND p2.createddate < p.CreatedDate 
						AND EM2.FullNameFirstLast IS NULL --client post
					ORDER BY p2.CreatedDate desc
					) A
               
	WHERE EM.OpsTeamLeader like '%Adam Palmer%'
		OR EM.OpsTeamLeader like '%John Long%'
		OR EM.OpsTeamLeader like '%David Downs%'
		 --TM population we want
	) b ---subquery was to convert the createddate to a date rather than date time. 
                                  
WHERE b.d between '2017-10-01' and '2017-10-11'  --set date range of the create date




SELECT
#bp.LoanNumber
, #bp.ThreadId
, #bp.CreatedDate	'Created DateTime'
, #bp.d				'CreatedDate'
, #bp.DVP	
, #bp.LoanPurpose
, #bp.ChannelName
, #bp.ProductBucket
, #bp.Datediff		'ResponseTime'

FROM #bp
ORDER BY #bp.d ASC, #bp.LoanNumber
