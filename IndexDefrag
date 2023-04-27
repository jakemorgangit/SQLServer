/*
This SQL code is dynamically generating a script to check the fragmentation status of all indexes in a given database and then rebuild them using the ALTER INDEX statement with the ONLINE option set to ON.
The code is creating a SELECT statement that joins multiple system tables in the specified database to retrieve information about the indexes, including their fragmentation percentage, size, and type. It then creates an ALTER INDEX statement based on the retrieved data to rebuild the indexes with the ONLINE option, which allows the index to be rebuilt without locking the table.
The output of this query will list all indexes with their respective fragmentation status and a corresponding ALTER INDEX statement to rebuild them with the ONLINE option.
The variables used in the SQL code are:

    @SQL: a variable to store the dynamically generated SQL statement
    @@ServerName: a built-in variable that returns the name of the SQL Server instance
    @DatabaseName: a user-defined variable that specifies the name of the database to check
    @SampleMode: a user-defined variable that specifies the sampling mode to use for the physical index statistics
*/

select @SQL = 
'
select getdate(),
       ''' + @@ServerName + ''',
       ''' + @DatabaseName + ''',
       so.Name,
       si.Name,
       db_id(''' + @DatabaseName + '''),
       ips.object_id,
       ips.index_id,
       ips.index_type_desc,
       ips.alloc_unit_type_desc,
       ips.index_depth,
       ips.avg_fragmentation_in_percent,
       ips.fragment_count,
       avg_fragment_size_in_pages,
       ips.page_count,
       ips.record_count,
       case
         when ips.index_id = 0 then ''alter table [' + @DatabaseName + '].'' + ss.name + ''.['' + so.name + ''] rebuild with (online = on)''
         else ''alter index '' + si.name + '' on [' + @DatabaseName + '].'' + ss.name + ''.['' + so.name + ''] rebuild with (online = on)''
       end
  from sys.dm_db_index_physical_stats(db_id(''' + @DatabaseName + '''),null,null,null, ''' + @SampleMode + ''') ips
  join [' + @DatabaseName + '].sys.objects so  on so.object_id = ips.object_id
  join [' + @DatabaseName + '].sys.schemas ss  on ss.schema_id = so.schema_id
  join [' + @DatabaseName + '].sys.indexes si  on si.object_id = ips.object_id
                      and si.index_id  = ips.index_id
order by so.Name, ips.index_id
'

exec (@SQL)
