unit SetupMain;

interface

Uses Windows, Classes, DXClass, DXDraws, VarsComun, Controls,
     Module, ModTypes;

type
 TSetup = class
  private
   mOwner : TComponent;
   images : array[0..26] of TAutomaticSurfaceLib;
   imgIndex : dword;
   SetupLib : TILib;
   options : word;
   gamesLoad : TList;
   GamesReady: TList;
   JuegoPos, JuegoMax : word;

   selected : byte;
   down : byte;

   mem : TmemoryStream;
   sndlib : TSoundLibrary;
   musica : TMod;
   efecto : TWavLib;
   prueba : boolean;
  protected
   function RenderLoad : boolean;
   procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure DisplayAll;
   procedure CheckGames;
   procedure ExistGameReady(id : integer);
   procedure ClearSetup;

   procedure AboutIdle(Sender: TObject; var Done: Boolean);
  public
   constructor Create(Owner : TComponent);
   destructor Destroy; Override;
   function RenderFrame : boolean;
 end;

var
 Setup : TSetup;

 procedure DXInit(Forms : TDXForm; Width, Height, Bits : integer);
 procedure DXClose;

implementation

Uses Forms, Graphics, SysUtils, Messages,
     DXInput, SetupVars, Mouse, DLL, MainSetup;

type
 TGame = record
  Number : integer;
  Play : boolean;
 end;
 PGame = ^TGame;

const
 SetupInit = 0;
 SetupLoad = 1;
 SetupRun  = 2;
 SetupQuit = 3;

 cposition = 10;
 rects : array[1..cposition] of TRect =
  ((left:203;top:170;right:264;bottom:191),  // Musica
   (left:203;top:239;right:264;bottom:260),  // efectos
   (left:203;top:307;right:264;bottom:328),  // prueba
   (left:342;top:313;right:401;bottom:342),  // arriba
   (left:530;top:313;right:589;bottom:342),  // abajo
   (left:406;top:313;right:525;bottom:342),  // si largo
   (left:388;top:365;right:455;bottom:396),  // grabar
   (left:470;top:365;right:537;bottom:396),  // salir
   (left:288;top:50;right:623;bottom:65),    // configurador acerca de...
   (left:344;top:57;right:587;bottom:292)    // Juego
   );

var
 save : TSave;
 RenderAbout : TFarProcObj;
 CoDestroyAbout : TCoDestroyGame;
 CoCreateAbout : TCoCreateGame;
 
procedure TSetup.AboutIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderAbout <> 0 then
   begin
    CoDestroyAbout;
    Application.OnIdle := fmain.AppOnIdle;
    fMouse.ClearMouseHard;
    fMouse.SetMouseEvent(nil,MouseDown,MouseUp);
    fMouse.RestoreAllEvents;
    key.ClearStates;
   end;
 end;

procedure TSetup.ClearSetup;
 var
  i :word;
 begin
  zeromemory(@save,sizeof(TSave));
  save.Musica := Sound.ExistSound;
  save.Efectos := save.Musica;
  if GamesReady.Count <> 0 then
   for i := 0 to GamesReady.Count-1 do
    begin
     dispose(GamesReady.Items[i]);
     GamesReady.Delete(i);
    end;
  GamesReady.Clear;
  CheckGames;
 end;

constructor TSetup.Create(Owner : TComponent);
 var
  i,c : word;
  tmp : PGame;
 begin
  mOwner := Owner;
  zeromemory(@save,sizeof(TSave));
  options := SetupLoad;
  fMouse := TMouse.Create(scr,true);
  try
   SetupLib := TILib.Create(scr,'Lib\Configurador.lib');
  except
   raise Exception.Create('Error en el archivo Configurador.lib');
  end;
  imgIndex := 0;
  try
   sndlib := TSoundLibrary.Create('Lib\Configurador.snd',Sound);
   sndlib.LoadWaveFromLibrary(1,efecto);
   sndlib.LoadModFromLibrary(0,musica);
  except
  end;
  GamesReady := TList.Create;
  selected := 0; down := 0;
  prueba := false;
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
    end else ClearSetup;
  except
   ClearSetup;
  end;
  if not Sound.ExistSound then
   begin
    save.musica := false;
    save.efectos := false;
   end;
  Sound.SaveMusic := save.musica;
  Sound.SaveEffect := save.efectos;
  Sound.Music := save.musica;
  Sound.Effect := save.efectos; 
// extra
  AddFontResource(PChar(ExtractFilePath(Application.ExeName)+'MARIGOLD.TTF'));
  SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
 end;

destructor TSetup.Destroy;
 var
  i : integer;
 begin
// extra
  RemoveFontResource(PChar(ExtractFilePath(Application.ExeName)+'MARIGOLD.TTF'));
  SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);

  Sound.StopModule;
  sndlib.FreeModule(musica);
  efecto.Free;
  fMouse.Free;
  mem.Free;
  for i := 0 to SetupLib.ImageCount - 1 do images[i].Free;
  SetupLib.Free;
  inherited Destroy;
 end;

function TSetup.RenderLoad : boolean;
 begin
  SetupLib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.ctransparent;
  inc(imgIndex);
  result := imgIndex = SetupLib.ImageCount;
  fMouse.ProgressImage(images[0].surface,imgIndex,26);
 end;

procedure TSetup.DisplayAll;
 var
  i,c : word;
 begin
  with save , scr.surface do
  begin
   draw(0,0,images[0].surface,false); // imagen de fondo
   if JuegoMax > 0 then
    begin
     draw(344,157,images[PGame(GamesReady.items[JuegoPos])^.Number].surface,false);
     draw(406,313,images[3+byte(PGame(GamesReady.items[JuegoPos])^.Play)].surface,false);
    end;
   scr.surface.draw(203,170,images[5+byte(save.musica)].surface,false);
   scr.surface.draw(203,239,images[5+byte(save.efectos)].surface,false);
   if prueba then scr.Surface.Draw(203,307,images[9].surface,false);
   case down of
    1 : case selected of
         4 : scr.surface.draw(342,313,images[7].surface,false);
         5 : scr.surface.draw(530,313,images[8].surface,false);
         7 : begin
          scr.surface.draw(388,365,images[1].surface,false);
          mem.Clear;
          strPCopy(@save.id,bunnyID);
          mem.Write(save,sizeof(TSave));
          c := 0;
          mem.Write(c,sizeof(word));
          for i := 0 to GamesReady.Count -1 do
           if PGame(GamesReady.items[i])^.Play then
            begin
             mem.Write(PGame(GamesReady.items[i])^,sizeof(TGame));
             inc(c);
            end;
          mem.Seek(sizeof(TSave),soFromBeginning);
          mem.Write(c,sizeof(word));
          mem.SaveToFile('bunny.cfg');
         end;
         8 : scr.surface.draw(470,365,images[2].surface,false);
        end;
    2 : case selected of
         8 : options := SetupQuit;
        end;
   end;
  end;
 end;

procedure TSetup.ExistGameReady(id : integer);
 var
  tmp : PGame;
  i : word;
  full: boolean;

  procedure AddGameReady;
   begin
    new(tmp);
    tmp^.Number := id;
    tmp^.Play := false;
    GamesReady.Add(tmp);
   end;

 begin
  if GamesReady.Count = 0 then
   begin
    AddGameReady;
    exit;
   end;
  full := false;
  for i := 0 to GamesReady.Count-1 do
   if PGame(GamesReady.Items[i])^.Number = id then full := true;
  if not full then AddGameReady;
 end;

procedure TSetup.CheckGames;
 var
  i : integer;

 function ExistGameLoad(id : integer) : boolean;
  var
   j : integer;
  begin
   result := false;
   for j := 0 to GamesLoad.Count-1 do if PInteger(GamesLoad.Items[j])^=id then result := true;
  end;

 begin
  GamesLoad := LoadDLLids;
  if GamesLoad.Count = 0 then GamesReady.Clear
   else
    begin
     for i := 0 to GamesLoad.count-1 do ExistGameReady(PInteger(GamesLoad.Items[i])^);
     i := 0;
     while i <> GamesReady.Count do
      if not ExistGameLoad(PGame(GamesReady.Items[i])^.Number) then
       begin
        dispose(GamesReady.Items[i]);
        GamesReady.Delete(i);
       end else inc(i);
    end;
 end;

function TSetup.RenderFrame : boolean;
 begin
  result := false;
  key.Update;
  case options of
   SetupLoad : begin
    if RenderLoad then
     begin
      fMouse.SetMouseEvent(nil,MouseDown,MouseUp);
      options := SetupRun;
      CheckGames;
      JuegoMax := GamesReady.Count;
      JuegoPos := 0;
     end;
   end;
   SetupRun : begin
    if isEscape in key.States then options := SetupQuit;
    DisplayAll;
   end;
   SetupQuit : result := true;
  end;
  fMouse.AnimaMouseHard;
  scr.Flip;
 end;

procedure TSetup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  i : byte;
 begin
  for i := 1 to cposition do
   if ptinrect(rects[i],point(X,Y)) then
    begin
     efecto.Play;
     case i of
      1 : if Sound.ExistSound then save.Musica := not save.Musica;
      2 : if Sound.ExistSound then save.Efectos := not save.Efectos;
      3 : begin
       if Sound.ExistSound and save.musica then
        begin
         prueba := not prueba;
         if prueba then Sound.PlayModule(musica) else Sound.StopModule;
        end;
      end;
      4 : begin
       if JuegoMax > 0 then if JuegoPos = 0 then JuegoPos := GamesReady.Count -1 else dec(JuegoPos);
      end;
      5 : begin
       if JuegoMax > 0 then if JuegoPos = GamesReady.Count -1 then JuegoPos := 0 else inc(JuegoPos);
      end;
      6 :
      if JuegoMax > 0 then PGame(GamesReady.Items[JuegoPos])^.Play := not PGame(GamesReady.Items[JuegoPos])^.Play;
      9 : begin
       if LoadDLL(100) then
        begin
         Sound.StopModule;
         Sound.Music := save.musica;
         Sound.Effect := save.efectos;
         CoCreateAbout := LoadDLLProc('CoCreateGame');
         CoDestroyAbout := LoadDLLProc('CoDestroyGame');
         RenderAbout := CoCreateAbout(scr,key,Sound,fMouse);
         fMouse.SetMouseEvent(nil,nil,nil);
         fMouse.StopAllEvents;
         Application.OnIdle := AboutIdle;
         prueba := false;
        end;
      end;
     end;
     Sound.Effect := save.efectos;
     Sound.Music := save.musica;
     down := 1;
     selected := i;
     break;
    end;
 end;

procedure TSetup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  down := 2;
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
  Screen.Cursor := crDefault;
  Sound.Free;
  key.Free;
  scr.Finalize;
  scr.free;
 end;


end.
