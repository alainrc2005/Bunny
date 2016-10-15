unit Game13;

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

 TPorciento = record
  fig : shortint;
 end;

 TGame13 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..26] of TAutomaticSurfaceLib;

  imgIndex : dword;

  objectUpdate : TList;

  muestra : array[1..13] of TPorciento;

  MouseClick : boolean;
  MouseForm : TPorciento;
  ShowMouse : boolean;

  procedure PrepareRenderTriste;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);
  procedure ActualObject(Index : TPorciento;xx,yy : integer);
  procedure ObjectTop(Index : TPorciento);

  procedure Desorden;

  function Determinacion : byte;
  function Validate : boolean;

  function CalcX(Value : Integer) : Integer;
  function CalcY(Value : Integer) : Integer;
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

Local : array[1..13] of TRect =
 ((Left:94;Top:145;Right:199;Bottom:236),
  (Left:209;Top:145;Right:314;Bottom:236),
  (Left:324;Top:145;Right:429;Bottom:236),
  (Left:439;Top:145;Right:544;Bottom:236),

  (Left:94;Top:249;Right:199;Bottom:340),
  (Left:209;Top:249;Right:314;Bottom:340),
  (Left:324;Top:249;Right:429;Bottom:340),
  (Left:439;Top:249;Right:544;Bottom:340),

  (Left:7;Top:27;Right:127;Bottom:132),
  (Left:134;Top:27;Right:254;Bottom:132),
  (Left:261;Top:27;Right:381;Bottom:132),
  (Left:388;Top:27;Right:508;Bottom:132),
  (Left:515;Top:27;Right:635;Bottom:132));

var
 ju13 : TGame13;

constructor TGame13.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego13.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego13.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 2 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  objectUpdate := TList.Create;
  fillchar(muestra,sizeof(muestra),-1);
  MouseClick := false; ShowMouse := True;
  Desorden;
 end;

destructor TGame13.Destroy;
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

procedure TGame13.Desorden;
 var
  imagen,i,j : byte;
  seto : Set of byte;

  procedure Pegar(img : byte);
   var
    i : byte;
   begin
    repeat
     i := random(8)+1;
    until muestra[i].fig = -1;
    muestra[i].fig := img;
   end;

 begin
  imagen := random(4);
  seto := [];
  for i := 0 to 4 do
   begin
    Pegar(7+imagen*5+i);
    seto := seto + [imagen*5+i];
   end;
  for i := 1 to 3 do
   begin
    repeat
     j := random(20);
    until not (j in seto);
    Pegar(7+j);
    seto := seto + [j];
   end;
  for i := 1 to 8 do
   with scr.Surface, muestra[i] do
    CreateObject(CalcX(i),CalcY(i),fig,true);
 end;

function TGame13.CalcX(Value : Integer) : Integer;
 begin
  result := local[Value].Left+Abs((local[Value].Right-local[Value].Left)-105) div 2;
 end;

function TGame13.CalcY(Value : Integer) : Integer;
 begin
  result := local[Value].Top+Abs((local[Value].Bottom-local[Value].Top)-91) div 2
 end;

function TGame13.Determinacion : byte;
 var
  i,t : byte;
 begin
  result := 0;
  t := 0;
  for i := 0 to 4 do
   if muestra[9+i].fig = muestra[9].fig+i then inc(t);
  if t = 5 then result := 1;
 end;

function TGame13.Validate : boolean;
 var
  i,j : byte;
 begin
  j := 0;
  for i := 9 to 13 do if muestra[i].fig <> -1 then inc(j);
  result := j = 5;
 end;

procedure TGame13.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame13.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  i : byte;
begin
 if not MouseClick then
  begin
   if ActualSound(X,Y) then exit;
   if ptinrect(rect(561,0,588,26),Point(X,Y)) then
    begin
     PrepareRenderTriste;
     exit;
    end;
   for i := 1 to 13 do
    if (ptinrect(local[i],point(X,Y))) and (muestra[i].fig<>-1) then
     begin
      MouseForm := Muestra[i];
      ObjectTop(Muestra[i]);
      Muestra[i].fig := -1;
      ShowMouse := false;
      MouseClick := true;
      break;
     end
  end
 else
  begin
   for i := 1 to 13 do
    if (ptinrect(local[i],point(X,Y))) and (muestra[i].fig = -1) then
     begin
      ActualObject(MouseForm,CalcX(i),CalcY(i));
      Muestra[i] := MouseForm;
      ShowMouse := True;
      if Determinacion = 1 then
       begin
        Prepare(true);
        options := RenderAlegre;
        efectos[1].Play;
       end
      else
       if Validate then
        begin
         PrepareRenderTriste;
         exit;
        end;
      MouseClick := False;
      break;
     end
  end;
end;

procedure TGame13.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  for i := 0 to 4 do scr.Surface.Draw((i+1)*7+i*120,27,images[i+2].Surface,true);
  scr.Surface.Draw(83,132,images[1].Surface,true);
  scr.Surface.Draw(80,354,images[0].Surface,false);
  if not ShowMouse then ActualObject(MouseForm,fMouse.MouseX,fMouse.MouseY);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
 end;

procedure TGame13.UpdateAyuda;
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  for i := 0 to 4 do scr.Surface.Draw((i+1)*7+i*120,27,images[i+2].Surface,true);
  scr.Surface.Draw(83,132,images[1].Surface,true);
  scr.Surface.Draw(80,354,images[0].Surface,false);
  if not ShowMouse then ActualObject(MouseForm,fMouse.MouseX,fMouse.MouseY);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame13.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^ do
   scr.surface.draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame13.CreateObject(xx,yy,iindex : integer; trans : boolean);
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

procedure TGame13.ObjectTop(Index : TPorciento);
 var
  tmp : TObjectUpdate;
  i : integer;
  Value : Integer;
 begin
  for i := 0 to objectUpdate.Count-1 do
   if (PObjectUpdate(objectUpdate.Items[i])^.cIndex = Index.fig) then
    begin
     Value := i;
     break;
    end;
  tmp := PObjectUpdate(objectUpdate.Items[Value])^;
  PObjectUpdate(objectUpdate.Items[Value])^ := PObjectUpdate(objectUpdate.Items[objectUpdate.Count-1])^;
  PObjectUpdate(objectUpdate.Items[objectUpdate.Count-1])^ := tmp;
 end;

procedure TGame13.ActualObject(Index : TPorciento;xx,yy : integer);
 var
  i : integer;
 begin
  for i := 0 to objectUpdate.Count -1 do
   with PObjectUpdate(objectUpdate.items[i])^ do
    if (cindex = Index.fig) then
     begin
       cx := xx;
       cy := yy;
     end;
 end;

function TGame13.RenderGame : byte;
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
      fMouse.RestoreAllEvents;
     end;
   end; // end of loadgame
   RenderRun : begin
    if isEscape in key.States then PrepareRenderTriste;
    if (isF1 in key.States) then options := RenderAyuda;
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
    ProcessHelp(RenderRun,1,3);
   end;
  end; // end of case
  if ShowMouse then fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame13.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 22;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju13 := TGame13.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju13.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju13.Free;
 end;

end.
