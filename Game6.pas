unit Game6;

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

 TGame6 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..29] of TAutomaticSurfaceLib;

  imgIndex : dword;

  objectUpdate : TList;

  baraja : array[0..14] of TRect;
  fichas : array[1..7] of byte;
  pos    : array[0..14] of byte;
  act    : array[0..14] of boolean;
  viradas: array[1..3] of byte;
  cVirar : byte;
  tickVirar : dword;
  virada : shortint;
  virando : boolean;
  zanahoria : byte;
  cviradas : byte;
  conservar : shortint;
  solve : byte;

  op : byte;
  virar : boolean;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);
  procedure Sustitute(index1, img : byte);
  procedure DeleteObjectUpdate(index : integer);

  procedure Aleatoria;
  procedure UpdateVirar;
  procedure updateKeyBoard;
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
 RenderVirar   = 7;
 RenderAyuda   = 8;

var
 ju6 : TGame6;

constructor TGame6.Create;
 var
  i,j : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego6.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego6.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 5 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  objectUpdate := TList.Create;
  for j := 0 to 2 do
   for i := 0 to 4 do
    begin
     with baraja[j*5+i] do
      begin
       left := 66+74*i+20*(i+1);
       top := 66+82*j+5*(j+1);
       right := left + 74;
       bottom := top + 82;
       CreateObject(left,top,28,true);
      end;
    end;
  fillchar(pos,sizeof(pos),0);
  fillchar(act,sizeof(act),true);
  fillchar(viradas,sizeof(viradas),0);
  cviradas := 1; virando := false; solve := 0; op := 0;
  Aleatoria; virar := false;
 end;

destructor TGame6.Destroy;
 var
  i : integer;
 begin
  FreeAllEffects;
  fSound.StopModule;
  SndLib.FreeModule(musica);
  SndLib.Free;
  for i := 0 to objectUpdate.count-1 do freemem(objectUpdate.items[i]);
  objectUpdate.free;
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TGame6.Sustitute(index1, img : byte);
 var
  i : integer;
 begin
  for i := 0 to objectUpdate.Count -1 do
   with PObjectUpdate(objectUpdate.Items[i])^, baraja[index1] do
    if (cX = left) and (cY=top) then cIndex := img;
 end;

procedure TGame6.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame6.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  i : byte;
begin
 if ActualSound(X,Y) then exit;
 if Button = mbRight then
  begin
   Virar := true;
   exit;
  end;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then
  begin
   PrepareRenderTriste;
   exit;
  end;
 if virando then exit;
 virada := -1;
 for i := 0 to 14 do
  begin
   if ptinrect(baraja[i],point(x,y)) then
    begin
     virada := i;
     efectos[5].Play;
     break;
    end;
  end;
 if (virada <> -1) then
  if act[virada] then
  begin
   virando := true;
   act[virada] := false;
   viradas[cviradas] := virada;
   conservar := -1;
   if cviradas = 3 then
    begin
     conservar := viradas[1];
     move(viradas[2],viradas[1],sizeof(byte)*2);
     act[conservar] := true;
    end else inc(cviradas);
   cVirar := 26;
   options := RenderVirar;
  end;
end;

procedure TGame6.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  Virar := false;
 end;

procedure TGame6.UpdateGame(Value : boolean);
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

procedure TGame6.UpdateAyuda;
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

procedure TGame6.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^ do
   scr.surface.draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame6.CreateObject(xx,yy,iindex : integer; trans : boolean);
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

procedure TGame6.UpdateVirar;
 begin
  if GetTickCount - tickVirar >= 100 then
   begin
    if conservar <> -1 then Sustitute(conservar,cVirar);
    tickVirar := GetTickCount;
    if pos[virada] = 29 then Sustitute(virada,29) else Sustitute(virada,pos[virada]+1);
    if cVirar = 28 then
     begin
      virando := false;
      options := RenderRun
     end
    else
     begin
      inc(cVirar);
      Sustitute(virada,cVirar);
     end;
   end;
 end;

procedure TGame6.DeleteObjectUpdate(index : integer);
 var
  i : integer;
 begin
  i := 0;
  while i < objectUpdate.Count  do
   begin
    with PObjectUpdate(objectUpdate.Items[i])^, baraja[index] do
     if (cX = left) and (cY = top) then objectUpdate.delete(i) else inc(i);
   end;
 end;

procedure TGame6.updateKeyBoard;
 begin
  if (solve = 7) and not act[zanahoria] then
   begin
    Prepare(true);
    options := RenderAlegre;
    efectos[1].Play;
   end;
  if isEscape in key.keyboard.states then PrepareRenderTriste;
  if (isSpace in key.states) or Virar then
   begin
    Virar := false;
    key.ClearStates;
    if (odd(pos[viradas[1]]) and (pos[viradas[1]] = pos[viradas[2]]-1)) or
       (odd(pos[viradas[2]]) and (pos[viradas[2]] = pos[viradas[1]]-1)) then
     begin
      DeleteObjectUpdate(viradas[1]);
      DeleteObjectUpdate(viradas[2]);
      inc(solve);
      cviradas := 1;
      zeromemory(@viradas,sizeof(viradas));
      efectos[3].Play;
     end
    else
     begin
      efectos[4].Play;
      inc(op);
      if op = 3 then PrepareRenderTriste;
     end;
   end;
  if isF1 in key.States then options := RenderAyuda;
 end;

procedure TGame6.Aleatoria;
 var
  vset : set of byte;
  i,j,cont,cont1 : byte;
 begin
  i := 0; vset := [];
  repeat
   cont := random(12);
   if not (cont in vset) then
    begin
     vset := vset + [cont];
     inc(i);
     fichas[i] := cont;
    end;
  until i=7;
  zanahoria := random(15);
  pos[zanahoria] := 29;
  i := 0; j := 1;
  repeat
   cont := random(15);
   if pos[cont]=0 then
    begin
     inc(i);
     cont1 := (fichas[j]-1)*2 + 3;
     if odd(i) then pos[cont] := cont1 else
      begin
       pos[cont] := cont1 + 1;
       inc(j);
      end;
    end;
  until i=14;
 end;
 
function TGame6.RenderGame : byte;
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
    updateKeyboard;
    UpdateGame(True);
   end;
   RenderVirar : begin
    UpdateVirar;
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
    ProcessHelp(RenderRun,4,6);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame6.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 15;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju6 := TGame6.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju6.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju6.Free;
 end;

end.
