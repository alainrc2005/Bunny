unit Cueva;

interface

Uses Windows, DXDraws, Vars;

Type
 TAranas = class
  private
   cxa : word;
   cya : word;
   tip : byte;
   top : word;
   dir : shortint;
   esp : dword;
   sesp: dword;
   virt : TAutomaticSurface;
   fColor : dword;
  public
   constructor Create(Index : byte; Surface : TAutomaticSurface; aColor : dword);
   destructor Destroy; Override;
   procedure Anima;
   function Collision : boolean;
  end;


implementation

Uses Graphics;

constructor TAranas.Create(Index : byte; Surface : TAutomaticSurface; aColor : dword);
 begin
  virt := surface;
  cxa := 108*Index;
  top := 60+random(100);
  cya := 20+random(40);
  tip := 2*(random(3)+1);
  if random(100) > 50 then dir := 1 else
   begin
    dir := -1;
    inc(tip);
   end;
  sesp := 10+random(20);
  esp := GetTickCount;
  fColor := aColor;
 end;

destructor TAranas.Destroy;
 begin
  inherited Destroy;
 end;

procedure TAranas.Anima;
 begin
  if GetTickCount - esp >= sesp then
   begin
    inc(cya,dir);
    if (cya = top) or (cya = 0) then
     begin
      inc(tip,dir);
      dir := -dir;
     end;
    esp := GetTickCount;
   end;
  virt.surface.draw(cxa,cya,imgCueva[tip].surface,true);

  try // para prevenir ctrl + del o ctrl + shift + escape
   with virt.Surface.Canvas do
    begin
     Pen.Color := fColor;
     Pen.Style := psSolid;
     MoveTo(cxa+16,0);
     if dir = 1 then LineTo(cxa+16,cya)
      else LineTo(cxa+16,cya+10);
     Release;
    end;
  except
  end;  
 end;

function TAranas.Collision : boolean;
 begin
  result := SurfaceCollision(cxa,cya,cxc,96,imgCueva[tip].Surface,walk[awalk].Surface,true);
 end;



end.
