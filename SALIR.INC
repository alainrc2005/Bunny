var
 optionsSalir : byte;
 sCueva : boolean;
 xSalir : boolean;

procedure TScroll.PrepareSalir(mCueva : boolean);
 begin
  key.ClearStates;
  sCueva := mCueva;
  fMouse.SetMouseEvent(nil,nil,nil);
  Application.OnIdle := SalirIdle;
  fSalir := false;
  xSalir := True;
  cxs := -228;
  SalirTick := GetTickCount;
  optionsSalir := 0;
 end;

procedure TScroll.MouseDownSalir(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  if ptinrect(rect(299,199,320,213),Point(X,Y)) then optionsSalir := 1 else
   if ptinrect(rect(333,199,353,213),Point(X,Y)) then optionsSalir := 2;
 end;

procedure TScroll.UpdateSalirMove;
 begin
  if (GetTickCount - SalirTick >= 5) and xSalir then
   begin
    if cxs < 207 then inc(cxs,9) else
     begin
      xSalir := false;
      fMouse.SetMouseEvent(nil,MouseDownSalir,nil);
     end;
   end;
  scr.surface.draw(cxs,172,amb[102].surface,false);
 end;

procedure TScroll.SalirIdle(Sender: TObject; var Done: Boolean);
 var
  Salir : byte;
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  Salir := RenderSalir;
  case Salir of
   1: Application.Terminate;
   2: begin
    key.ClearStates;
    if sCueva then
     begin
      fMouse.SetMouseEvent(MouseMove,MouseDownCueva,MouseUpCueva);
      Application.OnIdle := CuevaIdle;
     end
    else
     begin
      fMouse.SetMouseEvent(MouseMove,MouseDown,MouseUp);
      Application.OnIdle := AppOnIdle;
     end;
   end;
  end;
 end;

function TScroll.RenderSalir : byte;
 var
  i : byte;
 begin
  key.Update;
  if isEscape in key.States then optionsSalir := 2;
  if key.keyboard.keys[83] then optionsSalir := 1;
  if key.keyboard.keys[78] then optionsSalir := 2;
  scr.surface.Draw(0,0,amb[0].Surface,false);
  if sCueva then
   begin
    virt.Surface.draw(0,0,imgCueva[0].Surface,false);
    virt.Surface.Draw(cxc,96,walk[awalk].Surface,true);
    for i := 1 to 4 do aranas[i].Anima;
    virt.Surface.Draw(0,0,imgCueva[1].Surface,true);
    scr.surface.Draw(24,104,virt,false);
   end
  else
   begin
    virt.Surface.Draw(-sCielo,0,amb[1].Surface,false);
    virt.Surface.Draw(-sScene,0,amb[2].Surface,true);

    for i := 1 to 6 do peligros[i].anima;
    for i := 1 to 8 do zanahorias[i].anima;
    for i := 1 to 9 do manzanas[i].anima;
    for i := 1 to 11 do ambiente[i].Anima;

    piedra.DrawInside(PiedraEnabled and hvarita);

    // animacion de la varita majica
    updatevarita;

    if not (salto or crece) then virt.Surface.Draw(cx,cy,walk[awalk].Surface,true);

    for i := 1 to 4 do pdelante[i].anima;

    virt.Surface.Draw(-sPlano,0,amb[3].Surface,true);
    piedra.DrawOutSide(PiedraEnabled and hvarita);
    scr.surface.Draw(24,104,virt,false);
    updatePiedra;
    updatePeligros;
    updateManzanas;
   end;
  updateLivesZana;

  UpdateSalirMove;
  fMouse.AnimaMouse;
  scr.Flip;
  result := optionsSalir;
 end;


