unit CardGames.WinApi.SoundUnit;
//Simple sound demo. David Mayne.
//Dual mode sound system - Win32 and DirectSound.
//What SHOULD happen is that if Direct Sound is available it will play thru that
//else standard Win32. This has not been tested on a system without DirectX.
//Direct Sound uses freeware Bass dll. Go http://www.un4seen.com/bass.html for
//full package. DirectSound has better quality, multiple channels & can play
//music.
interface

uses
  WinApi.MMSystem,//Win32 sound.
  {$IFDEF GLSCENE}
  Sounds.Bass,    //DirectX sound.
  BASS.Import,
  {$ENDIF}
  System.SysUtils
  ;


type
  TBassType =(btSound, btStream);//Only used when stopping Bass sounds.

const
//Bass sound data.
  cNoOfSounds = 2;
  cSounds: array[0..cNoOfSounds-1] of string =
    ('deal.wav', 'drop.wav'
    );
  cNoOfStreams = 1;
  cStreams: array[0..cNoOfStreams-1] of string =
    ('Angelica-Machi.mp3'
    );

var
  BassSound: Boolean = False;//Set true if initialised.
{$IFDEF GLSCENE}
//Bass sound system.
  sams: array[0..29] of HSAMPLE;
  strs: array[0..15] of HSTREAM;
  Bass_Sounded: HSAMPLE;//Handle of last sample played.

//Call once to initialize direct sound with Bass.
procedure InitializeBass(const ASoundPath: string);
{$ENDIF}

//Play named sound. Direct Sound if possible.
//Mode 1 : Asynchronous - method returns after starting sound.
//Mode 2 : Synchronous - method returns after sound has finished playing.
//Mode 3 : Loop - method returns after starting sound in a loop.
//Mode 4 : Sound is played only after a currently playing sound has stopped.
//Mode 5 : Waits W milliseconds before playing sound.
procedure Sound(Name: TFileName; const Mode: Integer = 1;
  const W: Integer = 100);

//Stop sound playing eg a loop. Bass sounds must have a name.
procedure SoundStop(Name: TFileName = ''; Mode: TBassType = btSound);

//Stream music Bass only.
procedure Stream(Name: TFileName; const Mode: Integer = 1);

implementation

{$IFDEF GLSCENE}
uses
  Vcl.Forms;
{$ENDIF}

var
  _SoundPath: string;

{$IFDEF GLSCENE}
Procedure InitializeBass(const ASoundPath: string);
// Initialize audio - default device, 44100hz, stereo, 16 bits
var
  SLoaded: Boolean;
  i: Integer;

  function LoadSam(I: Integer): boolean;
  var
    f: PChar;
    S: string;
  begin
    S :=  _SoundPath + cSounds[i];
    if FileExists(S) then
    begin
      f := PChar(S);
      sams[I] := BASS_SampleLoad(FALSE, f, 0, 0, 3, BASS_SAMPLE_OVER_POS or BASS_UNICODE);
      if sams[I] <> 0 then
        Result := True
      else
        Result := False;
    end
    else
      Result := False;
  end;

  function loadStream(I: Integer): boolean;
  var
    f: PChar;
    S: string;
  begin
    S :=  _SoundPath + cStreams[i];
    f := PChar(S);
    strs[i] := BASS_StreamCreateFile(False, f, 0, 0, BASS_UNICODE);
    if strs[I] <> 0 then
      Result := True
    else
      Result := False;
  end;

begin
  _SoundPath := IncludeTrailingPathDelimiter(ASoundPath);

  if not BASS_Load('bass.dll') then
    raise Exception.Create('Cannot load bass.dll');
	if not BASS_Init(-1, 44100, 0, Application.Handle, nil) then
    BassSound := False
  else
    begin
      BassSound := True;
      SLoaded := False;
      for i := 0 to cNoOfSounds - 1 do
      begin
        if not LoadSam(i) then
          break;
        if i = cNoOfSounds - 1 then
          SLoaded := True;
      end;
      if not SLoaded then
      begin
        BassSound := False;
        exit;
      end
      else
        SLoaded := False;
      for i := 0 to cNoOfStreams - 1 do
      begin
        if not LoadStream(i) then
          break;
        if i = cNoOfStreams - 1 then
          SLoaded := True;
      end;
      if not SLoaded then
        BassSound := False;
    end;
end;
{$ENDIF}

procedure SoundStop(Name: TFileName = ''; Mode: TBassType = btSound);
//Generic stop sound looping. BassSound requires Name + optional type.

  {$IFDEF GLSCENE}
  procedure BassStop(Name: TFileName; Mode: TBassType = btSound);
  //Stop bass channel.
  var
    i: Integer;
  begin
    if not BassSound then exit;
    if Mode = btSound then//Sample.
    begin
      for i := 0 to cNoOfSounds - 1 do
        if SameText(Name, cSounds[i]) then
        begin
          BASS_SampleStop(sams[i]);
          exit;
        end
    end
    else//btStream.
      begin
        for i := 0 to cNoOfStreams - 1 do
          if SameText(Name, cStreams[i]) then
          begin
            BASS_ChannelStop(strs[i]);
            exit;
          end;
      end;
  end;
  {$ENDIF}

begin
  {$IFDEF GLSCENE}
  if BassSound then
    BassStop(Name, Mode)
  else
  {$ELSE}
    PlaySound(Nil, 0, SND_ASYNC );
  {$ENDIF}
end;

procedure Stream(Name: TFileName; const Mode: Integer = 1);
//Mode 1 once, 2 loop.
  {$IFDEF GLSCENE}
var
  i: Integer;
  {$ENDIF}
begin
  if not BassSound then exit;
  {$IFDEF GLSCENE}
  for i := 0 to cNoOfStreams - 1 do
    if SameText(Name, cStreams[i]) then
    begin
      BASS_ChannelSetAttribute(strs[i], BASS_ATTRIB_VOL, 40);
      if Mode = 1 then
        BASS_ChannelFlags(strs[i], 0, BASS_SAMPLE_LOOP)
      else
        BASS_ChannelFlags(strs[i], BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP);
      BASS_ChannelPlay(strs[i], False);
      exit;
    end;
  {$ENDIF}
end;

procedure Sound(Name: TFileName; const Mode: Integer = 1;
  const W: Integer = 100);
//Mode 1 Asynchronous, 2 Synchronous, 3 Asynchronous + loop, 4 async & wait for
//playing to stop first. Mode 5 waits W milliseconds before playing sound.

  {$IFDEF GLSCENE}
  procedure UseBass(Name: TFileName; const Mode: Integer = 1;
    const W: Integer = 100);
  //Bass is used to play the sound. Mode 4 works with last channel used only.
  //W is used with mode 5 only.
  var
    i: Integer;
    ch: HCHANNEL;
  begin
    for i := 0 to cNoOfSounds - 1 do
      if SameText(Name, cSounds[i]) then
      begin
        ch := BASS_SampleGetChannel(sams[i], False);
        BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, 50);
        if Mode = 1 then
          BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP)
        else if Mode = 2 then
            BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP)
          else if Mode = 3 then
            BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
            else if Mode = 4 then
            begin
              BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
              while BASS_ChannelIsActive(Bass_Sounded) = BASS_ACTIVE_PLAYING do
                sleep(0);
            end
              else if Mode = 5 then
              begin
                sleep(W);
                BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
              end;
        BASS_ChannelPlay(ch, False);
        Bass_Sounded := ch;//Last sample played.
        if Mode = 2 then
        repeat
          sleep(0);
        until BASS_ChannelIsActive(ch) = BASS_ACTIVE_STOPPED;
        exit;
      end;
  end;
  {$ENDIF}

begin
  {$IFDEF GLSCENE}
  if BassSound then
    UseBass(Name, Mode, W)
  else
  {$ENDIF}
  begin
    Name := _SoundPath + Name;
    if Mode = 1 then
  //Asynchronous
    begin
      PlaySound(PChar(Name), 0, SND_ASYNC or SND_FILENAME);
  //A slight delay despite being asynchronous helps.
      sleep(25);
    end
    else if Mode = 2 then
  //Synchronous
        PlaySound(PChar(Name), 0, SND_SYNC or SND_FILENAME)
      else if Mode = 3 then
  //Asynchronous & loop.
          PlaySound(PChar(Name), 0, SND_ASYNC or SND_FILENAME or SND_LOOP)
        else if Mode = 4 then
  //Wait for playing to stop before async.
          repeat
            sleep(0);
          until PlaySound(PChar(Name),0, SND_ASYNC or SND_FILENAME or
            SND_NOSTOP)
  //Wait for W milliseconds before playing.
          else
          begin
            sleep(W);
            PlaySound(PChar(Name), 0, SND_ASYNC or SND_FILENAME);
          end;
  end;
end;

end.
