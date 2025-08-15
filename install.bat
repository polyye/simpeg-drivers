@echo off
setlocal EnableDelayedExpansion

call "%~dp0get_conda_exec.bat"
if !errorlevel! neq 0 ( pause & exit /B !errorlevel! )

set PY_VER=3.10
set ENV_NAME=simpeg_drivers
set MY_CONDA=!MY_CONDA_EXE:"=!
cd /d %~dp0
set PYTHONUTF8=1
set CONDA_CHANNEL_PRIORITY=strict
set PIP_NO_DEPS=1

set MY_CONDA_ENV_FILE=environments\py-%PY_VER%-win-64-dev.conda.lock.yml
if not exist "%MY_CONDA_ENV_FILE%" (
  echo "** ERROR: Could not find '%MY_CONDA_ENV_FILE%' **"
  pause & exit /B 1
)

call "!MY_CONDA!" activate base || ( echo "** ERROR: activate base **" & pause & exit /B 1 )

:: Seed env with python + pip + git + git-lfs (needed for git+pip deps with LFS)
call "!MY_CONDA!" env list | findstr /R /C:"\b%ENV_NAME%\b" >nul
if !errorlevel! neq 0 (
  echo Creating '%ENV_NAME%' with Python %PY_VER%, git, git-lfs...
  call "!MY_CONDA!" create -y -n %ENV_NAME% -c conda-forge python=%PY_VER% pip git git-lfs || (
    echo "** ERROR: Failed to create seed environment **" & pause & exit /B 1
  )
) else (
  echo Environment '%ENV_NAME%' exists. Ensuring git and git-lfs are installed...
  call "!MY_CONDA!" install -y -n %ENV_NAME% -c conda-forge git git-lfs || (
    echo "** ERROR: Failed to install git/git-lfs **" & pause & exit /B 1
  )
)

:: Ensure LFS filters are active in this env
call "!MY_CONDA!" run -n %ENV_NAME% git lfs install

:: Update from the lock file (pip will now fetch real LFS content)
call "!MY_CONDA!" env update -n %ENV_NAME% --file "%MY_CONDA_ENV_FILE%" || (
  echo "** ERROR: Environment update failed **" & pause & exit /B 1
)

:: Editable install of your package
call "!MY_CONDA!" run -n %ENV_NAME% python -m pip install -e . --no-deps || (
  echo "** ERROR: Installation failed **" & pause & exit /B 1
)

echo.
echo Installation completed successfully.
pause
cmd /k "!MY_CONDA!" activate %ENV_NAME%