/********************************************************************************************************
Closing Message Board Post Report

This query is to show loans that had a CCS/SPS respond to a client from the previous day 

Dumps into Closing Message Board Post.xlsx
Located AmazeU Team Page 
		>> Traing Specialist 
		>> Tools and Resources
		>> CCS/PS Message Board Reports 

10.11.2017 -- Brandon Brewer -- Clean up code
10.23.2017 -- Brandon Brewer -- Add a variable for the previous business day
********************************************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @prevBusDate DATE =  GETDATE() + CASE DATEPART(WEEKDAY, GETDATE())
											WHEN 2 THEN -3
											WHEN 1 THEN -2
											ELSE -1
											END

DECLARE @prevBusStr VARCHAR(10) = CONCAT(Year(@prevBusDate), '-', MONTH(@prevBusDate), '-', DAY(@prevBusDate))


SELECT * FROM
(
	SELECT
	  T.LoanNumber
	, p.ThreadId
	, CASE WHEN A.createddate IS NULL THEN 'TM Post'   
		   WHEN A.fullnamefirstlast IS NULL THEN 'Client' 
		   ELSE 'Error' END 'Who Posted'
	, A.CreatedDate AS 'Client post date'
	, Em.FullNameFirstLast 'Hunt TM'
	, CONVERT(date, p.Createddate) AS d
	, p.createddate AS 'Hunt Response Date'
	, EM.opsdirector
	, Em.OpsDVP
	, CASE WHEN DATEDIFF(hour, A.createddate, P.createddate) > 24 THEN CONVERT(VARCHAR(5), DATEDIFF(day, A.createddate, P.createddate)) + ' days'
		   WHEN DATEDIFF(hour, A.createddate, P.createddate) IS NULL THEN 'No Client Post Time'
		   ELSE CONVERT(VARCHAR(2), datediff(minute, A.createddate, P.createddate)/60) + ':' + CONVERT(VARCHAR(2), (datediff(minute, A.createddate, P.createddate)%60)) + ' Hours' 
		   END AS 'time'

	FROM SRC.MessageBoard.Post P
		INNER JOIN SRC.MessageBoard.poster Pr ON Pr.posterid = P.PosterId
		LEFT JOIN QLODS..Employeemaster EM ON EM.commonid = Pr.PosterReferenceId
		INNER JOIN SRC.messageboard.Thread T ON T.ThreadId = P.ThreadId
		INNER JOIN QLODS..LKWD L ON L.loannumber = T.LoanNumber
		INNER JOIN QLODS..LoanPurposeDim LPD ON LPD.LoanPurposeID = L.LoanPurposeID
		INNER JOIN QLODS..LoanChannelDim LCD ON LCD.LoanChannelID = L.LoanChannelGroupID
		INNER JOIN Reporting..vwProductBuckets PBAT ON PBAT.ProductId = L.ProductID
		OUTER APPLY( 
					SELECT TOP 1 
						  EM2.FullNameFirstLast
						, P2.CreatedDate
						, P2.updateddate ---Finds the last time a client posted on the message board.
					FROM SRC.Messageboard.post P2
						INNER JOIN SRC.MessageBoard.poster PR2 ON PR2.PosterId = P2.posterid
						LEFT JOIN QLODS..employeemaster EM2 ON EM2.commonid =  PR2.PosterReferenceId
						INNER JOIN SRC.messageboard.thread T2 ON T2.ThreadId = P2.ThreadId
					WHERE 1=1 
						AND T2.loannumber = T.loannumber
						AND p.threadid = p2.threadid --same thread as the thread the TM posted on yesterday
						AND p2.createddate < p.CreatedDate 
						AND EM2.FullNameFirstLast IS NULL --client post
					ORDER BY p2.CreatedDate DESC) A
	
	WHERE 1=1
		AND EM.opsdvp like 'Rebecca Rosenberg' 
		OR Em.OpsDVP like 'Mylea Degoa'
) b ---subquery was to convert the createddate to a date rather than date time. 
					
WHERE b.d = @prevBusStr