
@REM 'x REG unPlaced' problem:

@REM needs 1.9.11.01 for timing
set GWSH=\Gowin\Gowin_V1.9.11.01_x64\IDE\bin\gw_sh

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

