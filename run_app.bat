@echo off
echo ========================================================
echo Running Flutter using the space-free junction path
echo This avoids the native-assets crash on Windows.
echo ========================================================
C:\flutter\bin\flutter.bat run %*
