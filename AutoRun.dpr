program AutoRun;

uses
  Forms,
  mainAutoRun in 'mainAutoRun.pas' {fmain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Bunny - AutoRun';
  Application.CreateForm(Tfmain, fmain);
  Application.Run;
end.
