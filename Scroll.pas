{$DEFINE NOcanvas}
unit Scroll;

interface

Uses Windows, Classes, Controls, DXDraws,
     Vars, VarsComun, Ambiente, Zanahorias, Peligros, Manzanas, Cueva, Piedras, ModTypes, Module, Ayuda;

Type
 TScroll = class
  private
    libAmb : TILib;  // libreria de ambiente
    libRab : TILib;  // libreria de conejos
    libDan : TILib;  // libreria de peligros
    sndLib : TSoundLibrary; // libreria de sonidos
    CaseLoad : byte;
    imgIndex : word;
    imgTotal : word;

    virt     : TAutomaticSurface;

    // Others
    tWalk,rWalk : byte;    {variables para la animacion del conejo}

    cpri,cult   : byte;   {variables de animacion}
    ccrece      : dword;   {para crecer y disminuir}
    crece       : boolean;

    // variables para el hada madrina
    hvarita     : boolean; {si esta activa la varita magica}
    hada,hadaEscape  : boolean; {hada visible}
    hcorx,hcory : integer; {coordenada de las hadas}
    htip        : byte;
    salto1sig   : shortint; {direccion del salto hacia el hada}
    SaltoHadas  : boolean; // salto para topar hada
    salto       : boolean; // activa el salto del conejo
    saltotick   : dword;
    conts,vec   : byte;    {contador del salto}
    waitjump    : dword; {velocidad de animacion del salto}

    avarita     : byte;    {variable de animacion de la varita magica}
    waitvarita  : dword; {espera en la animacion de la varita}

    // tratamiento de peligros destruccion
    dangtip     : byte;    {cual peligro es}
    virar       : boolean; {cuando pierde una vida y vira}
    cvirar      : byte;    {pasos a virar}
    cvirartick  : dword;

    lives       : byte; // cantidad de vidas

    czana       : byte;    {cantidad de zanahorias}

    KeyTick : dword; // tick count for keyboard

    peligros : array[1..6] of TPeligros; // objeto de peligros
    ambiente : array[1..11] of TAmbiente;  // objeto de ambiente
    pdelante : array[1..4] of TAmbiente;  // objetos de ambiente por delante del conejo
    zanahorias: array[1..8] of TZanahoria; // zanahorias de premio 8+1salto+1cueva
    manzanas : array[1..9] of TManzanas;
    piedra : TPiedras;
    PiedraEnabled : boolean;
    HadaPiedra : boolean;

    Right,Left : Boolean; // izquierda y derecha con el mouse;
    ZanaSel : byte; // Zanahoria seleccionada cuando se entra al juego

    DormirImg : integer; // contador de animacion de dormir
    DormirCiclo : byte;

    {Variables de la cueva}
    optionsCueva : word;
    libCueva : TILib;
    imgIndexCueva : dword;
    leftright : boolean; // true = entra por la derecha false = entra por la izquierda
    aranas : array[1..4] of TAranas; // arañas en la cueva
    CuevaD : boolean; // variable para cuando sale de la cueva darle una zanahoria
    {FIN de las variables de la cueva}

    RioD : boolean; // variable para cuando cruza el rio darle una zanahoria

    // adios y animaciones de aburrimiento
    optionsWait : word;
    indexWait : integer;
    libWait : TILib;
    imgWait : array[0..9] of TAutomaticSurfaceLib;
    typeWait : byte;
    tickWait : dword;

    modamb : TMod;
    tmp : TMod;
    efectos : array[1..17] of TWavLib;
    //Salir del juego
    fSalir : boolean;
    fSonido : boolean;
    cxs : integer;
    SalirTick : dword;

    Ayuda : TAyuda;
   procedure Finish;
   procedure StopAllEffects;
   function GetTocarFondo : boolean;
   procedure keyleft;  // cursor izquierda
   procedure keyright; // cursor derecha
   procedure updateKeyBoard;
   procedure calwalk; // calcula la animacion del conejo caminando
   procedure Grande;
   procedure Pequeno;
   procedure actualcrece; // crece actualiza las estrellas roja y azul
   procedure actualdismi; // disminuye actualiza las estrellas roja y azul
   procedure comuncrece(key : word); // animacion cuando crece y disminuye
   procedure updatehadas; // actualiza la animacion de las hadas
   procedure updatevarita; // animacion de la varita majica
   procedure updatesalto; // salto caminando;
   procedure updateSaltoHadas; // animacion salto en el lugar
   procedure updatecrece; // animacion crecer disminuir
   procedure bigsmall; // de chiquito a grande

   procedure updatepeligros; // determina si se destruye o no, decrementa vidas, etc
   procedure updateJuegos;   // cuando coge zanahorias entra a jugar
   procedure updateManzanas; // cuando se encuentra la arboleda de manzanas

   procedure FinishGame(Value : byte);  // cuando termina el juego incrementa o corre la zanahoria de lugar
   procedure updateLivesZana;
   procedure updateLivesZana2;
   procedure updateLivesZana3;

   procedure InitVars;
   procedure DoneVars;

   procedure GameOnIdle(Sender: TObject; var Done: Boolean);
   procedure DoneVarsGame;

   procedure EndIdle(Sender: TObject; var Done: Boolean);
   function RenderEnd : byte;
   function RenderEndLoad : boolean;
   procedure EndPart1;
   procedure EndPart2;

   procedure DormirIdle(Sender: TObject; var Done: Boolean);
   function RenderDormir : boolean;

   // Salir del juego
   procedure SalirIdle(Sender: TObject; var Done: Boolean);
   function RenderSalir : byte;
   procedure PrepareSalir(mCueva : boolean);
   procedure UpdateSalirMove;
   procedure MouseDownSalir(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

   {procedimientos relativos a la cueva}
   procedure CuevaIdle(Sender: TObject; var Done: Boolean);
   function RenderCueva : byte;
   function RenderCuevaLoad : boolean;
   function updateKeyBoardCueva : byte;
   procedure MouseDownCueva(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure MouseUpCueva(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure keyleftDec;  // cursor izquierda
   procedure keyrightDec; // cursor derecha
   procedure ActivaCueva;
   {FIN de los procedimientos relativos a la cueva}

   function ActualLives : boolean;

   procedure updatePiedra;
   procedure PiedraIdle(Sender: TObject; var Done: Boolean);
   function RenderPiedra : byte;
   function RenderPiedraLoad : boolean;

   function RenderAdiosLoad : boolean;
   function RenderWait : boolean;
   function RenderEsperaLoad : boolean;

   procedure AyudaIdle(Sender: TObject; var Done: Boolean);
   function RenderAyuda : boolean;

   procedure AboutIdle(Sender: TObject; var Done: Boolean);

  protected
   procedure RenderScroll;
   procedure MouseMove(Shift: TShiftState; X, Y: Integer);
   procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
   constructor Create;
   destructor Destroy; override;
   function RenderLoad : boolean;
   procedure AppOnIdle(Sender: TObject; var Done: Boolean);
   procedure WaitIdle(Sender: TObject; var Done: Boolean);
 end;

var
 fScroll : TScroll;

implementation

Uses Forms, Graphics, SysUtils, DXInput, Mouse, DLL;

const
 LoadAmbiente = 0;
 LoadConejos  = 1;
 LoadPeligros = 2;

 {ambiente 105
  conejos 78
  peligros 73}
 imagesGame = 105+78+73;

 // render options de la cueva
 LoadCueva = 0;
 MoveCueva = 1;

// render options de la piedra
 PiedraLoad  = 0;
 PiedraAnima = 1;

// render options de adios
 AdiosLoad  = 0;
 AdiosAnima = 1;

// render options de espera
 WaitInit = 2;
 WaitLoad = 3;
 WaitRun  = 4;

// Render options de final del juego
 EndLoad  = 0;
 EndAnima = 1;
 EndRun   = 2;
type
 TFarProcObj = function : byte of object;
 TCoCreateGame = function(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;

var
 RenderGames : function : byte of object;
 CoCreateGame : TCoCreateGame;
 CoDestroyGame : procedure; stdcall;

 RenderAbout : TFarProcObj;
 CoDestroyAbout : TCoDestroyGame;
 CoCreateAbout : TCoCreateGame;

{$INCLUDE SALIR.INC}
{$INCLUDE CUEVA.INC}
{$INCLUDE ESPERA.INC}

constructor TScroll.Create;
 var
  i : integer;
 begin
  Ayuda := nil;
  Randomize;
  libAmb := TILib.Create(scr,'Lib\Ambiente.lib');
  libRab := TILib.Create(scr,'Lib\Conejos.lib');
  libDan := TILib.Create(scr,'Lib\Peligros.lib');
  libWait := TILib.Create(scr,'Lib\Espera.lib');
  sndLib := TSoundLibrary.Create('Lib\Ambiente.snd',Sound);
  for i := 5 to 21 do
   sndlib.LoadWaveFromLibrary(i,efectos[i-4]);
  CaseLoad := LoadAmbiente;
  imgIndex := 0;
  imgTotal := 0;
  libAmb.CreateSurfaceIndex(0,amb[0]);
  amb[0].TransparentColor := fMouse.ctransparent;
  scr.CreateSurface(virt,592,186);
  optionsWait := AdiosLoad;
  indexWait := 0; fSalir := false; fSonido := Sound.Effect or Sound.Music;
  InitVars;
  SndLib.LoadModFromLibrary(random(3),modamb);
  Sound.PlayModule(modamb);
 end;

destructor TScroll.Destroy;
 var
  i : byte;
 begin
  for i := 1 to 17 do efectos[i].Free;
  Sound.StopModule;
  SndLib.FreeModule(modamb);
  SndLib.Free;
  libDan.Free;
  libRab.Free;
  libAmb.Free;
  inherited Destroy;
 end;

procedure TScroll.InitVars;
 var
  i : byte;
 begin
  UpdateDangerZanahoria;
  sPlano := 0; sScene := 0; sCielo := 0;
  for i := 1 to 11 do ambiente[i] := TAmbiente.Create(i,virt);
  for i := 12 to 15 do pdelante[i-11] := TAmbiente.Create(i,virt);
  for i := 1 to 9 do manzanas[i] := TManzanas.Create(i,virt);
  piedra := TPiedras.Create(virt);
  CuevaD := false; RioD := false;
  czana := 0;
  lives := 5;
  for i := 1 to 6 do peligros[i] := TPeligros.Create(virt);
  for i := 1 to 8 do zanahorias[i] := TZanahoria.Create(virt);
  tWalk := 2;
  bigsmall;
  hada := false; hadaEscape := false;
  SaltoHadas := false; salto := false;
  waitjump := GetTickCount;
  avarita := 4; hvarita := false;
  waitvarita := GetTickCount;
  virar := false;
  Right := false; Left := false;
  PiedraEnabled := false; HadaPiedra := false;
 end;

procedure TScroll.DoneVars;
 var
  i : byte;
 begin
  for i := 1 to 11 do ambiente[i].Free;
  for i := 12 to 15 do pdelante[i-11].Free;
  for i := 1 to 9 do manzanas[i].Free;
  piedra.Free;
  for i := 1 to 6 do peligros[i].Free;
  for i := 1 to 8 do zanahorias[i].Free;
 end;

function TScroll.RenderLoad : boolean;
 begin
  result := false;
  case CaseLoad of
   LoadAmbiente : begin
    inc(imgIndex);
    if imgIndex = libAmb.ImageCount then
     begin
      imgIndex := 0;
      CaseLoad := LoadConejos;
      exit;
     end;
    libAmb.CreateSurfaceIndex(imgIndex,amb[imgIndex]);
    amb[imgIndex].TransparentColor := fMouse.ctransparent;
   end;
   LoadConejos : begin
    libRab.CreateSurfaceIndex(imgIndex,walk[imgIndex]);
    walk[imgIndex].TransparentColor := fMouse.ctransparent;
    inc(imgIndex);
    if imgIndex = libRab.ImageCount then
     begin
      imgIndex := 0;
      CaseLoad := LoadPeligros;
      exit;
     end;
   end;
   LoadPeligros : begin
    libDan.CreateSurfaceIndex(imgIndex,danger[imgIndex]);
    danger[imgIndex].TransparentColor := fMouse.ctransparent;
    inc(imgIndex);
    if imgIndex = libDan.ImageCount then result := true;
    fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
   end;
  end;
  inc(imgTotal);
  fMouse.ProgressImage(224,173,amb[0].surface,imgTotal,imagesGame);
 end;

procedure TScroll.updateKeyBoard;
begin
 if isF1 in key.States then
  begin
   try
    Ayuda := TAyuda.Create(0,scr);
   except
   end;
   Sound.StopModule;
   sndlib.LoadModFromLibrary(24,HelpMusic);
   Sound.PlayModule(HelpMusic);
   StopAllEffects;
   Application.OnIdle := AyudaIdle;
   exit;
  end;
 //salto tocar hada
 if ((isButton2 in key.States) or (isUp in key.Keyboard.States)) and not (SaltoHadas or virar or salto or crece) then
  begin
   SaltoHadas := true;
   salto1sig := -1;
   awalk := canis[twalk];
   conts := 0;
   case twalk of
    1,4: vec := 20;
    2,5: vec := 10;
    3,6: vec := 30;
   end;
  end;
 // crecer F2
 if (isF2 in key.States) and not (PiedraEnabled) then Grande;
 // disminuir F3
 if (isF3 in key.States) and not (PiedraEnabled) then Pequeno;
 // close game
 if isEscape in key.States then
   begin
    PrepareSalir(False);
    exit;
   end;

  // salto con espacio
  if (isSpace in key.Keyboard.States) and not(crece or salto or SaltoHadas or virar) then
   begin
    salto := true;
    awalk := 37+twalk*5;
    conts := 0;
    saltotick := GetTickCount;
    case twalk of
     1,4: vec := 7;
     2,5: vec := 17;
     3,6: vec := 30;
    end;
   end;
   
 if GetTickCount - KeyTick < 50 then exit;
 KeyTick := GetTickCount;
 // derecha
 if ((isRight in key.KeyBoard.States) or Right) and not(crece or virar or salto or SaltoHadas) then
    keyright;
 // izquierda
 if ((isLeft in key.Keyboard.States) or Left) and not(crece or virar or salto or SaltoHadas) then
    keyleft;
 if not GetTocarFondo then
  case sScene of
   2368,6808 : efectos[14].Play;
   1184,592,5328 : efectos[15+random(3)].Play;
  end;
// if key.Keyboard.Keys[65] then for i := 1 to 40 do keyright;
end;

function TScroll.GetTocarFondo : boolean;
 var
  i : byte;
 begin
  result := false;
  for i := 14 to 17 do result := result or efectos[i].Playing;
 end;

procedure TScroll.MouseMove(Shift: TShiftState; X, Y: Integer);
 begin
  fSalir := ptinrect(rect(560,0,608,29),Point(X,Y));
 end;

procedure TScroll.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 var
  l,o : byte;
 begin
  if Button <> mbLeft then exit;
  if PtInRect(Rect(518,0,543,29),Point(X,Y)) then
   begin
    if Sound.ExistSound then
     begin
      if save.musica then Sound.Music := not Sound.Music;
      if save.efectos then Sound.Effect := not Sound.Effect;
      fSonido := Sound.Music or Sound.Effect;
      if Sound.Music then Sound.PlayModule(modamb) else
       begin
        StopAllEffects;
        Sound.StopModule;
       end;
     end;
    exit;
   end;
  if Ayuda <> nil then exit;
  if PtInRect(Rect(212,54,222,65),Point(X,Y)) then
   begin
    if LoadDLL(100) then
     begin
      CoCreateAbout := LoadDLLProc('CoCreateGame');
      if not assigned(CoCreateAbout) then exit;
      CoDestroyAbout := LoadDLLProc('CoDestroyGame');
      RenderAbout := CoCreateAbout(scr,key,Sound,fMouse);
      if not assigned(RenderAbout) then exit;
      fMouse.StopAllEvents;
      Application.OnIdle := AboutIdle;
     end;
   end;
  if fSalir then
   begin
    PrepareSalir(False);
    exit;
   end;
  o := 0;
  for l := 1 to zonecount do
   if ptinrect(zone[l],point(X,Y)) then
    begin
     o := l;
     break;
    end;
  if PiedraEnabled and (o in [1..2]) then exit;
  case o of
   1: Grande;
   2: Pequeno;
   3: if X > 320 then Right := true else Left := true;
  end;
 end;

procedure TScroll.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  if Right then Right := false;
  if Left then Left := false;
 end;

procedure TScroll.Grande;
 begin
  if not (SaltoHadas or salto or crece)then
   if not (twalk in [3,6]) then
    begin
     actualcrece;
     comuncrece(VK_F2);
    end;
 end;

procedure TScroll.Pequeno;
 begin
  if not (SaltoHadas or salto or crece) then
   if not (twalk in [1,4]) then
    begin
     actualdismi;
     comuncrece(VK_F3);
    end;
 end;

procedure TScroll.actualdismi;
 begin
  amb[0].Surface.draw(504,328,amb[71].Surface,false);
  amb[0].Surface.draw(568,328,amb[73].Surface,false);
 end;

procedure TScroll.actualcrece;
 begin
  amb[0].Surface.draw(504,328,amb[71].Surface,false);
  amb[0].Surface.draw(504,336,amb[72].Surface,false);
 end;

procedure TScroll.comuncrece(key : word);
 begin
  if key = vk_f2 then
   begin
    cpri := 83;
    cult := 85;
    efectos[1].Play;
   end
  else
   begin
    efectos[2].Play;
    cpri := 86;
    cult := 88;
   end;
  crece := true;
  ccrece := GetTickCount;
 end;

procedure TScroll.updatesalto;
 begin
  if salto then
   begin
    virt.Surface.draw(cx,cy-16,walk[awalk].Surface,true);
    if GetTickCount - saltotick < 20 then exit;
    saltotick := GetTickCount;
    if twalk in [1..3] then keyright else keyleft;
    if conts < 4 then
     begin
      inc(awalk);
      inc(conts);
     end
    else if vec<>0 then dec(vec) else
     begin
      dec(awalk);
      inc(conts);
     end;
    if conts = 8 then
     begin
      salto := false;
      calwalk;
     end;
   end;
 end;

procedure TScroll.updateSaltoHadas;
 begin
  if SaltoHadas then
   begin
    if GetTickCount - waitjump >= 30 then
     begin
      inc(cy,salto1sig);
      waitjump := GetTickCount;
      inc(conts);
      if (conts = vec) then
       if (salto1sig=-1) then
       begin
        salto1sig := 1;
        conts := 0;
       end
      else
       begin
        SaltoHadas := false;
        calWalk;
       end;
     end;
    if hada and (twalk>3) then
     if (htip = htwalk[twalk-3]) then
     begin
      if SurfaceCollision(cx,cy,hcorx,hcory,walk[awalk].Surface,amb[88+htip].Surface,true) then
       begin
        hada := false;
        hadaEscape := true;
        hvarita := true;
        if HadaPiedra then
         begin
          piedra.tip := htip;
          PiedraEnabled := true;
         end;
       end;
     end;
   end;
 end;

procedure TScroll.updatehadas;
 begin
  if hada then
   begin
    if hcorx < hxtop[htip] then inc(hcorx,4);
    virt.Surface.draw(hcorx,hcory,amb[88+htip].Surface,true);
   end
  else
   begin
    if not (hvarita or HadaEscape) then
     if (sScene > 2780) and (sScene < 3106) then
     begin
      hada := true; 
      htip := random(3)+1;
      hcorx := chcorx[htip];
      hcory := chcory[htip];
      HadaPiedra := true
     end;
   end;
  if hadaEscape then
   begin
    if hcorx < chpcorx[htip] then inc(hcorx,3) else hadaEscape := false;
    virt.Surface.draw(hcorx,hcory,amb[88+htip].Surface,true);
   end;
 end;

procedure TScroll.updatevarita;
 begin
  if hvarita then
   begin
    if GetTickCount - waitvarita >= 200 then
     begin
      waitvarita := GetTickCount;
      if avarita > 8 then avarita := 4 else inc(avarita);
     end;
    scr.Surface.draw(270,394,amb[avarita].Surface,false);
   end;
 end;

procedure TScroll.updatecrece;
 begin
  if crece then
   begin
    if GetTickCount - ccrece >= 200 then
     begin
      if (cpri < cult) then inc(cpri)
      else
       begin
        crece := false;
        if cult = 85 then twalk := cre[twalk] else twalk := dis[twalk];
        bigsmall;
       end;
      ccrece := GetTickCount;
     end;
    if not (twalk in [3,6]) then virt.Surface.draw(cx-20,50,amb[cpri].Surface,true)
     else virt.Surface.draw(cx,50,amb[cpri].Surface,true);
   end;
 end;

procedure TScroll.bigsmall;
 var
  i : byte;
 begin
  if twalk > 3 then i := twalk-3 else i := twalk;
  cx := tx[i];
  cy := ty[i];
  calwalk;
 end;

procedure TScroll.calwalk;
 begin
  rwalk := ((twalk-1)*7);
  awalk := rwalk;
 end;

function TScroll.ActualLives : boolean;
 begin
  dec(lives);
  efectos[12].Play;
  if lives = 0 then
   begin
    fMouse.SetMouseEvent(nil,nil,nil);
    DormirImg := 74;
    tickWait := GetTickCount; DormirCiclo := 0;
    StopAllEffects;
    Sound.StopModule;
    sndlib.LoadModFromLibrary(22,tmp);
    Sound.PlayModule(tmp);
    Application.OnIdle := DormirIdle;
   end;
  result := lives = 0;
 end;

procedure TScroll.StopAllEffects;
 var
  i : byte;
 begin
  for i := 1 to 6 do peligros[i].effpel := false;
  for i := 1 to 17 do efectos[i].Stop;
 end;

procedure TScroll.updatepeligros;
 var
  i : byte;
 begin
 if virar then exit;
 for i := 1 to 6 do
  with peligros[i] do
  if not dangdestroy then
   begin
    if Collision then
     begin
      dangtip := i;
      if hvarita then
       begin
        effpel := false;
        efectos[3+dtip].Stop;
        efectos[10].Play;
        updateDestruction;
        amb[0].Surface.FillRect(rect(270,394,386,431),0);
        hvarita := false;
        break;
       end   // end if hvarita
      else
       begin
        if ActualLives then break
        else
         begin
          saltoHadas := false;
          salto := false;
          virar := true;
          cvirar := 0;
          cvirartick := GetTickCount;
         end;
       end; // end else if hvarita
     end // end if collision
    else
     begin
      if not hada and not hvarita and dan_zana[posarr].act then
       begin
        if distcp <= 80 then
         begin
          inc(cdist);
          if cdist >= 100 then
           begin
            efectos[3].Play;
            hada := true;
            htip := random(3)+1;
            hcorx := chcorx[htip];
            hcory := chcory[htip];
            break;
           end;
         end else cdist := 0;
        if distcp < 131 then if not effpel then
         begin
          effpel := true;
          efectos[3+dtip].PlayLoop;
         end else
        else
         if effpel then
          begin
           effpel := false;
           efectos[3+dtip].Stop;
          end;
       end
     end; // end else if collosion
   end; // end if dandestroy
 end;

procedure TScroll.DormirIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderDormir then
   begin
    DoneVars;
    InitVars;
    fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
    Sound.StopModule;
    sndlib.FreeModule(tmp);
    Sound.PlayModule(modamb);
    Application.OnIdle := AppOnIdle;
   end;
 end;

function TScroll.RenderDormir : boolean;
 var
  i : byte;
 begin
  scr.surface.Draw(0,0,amb[0].Surface,false);
  virt.Surface.Draw(-sCielo,0,amb[1].Surface,false);
  virt.Surface.Draw(-sScene,0,amb[2].Surface,true);

  for i := 1 to 6 do peligros[i].anima;
  for i := 1 to 8 do zanahorias[i].anima;
  for i := 1 to 9 do manzanas[i].anima;
  for i := 1 to 11 do ambiente[i].Anima;
  piedra.DrawInside(PiedraEnabled and hvarita);
  if GetTickCount - tickWait >=400 then
   begin
    tickWait := GetTickCount;
    if DormirImg = 77 then
     begin
      DormirImg := 74;
      inc(DormirCiclo);
     end else inc(DormirImg);
   end;
  for i := 1 to 4 do pdelante[i].anima;

  virt.Surface.Draw(-sPlano,0,amb[3].Surface,true);
  piedra.DrawOutSide(PiedraEnabled and hvarita);
  scr.surface.Draw(24,104,virt,false);
  updateLivesZana2;
  scr.surface.Draw(8,328,amb[DormirImg].surface,false);
  fMouse.AnimaMouse;
  scr.Flip;
  result := DormirCiclo = 5;
 end;


procedure TScroll.keyleft;
 var
  i : byte;
 begin
  if twalk in [1..3] then
   begin
    inc(twalk,3);
    calwalk;
   end
  else
   begin
    if not salto then if awalk < rwalk+6 then inc(awalk) else awalk := rwalk;
   end;
  if (sScene = 4738) then
   ActivaCueva;
  if (sPlano > 0) then
   begin
    dec(sPlano,4);
    for i := 1 to 11 do inc(ambiente[i].CorX,2);
    for i := 1 to 4 do inc(pdelante[i].corx,2);
    for i := 1 to 6 do inc(peligros[i].corx,2);
    for i := 1 to 8 do inc(zanahorias[i].corx,2);
    for i := 1 to 9 do inc(manzanas[i].corx,2);
    inc(piedra.X,2);
   end
   else if sScene > 0 then
    begin
     sPlano := 1774*2;
     for i := 1 to 11 do inc(ambiente[i].corx,2);
     for i := 1 to 4 do inc(pdelante[i].corx,2);
     for i := 1 to 6 do inc(peligros[i].corx,2);
     for i := 1 to 8 do inc(zanahorias[i].corx,2);
     for i := 1 to 9 do inc(manzanas[i].corx,2);
     inc(piedra.X,2);
    end;
  if sScene > 0 then
   begin
    dec(sScene,2);
    if (sScene mod 4 = 0) then
     begin
      if sCielo > 0 then dec(sCielo)
       else if sScene > 0 then sCielo := 1182*2;
     end;
   end;
 end;

procedure TScroll.keyright;
 var
  i : byte;
 begin
  if twalk in [4..6] then
   begin
    dec(twalk,3);
    calwalk;
   end
  else
   begin
    if not salto then if awalk < rwalk+6 then inc(awalk) else awalk := rwalk;
   end;
  if (sScene = 4116) then ActivaCueva;
  if sScene > 8880-592-1 then exit;
  inc(sPlano,4);
  for i := 1 to 11 do dec(ambiente[i].corx,2);
  for i := 1 to 4 do dec(pdelante[i].corx,2);
  for i := 1 to 6 do dec(peligros[i].corx,2);
  for i := 1 to 8 do dec(zanahorias[i].corx,2);
  for i := 1 to 9 do dec(manzanas[i].corx,2);
  dec(piedra.X,2);
  if sPlano = 1776*2 then
   begin
    sPlano := 0;
   end;
  inc(sScene,2);
  if sScene mod 4 = 0 then
   begin
    inc(sCielo);
    if sCielo = 1184*2 then
     begin
      sCielo := 0;
     end;
   end;
 end;

procedure TScroll.AppOnIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  RenderScroll;
 end;

procedure TScroll.keyleftDec;
 var
  i : byte;
 begin
  if (sPlano > 0) then
   begin
    dec(sPlano,4);
    for i := 1 to 11 do inc(ambiente[i].CorX,2);
    for i := 1 to 4 do inc(pdelante[i].corx,2);
    for i := 1 to 6 do inc(peligros[i].corx,2);
    for i := 1 to 8 do inc(zanahorias[i].corx,2);
    for i := 1 to 9 do inc(manzanas[i].corx,2);
    inc(piedra.X,2);
   end
   else if sScene > 0 then
    begin
     sPlano := 1774*2;
     for i := 1 to 11 do inc(ambiente[i].corx,2);
     for i := 1 to 4 do inc(pdelante[i].corx,2);
     for i := 1 to 6 do inc(peligros[i].corx,2);
     for i := 1 to 8 do inc(zanahorias[i].corx,2);
     for i := 1 to 9 do inc(manzanas[i].corx,2);
    inc(piedra.X,2);
    end;
  if sScene > 0 then
   begin
    dec(sScene,2);
    if (sScene mod 4 = 0) then
     begin
      if sCielo > 0 then dec(sCielo)
       else if sScene > 0 then sCielo := 1182*2;
     end;
   end;
 end;

procedure TScroll.keyrightDec;
 var
  i : byte;
 begin
  inc(sPlano,4);
  for i := 1 to 11 do dec(ambiente[i].corx,2);
  for i := 1 to 4 do dec(pdelante[i].corx,2);
  for i := 1 to 6 do dec(peligros[i].corx,2);
  for i := 1 to 8 do dec(zanahorias[i].corx,2);
  for i := 1 to 9 do dec(manzanas[i].corx,2);
  dec(piedra.X,2);
  if sPlano = 1776*2 then
   begin
    sPlano := 0;
   end;
  inc(sScene,2);
  if sScene mod 4 = 0 then
   begin
    inc(sCielo);
    if sCielo = 1184*2 then
     begin
      sCielo := 0;
     end;
   end;
 end;

procedure TScroll.GameOnIdle(Sender: TObject; var Done: Boolean);
 var
  i : byte;
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  i := RenderGames;
  if i <> 0 then
   begin
    CoDestroyGame;
    key.ClearStates;
    FinishGame(i);
    fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
    fMouse.RestoreAllEvents;
    Sound.PlayModule(modamb);
    Application.OnIdle := AppOnIdle;
    tickWait := GetTickCount;
    fSonido := Sound.Music or Sound.Effect;
   end;
 end;

procedure TScroll.updateLivesZana;
 var
  i : byte;
 begin
  i := 0;
  while i < czana do
   begin
    scr.surface.draw(136+(i)*36,340,amb[95].surface,false);
    inc(i);
   end;
  scr.surface.draw(8,328,amb[83-lives].surface,false)
 end;

procedure TScroll.updateLivesZana2;
 var
  i : byte;
 begin
  i := 0;
  while i < czana do
   begin
    scr.surface.draw(136+(i)*36,340,amb[95].surface,false);
    inc(i);
   end;
 end;

procedure TScroll.updateLivesZana3;
 var
  i : byte;
 begin
  i := 0;
  while i < czana do
   begin
    scr.surface.draw(136+(i)*36,340,amb[95].surface,false);
    inc(i);
   end;
  if lives <> 0 then scr.surface.draw(8,328,amb[83-lives].surface,false)
   else scr.surface.draw(8,328,amb[82].surface,false)
 end;

procedure TScroll.FinishGame(Value : byte);
 var
  tmp : byte;
 begin
  Hada := False; hvarita := false;
  HadaEscape := False;
  saltoHadas := false;
  salto := false;
  with zanahorias[zanaSel] do
  if Value = 1 then
   begin
    dan_zana[posarr].act := false;
    posarr := 0;
    if czana < 10 then inc(czana);
   end
  else
   begin
    tmp := posarr;
    consul_init;
    dan_zana[tmp].act := false;
   end;
 end;

procedure TScroll.DoneVarsGame;
 begin
  StopAllEffects;
  left := false;
  right := false;
  hada := false; hadaEscape := false;
  crece := false;
  hvarita := false;
  SaltoHadas := false; salto := false;
  PiedraEnabled := false;
  HadaPiedra := false;
 end;

procedure TScroll.updateJuegos;
 var
  i : byte;
 begin
  for i := 1 to 8 do
   with zanahorias[i] do
    begin
     if dan_zana[posarr].act then
      if Collision then
       if (tip=ztwalk[twalk]) then
       begin
        ZanaSel := i;
        if GamesReady.Count = 0 then
         begin
          FinishGame(1);
         end
        else
         begin
          if LoadDLL(PGame(GamesReady.Items[Random(GamesReady.Count)])^.Number) then
           begin
            fMouse.StopAllEvents;
            CoCreateGame := LoadDLLProc('CoCreateGame');
            CoDestroyGame := LoadDLLProc('CoDestroyGame');
            RenderGames := CoCreateGame(scr,key,Sound,fMouse);
            Application.OnIdle := GameOnIdle;
            DoneVarsGame;
           end; {OJO que pasa cuando no se puede cargar la dll}
         end;
        break;
       end;
    end; // animaciones de las zanahorias
 end;

procedure TScroll.updateManzanas;
 var
  i : byte;
 begin
  for i := 1 to 9 do
   if manzanas[i].Collision then
    if ActualLives then break else manzanas[i].upapple;
 end;

function TScroll.RenderPiedraLoad : boolean;
 begin
  libCueva.CreateSurfaceIndex(imgIndexCueva,imgCueva[imgIndexCueva]);
  imgCueva[imgIndexCueva].TransparentColor := fMouse.cTransparent;
  inc(imgIndexCueva);
  result := imgIndexCueva = libCueva.ImageCount;
 end;

function TScroll.RenderPiedra : byte;
 var
  i : integer;
 begin
  result := 0;
  scr.surface.Draw(0,0,amb[0].Surface,false);
  virt.Surface.Draw(-sCielo,0,amb[1].Surface,false);
  virt.Surface.Draw(-sScene,0,amb[2].Surface,true);

  for i := 1 to 6 do peligros[i].anima;
  for i := 1 to 8 do zanahorias[i].anima;
  for i := 1 to 9 do manzanas[i].anima;
  for i := 1 to 11 do ambiente[i].Anima;
  piedra.DrawInside(PiedraEnabled and hvarita);
  for i := 1 to 4 do pdelante[i].anima;

  case optionsCueva of
   PiedraLoad : begin
    if RenderPiedraLoad then
     begin
      efectos[11].Play;
      optionsCueva := PiedraAnima;
      tickWait := GetTickCount;
      imgIndexCueva := b_e_piedra[1][twalk];
     end;
   end;
   PiedraAnima : begin
    if GetTickCount - tickWait >= 400 then
     begin
      tickWait := GetTickCount;
      if imgIndexCueva = b_e_piedra[2][twalk] then
       begin
        result := 1;
        if not ActualLives then
         begin
          while sScene <> 2842 do keyleft;
          keyright;
          calwalk;
         end else result := 2;
       end else inc(imgIndexCueva);
     end;
    virt.surface.draw(cx-resto[twalk],120+incr[twalk],imgCueva[imgIndexCueva].surface,true);
   end;
  end;
  virt.Surface.Draw(-sPlano,0,amb[3].Surface,true);
  piedra.DrawOutSide(PiedraEnabled and hvarita);
  scr.surface.Draw(24,104,virt,false);
  updateLivesZana3;
  fMouse.AnimaMouse;
  scr.Flip;
 end;

procedure TScroll.PiedraIdle(Sender: TObject; var Done: Boolean);
 var
  i : integer;
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  i := RenderPiedra;
  if i <> 0 then
   begin
    if i = 1 then Application.OnIdle := AppOnIdle;
    for i := 0 to libCueva.ImageCount-1 do imgCueva[i].Free;
    libCueva.Free;
   end;
 end;

procedure TScroll.updatePiedra;
 begin
  if HadaPiedra then
   if (sScene < 2780) or (sScene > 3106) then
    begin
     hada := false;
     HadaPiedra := false;
     HadaEscape := true;
    end;
  if PiedraEnabled then
   begin
    if (sScene < 2780) or (sScene > 3106) then
     begin
      PiedraEnabled := false;
      HadaPiedra := false;
      hvarita := false;
     end
    else
     begin
       if piedra.Splash(sScene,twalk) and not salto then
        begin
         libCueva := TILib.Create(scr,'Lib\Splash.lib');
         imgIndexCueva := 0;
         optionsCueva := PiedraLoad;
         Application.OnIdle := PiedraIdle;
        end;
      if not RioD then
       if sScene > 2994 then
        begin
         inc(czana);
         RioD := true;
        end;
     end;
   end
  else
   begin
    if piedra.Splash2(sScene,twalk) and not salto then
     begin
      libCueva := TILib.Create(scr,'Lib\Splash.lib');
      imgIndexCueva := 0;
      optionsCueva := PiedraLoad;
      Application.OnIdle := PiedraIdle;
     end;
   end
 end;

procedure TScroll.RenderScroll;
 var
  i : byte;
 begin
  key.Update;
  updateKeyBoard;

  if key.States = [] then
   if not (salto or Saltohadas or Crece or virar or PiedraEnabled) then
   begin
    calwalk;
    if (GetTickCount - tickWait >= 6180) then
     begin
      optionsWait := WaitInit;
      Application.OnIdle := WaitIdle;
     end;
   end else else tickWait := GetTickCount;

  scr.surface.Draw(0,0,amb[0].Surface,false);
  virt.Surface.Draw(-sCielo,0,amb[1].Surface,false);
  virt.Surface.Draw(-sScene,0,amb[2].Surface,true);

  for i := 1 to 6 do peligros[i].anima;
  for i := 1 to 8 do zanahorias[i].anima;
  for i := 1 to 9 do manzanas[i].anima;
  for i := 1 to 11 do ambiente[i].Anima;

  piedra.DrawInside(PiedraEnabled and hvarita);

  // animacion de la varita majica
  updatevarita;
  if virar then
   begin
    if cvirar = 40 then
     begin
      tickWait := GetTickCount;
      virar := false;
     end
    else
     if GetTickCount - cvirartick >= 80 then
      begin
       cvirartick := GetTickCount;
       inc(cvirar);
       keyleft;
      end;
   end;

  if not (salto or crece) then virt.Surface.Draw(cx,cy,walk[awalk].Surface,true);
  updatesalto;
  updateSaltoHadas;

  // animacion crecer disminuir
  updatecrece;
  for i := 1 to 4 do pdelante[i].anima;
  // actualiza la animacion de las hadas
  updatehadas;

  virt.Surface.Draw(-sPlano,0,amb[3].Surface,true);
  piedra.DrawOutSide(PiedraEnabled and hvarita);
  scr.surface.Draw(24,104,virt,false);
  updateLivesZana;

  if fSalir then scr.Surface.Draw(561,0,amb[104].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,amb[103].surface,true);
  fMouse.AnimaMouse;
  updatePiedra;
{$ifdef canvas}
  with scr.Surface.Canvas do
   begin
    TextOut(0,0,format('MouseX = %d MouseY=%d',[fMouse.MouseX,fMouse.MouseY]));
    release;
   end;
{$endif}
  scr.Flip;
  Finish;
  updatePeligros;
  updateJuegos;
  updateManzanas;
 end;

function TScroll.RenderEndLoad : boolean;
 begin
  libCueva.CreateSurfaceIndex(imgIndexCueva,imgCueva[imgIndexCueva]);
  imgCueva[imgIndexCueva].TransparentColor := fMouse.cTransparent;
  inc(imgIndexCueva);
  result := imgIndexCueva = 13;
 end;

procedure TScroll.EndPart1;
 begin
  scr.surface.Draw(0,0,amb[0].Surface,false);
  virt.Surface.Draw(-sCielo,0,amb[1].Surface,false);
  virt.Surface.Draw(-sScene,0,amb[2].Surface,true);
 end;

procedure TScroll.EndPart2;
 begin
  virt.Surface.Draw(-sPlano,0,amb[3].Surface,true);
  scr.surface.Draw(24,104,virt,false);
  updateLivesZana;
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TScroll.RenderEnd : byte;
 begin
  key.Update;
  result := 0;
  case optionsCueva of
   EndLoad : begin
    EndPart1;
    virt.Surface.Draw(cx,cy,walk[awalk].Surface,true);
    if RenderEndLoad then
     begin
      sndlib.LoadModFromLibrary(23,tmp);
      Sound.PlayModule(tmp);
      awalk := 0;
      tickWait := GetTickCount;
      optionsCueva := EndAnima;
      key.ClearStates;
     end;
    EndPart2;
   end;
   EndAnima : begin
    EndPart1;
    if GetTickCount - tickWait >= 150 then
     begin
      tickWait := GetTickCount;
      if awalk < 11 then inc(awalk) else optionsCueva := EndRun;
     end;
    virt.Surface.Draw(204,64,imgCueva[awalk].Surface,true);
    EndPart2;
   end;
   EndRun : begin
    scr.Surface.Draw(0,0,imgCueva[12].surface,false);
    fMouse.AnimaMouse;
    scr.Flip;
    if (key.Keyboard.States <> []) or (isButton1 in key.Mouse.States) then result := 1;
   end;
  end;
 end;

procedure TScroll.EndIdle(Sender: TObject; var Done: Boolean);
 var
  i : byte;
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  i := RenderEnd;
  if i <> 0 then
   begin
    for i := 0 to libCueva.ImageCount-1 do imgCueva[i].Free;
    libCueva.Free;
    key.ClearStates;
    Sound.StopModule;
    sndlib.FreeModule(tmp);
    Sound.PlayModule(modamb);
    fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
    DoneVars;
    InitVars;
    Application.OnIdle := AppOnIdle;
    tickWait := GetTickCount;
   end;
 end;

procedure TScroll.Finish;
 begin
  if sScene = 8288 then
   if czana = 10 then
    begin
     libCueva := TILib.Create(scr,'Lib\Final.lib');
     imgIndexCueva := 0;
     optionsCueva := EndLoad;
     fMouse.SetMouseEvent(nil,nil,nil);
     calwalk;
     Application.OnIdle := EndIdle;
    end;
 end;

function TScroll.RenderAyuda : boolean;
 begin
  result := false;
  key.Update;
  scr.surface.Draw(0,0,amb[0].Surface,false);
  updatevarita;
  updateLivesZana;
  if fSalir then scr.Surface.Draw(561,0,amb[104].surface,true);
  if not fSonido then scr.Surface.Draw(518,0,amb[103].surface,true);
  scr.Surface.Draw(24,104,Ayuda.Imagen.Surface,false);
  fMouse.AnimaMouse;
  scr.Flip;
  if (key.Keyboard.States <> [isF1]) and (key.Keyboard.States <> []) then
   begin
    key.ClearStates;
    result := true;
   end;
 end;

procedure TScroll.AyudaIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderAyuda then
   begin
    Sound.PlayModule(modamb);
    sndlib.FreeModule(HelpMusic);
    Ayuda.Free;
    Ayuda := nil;
    tickWait := GetTickCount;
    Application.OnIdle := AppOnIdle;
   end;
 end;

procedure TScroll.AboutIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderAbout <> 0 then
   begin
    CoDestroyAbout;
    Sound.PlayModule(modamb);
    tickWait := GetTickCount;
    fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
    fMouse.RestoreAllEvents;
    Application.OnIdle := AppOnIdle;
   end;
 end;

end.
