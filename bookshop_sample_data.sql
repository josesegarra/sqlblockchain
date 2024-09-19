
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--- Create and populate Genres
DROP TABLE IF EXISTS [Genres]

CREATE TABLE [Genres](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED ([Id] ASC),
	CONSTRAINT [AK_CategoryName] UNIQUE NONCLUSTERED ([Name] ASC) 
) 

TRUNCATE TABLE [Genres]

INSERT INTO [Genres]([Name])
SELECT v FROM (VALUES 
	('Drama'),('Fable'),('Fairy Tale'),('Fantasy'),('Fiction'),('Folklore'),('Historical Fiction'),('Children'),
	('Horror'),('Comedy'),('Legend'),('Mystery'),('Mythology'),('Poetry'),('Realistic Fiction'),('Science Fiction'),
	('Short Story'),('Tall Tale'),('Biography'),('Essay'),('Narrative Nonfiction'),('Nonfiction'),('Speech')) K(v)


--- Create and populate Authors
DROP TABLE IF EXISTS [Authors]

CREATE TABLE [Authors](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](80) NOT NULL,
	CONSTRAINT [PK_Author] PRIMARY KEY CLUSTERED ([Id] ASC),
	CONSTRAINT [AK_AName] UNIQUE NONCLUSTERED ([Name] ASC)
)

TRUNCATE TABLE [Authors]

INSERT INTO [Authors]([name]) 
SELECT k.v FROM (VALUES
		('Aldous Huxley'),('Alice Sebold'),('Alice Walker'),('Anthony Burgess'),('Antoine de Saint-Exupéry'),
		('Arthur Golden'),('Audrey Niffenegger'),('Betty Smith'),('Bram Stoker'),('C.S. Lewis'),('Charles Dickens'),('Charlotte Brontë'),
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


--- Create and populate Books
DROP TABLE IF EXISTS [Books]

CREATE TABLE [Books](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GenreId] [int] NULL,
	[AuthorId] [int] NULL,
	[Title] [nvarchar](50) NOT NULL,
	[Price] [int] NOT NULL,
	[Attachment] [varbinary](max) NULL,
	[Content] [xml] NULL,
	CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED ([Id] ASC),
	CONSTRAINT [AK_Name] UNIQUE NONCLUSTERED ([Title] ASC)
) ON [PRIMARY] 

TRUNCATE TABLE [Books]

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


--- Create and populate Readers
DROP TABLE IF EXISTS [Readers]

CREATE TABLE [Readers](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](80) NOT NULL,
	CONSTRAINT [PK_Reader] PRIMARY KEY CLUSTERED ([Id] ASC),
	CONSTRAINT [AK_Reader] UNIQUE NONCLUSTERED ([Name] ASC)
)

TRUNCATE TABLE [Readers]

INSERT INTO [Readers]([name]) 
SELECT k.v FROM (VALUES
		('John Smith'),('Louise Cantu'),('Anakin Randall'),('Christina Clarke'),('Stetson Shaw'),
		('Emersyn Cook'),('Ezekiel Perry'),('Clara Delarosa'),('Osiris Hanna'),('Cynthia Lowe'),
		('Julius Raymond'),('Hadlee Frederick'),('Kase Adkins'),('Emelia Lozano'),('Boone Davis'),
		('Mia Montgomery'),('Maximiliano Wiley'),('Lauryn Morse'),('Bode West'),('Remi Galindo'),
		('Salvatore Schneider'),('Alice Soyun')) K(V)

--- Create and populate book
DROP TABLE IF EXISTS [Loans]

CREATE TABLE [Loans](
	[Book] [int] NOT NULL,
	[Reader] [int] NOT NULL,
	[Borrowed] [date] NOT NULL,
	[Returned] [date] NULL,
	CONSTRAINT [PK_Loans] PRIMARY KEY CLUSTERED ([Book],[Reader],[Borrowed] DESC)
)

CREATE NONCLUSTERED INDEX [IDX_LOAD_READER] ON [dbo].[Loans]
(
	[Reader] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]


TRUNCATE TABLE [Loans]

INSERT INTO [Loans]([Book],[Reader],[Borrowed],[Returned]) 
SELECT a1,a2,a3,a4 FROM (VALUES
		(1,2,'2022-10-01','2022-10-03'),
		(2,2,'2022-10-03',NULL),
		(3,2,'2022-10-04','2022-10-07'),
		(3,5,'2022-10-08','2022-10-10'),
		(3,3,'2022-10-12',NULL)
) K(a1,a2,a3,a4)
