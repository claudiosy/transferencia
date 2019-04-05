DECLARE @TotalWorkDays INT, @TotalTimeDiff DECIMAL(18, 2)
 
DECLARE @DateFrom DATETIME, @DateTo DATETIME;

SET @DateFrom = '2019-04-08 12:00';
SET @DateTo = '2019-04-08 23:00';

SET @TotalWorkDays = DATEDIFF(DAY, @DateFrom, @DateTo)
				    -(DATEDIFF(WEEK, @DateFrom, @DateTo) * 2)
					   -CASE
                                    WHEN DATENAME(WEEKDAY, @DateFrom) = 'Sunday'
                                    THEN 0
                                    ELSE 1
                                END+CASE
                                        WHEN DATENAME(WEEKDAY, @DateTo) = 'Saturday'
                                        THEN 0
                                        ELSE 1
                                    END;
SET @TotalTimeDiff =
(
    SELECT DATEDIFF(SECOND,
                   (
                       SELECT CONVERT(TIME, @DateFrom)
                   ),
                   (
                       SELECT CONVERT(TIME, @DateTo)
                   )) / 3600.0
);
 
 select DATENAME(WEEKDAY, @DateFrom)
 select DATENAME(WEEKDAY, @DateTo)

select @TotalWorkDays as dias

SELECT(@TotalWorkDays * 24.00) + @TotalTimeDiff as horas
 