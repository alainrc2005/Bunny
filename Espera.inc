function TScroll.RenderAdiosLoad : boolean;
 begin
  libWait.CreateSurfaceIndex(IndexWait,imgWait[IndexWait]);
  imgWait[IndexWait].TransparentColor := fMouse.cTransparent;
  inc(IndexWait);
  result := IndexWait = 5;
 end;

function TScroll.RenderEsperaLoad : boolean;
 begin
  libWait.CreateSurfaceIndex(IndexWait,imgWait[IndexWait-wbeginload[TypeWait]]);
  imgWait[IndexWait-wbeginload[TypeWait]].TransparentColor := fMouse.cTransparent;
  inc(IndexWait);
  result := IndexWait > wendload[TypeWait];
 end;

function TScroll.RenderWait : boolean;
 var
  i : byte;
 begin
  result := false;
  scr.surface.Draw(0,0,amb[0].Surface,false);
  virt.Surface.Draw(-sCielo,0,amb[1].Surface,false);
  virt.Surface.Draw(-sScene,0,amb[2].Surface,true);
  for i := 1 to 6 do peligros[i].anima;
  for i := 1 to 8 do zanahorias[i].anima;
  for i := 1 to 9 do manzanas[i].anima;
  for i := 1 to 11 do ambiente[i].Anima;
  piedra.DrawInside(PiedraEnabled and hvarita);
  // animacion de la varita majica
  updatevarita;
  // actualiza la animacion de las hadas
  updatehadas;

  case optionsWait of
   AdiosLoad : begin
    if RenderAdiosLoad then
     begin
      tickWait := GetTickCount;
      indexWait := 0; imgIndex := 0;
      optionsWait := AdiosAnima;
     end;
   end; // end of AdiosLoad
   AdiosAnima : begin
    if GetTickCount - tickWait >= 200 then
     begin
      tickWait := GetTickCount;
      inc(indexWait);
      if indexWait = 5 then
       begin
        indexWait := 1;
        inc(imgIndex);
        if imgIndex = 3 then
         begin
          for i := 0 to 4 do imgWait[i].free;
          result := true;
         end;
       end;
     end;
    virt.Surface.Draw(cx,cy,imgWait[indexWait].Surface,true);
   end;
   WaitInit : begin
    virt.Surface.Draw(cx,cy,walk[awalk].Surface,true);
    libWait := TILib.Create(scr,'Lib\Espera.lib');
    TypeWait := random(3)+1;
    IndexWait := wbeginload[TypeWait];
    imgTotal := wendload[TypeWait];
    optionsWait := WaitLoad;
    twalk := 2;
    calwalk;
    bigsmall;
   end;
   WaitLoad : begin
    virt.Surface.Draw(cx,cy,walk[awalk].Surface,true);
    if RenderEsperaLoad then
     begin
      IndexWait := 0; tickWait := GetTickCount;
      optionsWait := WaitRun;
     end;
   end;
   WaitRun : begin
    key.Update;
    if GetTickCount - tickWait >= 200 then
     begin
      tickWait := GetTickCount;
      inc(indexWait);
      if indexWait = 7+TypeWait then indexWait := 0;
     end;
    if key.States <> [] then
     begin
      for i := 0 to 6+TypeWait do imgWait[i].free;
      result := true;
     end;
    virt.Surface.Draw(cx,cy,imgWait[indexWait].Surface,true);
   end;
  end; // end of case

  for i := 1 to 4 do pdelante[i].anima;
  virt.Surface.Draw(-sPlano,0,amb[3].Surface,true);
  piedra.DrawOutSide(PiedraEnabled and hvarita);
  scr.surface.Draw(24,104,virt,false);
  updateLivesZana;
  fMouse.AnimaMouse;
  scr.Flip;
 end;

procedure TScroll.WaitIdle(Sender: TObject; var Done: Boolean);
 begin
  Done := false;
  if (not GameReady) or (not GameAvailable) then exit;
  if RenderWait then
   begin
    libWait.Free;
    Application.OnIdle := AppOnIdle;
   end;
 end;
