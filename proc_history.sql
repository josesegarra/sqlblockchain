

DROP PROCEDURE IF EXISTS  [dbo].[do];
GO
CREATE PROCEDURE [dbo].[do](@tsource nvarchar(500))
AS
BEGIN
	set nocount on
	--- Let's declare some names that will be used all around
	declare @prefix  nvarchar(20)='HISTORY_'																	                        			-- Prefix for TIME TRAVEL objects and columns
	declare @table  nvarchar(500)=(SELECT PARSENAME(@tsource, 1))												                        			-- NAME of the table in TSOURCE
	declare @tschema  nvarchar(500)=(SELECT PARSENAME(@tsource, 2))												                        			-- SCHEMA in TSOURCE
	declare @hpk nvarchar(500)=QUOTENAME(@prefix+'_PK'+@table)													                        			-- PRIMARY KEY INDEX IN SHADOW_TABLE
	declare @htable nvarchar(500)=QUOTENAME(@prefix+@table)														                        			-- SHADOW TABLE NAME

	-- Let´s create a @FIELDS variable with fields that the SHADOW TABLE will need
	DECLARE @Fields TABLE (wName nvarchar(200),wType nvarchar(200),wIndex nvarchar(200),wOrder nvarchar(10),wShadow int)                          	-- COLUMN NAME + TYPE + INDEX + ORDER if INDEX + SHADOW OR ORIGINAL 

    -- Insert into @FIELDS the fields specific to a SHADOW table
    insert into @Fields(wName,wType,wIndex,wOrder,wShadow)
    SELECT a1,a2,a3,a4,a5 FROM (VALUES
		(QUOTENAME(@prefix+'ID'),QUOTENAME('BIGINT')+' IDENTITY(1,1) NOT NULL','@','ASC',1),															-- ID of the ROW in the SHADOW table
   	    (QUOTENAME(@prefix+'STAMP'),QUOTENAME('DateTime')+' DEFAULT(GetDate())','@','ASC',1),														-- CREATION TIMESTAMP of the ROW in the SHADOW table
   	    (QUOTENAME(@prefix+'ACTION'),QUOTENAME('NVARCHAR')+'(1) NOT NULL','@','ASC',1),																-- What ACTION happened in the ORIGINAL TABLE: (A: Initial append, I: Insert, D: Delete, R: Update)
   	    (QUOTENAME(@prefix+'HASH'),QUOTENAME('VARBINARY')+'(64)',null,'',1),																		-- HASH Of the DATA making up this ROW in the SHADOW TABLE
   	    (QUOTENAME(@prefix+'SIGNATURE'),QUOTENAME('VARBINARY')+'(64)',null,'',1)																	-- current_row(SIGNATURE) = current_row(HASH)+previous_row(SIGNATURE)
    ) K(a1,a2,a3,a4,a5)

    -- Insert into @FIELDS the fields from the SOURCE table (aka: data fields)
	insert into @Fields(wName,wType,wIndex,wOrder,wShadow)
	SELECT QUOTENAME(C.COLUMN_NAME),																												-- This just fetches the fields for @schema.@table from the INFORMATION_SCHEMA 
		   C.DATA_TYPE+iif(lower(C.DATA_TYPE)='xml' or C.CHARACTER_MAXIMUM_LENGTH is null,'',
				IIF(C.CHARACTER_MAXIMUM_LENGTH =-1,'(MAX)',
				'('+CONVERT(NVARCHAR(MAX),C.CHARACTER_MAXIMUM_LENGTH)+')')) CLENGTH, 
			(select iif(a.is_primary_key=1,'@',a.name) from sys.indexes a where a.object_id=d.object_id and a.index_id=d.index_id),
			isnull(D.DIR,''),0	
	FROM INFORMATION_SCHEMA.COLUMNS C 
	OUTER APPLY (
		select iif(b.is_descending_key=0,' ASC',' DESC') AS DIR,b.object_id,b.index_id 
        from sys.index_columns AS b 
        WHERE b.object_id = OBJECT_ID(@tsource) and QUOTENAME(COL_NAME(b.object_id,b.column_id))=QUOTENAME(C.COLUMN_NAME)
	) D
	WHERE C.TABLE_NAME = @table and C.TABLE_SCHEMA = isnull(@tschema,C.TABLE_SCHEMA)

	-- Create HISTORY TABLE
	DECLARE @LINES TABLE (line nvarchar(max))

    insert into @lines select 'DROP TABLE IF EXISTS '+@htable                                                                           			-- DROP TABLE IF EXISTED BEFORE
	insert into @lines select 'CREATE TABLE '+@htable+'('                                                                               			-- CREATE TABLE
	insert into @lines(line) 																														-- WITH THE REQUIRED FIELDS (DISTINCT as a FIELD can appear more than ONCE if PRESENT IN DIFFERENT INDEXES)
		select string_agg(k.n+' '+k.t+',',CHAR(13))  WITHIN GROUP (ORDER BY k.s desc,k.n) from 														
			(select distinct wName,wType,wShadow from @fields) k(n,t,s) 
	insert into @lines(line) 
        select isnull('CONSTRAINT '+@hpk+' PRIMARY KEY CLUSTERED ('+STRING_AGG(wName+' '+wOrder,' , ')+')' ,'') from @fields where wIndex='@'		-- INCLUDE A PRIMARY KEY CONSTRAINT
	insert into @lines select ') '

    insert into @lines 
	select 'CREATE NONCLUSTERED INDEX '+QUOTENAME(@prefix+'IDX_'+wIndex)+' ON '+@htable+' ('+string_agg(wName+' '+wOrder,',')+')'       			-- CREATE THE INDEXES THAT WHERE PRESENT IN SOURCE TABLE
	from @fields where wIndex is not null and wIndex<>'@' group by wIndex

	declare @s nvarchar(max)=(select string_agg(line,CHAR(13)) from @lines)
	exec(@s)
	print CONVERT( VARCHAR(24), GETDATE(), 121)+' *********** Created   HISTORY TABLE:         '+@htable 


	--- Make sure that HISTORY TABLE cannot be modified easily
	delete from @lines
	declare @trLock nvarchar(500)=QUOTENAME(@prefix+'TR_LOCK_'+@table)											                        			-- ONLY INSERTS ARE ALLOWED IN HISTORY TABLE		
	insert into @lines(line)  SELECT  ' '
	insert into @lines(line)  SELECT  'CREATE OR ALTER TRIGGER '+@trLock+' ON '+@htable+'INSTEAD OF UPDATE,DELETE AS BEGIN'							-- Create a trigger in HISTORY_TABLE
	insert into @lines(line)  SELECT  '   RAISERROR( ''History tables cannot be modified'', 16, 1 )'												-- Throwing an error if data is modified or deleted
	insert into @lines(line)  SELECT  '   ROLLBACK TRANSACTION'
	insert into @lines(line)  SELECT  'END'
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	exec(@s)
	print CONVERT( VARCHAR(24), GETDATE(), 121)+' *********** Locked    HISTORY TABLE:         '+@htable +' with TRIGGER '+@trLock


	-- Populate HISTORY TABLE
	declare @hash  nvarchar(20)='''SHA2_256'''																	                        			-- Hash function to use
	declare @tableFULL  nvarchar(500)=iif(@tschema is null or @tschema='','',@tschema+'.')+@table				                        			-- SCHEMA + NAME of the table in TSOURCE
	declare @tfields nvarchar(max)=
		(select string_agg(k.n,',')  WITHIN GROUP (ORDER BY k.n) from (select distinct wName from @fields where wShadow=0) as k(n))					-- Data fields in SOURCE table

	declare @dohash nvarchar(max)=REPLACE(																											-- This is the expression to calculate a ROW HASH		
		'UPDATE a set a.#HASH=HashBytes('+@hash  +','+CHAR(13)+
		'                   (SELECT #ID,#STAMP,#ACTION,'+@tfields+' FROM '+@htable+' b where b.#ID=a.#ID  FOR XML RAW,BINARY BASE64) '+CHAR(13)+ 
		') FROM '+@htable+'  a where a.#HASH is null; '+CHAR(13),'#', @prefix)
	
	declare @dosignature nvarchar(max)= REPLACE(																									-- This is the expression to calculate PENDING SIGNATURES
		'WITH bchain(#ID,SIGNEDVAL) AS ( '+CHAR(13)+
		'    select TOP 1 #ID,CONVERT(VARBINARY(64),a.#SIGNATURE) from {T} a where #SIGNATURE IS NOT NULL ORDER BY #ID DESC '+char(13)+
		'    union all select b0.#ID,CONVERT(VARBINARY(64),HASHBYTES('+@hash+',b0.#HASH+b1.SIGNEDVAL)) '+char(13)+
		'    from {T} b0 inner join bchain b1 on b0.#ID=(b1.#ID+1)) '+char(13)+
		'    update tab set tab.#SIGNATURE=bchain.SIGNEDVAL from {T} tab '+char(13)+
		'    inner join bchain on tab.#ID = bchain.#ID where tab.#SIGNATURE is null ','#', @prefix)

	delete from @lines
	insert into @lines(line)  																														-- Query that will POPULATE SHADOW table from SOURCE (and init STAMP, ACTION and ID fields)
		select 'insert into '+@htable+'('+QUOTENAME(@prefix+'ACTION')+','+@tfields+') SELECT ''A'','+@tfields+' FROM '+@tableFULL			
	insert into @lines(line) select @dohash  																										-- Query that sets initial HASHES for the just populated SHADOW ROWS
	insert into @lines(line)  																														-- Query that sets SIGNATURE for the FIRST ROW
		select 'update '+@htable+' set '+@prefix+'SIGNATURE='+@prefix+'HASH where '+@prefix+'ID=1 and '+@prefix+'SIGNATURE is null;'+CHAR(13)
	insert into @lines(line)  select REPLACE(@dosignature,'{T}',@htable)																			-- Query that recursively updates SIGNATURE for rows without signature

	set @s=(select string_agg(line,CHAR(13)) from @lines)
	exec(@s)
	SET @s = 'SELECT @cnt=COUNT(*) FROM '+@htable
	EXECUTE sp_executesql @s, N'@cnt VARCHAR(50) OUTPUT', @cnt = @s OUTPUT
	print CONVERT( VARCHAR(24), GETDATE(), 121)+' *********** Populated HISTORY TABLE:         '+@htable +' with '+@s+' records'

	-- Create INSERT trigger
	declare @trInsert nvarchar(500)=QUOTENAME(@prefix+'ITR_'+@table)											                        		-- INSERT TRIGGER NAME		

	delete from @lines
	insert into @lines(line)  select 'CREATE OR ALTER TRIGGER '+@trInsert+' ON '+@tableFULL+' FOR INSERT AS BEGIN ';
	insert into @lines(line)  select 'SET NOCOUNT ON; ';
	insert into @lines(line)  select 'insert into '+@htable+'('+QUOTENAME(@prefix+'ACTION')+','+@tfields+') SELECT ''I'','+@tfields+' FROM INSERTED ';
	insert into @lines(line) select @dohash 
	insert into @lines(line) select 'update '+@htable+'  set '+@prefix+'SIGNATURE='+@prefix+'HASH where '+@prefix+'ID=1 and '+@prefix+'SIGNATURE is null;'+CHAR(13)
	insert into @lines(line) select REPLACE(@dosignature,'{T}',@htable)	
	insert into @lines(line) select 'END'
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	exec(@s)
	print CONVERT( VARCHAR(24), GETDATE(), 121)+' *********** Created INSERT TRIGGER in:       '+@htable +' as '+@trInsert


	print CONVERT( VARCHAR(24), GETDATE(), 121)+' '
end
GO
exec do @tsource='Authors'																	                        			-- Prefix for TIME TRAVEL objects and columns
exec do @tsource='Loans'																	                        			-- Prefix for TIME TRAVEL objects and columns
exec do @tsource='Readers'																	                        			-- Prefix for TIME TRAVEL objects and columns


/*
declare @DelayLength char(8)= '00:00:05'  
set @DelayLength='00:00:0'+cast(Cast(RAND()*(9-3)+3 as int) as varchar(1))
PRINT (CONVERT( VARCHAR(24), GETDATE(), 121))+' deleting user1 and user2 in Readers and wait for '+@DelayLength
delete from readers where name='User1' or name='User2' 
--WAITFOR DELAY @DelayLength

set @DelayLength='00:00:0'+cast(Cast(RAND()*(9-5)+5 as int) as varchar(1))
PRINT (CONVERT( VARCHAR(24), GETDATE(), 121))+' adding user1 in Readers and wait for '+@DelayLength
insert into readers([Name]) select 'User1'
--WAITFOR DELAY @DelayLength

PRINT (CONVERT( VARCHAR(24), GETDATE(), 121))+' adding user2 in Readers'
insert into readers([Name]) select 'User2'
PRINT 'Completed'
*/
