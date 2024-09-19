ALTER PROCEDURE [dbo].[SetHistory](@tsource nvarchar(500))
AS
BEGIN
	set nocount on																																				-- Disable printing affected rows

	-- #############     INIT
	declare @prx	    nvarchar(30)='HISTORY_'																													-- Prefix to USE
	declare @hash       nvarchar(20)='''SHA2_256'''																												-- Hash function to use (QUOTED!!!)
	declare @table      nvarchar(500)=(SELECT PARSENAME(@tsource, 1))																							-- Name of the TABLE from TSOURCE
	declare @tschema    nvarchar(500)=(SELECT PARSENAME(@tsource, 2))																							-- Name of the SCHEMA from TSOURCE
	declare @tableFULL  nvarchar(500)=iif(@tschema is null or @tschema='','',@tschema+'.')+@table																-- Full NAME of TSOURCE
	declare @tTrigger   nvarchar(500)=QUOTENAME(@prx+'_TR_'+@table)																								-- Name of the data trigger in TSOURCE
	declare @htable     nvarchar(500)=QUOTENAME(@prx+@table)																									-- Name of the HISTORY table for TSOURCE		
	declare @hpk        nvarchar(500)=QUOTENAME(@prx+'_PK_'+@table)																								-- Primary KEY in HISTORY TABLE
	declare @hTrigger   nvarchar(500)=QUOTENAME(@prx+'_TRHIST_'+@table)																							-- Name of READONLY trigger in HISTORY TABLE
	
	declare @nTruncate	nvarchar(500)=@prx+'NOTRUNCATE'																										-- Name of TABLE to manage TRUNCATE
	declare @s			nvarchar(max)																															-- Generic purpose variable used all around
	DECLARE @LINES		TABLE (lId int identity(1,1),line nvarchar(max))																						-- Generic purpose table variable for dynamic SQL 
	DECLARE @LINES_H	TABLE (lId int identity(1,1),line nvarchar(max),lMark int default(0))																	-- Generic purpose table variable for dynamic SQL 
	
	--- ##############  Extract information from SOURCE TABLE
	declare @table_id int = OBJECT_ID(@tableFull)																												-- Object ID of the source table

	DECLARE @fields TABLE (cId int,cName nvarchar(max),cType nvarchar(max))																						-- @fields holds all columns and their types from source table
	insert into @fields(cId        ,cName  ,cType)																												--      Insert into @fields
	select              c.column_id,c.name ,QUOTENAME(t.name) +																									--      all the columns in the table
	case																																						--      and their type definition 
		when charindex(lower(t.name),'decimal|numeric')<>0	then '('+convert(nvarchar(10),c.precision)+','+ convert(nvarchar(10),c.scale)+')'					--		   decimal & numeric columns use precission and scale
		when charindex(lower(t.name),'char|nchar|binary|image')<>0 then '('+convert(nvarchar(10),c.max_length)+')'												--		   char|nchar|binary|image have a fixed size
		when charindex(lower(t.name),'varchar|varbinary')<>0 then '('+iif(c.max_length=-1,'max',convert(nvarchar(10),c.max_length))+')'							--		   varchar|varbinary can fixed size or MAX
		when charindex(lower(t.name),'nvarchar')<>0 then '('+iif(c.max_length=-1,'max',convert(nvarchar(10),c.max_length/2))+')'								--		   nvarchar size is twice capacity -> UTF16
		else ''																																					--		   all other types have no modifiers
	end
	from sys.columns c INNER JOIN sys.types t ON c.user_type_id = t.user_type_id 
	WHERE c.object_id = @table_id

	declare @maxl1 int=(select 6+max(len(n)) from (select cname from @fields union select 'HISTORY_SIGNATURE') k(n))											-- @maxl1 is a padding value for pretty printing field names
	declare @maxl2 int=3+(select max(len(ctype)) from @fields)																									-- @maxl2 is a padding value for pretty printing type definition
	declare @padstr nvarchar(max)= REPLICATE(' ', @maxl1+@maxl2)																								-- Just a padding string

	DECLARE @indexes TABLE (cName nvarchar(max),cKind int,cId int)																								-- @indexes holds all indexes from source table 
	insert into			@indexes(cName ,cKind           ,cId)																									--      Populate @indexes
	select						 i.name,i.is_primary_key,ic.column_id																							--      with all indexes and their columns
	from				sys.index_columns ic inner JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id								--      notice that @fields.cId matches the @indexes.cId
	where				ic.object_id=@table_id																													--      for the source table

	if ((select count(*) from @indexes where cKind=1)=0) RAISERROR( 'Missing PRIMARY KEY in SOURCE', 16, 1 );													-- Make sure that table has a Primary Key


	--- ##############  Create HISTORY TABLE
	insert into @fields(cId,cName,cType) select    -30,'HISTORY_ID'        ,left(QUOTENAME('BIGINT')          +@padstr,@maxl2)+' IDENTITY(1,1) NOT NULL'		-- Additional field in HISTORY TABLE
	insert into @fields(cId,cName,cType) select    -19,'HISTORY_STAMP'     ,left(QUOTENAME('DATETIME')        +@padstr,@maxl2)+' NOT NULL'						-- Additional field in HISTORY TABLE
	insert into @fields(cId,cName,cType) select    -18,'HISTORY_ACTION'    ,left(QUOTENAME('NVARCHAR')+'(1)'  +@padstr,@maxl2)+' NOT NULL'						-- Additional field in HISTORY TABLE
	insert into @fields(cId,cName,cType) select	100000,'HISTORY_HASH' 	   ,left(QUOTENAME('VARBINARY')+'(64)'+@padstr,@maxl2)+' NOT NULL'						-- Max NUMBER of columns in SQL is 30,000. So no clash !!
	insert into @fields(cId,cName,cType) select	100001,'HISTORY_SIGNATURE' ,left(QUOTENAME('VARBINARY')+'(64)'+@padstr,@maxl2)+' NOT NULL'						-- Max NUMBER of columns in SQL is 30,000. So no clash !!		

	insert into @lines(line) SELECT  ' '
	insert into @lines(line) select  'DROP TABLE IF EXISTS '+@htable+';'																						-- Drop any previous HISTORY TABLE
	insert into @lines(line) select  'CREATE TABLE '+@htable+'('																								-- Create HISTORY TABLE
	insert into @lines(line) select  '    '+left(QUOTENAME(cName)+@padstr,@maxl1) +cType +',' FROM    @fields order by cId										-- With same fields as SOURCE table +  ADDITIONAL		
	insert into @lines(line) SELECT  '    CONSTRAINT '+@hpk+' PRIMARY KEY CLUSTERED ('																			-- And a PRIMARY KEY made of:
	insert into @lines(line) SELECT  '                       '+left(QUOTENAME('HISTORY_ID')+@padstr,@maxl1)+' ASC'												--		HISTORY_ID
	insert into @lines(line) SELECT  '                      ,'+left(QUOTENAME('HISTORY_STAMP')+@padstr,@maxl1)+' ASC'											--		HISTORY_STAMP
	insert into @lines(line) SELECT  '                      ,'+left(QUOTENAME('HISTORY_ACTION')+@padstr,@maxl1)+' ASC'											--		HISTORY_ACTION		
	insert into @lines(line) SELECT  '                      ,'+left(QUOTENAME(f.cName)+@padstr,@maxl1)+' ASC'													--		and whatever fields were PRIMARY KEY in source table
							 FROM    @indexes ic inner join @fields f on f.cId=ic.cId where ic.cKind=1
	insert into @lines(line) SELECT  '   ))'
	
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	
	--exec s_print @text =@s
	print '1. Creating table '+@htable+', dropping previous version if needed'
	exec(@s)
	delete from @lines
	
	--- ##############  Make sure that HISTORY TABLE cannot be modified easily
	insert into @lines(line)  SELECT  ' '
	insert into @lines(line)  SELECT  'CREATE TRIGGER '+@hTrigger+' ON '+@htable+'INSTEAD OF UPDATE,DELETE AS BEGIN'											-- Create a trigger in HISTORY_TABLE
	insert into @lines(line)  SELECT  '   RAISERROR( ''History tables cannot be modified'', 16, 1 )'															-- Throwing an error if data is modified or deleted
	insert into @lines(line)  SELECT  '   ROLLBACK TRANSACTION'
	insert into @lines(line)  SELECT  'END'
	insert into @lines(line)  SELECT  '        '
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	--exec s_print @text =@s
	print '2. Making '+@htable+' write only'
	exec(@s)
	delete from @lines



	--- ##############  Delete previous trigger in SOURCE TABLE
	insert into @lines(line) SELECT  ' '
	insert into @lines(line) SELECT 'DROP TRIGGER IF EXISTS '+@tTrigger																							-- If trigger exists then delete it
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	--exec s_print @text =@s
	print '3. Deleting if exists trigger '+@tTrigger
	exec(@s)
	delete from @lines


	--- ##############  Create TRIGGER IN SOURCE TABLE
	insert into @lines(line) SELECT  ' '
	--insert into @lines(line) SELECT  'set nocount on'
	insert into @lines(line)   SELECT 'CREATE TRIGGER '+@tTrigger+' ON '+@tableFULL+' FOR UPDATE,INSERT,DELETE AS BEGIN'										-- Create the trigger
	insert into @lines(line)   SELECT '  SET NOCOUNT ON'																										-- We don´t want messages
	insert into @lines(line)   SELECT '  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE					        '												-- Make this trigger as atomic as possible'
	insert into @lines(line)   SELECT '  	 declare @action nvarchar(1)=''U''									'                                               -- Assume this is an UPDATE operation
	insert into @lines(line)   SELECT '  	 if ((select count(*) from inserted)=0) set @action=''D''           '												-- Unless it is a DELETE
	insert into @lines(line)   SELECT '  	 if ((select count(*) from deleted)=0) set @action=''I''            '												-- Or INSERT

	

	insert into @lines_H(line)   SELECT '  	 DECLARE @NOW DATETIME=GetDate()									'												-- Timestamp of the operation
	insert into @lines_H(line)   SELECT '  	 DECLARE @LOCAL TABLE(												'												-- @local is an intermediate table to compute blockchain
	insert into @lines_H(line)   SELECT '               '+left(QUOTENAME(cName)+@padstr,@maxl1)+cType+',' FROM   @fields where cid<100001 order by cid			-- It has the same fields as HISTORY except SIGNATURE
	insert into @lines_H(line)   SELECT '              CHECK (1=1) ) '																							-- This CHECK is just syntax sugar to accept the [comma] in the last field
	insert into @lines_H(line)   SELECT ' '
	insert into @lines_H(line)   SELECT '  	 --  Store into @local the changes to SOURCE table. Notice that HISTORY_ID>=1 and HASH calculation  '
	insert into @lines_H(line)   SELECT '  	 INSERT INTO @local( '																								-- Let´s insert into @local
	insert into @lines_H(line)   SELECT '               '+QUOTENAME(cName)+iif(cid<>100000,',','') from @fields where cId>-20 and cid<100001 order by cId			-- 
	insert into @lines_H(line)   SELECT '              ) '
	insert into @lines_H(line)   SELECT '      SELECT                '
	insert into @lines_H(line)   SELECT '                @now,       '																							-- The fields from STAMP 
	insert into @lines_H(line)   SELECT '                @action,    '																							-- The ACTION
	insert into @lines_H(line)   SELECT '                '+QUOTENAME(cName)+',' from @fields where cId>=0 and cid<100000 order by cId								-- The fields from SOURCE
	insert into @lines_H(line)   SELECT '                HashBytes('+@hash+', '																					-- And a HASH
	insert into @lines_H(line)   SELECT '                          (SELECT  @action as '+QUOTENAME('action')														--		of ACTION
	insert into @lines_H(line)   SELECT '                                  ,@now    as '+QUOTENAME('stamp')														--		of STAMP		
	insert into @lines_H(line)   SELECT '                                  ,'+QUOTENAME(cName) FROM   @fields where cId>=0 and cid<100000 order by cId			--		and all the other fields
	insert into @lines_H(line)   SELECT '                           FOR XML RAW,BINARY BASE64))  '
    insert into @lines_H(line)   SELECT '      FROM ('																											-- Changes come from INSERTED or DELETED depending on the ACTION
	insert into @lines_H(lmark,line)   SELECT 1,'            select * from INSERTED union all select * from deleted where @action=''D''    '							-- Changes come from INSERTED or DELETED depending on the ACTION
	insert into @lines_H(line)   SELECT '      ) as data_changed '																								-- Changes come from INSERTED or DELETED depending on the ACTION
	
	insert into @lines_H(line)   SELECT ' '
	insert into @lines_H(line)   SELECT '  	 --- Calculate SIGNATURE for every row in @local, using HASH of current record and HASH of previous record '
    insert into @lines_H(line)   SELECT '  	 --- if there is no previous record we will use the VARBINARY value of GENESIS_RECORD '
    insert into @lines_H(line)   SELECT '  	 ;WITH bchain(CHAIN_ID,SIGNEDVAL) AS '
    insert into @lines_H(line)   SELECT '  	 ( '
    insert into @lines_H(line)   SELECT '  	 SELECT convert(bigint,0),    -- For root record in bchain CHAIN_ID=0 '
	insert into @lines_H(line)   SELECT '		        isnull                -- For root record in bchain SIGNEDVAL is either last signature in HISTORY TABLE or CONVERT(VARBINARY(64),GENESIS_RECORD)'
	insert into @lines_H(line)   SELECT '		        (   '
	insert into @lines_H(line)   SELECT '		           (SELECT top 1 CONVERT(VARBINARY(64),a.HISTORY_SIGNATURE) FROM '+@htable+' a WITH (TABLOCKX) ORDER BY HISTORY_ID DESC) '
  	insert into @lines_H(line)   SELECT '		          ,CONVERT(VARBINARY(64),''GENESIS_RECORD'')'
	insert into @lines_H(line)   SELECT '		         ) '
  	insert into @lines_H(line)   SELECT '      UNION ALL '
	insert into @lines_H(line)   SELECT '		           select	b0.HISTORY_ID,          -- For not root records in bchain -> CHAIN_ID=@local.HISTORY_ID '
	insert into @lines_H(line)   SELECT '		           	        CONVERT(VARBINARY(64),  -- For not root records in bchain -> SIGNEDVAL =SHA2_256(@local.HISTORY_HASH + bchain.SIGNEDVAL of previous record) '
	insert into @lines_H(line)   SELECT '		           	        HASHBYTES('+@hash+',b0.HISTORY_HASH+b1.SIGNEDVAL)) '
  	insert into @lines_H(line)   SELECT '		           	        from   @LOCAL b0 inner join bchain b1 on b0.HISTORY_ID=(b1.CHAIN_ID+1) '
	insert into @lines_H(line)   SELECT '		 )'
	insert into @lines_H(line)   SELECT '		 INSERT INTO '+@hTable+'('
	insert into @lines_H(line)   SELECT '               '+QUOTENAME(cName)+iif(cid<>100001,',','') from @fields where cId>-20 order by cId			-- 
	insert into @lines_H(line)   select '			  )'
	insert into @lines_H(line)   SELECT '		 SELECT'
	insert into @lines_H(line)   SELECT '               l.'+QUOTENAME(cName)+',' FROM   @fields where cid>-30 and cid<100001 order by cid 
	insert into @lines_H(line)   select '               c.'+QUOTENAME('SIGNEDVAL')
	insert into @lines_H(line)   select '	 FROM     @local as l '
	insert into @lines_H(line)   select '	 INNER    JOIN bchain as c on c.CHAIN_ID=l.HISTORY_ID'  
	insert into @lines_H(line)   select '	 ORDER    BY l.[HISTORY_ID]  '

	insert into @lines(line) select line from @lines_h order by lId
	insert into @lines(line)   select 'END'+char(13)+'   '
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	--exec s_print @text =@s
	print '4. Creating trigger '+@tTrigger+' to audit '+quotename(@tableFULL)

	exec(@s)
	delete from @lines

	
	
	--- ##############  Populating target table
	insert into @lines(line)   SELECT '  	 DECLARE @ACTION	NVARCHAR(1)=''C''									'											-- Action is C -> create
	update @lines_H set line='select * from '+@tableFULL where lMark=1																							-- Our source table IS whole table
	insert into @lines(line) select line from @lines_h order by lId
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	print '5. Populating '+@htable+' with data from '+@tableFULL
	--exec s_print @text =@s
	exec(@s)
	delete from @lines
	
	
	--- ########## Making sure HISTORY_NOTRUNCATE exists
	insert into @lines(line)   SELECT 'IF NOT EXISTS(SELECT 1 FROM sys.Tables WHERE  Name ='''+@nTruncate +''' AND Type = ''U'') BEGIN '
	insert into @lines(line)   SELECT '      CREATE TABLE '+@nTruncate +'([TABLES] [nvarchar](MAX) NULL)';
	insert into @lines(line)   SELECT 'END'      
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	print '6. Creating if needed table '+@nTruncate
	--exec s_print @text =@s
	exec(@s)
	delete from @lines

	--- ########## Making sure HISTORY_NOTRUNCATE exists
	-- Max Number of columns in PK is 32, so we are safe	https://docs.microsoft.com/en-us/sql/sql-server/maximum-capacity-specifications-for-sql-server
	insert into @lines(line) SELECT  'ALTER TABLE '+@nTruncate +' DROP CONSTRAINT IF EXISTS '+@nTruncate+'_FK_'+@table
	insert into @lines(line) SELECT  'ALTER TABLE '+@nTruncate +' DROP COLUMN IF EXISTS '+QUOTENAME(@prx+@table+'_'+f.cName) 
							 FROM @indexes ic inner join @fields f on f.cId=ic.cId where ic.cKind=1 order by f.cName
	
	insert into @lines(line) SELECT  'ALTER TABLE '+@nTruncate +' ADD '+QUOTENAME(@prx+@table+'_'+f.cName)+' '+f.cType 
							 FROM @indexes ic inner join @fields f on f.cId=ic.cId where ic.cKind=1 order by f.cName
	
	insert into @lines(line) SELECT  'ALTER TABLE '+@nTruncate +' ADD CONSTRAINT '+@nTruncate+'_FK_'+@table
	insert into @lines(line) SELECT  '    FOREIGN KEY ('
	insert into @lines(line) SELECT  '                   '+string_agg(QUOTENAME(@prx+@table+'_'+f.cName),',')  WITHIN GROUP ( ORDER BY f.cName asc ) 
							 FROM @indexes ic inner join @fields f on f.cId=ic.cId where ic.cKind=1 
	insert into @lines(line) SELECT  '    ) REFERENCES '+@tableFull+'('
	insert into @lines(line) SELECT  '                   '+string_agg(QUOTENAME(f.cName),',')  WITHIN GROUP ( ORDER BY f.cName asc ) 
							 FROM @indexes ic inner join @fields f on f.cId=ic.cId where ic.cKind=1 
	insert into @lines(line) SELECT  '    )'
	
	
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	print '7. Adding FOREIGN KEY in '+@nTruncate+' to table '+@tableFull
	--exec s_print @text =@s
	exec(@s)
	delete from @lines

	
	--- ########## Creating HF table function
	declare @hfunc nvarchar(500)=QUOTENAME('HF_'+@table)
	insert into @lines(line) SELECT  'DROP FUNCTION IF EXISTS '+@hfunc
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	print '8. Deleting function'+@hfunc+' if needed '
	--exec s_print @text =@s
	exec(@s)
	delete from @lines

	insert into @lines(line) select 'CREATE FUNCTION '+@hfunc+'(@d4 datetime) RETURNS TABLE'
	insert into @lines(line) select 'AS RETURN'
	insert into @lines(line) select 'SELECT '
	insert into @lines(line) SELECT '        '+string_agg(QUOTENAME('T0')+'.'+QUOTENAME(f.cName),',') WITHIN GROUP ( ORDER BY f.cName asc ) FROM @fields f where f.cID>=0 and f.cId<100000
	insert into @lines(line) select 'FROM '+@htable+' T0 '
	insert into @lines(line) select 'INNER JOIN'
	insert into @lines(line) select '    ( SELECT MAX(HISTORY_ID) H  FROM '+@htable+' '
	insert into @lines(line) select '	   WHERE HISTORY_STAMP<@d4 GROUP BY '
	insert into @lines(line) SELECT  '                   '+string_agg(QUOTENAME(f.cName),',')  WITHIN GROUP ( ORDER BY f.cName asc ) 
							 FROM @indexes ic inner join @fields f on f.cId=ic.cId where ic.cKind=1 
	insert into @lines(line) SELECT  '   ) K '
	insert into @lines(line) select '		on K.H=T0.HISTORY_ID WHERE T0.HISTORY_ACTION<>''D'''
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	--exec s_print @text =@s
	print '9. Creating function'+@hfunc
	exec(@s)
	delete from @lines


	--- ########## Creating VF table function
	declare @vfunc nvarchar(500)=QUOTENAME('VF_'+@table)
	insert into @lines(line) SELECT  'DROP FUNCTION IF EXISTS '+@vfunc
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	print '10. Deleting function'+@vfunc+' if needed '
	--exec s_print @text =@s
	exec(@s)
	delete from @lines

	insert into @lines(line) SELECT  'CREATE FUNCTION '+@vfunc+'() RETURNS TABLE AS RETURN '
	insert into @lines(line) SELECT '( '
	insert into @lines(line) SELECT '    select T0.'+QUOTENAME('HISTORY_ID')+',''Missing hash'' as [ERROR_MSG] from '+@htable+' T0 where T0.HISTORY_HASH is null '
	insert into @lines(line) SELECT '    UNION '
	insert into @lines(line) SELECT '    select T0.'+QUOTENAME('HISTORY_ID')+',''Missing signature'' from '+@htable+'  T0 where T0.HISTORY_SIGNATURE is null '
    insert into @lines(line) SELECT '    UNION '
    insert into @lines(line) SELECT '    select T0.'+QUOTENAME('HISTORY_ID')+',''Inconsistent hash in row'' from '+@htable+' T0 where T0.HISTORY_HASH<> '
	insert into @lines(line) SELECT '		HashBytes('+@hash+','
	insert into @lines(line) SELECT '                          (SELECT  HISTORY_ACTION as '+QUOTENAME('action')														--		of ACTION
	insert into @lines(line) SELECT '                                  ,HISTORY_STAMP  as '+QUOTENAME('stamp')														--		of STAMP		
	insert into @lines(line) SELECT '                                  ,'+QUOTENAME(cName) FROM   @fields where cId>=0 and cid<100000 order by cId			--		and all the other fields
	insert into @lines(line) SELECT '                           FOR XML RAW,BINARY BASE64))  '
    insert into @lines(line) SELECT '    UNION '
    insert into @lines(line) SELECT '    select T0.'+QUOTENAME('HISTORY_ID')+',''Missing previous signature'' FROM '+@htable+' T0 '
	insert into @lines(line) SELECT '    left join '+@htable+' T1 ON T1.HISTORY_ID=T0.HISTORY_ID-1 where T1.HISTORY_ID is null and T0.HISTORY_ID>1 '
	insert into @lines(line) SELECT '    UNION '
    insert into @lines(line) SELECT '    select T0.'+QUOTENAME('HISTORY_ID')+',''Inconsistent signature'' FROM '+@htable+' T0 where HISTORY_ID>1 and '
    insert into @lines(line) SELECT '    T0.HISTORY_SIGNATURE<>CONVERT(VARBINARY(64),HASHBYTES('+@hash+','
	insert into @lines(line) SELECT '                    T0.HISTORY_HASH+isnull( (SELECT T1.HISTORY_SIGNATURE FROM '+@htable+' T1 where T1.HISTORY_ID=T0.[HISTORY_ID]-1),0)'
	insert into @lines(line) SELECT '                    ))'
	insert into @lines(line) SELECT ')'
	set @s=(select string_agg(CONVERT(NVARCHAR(max),line),CHAR(13)) within group (order by lId) from @lines)
	exec s_print @text =@s


	/*

	



	declare @vfunc nvarchar(500)=QUOTENAME('VF_'+@table)




	-- To create the TIME query


	-- To create the TAMPERING query
	exec('DROP FUNCTION IF EXISTS '+@vfunc)
	delete from @lines
	insert into @lines(line) select 'CREATE FUNCTION '+@vfunc+'() RETURNS TABLE'
	insert into @lines(line) select 'AS RETURN'
	insert into @lines(line) select '('
	insert into @lines(line) select '   select T0.[HISTORY_ID],''Missing hash'' as [ERROR_MSG] from '+@htable+' T0 where T0.HISTORY_HASH is null'
	insert into @lines(line) select '   UNION '
	insert into @lines(line) select '   select T0.[HISTORY_ID],''Missing signature'' from '+@htable+'  T0 where T0.HISTORY_SIGNATURE is null '
	insert into @lines(line) select '   UNION '
	insert into @lines(line) select '   select T0.[HISTORY_ID],''Inconsistent hash in row'' from '+@htable+' T0 where T0.HISTORY_HASH<> '
	insert into @lines(line) select '   	HashBytes('+@hash+', '
	insert into @lines(line) select '   			(SELECT HISTORY_STAMP,HISTORY_ACTION,'+REPLACE(@tfields_pre,'#.','T1.') 
	insert into @lines(line) select '   			   from '+@htable+' T1 where T1.HISTORY_ID  = T0.HISTORY_ID  FOR XML RAW,BINARY BASE64)'
	insert into @lines(line) select '		)' 
	insert into @lines(line) select '   UNION '
	insert into @lines(line) select '   select T0.[HISTORY_ID],''Inconsistent signature'' FROM '+@htable+'  T0 where id>1 and '
	insert into @lines(line) select '        T0.HISTORY_SIGNATURE<>CONVERT(VARBINARY(64), '
	insert into @lines(line) select '   		    HASHBYTES('+@hash+',T0.HISTORY_HASH+(SELECT T1.HISTORY_SIGNATURE FROM '+@htable+' T1 where T1.HISTORY_ID=T0.[HISTORY_ID]-1)))'	
	insert into @lines(line) select ')'

	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print '----------------------------- Creating Verification function: '+@vfunc
	print @s
	exec(@s)
	*/
end
