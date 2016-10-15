unit Piedras;

interface

Uses DXDraws, Vars;

type
 TPiedras = class
  private
   virt : TAutomaticSurface;
  public
   tip : byte;
   X : integer;
   constructor Create(Surface : TAutomaticSurface);
   destructor Destroy; Override;
   procedure DrawInside(Value : Boolean);
   procedure DrawOutSide(Value : Boolean);
   function Splash(Deltha : integer; tconejo : byte) : boolean;
   function Splash2(Deltha : integer; tconejo : byte) : boolean;
 end;

const
 resto : array[1..6] of byte = (14,34,16,20,25,18);
 incr  : array[1..6] of shortint = (20,8,-12,20,8,-12);


implementation

const
 g1 : array[0..1] of array[1..4] of integer = ((2874,2916,2956,2994), (2876,2920,2960,2994));
 m1 : array[1..2] of array[1..6] of integer = ((2868,2902,2924,2950,2974,2996), (2868,2898,2922,2944,2974,2996));
 c1 : array[0..1] of array[1..10] of integer = ((2880,2892,2904,2920,2932,2948,2964,2978,2992,3002),(2882,2892,2906,2922,2936,2954,2966,2984,2996,3004));

constructor TPiedras.Create(Surface : TAutomaticSurface);
 begin
  virt := Surface;
  X := 3198;
 end;

destructor TPiedras.Destroy;
 begin
  inherited Destroy;
 end;

procedure TPiedras.DrawInside(Value : Boolean);
 begin
  if Value then virt.Surface.Draw(X,178,amb[95+tip].surface,true);
 end;

procedure TPiedras.DrawOutSide(Value : Boolean);
 begin
  if Value then virt.Surface.Draw(X,178,amb[98+tip].surface,true);
 end;

function TPiedras.Splash(Deltha : integer; tconejo : byte) : boolean;
 var
  i : byte;
 begin
  result := false;
  i := 1;
  case tconejo of
   3,6 : begin
    repeat
     if (Deltha > g1[tconejo shr 2][i]) and (Deltha < g1[tconejo shr 2][i+1]) then
      begin
      result := true;
      break
     end;
     inc(i,2);
    until i=5;
   end;
   2,5 : begin
    repeat
     if (Deltha > m1[tconejo shr 1][i]) and (Deltha < m1[tconejo shr 1][i+1]) then
      begin
       result := true;
       break
      end;
     inc(i,2);
    until i=7;
   end;
   1,4 : begin
    repeat
     if (Deltha > c1[tconejo shr 2][i]) and (Deltha < c1[tconejo shr 2][i+1]) then
      begin
       result := true;
       break
      end;
     inc(i,2);
    until i=11;
   end;
  end;
 end;

function TPiedras.Splash2(Deltha : integer; tconejo : byte) : boolean;
 begin
  result := false;
  case tconejo of
   3,6 : begin
    if (Deltha > g1[tconejo shr 2][1]) and (Deltha < g1[tconejo shr 2][4]) then result := true;
   end;
   2,5 : begin
    if (Deltha > m1[tconejo shr 1][1]) and (Deltha < m1[tconejo shr 1][6]) then result := true;
   end;
   1,4 : begin
    if (Deltha > c1[tconejo shr 2][1]) and (Deltha < c1[tconejo shr 2][10]) then result := true;
   end;
  end;
 end;

end.
