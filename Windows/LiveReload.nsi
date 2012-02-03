# BASICS
!define VERSION "0.0.3"
!define REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\LiveReload"
!define REG_APP_PATH  "Software\Microsoft\Windows\CurrentVersion\App Paths\LiveReload.exe"
!define REG_UPDATES_PATH  "Software\LiveReload\Updates"
!define START_LINK_RUN "$STARTMENU\Programs\LiveReload.lnk"
!define UNINSTALLER_NAME "LiveReload-Uninstall.exe"
!define WEBSITE_LINK "http://livereload.com/"

# INCLUDES
!include MUI2.nsh ;Modern interface
!include LogicLib.nsh ;nsDialogs

# INIT
SetCompressor /SOLID lzma
Name "LiveReload"
; titlebar of the installer
Caption "LiveReload"
; Sets the text that is shown (by default it is 'Nullsoft Install System vX.XX') at the bottom of the install window
BrandingText " "
XPStyle on
InstallDirRegKey HKCU "${REG_APP_PATH}" ""
InstallDir "$LOCALAPPDATA\LiveReload\App"
OutFile "..\dist\LiveReload-${VERSION}-Setup.exe"
RequestExecutionLevel user

# VERSION INFO
VIProductVersion  "${VERSION}.0"
VIAddVersionKey "ProductName"  "${APP_NAME}"
VIAddVersionKey "CompanyName"  "${COMP_NAME}"
VIAddVersionKey "LegalCopyright"  "${COPYRIGHT}"
VIAddVersionKey "FileDescription"  "${DESCRIPTION}"
VIAddVersionKey "FileVersion"  "${VERSION}"

# GRAPHICS
!define MUI_ICON "images\LiveReload.ico"

# UI
;!define MUI_PAGE_HEADER_TEXT "LiveReload"
!define MUI_WELCOMEPAGE_TITLE "The Web Developer Paradise"
!define MUI_WELCOMEPAGE_TEXT "Welcome to highly experimental LiveReload ${VERSION}!$\r$\n$\r$\nPlease report any bugs and suggestions to help.livereload.com.$\r$\n$\r$\nThis beta expires on Jun 1, 2012. Eventually, in a few months, LiveReload will be sold for $$9.99.$\r$\n$\r$\nReady to install?"
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_RUN "$INSTDIR\LiveReload.exe"
;!define MUI_FINISHPAGE_RUN_TEXT "Run LiveReload now."
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# LANGUAGES
!insertmacro MUI_LANGUAGE "English"

# CALLBACKS
Function RegisterApplication
    ;Register uninstaller into Add/Remove panel (for local user only)
    WriteRegStr   HKCU "${REG_UNINSTALL}" "DisplayName" "LiveReload"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "DisplayIcon" "$\"$INSTDIR\LiveReload.exe$\""
    WriteRegStr   HKCU "${REG_UNINSTALL}" "Publisher" "Andrey Tarantsov"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "DisplayVersion" "${VERSION}"
    WriteRegDWord HKCU "${REG_UNINSTALL}" "EstimatedSize" 15360 ;KB
    WriteRegStr   HKCU "${REG_UNINSTALL}" "HelpLink" "${WEBSITE_LINK}"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "URLInfoAbout" "${WEBSITE_LINK}"
    WriteRegStr   HKCU "${REG_UNINSTALL}" "InstallLocation" "$\"$INSTDIR$\""
    WriteRegStr   HKCU "${REG_UNINSTALL}" "InstallSource" "$\"$EXEDIR$\""
    WriteRegDWord HKCU "${REG_UNINSTALL}" "NoModify" 1
    WriteRegDWord HKCU "${REG_UNINSTALL}" "NoRepair" 1
    WriteRegStr   HKCU "${REG_UNINSTALL}" "UninstallString" "$\"$INSTDIR\${UNINSTALLER_NAME}$\""
    WriteRegStr   HKCU "${REG_UNINSTALL}" "Comments" "Uninstalls LiveReload."
    
    WriteRegStr   HKCU "${REG_UPDATES_PATH}" "CheckForUpdates" "1"
    WriteRegStr   HKCU "${REG_UPDATES_PATH}" "DidRunOnce" "1"

    ;Start menu links
    SetShellVarContext current
    CreateShortCut "${START_LINK_RUN}" "$INSTDIR\LiveReload.exe"
FunctionEnd

Function un.DeregisterApplication
    DeleteRegKey HKCU "${REG_UNINSTALL}"
    DeleteRegKey HKCU "${REG_APP_PATH}"
    
    ;Start menu links
    SetShellVarContext current
    Delete "${START_LINK_RUN}"
FunctionEnd

# INSTALL SECTIONS
Section LiveReload
    SectionIn RO
    
    SetOutPath $INSTDIR
    SetOverwrite on

    File WinSparkle\WinSparkle.dll

    !include files.nsi    
        
    WriteUninstaller "$INSTDIR\${UNINSTALLER_NAME}"

    Call RegisterApplication
SectionEnd

Section "Uninstall"
    RmDir /r "$INSTDIR"
    
    Call un.DeregisterApplication
SectionEnd
