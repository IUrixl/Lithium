@echo off
setlocal EnableDelayedExpansion

For /F %%e in ('echo prompt $E^|cmd')Do set "esc=%%e"

chcp 65001>nul
goto fontSwap

:setup
    echo %esc%[?25l
    if "%1"=="" (
        echo Lithium model not provided
        pause>nul
        exit/b
    )

    set "model=%1"

    set frame=0
    set "buffer3D="
    set "len3D=0"

    goto core

:fontSwap
    reg query HKCU\Console\Lithium

    IF %errorlevel%==1 (
        >nul reg add HKCU\Console\Lithium /v FaceName /t reg_sz /d "Terminal" /f
        >nul reg add HKCU\Console\Lithium /v FontSize /t reg_dword /d 524296
        >nul reg add HKCU\Console\Lithium /v FontFamily /t reg_dword /d 48
        start "Lithium" "%~0" %1
        exit
    ) else ( 
        mode con: cols=75 lines=75
        >nul reg delete HKCU\Console\Lithium /f 
    )
    goto setup

:core
    goto :_update
    :_render
        call :__renderModel

        echo %esc%[2J%esc%[H!buffer2D!

        set "buffer2D=%esc%[38;2;7;173;250m%esc%[2;2HLithium 1.0%esc%[0m"
        goto :_update

        :__renderModel
            call :___joints
            call :___wireframe
            goto :eof

            :___wireframe
                for /L %%i in (1,1, !len3D!) do (
                    set "w_index=0"
                    for %%a in (!buffer3D[%%i]!) do (
                        set/a w_index+=1
                        if !w_index!==1 set "w_x=%%a"
                        if !w_index!==2 set "w_y=%%a"
                        if !w_index!==3 set "w_z=%%a"
                    )

                    rem if !l_z!==1 set "buffer2D=!buffer2D!%esc%[1m%esc%[43m"
                    rem if !l_z!==2 set "buffer2D=!buffer2D!%esc%[1m%esc%[41m"

                    set "buffer2D=!buffer2D!%esc%[1m%esc%[!w_y!;!w_x!H█%esc%[0m"
                )
                goto :eof

            :___joints
                for /L %%i in (1,1, !len3D!) do (
                    set "l_index=0"
                    set "l_connections="
                    for %%a in (!buffer3D[%%i]!) do (
                        set/a l_index+=1
                        if !l_index!==1 set "j_x=%%a"
                        if !l_index!==2 set "j_y=%%a"
                        if !l_index!==3 set "j_z=%%a"
                        if !l_index! geq 4 set "l_connections=!l_connections! %%a"
                       
                        rem echo !l_index! ^| %%i !j_x! ^| !buffer3D[%%i]! ^| !len3D!
                    )
                    set "l_origin=%%i"
                    for %%b in (!l_connections!) do (
                        set "l_connected=%%b"
                        set "l_connected=!l_connected: =!"
                        set "l_connected=!l_connected:#=!"
                        call :____renderLine
                    )
                )
                goto :eof

                    :____renderLine
                        set "t_index=0"
                        for %%a in (!buffer3D[%l_connected%]!) do (
                            set/a t_index+=1
                            if !t_index!==1 set "t_x=%%a"
                            if !t_index!==2 set "t_y=%%a"
                            if !t_index!==3 set "t_z=%%a"
                        )

                        set "l_x=!j_x!"
                        set "l_y=!j_y!"
                        set "l_z=!j_z!"

                        if !l_x! gtr !t_x! (
                            rem echo flip at %l_connected% from %l_origin% ^| !l_x! !t_x!
                            call :_flipInputs
                        )

                        if !l_y! gtr !t_y! (
                            rem echo flip at %l_connected% from %l_origin% ^| !l_x! !t_x!
                            call :_flipInputs
                        )

                        REM Deteccion de verticalidad y inversion
                        set/a ix=!t_x! - !l_x!
                        set/a iy=!t_y! - !l_y!
                        set "t_studs=1"
                        set "t_ysteps=!iy:-=!"
                        set "t_xsteps=!ix:-=!"

                        if !ix!==0 (
                            if !iy! lss 0 set "t_studs=-1"
                            for /L %%y in (1, 1, !t_ysteps!) do (  
                                set/a r_y=!l_y!+!t_studs!*%%y
                                set "buffer2D=!buffer2D!%esc%[!r_y!;!l_x!H%esc%[1m█"
                            )
                        ) else (    
                            set "ix=!ix:-=!"
                            if !l_x! lss !t_x! (
                                set "sx=1"
                            ) else (
                                set "sx=-1"
                            )
                            
                            set "iy=!iy:-=!"
                            set/a iy=-!iy!

                            if !l_y! lss !t_y! (
                                set "sy=1"
                            ) else (
                                set "sy='1"
                            )

                            set/a error=!ix!+!iy!
                            call :_plotLoop
                        )
                    goto :eof

                        :_plotLoop
                            set "buffer2D=!buffer2D!%esc%[!l_y!;!l_x!H%esc%[1m█"
                            if !l_x!==!t_x! if !l_y!==!t_y! goto :eof

                            set/a e2=2*!error!

                            if !e2! geq !iy! (
                                if !l_x!==!t_x! goto :eof
                                set/a error+=!iy!
                                set/a l_x+=!sx!
                                rem echo !l_x!
                            )
                            if !e2! leq !ix! (
                                if !l_y!==!t_y! goto :eof
                                set/a error+=!ix!
                                set/a l_y+=!sy!
                                rem echo !l_y!
                            )

                            goto _plotLoop


    :_update
        call :__readModel
        goto _render

        :__readModel
            set "l_index=0"
            set "l_offsetX=0"
            set "l_offsetY=0"
            for /f "tokens=* eol= " %%A in (!model!) do (
                set/a l_index+=1
                set "l_write=true"

                set "l_token=%%A"
                if "!l_token:~0,1!"=="?" (
                    set "l_write=false"
                    set/a l_index-=1

                    for %%b in (!l_token!) do (
                        set "z_token=%%b"

                        if "!z_token:~0,2!"=="x|" set "l_offsetX=!z_token:~2!"
                        if "!z_token:~0,2!"=="y|" set "l_offsetY=!z_token:~2!"
                    )
                )

                set "t_index=0"
                set "t_p="
                for %%a in (%%A) do (
                    set/a t_index+=1

                    if !t_index!==1 set "t_x=%%a"
                    if !t_index!==2 set "t_y=%%a"
                    if !t_index!==3 set "t_z=%%a"
                    if !t_index! geq 4 set "t_p=!t_p! %%a"
                )

                set/a t_x+=!l_offsetX!+2
                set/a t_y+=!l_offsetY!+2
                set/a t_x=!t_x!/!t_z!
                set/a t_y=!t_y!/!t_z!

                if "!l_write!"=="true" set "buffer3D[!l_index!]=!t_x! !t_y! !t_z! !t_p!"
            )
            set "len3D=!l_index!"
            goto :eof

    :_throwback
        cls
        echo Unexpected error, quitting.
        pause>nul
        exit /b

    :_flipInputs
        set "k_x=!l_x!"
        set "l_x=!t_x!"
        set "t_x=!k_x!"

        set "k_y=!l_y!"
        set "l_y=!t_y!"
        set "t_y=!k_y!"
        goto :eof