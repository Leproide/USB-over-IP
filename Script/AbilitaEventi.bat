@echo off
auditpol /set /subcategory:"Plug and Play Events" /success:enable
auditpol /set /subcategory:"Eventi Plug and Play" /success:enable
gpupdate /force
echo.
timeout /t 5
exit 0