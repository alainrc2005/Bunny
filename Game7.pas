unit Game7;

interface

uses DXDraws, DXInput, Mouse, Module;

type
 TFarProcObj = function : byte of object;

function IDGame : Integer; stdcall;
function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
procedure CoDestroyGame; stdcall;

implementation

Uses Windows, Classes, Controls, JuegoComun, VarsComun;

Type
 TGame7 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..10] of TAutomaticSurfaceLib;

  imgIndex : dword;


  tc        : byte;
  xf,yz     : word;
  zana      : byte;
  dirzana : shortint;
  zanaTick : dword;
  zanaSpeed : byte;
  Arco : boolean;
  arcoTick : dword;
  doble : boolean;

  op : byte;
  tirar : boolean;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure AnimaZanahoria;
  procedure AnimaArco;
  procedure updateKeyBoard;
  procedure AnimaFlecha;
  procedure Collision;
  procedure PrepareRenderTriste;

 public
  constructor Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
  destructor Destroy; Override;
  function RenderGame : byte;
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

 limitedy : array[1..3] of word = (274,294,306); // para juego7 y 8


var
 ju7 : TGame7;

constructor TGame7.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego7.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego7.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 3 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  tc := 6;
  yz := 80+random(80);
  if random(100) > 50 then dirzana := -2 else dirzana := 2;
  zana := random(3)+2; zanaTick := GetTickCount;
  Arco := false;  doble := false;
  zanaSpeed := 8+random(4)*10; op := 0; tirar := false;
 end;

destructor TGame7.Destroy;
 var
  i : integer;
 begin
  FreeAllEffects;
  fSound.StopModule;
  SndLib.FreeModule(musica);
  SndLib.Free;
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TGame7.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame7.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then PrepareRenderTriste else
  tirar := true;
end;

procedure TGame7.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  tirar := false;
 end;

procedure TGame7.UpdateGame(Value : boolean);
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  if Value then
   begin
    AnimaArco;
    AnimaZanahoria;
    AnimaFlecha;
   end
  else
   begin
    scr.surface.draw(400,yz,images[zana].surface,true);
    AnimaFlecha;
   end;
  scr.surface.draw(86,158,images[tc].surface,true);
 end;

procedure TGame7.UpdateAyuda;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  scr.surface.draw(400,yz,images[zana].surface,true);
  if doble then scr.surface.Draw(xf,186,images[10].surface,true);
  scr.surface.draw(86,158,images[tc].surface,true);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame7.AnimaFlecha;
 begin
  if not doble then exit;
  if GetTickCount - arcoTick >= 20 then
   begin
    arcoTick := GetTickCount;
    if xf < 520 then inc(xf,8)
     else
     begin
      doble := false;
      inc(op);
      if op = 3 then PrepareRenderTriste;
     end;
   end;
  scr.surface.Draw(xf,186,images[10].surface,true);
 end;

procedure TGame7.AnimaZanahoria;
 begin
  if GetTickCount - zanaTick  >= zanaSpeed then
   begin
    if (yz <=64) or (yz>=limitedy[zana-1]) then dirzana :=-dirzana;
    inc(yz,dirzana);
    zanaTick := GetTickCount;
   end;
  scr.surface.draw(400,yz,images[zana].surface,true);
 end;

procedure TGame7.AnimaArco;
 begin
  if not Arco then exit;
  if GetTickCount - arcoTick >=120 then
   begin
    arcoTick := GetTickCount;
    if tc = 9 then
     begin
      tc := 6;
      Arco := false;
      doble := true;
      efectos[3].Play;
     end else inc(tc);
   end;
 end;

procedure TGame7.Collision;
 begin
  if not doble then exit;
  if SurfaceCollision(xf,186,400,yz,images[10].surface,images[zana].surface,true) and (xf < 390) then
   begin
    doble := false;
    Prepare(True);
    options := RenderAlegre;
    efectos[1].Play;
   end;
 end;

procedure TGame7.updateKeyBoard;
 begin
  if isEscape in key.keyboard.states then PrepareRenderTriste;
  if ((isSpace in key.keyboard.states) or Tirar) and not (doble or Arco) then
   begin
    Tirar := false;
    Arco := true;
    arcoTick := GetTickCount;
    xf := 116;
   end;
  if isF1 in key.States then options := RenderAyuda;
 end;

function TGame7.RenderGame : byte;
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
    Collision;
    UpdateGame(True);
    updateKeyboard;
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
    ProcessHelp(RenderRun,5,4);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame7.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 16;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju7 := TGame7.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju7.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju7.Free;
 end;

end.
