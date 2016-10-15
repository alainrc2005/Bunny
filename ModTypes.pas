unit ModTypes;

interface

Uses Windows, DirectX;

type
 TrackInfo = record
  Samples    : pointer;
  Position   : dword;
  Len        : dword;
  Repeaat    : dword;
  RepLen     : dword;
  Volume     : byte;
  Period     : dword;
  Pitch      : dword;
  Effect     : dword;
  PortTo     : dword;
  PortParm   : byte;
  VibPos     : byte;
  VibParm    : byte;
  TremPos    : byte;
  TremParm   : byte;
  OldSampOfs : byte;
  Arp        : array [1..3] of dword;
  ArpIndex   : dword;
{  barra      : dword;}
  num        : byte;
 end;

 PMod = ^TMod;
 TMod  = record
  OrderLen        : byte;
  ReStart         : byte;
  Order           : array [1..128] of byte;
  Patterns        : array [1..255] of pointer;
  Samplen         : array [1..99] of dword;
  Sampaddr        : array [1..99] of pointer;
  SampRep         : array [1..99] of dword;
  SampRepLen      : array [1..99] of dword;
  SampVol         : array [1..99] of dword;
  patnum          : word;
  numtracks       : dword;
 end;

type
 ModSample = record
  msName          : array [1..22] of byte;
  msLength        : word;
  msFinetune      : byte;
  msVolume        : byte;
  msRepeat        : word;
  msRepLen        : word;
 end;

 ModHeader  = record
  mhName          : array [1..20] of byte;
  mhSamples       : array [1..31] of ModSample;
  mhOrderLen      : byte;
  mhReStart       : byte;
  mhOrder         : array [1..128] of byte;
  mhSign          : longint;
 end;


// ModLibrary
 TModWav = (ttWav,ttMod);
 TModWavHeader = record
  Name  : string[8];
  Size  : integer;
  mtType: TModWav;
 end;

 TWavHeader = record
  RIFFMagic    : longint;
  FileLength   : longint;
  FileType     : longint;
  FormMagic    : longint;
  FormLength   : longint;
  SampleFormat : word;
  NumChannels  : word;
  PlayRate     : longint;
  BytesPerSec  : longint;
  Pad          : word;
  BitsPerSample: word;
  DataMagic    : longint;
  DataLength   : longint;
 end;

  TModWaveFormatEx = record
    wFormatTag: Word;         { format type }
    nChannels: Word;          { number of channels (i.e. mono, stereo, etc.) }
    nSamplesPerSec: DWORD;  { sample rate }
    nAvgBytesPerSec: DWORD; { for buffer estimation }
    nBlockAlign: Word;      { block size of data }
    wBitsPerSample: Word;   { number of bits per sample of mono data }
    cbSize: Word;           { the count in bytes of the size of }
  end;

const
 libIDString = 'AlCam Sound Library';
 lenID = Length(libIDString);

type
 TSndLib = record
  libID : array[0..lenID-1] of char; // cabecera de la libreria
  WaveCount : integer; // cantidad de wav
  ModuleCount : integer; // cantidad de mod
 end;

 TSndSoundType = (tsWav,tsMod,tsMp3);
 TSndLibSound = record
  Name: array[0..11] of char;
  SoundType: TSndSoundType;
  Size: Integer;
 end;
 
implementation

end.
