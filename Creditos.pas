unit Creditos;

interface

uses DXDraws, DXInput, Mouse, Module, ModTypes;

type
 TFarProcObj = function : byte of object;

function IDGame : Integer; stdcall;
function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
procedure CoDestroyGame; stdcall;

implementation

Uses Windows, Classes, Controls, Graphics, VarsComun;

type

 TCreditos = class
 private
  lib : TILib;
  images   : array[0..27] of TAutomaticSurfaceLib;

  scr : TDXDraw;
  key : TDXInput;
  fMouse : Mouse.TMouse;
  fSound : TSoundSystem;
  sndlib : TSoundLibrary;
  musica : TMod;
  
  options : word;
  imgIndex : dword;

  corY : Integer;
  tick : dword;
  Clipper : HRGN;
  CartelIndex : Shortint;
  imgCartel : integer;

  eff : TList;
  fula : set of byte;
  tickEff : dword;
  imgEff : integer;

 protected
  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  function RenderLoad : boolean;
  procedure UpdateGame(Value : boolean);

  function GetToken(aString : String;TokenNum: Byte): String;
  procedure DrawText;

  procedure CreateObject;
  procedure PaintObject;
  procedure FreeObject;

 public
  constructor Create(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse);
  destructor Destroy; Override;
  function RenderGame : byte;
 end;

 TObj = class
  private
   fx,fy,fdx,fdy : integer;
   fdex,fdey : shortint;
   fsdey : integer;
   fSource : TRect;
   Blend : smallint;
  public
   constructor Create(Value : byte);
   destructor Destroy; override;
   function Update : boolean;
   property Source : TRect read fSource;
   property X : integer read fx;
   property Y : integer read fy;
 end;
 PObj = ^TObj;


const
 // Game Options

 LoadCreditos  = 1;
 RenderCreditos= 2;
 RenderQuit    = 3;

 CartelCount = 49;
 Cartel : array[1..CartelCount] of string =
 ('1,-1,EQUIPO CEJISOFT',
  '',
  '1,-1,Programación',
  '2,3,Juan Antonio Delgado Rivero',
  '2,4,Alain Ramírez Cabrejas',
  '2,5,Camilo Ernesto Blanco Peña',
  '2,6,Javier Gutierrez Rodríguez',
  '2,7,Daris Sao Osorio',
  '2,8,Yoanys Vaillant Fajardo',
  '2,9,Juan Carlos Pérez Nieves',
  '2,23,Amaury Fernández Reyna',
  '',
  '1,-1,Diseño Gráfico y Animaciones',
  '2,10,Miguel Pérez Quintana',
  '2,11,Alexey Caraballo Quevedo',
  '2,12,Yoel López Soriano',
  '2,13,Rodolfo Caraballo Quevedo',
  '',
  '1,-1,Soporte WEB y redes',
  '2,14,Tomás Ramírez Andújar',
  '2,15,Yusimy Castellanos López',
  '2,4,Alain Ramírez Cabrejas',
  '',
  '1,-1,Documentación Pedagógica',
  '2,16,Gabriel Garcia Vega',
  '2,17,Elvia Hernández Noval',
  '2,18,Orelbis Corrales Barrios',
  '2,19,Yoandris Oro Aldaya',
  '',
  '1,-1,Equipo Pedagógico',
  '2,20,Pedro López Bello',
  '2,21,Efraín Rodríguez Seijo',
  '',
  '1,-1,Dirección General',
  '2,22,Luis Gaspar Ulloa Reyes',
  '',
  '1,-1,Dirección de Producción',
  '2,3,Juan Antonio Delgado Rivero',
  '',
  '1,-1,Programador Principal',
  '2,4,Alain Ramírez Cabrejas',
  '',
  '1,-1,Agradecimientos Especiales',
  '2,26,A mi esposa Norelys por su calmada espera...',
  '2,24,A Microsoft Corporation por DirectX y Windows',
  '2,25,A Inprise Corporation por su grandioso Delphi',
  '',
  '1,-1,Dedicado a mi hija',
  '2,27,Claudia Ramírez Nápoles');


var
 About : TCreditos;

constructor TCreditos.Create;
 begin
  Randomize;
  scr := Screen; key := KeyBoard;
  fMouse := Mouse; fSound := Sound;
  lib := TILib.Create(scr,'Lib\Creditos.lib');
  try
   sndlib := TSoundLibrary.Create('Lib\Creditos.snd',fSound);
  except
  end; 
  options := LoadCreditos;
  imgIndex := 0;
  CorY := 439;
  tick := GetTickCount;
  Clipper := CreateRectRgn(224,39,640,439);
  CartelIndex := -1;
  imgCartel := -1;
  eff := TList.Create;
 end;

destructor TCreditos.Destroy;
 var
  i : integer;
 begin
  for i := 0 to lib.ImageCount-1 do images[i].Free;
  lib.Free;
  fSound.StopModule;
  sndlib.FreeModule(musica);
  sndlib.Free;
  DeleteObject(Clipper);
  FreeObject;
  eff.Free;
  key.ClearStates;
  repeat
   key.Update;
  until key.Keyboard.States = [];
  inherited Destroy;
 end;

procedure TCreditos.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 options := RenderQuit;
end;

function TCreditos.GetToken(aString : String;TokenNum: Byte): String;
 var
   Token     : String;
   StrLen    : Byte;
   TNum      : Byte;
   TEnd      : Byte;

begin
 StrLen := Length(aString);
 TNum   := 1;
 TEnd   := StrLen;
 while ((TNum <= TokenNum) and (TEnd <> 0)) do
  begin
   TEnd := Pos(',',aString);
   if TEnd <> 0 then
   begin
    Token := Copy(aString,1,TEnd-1);
    Delete(aString,1,TEnd);
    Inc(TNum);
   end
  else Token := aString;
 end;
 if TNum >= TokenNum then result := Token else result := '';
end;

function StrToInt(const S: string): Integer;
var
  E: Integer;
begin
  Val(S, Result, E);
end;

procedure TCreditos.DrawText;
 var
  i : Shortint;
  x : integer;
 begin
  if GetTickCount - tick >= 100 then
   begin
    tick := GetTickCount;
    dec(CorY);
    if CorY < -1480 then options := RenderQuit;
   end;
  with scr.Surface.Canvas do
   begin
    SelectClipRgn(Handle,Clipper);
    Font.Name := 'Marigold';
    Font.Size := 25;
    Brush.Style := bsClear;
    for i := 1 to CartelCount do
     begin
      if Cartel[i] = '' then continue;
      case StrToInt(GetToken(Cartel[i],1)) of
       1 : begin
        Font.Color := RGB(232,224,140);
        Font.Style := [fsUnderline];
       end;
       2 : begin
        if i = CartelIndex then Font.Color := RGB(255,0,0) else Font.Color := RGB(24,222,240);
        Font.Style := [];
       end;
      end;
      x := ((640-224)-TextWidth(GetToken(Cartel[i],3))) div 2;
      TextOut(224+x,CorY+Pred(i)*30,GetToken(Cartel[i],3));
     end;
    SelectClipRgn(Handle,0);
    Release;
   end;
 end;

procedure TCreditos.UpdateGame(Value : boolean);
 var
  Actual : Shortint;
 begin
  if (fMouse.MouseY >= 39) and (fMouse.MouseY <= 439) then
  if fMouse.MouseY > CorY then
   begin
    Actual := ((fMouse.MouseY-CorY)div 30) + byte((fMouse.MouseY-CorY) mod 30<>0);
    if Actual <> CartelIndex then
     begin
      if imgCartel <> -1 then
       begin
        if eff.count = 0 then CreateObject else
         begin
          FreeObject;
          CreateObject;
         end;
        imgEff := imgCartel;
       end;
     end;
    CartelIndex := Actual;
    if CartelIndex > CartelCount then imgCartel := -1 else
    if Cartel[CartelIndex] <> '' then imgCartel := StrToInt(GetToken(Cartel[CartelIndex],2)) else imgCartel := -1
   end else imgCartel := -1 else imgCartel := -1;

  scr.surface.Draw(0,0,images[0].Surface,false);
  DrawText;
  scr.surface.Draw(300,40,images[1].Surface,true);
  if imgCartel = -1 then scr.surface.Draw(79,79,images[2].Surface,false) else
   scr.Surface.Draw(59,143,images[imgCartel].Surface,false);
  PaintObject;
 end;

function TCreditos.RenderGame : byte;
 begin
  result := 0;
  key.Update;
  case options of
   LoadCreditos : begin
    if RenderLoad then
     begin
      options := RenderCreditos;
      fMouse.SetMouseEvent(nil,MouseDown,nil);
      fMouse.RestoreAllEvents;
      if random(50) > 25 then sndlib.LoadModFromLibrary(1,musica) else sndlib.LoadModFromLibrary(0,musica);
      fSound.PlayModule(musica);
     end;
   end; // end of loadgame
   RenderCreditos : begin
    if key.Keyboard.States <> [] then options := RenderQuit;
    UpdateGame(True);
   end;
   RenderQuit : result := 1;
  end; // end of case
  fMouse.AnimaMouse;
  scr.Flip;
 end;

function TCreditos.RenderLoad : boolean;
 begin
  lib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.cTransparent;
  inc(imgIndex);
  result := imgIndex = lib.ImageCount;
  fMouse.ProgressImage(nil,imgIndex,lib.imagecount);
 end;

procedure TCreditos.CreateObject;
 var
  i,j : byte;
  aux : boolean;
  tmp : PObj;
 begin
  fula := [];
  eff.Clear;
  for i := 1 to 9*12 do
   begin
    aux := true;
    while aux do
     begin
      j := random(9*12);
      aux := j in fula;
     end;
    fula := fula + [j];
    getmem(tmp,sizeof(TObj));
    tmp^ := TObj.Create(j);
    eff.Add(tmp)
   end;
 end;

procedure TCreditos.FreeObject;
 var
  i : integer;
 begin
  if eff.Count = 0 then exit;
  for i := 0 to eff.Count-1 do
   PObj(eff.Items[i])^.Free;
 end;

procedure TCreditos.PaintObject;
 var
  i,j : byte;
 begin
  if eff.Count = 0 then exit;
  for i := 0 to eff.Count-1 do
   with PObj(eff.Items[i])^ do scr.Surface.DrawAlpha(Rect(X,Y,X+14,Y+14),Source,images[imgEff].surface,false,Blend);
  if GetTickCount - tickEff < 50 then exit;
  tickEff := GetTickCount; j := 0;
  for i := 0 to eff.Count-1 do
   with PObj(eff.Items[i])^ do if Update then inc(j);
  if j = eff.Count then
   begin
    FreeObject;
    eff.Clear;
   end;
 end;

////////// TOBJ //////////////////

constructor TObj.Create(Value : byte);
 begin
  fx := (Value mod 9)*14;
  fy := (Value div 9)*14;
  fdx := fx+14;
  fdy := fy+14;
  fdex := -10+random(20);
  fdey := -random(20);
  fsdey := fdey;
  fSource := Rect(fx,fy,fdx,fdy);
  inc(fx,59);
  inc(fy,143);
  inc(fdx,59);
  inc(fdy,143);
  Blend := 255;
 end;

destructor TObj.Destroy;
 begin
  inherited Destroy;
 end;

function TObj.Update;
 begin
  result := true;
  if Blend < 0 then exit;
  dec(Blend,5);
  result := Blend < 0;
  inc(fx,fdex);
  inc(fy,fdey);
  inc(fdx,fdex);
  inc(fdy,fdey);
  inc(fdey);
 end;

/////// DLL FUNCTIONS //////////////////////////

function IDGame : Integer; stdcall;
 begin
  Result := 100;
 end;

function CoCreateGame(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 begin
  result := nil;
  About := TCreditos.Create(Screen,KeyBoard,Sound,Mouse);
  result := About.RenderGame;
 end;

procedure CoDestroyGame; stdcall;
 begin
  About.Free;
 end;




end.
