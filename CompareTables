USE [msdb]
GO
CREATE PROCEDURE CompareTables
    @DB1 NVARCHAR(128),
    @DB2 NVARCHAR(128),
    @Schema NVARCHAR(128),
    @Table NVARCHAR(128),
    @PrimaryKey NVARCHAR(128) = NULL
/* 
Compares the same table of two different databases and reports on differences
Jake Morgan  V1 20230524

USAGE:
EXEC msdb.dbo.CompareTables @DB1 = 'Database1', @DB2 = 'Database2', @Schema = 'dbo', @Table = 'YourTable'

*/

AS
BEGIN
    -- Ensure Temp table is dropped before proceeding
    EXEC ('DROP TABLE ##Temp')

    -- If primary key is not specified, assume it's the first column
    IF @PrimaryKey IS NULL
    BEGIN
        DECLARE @sqlGetPrimaryKey NVARCHAR(MAX) = 
        'SELECT TOP 1 @PrimaryKeyOut = COLUMN_NAME 
         FROM ' + QUOTENAME(@DB1) + '.INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = ''' + @Schema + ''' AND TABLE_NAME = ''' + @Table + '''
         ORDER BY ORDINAL_POSITION'
        
        EXEC sp_executesql @sqlGetPrimaryKey, N'@PrimaryKeyOut NVARCHAR(128) OUTPUT', @PrimaryKey OUTPUT
    END

    -- Create the dynamic SQL query as before
    DECLARE @sql NVARCHAR(MAX)
    DECLARE @col NVARCHAR(MAX) = ''

    DECLARE @sqlGetColumns NVARCHAR(MAX) = 
    'SELECT 
        @colOut = COALESCE(@colOut + ''CASE WHEN J.['' + COLUMN_NAME + ''] <> P.['' + COLUMN_NAME 
           + ''] THEN '''''' + COLUMN_NAME + '': '''' + ISNULL(CONVERT(NVARCHAR(MAX), J.['' + COLUMN_NAME 
           + '']), ''''NULL'''') + '''' <> '''' + ISNULL(CONVERT(NVARCHAR(MAX), P.['' + COLUMN_NAME 
           + '']), ''''NULL'''') ELSE NULL END AS Diff'' + COLUMN_NAME + '', '', '''')
    FROM 
        ' + QUOTENAME(@DB1) + '.INFORMATION_SCHEMA.COLUMNS
    WHERE 
        TABLE_SCHEMA = ''' + @Schema + ''' AND TABLE_NAME = ''' + @Table + ''''

    EXEC sp_executesql @sqlGetColumns, N'@colOut NVARCHAR(MAX) OUTPUT', @col OUTPUT

    -- Remove the trailing comma
    SET @col = LEFT(@col, LEN(@col) - 1)

    -- Insert the results into a global temporary table
    SET @sql = 'SELECT ' + @col + ' 
                INTO ##Temp
                FROM ' + QUOTENAME(@DB1) + '.' + QUOTENAME(@Schema) + '.' + QUOTENAME(@Table) + ' AS J
                JOIN ' + QUOTENAME(@DB2) + '.' + QUOTENAME(@Schema) + '.' + QUOTENAME(@Table) + ' AS P
                ON J.' + QUOTENAME(@PrimaryKey) + ' = P.' + QUOTENAME(@PrimaryKey)

    EXEC sp_executesql @sql

    -- Define a table variable to hold non-null column names
    DECLARE @NotNullCols TABLE (ColumnName NVARCHAR(MAX))

    -- Get the names of non-null columns
    DECLARE @colName NVARCHAR(MAX)
    DECLARE @sqlCheckNull NVARCHAR(MAX)
    DECLARE @result INT

    DECLARE columnCursor CURSOR FOR
    SELECT COLUMN_NAME
    FROM TEMPDB.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = '##Temp'

    OPEN columnCursor

    FETCH NEXT FROM columnCursor INTO @colName

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sqlCheckNull = 'SELECT @result = COUNT(' + QUOTENAME(@colName) + ') FROM ##Temp WHERE ' + QUOTENAME(@colName) + ' IS NOT NULL'
        
        EXEC sp_executesql @sqlCheckNull, N'@result INT OUTPUT', @result OUTPUT
        
        IF @result > 0
            INSERT INTO @NotNullCols (ColumnName) VALUES (@colName)
            
        FETCH NEXT FROM columnCursor INTO @colName
    END

    CLOSE columnCursor
    DEALLOCATE columnCursor

    -- Create the dynamic SQL query to select only non-null columns
    DECLARE @sql2 NVARCHAR(MAX) = 'SELECT '
    DECLARE @col2 NVARCHAR(MAX) = ''

    SELECT @col2 = COALESCE(@col2 + QUOTENAME(ColumnName) + ', ', '')
    FROM @NotNullCols

    -- Remove the trailing comma
    IF LEN(@col2) > 0
    BEGIN
        SET @col2 = LEFT(@col2, LEN(@col2) - 1)
        SET @sql2 = @sql2 + @col2 + ' FROM ##Temp'
    END
    ELSE
        SET @sql2 = ''

    -- Execute the dynamic SQL query to select only non-null columns
    IF LEN(@sql2) > 0
        EXEC sp_executesql @sql2

    -- Drop the global temporary table
    IF OBJECT_ID('tempdb..##Temp') IS NOT NULL
        EXEC ('DROP TABLE ##Temp')
END
