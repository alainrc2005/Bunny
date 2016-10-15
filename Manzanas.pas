unit Manzanas;

interface

Uses Windows, DXDraws;

type
  TManzanas = class
   private
    cory  : integer;
    scory : integer;
    decvel: dword;
    virt  : TAutomaticSurface;
    visible : boolean;
   public
    corx  : integer;
    constructor Create(Index : byte; Surface : TAutomaticSurface);
    destructor Destroy; Override;
    procedure Anima;
    procedure upapple;
    function Collision : boolean;
  end;

implementation

Uses Vars;

const
 cxmanza : array[1..9] of word =
  (7754,7800,7878,7922,7988,8052,8066,8134,8192);
 cymanza : array[1..9] of integer = (38,26,40,8,20,30,24,22,6);


constructor TManzanas.Create(Index : byte; Surface : TAutomaticSurface);
 begin
  visible := true;
  virt := Surface;
  corx := cxmanza[index];
  cory := cymanza[index];
  scory := cory;
  decvel := GetTickCount;
 end;

destructor TManzanas.destroy;
 begin
  inherited Destroy;
 end;

procedure TManzanas.anima;
 begin
  if GetTickCount - decvel >= 45 then
   begin
    decvel := GetTickCount;
    if cory >= 210 then cory := scory else inc(cory);
   end;
  if visible then virt.surface.draw(corx,cory,amb[70].surface,true);
 end;

procedure TManzanas.upapple;
 begin
  cory := scory;
  decvel := GetTickCount;
 end;

function TManzanas.Collision : boolean;
 begin
  result := false;
  if not visible then exit;
  result := SurfaceCollision(corx,cory,cx,cy,amb[70].Surface,walk[awalk].Surface,true);
  visible := not result;
 end;

end.
