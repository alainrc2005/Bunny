{$DEFINE FULL}
unit Vars;

interface

Uses Windows, Classes, DXDraws, DXInput, VarsComun, Mouse, Module;

Type
 TGame = record
  Number : integer;
  Play : boolean;
 end;
 PGame = ^TGame;

// posicion de los peligros y zanahorias
  Dang   = record
   pos : byte;
   act : boolean;
   pel : boolean;
  end;
  bdanger= array[1..6] of byte;

var
 scr : TDXDraw;
 key : TDXInput;
 fMouse : Mouse.TMouse;
 Sound : TSoundSystem;
 save : TSave;
 GamesReady : TList;

 GameReady : boolean = false;
 GameAvailable : boolean = false;
 GameInitialized : boolean = false;

 FullScreen : boolean = {$IFDEF FULL}True{$ELSE}False{$ENDIF};

 sPlano,sScene,sCielo  : integer;

 imgCueva : array[0..12] of TAutomaticSurfaceLib; // imagenes de la cueva 8 y de la caida en el rio 12 y del final del juego 13
 cxc : word; // coordenada x dentro de la cueva
 amb    : array[0..104] of TAutomaticSurfaceLib;  // imagenes del ambiente del juego
 walk   : array[0..77] of TAutomaticSurfaceLib; // Animacion del conejo caminando
 danger : array[0..72] of TAutomaticSurfaceLib;  // peligros del juego
 cx,cy   : word; {coordenadas de los conejos}
 aWalk   : word; // animacion caminar
 dan_zana : array[1..19] of Dang;

const
  PositionDangerZanahoria : array[1..19] of byte =
  (2,4,6,8,10,13,16,18,22,25,27,34,36,38,41,44,47,49,55);


// constante de animacion crecimiento y disminucion
 tx : array[1..3] of word = (296,296,280);
 ty : array[1..3] of word = (130,96,50);
 cre : array[1..6] of byte = (2,3,3,5,6,6);
 dis : array[1..6] of byte = (1,1,2,4,4,5);

// coordenadas de las hadas
 chcorx : array[1..3] of integer = (-60,-96,-148);
 chpcorx: array[1..3] of integer = (700,736,788);
 chcory : array[1..3] of integer = (100,60,0);
 hxtop  : array[1..3] of integer = (236,200,140);
 canis  : array[1..6] of word = (72,73,74,75,76,77);
 htwalk : array[1..3] of byte = (1,2,3);

 //Zonas del ambiente principal donde se usa el mouse
 zonecount = 3;
 zone : array[1..zonecount] of trect =
  ((left:504;top:338;right:560;bottom:424),
   (left:561;top:328;right:628;bottom:414),
   (left:24;top:104;right:616;bottom:290));

 b_e_piedra : array[1..2] of array[1..6] of byte = ((0,4,8,0,4,8),(3,7,11,3,7,11));

 // constante de espera, aburrimiento
 wbeginload : array[1..3] of byte = (5,13,22);
 wendload : array[1..3] of byte = (12,21,31);

function FindPos : byte;
function FindPosZanahoria : byte;
procedure UpdateDangerZanahoria;

implementation

function FindPos : byte;
 begin
  repeat
   result  := random(19)+1;
  until not dan_zana[result].act;
 end;

function FindPosZanahoria : byte;
 begin
  repeat
   result  := random(19)+1;
  until (not dan_zana[result].act) and (not dan_zana[result].pel);
 end;

procedure UpdateDangerZanahoria;
 var
  i : byte;
 begin
  ZeroMemory(@Dan_Zana,sizeof(Dan_Zana));
  for i := 1 to 19 do
  Dan_Zana[i].pos := PositionDangerZanahoria[i];
 end;
end.
