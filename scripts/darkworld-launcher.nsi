!include "MUI2.nsh"

Name "Dark World Launcher"
OutFile "/opt/darkworld/build/DarkWorld-Launcher-Setup.exe"
InstallDir "$PROGRAMFILES64\Dark World"
RequestExecutionLevel admin

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "PortugueseBR"

Section "Dark World Launcher" SecMain
    SetOutPath "$INSTDIR"

    File "/opt/darkworld/build/launcher/DarkWorld-Launcher.exe"

    File "/opt/darkworld/scripts/templates/installer-version.json"
    Rename "$INSTDIR\installer-version.json" "$INSTDIR\version.json"

    CreateDirectory "$LOCALAPPDATA\DarkWorld\game"

    CreateShortCut "$DESKTOP\Dark World.lnk" "$INSTDIR\DarkWorld-Launcher.exe" "" "$INSTDIR\DarkWorld-Launcher.exe" 0

    CreateDirectory "$SMPROGRAMS\Dark World"
    CreateShortCut "$SMPROGRAMS\Dark World\Dark World Launcher.lnk" "$INSTDIR\DarkWorld-Launcher.exe"
    CreateShortCut "$SMPROGRAMS\Dark World\Desinstalar.lnk" "$INSTDIR\Uninstall.exe"

    WriteUninstaller "$INSTDIR\Uninstall.exe"

    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorldLauncher" "DisplayName" "Dark World Launcher"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorldLauncher" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorldLauncher" "Publisher" "Zorion Labs"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorldLauncher" "DisplayVersion" "1.0.0"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\DarkWorld-Launcher.exe"
    Delete "$INSTDIR\version.json"
    Delete "$INSTDIR\Uninstall.exe"
    Delete "$DESKTOP\Dark World.lnk"
    RMDir /r "$SMPROGRAMS\Dark World"
    RMDir "$INSTDIR"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorldLauncher"
SectionEnd
