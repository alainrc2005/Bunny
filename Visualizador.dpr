program Configurador;

uses
  Forms,
  Windows,
  DirectSetup,
  Dialogs,
  mainVisualizador in 'mainVisualizador.pas' {fmain},
  Ayuda in 'Ayuda.pas',
  VisualMain in 'VisualMain.pas';

{$R Visualizador.RES}

 var
  dx1,dx2 : dword;
  dxResult : integer;

begin
 try
  dxResult := DirectXSetupGetVersion(dx1,dx2);
  if (dxResult = 0) or (dx1 < $00040005) then
   begin
    ShowMessage('El visualizadr del juego Bunny necesita Microsoft DirectX 5.0 o superior');
    halt;
   end;
 except
  ShowMessage('Es posible que el juego esté mal instalado,'^M+
              'recuerde que necesita Microsoft DirectX 5.0 o superior.'^M+
              'Por favor reinstale.');
  halt;
 end;
  Application.Initialize;
  Application.Title := 'Bunny - Visualizador';
  Application.CreateForm(Tfmain, fmain);
  Application.Run;
end.
