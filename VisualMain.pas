unit VisualMain;

interface

Uses Windows, Classes, DXClass, DXDraws, VarsComun, Controls,
     Module, ModTypes;

type
 TVisualizador = class
  private
   images : array[0..26] of TAutomaticSurfaceLib;
   imgIndex : dword;
   VisualLib : TILib;
   options : word;
   gamesLoad : TList;
   GamesReady: TList;
   JuegoPos, JuegoMax : word;

   selected : byte;
   down : byte;

   sndlib : TSoundLibrary;
   musica : TMod;
   efecto : TWavLib;

  protected
   function RenderLoad : boolean;
   procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure DisplayAll;
   procedure CheckGames;

   procedure AboutIdle(Sender: TObject; var Done: Boolean);
   procedure GameIdle(Sender: TObject; var Done: Boolean);
   procedure NormalIdle;
  public
   constructor Create;
   destructor Destroy; Override;
   function RenderFrame : boolean;
 end;

var
 Visualizador : TVisualizador;

 procedure DXInit(Forms : TDXForm; Width, Height, Bits : integer);
 procedure DXClose;

implementation

Uses Forms, Graphics, SysUtils, Messages,
     DXInput, SetupVars, Mouse, DLL, MainVisualizador;

Type
 TGame = record
  Number : integer;
  Play : boolean;
 end;
 PGame = ^TGame;

const
 VisualInit = 0;
 VisualLoad = 1;
 VisualRun  = 2;
 VisualQuit = 3;

 cposition = 6;
 rects : array[1..cposition] of TRect =
  ((left:288;top:66;right:623;bottom:91),   // acerda de...
   (left:200;top:306;right:247;bottom:335), // arriba
   (left:252;top:306;right:401;bottom:335), // jugar
   (left:406;top:306;right:451;bottom:335), // abajo
   (left:294;top:362;right:361;bottom:393), // salir
   (left:204;top:144;right:447;bottom:279)  // click en el juego = jugar
   );

var
 save : TSave;
 RenderGames : function : byte of object;
 RenderAbout : TFarProcObj;
 CoDestroyAbout : TCoDestroyGame;
 CoCreateAbout : TCoCreateGame;

procedure TVisualizador.NormalIdle;
 begin
  CoDestroyAbout;
  Application.OnIdle := fmain.AppOnIdle;
  fMouse.StopAllEvents;
  fMouse.SetMouseEvent(nil,MouseDown,MouseUp);
  fMouse.RestoreAllEvents;
  key.ClearStates;
  selected := 0; down := 0;
  Sound.RestoreSaveMusic;
  Sound.PlayModule(musica);
 end;

procedure TVisualizador.AboutIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderAbout <> 0 then NormalIdle;
 end;

procedure TVisualizador.GameIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderGames <> 0 then NormalIdle;
 end;

constructor TVisualizador.Create;
 var
  mem : TMemoryStream;
  i,c : word;
  tmp : PGame;
 begin
  zeromemory(@save,sizeof(TSave));
  options := VisualLoad;
  fMouse := TMouse.Create(scr,false);
  VisualLib := TILib.Create(scr,'Lib\Configurador.lib');
  imgIndex := 0;
  try
   SndLib := TSoundLibrary.Create('Lib\Configurador.snd',Sound);
   SndLib.LoadModFromLibrary(0,musica);
   SndLib.LoadWaveFromLibrary(1,efecto);
  except
  end;
  GamesReady := TList.Create;
  selected := 0; down := 0;
  mem := TMemoryStream.Create;
  try
   mem.LoadFromFile('bunny.cfg');
   mem.Seek(0,soFromBeginning);
   mem.Read(save,sizeof(TSave));
   if strpas(@save.id) = BunnyID then
    begin
     mem.Read(c,sizeof(word));
     for i := 1 to c do
      begin
       getmem(tmp,sizeof(TGame));
       mem.Read(tmp^,sizeof(TGame));
       GamesReady.Add(tmp);
      end;
     CheckGames;
    end;
  except
   save.Musica := Sound.ExistSound;
   save.Efectos := save.Musica;
   if GamesReady.Count > 0 then
    for i := 0 to GamesReady.Count-1 do
     begin
      freemem(GamesReady.Items[i]);
      GamesReady.Delete(i);
     end;
   GamesReady.Clear;
  end;
  mem.Free;
  if not Sound.ExistSound then
   begin
    save.musica := false;
    save.efectos := false;
   end;
  Sound.UpdateSaveMusic(save);
  Sound.Music := save.musica;
  Sound.Effect := save.efectos;
// extra
  AddFontResource(PChar(ExtractFilePath(Application.ExeName)+'MARIGOLD.TTF'));
  SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
  Sound.PlayModule(musica);
 end;

destructor TVisualizador.Destroy;
 var
  i : integer;
 begin
// extra
  RemoveFontResource(PChar(ExtractFilePath(Application.ExeName)+'MARIGOLD.TTF'));
  SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);

  Sound.StopModule;
  SndLib.FreeModule(musica);
  efecto.Free;
  fMouse.Free;
  for i := 0 to VisualLib.ImageCount - 1 do images[i].Free;
  VisualLib.Free;
  inherited Destroy;
 end;

procedure TVisualizador.DisplayAll;
 begin
  with save , scr.surface do
  begin
   draw(0,0,images[23].surface,false); // imagen de fondo
   if JuegoMax > 0 then
    begin
     draw(204,144,images[PGame(GamesReady.items[JuegoPos])^.Number].surface,false);
    end;
   case down of
    1 : case selected of
         2 : scr.surface.draw(200,306,images[25].surface,false);
         3 : scr.surface.draw(252,306,images[24].surface,false);
         4 : scr.surface.draw(406,306,images[26].surface,false);
         5 : scr.surface.draw(294,362,images[2].surface,false);
        end;
    2 : case selected of
         1 : begin
          if LoadDLL(100) then
           begin
            CoCreateAbout := LoadDLLProc('CoCreateGame');
            CoDestroyAbout := LoadDLLProc('CoDestroyGame');
            RenderAbout := CoCreateAbout(scr,key,Sound,fMouse);
            fMouse.SetMouseEvent(nil,nil,nil);
            fMouse.StopAllEvents;
            Application.OnIdle := AboutIdle;
           end;
         end;
         3,6 : begin
          if LoadDLL(PGame(GamesReady.items[JuegoPos])^.Number) then
           begin
            fMouse.StopAllEvents;
            CoCreateAbout := LoadDLLProc('CoCreateGame');
            CoDestroyAbout := LoadDLLProc('CoDestroyGame');
            RenderGames := CoCreateAbout(scr,key,Sound,fMouse);
            Application.OnIdle := GameIdle;
           end;
         end;
         5 : options := VisualQuit;
        end;
   end;
  end;
 end;

function TVisualizador.RenderFrame : boolean;
 begin
  result := false;
  key.Update;
  case options of
   VisualLoad : begin
    if RenderLoad then
     begin
      fMouse.SetMouseEvent(nil,MouseDown,MouseUp);
      options := VisualRun;
      JuegoMax := GamesReady.Count;
      JuegoPos := 0;
     end;
   end;
   VisualRun : begin
    if isEscape in key.States then options := VisualQuit;
    DisplayAll;
   end;
   VisualQuit : result := true;
  end;
  fMouse.AnimaMouse;
  scr.Flip;
 end;

procedure TVisualizador.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  i : byte;
 begin
  for i := 1 to cposition do
   if ptinrect(rects[i],point(X,Y)) then
    begin
     efecto.Play;
     case i of
      2 : begin
       if JuegoMax > 0 then if JuegoPos = 0 then JuegoPos := GamesReady.Count -1 else dec(JuegoPos);
      end;
      4 : begin
       if JuegoMax > 0 then if JuegoPos = GamesReady.Count -1 then JuegoPos := 0 else inc(JuegoPos);
      end;
     end;
     down := 1;
     selected := i;
     break;
    end;
 end;

procedure TVisualizador.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  down := 2;
 end;

procedure TVisualizador.CheckGames;
 var
  i : integer;

 function ExistGameReady(id : integer) : boolean;
  var
   j : integer;
  begin
   result := false;
   for j := 0 to GamesLoad.Count-1 do if PInteger(GamesLoad.Items[j])^=id then result := true;
  end;

 begin
  if GamesReady.Count = 0 then exit;
  GamesLoad := TList.Create;
  GamesLoad := LoadDLLids;
  if GamesLoad.Count = 0 then GamesReady.Clear
   else
    begin
     i := 0;
     while i <> GamesReady.Count do
      if not ExistGameReady(PGame(GamesReady.Items[i])^.Number) then
       begin
        freemem(GamesReady.Items[i]);
        GamesReady.Delete(i);
       end else inc(i);
    end;
  GamesLoad.Free;
 end;
 
function TVisualizador.RenderLoad : boolean;
 begin
  VisualLib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.ctransparent;
  inc(imgIndex);
  result := imgIndex = VisualLib.ImageCount;
  scr.Surface.Fill(0);
  fMouse.ProgressImage(nil,imgIndex,26);
 end;

 /////////////////////////////////////////////
///////////////////////////////////////////////
////                                       ////
////     DDDD    U   U   RRR     OOOO      ////
////     D   D   U   U   R  R   O    O     ////
////     D    D  U   U   R  R   O    O     ////
////     D    D  U   U   RRR    O    O     ////
////     D   D   U   U   R  R   O    O     ////
////     DDDD     UUU    R   R   OOOO      ////
////                                       ////
///////////////////////////////////////////////
 /////////////////////////////////////////////

procedure CreateDirectInputGame(Owner : TComponent);
 begin
  key := tdxinput.create(Owner);
  key.UseDirectInput := false;
  key.UseDirectInput := true;
  key.Keyboard.Enabled := true;
  key.Keyboard.BindInputStates := true;
  key.Mouse.Enabled := true;
  key.Mouse.BindInputStates := true;
 end;


procedure DXInit(Forms : TDXForm; Width, Height, Bits : integer);
 begin
  scr :=TDXDraw.Create(Forms);
  scr.Width := Width;
  scr.Height := Height;
  scr.Display.BitCount := Bits;
  scr.Display.Width := Width;
  scr.Display.Height := Height;
  scr.parent := Forms;
  scr.Options := [doAllowReboot,doWaitVBlank,doCenter,doFlip];
  if FullScreen then
   begin
    Forms.StoreWindow;
    scr.Options := scr.Options + [doFullScreen];
   end;
  scr.Initialize;
  CreateDirectInputGame(Forms);
  Sound := TSoundSystem.Create(Forms);
 end;

procedure DXClose;
 begin
  Sound.Free;
  key.Free;
  scr.Finalize;
  scr.free;
 end;


end.
