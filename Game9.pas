unit Game9;

interface

uses DXDraws, DXInput, Mouse, Module;

type
 TFarProcObj = function : byte of object;

function IDGame : Integer; stdcall;
function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
procedure CoDestroyGame; stdcall;

implementation

Uses Windows, Classes, Controls, JuegoComun, VarsComun, SysUtils;

type
 TObjectUpdate = record
  cX,cY,cIndex : Integer;
  Transparent : boolean;
 end;
 PObjectUpdate = ^TObjectUpdate;

 TPiedra = record
  cxp : word;
  tick : dword;
  speed : byte;
  sig : shortint;
 end;

 TGame9 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..32] of TAutomaticSurfaceLib;

  imgIndex : dword;

  objectUpdate : TList;

  cxr,cyr  : word; {coordenadas del conejito}
  piedra   : array[1..2] of TPiedra; {piedras}
  tc       : byte; {animacion del conejito}
  KeyTick : dword;
  salto : boolean;
  saltoTick : dword;
  Right, Left, Up : boolean;

 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);

  procedure AnimaPiedras;
  procedure updateKeyboard;
  procedure AnimaSalto;

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
 RenderCaida   = 7;
 RenderAyuda   = 8;

const
 tipo : array[1..2] of TPoint = ((X:138;Y:272),(X:317;Y:452));


var
 ju9 : TGame9;

constructor TGame9.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego9.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego9.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 4 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  objectUpdate := TList.Create;

  for i := 1 to 2 do
   with piedra[i] do
    begin
     if random(100) > 50 then sig := 1 else sig := -1;
     if i=1 then cxp := 164+random(40) else cxp := 340+random(40);
     Speed := 8+random(4)*10;
     tick := GetTickCount;
    end;
  cxr := 76; cyr := 146;
  tc := 9;
  KeyTick := GetTickCount;
  salto := false; Right := false; Left := false; Up := false;
  CreateObject(286,194,7,true);
 end;

destructor TGame9.Destroy;
 var
  i : integer;
 begin
  FreeAllEffects;
  fSound.StopModule;
  SndLib.FreeModule(musica);
  SndLib.Free;
  for i := 0 to objectUpdate.count-1 do freemem(objectUpdate.items[i]);
  objectUpdate.Free;
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TGame9.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame9.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if ActualSound(X,Y) then exit;
 if Button = mbRight then
  begin
   Up := true;
   exit;
  end; 
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then PrepareRenderTriste else
  begin
   if X > cxr+17 then Right := True else Left := True;
  end;
end;

procedure TGame9.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  Right := false;
  Left := false;
  Up := false;
 end;

procedure TGame9.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
  if salto then AnimaSalto;
  AnimaPiedras;
  scr.surface.draw(cxr,cyr,images[tc].surface,true);
 end;

procedure TGame9.UpdateAyuda;
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
  for i := 1 to 2 do
   with piedra[i] do scr.surface.draw(cxp,194,images[7].surface,true);
  scr.surface.draw(cxr,cyr,images[tc].surface,true);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
end;

procedure TGame9.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^ do
   scr.surface.draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame9.CreateObject(xx,yy,iindex : integer; trans : boolean);
 var
  objeto : PObjectUpdate;
 begin
  getmem(objeto,sizeof(TObjectUpdate));
  with objeto^ do
   begin
    cx := xx;
    cy := yy;
    cindex :=iindex;
    transparent := trans;
   end;
  objectUpdate.Add(objeto);
 end;

procedure TGame9.AnimaPiedras;
 var
  i : byte;
  pegado : boolean;
 begin
  for i := 1 to 2 do
   with piedra[i] do
    begin
     scr.surface.draw(cxp,194,images[7].surface,true);
     if (GetTickCount - tick < Speed) then continue;
     tick := GetTickCount;
     if (cxp=158) or (cxp=236) or (cxp=336) or (cxp=416) then sig := -sig;
     inc(cxp,sig);
     if salto or (options = RenderCaida) then continue;
     pegado := SurfaceCollision(cxp,193,cxr,cyr,images[7].surface,images[tc].surface,true);
     if pegado then
      begin
       if sig=1 then inc(cxr) else dec(cxr);
       continue;
      end;
     if ((cxr >= tipo[i].X) and (cxr <= tipo[i].Y)) and (cyr=146) then
      begin
       efectos[3].Play;
       tc := 2; salto := false;
       options := RenderCaida;
       KeyTick := GetTickCount;
       break;
      end;
    end;
 end;

procedure TGame9.AnimaSalto;
 begin
  if GetTickCount - saltoTick < 60 then exit;
  saltoTick := GetTickCount;
  cyr := 110;
  if tc in [23..27] then
   if tc = 27 then
    begin
     tc := 9; cyr := 146;
     salto := false;
    end
   else
    begin
     inc(tc);
     if cxr < 490 then inc(cxr,12);
    end
  else
   if tc = 32 then
    begin
     tc := 16; cyr := 146;
     salto := false;
    end
   else
    begin
     inc(tc);
     if cxr > 76 then dec(cxr,12);
    end;
 end;

function TGame9.RenderGame : byte;
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
    UpdateKeyboard;
    UpdateGame(True);
    if cxr > 488 then
     begin
      Prepare(True);
      options := RenderAlegre;
      efectos[1].Play;
     end;
   end;
   RenderCaida : begin
    if isEscape in key.States then
     begin
      CreateObject(cxr,cyr,tc,true);
      PrepareRenderTriste;
     end
    else
     begin
      UpdateGame(True);
      if GetTickCount - KeyTick >= 60 then
       begin
        inc(cyr,4);
        KeyTick := GetTickCount;
        if cyr = 262 then dec(cxr,10);
        if cyr > 260 then
         begin
          if tc < 6 then inc(tc) else
           begin
            PrepareRenderTriste;
            CreateObject(cxr,cyr,tc,true);
            efectos[4].Play;
           end;
         end;
       end;
     end;
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
    ProcessHelp(RenderRun,7,5);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

procedure TGame9.updateKeyboard;
 begin
  if isF1 in key.States then options := RenderAyuda;
  if isEscape in key.keyboard.states then
   begin
    PrepareRenderTriste;
    exit;
   end;
  if (GetTickCount - KeyTick < 60) or salto then exit;
  KeyTick := GetTickCount;
  if (isRight in key.Keyboard.States) or Right then if (tc in [16..22]) then tc := 9
   else
    begin
     if cxr < 514 then inc(cxr);
     if tc = 15 then tc := 9 else inc(tc);
    end else
  if (isLeft in key.Keyboard.States) or Left then if (tc in [9..15]) then tc := 16
   else
    begin
     if cxr > 76 then dec(cxr);
     if tc = 22 then tc := 16 else inc(tc);
    end else
  if (isUp in key.Keyboard.States) or Up then
   begin
    if tc in [9..15] then tc := 23 else tc := 28;
    salto := true; cyr := 136;
    saltoTick := GetTickCount;
   end else if tc in [9..15] then tc := 9 else tc := 16;
 end;

function TGame9.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 18;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju9 := TGame9.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju9.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju9.Free;
 end;

end.
