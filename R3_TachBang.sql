-------------------------------------------Tách bảng--------------------------
select * from [dbo].[AnimeData] 

--Tạo Anime
SELECT 
    AnimeID,       
    AnimeName, 
    Duration_min, 
    Synopsis, 
    Episodes, 
    AnimeStatus
INTO Anime
FROM AnimeData;
ALTER TABLE Anime
ADD CONSTRAINT PK_Anime PRIMARY KEY (AnimeID);

-- Tạo bảng Statistic
-- Tạo bảng Statistic từ bảng AnimeData
SELECT 
    IDENTITY(INT, 1, 1) AS StatisticID, 
    Ranking,
    Favorites,
    Score,
    Popularity,
    Members
INTO Statistic
FROM [dbo].[AnimeData];
-- Thiết lập StatisticID là khóa chính
ALTER TABLE Statistic
ADD CONSTRAINT PK_Statistic PRIMARY KEY (StatisticID);
-- Thêm cột StatisticID vào bảng Anime
ALTER TABLE [dbo].[Anime]
ADD StatisticID INT;
-- Câph nhật cột StatisticID trong bảng Anime
UPDATE [dbo].[Anime]
SET StatisticID = s.StatisticID
FROM [dbo].[AnimeData] a
JOIN Statistic s ON a.Ranking = s.Ranking 
                 AND a.Favorites = s.Favorites
                 AND a.Score = s.Score
                 AND a.Popularity = s.Popularity
                 AND a.Members = s.Members;
-- Thêm rảng buộc khoá ngoại cho cột StatisticID
ALTER TABLE [dbo].[Anime]
ADD CONSTRAINT FK_Anime_Statistic 
FOREIGN KEY (StatisticID) REFERENCES Statistic(StatisticID);

-- Tạo bảng Premiered
-- Tạo bảng Premiered và chèn dữ liệu từ bảng AnimeData
SELECT DISTINCT Premiered
INTO Premiered
FROM AnimeData
WHERE Premiered IS NOT NULL;
-- Thêm cột PremieredID tự động tăng làm khóa chính cho bảng Premiered
ALTER TABLE Premiered
ADD PremieredID INT IDENTITY(1,1) PRIMARY KEY;
-- Thêm cột PremieredID vào bảng Anime (chứa liên kết khóa ngoại đến bảng Premiered)
ALTER TABLE Anime
ADD PremieredID INT;
-- Cập nhật cột PremieredID trong bảng Anime từ bảng Premiered
UPDATE Anime
SET Anime.PremieredID = p.PremieredID
FROM AnimeData AS a
JOIN Premiered AS p ON a.Premiered = p.Premiered;
-- Thêm ràng buộc khóa ngoại để liên kết cột PremieredID của bảng Anime với bảng Premiered
ALTER TABLE [dbo].[Anime]
ADD CONSTRAINT FK_Anime_Premiered
FOREIGN KEY (PremieredID) REFERENCES [dbo].[Premiered](PremieredID);

-- Tạo bảng Rating
-- Tạo bảng Rating và chèn các giá trị Rating duy nhất từ AnimeData
SELECT DISTINCT Rating
INTO Rating
FROM AnimeData
WHERE Rating IS NOT NULL;
-- Thêm cột RatingID với giá trị tự tăng vào bảng vừa tạo
ALTER TABLE Rating
ADD RatingID INT IDENTITY(1,1) PRIMARY KEY;
-- Thêm cột RatingID vào bảng Anime
ALTER TABLE Anime
ADD RatingID INT;
-- Cập nhật giá trị của RatingID trong bảng Anime
UPDATE Anime
SET Anime.RatingID = r.RatingID
FROM AnimeData AS a
JOIN Rating AS r ON a.Rating = r.Rating;
-- Thêm khóa ngoại vào cột RatingID trong bảng Anime để tham chiếu đến RatingID trong bảng Rating
ALTER TABLE [dbo].[Anime]
ADD CONSTRAINT FK_Anime_Rating
FOREIGN KEY (RatingID) REFERENCES [dbo].[Rating](RatingID);

-- Tạo bảng AnimeType
-- Tạo bảng AnimeType và chèn các giá trị AnimeType duy nhất từ bang AnimeData
SELECT DISTINCT AnimeType
INTO AnimeType
FROM AnimeData
WHERE AnimeType IS NOT NULL;
-- Thêm cột AnimeTypeID với giá trị tự tăng vào bảng vừa tạo
ALTER TABLE AnimeType
ADD AnimeTypeID INT IDENTITY(1,1) PRIMARY KEY;
-- Thêm cột AnimeTypeID vào bảng Anime
ALTER TABLE Anime
ADD AnimeTypeID INT;
-- Cập nhật AnimeTypeID trong bảng AnimeData6 dựa trên giá trị AnimeType
UPDATE Anime
SET Anime.AnimeTypeID = b.AnimeTypeID
FROM AnimeData AS a
JOIN AnimeType AS b ON a.AnimeType = b.AnimeType;
-- Thêm ràng buộc khoá chính, khoá ngoại của Anime và AnimeType 
ALTER TABLE [dbo].[Anime]
ADD CONSTRAINT FK_Anime_AnimeType
FOREIGN KEY (AnimeTypeID) REFERENCES [dbo].[AnimeType](AnimeTypeID);

-- Tạo bảng Genres
CREATE TABLE Genres (
    GenresID INT IDENTITY(1,1) PRIMARY KEY,
    GenreName NVARCHAR(500) UNIQUE
);
-- Tách và chèn dữ liệu vào bảng Genres
;WITH GenreList AS (
    SELECT DISTINCT
        TRIM(value) AS GenreName
    FROM AnimeData
    CROSS APPLY STRING_SPLIT(Genres, ',')  
)
INSERT INTO Genres (GenreName)
SELECT GenreName FROM GenreList;
-- Tạo bảng Anime_genres
CREATE TABLE Anime_genres (
    AnimegenresID INT IDENTITY(1,1) PRIMARY KEY,
    AnimeID INT,
    GenresID INT,
    FOREIGN KEY (AnimeID) REFERENCES Anime(AnimeID),  -- Khóa ngoại đến bảng Anime
    FOREIGN KEY (GenresID) REFERENCES Genres(GenresID)     -- Khóa ngoại đến bảng Genres
);
-- Tách và chèn dữ liệu vào bảng Anime_genres
INSERT INTO Anime_genres (AnimeID, GenresID)
SELECT 
    a.AnimeID,
    g.GenresID
FROM AnimeData a
CROSS APPLY STRING_SPLIT(a.Genres, ',') AS splitGenres
JOIN Genres g ON TRIM(splitGenres.value) = g.GenreName;

----- Tạo bảng Studio
CREATE TABLE Studio (
    StudioID INT IDENTITY(1,1) PRIMARY KEY,
    StudioName NVARCHAR(255) UNIQUE
);
--
CREATE TABLE Anime_Studio (
    SXID INT IDENTITY(1,1) PRIMARY KEY,
    AnimeID INT, -- Khóa ngoại từ bảng Anime
    StudioID INT, -- Khóa ngoại từ bảng Studio
    FOREIGN KEY (AnimeID) REFERENCES Anime(AnimeID), 
    FOREIGN KEY (StudioID) REFERENCES Studio(StudioID)
);
--
;WITH StudioCTE AS (
    SELECT DISTINCT TRIM(value) AS StudioName
    FROM AnimeData
    CROSS APPLY STRING_SPLIT(Studio, ',') -- Tách studio
)
INSERT INTO Studio(StudioName)
SELECT StudioName
FROM StudioCTE;
--
INSERT INTO Anime_Studio (AnimeID, StudioID)
SELECT a.AnimeID, s.StudioID
FROM AnimeData a
CROSS APPLY (
    SELECT TRIM(value) AS StudioName
    FROM STRING_SPLIT(a.Studio, ',')
) AS temp
JOIN Studio s ON temp.StudioName = s.StudioName;

-- Cập nhật StatisticID
UPDATE Anime
SET StatisticID = s.StatisticID
FROM Anime AS ani
JOIN AnimeData AS a ON ani.AnimeID = a.AnimeID
JOIN Statistic AS s ON a.Ranking = s.Ranking 
                    AND a.Favorites = s.Favorites
                    AND a.Score = s.Score
                    AND a.Popularity = s.Popularity
                    AND a.Members = s.Members;