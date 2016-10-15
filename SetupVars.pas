{$DEFINE FULL}
unit SetupVars;

interface

Uses Windows, Classes, DXDraws, DXInput, VarsComun, Mouse, Module;

var
 scr : TDXDraw;
 key : TDXInput;
 Sound : TSoundSystem;
 fMouse : Mouse.TMouse;

 GameReady : boolean = false;
 GameAvailable : boolean = false;
 GameInitialized : boolean = false;

 FullScreen : boolean = {$IFDEF FULL}True{$ELSE}False{$ENDIF};

implementation

end.
