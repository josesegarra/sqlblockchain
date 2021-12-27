USE [TimeMachine]
GO
/****** Object:  Table [dbo].[HISTORY_Books]    Script Date: 2021-05-20 15:18:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HISTORY_Books](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[HISTORY_STAMP] [datetime] NOT NULL,
	[HISTORY_ACTION] [nvarchar](1) NOT NULL,
	[HISTORY_HASH] [varbinary](64) NULL,
	[HISTORY_SIGNATURE] [varbinary](64) NULL,
	[Id] [int] NOT NULL,
	[GenreId] [int] NULL,
	[AuthorId] [int] NULL,
	[Title] [nvarchar](50) NULL,
	[Price] [int] NULL,
	[Attachment] [varbinary](max) NULL,
	[Content] [xml] NULL,
 CONSTRAINT [HISTORY_PKBooks] PRIMARY KEY CLUSTERED 
(
	[Id] ASC,
	[HISTORY_ID] ASC,
	[HISTORY_STAMP] ASC,
	[HISTORY_ACTION] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[HF_Books]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[HF_Books]() RETURNS TABLE
AS RETURN
(
select T0.[HISTORY_ID],'Missing hash' as [ERROR_MSG]		
from [HISTORY_Books] T0 where T0.HISTORY_HASH is null
UNION
select T0.[HISTORY_ID],'Missing signature' as [ERROR_MSG]		
from [HISTORY_Books] T0 where T0.HISTORY_SIGNATURE is null
UNION
select T0.[HISTORY_ID],'Inconsistent hash in row' 
from [HISTORY_Books] T0 where T0.HISTORY_HASH<>
		HashBytes('SHA2_256',
			(SELECT HISTORY_ID,HISTORY_STAMP,HISTORY_ACTION,T1.[Id],T1.[GenreId],T1.[AuthorId],T1.[Title],T1.[Price],T1.[Attachment],T1.[Content] 
			 FROM [HISTORY_Books] T1 where T1.HISTORY_ID  = T0.HISTORY_ID  FOR XML RAW,BINARY BASE64)
			) 
UNION
select T0.[HISTORY_ID],'Inconsistent signature'
FROM [HISTORY_Books] T0 where id>1 and
	T0.HISTORY_SIGNATURE<>
		CONVERT(VARBINARY(64),
			HASHBYTES('SHA2_256',T0.HISTORY_HASH+
				(SELECT T1.HISTORY_SIGNATURE FROM [HISTORY_Books] T1 where T1.HISTORY_ID=T0.[HISTORY_ID]-1)
			)	
		)
)
GO
/****** Object:  Table [dbo].[HISTORY_Authors]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HISTORY_Authors](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[HISTORY_STAMP] [datetime] NOT NULL,
	[HISTORY_ACTION] [nvarchar](1) NOT NULL,
	[HISTORY_HASH] [varbinary](64) NULL,
	[HISTORY_SIGNATURE] [varbinary](64) NULL,
	[Id] [int] NOT NULL,
	[Name] [nvarchar](80) NULL,
 CONSTRAINT [HISTORY_PKAuthors] PRIMARY KEY CLUSTERED 
(
	[Id] ASC,
	[HISTORY_ID] ASC,
	[HISTORY_STAMP] ASC,
	[HISTORY_ACTION] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[HF_Authors]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[HF_Authors](@d4 datetime) RETURNS TABLE
AS RETURN
select T0.[Id],T0.[Name] from [HISTORY_Authors] T0 INNER JOIN
(	select MAX(HISTORY_ID) H  from [HISTORY_Authors] 
		where HISTORY_STAMP<@d4 GROUP BY [Id]) K 
		on K.H=T0.HISTORY_ID WHERE T0.HISTORY_ACTION<>'D'
GO
/****** Object:  UserDefinedFunction [dbo].[VF_Authors]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[VF_Authors]() RETURNS TABLE
AS RETURN
(
   select T0.[HISTORY_ID],'Missing hash' as [ERROR_MSG] from [HISTORY_Authors] T0 where T0.HISTORY_HASH is null
   UNION 
   select T0.[HISTORY_ID],'Missing signature' from [HISTORY_Authors]  T0 where T0.HISTORY_SIGNATURE is null 
   UNION 
   select T0.[HISTORY_ID],'Inconsistent hash in row' from [HISTORY_Authors] T0 where T0.HISTORY_HASH<> 
   	HashBytes('SHA2_256', 
   			(SELECT HISTORY_ID,HISTORY_STAMP,HISTORY_ACTION,T1.[Id],T1.[Name]
   			   from [HISTORY_Authors] T1 where T1.HISTORY_ID  = T0.HISTORY_ID  FOR XML RAW,BINARY BASE64)
		)
   UNION 
   select T0.[HISTORY_ID],'Inconsistent signature' FROM [HISTORY_Authors]  T0 where id>1 and 
        T0.HISTORY_SIGNATURE<>CONVERT(VARBINARY(64), 
   		    HASHBYTES('SHA2_256',T0.HISTORY_HASH+(SELECT T1.HISTORY_SIGNATURE FROM [HISTORY_Authors] T1 where T1.HISTORY_ID=T0.[HISTORY_ID]-1)))
)
GO
/****** Object:  Table [dbo].[HISTORY_Genres]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HISTORY_Genres](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[HISTORY_STAMP] [datetime] NOT NULL,
	[HISTORY_ACTION] [nvarchar](1) NOT NULL,
	[Id] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
 CONSTRAINT [HISTORY_PKGenres] PRIMARY KEY CLUSTERED 
(
	[Id] ASC,
	[HISTORY_ID] ASC,
	[HISTORY_STAMP] ASC,
	[HISTORY_ACTION] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[HF_Genres]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[HF_Genres](@d4 datetime) RETURNS TABLE
AS RETURN
select T0.[Id],T0.[Name] from [HISTORY_Genres] T0 INNER JOIN
(	select MAX(HISTORY_ID) H  from [HISTORY_Genres] 
		where HISTORY_STAMP<@d4 GROUP BY [Id]) K 
		on K.H=T0.HISTORY_ID WHERE T0.HISTORY_ACTION<>'D'
GO
/****** Object:  Table [dbo].[Authors]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authors](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](80) NOT NULL,
 CONSTRAINT [PK_Author] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [AK_AName] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Books]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Books](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GenreId] [int] NULL,
	[AuthorId] [int] NULL,
	[Title] [nvarchar](50) NOT NULL,
	[Price] [int] NOT NULL,
	[Attachment] [varbinary](max) NULL,
	[Content] [xml] NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [AK_Name] UNIQUE NONCLUSTERED 
(
	[Title] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Genres]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Genres](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [AK_CategoryName] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LOG]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LOG](
	[TXT] [nvarchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[HISTORY_Authors] ADD  DEFAULT (getdate()) FOR [HISTORY_STAMP]
GO
ALTER TABLE [dbo].[HISTORY_Books] ADD  DEFAULT (getdate()) FOR [HISTORY_STAMP]
GO
ALTER TABLE [dbo].[HISTORY_Genres] ADD  DEFAULT (getdate()) FOR [HISTORY_STAMP]
GO
/****** Object:  StoredProcedure [dbo].[SampleData]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SampleData]
AS BEGIN
	exec [SetHistory] @tsource='Books' 
	exec [SetHistory] @tsource='Authors' 
	exec [SetHistory] @tsource='Genres' 
	exec [SampleDataCreate]
	exec [SampleDataSimulateTime]
END
GO
/****** Object:  StoredProcedure [dbo].[SampleDataBlobs]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SampleDataBlobs]
AS
BEGIN
	set nocount on
	-- Lets add some images
	UPDATE Books SET Attachment=(SELECT BulkColumn FROM OPENROWSET (BULK 'C:\J\Test1.pdf', SINGLE_BLOB) a) WHERE (Title= 'Brave New World')
	UPDATE Books SET Content=CONVERT(xml,(SELECT BulkColumn FROM OPENROWSET (BULK 'C:\J\Test1.xml', SINGLE_BLOB)a),2) WHERE (Title= 'Brave New World')

END
GO
/****** Object:  StoredProcedure [dbo].[SampleDataCreate]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SampleDataCreate]
AS
BEGIN
	set nocount on
	
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'HISTORY_Genres')  TRUNCATE	TABLE [HISTORY_Genres]
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'HISTORY_Books')   TRUNCATE	TABLE [HISTORY_Books]
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'HISTORY_Authors') TRUNCATE	TABLE [HISTORY_Authors]

	--- Populate Genres
	truncate table genres
	insert into genres(name)
	select v from (values ('Drama'),('Fable'),('Fairy Tale'),('Fantasy'),('Fiction'),('Folklore'),('Historical Fiction'),('Children'),
				('Horror'),('Comedy'),('Legend'),('Mystery'),('Mythology'),('Poetry'),('Realistic Fiction'),('Science Fiction'),
				('Short Story'),('Tall Tale'),('Biography'),('Essay'),('Narrative Nonfiction'),('Nonfiction'),('Speech')) K(v)
	--- Populate Authors
	truncate table Authors
	insert into Authors([name]) 
	select k.v from (values 
		('Aldous Huxley'),('Alice Sebold'),('Alice Walker'),('Anthony Burgess'),('Antoine de Saint-Exupéry'),('Arthur Golden'),
		('Audrey Niffenegger'),('Betty Smith'),('Bram Stoker'),('C.S. Lewis'),('Cassandra Clare'),('Charles Dickens'),('Charlotte Brontë'),
		('Cormac McCarthy'),('Dan Brown'),('Daphne du Maurier'),('Diana Gabaldon'),('Douglas Adams'),('Dr. Seuss'),('E.B. White'),
		('Emily Bronte'),('F. Scott Fitzgerald'),('Frances Hodgson Burnett'),('Frank Herbert'),('Fyodor Dostoyevsky'),('Gabriel García Márquez'),
		('George Orwell'),('George R.R. Martin'),('Harper Lee'),('Homer'),('J.D. Salinger'),('J.K. Rowling'),('J.R.R. Tolkien'),('Jane Austen'),
		('Jodi Picoult'),('John Green'),('John Steinbeck'),('Joseph Heller'),('Kathryn Stockett'),('Ken Follett'),('Ken Kesey'),('Khaled Hosseini'),
		('Kurt Vonnegut Jr.'),('L.M. Montgomery'),('Leo Tolstoy'),('Lewis Carroll'),('Lois Lowry'),('Louisa May Alcott'),('Madeleine L Engle'),
		('Margaret Atwood'),('Margaret Mitchell'),('Mark Twain'),('Markus Zusak'),('Mary Wollstonecraft Shelley'),('Maurice Sendak'),
		('Orson Scott Card'),('Oscar Wilde'),('Paulo Coelho'),('Ray Bradbury'),('Richard Adams'),('Rick Riordan'),('Roald Dahl'),
		('S.E. Hinton'),('Sara Gruen'),('Shel Silverstein'),('Stephen Chbosky'),('Stephen King'),('Stephenie Meyer'),('Stieg Larsson'),
		('Suzanne Collins'),('Sylvia Plath'),('Veronica Roth'),('Victor Hugo'),('Vladimir Nabokov'),('William Golding'),('William Goldman'),
		('William Shakespeare'),('Yann Martel')) K(V)

	--- Populate Books
	truncate table Books

	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'Brave New World',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Aldous Huxley')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Lovely Bones',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Alice Sebold')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'The Color Purple',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Alice Walker')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'A Clockwork Orange',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Anthony Burgess')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'The Little Prince',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Antoine de Saint-Exupéry')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'Memoirs of a Geisha',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Arthur Golden')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'The Time Traveler''s Wife',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Audrey Niffenegger')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'A Tree Grows in Brooklyn',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Betty Smith')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'Dracula',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Bram Stoker')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'The Chronicles of Narnia',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='C.S. Lewis')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Mystery'),'City of Bones',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Cassandra Clare')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'A Tale of Two Cities',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Charles Dickens')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Great Expectations',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Charles Dickens')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Dama'),'Jane EYre',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Charlotte Brontë')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'The Road',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Cormac McCarthy')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Mystery'),'The Da Vinci Code',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Dan Brown')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Mystery'),'Rebecca',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Daphne du Maurier')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'Outlander',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Diana Gabaldon')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'The Hitchhiker''s Guide to the Galaxy',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Douglas Adams')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Children'),'Green Eggs and Ham',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Dr. Seuss')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Children'),'Charlotte''s Web',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='E.B. White')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Wuthering Heights',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Emily Bronte')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Great Gatsby',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='F. Scott Fitzgerald')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Children'),'The Secret Garden',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Frances Hodgson Burnett')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'Dune',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Frank Herbert')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Crime and Punishment',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Fyodor Dostoyevsky')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Brothers Karamazov',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Fyodor Dostoyevsky')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'One Hundred Years of Solitude',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Gabriel García Márquez')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'Animal Farm',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='George Orwell')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'1984',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='George Orwell')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'A Game of Thrones - A Song of Ice and Fire',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='George R.R. Martin')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'To Kill a Mockingbird',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Harper Lee')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Legend'),'The Odyssey',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Homer')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Catcher in the Rye',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='J.D. Salinger')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'Harry Potter and the Order of the Phoenix',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='J.K. Rowling')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'Harry Potter and the Sorcerer''s Stone',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='J.K. Rowling')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'Harry Potter and the Deathly Hallows',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='J.K. Rowling')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'The Lord of the Rings',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='J.R.R. Tolkien')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'The Hobbit',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='J.R.R. Tolkien')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Pride and Prejudice',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Jane Austen')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'My Sister''s Keeper',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Jodi Picoult')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'The Fault in Our Stars',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='John Green')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'Of Mice and Men',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='John Steinbeck')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'Catch-22',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Joseph Heller')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'The Help',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Kathryn Stockett')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'The Pillars of the Earth (Kingsbridge, #1)',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Ken Follett')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Comedy'),'One Flew Over the Cuckoo''s Nest',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Ken Kesey')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Kite Runner',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Khaled Hosseini')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'A Thousand Splendid Suns',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Khaled Hosseini')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Comedy'),'Slaughterhouse-Five',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Kurt Vonnegut Jr.')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Anne of Green Gables',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='L.M. Montgomery')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Anna Karenina',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Leo Tolstoy')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'Alice''s Adventures in Wonderland',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Lewis Carroll')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Mistery'),'The Giver',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Lois Lowry')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Little Women',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Louisa May Alcott')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'A Wrinkle in Time ',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Madeleine L Engle')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'The Handmaid''s Tale',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Margaret Atwood')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Historical Fiction'),'Gone with the Wind',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Margaret Mitchell')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Adventures of Huckleberry Finn',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Mark Twain')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Book Thief',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Markus Zusak')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'Frankenstein: The 1818 Text',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Mary Wollstonecraft Shelley')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Children'),'Where the Wild Things Are',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Maurice Sendak')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'Ender''s Game',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Orson Scott Card')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Picture of Dorian Gray',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Oscar Wilde')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Alchemist',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Paulo Coelho')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'Fahrenheit 451',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Ray Bradbury')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Watership Down',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Richard Adams')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'Percy Jackson and the Olympians',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Rick Riordan')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Matilda',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Roald Dahl')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Outsiders',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='S.E. Hinton')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Water for Elephants',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Sara Gruen')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Giving Tree',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Shel Silverstein')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Perks of Being a Wallflower',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stephen Chbosky')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'The Stand',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stephen King')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'It',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stephen King')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'Christine',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stephen King')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'Carrie',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stephen King')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Horror '),'Twilight, #1',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stephenie Meyer')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Mistery'),'The Girl with the Dragon Tattoo (Millennium, #1)',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Stieg Larsson')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'The Hunger Games (The Hunger Games, #1)',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Suzanne Collins')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'The Bell Jar',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Sylvia Plath')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Science Fiction'),'Divergent, #1',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Veronica Roth')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Les Misérables',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Victor Hugo')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Lolita',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Vladimir Nabokov')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fiction'),'Lord of the Flies',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='William Golding')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Fantasy'),'The Princess Bride',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='William Goldman')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Romeo and Juliet',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='William Shakespeare')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Othello',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='William Shakespeare')
	insert into Books(GenreId,Title,Price,AuthorId) SELECT (select id from Genres where Name='Drama'),'Life of Pi',(40+CAST(RAND() * 100 AS INT)),(select id from Authors where Name='Yann Martel')

	-- Some changes to books
	UPDATE Books set title='A Song of Ice and Fire'				where  title='A Game of Thrones - A Song of Ice and Fire'
	UPDATE Books set title='The Pillars of the Earth'			where  title='The Pillars of the Earth (Kingsbridge, #1)'
	UPDATE Books set title='The Girl with the Dragon Tattoo'	where title='The Girl with the Dragon Tattoo (Millennium, #1)'
	UPDATE Books set title='The Hunger Games'					where title='The Hunger Games (The Hunger Games, #1)'
	UPDATE Books set title='Divergent'							where title='Divergent, #1'
	UPDATE Books set GenreId=(select id from Genres where Name='Mystery') where GenreId is null
	UPDATE Books set title='Jane Eyre'							where title='Jane EYre'


	UPDATE Authors set [Name]='Susan Eloise Hinton' where [Name]='S.E. Hinton' 
	UPDATE Authors set [Name]='Lucy Maud Montgomery' where [Name]='L.M. Montgomery'
	UPDATE Authors set [Name]='Jerome David Salinger' where [Name]='J.D. Salinger'
	UPDATE Authors set [Name]='Francis Scott Fitzgerald' where [Name]='F. Scott Fitzgerald'
	UPDATE Authors set [Name]='Joanne Kathleen Rowling' where [Name]='J.K. Rowling'
	UPDATE Authors set [Name]='John Ronald Reuel Tolkien' where [Name]='J.R.R. Tolkien'
	UPDATE Authors set [Name]='Clive Staples Lewis' where [Name]='C.S. Lewis'


	DELETE FROM Books where left(TITLE,1)='C'



END
GO
/****** Object:  StoredProcedure [dbo].[SampleDataSimulateTime]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SampleDataSimulateTime]
AS
BEGIN
	set nocount on
	declare @d1 datetime = datefromparts(2020,01,01)
	declare @d2 datetime = datefromparts(2020,06,30)
	declare @d3 datetime = datefromparts(2020,12,01)
	declare @d4 datetime = datefromparts(2021,01,01)
	declare @d5 datetime = datefromparts(2021,02,01)

	-- All genres where registered on 2020/01/01
	update HISTORY_Genres SET HISTORY_STAMP=@d1  

	-- All authors<M where registered on 2020/01/01
	update HISTORY_Authors set HISTORY_STAMP=@d1  where [Name]<'M' and HISTORY_ACTION='I' 

	-- All authors>=M where registered on 2020/06/30
	update HISTORY_Authors set HISTORY_STAMP=@d2 where [Name]>='M' and HISTORY_ACTION='I' 

	-- All books with author <M where registered on 2020/01/01
	UPDATE t1 SET t1.HISTORY_STAMP=@d1 FROM HISTORY_Books AS t1 INNER JOIN AUTHORS AS t2 ON t1.AuthorID= t2.ID where t1.HISTORY_ACTION='I' and t2.Name<'M'

	-- All books with author >M where registered on 2020/06/30
	UPDATE t1 SET t1.HISTORY_STAMP=@d2 FROM HISTORY_Books AS t1 INNER JOIN AUTHORS AS t2 ON t1.AuthorID= t2.ID  where t1.HISTORY_ACTION='I' and t2.Name>='M'

	-- All updates in Author names where done on 2020/12/01
	update HISTORY_Authors SET HISTORY_STAMP=@d3 where HISTORY_ACTION='U'  

	-- All updates in Books where done on 2021/01/01
	update HISTORY_Books SET HISTORY_STAMP=@d4 where HISTORY_ACTION='U'  

	-- All deletions in Books where done on 2021/02/01
	update HISTORY_Books SET HISTORY_STAMP=@d5 where HISTORY_ACTION='D'  

end

GO
/****** Object:  StoredProcedure [dbo].[SetHistory]    Script Date: 2021-05-20 15:18:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SetHistory](@tsource nvarchar(500))
AS
BEGIN
	set nocount on
	--- Some names we will need
	declare @hash  nvarchar(20)='''SHA2_256'''
	declare @table  nvarchar(500)=(SELECT PARSENAME(@tsource, 1))
	declare @tschema  nvarchar(500)=(SELECT PARSENAME(@tsource, 2))
	declare @tableFULL  nvarchar(500)=iif(@tschema is null or @tschema='','',@tschema+'.')+@table
	declare @trInsert nvarchar(500)=QUOTENAME('HISTORY_ITR_'+@table)
	declare @trDelete nvarchar(500)=QUOTENAME('HISTORY_DTR_'+@table)
	declare @trUpdate nvarchar(500)=QUOTENAME('HISTORY_UTR_'+@table)
	declare @htable nvarchar(500)=QUOTENAME('HISTORY_'+@table)
	declare @hpk nvarchar(500)=QUOTENAME('HISTORY_PK'+@table)
	declare @hfunc nvarchar(500)=QUOTENAME('HF_'+@table)
	declare @vfunc nvarchar(500)=QUOTENAME('VF_'+@table)

	
	-- This table holds Primary Key fields
	DECLARE @Keys TABLE (wKey nvarchar(max),wOrder nvarchar(10))
	insert into @Keys(wKey,wOrder)
			SELECT  QUOTENAME(COL_NAME(b.object_id,b.column_id)),iif(b.is_descending_key=0,' ASC',' DESC')
			FROM    sys.indexes AS a INNER JOIN sys.index_columns AS b ON a.object_id = b.object_id AND a.index_id = b.index_id
			WHERE	a.is_hypothetical = 0 AND	a.object_id = OBJECT_ID(@table)
			and a.name in (SELECT CONSTRAINT_NAME FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc WHERE tc.CONSTRAINT_TYPE = 'Primary Key' and tc.TABLE_NAME = @table and TABLE_SCHEMA = isnull(@tschema,TABLE_SCHEMA)) 
	-- Comma list of primary keys
	declare @tkeys nvarchar(max)=(SELECT string_agg(wKey,',') FROM @Keys)

	-- We want to add 2 additinonal keys !!
	insert into @Keys(wKey,wOrder) select QUOTENAME('HISTORY_ID'),' ASC'
	insert into @Keys(wKey,wOrder) select QUOTENAME('HISTORY_STAMP'),' ASC'
	insert into @Keys(wKey,wOrder) select QUOTENAME('HISTORY_ACTION'),' ASC'
	

	-- Let's do some preparation work and find out the fields that make our target table
	DECLARE @Fields TABLE (wName nvarchar(max))
	insert into @Fields(wname) 
		SELECT QUOTENAME(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @table and TABLE_SCHEMA = isnull(@tschema,TABLE_SCHEMA)
	declare @tfields nvarchar(max)=(SELECT string_agg(wName,',') FROM @Fields)
	declare @tfields_pre nvarchar(max)=(SELECT string_agg('#.'+wName,',') FROM @Fields)
	
	-- This table hold the dynamic SQL
	DECLARE @LINES TABLE (line nvarchar(max))

	-- Lets get the fields that make our table
	insert into @lines(line) 
			SELECT '        ,'+QUOTENAME(COLUMN_NAME)+' '+DATA_TYPE+
				case 
					when lower(DATA_TYPE)='xml' or CHARACTER_MAXIMUM_LENGTH is null then '' 
					when CHARACTER_MAXIMUM_LENGTH =-1  then '(MAX)' 
					else '('+CONVERT(NVARCHAR(MAX),CHARACTER_MAXIMUM_LENGTH)+')' end 
			FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @table and TABLE_SCHEMA = isnull(@tschema,TABLE_SCHEMA)

	declare @tfields_define  nvarchar(max)=(select string_agg(line,CHAR(13)) from @lines)

	-- Let's build the HISTORY TABLE
	delete from @lines
	insert into @lines select 'DROP TABLE IF EXISTS '+@htable
	insert into @lines select 'CREATE TABLE '+@htable+'('
	insert into @lines select '         '+QUOTENAME('HISTORY_ID')+'  '+QUOTENAME('INT')+' IDENTITY(1,1) NOT NULL'
	insert into @lines select '        ,'+QUOTENAME('HISTORY_STAMP')+'  '+QUOTENAME('DateTime')+' DEFAULT(GetDate())'
	insert into @lines select '        ,'+QUOTENAME('HISTORY_ACTION')+'     NVARCHAR(1) NOT NULL'
	insert into @lines select '        ,'+QUOTENAME('HISTORY_HASH')+'       VARBINARY(64) NULL'
	insert into @lines select '        ,'+QUOTENAME('HISTORY_SIGNATURE')+'  VARBINARY(64) NULL'
	insert into @lines select @tfields_define  
	

	-- PRIMARY KEY CONSTRAIN 
	insert into @lines(line) 
		SELECT  isnull(',CONSTRAINT '+@hpk+' PRIMARY KEY CLUSTERED ('+STRING_AGG(wKey+wOrder,' , ')+')' ,'') from @keys

	insert into @lines select ') '
		
	-- Create Indexes from ALL CONSTRAINS that ARE NON PRIMARY KEYS
	insert into @lines(line) 
			select 'CREATE NONCLUSTERED INDEX '+QUOTENAME('HISTORY_IDX_'+Iname)+' ON '+@htable+' ('+STRING_AGG(IField,',')+')'
			FROM
			(
			select name as IName,
					QUOTENAME(COL_NAME(b.object_id,b.column_id)) +iif(is_descending_key=0,' ASC',' DESC') IField
					FROM    sys.indexes AS a INNER JOIN sys.index_columns AS b ON a.object_id = b.object_id AND a.index_id = b.index_id 
					WHERE	a.is_hypothetical = 0 AND	a.object_id = OBJECT_ID(@table)
					and a.name not in (SELECT wKey from @keys)
					--CONSTRAINT_NAME FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc WHERE tc.CONSTRAINT_TYPE = 'Primary Key' and tc.TABLE_NAME =@table)
			) as k group by IName
	-- Prepare for triggers
	insert into @lines(line) select 'DROP TRIGGER IF EXISTS '+@trInsert+','+@trDelete+','+@trUpdate
	declare @s nvarchar(max)=(select string_agg(line,CHAR(13)) from @lines)
	
	print '----------------------------- Creating HISTORY TABLE: '+@htable 
	print @s
	exec(@s)

	--- HISTORY_ACTION
	--- A: row added in HISTORY table initialization
	--- I: row inserted in HISTORY table by trigger
	--- D: row deleted in HISTORY table by trigger
	--- U: row update in HISTORY table by trigger
	delete from @lines

	declare @definehash nvarchar(max)='update a set a.HISTORY_HASH=HashBytes('+@hash  +','+CHAR(13)+
				'                   (SELECT HISTORY_ID,HISTORY_STAMP,HISTORY_ACTION,'+@tfields+' FROM '+@htable+' b where b.HISTORY_ID  = a.HISTORY_ID  FOR XML RAW,BINARY BASE64) '+CHAR(13)+ 
				'     ) from '+@htable+'  a where a.HISTORY_HASH is null; '+CHAR(13)

	declare @signblocks nvarchar(max)='WITH bchain(HISTORY_ID,SIGNEDVAL) AS ( '+CHAR(13)+
							'    select TOP 1 HISTORY_ID,CONVERT(VARBINARY(64),a.HISTORY_SIGNATURE) from {T} a where HISTORY_SIGNATURE IS NOT NULL ORDER BY HISTORY_ID DESC '+char(13)+
							'    union all select b0.HISTORY_ID,CONVERT(VARBINARY(64),HASHBYTES('+@hash+',b0.HISTORY_HASH+b1.SIGNEDVAL)) '+char(13)+
							'    from {T} b0 inner join bchain b1 on b0.HISTORY_ID=(b1.HISTORY_ID+1)) '+char(13)+
							'    update tab set tab.HISTORY_SIGNATURE=bchain.SIGNEDVAL from   {T} tab '+char(13)+
							'    inner join bchain on tab.HISTORY_ID = bchain.HISTORY_ID where tab.HISTORY_SIGNATURE is null '



	print '----------------------------- Initial population of HISTORY TABLE: '+@tableFULL+' --> '+@htable 
	-- Now we are going to populate our history table
	insert into @lines(line)  select 'insert into '+@htable+'('+QUOTENAME('HISTORY_ACTION')+','+@tfields+') SELECT ''A'','+@tfields+' FROM '+@tableFULL
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print @s
	exec(@s)
	delete from @lines

	print '----------------------------- Creating BLOCKCHAIN for: '+@htable 
	-- Let's create a HASH with the data that has been entered
	insert into @lines(line)  select @definehash 
	-- Lets create signature for first row
	insert into @lines(line)  select 'update '+@htable+'  set HISTORY_SIGNATURE=HISTORY_HASH where HISTORY_ID=1 and HISTORY_SIGNATURE is null;'+CHAR(13)
	-- Lets sign the rest of rows
	insert into @lines(line)  select replace(@signblocks,'{T}',@htable)
	


	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print @s
	exec(@s)

	-- Create INSERT TRIGGER
	delete from @lines
	insert into @lines(line)  select 'CREATE TRIGGER '+@trInsert+' ON '+@tableFULL+' FOR INSERT AS BEGIN ';
	insert into @lines(line)  select 'SET NOCOUNT ON; ';
	insert into @lines(line)  select 'insert into '+@htable+'('+QUOTENAME('HISTORY_ACTION')+','+@tfields+') SELECT ''I'','+@tfields+' FROM INSERTED ';
	insert into @lines(line) select @definehash 
	insert into @lines(line) select 'update '+@htable+'  set HISTORY_SIGNATURE=HISTORY_HASH where HISTORY_ID=1 and HISTORY_SIGNATURE is null;'+CHAR(13)
	insert into @lines(line) select replace(@signblocks,'{T}',@htable)
	insert into @lines(line) select 'END'
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print '----------------------------- Creating trigger for INSERT: '+@trInsert
	print @s
	exec(@s)

	-- Create UPDATE TRIGGER
	delete from @lines
	insert into @lines(line) select 'CREATE TRIGGER '+@trUpdate+' ON '+@tableFULL+' FOR UPDATE AS BEGIN ';
	insert into @lines(line) select 'SET NOCOUNT ON; ';
	insert into @lines(line) select 'insert into '+@htable+'('+QUOTENAME('HISTORY_ACTION')+','+@tfields+') SELECT ''I'','+@tfields+' FROM INSERTED ';
	insert into @lines(line) select @definehash 
	insert into @lines(line) select 'update '+@htable+'  set HISTORY_SIGNATURE=HISTORY_HASH where HISTORY_ID=1 and HISTORY_SIGNATURE is null;'+CHAR(13)
	insert into @lines(line) select replace(@signblocks,'{T}',@htable)
	insert into @lines(line) select 'END'
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print '----------------------------- Creating trigger for UPDATE: '+@trUpdate
	print @s
	exec(@s)

	-- Create DELETE TRIGGER
	delete from @lines
	insert into @lines(line) select 'CREATE TRIGGER '+@trDelete+' ON '+@tableFULL+' FOR DELETE AS BEGIN ';
	insert into @lines(line) select 'SET NOCOUNT ON; ';
	insert into @lines(line) select 'insert into '+@htable+'('+QUOTENAME('HISTORY_ACTION')+','+@tfields+') SELECT ''D'','+@tfields+' FROM DELETED ';
	insert into @lines(line) select @definehash 
	insert into @lines(line) select 'update '+@htable+'  set HISTORY_SIGNATURE=HISTORY_HASH where HISTORY_ID=1 and HISTORY_SIGNATURE is null;'+CHAR(13)
	insert into @lines(line) select replace(@signblocks,'{T}',@htable)
	insert into @lines(line) select 'END'
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print '----------------------------- Creating trigger for DELETE: '+@trDelete
	print @s
	exec(@s)

	-- To create the TIME query
	exec('DROP FUNCTION IF EXISTS '+@hfunc)
	delete from @lines
	insert into @lines(line) select 'CREATE FUNCTION '+@hfunc+'(@d4 datetime) RETURNS TABLE'
	insert into @lines(line) select 'AS RETURN'
	insert into @lines(line) select 'select '+REPLACE(@tfields_pre,'#.','T0.') +' from '+@htable+' T0 INNER JOIN'
	insert into @lines(line) select '(	select MAX(HISTORY_ID) H  from '+@htable+' '
	insert into @lines(line) select '		where HISTORY_STAMP<@d4 GROUP BY '+@tkeys+') K '
	insert into @lines(line) select '		on K.H=T0.HISTORY_ID WHERE T0.HISTORY_ACTION<>''D'''
	set @s=(select string_agg(line,CHAR(13)) from @lines)
	print '----------------------------- Creating TIME function: '+@hfunc
	print @s
	exec(@s)


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
	insert into @lines(line) select '   			(SELECT HISTORY_ID,HISTORY_STAMP,HISTORY_ACTION,'+REPLACE(@tfields_pre,'#.','T1.') 
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


end

GO
