unit Zanahorias;

interface

uses Windows, Classes, DXDraws, Vars;

type
 TZanahoria   = Class
  private
   decmov : dword;
   sig    : shortint;
   cont   : byte;
   virt : TAutomaticSurface;
  public
   posarr : byte;
   tip    : byte;
   corx   : integer;
   cory   : integer;
   constructor Create(Surface : TAutomaticSurface);
   destructor Destroy; Override;
   procedure actualcoors;
   procedure consul_init;
   procedure anima;
   function Collision : boolean;
  end;

const
 ztwalk : array[1..6] of byte = (1,2,3,1,2,3);

implementation

const
 // cooordenadas y de las zanahorias
 zanacory: array[1..3] of integer = (130,100,90);

 procedure Tzanahoria.consul_init;
  var
   j : byte;
  begin
   j := FindPosZanahoria;
   dan_zana[j].act := true;
   posarr := j;
   corx := dan_zana[j].pos*148 + 296;
   tip := random(3)+1;
   if random(11) > 5 then sig := -1 else sig := 1;
   cont := Random(5);
   if sig = -1 then cont := 5-cont;
   cory := zanacory[tip]+cont;
   decmov := GetTickCount;
   cont := 0;
   dec(corx,sScene);
  end;

 procedure Tzanahoria.actualcoors;
  begin
   corx := dan_zana[posarr].pos*148 + 296;
   cory := zanacory[tip];
  end;

 constructor Tzanahoria.Create(Surface : TAutomaticSurface);
  begin
   virt := surface;
   consul_init;
  end;

 destructor Tzanahoria.Destroy;
  begin
   inherited Destroy;
  end;

 procedure Tzanahoria.anima;
  begin
   if dan_zana[posarr].act then
    begin
     if GetTickCount - decmov >= 100 then
      begin
       decmov := GetTickCount;
       inc(cory,sig);
       inc(cont);
       if cont = 5 then
        begin
         sig := -sig;
         cont := 0;
        end;
      end;
     virt.Surface.draw(corx,cory,amb[91+tip].Surface,true);
    end;
  end;

function Tzanahoria.Collision : boolean;
 begin
  result := SurfaceCollision(corx,cory,cx,cy,amb[91+tip].Surface,walk[awalk].Surface,true);
 end;


end.
