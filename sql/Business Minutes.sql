DECLARE @start AS datetime = '2017-07-10 08:00:00'
DECLARE @end AS datetime = '2017-07-11 20:01:00'

Select COUNT([Date Time])/60.0 'Business Hours'
	, COUNT([Date Time])/60 'Hours'
	, COUNT([Date Time])%60 'Minutes'
FROM [BISandboxWrite].[dbo].[JH_BusinessMinutes] BM
Where BM.[Date Time] BETWEEN @start AND @end
