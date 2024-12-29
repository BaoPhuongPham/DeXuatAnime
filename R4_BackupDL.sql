SELECT SYSDATETIMEOFFSET();

--Backup full
BACKUP DATABASE [Anime_Org]
TO DISK = N'D:\Backup\DatabaseName_Full.bak'
WITH INIT, COMPRESSION, STATS = 10;
--Backup diffrent
BACKUP DATABASE [Anime_Org]
TO DISK = N'D:\Backup\DatabaseName_Diff.bak'
WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10;

-- lên lịch 
USE msdb;
GO

-- Tạo job
EXEC sp_add_job 
    @job_name = N'Monthly_Full_Backup';
GO

-- Thêm bước backup vào job
EXEC sp_add_jobstep 
    @job_name = N'Monthly_Full_Backup',
    @step_name = N'Full Backup Step',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE [Anime_Org] TO DISK = N''D:\Backup\DatabaseName_Full.bak'' WITH INIT, COMPRESSION, STATS = 10;',
    @database_name = N'Anime_Org';
GO

-- Tạo lịch trình chạy vào ngày 1 mỗi tháng lúc 3:00 AM
EXEC sp_add_jobschedule 
    @job_name = N'Monthly_Full_Backup',
    @name = N'Monthly Schedule',
    @freq_type = 4,            -- Định kỳ (Scheduled)
    @freq_interval = 30,        -- sau 30 ngày kể từ ngày backup gần nhất
    @freq_recurrence_factor = 1, -- Lặp lại mỗi tháng
    @active_start_time = 30000; -- 3:00 AM
GO

-- Liên kết job với SQL Server Agent
EXEC sp_add_jobserver 
    @job_name = N'Monthly_Full_Backup';
GO

--Lên lịch hàng tuần vào 4h sáng chủ nhật
USE msdb;
GO

-- Tạo job
EXEC sp_add_job 
    @job_name = N'Weekly_Differential_Backup';
GO

-- Thêm bước backup vào job
EXEC sp_add_jobstep 
    @job_name = N'Weekly_Differential_Backup',
    @step_name = N'Differential Backup Step',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE [Anime_Org] TO DISK = N''D:\Backup\DatabaseName_Diff.bak'' WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10;',
    @database_name = N'Anime_Org';
GO

-- Thiết lập lịch chạy job vào mỗi Chủ nhật lúc 4h sáng
EXEC sp_add_jobschedule 
    @job_name = N'Weekly_Differential_Backup',
    @name = N'Weekly Schedule',
    @freq_type = 8,              -- Chạy hàng tuần
    @freq_interval = 1,          -- Chủ nhật (1: Chủ nhật)
    @freq_recurrence_factor = 1, -- Lặp lại mỗi tuần
    @active_start_time = 40000;  -- 4:00 AM
GO

-- Liên kết job với SQL Server Agent
EXEC sp_add_jobserver 
    @job_name = N'Weekly_Differential_Backup';
GO


