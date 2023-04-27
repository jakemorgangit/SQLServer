/*
This SQL code declares several variables and tables and uses a cursor to iterate through all user databases except for the tempdb. 
For each database, it retrieves the size information of all tables using the stored procedure sp_spaceused and inserts it into a table variable @TV.
It also retrieves the schema and table name information from the sys.tables and sys.schemas system tables and inserts it into another table variable @TV3. The two table variables @TV and @TV3 are joined on the table name and schema name to get the fully qualified table names along with their size information for each database.
The results are then inserted into another table variable @TV2 that includes the database name along with the table name, row count, reserved space, data size, index size, and unused space. Finally, the results from @TV2 are displayed in ascending order of database name and descending order of row count.
This SQL code is useful in providing an estimate of the space used by each table in a database and identifying tables that may have excessive unused space. This information can be used to monitor the growth of a database and identify tables that may require optimization.
*/

DECLARE @DBName varchar(200)
DECLARE @CMD varchar(max)
DECLARE @TV TABLE ( name_table varchar(500),ROWSCOUNT int, reserveder varchar(50), datasize varchar(50), indexsize varchar(50), unused varchar(50))
DECLARE @TV2 TABLE ( DBName varchar(200),name_table varchar(500),ROWSCOUNT int, reserveder varchar(50), datasize varchar(50), indexsize varchar(50), unused varchar(50))
DECLARE @TV3 TABLE ( DBName varchar(200),SchemaTAble varchar(500), TableName varchar(200))
DECLARE C Cursor for select quotename(name) as dbname from sys.databases where name <> 'tempdb'  and state = 0

OPEN C

FETCH NEXT FROM C INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM @TV3
    SET @CMD = 
    @DBName+'..sp_msforeachtable ''exec sp_spaceused [?]'''
    insert into @TV
    EXEC (@CMD)

    SET @CMD = 'select '''+@DBName+''' as DatabaseName, quotename(s.name)+''.''+quotename(t.name) as SchemaTable, quotename(t.name) TableName from '+@DBName+'.sys.tables t inner join '+@DBName+'.sys.schemas s on s.schema_id = t.schema_id '
    insert into @TV3
    EXEC (@CMD)

    insert into @TV2
    select @DBName ,t.name_table,t.ROWSCOUNT,t.reserveder,t.datasize,t.indexsize,t.unused from @TV t
    inner join @TV3 s on quotename(t.name_table) = s.TableName and s.DBName = @DBName

    FETCH NEXT FROM C INTO @DBNAME
END
CLOSE C
DEALLOCate C

select * from @TV2
order by 1, 3 desc
