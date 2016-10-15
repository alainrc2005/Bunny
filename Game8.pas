unit Game8;

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
 TBicho = class;

 TGame8 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..26] of TAutomaticSurfaceLib;

  imgIndex : dword;


  bugs : array[1..3] of TBicho;
  yc        : word; // coordenadas y del conejito}
  tc        : byte; // tipo de conejo
  zana      : byte; // zanahoria
  xf,yz     : word; // coordenadas de la flecha
  KeyTick : dword;
  Arco : boolean;
  arcoTick : dword;
  doble : boolean;
  zanaTick : dword;
  zanaSpeed : byte;
  dirzana : shortint;
  op : byte;
  Up, Down, Fire : boolean;

 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure AnimaZanahoria;
  procedure updateKeyboard;
  procedure AnimaArco;
  procedure AnimaFlecha;
  procedure Collision;
  procedure GameOver;

  procedure PrepareRenderTriste;
 public
  constructor Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
  destructor Destroy; Override;
  function RenderGame : byte;
 end;

 TBicho  = class
  private
   owner : TGame8;
   xx,yy : word;   {coordenadas de los bichos}
   decvel : dword;
   velocity : byte;
   factor : shortint;
   bbegin : word;
   nbich  : byte;
   clip : TDirectDrawClipper;
   fRect : TRect;
   procedure reallybegin;
  public
   constructor Create(i : byte; mOwner : TGame8);
   destructor Destroy; override;
   procedure Anima;
   procedure AnimaWithOutMove;
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

 limitedy : array[1..3] of word = (274,294,306); // para juego7 y 8

var
 ju8 : TGame8;

constructor TGame8.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego8.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego8.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 4 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  for i := 1 to 3 do bugs[i] := TBicho.Create(i,self);
  KeyTick := GetTickCount;
  tc := 22; yc := 160;
  Arco := false;  doble := false;
  if random(100) > 50 then dirzana := -1 else dirzana := 1;
  zana := random(3)+18; zanaTick := GetTickCount;
  yz := 80+random(80);
  zanaSpeed := 8+random(4)*10; op := 0; Up := False; Down := False; Fire := False;
 end;

destructor TGame8.Destroy;
 var
  i : integer;
 begin
  FreeAllEffects;
  fSound.StopModule;
  SndLib.FreeModule(musica);
  SndLib.Free;
  for i := 1 to 3 do bugs[i].Free;
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TGame8.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame8.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then PrepareRenderTriste else
  if (Y > yc) and (Y < yc+50) then Fire := true else if Y > yc+50 then Down := true else Up := true;
end;

procedure TGame8.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  Up := false;
  Down := false;
  Fire := false;
 end;

procedure TGame8.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  if Value then
   begin
    for i := 1 to 3 do bugs[i].Anima;
    AnimaArco;
    AnimaZanahoria;
    AnimaFlecha;
   end
  else
   begin
    for i := 1 to 3 do bugs[i].AnimaWithOutMove;
    scr.surface.draw(480,yz,images[zana].surface,true);
    AnimaFlecha;
   end;
  scr.surface.draw(100,yc,images[tc].surface,true);
 end;

procedure TGame8.UpdateAyuda;
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 1 to 3 do bugs[i].AnimaWithOutMove;
  scr.surface.draw(480,yz,images[zana].surface,true);
  if doble then scr.surface.Draw(xf,yc+20,images[26].surface,true);
  scr.surface.draw(100,yc,images[tc].surface,true);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame8.AnimaZanahoria;
 begin
  if GetTickCount - zanaTick  >= zanaSpeed then
   begin
    if (yz <=64) or (yz=limitedy[zana-17]) then dirzana :=-dirzana;
    inc(yz,dirzana);
    zanaTick := GetTickCount;
   end;
  scr.surface.draw(480,yz,images[zana].surface,true);
 end;

procedure TGame8.AnimaArco;
 begin
  if not Arco then exit;
  if GetTickCount - arcoTick >=120 then
   begin
    arcoTick := GetTickCount;
    if tc = 25 then
     begin
      tc := 22;
      Arco := false;
      doble := true;
      efectos[3].Play;
     end else inc(tc);
   end;
 end;

procedure TGame8.GameOver;
 begin
  inc(op);
  if op = 5 then PrepareRenderTriste;
 end;

procedure TGame8.AnimaFlecha;
 begin
  if not doble then exit;
  if GetTickCount - arcoTick >= 20 then
   begin
    arcoTick := GetTickCount;
    if xf < 520 then inc(xf,4)
     else
     begin
      doble := false;
      GameOver;
     end;
   end;
  scr.surface.Draw(xf,yc+20,images[26].surface,true);
 end;

procedure TGame8.Collision;
 var
  i : byte;
 begin
  if not doble then exit;
  if SurfaceCollision(xf,yc+20,480,yz,images[26].surface,images[zana].surface,true) then
   begin
    doble := false;
    Prepare(True);
    options := RenderAlegre;
    efectos[1].Play;
   end;
  for i := 1 to 3 do if bugs[i].Collision then
   begin
    efectos[4].Play;
    doble := false;
    GameOver;
    Break;
   end;
 end;

procedure TGame8.updateKeyboard;
 begin
  if isF1 in key.States then options := RenderAyuda;
  if isEscape in key.keyboard.states then
   begin
    PrepareRenderTriste;
    exit;
   end;
  if (GetTickCount - KeyTick < 40) then exit;
  KeyTick := GetTickCount;
  if (isUp in key.keyboard.states) or Up then if not (tc in [15..17]) then tc := 15 else
   begin
    if yc > 66 then dec(yc);
    if tc = 17 then tc := 15 else inc(tc);
   end else
  if  (isDown in key.keyboard.states) or Down then if not (tc in [12..14]) then tc := 12 else
   begin
    if yc < 283 then inc(yc);
    if tc = 14 then tc := 12 else inc(tc);
   end else
  if ((isSpace in key.keyboard.states) or Fire) and not (doble or Arco) then
   begin
    tc := 22;
    xf := 132;
    Arco := true;
    arcoTick := GetTickCount;
   end else if  not (doble or Arco) then tc := 22;
 end;

function TGame8.RenderGame : byte;
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
    ProcessHelp(RenderRun,5,5);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame8.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
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
 arriba : array[1..6] of byte = (2,3,4,5,6,6);
 abajo  : array[1..6] of byte = (7,8,9,10,11,11);

constructor TBicho.Create(i : byte; mOwner : TGame8);
 begin
  owner := mOwner;
  xx := 240 + (i-1)*50;
  yy := 76+random(160);
  velocity := random(3)+1;
  if random(50) > 25 then factor := 1 else factor := -1;
  nbich := random(3);
  reallybegin;
  decvel := GetTickCount;
  clip := TDirectDrawClipper.Create(owner.scr.DDraw);
  fRect := rect(66,66,556,332);
 end;

destructor TBicho.Destroy;
 begin
  inherited Destroy;
  clip.Free;
 end;

procedure TBicho.reallybegin;
 begin
  if factor = -1 then bbegin := arriba[nbich*2+1] else bbegin := abajo[nbich*2+1];
 end;

procedure TBicho.Anima;
 begin
  if GetTickCount - decvel >= 200 then
   begin
    decvel := GetTickCount;
    if (yy >= 330) or (yy <= 1)  then
     begin
      factor := -factor;
      reallybegin;
     end;
    inc(yy,factor*velocity);
    case factor of
     1 : if bbegin=abajo[nbich*2+2] then bbegin := abajo[nbich*2+1] else inc(bbegin);
     -1: if bbegin=arriba[nbich*2+2] then bbegin := arriba[nbich*2+1] else inc(bbegin);
    end;
   end;
  clip.SetClipRects(fRect);
  with owner.scr.surface do
   begin
    Clipper := clip;
    draw(xx,yy,owner.images[bbegin].surface,true);
    Clipper := nil;
   end;
 end;

procedure TBicho.AnimaWithOutMove;
 var
  clip : TDirectDrawClipper;
  x : TRect;
 begin
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
   result := SurfaceCollision(xx,yy,xf,yc+13,images[bbegin].surface,images[26].surface,true);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 17;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju8 := TGame8.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju8.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju8.Free;
 end;

end.
