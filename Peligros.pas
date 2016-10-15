unit Peligros;

interface

uses Windows, Classes, DXDraws, Vars;

type
 TPeligros = class
  private
   decvel : dword; // decremento de velocidad
   velo   : word; // velocidad
   sbegin : byte; // salva del inicio de la animacion
   moving : boolean;
   virt : TAutomaticSurface;
   abegin : byte; // inicio de la animacion
   aend   : byte; // fin de la animacion
   dvel   : dword;    // velocidad del peligro
   dbegin,
   dend   : integer;    // inicio y fin del peligro
  public
   dtip   : byte; // que peligro es este
   corx   : integer;  // coordenada x del peligro
   cory   : integer;  // coordenada y del peligro
   dangdestroy : boolean; // peligro en destruccion
   posarr : byte;
   distcp : integer;
   cdist  : byte; // contador de distancia al peligro
   effpel : boolean;
   constructor Create(Surface : TAutomaticSurface);
   destructor Destroy; Override;
   procedure actualcoors;
   procedure Anima;
   function Collision : boolean;
   procedure updateDestruction;
  end;

implementation

const
 adanger : array[1..6] of bdanger =
  ((0,5,6,12,0,0), // fuego
   (13,15,16,21,22,23), // buho
   (24,28,29,34,35,35), // maja
   (36,39,40,44,0,0), // ciclon
   (45,50,51,55,56,57), // cienpies
   (58,62,63,71,72,72)); // lobo

 danvel : array[1..6] of integer = (218,212,208,204,206,206);
 dancory: array[1..6] of integer = (36,60,80,60,70,50);
 dandec : array[1..6] of byte = (0,0,0,8,4,0);

constructor TPeligros.Create(Surface : TAutomaticSurface);
 var
  j : byte;
  begin
   virt := surface;

   dangdestroy := false;
   cdist := 0;
   j := FindPos;
   dan_zana[j].act := true;
   dan_zana[j].pel := true;
   posarr := j;
   corx := dan_zana[j].pos*148 + 296;
   j := random(6)+1; // elige tipo de peligro
   abegin := adanger[j][1];
   sbegin := abegin;
   aend   := adanger[j][2];
   cory := dancory[j];
   decvel := GetTickCount;
   velo := danvel[j];
   if j in [2,3,5..6] then moving := true else moving := false;
   dtip := j;
   effpel := false;
  end;

 procedure TPeligros.actualcoors;
  begin
   cory := dancory[dtip];
   corx := dan_zana[posarr].pos*148 + 296;
  end;

 destructor TPeligros.Destroy;
  begin
   inherited Destroy;
  end;

 procedure TPeligros.Anima;
  begin
   if dangdestroy then
    begin
     if (GetTickCount - dvel >= 200) then
      begin
       if (dbegin < dend) then inc(dbegin)
       else
        begin
         dangdestroy := false;
         dan_zana[posarr].act := false;
         abegin := adanger[dtip][5];
         sbegin := abegin;
         aend := adanger[dtip][6];
        end;
       dvel := GetTickCount;
      end;
     virt.Surface.draw(corx,cory-dandec[dtip],danger[dbegin].Surface,true);
     exit;
    end;

   if (dan_zana[posarr].act) then
    begin
     if GetTickCount - decvel >= velo then
      begin
       if abegin=aend then abegin := sbegin else inc(abegin);
       decvel := GetTickCount;
      end;
     virt.Surface.Draw(corx,cory,danger[abegin].Surface,true);
     distcp := corx-cx;
    end
   else
    if moving then
     begin
      if GetTickCount - decvel >= velo then
       begin
        if abegin=aend then abegin := sbegin else inc(abegin);
        decvel := GetTickCount;
       end;
      virt.Surface.Draw(corx,cory-dandec[dtip],danger[abegin].Surface,true);
     end;
  end;

function TPeligros.Collision : boolean;
 begin
  result := false;
  if (dan_zana[posarr].act) then
  result := SurfaceCollision(corx,cory,cx,cy,danger[abegin].Surface,walk[awalk].Surface,true);
 end;

procedure TPeligros.updateDestruction;
 begin
  dangdestroy := true;
  dbegin := adanger[dtip][3];
  dend := adanger[dtip][4];
  dvel := GetTickCount;
 end;

end.
