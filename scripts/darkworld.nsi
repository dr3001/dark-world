!include "MUI2.nsh"

Name "Dark World"
OutFile "/opt/darkworld/build/DarkWorld-Setup.exe"
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

Section "Dark World" SecMain
    SetOutPath "$INSTDIR"
    File "/opt/darkworld/build/windows/DarkWorld.exe"
    
    ; Desktop shortcut
    CreateShortCut "$DESKTOP\Dark World.lnk" "$INSTDIR\DarkWorld.exe"
    
    ; Start menu
    CreateDirectory "$SMPROGRAMS\Dark World"
    CreateShortCut "$SMPROGRAMS\Dark World\Dark World.lnk" "$INSTDIR\DarkWorld.exe"
    CreateShortCut "$SMPROGRAMS\Dark World\Desinstalar.lnk" "$INSTDIR\Uninstall.exe"
    
    ; Uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; Registry for Add/Remove Programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorld" "DisplayName" "Dark World"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorld" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorld" "Publisher" "Zorion Labs"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorld" "DisplayVersion" "1.0.0"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\DarkWorld.exe"
    Delete "$INSTDIR\Uninstall.exe"
    Delete "$DESKTOP\Dark World.lnk"
    RMDir /r "$SMPROGRAMS\Dark World"
    RMDir "$INSTDIR"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DarkWorld"
SectionEnd
