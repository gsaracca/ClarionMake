
    PROGRAM

    map
        init_prj()
        add_prj( string _path, string _app )
        make_prj_list(),string
        
        init_properties( string _path )
        add_prop( string _prop )
        
        write_cmd( string _cmd )               
        compilar()
        
    end !* map *
    
ONEDRIVE_PATH   equate( '<ABSOLUTE PATH>' )                                                        ! ABSOLUTE PATH FOR BACK UP
    
CLARION_PATH    cstring( 'c:\clarion10' )                                                          ! YOUR TARGET CLARION SYSTEM
BUILD_FOLDER    cstring( 'c:\Windows\Microsoft.NET\Framework\v4.0.30319' )
SOURCE_BASE     cstring( '<YOUR APPLICATIONS PATH>' )                                              ! YOUR APP PATH "d:\source\myapp"
BACKUP_PATH     cstring( ONEDRIVE_PATH & '\backup' )
BUILD_CONFIG    cstring( 'release' )
SB_PATH         cstring( 'c:\Program Files (x86)\Lindersoft\SetupBuilder 10 Developer\sb10.exe' )  ! IF YOU WISH MAKE INSTALL
WINRAR_PATH     cstring( 'c:\Program Files\WinRAR\WinRAR.exe' )                                    ! IF YOU WISH MAKE A RAR FILE
INSTALL_PATH    cstring( '<RELATIVE PATH: myapp.sbp>' )                                            ! REALTIVE PATH TO INSTALL FOR SETUP BUILDER

tCMD            file,driver('ascii','/clip=on'),name('make.cmd'),create
record              record
linea                   string(10000)
                    end !* record *
                end !* file *    
    
qCMD            queue
order               long
path                cstring(1000)
app                 cstring(1000)
                end !* queue *   

qProp           queue
propiedad           cstring(255)
                end !* queue *
propertyList    cstring(100000)        
    
Window WINDOW('Batch Compiler'),AT(,,374,228),CENTER,GRAY,FONT('Courier New',10), |
            VSCROLL
        BUTTON('&Generate "make.cmd"'),AT(2,212,184,14),USE(?Comp),DEFAULT
        BUTTON('&Close'),AT(188,212,184,14),USE(?Close)
        LIST,AT(2,2,369,206),USE(?ListCMD),FROM(qCMD),FORMAT('29R(2)|M~Order~C(0' & |
                ')@n_3@180L(2)|M~Path~C(0)@s255@80L(2)|M~Applications~C(0)@s255@')
    END
    code  
    open( Window )    
    accept
        case field()
            of ?Comp
                if event() = EVENT:Accepted
                    compilar()
                end !* if *
            of ?Close
                if event() = EVENT:Accepted
                    break
                end !* if *            
        end !* case *
    end !* accepr *    
    close( Window )

add_prj     procedure( string _path, string _app )
    code
    clear( qCMD )
    qCMD.order = records(qCMD)+1
    qCMD.path = clip(_path)
    qCMD.app = clip(_app)
    add( qCMD ) 

init_prj    procedure()
    code
    clear( qCMD )
    free( qCMD )
    add_prj( 'ddl', 'ddl' )
    ! .........
    add_prj( 'DDL/EXE PATH', 'APP NAME' )
    
add_prop            procedure( string _prop )    
    code
    clear( qProp )
    qProp.propiedad = clip(_prop)
    add( qProp )
    
init_properties     procedure( string _path )
i                   long
    code
    clear( qProp )
    free( qProp )
    add_prop( 'redirection_ConfigDir="' & CLARION_PATH & '\Settings"' )
    add_prop( 'Configuration="' & BUILD_CONFIG &'"' )
    add_prop( 'clarion_Sections="release"' )
    add_prop( 'SolutionDir="' & clip(_path) & '"' )
    add_prop( 'ClarionBinPath="' & CLARION_PATH &'\Bin"' )
    add_prop( 'NoDependency=true' )
    add_prop( 'Verbosity=diagnostic' )
    add_prop( 'WarningLevel=1' )
    
    propertyList = ''
    loop i = 1 to records( qProp )
        get( qProp, i )
        propertyList = propertyList & ' /property:' & clip( qProp.propiedad ) 
    end !* loop *        

write_cmd           procedure( string _cmd )
    code
    clear( tCMD )
    tCMD.linea = clip( _cmd )
    add( tCMD )
    
make_prj_list       procedure()!,string
str_app             cstring(16000)
i                   long
    code
    str_app = ''
    loop i = 1 to records( qCMD )
        get( qCMD, i )
        if i = 1
            str_app = qCMD.path &'\'& qCMD.app
        else
            str_app = str_app & ' ' & qCMD.path &'\'& qCMD.app
        end !* if *
    end !* loop *    
    return str_app
    
compilar            procedure()
    code
    init_prj()
        
    create( tCMD )
    open( tCMD )
    write_cmd( '@echo off' )
    write_cmd( 'cd ' & SOURCE_BASE )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'echo CompileCW Updated: ' & format( today(), @d17 ) & ' at ' & format( clock(), @t7 ) )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'echo RoboCopy BackUp.' )
    write_cmd( 'echo ------------------------------------------------------------------' )    
    write_cmd( 'set startBackup=%time%' )
    write_cmd( 'robocopy . ' & BACKUP_PATH & ' /mir' )
    write_cmd( 'if %errorlevel% GEQ 8 (' )
    write_cmd( '<9>echo RoboCopy BackUp failed with error level %ERRORLEVEL%.' )
    write_cmd( '<9>exit /b %ERRORLEVEL%' )
    write_cmd( ') else (' )
    write_cmd( '<9>echo RoboCopy BackUp completed with error level %errorlevel%.' )
    write_cmd( ')' )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'echo Clarion Generation and Build.' )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'set startBuild=%time%' )
    write_cmd( 'set "apps=' & make_prj_list() & '"' )
    write_cmd( 'for %%a in (%apps%) do (' )
    write_cmd( '<9>for /f "tokens=1,2 delims=\" %%b in ("%%a") do (' )
    write_cmd( '<9><9>cd ' & SOURCE_BASE & '\%%b' )
    write_cmd( '<9><9>' & CLARION_PATH & '\bin\clarioncl /ag %%c.app' )
    write_cmd( '<9><9>if %ERRORLEVEL% NEQ 0 (' )
    write_cmd( '<9><9><9>echo Clarion generation failed for %%c.app with error level %ERRORLEVEL%.' )
    write_cmd( '<9><9><9>exit /b %ERRORLEVEL%' )
    write_cmd( '<9><9>)' )    
    write_cmd( '<9><9>' & BUILD_FOLDER & '\MSBuild %%c.cwproj' & |
                        ' /property:redirection_ConfigDir="' & CLARION_PATH &'\Settings"' & |
                        ' /property:Configuration="release"' & |
                        ' /property:clarion_Sections="release"' & |
                        ' /property:SolutionDir="' & SOURCE_BASE & '\%%b"' & |
                        ' /property:ClarionBinPath="' & CLARION_PATH & '\Bin"' & |
                        ' /property:NoDependency=true' & |
                        ' /property:Verbosity=diagnostic' & |
                        ' /property:WarningLevel=1' )
    write_cmd( '<9><9>if %ERRORLEVEL% NEQ 0 (' )
    write_cmd( '<9><9><9>echo MSBuild failed for %%c.cwproj with error level %ERRORLEVEL%.' )
    write_cmd( '<9><9><9>exit /b %ERRORLEVEL%' )
    write_cmd( '<9><9>)' )                        
    write_cmd( '<9>)' )
    write_cmd( ')' )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'echo SetUpBuilder Install.' )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'set startInstall=%time%' )
    write_cmd( 'cd ' & SOURCE_BASE )
    write_cmd( '"' & SB_PATH & '" /c ' & INSTALL_PATH )
    write_cmd( 'if %ERRORLEVEL% NEQ 0 (' )
    write_cmd( '<9>echo SetUpBuilder Install failed with error level %ERRORLEVEL%.' )
    write_cmd( '<9>exit /b %ERRORLEVEL%' )
    write_cmd( ')' )
    write_cmd( 'echo WinRAR Second BackUp.' )
    write_cmd( 'set startWinRar=%time%' )
    write_cmd( 'cd ' & SOURCE_BASE )
    write_cmd( '"' & WINRAR_PATH & '" a -agYYYY-MM-DD "' & ONEDRIVE_PATH & '\osgX " -r ..\osg' )
    write_cmd( 'if %ERRORLEVEL% NEQ 0 (' )
    write_cmd( '<9>echo WinRAR Second BackUp failed with error level %ERRORLEVEL%.' )
    write_cmd( '<9>exit /b %ERRORLEVEL%' )
    write_cmd( ')' )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'echo Start BackUp : %startBackup%'   )
    write_cmd( 'echo Start Build  : %startBuild%'    )
    write_cmd( 'echo Start Install: %startInstall%'  )
    write_cmd( 'echo Start WinRar : %startWinRar%'  )
    write_cmd( 'echo Final        : %time%'          )
    write_cmd( 'echo ------------------------------------------------------------------' )
    write_cmd( 'pause' )
    close( tCMD )

!* end *
