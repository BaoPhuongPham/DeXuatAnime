--Xem có bao nhiêu Trigger
SELECT name AS TriggerName
FROM sys.triggers
WHERE parent_id = OBJECT_ID('dbo.AnimeData');
DROP TRIGGER IF EXISTS Convert_Duration_Trigger;
-- Xem có bao nhiêu Procedure
SELECT name
FROM sys.objects
WHERE type = 'P';

DROP Procedure RemoveDuplicateRows;
--1. Xóa dòng trống 
CREATE PROCEDURE XoaDongTrong
AS
BEGIN
    -- Xóa các dòng có AnimeID nhưng tất cả các cột còn lại đều trống hoặc NULL
    DELETE FROM AnimeData
    WHERE 
        -- Cột AnimeName trống hoặc NULL
        (AnimeName IS NULL OR LTRIM(RTRIM(AnimeName)) = '');
END;
--Gọi thủ tục
EXEC XoaDongTrong;


--2.Xóa các khoảng trắng 
CREATE PROCEDURE XoaKhoangTrang
    @TableName NVARCHAR(255),  -- Tên bảng
    @ColuAnimeDataName NVARCHAR(255)  -- Tên cột cần loại bỏ khoảng trắng
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    -- Câu lệnh SQL động để cập nhật tất cả các bản ghi trong cột đã chỉ định và loại bỏ khoảng trắng ở đầu và cuối
    SET @SQL = N'UPDATE ' + @TableName + 
               ' SET ' + @ColuAnimeDataName + ' = LTRIM(RTRIM(' + @ColuAnimeDataName + '))';
    -- Thực thi câu lệnh SQL động
    EXEC sp_executesql @SQL;
END;
--Gọi thủ tục
EXEC XoaKhoangTrang
    @TableName = 'AnimeData',
    @ColuAnimeDataName = 'Studio';

--3. Chuyển đổi kiểu:
 --Chuyển Premiered từ Null, ? thành N/A
CREATE TRIGGER Clean_Trigger
ON [dbo].[AnimeData]
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE [dbo].[AnimeData]
    SET Premiered = 'N/A'
   -- Chỉ cập nhật bản ghi có thay đổi
    WHERE Premiered IS NULL OR Premiered = '?'
	AND AnimeID IN (SELECT AnimeID FROM INSERTED)
    UPDATE [dbo].[AnimeData]
    SET Studio = 'N/A'
    WHERE Studio IS NULL OR Studio = 'None found, add some'
	AND AnimeID IN (SELECT AnimeID FROM INSERTED)
 --Blanks của Epsido => chuyển về 1 tập.
    UPDATE [dbo].[AnimeData]
    SET Episodes = 1
    WHERE Episodes IS NULL
	AND AnimeID IN (SELECT AnimeID FROM INSERTED)
END;


UPDATE [dbo].[AnimeData]
SET Premiered = Premiered;
UPDATE [dbo].[AnimeData]
SET Studio = Studio;
UPDATE [dbo].[AnimeData]
SET Episodes = Episodes;


--6. Đổi Duration thành phút
-- Thêm cột mới: Duration_min
ALTER TABLE [dbo].[AnimeData]
ADD Duration_min Float;
-- Tạo trigger chuyển duration thành phút
CREATE TRIGGER Convert_Duration_Trigger
ON [dbo].[AnimeData]
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra mức độ lồng nhau của trigger
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;  -- Dừng trigger nếu nó đã bị gọi trong quá trình lồng nhau

    -- Chuyển các giá trị khác 'unknown' thành phút
    UPDATE [dbo].[AnimeData]
    SET Duration_min = 
        CASE 
            -- Trường hợp có định dạng giờ và phút
            WHEN Duration LIKE '%hr. %min.%' THEN 
                CAST(SUBSTRING(Duration, 1, CHARINDEX('hr.', Duration) - 1) AS INT) * 60 + 
                CAST(SUBSTRING(Duration, CHARINDEX('hr.', Duration) + 4, CHARINDEX('min.', Duration) - CHARINDEX('hr.', Duration) - 4) AS INT)

            -- Trường hợp có định dạng phút cho mỗi tập
            WHEN Duration LIKE '%min. per ep.%' THEN 
                CAST(SUBSTRING(Duration, 1, CHARINDEX(' min.', Duration) - 1) AS INT)

            -- Trường hợp có định dạng phút
            WHEN Duration LIKE '%min%' THEN 
                CAST(SUBSTRING(Duration, 1, CHARINDEX(' min', Duration) - 1) AS INT)

            -- Trường hợp có định dạng giờ
            WHEN Duration LIKE '%hr%' THEN 
                CAST(SUBSTRING(Duration, 1, CHARINDEX(' hr', Duration) - 1) AS INT) * 60

            -- Trường hợp có định dạng giây
            WHEN Duration LIKE '%sec%' THEN 
                ROUND(CAST(SUBSTRING(Duration, 1, CHARINDEX(' sec', Duration) - 1) AS FLOAT) / 60.0, 2)

            -- Trường hợp là 'unknown', giữ nguyên giá trị
            WHEN Duration = 'unknown' THEN NULL  -- Giữ nguyên giá trị 'unknown'
        END
    WHERE Duration IS NOT NULL
    AND AnimeID IN (SELECT AnimeID FROM INSERTED);  -- Chỉ cập nhật các hàng có trong bảng INSERTED

    -- Với những Duration = 'unknown', thì Duration_min bằng TBC của các bộ anime có cùng episodes
    UPDATE [dbo].[AnimeData]
    SET Duration_min = ROUND(
        (
            SELECT AVG(Duration_min)
            FROM [dbo].[AnimeData] AS sub
            WHERE sub.Episodes = [dbo].[AnimeData].Episodes
            AND sub.Duration_min IS NOT NULL  -- Chỉ tính trung bình cho những bản ghi không NULL
        ), 2)  -- Làm tròn đến 2 chữ số phần thập phân
    WHERE Duration_min IS NULL
   AND AnimeID IN (SELECT AnimeID FROM INSERTED);  -- Chỉ cập nhật các hàng có trong bảng INSERTED
END;
UPDATE [dbo].[AnimeData]
SET Duration = Duration;

--7.Trigger để kiểm tra tính hợp lệ của dữ liệu:
CREATE TRIGGER CheckAnimeData
ON AnimeData
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra Score phải nằm trong khoảng từ 0 đến 10
    IF EXISTS (SELECT 1 FROM inserted WHERE Score < 0 OR Score > 10)
    BEGIN
        RAISERROR('Score must be between 0 and 10', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Kiểm tra Ranking phải là số dương
    IF EXISTS (SELECT 1 FROM inserted WHERE Ranking <= 0)
    BEGIN
        RAISERROR('Ranking must be a positive number', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END

    -- Kiểm tra Members và Favorites không được âm
    IF EXISTS (SELECT 1 FROM inserted WHERE Members < 0 OR Favorites < 0)
    BEGIN
        RAISERROR('Members and Favorites must be non-negative', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END

--Câu 8  Viết thủ tục để xóa các chú thích ở cột rating
CREATE PROCEDURE RemoveRatingComments
AS
BEGIN
    -- Cập nhật cột Rating, giữ lại các giá trị chính và xóa phần chú thích
    UPDATE AnimeData
    SET Rating = CASE
        WHEN Rating LIKE 'G%' THEN 'G'
        WHEN Rating LIKE 'PG-13%' THEN 'PG-13'
        WHEN Rating LIKE 'R+%' THEN 'R+'
        WHEN Rating LIKE 'PG%' THEN 'PG'
        WHEN Rating LIKE 'None%' THEN 'None'
		Else 'R-17+'
    END
    WHERE Rating LIKE '%-%'
END
--Gọi thủ tục
exec  RemoveRatingComments;

--9. kiểm tra dòng trùng lặp
CREATE PROCEDURE RemoveDuplicateRows
AS
BEGIN
    -- Xóa các dòng trùng lặp dựa trên AnimeID, giữ lại bản ghi đầu tiên
    WITH DuplicateRows AS (
        SELECT 
            AnimeID, 
            ROW_NUMBER() OVER(PARTITION BY AnimeID ORDER BY (SELECT NULL)) AS RowNum
        FROM 
            dbo.AnimeData 
    )
    DELETE FROM DuplicateRows
    WHERE RowNum > 1;  -- Chỉ xóa các bản ghi có RowNum lớn hơn 1 (tức là bản ghi trùng lặp)
END;
EXEC RemoveDuplicateRows;




