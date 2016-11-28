
#define MyAppName "Twitch Bundle"
#define MyAppVersion "1.0"
;#define MyAppPublisher "My Company, Inc."
;#define MyAppURL "http://www.example.com/"

#define TwitchGuiRepo "bastimeyer/livestreamer-twitch-gui"
#define StreamlinkRepo "streamlink/streamlink"
#define MpvUrl "https://mpv.srsfckn.biz/mpv-i686-latest.7z"

#define TwitchGuiTmp "{tmp}\livestreamer-twitch-gui.zip"
#define StreamlinkTmp "{tmp}\streamlink.exe"
#define MpvTmp "{tmp}\mpv.7z"

#define TwitchGuiPath "{app}\livestreamer-twitch-gui"
#define StreamlinkPath "{app}\streamlink"
#define MpvPath "{app}\mpv"

#define GuiAppName "Livestreamer Twitch GUI"
#define GuiAppExeName TwitchGuiPath + "\livestreamer-twitch-gui.exe"

#include <idp.iss>
#include "unzip.iss"

[Setup]
AppId={{CCAB6218-E38A-4D98-86EB-50C0399523DE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppPublisher={#MyAppPublisher}
;AppPublisherURL={#MyAppURL}
;AppSupportURL={#MyAppURL}
;AppUpdatesURL={#MyAppURL}
DefaultDirName={userappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=bundle-{#MyAppVersion}
UninstallDisplayIcon={#GuiAppExeName}
InfoBeforeFile=Info.txt
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "data\Local Storage\app_livestreamer-twitch-gui_0.localstorage"; DestDir: "{localappdata}\livestreamer-twitch-gui\Local Storage"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "bin\7z.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "bin\7z.dll"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "bin\GitHubReleases.dll"; DestDir: "{tmp}"; Flags: dontcopy

[Icons]
Name: "{userprograms}\{#GuiAppName}"; Filename: "{#GuiAppExeName}"
Name: "{userdesktop}\{#GuiAppName}"; Filename: "{#GuiAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{#GuiAppExeName}"; Flags: nowait postinstall skipifsilent; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"

[UninstallDelete]
Type: filesandordirs; Name: "{#TwitchGuiPath}"
Type: filesandordirs; Name: "{#MpvPath}"
Type: filesandordirs; Name: "{#StreamlinkPath}"

[Code]

function ShellExecute(hwnd: HWND; lpOperation: String; lpFile: String;
  lpParameters: String; lpDirectory: String; nShowCmd: Integer): THandle;
  external 'ShellExecuteW@shell32.dll stdcall';
function GetLatestReleaseLink(Repo, Pattern: WideString; out Res: WideString): Integer;
  external 'GetLatestReleaseLink@files:GitHubReleases.dll stdcall setuponly';

var 
  Extracting: TNewStaticText;

procedure InitializeWizard();
var
  Url: WideString;
  Size: Integer;
begin
  Size := GetLatestReleaseLink('{#TwitchGuiRepo}', 'win32', Url);
  idpAddFileSize(Url, ExpandConstant('{#TwitchGuiTmp}'), Size);
  
  Size := GetLatestReleaseLink('{#StreamlinkRepo}', '\.exe', Url);
  idpAddFileSize(Url, ExpandConstant('{#StreamlinkTmp}'), Size);
  
  idpAddFile('{#MpvUrl}', ExpandConstant('{#MpvTmp}'));
  (*
  idpAddFile('http://localhost:8000/livestreamer-twitch-gui-v0.16.0-win32.zip', ExpandConstant('{#TwitchGuiTmp}'));
  idpAddFile('http://localhost:8000/streamlink-0.1.0.exe', ExpandConstant('{#StreamlinkTmp}'));
  idpAddFile('http://localhost:8000/mpv-i686-20161120.7z', ExpandConstant('{#MpvTmp}'));
  *)
  idpDownloadAfter(wpReady);
  
  Extracting := TNewStaticText.Create(WizardForm);
  with WizardForm.ProgressGauge do
  begin
    Extracting.Parent := WizardForm.InstallingPage;
    Extracting.Autosize := False;
    Extracting.Width := Width;
    Extracting.Top:=Top + ScaleX(35);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then 
  begin
    Extracting.Caption := 'Extracting Livestreamer Twitch GUI...';
    UnZip('{#TwitchGuiTmp}', '{app}');

    Extracting.Caption := 'Extracting mpv...';
    UnZip('{#MpvTmp}', '{#MpvPath}');
    
    Extracting.Caption := 'Extracting Streamlink...';
    UnZip('{#StreamlinkTmp}', '{#StreamlinkPath}');
    
    // Shebang in streamlink must be rewritten to actual python location
    ShellExecute(0, 'open',
      ExpandConstant('{#StreamlinkPath}\Python\pythonw.exe'),
      ExpandConstant('"{#StreamlinkPath}\_rewrite_shebangs.py" "{#StreamlinkPath}\bin"'),
      '', SW_SHOW);
  end;
end;
