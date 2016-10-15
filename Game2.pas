unit Game2;

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

 TGame2 = class(TJuego)
 private
  lib : TILib;
  images   : array[0..12] of TAutomaticSurfaceLib;

  suboptions : word;
  imgIndex : dword;

  // variables de las hormigas en movimiento
  Hormiga1Tick,Hormiga2Tick : dword;
  cont1, cont2 : byte;
  vshor1, vshor2 : shortint;
  // fin de las variables de las hormigas

  manzaact: array[1..3] of boolean; // manzanas activas

  x,y    : word;
  cont : byte;
  cont3 : word;
  abc    : array[1..3] of boolean;
  vset   : set of byte;

  tickZ : dword;
  countZ: byte;

  cRenderMan4 : byte;
  optionsRenderMan4 : word;
  objectUpdate : TList;

 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure AnimaHormigas;
  procedure UpdateGame(Value : boolean);

  function Rueda : boolean;
  function ZanaUp : boolean;
  function lefttoright(sig : shortint) : boolean;
  function CanDoIt : boolean;
  procedure InitZ(Value : byte);
  function MovZ(cor: integer; sig : shortint) : boolean;
  procedure UpdateObject(Objected : PObjectUpdate);
  procedure CreateObject(xx,yy,iindex : integer; trans : boolean);
  procedure UpdateAyuda; Override;
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
 RenderManzana = 7;
 RenderAyuda   = 8;

 // sub options
  RenderMan1 = 0;
  RenderMan2 = 1;
  RenderMan3 = 2;
  RenderMan4 = 3;
  RenderMan5 = 4;
  RenderMan5_1 = 5;
  RenderMan6 = 6;
  RenderMan7 = 7;

 // options for RenderMan4
  RenderMan4_1 = 0;
  RenderMan4_2 = 1;
  RenderMan4_3 = 2;

 manzanas : array[1..3] of TRect = (
  (Left:183;  Top:94; Right:199;  Bottom:105),
  (Left:203;  Top:92; Right:218; Bottom:104),
  (Left:223; Top:94; Right:238; Bottom:105));

 coor : array[1..3] of byte = (180,202,220);

 caminos : array[1..11,1..4] of shortint = (
        ( 1, 1, 1,-1),  {*}
        (-1,-1,-1, 0),  {A}
        (-1,-1, 1,-1),  {B}
        (-1, 1,-1, 1),  {*}
        (-1, 1,-1,-1),  {B}
        ( 1,-1,-1,-1),  {B}
        (-1,-1, 1, 1),  {*}
        (-1, 1, 1, 0),  {C}
        ( 1, 1,-1, 0),  {C}
        ( 1,-1,-1, 1),  {*}
        ( 1,-1, 1, 0)); {C}

 desplazx : array[1..25] of byte =
  (8,8,8,8,8,8,8,8,8,8,9,2,8,8,8,8,8,8,8,4, 8,12,12, 8,6);
 desplazy : array[1..25] of shortint =
  (4,2,4,2,4,4,2,4,2,4,2,4,4,4,2,0,0,0,-6,-6, -6,-12,-12, 0,13);

  incx : array[1..6] of byte = (12,8,6,4,6,4);
  incy : array[1..6] of byte = (2,4,2,4,8,12);

var
 ju2 : TGame2;

constructor TGame2.Create;
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego2.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego2.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  fSound.StopModule;
  fSound.PlayModule(musica);
  for i := 1 to 3 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  options := LoadGameComun;
  imgIndex := 0;
  objectUpdate := TList.Create;

  Hormiga1Tick := GetTickCount;
  Hormiga2Tick := GetTickCount;
  vshor1 := 1; vshor2 := -1;
  cont1 := 5; cont2 := 7;
  fillchar(manzaact,3,true);
  fillchar(abc,3,true);
  cont := 0;
  cont3 := 0;
  vset := [];
 end;

destructor TGame2.Destroy;
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

procedure TGame2.PrepareRenderTriste;
 begin
  Prepare(False);
  options := RenderTriste;
  efectos[2].Play;
 end;

procedure TGame2.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  i,j : byte;
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then
  begin
   PrepareRenderTriste;
   exit;
  end;
 if options = RenderManzana then exit;
 j := 0;
 for i := 1 to 3 do
  if manzaact[i] then
   if ptinrect(manzanas[i],point(x,y)) then j := i;
 if j <> 0 then
  begin
   manzaact[j] := false;
   CreateObject(coor[j],84,9+j,false);
   self.x := 202; self.y := 135;
   InitZ(1);
   options := RenderManzana;
   suboptions := RenderMan1;
  end;
end;

procedure TGame2.InitZ(Value : byte);
 begin
  countZ := Value;
  tickZ := GetTickCount;
 end;

function TGame2.MovZ(cor: integer; sig : shortint) : boolean;
 begin
  if GetTickCount-tickZ >= 20 then
   begin
    tickZ := GetTickCount;
    inc(countZ);
   end;
  scr.surface.draw(x,cor+sig*countZ,images[2].surface,true);
  result := countZ = 17;
 end;

procedure TGame2.AnimaHormigas;
 begin
  if GetTickCount - Hormiga1Tick >= 350 then
   begin
    Hormiga1Tick := GetTickCount;
    if (cont1=8) or (cont1=4) then vshor1 := -vshor1;
    inc(cont1,vshor1);
   end;
  if GetTickCount - Hormiga2Tick >= 240 then
   begin
    Hormiga2Tick := GetTickCount;
    if (cont2=8) or (cont2=4) then vshor2 := -vshor2;
    inc(cont2,vshor2);
   end;
  scr.surface.Draw(362,170,images[cont1].surface,false);
  scr.surface.Draw(130,282,images[cont2].surface,false);
 end;

procedure TGame2.UpdateGame(Value : boolean);
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  AnimaHormigas;
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
 end;

function TGame2.CanDoIt : boolean;
 var
  i : byte;
 begin
  repeat
  result := false;
  i := random(11)+1;
  case i of
   2 : if abc[1] then
        begin
         result := true;
         abc[1] := false;
        end;
   3,5,6: if abc[2] then
           begin
            result := true;
            abc[2] := false;
           end;
   8,9,11: if abc[3] then
            begin
             result := true;
             abc[3] := false;
            end;
   else result := true;
  end;
  until not(i in vset) and result ;
  cont3 := i;
  vset := vset + [i];
 end;

function TGame2.lefttoright(sig : shortint) : boolean;
 begin
  result := true;
  if sig = 0 then exit;
  if GetTickCount-tickZ>=40 then
   begin
    inc(x,sig*incx[countZ]);
    inc(y,incy[countZ]);
    tickZ := GetTickCount;
    inc(countZ);
   end;
  scr.surface.draw(x,y,images[2].surface,true);
  result := countZ=7;
 end;

function TGame2.Rueda : boolean;
 begin
  if GetTickCount-tickZ>=40 then
   begin
    inc(x,desplazx[countZ]);
    inc(y,desplazy[countZ]);
    tickZ := GetTickCount;
    inc(countZ);
   end;
  scr.surface.draw(x,y,images[2].surface,true);
  result := countZ=26;
 end;

function TGame2.ZanaUp : boolean;
 begin
  if GetTickCount-tickZ>=40 then
   begin
    tickZ := GetTickCount;
    inc(countZ);
   end;
  scr.surface.draw(466,200-countZ*2,images[9].surface,true);
  result := countZ=59;
 end;

procedure TGame2.UpdateObject(Objected : PObjectUpdate);
 begin
  with Objected^ do
   scr.surface.draw(cX,cY,images[cIndex].surface,Transparent);
 end;

procedure TGame2.CreateObject(xx,yy,iindex : integer; trans : boolean);
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

procedure TGame2.UpdateAyuda;
 var
  i : integer;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  AnimaHormigas;
  for i := 0 to objectUpdate.Count-1 do updateObject(objectUpdate.items[i]);
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

function TGame2.RenderGame : byte;
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
    if isF1 in key.States then options := RenderAyuda;
    UpdateGame(True);
   end;
   RenderManzana : begin
    if isEscape in key.States then PrepareRenderTriste;
    UpdateGame(True);
    case suboptions of
     RenderMan1 : begin
      if MovZ(120,1) then
       begin
        InitZ(1);
        efectos[3].Play;
        suboptions := RenderMan2;
       end;
     end;
     RenderMan2 : begin
      if MovZ(136,-1) then
       begin
        InitZ(1);
        suboptions := RenderMan3;
       end;
     end;
     RenderMan3 : begin
      if MovZ(120,1) then
       begin
        efectos[3].Play;
        InitZ(1);
        CanDoIt;
        cRenderMan4 := 1; optionsRenderMan4 := RenderMan4_1;
        suboptions := RenderMan4;
       end;
     end;
     RenderMan4 : begin
      case optionsRenderMan4 of
       RenderMan4_1 : begin
        if lefttoright(caminos[cont3,cRenderMan4]) then
         if (cRenderMan4=4) and (cont3 in [1,4,7,10]) then suboptions := RenderMan5
          else
           begin
            efectos[3].Play;
            InitZ(1);
            optionsRenderMan4 := RenderMan4_2;
           end;
       end;
       RenderMan4_2 : begin
        if MovZ(y+2,-1) then
         begin
          InitZ(1);
          optionsRenderMan4 := RenderMan4_3;
         end;
       end;
       RenderMan4_3 : begin
        if MovZ(y-14,1) then
         begin
          efectos[3].Play;
          inc(cRenderMan4);
          if cRenderMan4 = 5 then suboptions := RenderMan5;
          InitZ(1);
          optionsRenderMan4 := RenderMan4_1;
         end;
       end;
      end;
     end; //end of RenderMan4
     RenderMan5_1 : begin
      if cRenderMan4 = 31 then
       begin
        InitZ(11);
        suboptions := RenderMan6;
       end
      else
       begin
        inc(y);
        inc(cRenderMan4);
        scr.surface.draw(x,y,images[2].surface,true);
       end;
     end;
     RenderMan5 : begin
      if cont3 in [1,4,7,10] then
       begin
        if cont3 = 1 then
         begin
          cRenderMan4 := 1;
          suboptions := RenderMan5_1
         end
        else
         begin
          InitZ(1);
          suboptions := RenderMan6;
         end
       end
      else
       begin
        inc(cont);
        if cont = 2 then PrepareRenderTriste else options := RenderRun;
        CreateObject(x,y,2,true);
       end;
     end;
     RenderMan6 : begin
      if Rueda then
       begin
        CreateObject(394,258,3,false);
        InitZ(1);
        suboptions := RenderMan7;
       end;
     end;
     RenderMan7 : begin
      if ZanaUp then
       begin
        CreateObject(466,82,9,true);
        Prepare(True);
        options := RenderAlegre;
        efectos[1].Play;
       end;
     end;
    end; //end of case
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
    ProcessHelp(RenderRun,1,4);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame2.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 11;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju2 := TGame2.Create(Screen,KeyBoard,Sound, Mouse);
  result := ju2.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju2.Free;
 end;

end.
