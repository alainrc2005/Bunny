unit GameMain;

interface

Uses Classes, DXClass, DXDraws;

 procedure DXInit(Forms : TDXForm; Width, Height, Bits : integer);
 procedure DXClose;
 procedure RenderFrame;
 procedure CreateDirectInputGame(Owner : TComponent);

implementation

Uses Windows, Forms, DXInput, SysUtils,
     Vars, VarsComun, Mouse, Present, Scroll, DLL, Module;

Const

// Present swicth
 Present1 = 0;
 Present2 = 1;
 Present3 = 2;
 Present4 = 3;
 PresentLoad = 4;

// Game swicth
 LoadIntro = 0;
 RunIntro  = 1;
 LoadAmb   = 2;
 EndGame   = 3;

var
 GameThread : word = LoadIntro;
 PresentThread : word = PresentLoad;
 GamesLoad : TList;

procedure CheckGames;
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


procedure LoadSetup;
 var
  mem : TMemoryStream;
  i,c : word;
  tmp : PGame;
 begin
  GamesReady := TList.Create;
  try
   mem := TMemoryStream.Create;
   mem.LoadFromFile('bunny.cfg');
   mem.Seek(0,soFromBeginning);
   mem.Read(save,sizeof(TSave));
   if strpas(@save.id) = BunnyID then
    begin
     Sound.Music := save.musica;
     Sound.Effect := save.efectos;
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
  mem.free;
  if not Sound.ExistSound then
   begin
    save.musica := false;
    save.efectos := false;
   end;
  Sound.UpdateSaveMusic(save);
 end;

procedure RenderFrame;
 begin
  key.Update;
  case GameThread of
   LoadIntro: begin
    LoadSetup;
    fMouse := TMouse.Create(scr,false);
    fpresent := Tfpresent.Create;
    GameThread := RunIntro;
    key.ClearStates;

{    fScroll := TScroll.Create;
    GameThread := LoadAmb;}
   end;
   RunIntro: begin
              case PresentThread of
               PresentLoad : if fpresent.RenderLoad then PresentThread := Present1;
               Present1: begin
                fpresent.Render1;
                if [isSpace,isButton1]*Key.States<>[] then
                 begin
                  key.ClearStates;
                  PresentThread := Present2;
                 end;
               end;
               Present2: begin
                fpresent.Render2;
                if ([isSpace,isButton1]*Key.States<>[]) or (fpresent.Amplitud = 56) then
                 begin
                  key.ClearStates;
                  PresentThread := Present3;
                 end;
               end;
               Present3: begin
                fpresent.Render3;
                if ([isSpace,isButton1]*Key.States<>[]) or (fpresent.Amplitud = 0) then
                 begin
                  key.ClearStates;
                  PresentThread := Present4;
                 end;
               end;
               Present4: begin
                fpresent.Render4;
                if ([isSpace,isButton1]*Key.States<>[]) then
                 begin
                  key.ClearStates;
                  fpresent.Free;
                  fScroll := TScroll.Create;
                  GameThread := LoadAmb;
                 end;
               end;
              end;{end case}
             end;
   LoadAmb : begin
    if fScroll.RenderLoad then Application.OnIdle := fScroll.WaitIdle;
   end;
  end;
  fMouse.AnimaMouse;
  scr.Flip;
 end;

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
  key.free;
  scr.Finalize;
  scr.free;
 end;


end.
