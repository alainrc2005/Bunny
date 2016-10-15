unit Ambiente;

interface

uses Windows, Classes, DXDraws, Vars;

 type
  TAmbiente = class
   private
    decvel : dword;
    velo   : word;
    timevi : dword;  // tiempo entre una animacion y otra
    auxview: word;     // auxiliar del tiempo entre una animacion y otra
    sbegin : byte;     // salva del inicio de la animacion
    abegin : byte;     // inicio de la animacion
    aend   : byte;     // fin de la animacion
    fijo   : boolean;  // si no tiene animacion [imagenes=1]
    virt : TAutomaticSurface;
   public
    corx   : integer;
    cory   : integer;
    constructor Create(fig : byte;surface : TAutomaticSurface);
    destructor Destroy; override;
    procedure Anima;
  end;

implementation

const
// animaciones de ambiente
  corxs : array[1..15] of integer = (
    {raton   carpintero  topo      abejas}
   816,1672,2112,2512,
    {pez1       pez2      ardilla}
   3208,3248,3856,
    {culebra   venado      buho       cascada}
   4520,5744,6928,7376,
    {entrada    salida    camaleon   puente }
   4360,4984,5016,6028);
  corys : array[1..15] of integer = (
   48,22,110,20,   116,138,24,   16,64,32,32,   0,0,50,128);
  fijos : array[1..15] of boolean = (
   false,false,false,false,
   false,false,false,
   false,false,false,false,
   true,true,false,true);
  primeros : array[1..15] of byte = (
   55,65,58,10,   43,49,21,   39,16,29,33,   67,68,37,69);
  ultimos : array[1..15] of byte = (
   57,66,64,15,   48,54,28,   42,20,32,36,   67,68,38,69);
  veloc : array[1..15] of integer = (
   210,208,216,206,   214,210,212,   212,212,212,210,   0,0,212,0);
  viewani : array[1..15] of integer = (
   0,0,1680,0,   200,1860,1890,   1100,1100,1650,0,   0,0,1680,0);

constructor TAmbiente.Create(fig : byte;surface : TAutomaticSurface);
 begin
  virt := surface;

  fijo := fijos[fig];
  corx := corxs[fig];
  cory := corys[fig];
  abegin := primeros[fig];
  sbegin := primeros[fig];
  aend := ultimos[fig];
  decvel := GetTickCount;
  velo := veloc[fig];
  timevi := GetTickCount;
  auxview := viewani[fig];
 end;

destructor TAmbiente.Destroy;
 begin
  inherited Destroy;
 end;

procedure TAmbiente.anima;
 begin
  if not fijo then
   begin
    if GetTickCount - timevi >= auxview then
     begin
      if GetTickCount - decvel >= velo then
       begin
        if abegin=aend then
         begin
          abegin := sbegin;
          timevi := GetTickCount;  
         end else inc(abegin);
        decvel := GetTickCount;
       end;
    end;
   end;
  virt.Surface.draw(corx,cory,amb[abegin].Surface,true);
 end;

end.
