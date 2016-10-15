unit VarsComun;

interface

Uses DXInput, DXDraws, Windows, Classes;

Type
  TILib = class;

  TAutomaticSurfaceLib = class
  private
    FLib : TILib;
    FOffset : Integer;
    FSurface: TDirectDrawSurface;
    fTransparent : Longint;
    scr : TDXDraw;
    procedure SetTransparentColor(Value : Longint);
    function GetClientRect : TRect;
  protected
    procedure DXDrawNotifyEvent(Sender: TCustomDXDraw; NotifyType: TDXDrawNotifyType); virtual;
  public
    constructor Create(DXDraw : TDXDraw; Lib : TILib; _Offset : Integer);
    destructor Destroy; override;
    property Surface: TDirectDrawSurface read FSurface;
    property TransparentColor : Longint read fTransparent write SetTransparentColor;
    property ClientRect : TRect read GetClientRect;
    property Offest : Integer read FOffset;
  end;

  TILib = class
  private
   flib : TFileStream;
   fImageCount : dword;
   fscr : TDXDraw;
  public
   constructor Create(DXDraw : TDXDraw; FileName : String);
   destructor Destroy; Override;
   procedure CreateSurfaceIndex(Index : integer; Var Surface : TAutomaticSurfaceLib);
   procedure SurfaceIndex(_Offset : integer; Var Surface : TAutomaticSurfaceLib);
   property ImageCount : dword read fImageCount;
  end;

 procedure ScaleRect(var _rect: TRect; _perc: integer);

implementation

Uses SysUtils;

const
  LibID = 'AlCamLib';
 type
   TImgHeader= record
    name : string[12];
    size : dword;
   end;
const
 seeked = length(LibId)+SizeOf(dword);

{  TAutomaticSurface with ILib }

constructor TAutomaticSurfaceLib.Create(DXDraw : TDXDraw; Lib : TILib; _Offset : Integer);
begin
  inherited Create;
  FLib := Lib;
  FOffset := _Offset;
  scr := DXDraw;
end;

destructor TAutomaticSurfaceLib.Destroy;
begin
  if scr<>nil then
    scr.UnRegisterNotifyEvent(DXDrawNotifyEvent);
  inherited Destroy;
end;

procedure TAutomaticSurfaceLib.DXDrawNotifyEvent(Sender: TCustomDXDraw;
  NotifyType: TDXDrawNotifyType);
begin
  case NotifyType of
    dxntInitialize:
        begin
          FSurface := TDirectDrawSurface.Create(scr.DDraw);
          FSurface.SystemMemory := true;
        end;
    dxntFinalize:
        begin
          FSurface.Free;
          FSurface := nil;
        end;
    dxntRestore:
        begin
          FLib.SurfaceIndex(FOffset,Self);
          FSurface.TransparentColor := fTransparent;
        end;
    dxntDestroying:
        begin
          scr := nil;
        end;
  end;
end;

procedure TAutomaticSurfaceLib.SetTransparentColor(Value : Longint);
 begin
  fTransparent := Value;
  FSurface.TransparentColor := Value;
 end;

function TAutomaticSurfaceLib.GetClientRect : TRect;
 begin
  result := FSurface.ClientRect;
 end;

///////// Image Library ////////
constructor TILib.Create(DXDraw : TDXDraw; FileName : String);
 begin
  try
   fscr := DXDraw;
   flib := tfilestream.Create(FileName,fmOpenRead or fmShareDenyNone);
   flib.Seek(length(LibID),soFromBeginning);
   flib.Read(fImageCount,sizeof(fImageCount));
  except
   raise;
  end;
 end;

destructor TILib.Destroy;
 begin
  flib.Free;
  inherited Destroy;
 end;

procedure TILib.CreateSurfaceIndex(Index : integer; Var Surface : TAutomaticSurfaceLib);
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
      Surface := TAutomaticSurfaceLib.Create(fscr,Self,flib.Position - SizeOf(TImgHeader));
      fscr.RegisterNotifyEvent(Surface.DXDrawNotifyEvent);
      break;
     end
    else flib.Seek(ImgHdr.size,soFromCurrent);
  end;
 end;


procedure TILib.SurfaceIndex(_Offset : integer; var Surface : TAutomaticSurfaceLib);
 var
  ImgHdr: TImgHeader;
 begin
  flib.Seek(_Offset,soFromBeginning);
  flib.ReadBuffer(ImgHdr, SizeOf(TImgHeader));
  Surface.FSurface.LoadFromStream(flib);
 end;


procedure ScaleRect(var _rect: TRect; _perc: integer);
var
 _x, _y : longint;
begin
  _x := _rect.Right  - _rect.Left + 1;
  _y := _rect.Bottom - _rect.Top  + 1;
  _x := (_perc * _x) div 100;
  _y := (_perc * _y) div 100;
  _rect.Left   := _rect.Left   - _x;
  _rect.Right  := _rect.Right  + _x;
  _rect.Top    := _rect.Top    - _y;
  _rect.Bottom := _rect.Bottom + _y;
end;


end.
