program Bunny;

uses
  Forms,
  Windows,
  Dialogs,
  DirectSetup,
  main in 'main.pas' {fmain},
  GameMain in 'GameMain.pas',
  Vars in 'Vars.pas',
  Scroll in 'Scroll.pas',
  ambiente in 'Ambiente.pas',
  Zanahorias in 'Zanahorias.pas',
  Peligros in 'Peligros.pas',
  VarsComun in 'VarsComun.pas',
  Manzanas in 'Manzanas.pas',
  Cueva in 'Cueva.pas',
  Piedras in 'Piedras.pas',
  present in 'Present.pas';

{$R *.RES}

 var
  dx1,dx2 : dword;
  dxResult : integer;

begin
 try
  dxResult := DirectXSetupGetVersion(dx1,dx2);
  if (dxResult = 0) or (dx1 < $00040005) then
   begin
    ShowMessage('El juego Bunny necesita Microsoft DirectX 5.0 o superior');
    halt;
   end;
 except
  ShowMessage('Es posible que el juego esté mal instalado,'^M+
              'recuerde que necesita Microsoft DirectX 5.0 o superior.'^M+
              'Por favor reinstale.');
  halt;
 end;
  Application.Initialize;
  Application.Title := 'Bunny';
  Application.CreateForm(Tfmain, fmain);
  Application.Run;
end.
