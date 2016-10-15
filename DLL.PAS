unit DLL;

interface

Uses Windows, Classes, DXDraws, DXInput, Mouse, Module;

type
 TFarProcObj = function : byte of object;
 TCoCreateGame = function(Screen : TDXDraw; KeyBoard : TDXInput; Sound : TSoundSystem; Mouse : Mouse.TMouse) : TFarProcObj; stdcall;
 TCoDestroyGame = procedure; stdcall;
 
var
 IdGame : function : Integer; stdcall;

function LoadDLLids : TList;
function LoadDLL(id : Integer) : boolean;
function LoadDLLProc(NameProc : String) : TFarProc;
procedure FreeDLL;

implementation

Uses SysUtils;

var
 h : THandle = 0;

function LoadDLL(id : Integer) : boolean;
 var
  F : TSearchRec;
  DosError : Integer;
 begin
  result := false;
  DosError := FindFirst('*.DLL',faReadOnly or faArchive,F);
  while DosError = 0 do
  begin
   h := LoadLibrary(pchar(F.Name));
   if h<>0 then
    begin
     IdGame := GetProcAddress(h,pchar('IdGame'));
     if not(@IdGame = nil) then
      begin
       if IdGame = id then
        begin
         result := True;
         break;
        end
      end;
     FreeLibrary(h); 
    end;
   DosError := FindNext(F);
  end;
 end;

function LoadDLLProc(NameProc : String) : TFarProc;
 begin
  result := GetProcAddress(h,pchar(NameProc));
 end;

procedure FreeDLL;
 begin
  FreeLibrary(h);
 end;

function LoadDLLids : TList;
 var
  x : pinteger;
  F : TSearchRec;
  DosError : Integer;
  hh : THandle; 
 begin
  hh := 0;
  result := TList.Create;
  DosError := FindFirst('Juego*.DLL',faReadOnly or faArchive,F);
  while DosError = 0 do
  begin
   hh := LoadLibrary(pchar(F.Name));
   if hh<>0 then
    begin
     IdGame := GetProcAddress(hh,pchar('IdGame'));
     if not(@IdGame = nil) then
      begin
       new(x);
       try
        x^ := IdGame;
       except
        dispose(x);
       end;
       result.Add(x);
      end;
     FreeLibrary(hh);
    end;
   DosError := FindNext(F);
  end;
 end;
end.
