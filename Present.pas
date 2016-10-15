unit present;

interface

uses Windows, Classes, DXDraws, Vars, VarsComun, ModTypes, Module;

type
  Tfpresent = class
  private
    imgLib : TILib;
    sndLib : TSoundLibrary;
    virt : TAutomaticSurface;
    images : array[0..24] of TAutomaticSurfaceLib;
    RabTick : dword;
    Rab : byte;
    paso : integer;
    pasoTick : dword;
    padre,conPadre, Chamas : boolean;
    padreimg : byte;


    motherTick : dword;
    motherimg : integer;
    conMother, mother : boolean;
    fBunny : boolean;
    fScale : integer;
    stars : boolean;
    posstar : byte;
    aleastar : byte;
    starTick : dword;
    ojo : byte;

    amp,tc : dword;
    frect,nrect : TRect;
    imgIndex : dword;

    modpresent : TMod;
    procedure putrabbys;
    procedure putpadre;
    procedure animamother;
    procedure animastars;
  public
    constructor Create;
    destructor Destroy; Override;
    function RenderLoad : boolean;
    procedure Render1;
    procedure Render2;
    procedure Render3;
    procedure Render4;
    property Amplitud : dword read amp write amp;
  end;

var
 fpresent : Tfpresent;

implementation

Uses Forms, DXInput, Mouse;

 const
  coorrabbys : array[0..15] of word =
  (298,256,442,270,
    162,304,490,310,
   258,338,434,346,
   338,328,218,272);
  coorstar : array[0..11] of word =
   (290,106,402,126,
    198,76,450,100,
    370,100,242,112);
  star : array[1..5] of byte = (22,23,24,23,22);

constructor Tfpresent.Create;
 begin
  imgLib := TIlib.Create(scr, 'Lib\presentacion.lib');
  RabTick := GetTickCount;
  pasoTick := RabTick;

  motherTick := RabTick; motherimg := 15; mother := false; conMother := false;

  Rab := 0;
  paso := -97;
  Chamas := false;
  Padre := true; conPadre := false; padreimg := 1;
  posstar := 1; aleastar := random(6); starTick := RabTick;
  ojo := 21;
  tc := GetTickCount;
  amp := 0; imgIndex := 0;
  try
   SndLib := TSoundLibrary.Create('Lib\Presentacion.snd',Sound);
   SndLib.LoadModFromLibrary(0,modpresent);
   Sound.PlayModule(modpresent);
  except
  end; 
 end;

destructor Tfpresent.Destroy;
 var
  i : integer;
 begin
  Sound.StopModule;
  SndLib.FreeModule(modpresent);
  SndLib.Free;
  virt.Free;
  for i := 0 to imgLib.ImageCount - 1 do images[i].Free;
  imgLib.free;
  inherited Destroy;
 end;

procedure Tfpresent.Render1;
 begin
  putpadre;
  putrabbys;
  animamother;
  animastars;
  scr.surface.Draw(0,0,virt,false);
 end;

procedure Tfpresent.Render2;
 begin
  if gettickcount - tc >=80 then
   begin
    inc(amp,4);
    tc := gettickcount;
   end;
  scr.surface.Fill(0);
  scr.surface.DrawRotate(0,0,virt,0,0,false,-amp);
 end;

procedure Tfpresent.Render3;
 begin
  if gettickcount - tc >=80 then
   begin
    tc := gettickcount;
    dec(amp,4);
   end;
  scr.surface.Fill(0); 
  scr.surface.DrawRotate(0,0,images[14].Surface,0,0,false,-amp);
 end;

procedure Tfpresent.Render4;
 begin
  scr.surface.Draw(0,0,images[14].Surface,false);
 end;

procedure Tfpresent.animamother;
 begin
  if Mother then
   begin
    virt.Surface.Draw(144,208,images[motherimg].Surface,false);
    if GetTickCount - motherTick >= 200 then
     begin
      motherTick := GetTickCount;
      inc(motherimg);
      if motherimg = 20 then
       begin
        mother := false; fBunny := true; fScale := 100;
        conMother := true;
        nRect := Rect(154,62,154+images[13].Surface.width,62+images[13].Surface.height);
       end;
     end;
    end
   else if conMother then virt.Surface.Draw(144,208,images[19].Surface,false); // madre
 end;

procedure Tfpresent.putrabbys;
 var
  i : byte;
 begin
  if Chamas then
   begin
    for i := 0 to Rab do virt.Surface.Draw(coorrabbys[i*2],coorrabbys[i*2+1],images[i+5].Surface,true);
    if GetTickCount - RabTick >= 100 then
     begin
      RabTick := GetTickCount;
      inc(Rab);
      Chamas := not(Rab > 7);
      mother := Rab > 7;
     end;
   end else
    if conPadre then
     begin
      for i := 0 to 7 do virt.Surface.Draw(coorrabbys[i*2],coorrabbys[i*2+1],images[i+5].Surface,true);
     end;
 end;

procedure Tfpresent.putpadre;
 begin
  if not conPadre then
   begin
    virt.Surface.Draw(0,0,images[0].Surface,false);
    virt.Surface.Draw(306,paso,images[padreimg].Surface,true);
    if GetTickCount - pasoTick >=80 then
     begin
      pasoTick := GetTickCount;
      inc(paso,7);
      if paso = 78 then padreimg := 2;
      if paso = 106 then padreimg := 3;
      if paso > 158 then
       begin
        Chamas := true;
        conPadre := true;
       end;
     end
   end else
    begin
     virt.Surface.Draw(0,0,images[0].Surface,false);
     virt.Surface.Draw(306,162,images[4].Surface,true);
    end;
 end;

procedure Tfpresent.animastars;
 begin
  if conMother then
   begin
    if fBunny then
     if fScale > 1 then
      begin
       dec(fScale,3);
       frect := nrect;
       ScaleRect(fRect,fScale);
       virt.Surface.StretchDraw(frect,images[13].surface,true);
      end
     else
      begin
       fBunny := false;
       stars := true;
      end
    else virt.Surface.Draw(154,62,images[13].Surface,true);
   end;
  if not stars then exit;
  virt.Surface.Draw(coorstar[aleastar*2],coorstar[aleastar*2+1],images[star[posstar]].Surface,true);
  virt.Surface.Draw(338,202,images[ojo].Surface,true);
  if GetTickCount - starTick >= 180 then
   begin
    starTick := GetTickCount;
    inc(posstar);
    if posstar > 5 then
     begin
      if ojo = 21 then ojo := 20 else ojo := 21;
      posstar := 1;
      aleastar := random(6);
     end;
   end;
 end;

function Tfpresent.RenderLoad : boolean;
 begin
  imgLib.CreateSurfaceIndex(imgIndex,images[imgIndex]);
  images[imgIndex].TransparentColor := fMouse.ctransparent;
  inc(imgIndex);
  result := imgIndex = imgLib.ImageCount;
  if result then
   begin
    scr.CreateSurface(virt,640,480);
    virt.Surface.Draw(0,0,images[0].Surface,false);
   end;
  fMouse.ProgressImage(images[0].surface,imgIndex,24);
 end;


end.
