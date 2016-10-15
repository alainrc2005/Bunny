unit JuegoComun;

interface

Uses Windows, Classes, DXDraws, DXInput, VarsComun, Mouse, Module, Ayuda, ModTypes;

type
 TJuego = class // clase comun a los juegos;
  private
  protected
   imgcomun : array[0..9] of TAutomaticSurfaceLib;
   TATick : dword;
   ci,cj : smallint;
   lib : TILib;
   imgIndex : dword;
   function AnimaTriste : boolean;
   function AnimaAlegre : boolean;
   function RenderLoad : boolean;
  protected
   options : word;
   fAyuda : TAyuda;
   scr : TDXDraw;
   key : TDXInput;
   fMouse : Mouse.TMouse;
   fSound : TSoundSystem;
   SndLib : TSoundLibrary;
   musica : TMod;
   efectos : array[1..5] of TWavLib;
   fSalir : boolean;
   fSonido: boolean;
   procedure MouseMove(Shift: TShiftState; X, Y: Integer);
   procedure ProcessHelp(Value : word; Index, IndexMusic : integer);
   procedure UpdateAyuda; virtual; Abstract;
   function  ActualSound(X,Y : Integer) : boolean;
   procedure StopAllEffects;
   procedure FreeAllEffects;
  public
   constructor Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
   destructor Destroy; Override;
   procedure Prepare(Value : Boolean);
 end;

implementation

constructor TJuego.Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
 var
  i : byte;
 begin
  Randomize;
  scr := screen;
  key := KeyBoard;
  fSound := Sound;
  fMouse := Mouse;
  fSalir := false;
  lib := TILib.Create(scr, 'Lib\Comun.lib');
  imgIndex := 0;
  fAyuda := nil;
  for i := 1 to 5 do efectos[i] := nil;
  fSonido := fSound.Music or fSound.Effect;
 end;

destructor TJuego.Destroy;
 var
  i : byte;
 begin
  for i := 0 to lib.ImageCount-1 do imgcomun[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TJuego.MouseMove(Shift: TShiftState; X, Y: Integer);
 begin
  fSalir := ptinrect(rect(560,0,608,29),Point(X,Y));
 end;

function TJuego.AnimaAlegre : boolean;
 begin
  if GetTickCount - TATick >=220 then
   begin
    if ci = 4 then
     begin
      ci := 2;
      inc(cj);
     end else inc(ci);
    TATick := GetTickCount;
   end;
  scr.surface.Draw(518,342,imgcomun[ci].Surface,true);
  result := cj=5;
 end;

function TJuego.AnimaTriste : boolean;
 begin
  if GetTickCount - TATick >=220 then
   begin
    if ci = 7 then
     begin
      ci := 5;
      inc(cj);
     end else inc(ci);
    TATick := GetTickCount;
   end;
  scr.surface.Draw(518,342,imgcomun[ci].Surface,true);
  result := cj=5;
 end;

function TJuego.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,imgcomun[imgIndex]);
  imgcomun[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
 end;

procedure TJuego.Prepare(Value : Boolean);
{Value true=Alegre false=Triste}
 begin
  fMouse.SetMouseEvent(nil,nil,nil);
  TATick := GetTickCount;
  if Value then
   begin
    ci := 2;
    cj := 0;
   end
  else
   begin
    ci := 5;
    cj := 0;
   end;
 end;

procedure TJuego.ProcessHelp(Value : word; Index, IndexMusic : integer);
 begin
  if fAyuda = nil then
   begin
    try
     fAyuda := TAyuda.Create(Index,scr);
     key.ClearStates;
    except
     options := Value;
     exit;
    end;
    SndLib.LoadModFromLibrary(IndexMusic,HelpMusic);
    fSound.StopModule;
    fSound.PlayModule(HelpMusic);
   end else UpdateAyuda;
  if (key.Keyboard.States <> [isF1]) and (key.Keyboard.States <> []) then
   begin
    fSound.StopModule;
    fSound.PlayModule(musica);
    fAyuda.Free;
    fAyuda := nil;
    key.ClearStates;
    options := Value;
   end;
 end;

function TJuego.ActualSound(X,Y : Integer) : boolean;
 begin
  result := PtInRect(Rect(518,0,543,29),Point(X,Y));
  if result then
   begin
    if fSound.ExistSound then
     begin
      if fSound.SaveMusic then fSound.Music := not fSound.Music;
      if fSound.SaveEffect then fSound.Effect := not fSound.Effect;
      fSonido := fSound.Music or fSound.Effect;
      if fSonido then fSound.PlayModule(musica) else
       begin
        StopAllEffects;
        fSound.StopModule;
       end;
     end;
   end;
 end;

procedure TJuego.StopAllEffects;
 var
  i : byte;
 begin
  for i := 1 to 5 do if assigned(efectos[i]) then efectos[i].Play;
 end;

procedure TJuego.FreeAllEffects;
 var
  i : byte;
 begin
  for i := 1 to 5 do if assigned(efectos[i]) then efectos[i].Free;
 end;

end.
