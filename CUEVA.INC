procedure TScroll.CuevaIdle(Sender: TObject; var Done: Boolean);
 var
  i : integer;
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  i := RenderCueva;
  if i <> 0 then
   begin
    if i = 1 then
     begin
      if not CuevaD then
       begin
        CuevaD := True;
        inc(czana);
       end;
      if leftright then for i := 1 to 310 do keyrightDec else keyrightDec;
     end
    else
     begin
      if leftright then keyleftDec else for i := 1 to 310 do keyleftDec;
     end;
    for i := 0 to libCueva.ImageCount-1 do imgCueva[i].Free;
    libCueva.Free;
    fMouse.SetMouseEvent(nil,MouseDown,MouseUp);
    salto := false;
    Sound.PlayModule(modamb);
    sndlib.FreeModule(tmp);
    Application.OnIdle := AppOnIdle;
   end;
 end;

procedure TScroll.ActivaCueva;
 var
  i : byte;
 begin
  for i := 1 to 4 do aranas[i].Free;
  libCueva := TILib.Create(scr,'Lib\Cueva.lib');
  fMouse.SetMouseEvent(MouseMove,MouseDownCueva,MouseUpCueva);
  imgIndexCueva := 0;
  key.ClearStates;
  optionsCueva := LoadCueva;
  DoneVarsGame;
  Application.OnIdle := CuevaIdle;
 end;

function TScroll.RenderCuevaLoad : boolean;
 begin
  libCueva.CreateSurfaceIndex(imgIndexCueva,imgCueva[imgIndexCueva]);
  imgCueva[imgIndexCueva].TransparentColor := fMouse.cTransparent;
  inc(imgIndexCueva);
  result := imgIndexCueva = libCueva.ImageCount;
  fMouse.ProgressImage(224,173,nil,imgIndexCueva,libCueva.imagecount);
 end;

function TScroll.updateKeyBoardCueva : byte;
 begin
  result := 0;
  // crecer F2
  if (isF2 in key.States) then Grande;
  // disminuir
  if (isF3 in key.States) then Pequeno;
  // close game
  if isEscape in key.States then
   begin
    PrepareSalir(True);
    exit;
   end;
  // derecha
  if GetTickCount - KeyTick < 50 then exit;
  KeyTick := GetTickCount;
  if ((isRight in key.KeyBoard.States) or Right) then
   begin
    if twalk in [4..6] then
     begin
      dec(twalk,3);
      calwalk;
     end
    else
     begin
      if cxc < 556 then inc(cxc,2) else result := 1;
      if awalk < rwalk+6 then inc(awalk) else awalk := rwalk;
     end;
   end;
  // izquierda
  if ((isLeft in key.Keyboard.States) or Left) then
   begin
    if twalk in [1..3] then
     begin
      inc(twalk,3);
      calwalk;
     end
    else
     begin
      if cxc > 2 then dec(cxc,2) else result := 2;
      if awalk < rwalk+6 then inc(awalk) else awalk := rwalk;
     end;
   end;
 end;

function TScroll.RenderCueva : byte;
 var
  i : byte;
 begin
  result := 0;
  key.Update;
  scr.surface.Draw(0,0,amb[0].Surface,false);
  case optionsCueva of
   LoadCueva : begin
    if RenderCuevaLoad then
     begin
      sndlib.LoadModFromLibrary(3+random(2),tmp);
      Sound.PlayModule(tmp);
      for i := 1 to 4 do aranas[i] := TAranas.Create(i,virt,fMouse.cTransparent);
      if twalk in [1..3] then
       begin
        leftright := true;
        twalk := 2;
        cxc := 2;
       end
      else
       begin
        leftright := false;
        twalk := 5;
        cxc := 554;
       end;
      bigsmall;
      optionsCueva := MoveCueva;
      KeyTick := GetTickCount;
     end;
   end;
   MoveCueva : begin
    if (GetTickCount - tickWait >= 1180) then
     begin
      tickWait := GetTickCount;
      calwalk;
     end;
    for i := 1 to 4 do
     if aranas[i].Collision then
      begin
       if leftright then cxc := 2 else cxc := 554;
       break;
      end;
    virt.Surface.draw(0,0,imgCueva[0].Surface,false);
    result := updateKeyBoardCueva;
    virt.Surface.Draw(cxc,96,walk[awalk].Surface,true);
    for i := 1 to 4 do aranas[i].Anima;
    virt.Surface.Draw(0,0,imgCueva[1].Surface,true);
    scr.surface.Draw(24,104,virt,false);
    if fSalir then scr.Surface.Draw(561,0,amb[104].surface,true);
   end;
  end;
  updateLivesZana;
  fMouse.AnimaMouse;
  scr.Flip;
 end;

procedure TScroll.MouseDownCueva(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  if fSalir then
   begin
    PrepareSalir(True);
    exit;
   end;
  Right := X > 24 + cxc + walk[awalk].Surface.Width;
  Left := X < 24 + cxc;
 end;

procedure TScroll.MouseUpCueva(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  if Right then Right := false;
  if Left then Left := false;
 end;
