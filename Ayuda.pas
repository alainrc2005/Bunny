unit Ayuda;

interface

Uses DXDraws, VarsComun, ModTypes;

Type
 TAyuda = class
  private
   lib : TILib;
   img : TAutomaticSurfaceLib;
  public
   constructor Create(Index : Integer; Screen : TDXDraw);
   destructor Destroy; Override;
   property Imagen : TAutomaticSurfaceLib read img;
 end;

var
 HelpMusic : TMod;

implementation

constructor TAyuda.Create(Index : Integer; Screen : TDXDraw);
 begin
  lib := TILib.Create(Screen,'Lib\Ayudas.lib');
  lib.CreateSurfaceIndex(Index,img);
 end;

destructor TAyuda.Destroy;
 begin
  img.Free;
  lib.Free;
  inherited Destroy;
 end;

end.
