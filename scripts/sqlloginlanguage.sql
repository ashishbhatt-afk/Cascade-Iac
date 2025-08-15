DECLARE @vmList NVARCHAR(MAX) = '$(servicePrincipalList)';

DECLARE @vmName NVARCHAR(256);
DECLARE vm_cursor CURSOR FOR 
    SELECT RTRIM(value) as vmName 
    FROM STRING_SPLIT(@vmList, ',') 
    WHERE RTRIM(value) <> '';

OPEN vm_cursor;
FETCH NEXT FROM vm_cursor INTO @vmName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Check if user exists and create if not
    IF NOT EXISTS (
        SELECT [name]
        FROM [sys].[database_principals]
        WHERE [type] = N'E' AND [name] = @vmName
    )
    BEGIN
        DECLARE @sql NVARCHAR(MAX) = 'CREATE USER [' + @vmName + '] FROM EXTERNAL PROVIDER;';
        EXEC sp_executesql @sql;

        SET @sql = 'ALTER USER [' + @vmName + '] WITH DEFAULT_LANGUAGE = English;';
        EXEC sp_executesql @sql;
    END

    -- Add user to db_owner role
    EXEC sp_addrolemember 'db_owner', @vmName;

    FETCH NEXT FROM vm_cursor INTO @vmName;
END

CLOSE vm_cursor;
DEALLOCATE vm_cursor;
GO



--  below can be used to check if the user is added to db_owner role
-- SELECT dp.name AS UserName, rp.name AS RoleName
-- FROM sys.database_role_members drm
-- JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
-- JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
-- WHERE dp.name = 'SPN';