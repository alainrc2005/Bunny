unit mainAutoRun;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Registry;

type
  Tfmain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
   fLib : TFileStream;
   fImageCount : dword;

   front : TBitmap;
   back : TBitmap;
   rgn : HRGN;

   ciclo : TBitmap;
   cicloTick : dword;
   cy : integer;

   options : word;

   conejos : array[1..8] of TBitmap;
   menu : array[1..10] of TBitmap;
   opciones : array[1..4] of boolean;
   selected : byte;

   installed : boolean;
   installedPath : string;
   pathApp : string;

   procedure LoadBitmapIndex(Index : integer; Var Bmp : TBitmap);
   procedure DrawTransparent(t: TBitmap; x,y: Integer; s: TBitmap; TrCol: TColor);
   function BitmapToRgn(Bitmap : TBitmap; TransColor : TColor) : HRGN;

   procedure updateCiclo;
   procedure ProcessMenu;

   procedure AppOnIdle(Sender: TObject; var Done: Boolean);
  end;

var
  fmain: Tfmain;

implementation

{$R *.dfm}
Uses ShellAPI;

resourcestring
 sInstall = '  Se ha producido un error, asegúrese de que los'^M+
            'ficheros de instalación existan y no esten dañados';
 sExecute = 'Se ha producido un error al intentar ejecutar el juego,'^M+
            'si el problema persiste instale nuevamente.';
 sPrimero = 'Para jugar es necesario instalar Bunny primero.';
 sDoc = '   Se ha producido un error, asegúrese de que los'^M+
        'ficheros de Documentación existan y no esten dañados';
const
 RenderLoad = 0;
 RenderRun  = 1;
const
  LibID = 'AlCamLib';
 type
   TImgHeader= record
    name : string[12];
    size : dword;
   end;
const
 seeked = length(LibId)+SizeOf(dword);

rab : array[1..8] of TPoint =
 ((X:5;Y:49),
  (X:268;Y:49),
  (X:5;Y:152),
  (X:268;Y:152),
  (X:5;Y:249),
  (X:268;Y:249),
  (X:5;Y:346),
  (X:268;Y:346)
  );
    {5,331} {239,331}
opt : array[1..4] of TRect =
 ((Left:59;Top:34;Right:261;Bottom:131),
  (Left:59;Top:138;Right:261;Bottom:235),
  (Left:59;Top:242;Right:261;Bottom:339),
  (Left:59;Top:346;Right:261;Bottom:443));

figmenu : array[1..4] of byte = (1,5,7,9);

procedure Tfmain.DrawTransparent(t: TBitmap; x,y: Integer; s: TBitmap; TrCol: TColor);
var
  bmpXOR, bmpAND, bmpINVAND, bmpTarget: TBitmap;
  oldcol: Longint;
begin
  try
   bmpAND        := TBitmap.Create;
   bmpAND.Width  := s.Width;
   bmpAND.Height := s.Height;
   bmpAND.Monochrome := True;
 
   oldcol := SetBkColor(s.Canvas.Handle, ColorToRGB(TrCol));

   BitBlt(bmpAND.Canvas.Handle, 0,0, s.Width, s.Height,
               s.Canvas.Handle, 0,0, SRCCOPY);
 
   SetBkColor(s.Canvas.Handle, oldcol);


   bmpINVAND       := TBitmap.Create;
   bmpINVAND.Width := s.Width;
   bmpINVAND.Height:= s.Height;
   bmpINVAND.Monochrome := True;
 
   BitBlt(bmpINVAND.Canvas.Handle, 0,0, s.Width, s.Height,
             bmpAND.Canvas.Handle, 0,0, NOTSRCCOPY);

   bmpXOR        := TBitmap.Create;
   bmpXOR.Width  := s.Width;
   bmpXOR.Height := s.Height;
 
   BitBlt(bmpXOR.Canvas.Handle, 0,0, s.Width, s.Height,
               s.Canvas.Handle, 0,0, SRCCOPY);
 
   BitBlt(bmpXOR.Canvas.Handle, 0,0, s.Width, s.Height,
       bmpINVAND.Canvas.Handle, 0,0, SRCAND);

   bmpTarget        := TBitmap.Create;

   bmpTarget.Width  := s.Width;
   bmpTarget.Height := s.Height;

   BitBlt(bmpTarget.Canvas.Handle, 0,0, s.Width, s.Height,
                  t.Canvas.Handle, x,y, SRCCOPY);
 
   BitBlt(bmpTarget.Canvas.Handle, 0,0, s.Width,s.Height,
             bmpAND.Canvas.Handle, 0,0, SRCAND);

   BitBlt(bmpTarget.Canvas.Handle, 0,0, s.Width,s.Height,
             bmpXOR.Canvas.Handle, 0,0, SRCINVERT);
 
   BitBlt(t.Canvas.Handle,   x,y, s.Width, s.Height,
    bmpTarget.Canvas.Handle, 0,0, SRCCOPY);

  finally
   bmpXOR.Free;
   bmpAND.Free;
   bmpINVAND.Free;
   bmpTarget.Free;

  end;{End of TRY section}
end;

procedure Tfmain.LoadBitmapIndex(Index : integer; Var Bmp : TBitmap);
 var
  n: Integer;
  ImgHdr: TImgHeader;
 begin
  flib.Seek(seeked,soFromBeginning);
  for n := 0 to fImageCount - 1 do
  begin
     //Read Image Header
     flib.ReadBuffer(ImgHdr, SizeOf(TImgHeader));
     if n = index then
      begin
      bmp := TBitmap.Create;
      bmp.LoadFromStream(fLib);
      break;
     end
    else flib.Seek(ImgHdr.size,soFromCurrent);
  end;
 end;

function Tfmain.BitmapToRgn(Bitmap : TBitmap; TransColor : TColor) : HRGN;
 const
  AllocUnit=100;
  var
   BMP:TBitmap;
   MaxRects:Cardinal;
   HData:HGlobal;
   PData:PRgnData;
   CB,CR,CG,LR,LG,LB:Byte;
   P32:Pointer;
   X,X0,Y:Integer;
   P:PLongInt;
   PR:PRect;
   H:Hrgn;
begin
 Result:=0;
 BMP:=TBitmap.Create;
 BMP.Assign(Bitmap);
 BMP.HandleType:=bmDIB;
 BMP.PixelFormat:=pf32bit;
 MaxRects:=AllocUnit;
 HData:=GlobalAlloc(GMem_Moveable,SizeOf(TRgnDataHeader)+SizeOf(TRect)*MaxRects);
 PData := GlobalLock(HData);
 PData^.RDH.dwSize:=SizeOf(TRgnDataHeader);
 PData^.RDH.iType:=RDH_Rectangles;
 PData^.RDH.nCount:=0;
 PData^.RDH.nRgnSize:=0;
 SetRect(PData^.RDH.rcBound,MaxInt,MaxInt,0,0);
 LR:=GetRValue(ColorToRGB(TransColor));
 LG:=GetGValue(ColorToRGB(TransColor));
 LB:=GetBValue(ColorToRGB(TransColor));
 for Y:=0 to Bitmap.Height-1 do
  begin
   X:=-1;
   P32:=BMP.ScanLine[Y];
   while X+1<Bitmap.Width do
    begin
     Inc(X);
     X0:=X;
     P:=PLongInt(P32);
     Inc(PChar(P),X*SizeOf(LongInt));
     while X<Bitmap.Width do
      begin
       CR:=GetBValue(P^);
       CG:=GetGValue(P^);
       CB:=GetRValue(P^);
       if ((CR=LR) and (CG=LG) and (CB=LB)) then
        Break;
       Inc(PChar(P),SizeOf(LongInt));
       Inc(X)
      end;
     if X>X0 then
      begin
       if PData^.RDH.nCount>=MaxRects then
        begin
         GlobalUnlock(HData);
         Inc(MaxRects,AllocUnit);
         HData:=GlobalReAlloc(HData,SizeOf(TRgnDataHeader)+SizeOf(TRect)*MaxRects,GMem_Moveable);
         PData:=GlobalLock(HData)
        end;
       PR:=@PData^.Buffer[PData^.RDH.nCount*SizeOf(TRect)];
       SetRect(PR^,X0,Y,X,Y+1);
       if X0<PData^.RDH.rcBound.Left then
        PData^.RDH.rcBound.Left:=X0;
       if Y<PData^.RDH.rcBound.Top then
        PData^.RDH.rcBound.Top:=Y;
       if X>PData^.RDH.rcBound.Right then
        PData^.RDH.rcBound.Left:=X;
       if Y+1>PData^.RDH.rcBound.Bottom then
        PData^.RDH.rcBound.Bottom:=Y+1;
       Inc(PData^.RDH.nCount);
       if PData^.RDH.nCount=2000 then
        begin
         H:=ExtCreateRegion(nil,SizeOf(TRgnDataHeader)+(SizeOf(TRect)*MaxRects),PData^);
         if Result<>0 then
          begin
           CombineRgn(Result,Result,H,RGN_OR);
           DeleteObject(H);
          end
         else
          Result:=H;
         PData^.RDH.nCount:=0;
         SetRect(PData^.RDH.rcBound,MaxInt,MaxInt,0,0)
        end
      end
    end
  end;
 H:=ExtCreateRegion(nil,SizeOf(TRgnDataHeader)+(SizeOf(TRect)*MaxRects),PData^);
 if Result<>0 then
  begin
   CombineRgn(Result,Result,H,RGN_OR);
   DeleteObject(H);
  end
 else
  Result:=H;
 GlobalFree(HData);
 BMP.Free
end;

procedure Tfmain.FormCreate(Sender: TObject);
 var
  reg : TRegistry;
begin
 pathApp := ExtractFilePath(Application.ExeName);
 reg := TRegistry.Create;
 try
  reg.RootKey := HKEY_CLASSES_ROOT;
  if reg.OpenKey('\ZBunny',false) then
   begin
    installed := reg.ReadInteger('Installed') = 1;
    installedPath := reg.ReadString('InstalledPath');
   end else installed := false;
  reg.CloseKey;
 finally
  reg.Free;
 end;
 try
  flib := tfilestream.Create('AutoRun.lib',fmOpenRead or fmShareDenyNone);
  flib.Seek(length(LibID),soFromBeginning);
  flib.Read(fImageCount,sizeof(fImageCount));
  options := RenderLoad;
  LoadBitmapIndex(0,back);
  front := TBitmap.Create;
  front.Assign(back);
  rgn := BitmapToRgn(back,rgb(84,84,84));
  SetWindowRgn(Handle,rgn,True);
 except
 end;
 Application.OnIdle := AppOnIdle;
end;

procedure Tfmain.updateCiclo;
 var
  i,j : byte;
 begin
  if GetTickCount - cicloTick >= 50 then
   begin
    cicloTick := GetTickCount;
    dec(cy);
    if cy = -52 then cy := 0;
   end;
  front.canvas.Draw(44,cy,ciclo);
  front.canvas.Draw(265,cy,ciclo);
  for i := 1 to 4 do front.Canvas.Draw(opt[i].Left,opt[i].Top,menu[figmenu[i]+byte(opciones[i])]);
  j := 1;
  for i := 1 to 4 do
   if opciones[i] then
    begin
     DrawTransparent(front,rab[pred(i)*2+1].X,rab[pred(i)*2+1].Y-15,conejos[7],rgb(84,84,84));
     DrawTransparent(front,rab[pred(i)*2+2].X-29,rab[pred(i)*2+2].Y-15,conejos[8],rgb(84,84,84));
    end
   else
    begin
     DrawTransparent(front,rab[pred(i)*2+1].X,rab[pred(i)*2+1].Y,conejos[j],rgb(84,84,84));
     DrawTransparent(front,rab[pred(i)*2+2].X,rab[pred(i)*2+2].Y,conejos[j+1],rgb(84,84,84));
     inc(j,2);
    end;
 end;

procedure Tfmain.AppOnIdle(Sender: TObject; var Done: Boolean);
 var
  i : integer;
 begin
  Done := False;
  front.Canvas.Draw(0,0,back);
  case options of
   RenderLoad : begin
    LoadBitmapIndex(1,ciclo);
    cicloTick := GetTickCount; cy := 0;
    for i := 2 to 9 do LoadBitmapIndex(i,conejos[i-1]);
    for i := 10 to 19 do LoadBitmapIndex(i,menu[i-9]);
    fillchar(opciones,sizeof(opciones),false);
    selected := 1;
    if installed then figmenu[1] := 3 else figmenu[1] := 1;
    opciones[1] := true;
    options := RenderRun;
   end;
   RenderRun : begin
    updateCiclo;
   end;
  end;
  canvas.Draw(0,0,front);
 end;

procedure Tfmain.FormClose(Sender: TObject; var Action: TCloseAction);
 var
  i : integer;
begin
 for i := 1 to 10 do menu[i].Free;
 for i := 1 to 8 do conejos[i].Free;
 DeleteObject(rgn);
 ciclo.Free;
 front.Free;
 back.Free;
 fLib.Free;
end;

procedure Tfmain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_UP : if selected = 1 then selected := 4 else dec(selected);
  VK_DOWN : if selected = 4 then selected := 1 else inc(selected);
  VK_RETURN : ProcessMenu;
 end;
 fillchar(opciones,sizeof(opciones),false);
 opciones[selected] := true;
end;

procedure Tfmain.FormMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
 var
  i : byte;
begin
 for i := 1 to 4 do
  if PtInRect(opt[i],Point(X,Y)) then
   begin
    fillchar(opciones,sizeof(opciones),false);
    opciones[i] := true;
    selected := i;
    break;
   end;
end;

procedure Tfmain.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
 var
  i : byte;
begin
 for i := 1 to 4 do
  if PtInRect(opt[i],Point(X,Y)) then
   begin
    fillchar(opciones,sizeof(opciones),false);
    opciones[i] := true;
    selected := i;
    ProcessMenu;
    exit;
   end;
end;

procedure Tfmain.ProcessMenu;
 var
  x : hinst;
 begin
  case selected of
   1: begin
     x := ShellExecute(handle,pchar('open'),pchar(pathApp+'Instalacion\Setup.exe'),nil,pchar(pathApp+'\Instalacion'),SW_SHOW);
     if x <= 32 then ShowMessage(sInstall) else close;
   end;
   2: begin
    if installed then
     if ShellExecute(handle,pchar('open'),pchar(installedPath+'\Bunny.exe'),nil,pchar(installedPath),SW_SHOW) <= 32 then ShowMessage(sExecute) else close
    else ShowMessage(sPrimero);
   end;
   3: begin
    if installed then
     if ShellExecute(handle,pchar('open'),pchar(installedPath+'\Documentacion\index.htm'),nil,pchar(installedPath+'\Documentacion'),SW_SHOW) <= 32 then ShowMessage(sDoc)
    else else
     if ShellExecute(handle,pchar('open'),pchar(pathApp+'Documentacion\index.htm'),nil,pchar(pathApp+'Documentacion'),SW_SHOW)  <= 32 then ShowMessage(sDoc);
   end;
   4 : close;
  end;
 end;


end.
