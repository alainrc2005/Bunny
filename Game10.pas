unit Game10;

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

 TGame10 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..33] of TAutomaticSurfaceLib;

  imgIndex : dword;

  objectUpdate : TList;

  fig : byte;
  sel : byte;
  cpos : array[1..16] of byte;
  mouseclick : boolean;
  mouseform : byte;
  ShowMouse : boolean;
  gana : byte;
  op : byte;

  // variables de la linea
  a,b,c,d : integer;
  u,v,m,n:integer;
  d1x,d1y,d2x,d2y : shortint;
  s: real;
  sa,sb : integer;
  countLinea : integer;
  // fin de las variables de la linea

  procedure InitLine;
  procedure PrepareRenderTriste;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);
  procedure UpdateAyuda; Override;

  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);
  procedure ActualObject(Index,xx,yy : integer);
  procedure ObjectTop(Index : integer);
  procedure Desorden;

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
 RenderLinea   = 7;
 RenderAyuda   = 8;


 const
  des : array[1..16] of TRect =
  ((left:144;top:74;right:196;bottom:118),
   (left:78;top:92;right:130;bottom:136),
   (left:112;top:150;right:164;bottom:194),
   (left:76;top:212;right:128;bottom:256),
   (left:142;top:212;right:184;bottom:256),
   (left:120;top:274;right:172;bottom:318),
   (left:186;top:274;right:238;bottom:318),
   (left:252;top:274;right:304;bottom:318),
   (left:318;top:274;right:370;bottom:318),
   (left:384;top:274;right:436;bottom:318),
   (left:450;top:274;right:548;bottom:318),
   (left:428;top:212;right:480;bottom:256),
   (left:494;top:212;right:546;bottom:256),
   (left:460;top:150;right:512;bottom:194),
   (left:492;top:92;right:544;bottom:136),
   (left:426;top:74;right:478;bottom:118));

  orden : array[1..16] of TRect =
  ((left:204;top:74;right:254;bottom:116),
   (left:258;top:74;right:308;bottom:116),
   (left:312;top:74;right:362;bottom:116),
   (left:366;top:74;right:416;bottom:116),
   (left:204;top:120;right:254;bottom:162),
   (left:258;top:120;right:308;bottom:162),
   (left:312;top:120;right:362;bottom:162),
   (left:366;top:120;right:416;bottom:162),
   (left:204;top:166;right:254;bottom:208),
   (left:258;top:166;right:308;bottom:208),
   (left:312;top:166;right:362;bottom:208),
   (left:366;top:166;right:416;bottom:208),
   (left:204;top:212;right:254;bottom:254),
   (left:258;top:212;right:308;bottom:254),
   (left:312;top:212;right:362;bottom:254),
   (left:366;top:212;right:416;bottom:254));

var
 ju10 : TGame10;

constructor TGame10.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego10.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego10.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 4 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.StopModule;
  fSound.PlayModule(musica);
  options := LoadGameComun;
  imgIndex := 0;
  objectUpdate := TList.Create;
  fig := random(2);
  Desorden;
  MouseClick := false; ShowMouse := True;
  gana := 0; op := 0;
 end;

destructor TGame10.Destroy;
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

procedure TGame10.InitLine;

 function sgn(aa:real):integer;
  begin
   result := 0;
   if aa>0 then result:=+2;
   if aa<0 then result:=-2;
  end;

 begin
  a := fMouse.MouseX;
  b := fMouse.MouseY;
  c := des[sel].left;
  d := des[sel].top;
  u:= c - a;
  v:= d - b;
  d1x:= SGN(u);
  d1y:= SGN(v);
  d2x:= SGN(u);
  d2y:= 0;
  m:= ABS(u);
  n := ABS(v);
  if not (M>N) then
   begin
    d2x := 0 ;
    d2y := SGN(v);
    m := ABS(v);
    n := ABS(u);
   end;
   s := INT(m / 2);
   countLinea := 0;
 end;

procedure TGame10.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame10.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  i : byte;
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then
  begin
   PrepareRenderTriste;
   exit;
  end;
 if options = RenderLinea then exit;
 if not MouseClick then
  begin
   for i := 1 to 16 do
    if (ptinrect(des[i],point(X,Y))) and (cpos[i]<>0) then
     begin
      MouseForm := 1+fig*16+cpos[i];
      ObjectTop(1+fig*16+cpos[i]);
      ShowMouse := false;
      MouseClick := true;
      sel := i;
      break;
     end
  end
 else
  begin
   ShowMouse := true;
   MouseClick := false;
   for i := 1 to 16 do
   if ptinrect(orden[i],point(X,Y)) then
    if cpos[sel] = i then
     begin
      efectos[3].Play;
      ActualObject(1+fig*16+cpos[sel],orden[i].left,orden[i].top);
      cpos[sel] := 0;
      inc(gana);
      if gana = 16 then
       begin
        Prepare(True);
        options := RenderAlegre;
        efectos[1].Play;
        exit;
       end;
      break; 
     end
    else
     begin
      InitLine;
      options := RenderLinea;
      efectos[4].Play;
      inc(op);
      if op = 10 then PrepareRenderTriste;
      exit;
     end;
   if i = 17 then
    begin
     InitLine;
     options := RenderLinea;
     efectos[4].Play;
    end;
  end;
end;

procedure TGame10.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  if not ShowMouse then ActualObject(MouseForm,fMouse.MouseX,fMouse.MouseY);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
 end;

procedure TGame10.UpdateAyuda;
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  if not ShowMouse then ActualObject(MouseForm,fMouse.MouseX,fMouse.MouseY);
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame10.ObjectTop(Index : integer);
 var
  tmp : TObjectUpdate;
  i : integer;
 begin
  for i := 0 to objectUpdate.Count-1 do
   if PObjectUpdate(objectUpdate.Items[i])^.cIndex = Index then
    begin
     Index := i;
     break;
    end;
  tmp := PObjectUpdate(objectUpdate.Items[Index])^;
  PObjectUpdate(objectUpdate.Items[Index])^ := PObjectUpdate(objectUpdate.Items[objectUpdate.Count-1])^;
  PObjectUpdate(objectUpdate.Items[objectUpdate.Count-1])^ := tmp;
 end;

procedure TGame10.ActualObject(Index,xx,yy : integer);
 var
  i : integer;
 begin
  for i := 0 to objectUpdate.Count -1 do
   with PObjectUpdate(objectUpdate.items[i])^ do
    if cindex = Index then
     begin
       cx := xx;
       cy := yy;
     end;
 end;

procedure TGame10.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^,scr.Surface do draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame10.CreateObject(xx,yy,iindex : integer; trans : boolean);
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

function TGame10.RenderGame : byte;
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
   RenderLinea : begin
    sa := a; sb := b;
    s := s + n;
    if not (s<m) then
     begin
      s := s - m;
      a:= a +round(d1x);
      b := b + round(d1y);
     end
    else
     begin
      a := a + round(d2x);
      b := b + round(d2y);
     end;
    ActualObject(MouseForm,a,b);
    UpdateGame(True);
    inc(countLinea,2);
    if m <= countLinea then
     begin
      ActualObject(MouseForm,c,d);
      options := RenderRun;
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
    ProcessHelp(RenderRun,1,5);
   end;
  end; // end of case
  if ShowMouse then fMouse.AnimaMouse;
  scr.Flip;
 end;

procedure TGame10.Desorden;
 var
  vset : set of byte;
  i,j : byte;
begin
 vset := [];
 i := 0;
 repeat
  j := random (16) + 1;
  if not (j in vSet) then
   begin
    inc (i);
    cpos[i] := j;
    CreateObject(des[i].left,des[i].top,1+fig*16+j,false);
    vSet := vSet + [j];
   end;
 until (i = 16);
end;

function TGame10.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 19;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju10 := TGame10.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju10.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju10.Free;
 end;

end.
