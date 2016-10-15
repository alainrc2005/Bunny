{$DEFINE xHighPriority}
unit mainVisualizador;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, DXDraws, DXClass;
type
  Tfmain = class(TDXForm)
    procedure AppOnIdle(Sender: TObject; var Done: Boolean);
    procedure AppOnActivate(Sender: TObject);
    procedure AppOnDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure AppException(Sender: TObject; E: Exception);
  end;

var
  fmain: Tfmain;

implementation

{$R *.DFM}
Uses VisualMain, SetupVars;

procedure Tfmain.AppOnIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if Visualizador.RenderFrame then
   begin
    Visualizador.Free;
    Close;
   end;
 end;

procedure Tfmain.AppOnActivate(Sender: TObject);
begin
{$IFDEF HighPriority}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);
{$ENDIF}
  Screen.Cursor := crNone;
  if not GameInitialized then exit;
  GameAvailable := true;
end;

procedure Tfmain.AppOnDeactivate(Sender: TObject);

begin
  Screen.Cursor := crDefault;
  GameAvailable := false;
{$IFDEF HighPriority}
  SetPriorityClass(GetCurrentProcess, IDLE_PRIORITY_CLASS);
{$ENDIF}
end;

procedure Tfmain.FormDestroy(Sender: TObject);
begin
 Screen.Cursor := crDefault;
{$IFDEF HighPriority}
 SetPriorityClass(GetCurrentProcess, NORMAL_PRIORITY_CLASS);
{$ENDIF}
 DXClose;
end;

procedure Tfmain.AppException(Sender: TObject; E: Exception);
 begin
  halt;
 end;

procedure Tfmain.FormCreate(Sender: TObject);
begin
 if FullScreen then BorderStyle := bsNone;
 {inicializacion de variables aqui}
 Application.OnIdle       := AppOnIdle;
 Application.OnActivate   := AppOnActivate;
 Application.OnDeactivate := AppOnDeactivate;
 Application.OnRestore    := AppOnActivate;
 Application.OnMinimize   := AppOnDeActivate;
 Application.OnMessage := AppMessage;
 Application.OnException := AppException;
end;

procedure Tfmain.AppMessage(var Msg: TMsg; var Handled: Boolean);
 var
  a,b : word;
 begin
  if (not GameReady) or (not GameAvailable) then exit;
  if Msg.message = WM_MOUSEMOVE then
    begin
     a := LoWord(Msg.lParam);
     b := HiWord(Msg.lParam);
     if a > 640-52 then a := 640-52;
     if b > 480-51 then b := 480-51;
     Msg.lParam := MakeLong(a,b);
    end;
 end;

procedure Tfmain.FormShow(Sender: TObject);
begin
 if not GameInitialized then
  begin
   try
    DXInit(Self,640,480,16);
    Visualizador := TVisualizador.Create;
   except
   end;
   GameReady := true;
   GameInitialized := true;
  end;
end;

end.
