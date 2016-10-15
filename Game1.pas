unit Game1;

interface

uses DXDraws, DXInput, Mouse, Module;

type
 TFarProcObj = function : byte of object;

function IDGame : Integer; stdcall;
function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
procedure CoDestroyGame; stdcall;

implementation

Uses Windows, Classes, Controls, JuegoComun, VarsComun, Ayuda;

type
 TGame1 = class(TJuego)
 private
  images   : array[0..17] of TAutomaticSurfaceLib;

  vSet   : set of byte;
  vArray : array[1..3] of byte;
  Answer : array[1..3] of byte;
  ioerror : byte;
  iocorrect : byte;
  lib : TILib;

  optionsClick : word;
  duroClick : boolean;
  tickClick : dword;
  llaveClick : byte; // posicion de la llave 3 y 4
  llaveSel : byte;  // cual llave se esta abriendo
  imgIndex : dword;
  selected : boolean;
  selected_value : byte;

  borradas : TList;
 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure desorden;
  function select : byte;
  function RenderLoad : boolean;
  procedure updateClick;
  procedure updateGame(Value : Boolean);
  procedure updateAyuda; Override;
  function updateBaul : boolean;
 public
  constructor Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
  destructor Destroy; Override;
  function RenderGame : byte;
 end;

const
 LlaveDentro : array [1..3] of word = (240,296,352);
 LlaveGira   : array [1..3] of word = (250,306,362);
 ColLlavin   : array [1..3] of word = (242,298,354);

 // Game Options

 LoadGameComun = 0;
 LoadGame      = 1;
 RenderRun     = 2;
 QuitGame      = 3;
 RenderClick   = 4;
 RenderTriste  = 5;
 RenderAlegre  = 6;
 RenderBaul    = 7;
 RenderAyuda   = 8;

// Click Options
 UnoClick = 0;
 DosClick = 1;

var
 ju1 : TGame1;

constructor TGame1.Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
 var
  i : byte;
 begin
  inherited Create(Screen,KeyBoard,Sound,Mouse);
  lib := TILib.Create(scr,'Lib\Juego1.lib');
  SndLib := TSoundLibrary.Create('Lib\Juego1.snd',Sound);
  SndLib.LoadModFromLibrary(0,musica);
  for i := 1 to 4 do
   SndLib.LoadWaveFromLibrary(i,efectos[i]);
  fSound.PlayModule(musica);
  ioerror := 0; iocorrect := 0;
  options := LoadGameComun;
  imgIndex := 0; selected := false;
  borradas := TList.Create;
 end;

destructor TGame1.Destroy;
 var
  i : integer;
 begin
  FreeAllEffects;
  fSound.StopModule;
  SndLib.FreeModule(musica);
  SndLib.Free;
  for i := 0 to borradas.Count-1 do freemem(borradas.items[i]);
  borradas.Free;
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TGame1.desorden;
 var
  i,cont : byte;
 begin
   vSet := [];i:= 0;
   repeat
    cont:= random (12) + 1;
    if not (cont in vSet) then
     begin
      vSet := vSet + [cont];
      inc (i);
      vArray[i] := cont;
      Answer[i] := cont;
     end;
   until (i = 3);
   vSet := [];
 end;

procedure TGame1.updateAyuda;
 var
  i,b : byte;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 1 to 3 do
   begin
    scr.surface.Draw(ColLlavin[i],182,images[vArray[i]+3].Surface,false);
    if Answer[i] = 255 then scr.surface.Draw(LlaveDentro[i],182,images[2].Surface,true);
   end;
  for i := 1 to borradas.Count do
   begin
    b := pbyte(borradas.Items[i-1])^;
    scr.surface.fillrect(rect(100+36*(b-1),268,134+36*(b-1),314),ConverTo16bits(0,0,224));
   end;
  scr.Surface.Draw(24,147,fAyuda.Imagen.Surface,false);
 end;

procedure TGame1.updateGame(Value : Boolean);
 var
  i,b : byte;
 begin
  scr.surface.Draw(0,0,imgcomun[0].Surface,false);
  if Value then scr.surface.Draw(518,342,imgcomun[1].Surface,true);
  if fSalir then scr.Surface.Draw(561,0,imgcomun[9].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,imgcomun[8].surface,true);
  scr.Surface.Draw(66,66,images[0].Surface,false);
  scr.Surface.Draw(80,354,images[1].Surface,false);
  for i := 1 to 3 do
   begin
    scr.surface.Draw(ColLlavin[i],182,images[vArray[i]+3].Surface,false);
    if Answer[i] = 255 then scr.surface.Draw(LlaveDentro[i],182,images[2].Surface,true);
   end;
  for i := 1 to borradas.Count do
   begin
    b := pbyte(borradas.Items[i-1])^;
    scr.surface.fillrect(rect(100+36*(b-1),268,134+36*(b-1),314),ConverTo16bits(0,0,224));
   end;
 end;

function TGame1.updateBaul : boolean;
 begin
  updateGame(True);
  if GetTickCount - TATick >=120 then
   begin
    TATick := GetTickCount;
    inc(TickClick,cj);
    if (TickClick = 148) or (TickClick = 138) then
     begin
      cj := -cj;
      inc(ci);
     end;
   end;
  scr.surface.Draw(210,94,images[17].Surface,false);
  scr.surface.draw(254,TickClick,images[16].Surface,true);
  result := ci=4;
 end;

procedure TGame1.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  extra : pbyte;
begin
 if ActualSound(X,Y) then exit;
 if ptinrect(rect(561,0,588,26),Point(X,Y)) then
  begin
   Prepare(False);
   options := RenderTriste;
   efectos[2].Play;
   exit;
  end;
 selected_value := select;
 if (selected_value <> 0) and not ((selected_value in vSet) or selected) then
  begin
   vSet := vSet + [selected_value];
   getmem(extra,sizeof(byte));
   extra^ := selected_value;
   borradas.Add(extra);
   options := RenderClick;
   selected := true;
   optionsClick := UnoClick;
  end;
end;

function TGame1.RenderGame : byte;
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
      desorden;
      options := RenderRun;
      fMouse.SetMouseEvent(MouseMove,MouseDown,nil);
      fMouse.RestoreAllEvents;
     end;
   end; // end of loadgame
   RenderRun : begin
    if isEscape in key.States then
     begin
      Prepare(False);
      options := RenderTriste;
      efectos[2].Play;
     end;
    if isF1 in key.States then options := RenderAyuda;
    updateGame(True);
   end;
   RenderClick : begin
    updateClick;
   end;
   RenderBaul : begin
    if updateBaul then
     begin
      Prepare(True);
      options := RenderAlegre;
      efectos[1].Play;
     end;
   end;
   RenderTriste : begin
    updateGame(False);
    if AnimaTriste then result := 2;
   end;
   RenderAlegre : begin
    updateGame(False);
    if AnimaAlegre then result := 1;
   end;
   RenderAyuda : begin
    ProcessHelp(RenderRun,1,5);
   end;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TGame1.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

function TGame1.select : byte;
 begin
  result:= 0;
  if not ptinrect(rect(97,266,518,313),point(fMouse.MouseX,fMouse.MouseY)) then exit;
  result := (abs(fMouse.MouseX - 98) div 36)+1;
 end;

procedure TGame1.updateClick;
 var
  j : byte;
 begin
  updateGame(True);
  case optionsClick of
   UnoClick : begin
    duroClick := false;
    for j := 1 to 3 do
     if selected_value = Answer[j] then
      begin
       duroClick := true;
       tickClick := GetTickCount;
       llaveClick := 3;
       llaveSel := j;
       optionsClick := DosClick;
       efectos[3].Play;
      end;
    if not duroClick then
      begin
       efectos[4].Play;
       inc(ioerror);
       selected := false;
 //      Sound.PlayEffect(Wave[4]);
       if ioerror = 3 then
        begin
         selected := true;
         Prepare(False);
         options := RenderTriste;
         efectos[2].Play;
        end else options := RenderRun;
      end;
   end;
   DosClick : begin
    case llaveClick of
     3: scr.surface.Draw(LlaveGira[llaveSel],176,images[3].Surface,true);
     4: begin
         scr.surface.Draw(LlaveDentro[llaveSel],182,images[2].Surface,true);
         Answer[llaveSel] := 255;
        end;
    end; // end of case
    if GetTickCount - TickClick >= 200 then
     begin
      TickClick := GetTickCount;
      inc(llaveClick);
     end;
    if llaveClick = 5 then
     begin
      inc(iocorrect);
      selected := false;
      if iocorrect = 3 then
       begin
        TATick := GetTickCount;
        TickClick := 138;
        cj := 1; ci := 0;
        options := RenderBaul;
        selected := true;
       end else options := RenderRun;
     end;
   end;
  end;
 end;

function IDGame : Integer; stdcall;
 begin
  Result := 10;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  ju1 := TGame1.Create(Screen,KeyBoard,Sound,Mouse);
  result := ju1.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  ju1.Free;
 end;

end.
