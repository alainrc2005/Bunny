unit Mouse;

interface

uses Windows, Classes, Controls, Contnrs, DXDraws, VarsComun;

type
 TMouseMove = procedure(Shift: TShiftState; X, Y: Integer) of object;
 TMouseDownUp = procedure(Button: TMouseButton; Shift: TShiftState; X, Y: Integer) of object;

 TMouseHard = class
   fX,fY : integer;
   fBlend : byte;
   public
    constructor Create(x,y : integer;Blend : byte);
    function update : boolean;
    property X : Integer read fX;
    property Y : Integer read fY;
    property Blend : byte read fBlend;
 end;

 TMouse = class
  private
   progress : array[0..1] of TAutomaticSurfaceLib;
   lib : TIlib;
   mouseTick: Integer;
   MouseAnima : byte;
   fOnMouseMove : TMouseMove;
   FOnMouseDown,
   FOnMouseUp : TMouseDownUp;
   fTransparentColor : dword;
   fMouseHard : TClassList;
   fBooleanMouseHard : boolean;
 protected
   scr : TDXDraw;
   mouse : array[0..5] of TAutomaticSurfaceLib;
   fMouseX,fMouseY : integer;
   procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); virtual;
   procedure MouseMoveHard(Sender: TObject; Shift: TShiftState; X, Y: Integer);
   procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
   procedure MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
   constructor Create(Screen : TDXDraw; MouseHard : Boolean);
   destructor Destroy; Override;
   procedure AnimaMouse;
   procedure AnimaMouseHard;
   procedure ClearMouseHard;
   procedure ProgressImage(Surface : TDirectDrawSurface; Index,Total : integer); overload;
   procedure ProgressImage(X,Y : integer; Surface : TDirectDrawSurface; Index,Total : integer); overload;
   procedure SetMouseEvent(Move : TMouseMove;Down,Up : TMouseDownUp);
   procedure StopAllEvents;
   procedure RestoreAllEvents;
   property MouseX : integer read fMouseX;
   property MouseY : integer read fMouseY;
   property cTransparent : dword read fTransparentColor write fTransparentColor;
 end;

implementation

Uses Forms, SysUtils;

constructor TMouse.Create;
 var
  i : byte;
 begin
  scr := Screen;
  lib := TILib.Create(scr, 'Lib\Mouse.Lib');
  lib.CreateSurfaceIndex(0,mouse[0]);
  cTransparent := mouse[0].Surface.Pixels[0,50];
  mouse[0].TransparentColor := cTransparent;
//  cTransparent := ConverTo16bits(84,84,84);
  for i := 1 to 5 do
   begin
    lib.CreateSurfaceIndex(i,mouse[i]);
    mouse[i].TransparentColor := cTransparent;
   end;
  for i := 0 to 1 do
   begin
    lib.CreateSurfaceIndex(6+i,progress[i]);
    progress[i].TransparentColor := cTransparent;
   end;
  mouseTick := GetTickCount;
  MouseAnima := 0;
  fOnMouseUp := nil;
  fOnMouseDown := nil;
  fOnMouseMove := nil;
  fBooleanMouseHard := MouseHard;
  RestoreAllEvents;
  fMouseHard := TClassList.Create;
 end;

procedure TMouse.StopAllEvents;
 begin
  with scr do
   begin
    OnMouseDown := nil;
    OnMouseMove := nil;
    OnMouseUp := nil;
   end;
 end;

procedure TMouse.RestoreAllEvents;
 begin
  with scr do
   begin
    OnMouseDown := MouseDown;
    OnMouseMove := MouseMove;
    OnMouseUp := MouseUp;
    if fBooleanMouseHard then OnMouseMove := MouseMoveHard;
   end;
 end;

destructor TMouse.Destroy;
 var
  i : byte;
 begin
  ClearMouseHard;
  fMouseHard.Free;
  for i := 0 to 5 do mouse[i].Free;
  lib.Free;
  inherited Destroy;
 end;

procedure TMouse.AnimaMouse;
 var
  tc : integer;
 begin
  tc := GetTickCount;
  if tc - MouseTick >= 80 then
   begin
    MouseTick := tc;
    if MouseAnima = 5 then MouseAnima := 0 else inc(MouseAnima);
   end;
  scr.surface.Draw(fMouseX,fMouseY,mouse[MouseAnima].surface,true);
 end;

procedure TMouse.AnimaMouseHard;
 var
  tc : integer;
 begin
  tc := 0;
  while tc < fMouseHard.Count do
   begin
    with TMouseHard(fMouseHard.Items[tc]) do
     begin
      scr.surface.DrawAlpha(rect(X,Y,X+52,Y+51),Mouse[0].surface.ClientRect,Mouse[0].Surface,true,Blend);
      if not Update then inc(tc) else
       begin
        TMouseHard(fMouseHard.Items[tc]).Free;
        fMouseHard.Delete(fMouseHard.IndexOf(fMouseHard.Items[tc]));
       end;
     end;
   end;
  AnimaMouse;
 end;

procedure TMouse.MouseMoveHard(Sender: TObject; Shift: TShiftState; X, Y: Integer);
 var
  zero : TMouseHard;
 begin
  if (fMouseX <> X) or (fMouseY <> Y) then
   begin
    zero := TMouseHard.Create(fMouseX,fMouseY,250);
    fMouseHard.Add(TClass(zero));
   end;
  MouseMove(Sender,Shift,X,Y);
 end;

procedure TMouse.ClearMouseHard;
 var
  i : integer;
 begin
  if fMouseHard.Count = 0 then exit;
  for i := 0 to fMouseHard.Count - 1 do
   TMouseHard(fMouseHard.Items[i]).Free;
  fMouseHard.Clear; 
 end;
 
procedure TMouse.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
 begin
  fMouseX := X;
  fMouseY := Y;
  if assigned(fOnMouseMove) then fOnMouseMove(Shift,fMouseX,fMouseY);
 end;

procedure TMouse.MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  if assigned(fOnMouseDown) then fOnMouseDown(Button,Shift,X,Y);
 end;

procedure TMouse.MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  if assigned(fOnMouseUp) then fOnMouseUp(Button,Shift,X,Y);
 end;

procedure TMouse.SetMouseEvent(Move : TMouseMove;Down,Up : TMouseDownUp);
 begin
  fOnMouseMove := Move;
  fOnMouseDown := Down;
  fOnMouseUp := Up;
 end;

procedure TMouse.ProgressImage(Surface : TDirectDrawSurface; Index,Total : integer);
 var
  p : word;
 begin
  p := round(index*100/total);
  if Surface <> nil then scr.surface.draw(0,0,surface);
  scr.surface.Draw((640-progress[0].Surface.Width) div 2,(480-progress[0].Surface.Height) div 2,progress[0].Surface,true);
  scr.surface.Draw((640-progress[0].Surface.Width) div 2,(480-progress[0].Surface.Height) div 2,rect(0,0,progress[0].surface.width*p div 100,progress[0].surface.height),progress[1].Surface,true);
 end;

procedure TMouse.ProgressImage(X,Y : integer; Surface : TDirectDrawSurface; Index,Total : integer);
 var
  p : word;
 begin
  p := round(index*100/total);
  if Surface <> nil then scr.surface.draw(0,0,surface);
  scr.surface.Draw(X,Y,progress[0].Surface,true);
  scr.surface.Draw(X,Y,rect(0,0,progress[0].surface.width*p div 100,progress[0].surface.height),progress[1].Surface,true);
 end;

///////////////////////////////////////
///////////////////////////////////////
//                                   //
//    H   H   AAA    RRR   DDDD      //
//    H   H  A   A  R   R  D   D     //
//    HHHHH  AAAAA  RRRR   D   D     //
//    H   H  A   A  R R    D   D     //
//    H   H  A   A  R  R   DDDD      //
//                                   //
///////////////////////////////////////
///////////////////////////////////////

constructor TMouseHard.Create(x,y : integer;Blend : byte);
 begin
  fx := x;
  fy := y;
  fblend := blend;
 end;

function TMouseHard.update;
 begin
  dec(fBlend,10);
  result := fBlend = 0;
 end;

end.
