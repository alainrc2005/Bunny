Program Detect;

uses
  Forms,
  Windows,
  DirectSetup,
  MyDlgs,
  ShellAPI;

{$R *.res}
procedure getversion;
var
 path : string;
 i    : integer;
 dx1,dx2 : dword;
 dxResult : integer;
begin
 path := '';
 for i := 1 to paramcount do
  path := path+paramstr(i)+' ';
 delete (path,length(path),1);
 path := path+'\';
 try
  dxResult := DirectXSetupGetVersion(dx1,dx2);
  if (dxResult = 0) or (dx1 < $00040005) then
    begin
     MyMessageDlg ('Se ha detectado una versión del Directx inferior a la 5.'^M+
                   'Se procederá a instalar DirectX versión 8.0 en su PC.',mtinformation,[mbok],0);
     ShellExecute (Application.Handle,'open',pchar(path+'dxsetup.exe'),'','',SW_SHOWNORMAL);
    end;
 except
  MyMessageDlg('Error detectando versión del Microsoft DirectX',mtError,[mbOk],0)
 end;
end;

begin
 Application.Initialize;
 Application.Title := 'DirectX Detect';
 Application.Run;
 GetVersion;
end.
