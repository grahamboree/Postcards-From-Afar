@echo off
REM SIMPLE COMMAND.COM SCRIPT TO ASSEMBLE GAMEBOY FILES
REM REQUIRES MAKELNK.BAT
REM LUIGI GUATIERI
REM UPDATED 2019-01-25

if not exist obj mkdir obj

if exist bin\%1.gb del bin\%1.gb
REM IF THERE ARE SETTINGS WHICH NEED TO BE DONE ONLY ONCE, PUT THEM BELOW
rem if not %ASSEMBLE%1 == 1 goto begin
rem path=%path%;c:\GB_asm\
rem doskey UNNECESSARY ON DESKTOP --- DOSKEY ALREADY INSTALLED
rem set dir=c:\GB_asm\curren~1\
cmd /c makelnk %1 > obj\%1.link

:begin
set assemble=1
echo assembling...
rgbasm -E -iinc\ -oobj\%1.obj src\%1.asm
if errorlevel 1 goto end
echo linking...
rgblink -o obj\%1.gb -n obj\%1.sym obj\%1.obj
if errorlevel 1 goto end
echo fixing...
rgbfix -v obj\%1.gb

:end
rem del *.obj
