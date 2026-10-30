@echo off
cd /d "C:\Users\Admin\Desktop\tank_speak"
set "FL=C:\flutter sdk\flutter_windows_3.41.6-stable\flutter\bin\flutter.bat"
set LOG=flutter_checks.log
echo === flutter pub get === > %LOG%
call "%FL%" pub get >> %LOG% 2>&1
echo EXIT pub get: %ERRORLEVEL% >> %LOG%
echo === flutter analyze === >> %LOG%
call "%FL%" analyze --no-pub >> %LOG% 2>&1
echo EXIT analyze: %ERRORLEVEL% >> %LOG%
echo === flutter test === >> %LOG%
call "%FL%" test --no-pub >> %LOG% 2>&1
echo EXIT test: %ERRORLEVEL% >> %LOG%
echo === flutter build apk --debug === >> %LOG%
call "%FL%" build apk --debug --no-pub >> %LOG% 2>&1
echo EXIT build: %ERRORLEVEL% >> %LOG%
echo === DONE === >> %LOG%
