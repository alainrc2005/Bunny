// Programed by ALCAM Games
// ALain Ramírez Cabrejas
// CAMilo Blanco Peña
// 4/30/98 version 1.0
//
// 5/16/98 add stdcall to tfntimecallback in unit system
//
// 2/2/2001 Implemented with Direct Sound and TThread
//
// 11/22/2001 Implemente with DelphiX DirectSound

unit Module;

interface

uses Windows,MMSystem,Classes,Controls, SysUtils, ExtCtrls,
     DXSounds, Wave, ModTypes, ModVars;

const
 bunnyID = 'Bunny SETUP';
 len = length(bunnyID);
type
 SoundException = class(Exception);
 TEngine = class;
 TSave = record
  id : array[0..len] of char;
  musica : boolean;
  efectos: boolean;
 end;

 TSoundSystem   = class
  private
   fMusic : boolean;
   FDXSound : TDXSound;
   SoundBuffer : TDirectSoundBuffer;
   fExistSound : Boolean;

   fTimerThread : TThread;
   fEffect : boolean;
   fSaveMusic : boolean;
   fSaveEffect : boolean;

   fPlayingMod : PBoolean;
   fModInfo : PMod;
   fInitModVars : procedure;

  protected
   procedure Timer; dynamic;
  public
   constructor Create(Owner : TComponent);
   destructor Destroy; override;
   procedure PlayModule(fula : TMod);
   procedure StopModule;
   procedure UpdateSaveMusic(Save : TSave);
   procedure RestoreSaveMusic;

   property DirectSound : TDXSound read fDXSound write fDXSound;
   property ExistSound : boolean read fExistSound write fExistSound;
   property Music : boolean read fMusic write fMusic;
   property Effect : boolean read fEffect write fEffect;
   property SaveMusic : boolean read fSaveMusic write fSaveMusic;
   property SaveEffect : boolean read fSaveEffect write fSaveEffect;
 end;

 TWavLib = class
   fStream : TStream;
   fOffset : dword;
   fSoundSystem : TSoundSystem;
   fDirectSoundBuffer : TDirectSoundBuffer;
  protected
   procedure NotifyEventSound(Sender: TCustomDXSound; NotifyType: TDXSoundNotifyType);
  public
   constructor Create(SoundSystem : TSoundSystem; Stream : TStream; Offset : dword);
   destructor Destroy; override;
   procedure Play;
   procedure PlayLoop;
   procedure Stop;
   function Playing : boolean;
 end;

 TSoundLibrary = class
  private
   fSoundSystem : TSoundSystem;
   // library
   fLibHead : TSndLib;
   fLibStream : TFileStream;
   fLibrary : boolean;
  protected
   function Swap(j : dword) : dword;
  public
   constructor Create(FileName : string; SoundSystem : TSoundSystem); overload;
   constructor Create(SoundSystem : TSoundSystem); overload;
   destructor Destroy; Override;

   procedure LoadModFromStream(Stream : TStream; var ModVars : TMod);
   procedure LoadModFromFile(FileName : string; var ModVars : TMod);
   procedure LoadModFromLibrary(Index : integer; var ModVars : TMod);
   procedure FreeModule(var ModVars : TMod);

   procedure LoadWaveFromLibrary(Index : integer; var Wave : TEngine); overload;
   procedure LoadWaveFromLibrary(Index : integer; var Wave : TWavLib); overload;
 end;

 POptionsEngine = ^TOptionsEngine;
 TOptionsEngine = record
  ID : Integer;
  Active : boolean;
  DSBuffer : TDirectSoundBuffer;
 end;

 TEngine = class
  private
   fSoundSystem : TSoundSystem;
   fEffectList : TList;
   fTimer : TTimer;
   function GetEffect(Index: Integer): TDirectSoundBuffer;
   procedure SetEffectPlay(mID : Integer; Value : Boolean);
   function GetEffectCount: Integer;
   procedure TimerEvent(Sender: TObject);
  public
   constructor Create(SoundSystem : TSoundSystem);
   destructor Destroy; override;
   procedure Clear;
   procedure EffectFile(const Filename: string; mID : Integer);
   procedure EffectStream(Stream: TStream; mID : Integer);
   procedure EffectWave(Wave: TWave; mID : Integer);
   property EffectCount: Integer read GetEffectCount;
   property Effects[Index: Integer]: TDirectSoundBuffer read GetEffect;
   property EffectsPlay[Index: Integer]: Boolean write SetEffectPlay;
 end;

implementation

Uses Forms, DirectSound;

type
  TTimerThread = class(TThread)
  private
    FOwner: TSoundSystem;
    FException: Exception;
    procedure HandleException;
  protected
    procedure Execute; override;
  public
    constructor Create(Module: TSoundSystem; Enabled: Boolean);
  end;

constructor TTimerThread.Create(Module: TSoundSystem; Enabled: Boolean);
begin
  FOwner := Module;
  inherited Create(Enabled);
  FreeOnTerminate := True;
end;

procedure TTimerThread.HandleException;
begin
  if not (FException is EAbort) then begin
    if Assigned(Application.OnException) then
      Application.OnException(Self, FException)
    else
      Application.ShowException(FException);
  end;
end;

procedure TTimerThread.Execute;

  function ThreadClosed: Boolean;
  begin
    Result := Terminated or Application.Terminated or (FOwner = nil);
  end;

begin
  repeat
    if not ThreadClosed then
      if SleepEx(1, False) = 0 then begin
        if not ThreadClosed then
          with FOwner do
            //Synchronize(Timer) en caso de ser necesario
           try
             Timer;
           except
             on E: Exception do begin
               FException := E;
               HandleException;
             end;
           end;
      end;
  until Terminated;
end;


var
 MixBuffer     : array [1..8*1024*4] of byte;
 modinfo     : TMod;
 BpmSamples  : dword;
 BufLen      : dword;
 VolTable    : array [1..66*256] of byte;
 BufRep      : dword;
 TempoWait   : byte;
 Tempo       : byte;
 Note        : pointer;
 Row         : byte;
 OrderPos    : byte;
 BreakRow    : byte;
 Bpm         : byte;
 flag        : longint;
 first       : dword;

// modplay modules all subrutine are programmed in assambler
procedure makepitchvoltable; assembler;
 asm
  mov     eax,MidCRate
  mov     ebx,428
  mul     ebx
  div     [MixSpeed]
  xor     dh,dh
  mov     dl,ah
  mov     ah,al
  xor     al,al
  mov     ecx,3425
  xor     ebx,ebx
  mov     edi,offset PitchTable
@PitchLoop:
  push    eax
  push    edx
  cmp     edx,ebx
  jae     @NoDiv
  div     ebx
@NoDiv:
  stosd
  pop     edx
  pop     eax
  inc     ebx
  loop    @PitchLoop
@MakeVolume:
  mov     cl,6
  mov     edi,offset VolTable
  xor     bx,bx
@ci:
  mov     al,bl
  imul    bh
  sar     ax,cl
  mov     [edi],al
  inc     edi
  inc     bl
  jne     @ci
  inc     bh
  cmp     bh,64
  jbe     @ci
 end;

procedure InitModVars; assembler;
 asm
  pushad
  push    esi
  push    edi
@SetModParms:
  mov     [OrderPos],0
  mov     [Tempo],DefTempo
  mov     [TempoWait],DefTempo
  mov     [Bpm],DefBpm
  mov     [Row],64
  mov     [BreakRow],0
  mov     eax,[MixSpeed]
  xor     edx,edx
  mov     ebx,24*DefBpm/60
  div     ebx
  cmp     stereo,false
  je      @nostereo
  shl     eax,1
@nostereo:
  mov     [BpmSamples],eax

@ClearTracks:
  xor     ecx,ecx
  mov     edi,offset Tracks
  mov     ax,type (trackinfo)
  mul     [modinfo.NumTracks]
  mov     cx,ax
  xor     ax,ax
  cld
  rep     stosb
  mov     [BufPtr],eax
  mov     [BufLen],eax
  pop     edi
  pop     esi
  popad
end;

procedure MixTrack; assembler;
 asm
  cmp     [esi+trackinfo.RepLen],2
  ja      @MixLooped
@MixNonLooped:
  mov     edx,[esi+trackinfo.Samples]
  mov     ebx,[esi+trackinfo.Position]
  mov     ebp,[esi+trackinfo.Len]
  push    edx
  push    esi
  add     ebx,edx
  add     ebp,edx
  mov     edx,[esi+trackinfo.Pitch]
  mov     al,[esi+trackinfo.Volume]
  mul     [modvolume]
  xchg    ah,al
  xor     ah,ah
  mov     esi,ebx
  xor     ebx,ebx
  mov     bh,al
  mov     al,dl
  mov     dl,dh
  xor     dh,dh
@nlMixSamp:
  cmp     esi,ebp
  jae     @nlMixBye
  mov     bl,byte ptr [esi]
  mov     bl,byte ptr [VolTable+ebx]
  add     [edi],bl
  inc     edi
  add     ah,al
  adc     esi,edx
  loop    @nlMixSamp
@nlMixBye:
  mov     ebx,esi
  pop     esi
  pop     edx
  sub     ebx,edx
  mov     [esi+trackinfo.Position],ebx
  jmp     @Salida

@MixLooped:
  mov     edx,[esi+trackinfo.Samples]
  mov     ebx,[esi+trackinfo.Position]
  mov     ebp,[esi+trackinfo.RepLen]
  mov     [BufRep],ebp
  add     ebp,[esi+trackinfo.Repeaat]
  push    edx
  push    esi
  add     ebx,edx
  add     ebp,edx
  mov     edx,[esi+trackinfo.Pitch]
  mov     al,[esi+trackinfo.Volume]
  mul     [modvolume]
  xchg    ah,al
  xor     ah,ah
  mov     esi,ebx
  xor     ebx,ebx
  mov     bh,al
  mov     al,dl
  mov     dl,dh
  xor     dh,dh
@lpMixSamp:
  cmp     esi,ebp
  jb      @lpMixNow
  sub     esi,[BufRep]
@lpMixNow:
  mov     bl,[esi]
  mov     bl,byte ptr [VolTable+ebx]
  add     [edi],bl
  inc     edi
  add     ah,al
  adc     esi,edx
  loop    @lpMixSamp
@lpMixBye:
  mov     ebx,esi
  pop     esi
  pop     edx
  sub     ebx,edx
  mov     [esi+trackinfo.Position],ebx
@Salida:
 end;

procedure GetTrack; assembler;
 asm
  push    ecx
  xor     eax,eax
  xor     ebx,ebx
  mov     ax,word ptr [esi]
  xchg    al,ah
  mov     bl,ah
  and     ah,0Fh
  mov     ecx,eax     {cx=periodo}
  mov     ax,word ptr [esi+2]
  add     esi,4
  xchg    al,ah
  mov     bh,ah
  and     ah,0Fh
  mov     edx,eax     {dx=effect dh=effect dl=parameter}
  mov     [edi+trackinfo.Effect],edx
  and     bl,0F0h
  shr     bh,4
  or      bl,bh     {bx=sample number}
  je      @SetPeriod

@SetSample:
  xor     bh,bh
  mov     byte ptr [edi+trackinfo.num],bl
  dec     ebx
  shl     ebx,2
  mov     eax,dword ptr [modinfo.SampVol+ebx]
  mov     [edi+TrackInfo.Volume],al
  mov     eax,dword ptr [modinfo.Sampaddr+ebx]
  mov     [edi+TrackInfo.Samples],eax
  mov     eax,dword ptr [modinfo.SampLen+ebx]
  mov     [edi+TrackInfo.Len],eax
  mov     eax,dword ptr [modinfo.SampRep+ebx]
  mov     [edi+TrackInfo.Repeaat],eax
  mov     eax,dword ptr [modinfo.SampRepLen+ebx]
  mov     [edi+TrackInfo.RepLen],eax
@SetPeriod:
  test    ecx,ecx
  je      @SetEffect

  mov     [edi+TrackInfo.PortTo],ecx
  cmp     dh,03h    {tone portamento}
  je      @SetEffect

  mov     [edi+TrackInfo.Period],ecx
  mov     ebx,ecx
{ barra
  shr     ecx,3
  cmp     ecx,[edi+TrackInfo.barra]
  jb      @no
  mov     [edi+TrackInfo.barra],ecx
@no:
// barra end }
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     [edi+TrackInfo.Pitch],eax
  mov     [edi+TrackInfo.Position],0

@SetEffect:
  test    edx,edx
  je      @InitNone
  cmp     dh,00h
  je      @InitArpeggio
  cmp     dh,03h
  je      @InitTonePortamento
  cmp     dh,04h
  je      @InitVibrato
  cmp     dh,7
  je      @InitTremolo
  cmp     dh,09h
  je      @SampleOfs
  cmp     dh,0Bh
  je      @PosJump
  cmp     dh,0Ch
  je      @SetVolume
  cmp     dh,0Dh
  je      @Break
  cmp     dh,0Fh
  je      @SetSpeed
@InitNone:
  jmp     @Salida

@InitTonePortamento:  {3 TonePortamento}
  test    dl,dl
  jne     @SetPortParm
  mov     dl,[edi+TrackInfo.PortParm]
@SetPortParm:
  mov     [edi+TrackInfo.PortParm],dl
  mov     [edi+TrackInfo.Effect],edx
  jmp     @Salida

@InitVibrato:         {4 Vibrato}
  mov     al,[edi+TrackInfo.VibParm]
  mov     ah,al
  and     ax,0F00Fh
  test    dl,0Fh
  jne     @OkDepth
  or      dl,al
@OkDepth:
  test    dl,0F0h
  jne     @OkRate
  or      dl,ah
@OkRate:
  mov     [edi+TrackInfo.VibParm],dl
  mov     [edi+TrackInfo.Effect],edx
  test    ecx,ecx
  je      @OkPos
  mov     [edi+TrackInfo.VibPos],0
@OkPos:
  jmp     @Salida

@InitTremolo:       {7 Tremolo}
  mov     al,[edi+TrackInfo.TremParm]
  mov     ah,al
  and     eax,0F00Fh
  test    dl,0Fh
  jne     @tremolo1
  or      dl,al
@tremolo1:
  test    dl,0F0h
  jne     @tremolo2
  or      dl,ah
@tremolo2:
  mov     [edi+TrackInfo.TremParm],dl
  mov     [edi+TrackInfo.Effect],edx
  jmp     @salida

@SampleOfs:      {9 SampleOffset}
  test    dl,dl
  jne     @SetSampleOfs
  mov     dl,[edi+TrackInfo.OldSampOfs]
@SetSampleOfs:
  mov     [edi+TrackInfo.OldSampOfs],dl
  mov     dh,dl
  xor     dl,dl
  mov     [edi+TrackInfo.Position],edx
  jmp     @Salida

@PosJump:        {B PositionJump}
  mov     [OrderPos],dl
  mov     [Row],64
  jmp     @Salida

@SetVolume:      {C Set Volume}
  cmp     dl,64
  jbe     @OkVol
  mov     dl,64
@OkVol:
  mov     [edi+TrackInfo.Volume],dl
  jmp     @Salida

@Break:         {D PatternBreak}
  mov     dh,dl
  and     dl,0Fh
  shr     dh,4
  add     dh,dh
  add     dl,dh
  shl     dh,2
  add     dl,dh
  mov     [BreakRow],dl
  mov     [Row],64
  jmp     @Salida

@SetSpeed:     {F Set Speed}
  test    dl,dl
  je      @Salida
  cmp     dl,20h
  jae     @SetBpm
@SetTempo:
  mov     [Tempo],dl
  mov     [TempoWait],dl
  jmp     @Salida
@SetBpm:
  mov     [Bpm],dl
  mov     al,103
  mul     dl
  mov     bl,ah
  xor     bh,bh
  mov     eax,[MixSpeed]
  xor     edx,edx
  div     ebx
  cmp     stereo,false
  je      @nostereo
  shl     eax,1
@nostereo:
  mov     [BpmSamples],eax
  jmp     @Salida

@InitArpeggio:  {0 Arpeggio}
  test    dl,dl
  je      @salida
  mov     dh,dl
  and     dl,0Fh
  shr     dh,4
  mov     ecx,7*12
  xor     ebx,ebx
  mov     eax,dword ptr [edi+TrackInfo.Period]
@ScanPeriod:
  cmp     eax,dword ptr [PeriodTable+ebx]
  jae     @SetArp
  add     ebx,4
  loop    @ScanPeriod
@SetArp:
  shl     edx,2
  add     dh,bl
  add     dl,bl
  mov     ebx,dword ptr [PeriodTable+ebx]
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     dword ptr [edi+TrackInfo.Arp],eax
  mov     bl,dh
  xor     bh,bh
  mov     ebx,dword ptr [PeriodTable+ebx]
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     dword ptr [edi+TrackInfo.Arp+4],eax
  mov     bl,dl
  xor     bh,bh
  mov     ebx,dword ptr [PeriodTable+ebx]
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     dword ptr [edi+TrackInfo.Arp+8],eax
  mov     [edi+TrackInfo.ArpIndex],0
@Salida:
  pop     ecx
 end;

procedure BeatTrack; assembler;
 asm
  mov     edx,[edi+trackinfo.Effect]
  test    edx,edx
  je      @None
  cmp     dh,00h
  je      @Arpeggio
  cmp     dh,01h
  je      @PortUp
  cmp     dh,02h
  je      @PortDown
  cmp     dh,03h
  je      @TonePortamento
  cmp     dh,04h
  je      @Vibrato
  cmp     dh,05h
  je      @ToneSlide
  cmp     dh,06h
  je      @VibSlide
  cmp     dh,07h
  je      @Tremolo
  cmp     dh,0Ah
  je      @VolSlide
  cmp     dh,$E
  je      @cmisc
@None:
  jmp     @Salida

@cmisc:
  mov     dh,dl
  shr     dh,4
  and     dl,0Fh
  cmp     dh,1
  je      @FinePortaUp
  cmp     dh,2
  je      @FinePortaDown
  cmp     dh,$A
  je      @VolumeFineUp
  cmp     dh,$B
  je      @VolumeFineDown
  jmp     @Salida

@Arpeggio:       {0 Arpeggio}
  test    dl,dl
  je      @salida
  mov     ebx,[edi+TrackInfo.ArpIndex]
  mov     eax,dword ptr [edi+TrackInfo.Arp+ebx]
  mov     [edi+TrackInfo.Pitch],eax
  add     ebx,4
  cmp     ebx,12
  jb      @SetArpIndex
  xor     ebx,ebx
@SetArpIndex:
  mov     [edi+TrackInfo.ArpIndex],ebx
  jmp     @salida

@PortUp:         {1 Portamento Up}
  xor     dh,dh
  and     dl,Mt_LowMask
  mov     Mt_LowMask,$ff
  mov     ebx,[edi+TrackInfo.Period]
  sub     ebx,edx
  cmp     ebx,28
  jge     @NotSmall
  mov     ebx,28
@NotSmall:
  mov     [edi+TrackInfo.Period],ebx
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     [edi+TrackInfo.Pitch],eax
  jmp     @salida

@FinePortaUp:    {E1 FineSlide Up}
  cmp     TempoWait,5
  jne     @Salida
  mov     Mt_LowMask,$0f
  jmp     @PortUp

@PortDown:       {2 Portamento Down}
  xor     dh,dh
  and     dl,Mt_LowMask
  mov     Mt_LowMask,$ff
  mov     ebx,[edi+TrackInfo.Period]
  add     ebx,edx
  cmp     ebx,3424
  jle     @NotBig
  mov     ebx,3424
@NotBig:
  mov     [edi+TrackInfo.Period],ebx
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     [edi+TrackInfo.Pitch],eax
  jmp     @salida

@FinePortaDown:  {E2 FineSlide Down}
  cmp     TempoWait,5
  jne     @Salida
  mov     Mt_LowMask,$0f
  jmp     @PortDown

@TonePortamento: {3 TonePortamento}
  xor     dh,dh
  mov     eax,[edi+TrackInfo.PortTo]
  mov     ebx,[edi+TrackInfo.Period]
  cmp     ebx,eax
  je      @Salida
  jg      @PortToUp
@PortToDown:
  add     ebx,edx
  cmp     ebx,eax
  jle     @SetPort
@FixPort:
  mov     ebx,eax
  jmp     @SetPort
@PortToUp:
  sub     ebx,edx
  cmp     ebx,eax
  jl      @FixPort
@SetPort:
  mov     [edi+TrackInfo.Period],ebx
  shl     ebx,2
  mov     eax,dword ptr [PitchTable+ebx]
  mov     [edi+TrackInfo.Pitch],eax
  jmp     @salida

@Vibrato:        {4 Vibrato}
  mov     dh,dl
  and     edx,0F00Fh
  shr     dh,2
  mov     bl,byte ptr [edi+TrackInfo.VibPos]
  add     [edi+TrackInfo.VibPos],dh
  mov     dh,bl
  shr     bl,2
  and     ebx,1Fh
  mov     al,byte ptr [SinTable+ebx]
  mul     dl
  and     eax,0ffffh
  shr     eax,7
  test    dh,dh
  jge     @efxvibrato2
  neg     eax
@efxvibrato2:
  add     eax,[edi+TrackInfo.Period]
  mov     ebx,eax
  cmp     ebx,28
  jge     @efxvibrato3
  mov     ebx,28
@efxvibrato3:
  cmp     ebx,3424
  jle     @efxvibrato4
  mov     ebx,3424
@efxvibrato4:
  mov     eax,dword ptr [PitchTable+ebx*4]
  mov     [edi+TrackInfo.Pitch],eax
  jmp     @salida

@ToneSlide:      {5 ToneP + VolSlide}
  mov     dh,dl
  and     dl,0Fh
  mov     al,[edi+TrackInfo.Volume]
  shr     dh,4
  je      @efxvolslidef01
  add     al,dl
  cmp     al,64
  jle     @efxvolslidef11
  mov     al,64
@efxvolslidef11:
  mov     [edi+TrackInfo.Volume],al
  jmp     @salidavolslide
@efxvolslidef01:
  sub     al,dl
  jge     @efxvolslidef21
  xor     al,al
@efxvolslidef21:
  mov     [edi+TrackInfo.Volume],al
@salidavolslide:
  mov     dl,[edi+TrackInfo.PortParm]
  jmp     @TonePortamento

@VibSlide:       {6 Vibra + VolSlide}
  mov     dh,dl
  and     dl,0Fh
  mov     al,[edi+TrackInfo.Volume]
  shr     dh,4
  je      @efxvolslidef02
  add     al,dl
  cmp     al,64
  jle     @efxvolslidef12
  mov     al,64
@efxvolslidef12:
  mov     [edi+TrackInfo.Volume],al
  jmp     @salidavolslide1
@efxvolslidef02:
  sub     al,dl
  jge     @efxvolslidef22
  xor     al,al
@efxvolslidef22:
  mov     [edi+TrackInfo.Volume],al
@salidavolslide1:
  mov     dl,[edi+TrackInfo.VibParm]
  jmp     @Vibrato

@Tremolo:        {7 Tremolo}
  mov     dh,dl
  and     dx,0F00Fh
  shr     dh,2
  mov     bl,[edi+TrackInfo.TremPos]
  add     [edi+TrackInfo.TremPos],dh
  mov     dh,bl
  shr     bl,2
  and     ebx,1Fh
  mov     al,byte ptr [ebx+SinTable]
  mul     dl
  shr     eax,6
  test    dh,dh
  jge     @efxtremolo2
  neg     eax
@efxtremolo2:
  add     al,[edi+TrackInfo.Volume]
  jge     @efxtremolo3
  xor     al,al
@efxtremolo3:
  cmp     al,64
  jle     @efxtremolo4
  mov     al,64
@efxtremolo4:
  mov     [edi+TrackInfo.Volume],al
  jmp     @salida

@VolumeFineDown:  {EB FineVol Down}
  cmp     TempoWait,5
  jne     @salida
  mov     al,[edi+TrackInfo.Volume]
  jmp     @efxvolslidef0

@VolumeFineUp:   {EA FineVol Up}
  cmp     TempoWait,5
  jne     @salida
  jmp     @VolSlide

@VolSlide:       {9 VolumeSlide}
  mov     al,[edi+TrackInfo.Volume]
  mov     dh,dl
  shr     dl,4
  je      @efxvolslidef0
  add     al,dl
  cmp     al,64
  jle     @efxvolslidef1
  mov     al,64
@efxvolslidef1:
  mov     [edi+TrackInfo.Volume],al
  jmp     @salida
@efxvolslidef0:
  sub     al,dh
  jge     @efxvolslidef2
  xor     al,al
@efxvolslidef2:
  mov     [edi+TrackInfo.Volume],al
@salida:
 end;

procedure UpdateTracks; assembler;
 asm
  dec     [TempoWait]
  je      @GetTracks

@BeatTracks:
  mov     ecx,modinfo.Numtracks
  mov     edi,offset tracks
@loop1:
  call    BeatTrack
  add     edi,type (trackinfo)
  loop    @loop1
  jmp     @Salida

@GetTracks:
  mov     al,[Tempo]
  mov     [TempoWait],al

  mov     esi,[Note]
  cmp     [Row],64
  jb      @NoPattWrap

  lea     esi,[modinfo.Patterns]
  xor     ebx,ebx
  mov     bl,[OrderPos]
  cmp     bl,[modinfo.OrderLen]
  jb      @NoOrderWrap
  mov     bl,[modinfo.ReStart]
  mov     [OrderPos],bl
  cmp     [looping],true
  je      @loop
  mov     [PlayingMod],false
@loop:
  cmp     bl,[modinfo.OrderLen]
  jae     @NoUpdate
@NoOrderWrap:
  mov     bl,byte ptr [modinfo.Order+ebx]
  shl     ebx,2
  add     esi,ebx
  mov     esi,[esi]
  mov     bl,[BreakRow]
  mov     [Row],bl
  xor     bh,bh
  mov     [BreakRow],bh
  shl     ebx,4
  add     esi,ebx
  mov     [note],esi
  inc     [OrderPos]
@NoPattWrap:
  inc     [Row]

  cld
  mov     ecx,modinfo.Numtracks
  mov     edi,offset tracks
@loop2:
  call    GetTrack
  add     edi,type (trackinfo)
  loop    @loop2
  mov     [note],esi
@NoUpdate:
@Salida:
 end;


procedure getsamples (var buffer; count, desp : dword); assembler;
 asm
  pushad
  cld
  mov     edi,Buffer
  add     edi,desp
  mov     ebx,Count
@NextChunk:
  cmp     [BufLen],0
  jne     @CopyChunk
  push    ebx
  push    edi
@MixChunk:
  mov     edi,offset [MixBuffer]
  mov     ecx,[BpmSamples]
  mov     [BufPtr],edi
  mov     [BufLen],ecx
  mov     al,80h
  rep     stosb
  cmp     playingmod,false
  je      @nomod
  mov     ecx,[modinfo.numtracks]
  mov     esi,offset tracks
@loop1:
  push    ecx
  mov     edi,[bufptr]
  mov     ecx,[buflen]
  call    mixtrack
  pop     ecx
  add     esi,type (trackinfo)
  loop    @loop1
  call    UpdateTracks
@nomod:
  pop     edi
  pop     ebx
@CopyChunk:
  mov     ecx,[BufLen]
  cmp     ecx,ebx
  jbe     @MoveChunk
  mov     ecx,ebx

@MoveChunk:
  mov     esi,[BufPtr]
  add     [BufPtr],ecx
  sub     [BufLen],ecx
  sub     ebx,ecx
  rep     movsb
  test    ebx,ebx
  jne     @NextChunk
  popad
 end;

procedure MixStereoTrack; assembler;
 asm
  cmp     [esi+trackinfo.RepLen],2
  ja      @MixLooped
@MixNonLooped:
  mov     edx,[esi+trackinfo.Samples]
  mov     ebx,[esi+trackinfo.Position]
  mov     ebp,[esi+trackinfo.Len]
  push    edx
  push    esi
  add     ebx,edx
  add     ebp,edx
  mov     edx,[esi+trackinfo.Pitch]
  mov     al,[esi+trackinfo.Volume]
  mul     [modvolume]
  xchg    ah,al
  xor     ah,ah
  mov     esi,ebx
  xor     ebx,ebx
  mov     bh,al
  mov     al,dl
  mov     dl,dh
  xor     dh,dh
@nlMixSamp:
  cmp     esi,ebp
  jae     @nlMixBye
  mov     bl,byte ptr [esi]
  mov     bl,byte ptr [VolTable+ebx]
  add     [edi],bl
  add     edi,2
  add     ah,al
  adc     esi,edx
  loop    @nlMixSamp
@nlMixBye:
  mov     ebx,esi
  pop     esi
  pop     edx
  sub     ebx,edx
  mov     [esi+trackinfo.Position],ebx
  cmp     ebx,[esi+trackinfo.len]
  jne     @salida
  mov     byte ptr [esi+trackinfo.num],0
  jmp     @Salida

@MixLooped:
  mov     edx,[esi+trackinfo.Samples]
  mov     ebx,[esi+trackinfo.Position]
  mov     ebp,[esi+trackinfo.RepLen]
  mov     [BufRep],ebp
  add     ebp,[esi+trackinfo.Repeaat]
  push    edx
  push    esi
  add     ebx,edx
  add     ebp,edx
  mov     edx,[esi+trackinfo.Pitch]
  mov     al,[esi+trackinfo.Volume]
  mul     [modvolume]
  xchg    ah,al
  xor     ah,ah
  mov     esi,ebx
  xor     ebx,ebx
  mov     bh,al
  mov     al,dl
  mov     dl,dh
  xor     dh,dh
@lpMixSamp:
  cmp     esi,ebp
  jb      @lpMixNow
  sub     esi,[BufRep]
@lpMixNow:
  mov     bl,[esi]
  mov     bl,byte ptr [VolTable+ebx]
  add     [edi],bl
  add     edi,2
  add     ah,al
  adc     esi,edx
  loop    @lpMixSamp
@lpMixBye:
  mov     ebx,esi
  pop     esi
  pop     edx
  sub     ebx,edx
  mov     [esi+trackinfo.Position],ebx
@Salida:
 end;

procedure getstereosamples (var buffer; count, desp : longint); assembler;
 asm
  pushad
  cld
  mov     edi,Buffer
  add     edi,desp
  mov     ebx,Count
@NextChunk:
  cmp     [BufLen],0
  jne     @CopyChunk
  push    ebx
  push    edi
@MixChunk:
  mov     edi,offset [MixBuffer]
  mov     ecx,[BpmSamples]
  mov     [BufPtr],edi
  mov     [BufLen],ecx
  mov     al,80h
  rep     stosb
  cmp     playingmod,false
  je      @nomod

  mov     esi,offset tracks
  mov     ecx,modinfo.numtracks
@1:
  push    ecx
  mov     edi,[bufptr]
  add     edi,[flag]
  mov     ecx,[buflen]
  shr     ecx,1
  call    MixStereoTrack
  add     esi,type (trackinfo)
  inc     flag
  cmp     flag,2
  jne     @sigue
  mov     flag,0
@sigue:
  pop     ecx
  loop    @1
  call    UpdateTracks
@nomod:
  pop     edi
  pop     ebx
@CopyChunk:
  mov     ecx,[BufLen]
  cmp     ecx,ebx
  jbe     @MoveChunk
  mov     ecx,ebx

@MoveChunk:
  mov     esi,[BufPtr]
  add     [BufPtr],ecx
  sub     [BufLen],ecx
  sub     ebx,ecx
  rep     movsb
  test    ebx,ebx
  jne     @NextChunk
  popad
 end;

procedure TSoundSystem.PlayModule(fula : TMod);
 begin
  if not (fExistSound and fMusic) then exit;
  stopmodule;
  fModInfo^ := fula;
  fInitModVars;
  fPlayingMod^ := true;
 end;

procedure TSoundSystem.UpdateSaveMusic(Save : TSave);
 begin
  with Save do
   begin
    fSaveMusic := Music;
    fSaveEffect := Effect;
   end;
 end;

procedure TSoundSystem.RestoreSaveMusic;
 begin
  fMusic := fSaveMusic;
  fEffect := fSaveEffect;
 end;

procedure TSoundSystem.StopModule;
 begin
  if not (fExistSound) then exit;
  fPlayingMod^ := false;
 end;

constructor TSoundSystem.Create(Owner : TComponent);
 var
  BufferDesc: TDSBufferDesc;
  WaveFormatEx : TWaveFormatEx;
 begin
  fInitModVars := initmodvars;
  fPlayingMod := @PlayingMod;
  fModInfo := @modinfo;
  fMusic := false;
  fEffect := false;
  fExistSound := true;
  first := 0;
  flag := 0;
  stereo := true; // Estereo
  initmodvars;
  try
   fDXSound := TDXSound.Create(Owner);
   fDXSound.Options := [soPriority];
   fDXSound.Initialize;
   SoundBuffer := TDirectSoundBuffer.Create(fDXSound.DSound);
   with WaveFormatEx do
    begin
     wFormatTag := 1;                                //PCM
     nChannels := byte(Stereo)+1;                    // 1 mono 2 stereo
     nSamplesPerSec := MixSpeed;
     nAvgBytesPerSec := MixSpeed*(byte(Stereo)+1); // samplerate mono samplerate*2 stereo
     nBlockAlign := byte(Stereo)+1;                  // 1 mono 2 stereo
     wBitsPerSample := 8;
     cbSize := sizeof(TModWaveFormatEx);
    end;
   ZeroMemory(@BufferDesc, SizeOf(BufferDesc));
   BufferDesc.dwSize := sizeof ( TDSBUFFERDESC ) ;
   BufferDesc.dwFlags := DSBCAPS_STATIC + DSBCAPS_CTRLDEFAULT;
   BufferDesc.dwBufferBytes := mixbufsize; // mixbuff
   BufferDesc.lpwfxFormat := @WaveFormatEx;
   SoundBuffer.CreateBuffer(BufferDesc);
   SoundBuffer.Play(True);
   fTimerThread := TTimerThread.Create(Self, False);
  except
   fExistSound := false;
   exit;
  end;
  fMusic := true;
  fEffect := true;
 end;

destructor TSoundSystem.Destroy;
 begin
  if assigned(FTimerThread) then
   begin
    while FTimerThread.Suspended do FTimerThread.Resume;
    FTimerThread.Terminate;
   end;
  StopModule;
  SoundBuffer.Stop;
  SoundBuffer.Free;
  SoundBuffer := nil;
  fDXSound.Finalize;
  fDXSound.Free;
  inherited Destroy;
 end;

procedure TSoundSystem.Timer;
var
 ReadPos : DWord;
 Data1, Data2: PChar;
 Data1Size, Data2Size: Longint;
 begin
  if not fExistSound then exit;
  ReadPos := SoundBuffer.Position;
  SoundBuffer.Lock(0,mixbufsize, Pointer(Data1), Data1Size, Pointer(Data2),Data2Size);
  if (ReadPos > mixbufsize div 2) and (first = 0) then
   begin
    first := ReadPos;
    if stereo then
     GetStereoSamples (data1^,ReadPos,0)
      else
     GetSamples (data1^,ReadPos,0);
   end;
  if (ReadPos < mixbufsize div 2) and (first <> 0) then
   begin
    if Stereo then
     GetStereoSamples (data1^,(mixbufsize-first),first)
      else
     GetSamples (data1^,(mixbufsize-first),first);
    first := 0;
   end;
  SoundBuffer.UnLock;
 end;


///////////////////////////////////////

constructor TSoundLibrary.Create(FileName : string; SoundSystem : TSoundSystem);
 begin
  fLibrary := false;
  fSoundSystem := SoundSystem;
  if not SoundSystem.ExistSound then exit;
  try
   fLibStream := TFileStream.Create(Filename,fmOpenRead);
   fLibStream.Read(fLibHead,sizeof(TSndLib));
   if CompareStr(libIDString,StrPas(fLibHead.libID)) <> 0 then raise SoundException.Create('Invalid Sound Library');
  except
   raise SoundException.Create(format('Error abriendo la librería de sonido %s',[FileName]));
  end;
  fLibrary := true;
 end;

constructor TSoundLibrary.Create(SoundSystem : TSoundSystem);
 begin
  fSoundSystem := SoundSystem;
  fLibrary := false;
 end;


destructor TSoundLibrary.Destroy;
 begin
  fLibStream.Free;
  inherited Destroy;
 end;

function TSoundLibrary.Swap(j : dword) : dword; assembler;
 asm
  mov  eax,edx
  xchg al,ah
  shl  eax,1
 end;

procedure TSoundLibrary.LoadModFromStream(Stream : TStream;var modvars : TMod);
var
 i,j : integer;
 id  : string;
 Header : ModHeader;
 begin
  if not fSoundSystem.ExistSound then exit;
  fillchar (modvars,sizeof(modvars),0);
  Stream.read (header,sizeof(modheader));
  with header do
   begin
    setlength (id,4);
    move (mhsign,id[1],4);
    if (mhsign = idMK) or (mhsign = idFLT4) or
       (mhsign = id4CHN) or (mhsign = idMK1) then modvars.numtracks := 4
     else
     if mhsign = id8CHN then modvars.numtracks := 8
      else
     if mhsign = id6CHN then modvars.numtracks := 6
      else exit;
    modvars.OrderLen := mhOrderLen;
    if mhReStart < mhOrderLen then modvars.ReStart := mhReStart
     else modvars.ReStart := 0;
    j := 0;
    for i := 1 to 128 do
     begin
      modvars.order[i] := mhorder[i];
      if mhorder[i] >= j then j := mhorder[i];
     end;
    modvars.patnum := succ(j);
    for i := 1 to succ(j) do
     begin
      getmem (modvars.patterns[i],256*modvars.numtracks);
      try
       Stream.read (modvars.patterns[i]^,256*modvars.numtracks);
      except
       FreeModule(modvars);
      end;
     end;
    for i := 1 to 31 do
     begin
      j := mhsamples[i].msLength;
      j := Swap(j);
      modvars.SampLen[i] := j;
      modvars.SampVol[i] := mhsamples[i].msvolume div 2;
      j := mhsamples[i].msRepeat;
      j := Swap(j);
      modvars.SampRep[i] := j;
      j := mhsamples[i].msRepLen;
      j := Swap(j);
      modvars.SampRepLen[i] := j;
     end;
    for i := 1 to 31 do
     begin
      if modvars.samplen[i] = 0 then continue;
      getmem (modvars.Sampaddr[i],modvars.SampLen[i]);
      try
       Stream.read (modvars.Sampaddr[i]^,modvars.samplen[i]);
      except
       FreeModule(modvars);
      end
     end;
   end;
 end;

procedure TSoundLibrary.LoadModFromFile(FileName : string; var ModVars : TMod);
var
 FileStream : TFileStream;
 begin
  if not fSoundSystem.ExistSound then exit;
  try
   FileStream := TFileStream.Create(FileName,fmOpenRead);
   LoadModFromStream(FileStream,ModVars);
   FileStream.Free;
  except
   raise SoundException.Create(format('Error cargando el Modulo %s',[FileName]));
  end;
 end;

procedure TSoundLibrary.LoadModFromLibrary(Index : integer; var ModVars : TMod);
 var
  ind : integer;
  snd : TSndLibSound;
 begin
  if not (fSoundSystem.ExistSound and fLibrary) then exit;
  fLibStream.Seek(sizeof(TSndLib),soFromBeginning);
  for ind := 0 to fLibHead.WaveCount+fLibHead.ModuleCount-1 do
   begin
    fLibStream.Read(snd,sizeof(TSndLibSound));
    if Index = ind then
     if snd.SoundType = tsMod then
      begin
       try
        LoadModFromStream(fLibStream,ModVars);
       except
        raise SoundException.Create('Error cargando modulo');
       end;
       break;
      end else raise SoundException.Create('Indice válido pero no es modulo de sonido')
     else fLibStream.Seek(snd.Size,soFromCurrent);
   end;
 end;

procedure TSoundLibrary.FreeModule(var modvars : TMod);
var
 i : word;
 begin
  if not fSoundSystem.ExistSound then exit;
  for i := 1 to modvars.patnum do
   if assigned(modvars.patterns[i]) then freemem (modvars.patterns[i]);
  for i := 1 to 31 do
   begin
    if modvars.samplen[i] = 0 then continue;
    if assigned(modvars.sampaddr[i]) then freemem (modvars.sampaddr[i]);
   end;
  fillchar (modvars,sizeof(modvars),0);
 end;

procedure TSoundLibrary.LoadWaveFromLibrary(Index : integer; var Wave : TEngine);
 var
  ind : integer;
  snd : TSndLibSound;
 begin
  if not (fSoundSystem.ExistSound and fLibrary) then exit;
  fLibStream.Seek(sizeof(TSndLib),soFromBeginning);
  for ind := 0 to fLibHead.WaveCount+fLibHead.ModuleCount-1 do
   begin
    fLibStream.Read(snd,sizeof(TSndLibSound));
    if Index = ind then
     if snd.SoundType = tsWav then
      begin
       Wave.EffectStream(fLibStream,Index);
       break;
      end else
    else fLibStream.Seek(snd.Size,soFromCurrent);
   end;
 end;

procedure TSoundLibrary.LoadWaveFromLibrary(Index : integer; var Wave : TWavLib);
 var
  ind : integer;
  snd : TSndLibSound;
 begin
  if not (fSoundSystem.ExistSound and fLibrary) then exit;
  fLibStream.Seek(sizeof(TSndLib),soFromBeginning);
  for ind := 0 to fLibHead.WaveCount+fLibHead.ModuleCount-1 do
   begin
    fLibStream.Read(snd,sizeof(TSndLibSound));
    if Index = ind then
     if snd.SoundType = tsWav then
      begin
       Wave := TWavLib.Create(fSoundSystem,fLibStream,fLibStream.Position);
      end else
    else fLibStream.Seek(snd.Size,soFromCurrent);
   end;
 end;

//////////////////////////////////////////

constructor TWavLib.Create(SoundSystem : TSoundSystem; Stream : TStream; Offset : dword);
 begin
  fStream := Stream;
  fOffset := Offset;
  fSoundSystem := SoundSystem;
  fSoundSystem.DirectSound.RegisterNotifyEvent(NotifyEventSound);
 end;

destructor TWavLib.Destroy;
 begin
  if fSoundSystem.DirectSound <> nil then fSoundSystem.DirectSound.UnRegisterNotifyEvent(NotifyEventSound);
 end;

procedure TWavLib.NotifyEventSound(Sender: TCustomDXSound; NotifyType: TDXSoundNotifyType);
 begin
  case NotifyType of
   dsntDestroying:
     begin
      fSoundSystem.DirectSound := nil;
     end;
   dsntInitialize:
     begin
      fDirectSoundBuffer := TDirectSoundBuffer.Create(fSoundSystem.DirectSound.DSound);
     end;
   dsntFinalize:
     begin
      fDirectSoundBuffer.Stop;
      fDirectSoundBuffer.Free;
      fDirectSoundBuffer := nil;
     end;
   dsntRestore:
     begin
      fStream.Seek(fOffset,soFromBeginning);
      fDirectSoundBuffer.LoadFromStream(fStream);
     end;
  end;
 end;

procedure TWavLib.Play;
 begin
  if (fSoundSystem.DirectSound <> nil) and (fSoundSystem.Effect) then
   if not fDirectSoundBuffer.Playing then fDirectSoundBuffer.Play;
 end;

procedure TWavLib.PlayLoop;
 begin
  if (fSoundSystem.DirectSound <> nil) and (fSoundSystem.Effect) then
   if not fDirectSoundBuffer.Playing then fDirectSoundBuffer.Play(True);
 end;

function TWavLib.Playing;
 begin
  result := false;
  if (fSoundSystem.DirectSound <> nil) and (fSoundSystem.Effect) then result := fDirectSoundBuffer.Playing;
 end;

procedure TWavLib.Stop;
 begin
  if (fSoundSystem.DirectSound <> nil) then fDirectSoundBuffer.Stop;
 end;

////////////////////////////////////////////////

{  TEngine  }

constructor TEngine.Create(SoundSystem : TSoundSystem);
begin
  inherited Create;
  fSoundSystem := SoundSystem;
  if not fSoundSystem.ExistSound then exit;
  fEffectList := TList.Create;
  fTimer := TTimer.Create(nil);
  fTimer.Interval := 500;
  fTimer.OnTimer := TimerEvent;
  fTimer.Enabled := true;
end;

destructor TEngine.Destroy;
begin
 if fSoundSystem.ExistSound then
  begin
   Clear;
   fTimer.Free;
   fEffectList.Free;
  end; 
  inherited Destroy;
end;

procedure TEngine.Clear;
var
  i: Integer;
begin
  if not fSoundSystem.ExistSound then exit;
  for i:=EffectCount-1 downto 0 do
   begin
    POptionsEngine(fEffectList[i])^.DSBuffer.Free;
    FreeMem(fEffectList[i]);
   end;
  FEffectList.Clear;
end;

procedure TEngine.EffectFile(const Filename: string; mID : Integer);
var
  Stream : TFileStream;
begin
  if not fSoundSystem.ExistSound then exit;
  Stream :=TFileStream.Create(Filename, fmOpenRead);
  try
    EffectStream(Stream,mID);
  finally
    Stream.Free;
  end;
end;

procedure TEngine.EffectStream(Stream: TStream; mID : Integer);
var
  Wave: TWave;
begin
  if not fSoundSystem.ExistSound then exit;
  Wave := TWave.Create;
  try
    Wave.LoadfromStream(Stream);
    EffectWave(Wave,mID);
  finally
    Wave.Free;
  end;
end;

procedure TEngine.EffectWave(Wave: TWave; mID : Integer);
 var
  p : POptionsEngine;
begin
 if not fSoundSystem.ExistSound then exit;
 getmem(p,sizeof(TOptionsEngine));
 with p^ do
  begin
   ID := mID;
   DSBuffer := TDirectSoundBuffer.Create(fSoundSystem.DirectSound.DSound);
   try
    DSBuffer.LoadFromWave(Wave);
   except
   end;
   Active := False;
  end;
 fEffectList.Add(p);
end;

function TEngine.GetEffect(Index: Integer): TDirectSoundBuffer;
begin
  result := nil;
  if not fSoundSystem.ExistSound then exit;
  Result := POptionsEngine(FEffectList[Index])^.DSBuffer;
end;

function TEngine.GetEffectCount: Integer;
begin
 result := -1;
 if not fSoundSystem.ExistSound then exit;
 Result := FEffectList.Count;
end;

procedure TEngine.TimerEvent(Sender: TObject);
var
  i: Integer;
begin
 for i:=EffectCount-1 downto 0 do
  with POptionsEngine(fEffectList[i])^ do
   if Active and not DSBuffer.Playing then
    begin
      DSBuffer.Free;
      FreeMem(fEffectList[i]);
      FEffectList.Delete(i);
    end;
end;

procedure TEngine.SetEffectPlay(mID : Integer; Value : Boolean);
 var
  i : integer;
 begin
  if not fSoundSystem.ExistSound then exit;
  for i := EffectCount-1 downto 0 do
   with POptionsEngine(fEffectList[i])^ do
    begin
     if (mID = ID) then
      if (fSoundSystem.Effect) then
      begin
       Active := True;
       DSBuffer.Play(Value);
       break;
      end
     else
      begin
       DSBuffer.Free;
       FreeMem(fEffectList[i]);
       FEffectList.Delete(i);
       break;
      end;
    end;
 end;

initialization
 makepitchvoltable;
 ModVolume := 210;
end.


