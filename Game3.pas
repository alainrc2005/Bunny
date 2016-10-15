unit Game3;

interface

uses DXDraws, DXInput, Mouse, Module;

type
 TFarProcObj = function : byte of object;

function IDGame : Integer; stdcall;
function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
procedure CoDestroyGame; stdcall;

implementation

Uses Windows, Classes, Controls, JuegoComun, VarsComun;

type
 TBicho  = class;
 TGame3 = class(TJuego)
 private
  lib : TILib;
  images : array[0..40] of TAutomaticSurfaceLib;

  imgIndex : dword;

  bugs : array[1..8] of TBicho;
  xc,yc  : integer; {coordenadas del conejito}
  tc     : byte;
  KeyTick : dword;
  op : byte;
  Right, Left, Up, Down : boolean;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure TryAgain;
  procedure updateKeyboard;
  function updateCollision : boolean;

  procedure PrepareRenderTriste;
 public
  constructor Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
  destructor Destroy; Override;
  function RenderGame : byte;
 end;

TBicho  = class
 private
  xx,yy : word;
  decvel : dword;
  velocity : dword;
  factor : shortint;
  bbegin,bend : word;
  owner : TGame3;
 public
  constructor Create(i : byte; mOwner : TGame3);
  destructor Destroy; override;
  procedure Anima(Value : boolean = true);
  function Collision: boolean;
end;


const
 // Game Options

 LoadGameComun = 0;
 LoadGame      = 1;
 RenderRun     = 2;
 QuitGame      = 3;
 RenderTriste  = 5;
 RenderAlegre  = 6;
 RenderAyuda   = 7;

var
 ju3 : TGame3;

constructor TGame3.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego3.lib');
  options := LoadGameComun;
  SndLib := TSoundLibrary.Create('Lib\Juego3.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 3 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  imgIndex := 0;
  for i := 1 to 8 do bugs[i] := TBicho.Create(i,self);
  op := 0; TryAgain; KeyTick := GetTickCount;
  Right := false; Left := false; Up := false; Down := false;
 end;

destructor TGame3.Destroy;
 var
  i : integer;
 begin
  FreeAllEffects;
  fSound.StopModule;
  SndLib.FreeModule(musica);
  SndLib.Free;
  for i := 1 to 8 do bugs[i].Free;
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TGame3.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame3.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then PrepareRenderTriste else
  begin
   if (Y > yc) and (Y < yc+50) then
    if X > xc+11 then Right := true else Left := true else
     if Y < yc+24 then Up := true else Down := true;
  end;
end;

procedure TGame3.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  Right := false;
  Left := false;
  Up := false;
  Down := false;
 end;

procedure TGame3.UpdateAyuda;
 var
  i : byte;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 1 to 8 do bugs[i].Anima(false);
  scr.surface.draw(xc,yc,images[tc].surface,true);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame3.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 1 to 8 do bugs[i].Anima;
  scr.surface.draw(xc,yc,images[tc].surface,true);
 end;

function TGame3.updateCollision : boolean;
 var
  i : byte;
 begin
  result := false;
  for i := 1 to 8 do
   if bugs[i].Collision then
    begin
     efectos[3].Play;
     tryagain;
     exit;
    end;
  result := SurfaceCollision(xc,yc,512,166,images[tc].Surface,images[39].Surface,true);
 end;

function TGame3.RenderGame : byte;
 begin
  result := 0;
  key.Update;
  case options of
   LoadGameComun : begin
    if inherited RenderLoad then options := LoadGame;
   end;
   LoadGame : begin
    if RenderLoad then
     begin
      options := RenderRun;
      fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
      fMouse.RestoreAllEvents;
     end;
   end; // end of loadgame
   RenderRun : begin
    if updateCollision then
     begin
      Prepare(True);
      options := RenderAlegre;
      efectos[1].Play;
     end;
    updateKeyBoard;
    if isEscape in key.States then PrepareRenderTriste;
    if isF1 in key.States then options := RenderAyuda;
    UpdateGame(True);
   end;
   RenderTriste : begin
    UpdateGame(False);
    if AnimaTriste then result := 2;
   end;
   RenderAlegre : begin
    UpdateGame(False);
    if AnimaAlegre then result := 1;
   end;
   RenderAyuda : begin
    ProcessHelp(RenderRun,2,4);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame3.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

procedure TGame3.tryagain;
 begin
  xc := 80;
  yc := 160;
  tc := 8;
  inc(op);
  if op = 6 then PrepareRenderTriste;
 end;

procedure TGame3.updateKeyboard;
 begin
  if GetTickCount - KeyTick < 35 then exit;
  KeyTick := GetTickCount;
  if (isRight in key.KeyBoard.States) or Right then if not (tc in [8..10]) then tc := 8
   else
    begin
     if xc < 508 then inc(xc);
     if tc = 10 then tc := 8 else inc(tc);
    end;;
  if (isLeft in key.KeyBoard.States) or Left then if not (tc in [11..13]) then tc := 11
   else
    begin
     if xc > 80 then dec(xc);
     if tc = 13 then tc := 11 else inc(tc);
    end;
  if (isDown in key.KeyBoard.States) or Down then if not (tc in [2..4]) then tc := 2
   else
    begin
     if yc < 282 then inc(yc);
     if tc = 4 then tc := 2 else inc(tc);
    end;
  if (isUp in key.KeyBoard.States) or Up then if not (tc in [5..7]) then tc := 5
   else
    begin
     if yc > 64 then dec(yc);
     if tc = 7 then tc := 5 else inc(tc);
    end;
 end;

 ///////////////////////////////////////////////
/////////////////////////////////////////////////
///                                           ///
///       BBB   IIIII   CCC  H  H   OOO       ///
///       B  B    I    C     H  H  O   O      ///
///       BBB     I    C     HHHH  O   O      ///
///       B  B    I    C     H  H  O   O      ///
///       BBB   IIIII   CCC  H  H   OOO       ///
///                                           ///
/////////////////////////////////////////////////
 ///////////////////////////////////////////////

const
 velo : array[1..4] of word = (30,50,70,110);

constructor TBicho.Create(i : byte; mOwner : TGame3);
 begin
  owner := mOwner;
  xx := 160+(i-1)*40;
  yy := 58+random(266);
  velocity := velo[random(4)+1];
  if random(50) > 25 then factor := 1 else factor := -1;
  bbegin := 14 + random(5)*5;
  bend := bbegin+4;
  decvel := GetTickCount;
 end;

destructor TBicho.Destroy;
 begin
  inherited Destroy;
 end;

procedure TBicho.anima;
 var
  clip : TDirectDrawClipper;
  x : TRect;
 begin
  if Value then
  if GetTickCount - decvel >= velocity then
   begin
    decvel := GetTickCount;
    if (yy >= 333) or (yy <= 40)  then factor := -factor;
    inc(yy,factor);
    if bbegin=bend then bbegin := bend-4 else inc(bbegin);
   end;
  clip := TDirectDrawClipper.Create(owner.scr.DDraw);
  x := rect(66,66,556,332);
  clip.SetClipRects(x);
  with owner.scr.surface do
   begin
    Clipper := clip;
    draw(xx,yy,owner.images[bbegin].surface,true);
    Clipper := nil;
   end;
  clip.Free;
 end;

function TBicho.Collision: boolean;
 begin
  with owner do
   result := SurfaceCollision(xx,yy,xc,yc,images[bbegin].Surface,images[tc].Surface,true);
 end;


function IDGame : Integer; stdcall;
 begin
  Result := 12;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju3 := TGame3.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju3.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju3.Free;
 end;

end.
