unit Game4;

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
 TObjectUpdate = record
  cX,cY,cIndex : Integer;
  Transparent : boolean;
 end;
 PObjectUpdate = ^TObjectUpdate;

 TGame4 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..45] of TAutomaticSurfaceLib;

  imgIndex : dword;

  zana,zanaZ : byte;         //llave seleccionada a regar
  normal : boolean;
  cxr,cyr,cxo : word; //coordenadas del conejo y la oruga
  anioru,tc : byte;   //animacion de la oruga y tipo de conejo
  oruTick : dword;
  OruDir : shortint; // direccion de la oruga
  KeyTick : dword;
  salto : boolean;
  saltoTick : dword;

  objectUpdate : TList;
  Right, Left, Up, Open: boolean;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure AnimaOruga;
  procedure updateKeyboard;
  procedure AnimaSalto;
  function rabin(pp : TPoint) : boolean;

  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);
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
 RenderAbre    = 8;
 RenderRiega   = 9;
 RenderAyuda   = 10;

 pon : array[1..7] of byte = (7,5,1,4,3,2,6); {correspondencia llave zana}
 keyV : array[1..7] of TPoint =                 {espacio para las llaves}
  ((x:118;y:170),    (x:180;y:192),
   (x:242;y:254),  (x:304;y:316),
   (x:366;y:378),  (x:428;y:440),
   (x:490;y:502)); //-9,-9

var
 ju4 : TGame4;

constructor TGame4.Create;
 var
  i : integer;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego4.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego4.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 5 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  cxr := 514; cyr := 84;
  cxo := 78; anioru := 2; tc := 8;
  oruTick := GetTickCount;
  OruDir := 1;
  KeyTick := GetTickCount;
  salto := false;
  zana := random(7)+1;
  normal := true;
  objectUpdate := TList.Create;
  Right := false; Left := false; Up := false; Open := false;
 end;

destructor TGame4.Destroy;
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

procedure TGame4.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame4.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

procedure TGame4.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  Right := false;
  Left := false;
  Up := false;
  Open := false;
 end;

procedure TGame4.AnimaOruga;
 begin
  if GetTickCount - oruTick >= 100 then
   begin
    oruTick := GetTickCount;
    if (cxo = 498) or (cxo=76) then
     begin
      anioru := 2+3*byte(OruDir=1);
      OruDir := -OruDir;
     end;
    inc(cxo,OruDir);
    if cxo mod 4 = 0 then
     if anioru < 4 + 3*byte(OruDir=-1) then inc(anioru) else anioru := 2+3*byte(OruDir=-1);
   end;
  scr.surface.draw(cxo,110,images[anioru].surface,true);
 end;

procedure TGame4.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^ do
   scr.surface.draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame4.CreateObject(xx,yy,iindex : integer; trans : boolean);
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

procedure TGame4.AnimaSalto;
 begin
  if GetTickCount - saltoTick < 80 then exit;
  saltoTick := GetTickCount;
  if tc in [15..19] then
   if tc = 19 then
    begin
     tc := 1; cyr := 84;
     salto := false;
    end
   else
    begin
     inc(tc);
     if cxr < 490 then inc(cxr,24);
     if cyr > 40 then dec(cyr,10);
    end
  else
   if tc = 24 then
    begin
     tc := 8; cyr := 84;
     salto := false;
    end
   else
    begin
     inc(tc);
     if cxr > 100 then dec(cxr,24);
     if cyr > 40 then dec(cyr,10);
    end;
 end;

function TGame4.rabin;
 begin
  with pp do
   if tc in [8..14] then
    result := (cxr >= x) and (cxr <= y)
    else result := (cxr >= x-18) and (cxr <= y-18);
 end;

procedure TGame4.updateKeyboard;
 var
  i : byte;
 begin
  if isEscape in key.States then
   begin
    PrepareRenderTriste;
    exit;
   end;
  if (GetTickCount - KeyTick < 40) or salto then exit;
  KeyTick := GetTickCount;
  if (isRight in key.keyboard.states) or Right then if (tc in [8..14]) then tc := 1
   else
    begin
     if cxr < 514 then inc(cxr);
     if tc = 7 then tc := 1 else inc(tc);
    end;;
  if (isLeft in key.keyboard.states) or Left then if (tc in [1..7]) then tc := 8
   else
    begin
     if cxr > 76 then dec(cxr);
     if tc = 14 then tc := 8 else inc(tc);
    end;
  if (isUp in key.keyboard.states) or Up and not salto then
   begin
    if tc in [1..7] then tc := 15 else tc := 20;
    salto := true; cyr := 74;
    saltoTick := GetTickCount;
   end;
  if isSpace in key.keyboard.states then
   begin
    for i := 1 to 7 do
     if rabin(keyV[i]) then
      begin
       if tc in [1..7] then tc := 10 else tc := 8;
       imgIndex := 0; KeyTick := GetTickCount; saltoTick := 0;
       options := RenderAbre; zanaZ := i;
       efectos[5].Play;
       break;
      end;
   end;
  if isF1 in key.States then options := RenderAyuda;
 end;

procedure TGame4.UpdateAyuda;
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  scr.surface.draw(cxo,110,images[anioru].surface,true);
  if normal then scr.surface.draw(112+(pon[zana]-1)*62,306,images[20].surface,true)
   else scr.surface.draw(112+(pon[zana]-1)*62,282,images[21].surface,true);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
  scr.surface.draw(cxr,cyr,images[21+tc].surface,true);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame4.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  AnimaOruga;
  if salto then AnimaSalto;
  if normal then scr.surface.draw(112+(pon[zana]-1)*62,306,images[20].surface,true)
   else scr.surface.draw(112+(pon[zana]-1)*62,282,images[21].surface,true);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
 end;
 
function TGame4.RenderGame : byte;
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
    scr.surface.draw(cxr,cyr,images[21+tc].surface,true);
    if SurfaceCollision(cxr,cyr,cxo,110,images[21+tc].surface,images[anioru].surface,true) then
     begin
      tc := 12; salto := false;
      options := RenderCaida;
      KeyTick := GetTickCount;
      efectos[3].Play;
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
      scr.surface.draw(cxr,cyr,images[tc].surface,true);
      if GetTickCount - KeyTick >= 60 then
       begin
        inc(cyr,4);
        KeyTick := GetTickCount;
        if cyr > 280 then
         begin
          if tc < 15 then inc(tc);
          cyr := 302+(tc-14)*2;
         end;
        if cyr >= 304 then
         begin
          PrepareRenderTriste;
          CreateObject(cxr,cyr,tc,true);
         end;
       end;
     end;
   end;
   RenderAbre : begin
    if GetTickCount - KeyTick >= 200 then
     begin
      KeyTick := GetTickCount;
      imgIndex := imgIndex xor 1;
      inc(saltoTick);
     end;
    UpdateGame(True);
    scr.surface.draw(cxr,cyr,images[tc+imgIndex].surface,true);
    if saltoTick =5 then
     begin
      CreateObject(cxr,cyr,tc+imgIndex,true);
      imgIndex := 17; keyTick := GetTickCount;
      options := RenderRiega;
      efectos[4].Play;
     end;
   end;
   RenderRiega : begin
    UpdateGame(True);
    scr.surface.draw(102+(pon[zanaZ]-1)*62,306,images[imgIndex].surface,true);
    if GetTickCount - keyTick >= 120 then
     begin
      keyTick := GetTickCount;
      inc(imgIndex);
      if imgIndex = 20 then
       if zana = zanaZ then
        begin
         Prepare(True);
         options := RenderAlegre; normal := false;
         efectos[1].Play;
        end
       else PrepareRenderTriste;
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
    ProcessHelp(RenderRun,3,6);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame4.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 13;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju4 := TGame4.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju4.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju4.Free;
 end;

end.
