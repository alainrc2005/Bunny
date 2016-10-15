{$J+}
{Permite que las constantes puedan recibir asignación...Alain}
unit ModVars;

interface

Uses Windows, DirectX, ModTypes;

const
  Looping     : Boolean = true;
  PlayingSample : boolean = true;

const
  stereo      : boolean = false;
  MixSpeed    : dword = 11025*4;
  mixbufsize  : dword = 32*1024;
  Mt_LowMask  : byte = $ff;
  DefTempo    = 6;
  DefBpm    = 125;
  MidCRate  = 8363;

  ID_RIFF = $46464952; {RIFF}
  ID_WAVE = $45564157; {WAVE}
  ID_FMT  = $20746D66; {FMT}
  ID_DATA = $61746164; {DATA}

  idMK   = $2E4B2E4D; {M.K.}
  idMK1  = $214B214D; {M!K!}
  idFLT4 = $34544C46; {FLT4}
  id4CHN = $4E484334; {4CHN}
  id8CHN = $4E484338; {8CHN}
  id6CHN = $4E484336; {6CHN}

  SinTable  : array [1..32] of byte =
   (0  ,25 ,50 ,74 ,98 ,120,142,162,180,197,212,225,
    236,244,250,254,255,254,250,244,236,225,
    212,197,180,162,142,120,98 ,74 ,50 ,25 );

  PeriodTable : array [0..7*12-1] of dword =
   (3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1814,
    1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960 ,907 ,
    856 ,808 ,762 ,720 ,678 ,640 ,604 ,570 ,538 ,508 ,480 ,453 ,
    428 ,404 ,381 ,360 ,339 ,320 ,302 ,285 ,269 ,254 ,240 ,226 ,
    214 ,202 ,190 ,180 ,170 ,160 ,151 ,143 ,135 ,127 ,120 ,113 ,
    107 ,101 ,95  ,90  ,85  ,80  ,75  ,71  ,67  ,63  ,60  ,56  ,
    53  ,50  ,47  ,45  ,42  ,40  ,37  ,35  ,33  ,31  ,30  ,28   );

var
 BufPtr        : DWord;
 Tracks        : array [1..16] of TrackInfo;
 PlayingMod    : boolean;
 ModVolume     : byte; {se recomienda 0..110}
 PitchTable    : array [0..3424] of dword;

implementation

end.
