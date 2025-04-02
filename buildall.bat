
@REM 'x REG unPlaced' problem:

set GWSH=\Gowin\Gowin_V1.9.10.03_x64\IDE\bin\gw_sh

echo
echo "============ Building console60k ==============="
echo
%GWSH% build.tcl console60k
if %errorlevel% neq 0 exit /b %errorlevel%

echo
echo "============ Building console138k ==============="
echo
%GWSH% build.tcl console138k 
if %errorlevel% neq 0 exit /b %errorlevel%

dir impl\pnr\*.fs

echo "All done."

