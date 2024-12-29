--1. PHAN QUYEN CHO ADMIN

-- Tạo login và user cho Admin
CREATE LOGIN AdminLogin WITH PASSWORD = 'Anime@admin';
USE Anime;
CREATE USER AdminUser FOR LOGIN AdminLogin;

-- Cấp quyền sysadmin cho Admin (toàn quyền trên server)
ALTER SERVER ROLE sysadmin ADD MEMBER AdminLogin;

-- Cấp quyền db_owner cho Admin trong cơ sở dữ liệu cụ thể
USE Anime;
ALTER ROLE db_owner ADD MEMBER AdminUser;

-- Cấp quyền backup và phục hồi cơ sở dữ liệu
GRANT BACKUP DATABASE TO AdminUser;
GRANT BACKUP LOG TO AdminUser;

--2. PHAN QUYEN CHO DA

-- Tạo login và user cho Data Analyst
CREATE LOGIN DA_Login WITH PASSWORD = 'Anime@DA';
USE Anime;
CREATE USER DA_User FOR LOGIN DA_Login;
-- tạo role
USE Anime;
CREATE ROLE DataAnalystRole;
-- Cấp quyền SELECT cho Role trên tất cả các bảng trừ AnimeData
GRANT SELECT ON dbo.Anime TO DataAnalystRole;
GRANT SELECT ON dbo.Anime_genres TO DataAnalystRole;
GRANT SELECT ON dbo.Anime_Studio TO DataAnalystRole;
GRANT SELECT ON dbo.AnimeType TO DataAnalystRole;
GRANT SELECT ON dbo.Genres TO DataAnalystRole;
GRANT SELECT ON dbo.Premiered TO DataAnalystRole;
GRANT SELECT ON dbo.Rating TO DataAnalystRole;
GRANT SELECT ON dbo.Statistic TO DataAnalystRole;
GRANT SELECT ON dbo.Studio TO DataAnalystRole;

-- Cấp quyền EXECUTE cho role trên các stored procedure / khong
GRANT EXECUTE ON dbo.StoredProcedure1 TO DataAnalystRole;
--Them DA vào role
ALTER ROLE DataAnalystRole ADD MEMBER DA_User;

--3. PHAN QUYEN CHO DE

-- Tạo login và user cho Data Engineer
CREATE LOGIN DE_Login WITH PASSWORD = 'Anime@DE';
USE Anime;
CREATE USER DE_User FOR LOGIN DE_Login;

-- Cấp quyền SELECT, INSERT, UPDATE, DELETE cho tất cả các bảng
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Anime TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Anime_genres TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Anime_Studio TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.AnimeType TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Genres TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Premiered TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Rating TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Statistic TO DE_User;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Studio TO DE_User;

-- Cấp quyền ALTER cho tất cả các bảng
GRANT ALTER ON dbo.Anime TO DE_User;
GRANT ALTER ON dbo.Anime_genres TO DE_User;
GRANT ALTER ON dbo.Anime_Studio TO DE_User;
GRANT ALTER ON dbo.AnimeType TO DE_User;
GRANT ALTER ON dbo.Genres TO DE_User;
GRANT ALTER ON dbo.Premiered TO DE_User;
GRANT ALTER ON dbo.Rating TO DE_User;
GRANT ALTER ON dbo.Statistic TO DE_User;
GRANT ALTER ON dbo.Studio TO DE_User;


-- Cấp quyền EXECUTE cho stored procedures nếu có
GRANT EXECUTE ON dbo.ETL_StoredProcedure TO DE_User;  -- Thay 'ETL_StoredProcedure' bằng tên các stored procedure cụ thể

------------
-- Kiểm tra quyền của người dùng trong cơ sở dữ liệu
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState,
    obj.name AS ObjectName
FROM 
    sys.database_principals dp
JOIN 
    sys.database_permissions perm
    ON dp.principal_id = perm.grantee_principal_id
LEFT JOIN 
    sys.objects obj
    ON perm.major_id = obj.object_id
WHERE 
    dp.name = 'DE_User';  -- Thay 'DE_User' bằng tên người dùng cần kiểm tra
-- Kiểm tra quyền của người dùng trên tất cả các bảng
SELECT 
    dp.name AS UserName,
    obj.name AS TableName,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState
FROM 
    sys.database_principals dp
JOIN 
    sys.database_permissions perm
    ON dp.principal_id = perm.grantee_principal_id
JOIN 
    sys.objects obj
    ON perm.major_id = obj.object_id
WHERE 
    dp.name = 'DE_User'  -- Thay 'DE_User' bằng tên người dùng cần kiểm tra
    AND obj.type = 'U';  -- 'U' là kiểu bảng người dùng (user table)

-------------
-- Kiểm tra quyền SELECT của DE_User đối với bảng Anime
EXECUTE AS USER = 'DE_User';  -- Đổi ngữ cảnh sang DE_User
SELECT * FROM dbo.Anime;      -- Kiểm tra quyền SELECT
REVERT;                       -- Quay lại ngữ cảnh người dùng ban đầu
-- Kiểm tra quyền INSERT của DE_User đối với bảng Anime
EXECUTE AS USER = 'DE_User';  -- Đổi ngữ cảnh sang DE_User
INSERT INTO dbo.Anime (AnimeID, AnimeName, Duration_min, Episodes)  -- Thay thế column1, column2 bằng các cột thực tế trong bảng
VALUES (13000,'Dream', 25, 3);  -- Thay thế value1, value2 bằng giá trị thực tế
REVERT;                       -- Quay lại ngữ cảnh người dùng ban đầu

