program Configurador;

uses
  Forms,
  Windows,
  Dialogs,
  DirectSetup,
  mainsetup in 'mainsetup.pas' {fmain},
  SetupMain in 'SetupMain.pas';

{$R *.RES}

 var
  dx1,dx2 : dword;
  dxResult : integer;

begin
 try
  dxResult := DirectXSetupGetVersion(dx1,dx2);
  if (dxResult = 0) or (dx1 < $00040005) then
   begin
    ShowMessage('El configurador del juego Bunny necesita Microsoft DirectX 5.0 o superior');
    halt;
   end;
 except
  ShowMessage('Es posible que el juego esté mal instalado,'^M+
              'recuerde que necesita Microsoft DirectX 5.0 o superior.'^M+
              'Por favor reinstale.');
  halt;
 end;
  Application.Initialize;
  Application.Title := 'Bunny - Configurador';
  Application.CreateForm(Tfmain, fmain);
  Application.Run;
end.
