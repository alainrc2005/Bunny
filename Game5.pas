unit Game5;

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

 TGame5 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..19] of TAutomaticSurfaceLib;

  imgIndex : dword;
  aqui   : array[0..1] of byte;
  contador : byte;
  op : byte;

  objectUpdate : TList;

 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);

  procedure Aleatoria;
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

 poscz : array[1..16] of TRect =
 ((left:312;top:220;right:354;bottom:258),
  (left:306;top:220;right:348;bottom:258),
  (left:194;top:240;right:236;bottom:278),
  (left:310;top:220;right:352;bottom:258),
  (left:480;top:150;right:522;bottom:188),
  (left:434;top:200;right:476;bottom:238),
  (left:158;top:122;right:200;bottom:160),
  (left:390;top:90;right:432;bottom:128),
  (left:240;top:126;right:282;bottom:164),
  (left:198;top:220;right:240;bottom:258),
  (left:276;top:184;right:318;bottom:222),
  (left:290;top:280;right:332;bottom:318),
  (left:224;top:240;right:266;bottom:278),
  (left:174;top:190;right:216;bottom:228),
  (left:432;top:70;right:474;bottom:108),
  (left:278;top:164;right:320;bottom:202));


var
 ju5 : TGame5;

constructor TGame5.Create;
 var
  i : integer;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego5.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego5.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 4 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  objectUpdate := TList.Create;
  contador := 0; op := 0;
 end;

destructor TGame5.Destroy;
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

procedure TGame5.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame5.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  j,i : byte;
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then
  begin
   PrepareRenderTriste;
   exit;
  end;
 for j := 0 to 1 do
  for i := 1 to 8 do
   if ptinrect(poscz[i+8*j],point(x,y)) then
   if aqui[j] = i+8*j then
    begin
     efectos[3].Play;
     aqui[j] := 0;
     inc(contador); inc(op);
     with poscz[i+8*j] do CreateObject(left,top,2+j,true);
     if contador = 2 then
      begin
       Prepare(True);
       options := RenderAlegre;
       efectos[1].Play;
      end;
     exit;
    end;
 efectos[4].Play;
 inc(op);
 if op = 5 then PrepareRenderTriste;
end;

procedure TGame5.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^ do
   scr.surface.draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame5.CreateObject(xx,yy,iindex : integer; trans : boolean);
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

procedure TGame5.UpdateGame(Value : boolean);
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
 end;

procedure TGame5.UpdateAyuda;
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
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

function TGame5.RenderGame : byte;
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
      fMouse.SetMouseEvent(MouseMove,MouseDown,nil);
      Aleatoria;
      fMouse.RestoreAllEvents;
     end;
   end; // end of loadgame
   RenderRun : begin
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
    ProcessHelp(RenderRun,1,5);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame5.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

procedure TGame5.Aleatoria;
 begin
  aqui[0] := random(8)+1;
  with poscz[aqui[0]] do
   CreateObject(Left,top,aqui[0]+3,true);
  aqui[1] := random(8)+9;
  with poscz[aqui[1]] do
   CreateObject(left,top,aqui[1]+3,true);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 14;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju5 := TGame5.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju5.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju5.Free;
 end;

end.
