SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @StartDateTime datetime = getdate()
DECLARE @EndDateTime datetime
DECLARE @Server varchar(max)
DECLARE @Catalog varchar(max)
DECLARE @EndDtID VARCHAR(8) = CONVERT(VARCHAR(8),getdate(),112)
DECLARE @StartDtID VARCHAR(8) 

SET  @StartDtID  = CONVERT(VARCHAR(8),DATEADD(Day,-7,getdate()),112) 

SELECT @Server = convert(NVARCHAR,ServerName)
		,@Catalog = convert(NVARCHAR,CatalogName)
FROM BIG.List.CubeServers
WHERE CubeServerID = 1 --Avaya Cube
	
--Create MDX Script holder
DECLARE @MDX varchar(max) =
	' SELECT NON EMPTY { [Measures].[OUTFLOWCALLS], [Measures].[ABNCALLS], [Measures].[CALLSOFFERED] } ON COLUMNS, 
		        NON EMPTY { ([Date].[Date].[Date].ALLMEMBERS, [Time].[Hour Name].[Hour Name].ALLMEMBERS,[Skill].[SPLITNAME].[SPLITNAME].AllMEMBERS  ) } ON ROWS 
	FROM ( SELECT ( [Date].[Date].&['+@StartDtID+']:[Date].[Date].&['+@EndDtID+']  )  ON COLUMNS 
	FROM ( SELECT (({[Skill].[SPLITNAME].&[162 - Lifesaver Purchase]
		,[Skill].[SPLITNAME].&[159 - Lifesaver Hunt]
		,[Skill].[SPLITNAME].&[152 - AZ Refi CCS]
		,[Skill].[SPLITNAME].&[154 - AZ PurchCCS]
		,[Skill].[SPLITNAME].&[156 - LS Schwab Purchase] 
		,[Skill].[SPLITNAME].&[158 - LS TMLoans Purchase]
		,[Skill].[SPLITNAME].&[160 - LifeSaverSchwabRefi]
		,[Skill].[SPLITNAME].&[421 - LS Refi DC]
		,[Skill].[SPLITNAME].&[421 - LS Refi Jaremba]
		,[Skill].[SPLITNAME].&[422 - LS Refi Hoener]
		,[Skill].[SPLITNAME].&[422 - LS RefiReferral HLBP]
		,[Skill].[SPLITNAME].&[423 - LS Refi Maynard]
		,[Skill].[SPLITNAME].&[424 - LS Refi TM Loans]
		,[Skill].[SPLITNAME].&[425 - LS Refi Recchia]
		,[Skill].[SPLITNAME].&[425 - LS Refi Halliday]
		,[Skill].[SPLITNAME].&[426 - LS Refi M Gray]}) ) ON COLUMNS FROM [hCmsSkill])) '
	

CREATE TABLE #ResultsMDX  
		([Date] sql_variant, 
		[Hour] sql_variant,
		Skill sql_variant,
		LeftSkill sql_variant,
		ABNCalls sql_variant,
		CallsOffered sql_variant
		)

	--Insert results of stored proc into temp table
INSERT INTO #ResultsMDX
EXEC    [Reporting].[dbo].[QueryAnalysisServices]
		@server = @server,
		@database = @catalog,
		@command = @MDX  


SELECT   CAST(R.DAte AS DATE) AS Date
		,CAST(R.Hour AS time(0)) AS Hour
		,CAST(R.Skill AS VARCHAR(30)) AS Skill
		,CAST(R.Leftskill AS INT) AS LeftSkill
		,CAST(R.ABNCalls AS INT) AS ABNCalls
		,CAST(R.CallsOffered AS INT) AS CallsOffered
FROM #ResultsMDX R
	
DROP TABLE #ResultsMDX