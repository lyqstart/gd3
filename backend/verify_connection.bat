@echo off
REM 数据库连接验证脚本 (Windows)
REM 用于验证环境变量配置和数据库连接

setlocal enabledelayedexpansion

echo =========================================
echo 数据库连接验证脚本
echo =========================================
echo.

REM 检查环境变量
echo 1. 检查环境变量配置...
echo.

set MISSING_VARS=0

call :check_env_var DB_HOST
call :check_env_var DB_PORT
call :check_env_var DB_NAME
call :check_env_var DB_USER
call :check_env_var DB_PASSWORD
call :check_env_var JWT_SECRET_KEY

echo.

if %MISSING_VARS% GTR 0 (
    echo [错误] 缺少 %MISSING_VARS% 个必需的环境变量
    echo.
    echo 请设置以下环境变量:
    echo   set DB_HOST=localhost
    echo   set DB_PORT=3306
    echo   set DB_NAME=pipeline_calc
    echo   set DB_USER=pipeline_app_user
    echo   set DB_PASSWORD=your_password
    echo   set JWT_SECRET_KEY=your_jwt_secret_key
    echo.
    echo 或者在系统环境变量中设置这些值
    echo.
    exit /b 1
)

REM 可选的环境变量
echo 可选环境变量:
call :check_optional_env_var DB_MIN_POOL_SIZE 5
call :check_optional_env_var DB_MAX_POOL_SIZE 20
call :check_optional_env_var DB_CONNECTION_TIMEOUT 30

echo.
echo =========================================
echo 2. 测试MySQL连接...
echo.

REM 检查MySQL客户端是否可用
where mysql >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [警告] mysql 客户端未安装或不在PATH中,跳过直接连接测试
    echo 可以从 https://dev.mysql.com/downloads/mysql/ 下载MySQL客户端
    echo.
) else (
    echo 尝试连接到 MySQL 数据库...
    mysql -h%DB_HOST% -P%DB_PORT% -u%DB_USER% -p%DB_PASSWORD% %DB_NAME% -e "SELECT 1;" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [成功] MySQL 连接成功
        
        REM 获取数据库版本
        for /f "delims=" %%i in ('mysql -h%DB_HOST% -P%DB_PORT% -u%DB_USER% -p%DB_PASSWORD% %DB_NAME% -sN -e "SELECT VERSION();"') do set DB_VERSION=%%i
        echo [成功] MySQL 版本: !DB_VERSION!
        
        echo.
        echo 检查数据库表...
        mysql -h%DB_HOST% -P%DB_PORT% -u%DB_USER% -p%DB_PASSWORD% %DB_NAME% -sN -e "SHOW TABLES;" > temp_tables.txt
        
        for /f %%i in ("temp_tables.txt") do set TABLE_SIZE=%%~zi
        if !TABLE_SIZE! EQU 0 (
            echo [警告] 数据库中没有表
        ) else (
            echo [成功] 找到以下表:
            for /f "delims=" %%i in (temp_tables.txt) do echo   - %%i
        )
        del temp_tables.txt
    ) else (
        echo [失败] MySQL 连接失败
        echo.
        echo 请检查:
        echo   1. MySQL 服务是否运行
        echo   2. 数据库用户权限是否正确
        echo   3. 防火墙是否允许连接
        echo   4. 数据库凭据是否正确
        echo.
        exit /b 1
    )
)

echo.
echo =========================================
echo 3. 验证JWT配置...
echo.

REM 检查JWT密钥长度
set JWT_KEY=!JWT_SECRET_KEY!
set JWT_KEY_LENGTH=0
:count_jwt_length
if defined JWT_KEY (
    set JWT_KEY=!JWT_KEY:~1!
    set /a JWT_KEY_LENGTH+=1
    goto count_jwt_length
)

if %JWT_KEY_LENGTH% LSS 32 (
    echo [失败] JWT_SECRET_KEY 长度不足 ^(当前: %JWT_KEY_LENGTH% 字符, 建议: ≥32 字符^)
    echo [警告] JWT密钥过短可能导致安全风险
) else (
    echo [成功] JWT_SECRET_KEY 长度符合要求 ^(%JWT_KEY_LENGTH% 字符^)
)

echo.
echo =========================================
echo 4. 生成连接字符串...
echo.

REM 生成连接字符串(隐藏密码)
set CONNECTION_STRING=Server=%DB_HOST%;Port=%DB_PORT%;Database=%DB_NAME%;User=%DB_USER%;Password=***;CharSet=utf8mb4;
echo 连接字符串模板:
echo   %CONNECTION_STRING%

echo.
echo 完整连接字符串^(带连接池^):
if not defined DB_MIN_POOL_SIZE set DB_MIN_POOL_SIZE=5
if not defined DB_MAX_POOL_SIZE set DB_MAX_POOL_SIZE=20
if not defined DB_CONNECTION_TIMEOUT set DB_CONNECTION_TIMEOUT=30

set FULL_CONNECTION_STRING=Server=%DB_HOST%;Port=%DB_PORT%;Database=%DB_NAME%;User=%DB_USER%;Password=***;CharSet=utf8mb4;MinimumPoolSize=%DB_MIN_POOL_SIZE%;MaximumPoolSize=%DB_MAX_POOL_SIZE%;ConnectionTimeout=%DB_CONNECTION_TIMEOUT%;
echo   %FULL_CONNECTION_STRING%

echo.
echo =========================================
echo 5. 验证总结
echo =========================================
echo.

if %MISSING_VARS% EQU 0 (
    echo [成功] 所有必需的环境变量已配置
    echo [成功] 数据库连接验证通过
    echo.
    echo 您可以启动应用程序了:
    echo   dotnet run --project backend\PipelineCalculationAPI
    echo.
    echo 或在IIS中部署应用程序
    echo.
) else (
    echo [失败] 配置验证失败,请修复上述问题后重试
    exit /b 1
)

echo =========================================
goto :eof

REM 函数: 检查环境变量
:check_env_var
set VAR_NAME=%1
set VAR_VALUE=!%VAR_NAME%!

if not defined %VAR_NAME% (
    echo [失败] %VAR_NAME% 未设置
    set /a MISSING_VARS+=1
) else (
    echo %VAR_NAME% | findstr /C:"PASSWORD" /C:"SECRET" >nul
    if !ERRORLEVEL! EQU 0 (
        echo [成功] %VAR_NAME% 已设置 ^(值已隐藏^)
    ) else (
        echo [成功] %VAR_NAME% = !VAR_VALUE!
    )
)
goto :eof

REM 函数: 检查可选环境变量
:check_optional_env_var
set VAR_NAME=%1
set DEFAULT_VALUE=%2
set VAR_VALUE=!%VAR_NAME%!

if not defined %VAR_NAME% (
    echo [信息] %VAR_NAME% 未设置 ^(将使用默认值: %DEFAULT_VALUE%^)
) else (
    echo [成功] %VAR_NAME% = !VAR_VALUE!
)
goto :eof
