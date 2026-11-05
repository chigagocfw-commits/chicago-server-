@echo off
echo ========================================================
echo  CHICAGO SERVER - MySQL Database Backup Utility
echo ========================================================
echo Exporting database Qbox_C6CA87...

"C:\xampp\mysql\bin\mysqldump.exe" -u qbox_app -pxkOVGVyFXlmGWaRsZtVXUKtvGhfR7L7f -h 127.0.0.1 Qbox_C6CA87 --result-file="%~dp0..\database_backup.sql"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Backup exported successfully to: database_backup.sql
) else (
    echo [ERROR] Failed to export database. Please check MySQL is running.
)

pause

