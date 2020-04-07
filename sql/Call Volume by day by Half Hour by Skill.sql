SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #ResultsMDX
DROP TABLE IF EXISTS #callsByDay
DROP TABLE IF EXISTS #totalCalls

DECLARE @Server varchar(MAX) = 'ASQuerying2'
DECLARE @Catalog varchar(MAX) = 'Avaya'
DECLARE @EndDtID varchar(8) = 20180827
DECLARE @StartDtID varchar(8) = 20181006

DECLARE @MDX varchar(max) =
	'SELECT NON EMPTY { [Measures].[CALLSOFFERED] } ON COLUMNS
	, NON EMPTY { ([Date].[Date].[Date].ALLMEMBERS, [Time].[Time Dim].ALLMEMBERS ) } ON ROWS 
	FROM ( SELECT ( ({
	 [Skill].[SPLITNAME].&[189 - SchwabClosedLoansSrv]
    ,[Skill].[SPLITNAME].&[191 - Schwab HELOC]}) ) ON COLUMNS   
	FROM ( SELECT ( [Date].[Date].&['+CONVERT(VARCHAR(8),@StartDtID)+']:[Date].[Date].&['+CONVERT(VARCHAR(8),@EndDtID)+'] ) ON COLUMNS FROM [hCmsSkill])) '

			
CREATE TABLE #ResultsMDX ( 
		[Date] sql_variant,
		[Hour] sql_variant,
		 
		CallsOffered sql_variant
		)

INSERT INTO #ResultsMDX
EXEC    [Reporting].[dbo].[QueryAnalysisServices]
		@server = @server,
		@database = @catalog,
		@command = @MDX  


SELECT
  dd.[Date]
, dd.DayOfWeekName
, td.Time24 'TimeBucket'
, CAST(CallsOffered AS INT) 'CallsOffered'
INTO #callsByDay
FROM #ResultsMDX R
	INNER JOIN QLODS.dbo.DateDim dd WITH (NOLOCK) ON R.[Date] = dd.DayName2
		AND dd.[Year] > 2015
	INNER JOIN QLODS.dbo.TimeDim td WITH (NOLOCK) ON td.JulianTime = (CAST(R.[Hour] as INT) - 1)
WHERE 1=1
	AND R.[Hour] IS NOT NULL
	AND dd.DayOfWeekName NOT IN ('Saturday', 'Sunday')
	AND R.CallsOffered > 0

SELECT 
  #callsByDay.[Date]
, SUM(#callsByDay.CallsOffered) 'TotalCallsOffered'
INTO #totalCalls
FROM #callsByDay
GROUP BY #callsByDay.[Date]


SELECT
  #callsByDay.*
, #totalCalls.TotalCallsOffered
, CAST((1.0 * #callsByDay.CallsOffered) / #totalCalls.TotalCallsOffered AS float) 'PercentOfCalls'
FROM #callsByDay
	LEFT JOIN #totalCalls ON #totalCalls.[Date] = #callsByDay.[Date]
