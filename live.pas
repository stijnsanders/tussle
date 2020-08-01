unit live;

interface

uses Windows, SysUtils, Classes;

const
  MaxGames=10000;

type
  TGameData=class;//forward

  TKeyHolder=class(TObject)
  public
    Key:string;
    Game:TGameData; 
    constructor Create;
  end;

  TGameData=class(TObject)
  private
    Field:array[0..9,0..9] of byte;
    Pieces1,Pieces2:array[0..9] of byte;
    State1,State2,AtPlay:integer;
  public
    Key1,Key2,PlayerMsg1,PlayerMsg2:string;
    LastMove:TDateTime;
    constructor Create(const AKey1,AKey2:string);
    procedure AfterConstruction; override;
    procedure Signal1(const Data:UTF8String);
    procedure Signal2(const Data:UTF8String);
  end;

  TGameQueue=class(TObject)
  private
    FLock:TRTLCriticalSection;
    FWaiting:TKeyHolder;
    FGames:array of TGameData;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterFeed(KeyHolder:TKeyHolder);
    procedure ClearFeed(KeyHolder:TKeyHolder);
    function GameByKey(const Key:string):TGameData;
  end;

var
  GameQueue:TGameQueue;

const
  StartCount:array[0..9] of byte=(1,1,8,5,3,2,2,1,1,6);//total:30  

implementation

{ TKeyHolder }

constructor TKeyHolder.Create;
var
  g:TGUID;
  s:string;
begin
  inherited;
  if CreateGUID(g)<>0 then RaiseLastOSError;  
  s:=GUIDToString(g);
  Key:=LowerCase(Copy(s,2,36));
  Game:=nil;
end;

{ TGameQueue }

constructor TGameQueue.Create;
var
  i:integer;
begin
  inherited;
  InitializeCriticalSection(FLock);
  FWaiting:=nil;
  SetLength(FGames,MaxGames);
  for i:=0 to MaxGames-1 do FGames[i]:=nil;
end;

destructor TGameQueue.Destroy;
var
  i:integer;
begin
  //FLock?
  try
    //if FWaiting<>nil then FWaiting.Disconnect;
  except
    //ignore
  end;
  for i:=0 to MaxGames-1 do FreeAndNil(FGames[i]);
  DeleteCriticalSection(FLock);
  inherited;
end;

procedure TGameQueue.RegisterFeed(KeyHolder:TKeyHolder);
var
  gd:TGameData;
  k1,k2:string;
  i:integer;

  function IsLiveGame:boolean;
  begin
    if FGames[i]=nil then
      Result:=false
    else
      try
        if FGames[i].LastMove<Now-1.0/24.0 then
         begin
          FreeAndNil(FGames[i]);
          Result:=true;
         end
        else
          Result:=false;
      except
        //silent (log?)
        FGames[i]:=nil;
        Result:=false;
      end;
  end;

begin
  EnterCriticalSection(FLock);
  try
    if FWaiting=nil then
     begin
      //wait for opponent
      FWaiting:=KeyHolder;
     end
    else
     begin
      //start game

      i:=0;
      while (i<MaxGames) and IsLiveGame do inc(i);

      if i=MaxGames then raise Exception.Create('Max Concurrent Games reached');

      if Random<0.5 then
       begin
        k1:=FWaiting.Key;
        k2:=KeyHolder.Key;
       end
      else
       begin
        k1:=KeyHolder.Key;
        k2:=FWaiting.Key;
       end;
      gd:=TGameData.Create(k1,k2);
      FWaiting.Game:=gd;
      KeyHolder.Game:=gd;
      FGames[i]:=gd;

      FWaiting:=nil;
     end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TGameQueue.ClearFeed(KeyHolder:TKeyHolder);
begin
  EnterCriticalSection(FLock);
  try
    if FWaiting=KeyHolder then FWaiting:=nil;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TGameQueue.GameByKey(const Key:string):TGameData;
var
  i:integer;
begin
  i:=0;
  while (i<MaxGames) and not((FGames[i]<>nil)
    and ((FGames[i].Key1=Key) or (FGames[i].Key2=Key))) do inc(i);
  if i=MaxGames then Result:=nil else Result:=FGames[i];
end;

{ TGameData }

const
  fUnavailable=21;
  fEmpty=22;

constructor TGameData.Create(const AKey1,AKey2:string);
begin
  inherited Create;
  Key1:=AKey1;
  Key2:=AKey2;
  PlayerMsg1:='';
  PlayerMsg2:='';
  State1:=0;
  State2:=0;
  AtPlay:=1;//green starts
end;

procedure TGameData.AfterConstruction;
var
  i:integer;
begin
  inherited;
  for i:=0 to 9 do Pieces1[i]:=StartCount[i];
  for i:=0 to 9 do Pieces2[i]:=StartCount[i];

  Field[0,3]:=fEmpty;
  Field[1,3]:=fEmpty;
  Field[2,3]:=fUnavailable;
  Field[3,3]:=fUnavailable;
  Field[4,3]:=fEmpty;
  Field[5,3]:=fEmpty;
  Field[6,3]:=fUnavailable;
  Field[7,3]:=fUnavailable;
  Field[8,3]:=fEmpty;
  Field[9,3]:=fEmpty;

  Field[0,4]:=fEmpty;
  Field[1,4]:=fEmpty;
  Field[2,4]:=fEmpty;
  Field[3,4]:=fUnavailable;
  Field[4,4]:=fEmpty;
  Field[5,4]:=fEmpty;
  Field[6,4]:=fEmpty;
  Field[7,4]:=fUnavailable;
  Field[8,4]:=fEmpty;
  Field[9,4]:=fEmpty;

  Field[0,5]:=fEmpty;
  Field[1,5]:=fEmpty;
  Field[2,5]:=fUnavailable;
  Field[3,5]:=fEmpty;
  Field[4,5]:=fEmpty;
  Field[5,5]:=fEmpty;
  Field[6,5]:=fUnavailable;
  Field[7,5]:=fEmpty;
  Field[8,5]:=fEmpty;
  Field[9,5]:=fEmpty;

  Field[0,6]:=fEmpty;
  Field[1,6]:=fEmpty;
  Field[2,6]:=fUnavailable;
  Field[3,6]:=fUnavailable;
  Field[4,6]:=fEmpty;
  Field[5,6]:=fEmpty;
  Field[6,6]:=fUnavailable;
  Field[7,6]:=fUnavailable;
  Field[8,6]:=fEmpty;
  Field[9,6]:=fEmpty;

  LastMove:=Now;
end;

procedure TGameData.Signal1(const Data:UTF8String);
var
  ax,ay,bx,by,i,c,d:integer;
begin
  PlayerMsg1:='';
  LastMove:=Now;

  if Data='next' then //wait for next move
  else

  if (Length(Data)=31) and (Data[1]='f') then //field setup
   begin
    i:=1;
    for ay:=7 to 9 do
      for ax:=0 to 9 do
       begin
        inc(i);
        c:=byte(Data[i]) and $F;
        if (c<10) and (Pieces1[c]<>0) then
         begin
          Field[ax,ay]:=c;
          dec(Pieces1[c]);
         end;
       end;
    i:=0;
    while (i<10) and (Pieces1[i]=0) do inc(i);
    if i<10 then
     begin
      PlayerMsg1:='error Invalid field setup.';
      PlayerMsg2:='error Player1 posted an invalid field setup.';
      //Player1.Disconnect;
      //Player2.Disconnect;
     end
    else
     begin
      State1:=1;
     end;
   end
  else

  if (Length(Data)=5) and (Data[1]='m') and (AtPlay=1) then //move
   begin
    ax:=byte(Data[2]) and $F;
    ay:=byte(Data[3]) and $F;
    bx:=byte(Data[4]) and $F;
    by:=byte(Data[5]) and $F;
    if (ax<10) and (ay<10) and (bx<10) and (by<10) then
      if (Field[ax,ay] in [1..8]) and (Field[bx,by]=fEmpty) then
       begin
        Field[bx,by]:=Field[ax,ay];
        Field[ax,ay]:=fEmpty;
        AtPlay:=2;
        PlayerMsg2:=Format('m%d%d%d%d',[9-ax,9-ay,9-bx,9-by]);
       end
      else
        PlayerMsg1:=Format('error 1 src %d not mobile or dest %d not empty',[Field[ax,ay],Field[bx,by]])
    else
      PlayerMsg1:='error 1 move out of range';
    //else abort
   end
  else

  if (Length(Data)=5) and (Data[1]='a') and (AtPlay=1) then //attack
   begin
    ax:=byte(Data[2]) and $F;
    ay:=byte(Data[3]) and $F;
    bx:=byte(Data[4]) and $F;
    by:=byte(Data[5]) and $F;
    if (ax<10) and (ay<10) and (bx<10) and (by<10) then
      if (Field[ax,ay] in [1..8]) and (Field[bx,by] in [10..19]) then
       begin
        c:=Field[ax,ay];
        d:=Field[bx,by]-10;
        if (c>d) or ((c=1) and (d=8)) or ((c=3) and (d=9)) then //spy vs admiral, miner vs poison
          if d=0 then //flag captured?
           begin
            //game won
            PlayerMsg1:=Format('w%d%d',[bx,by]);
            //find flag position
            bx:=0;
            by:=9;
            while (by>6) and (Field[bx,by]<>0) do
             begin
              inc(bx);
              if bx=10 then
               begin
                bx:=0;
                dec(by);
               end;
             end;
            PlayerMsg2:=Format('l%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,c]);
            AtPlay:=0;
           end
          else
           begin
            //victory
            Field[ax,ay]:=fEmpty;
            Field[bx,by]:=c;
            AtPlay:=2;
            PlayerMsg1:=Format('V%d%d%d%d%d%d',[ax,ay,bx,by,c,d]);
            PlayerMsg2:=Format('v%d%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,c,d]);
           end
        else
        if c=d then
         begin
          //both die
          Field[ax,ay]:=fEmpty;
          Field[bx,by]:=fEmpty;
          AtPlay:=2;
          PlayerMsg1:=Format('B%d%d%d%d%d',[ax,ay,bx,by,c]);
          PlayerMsg2:=Format('b%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,c]);
         end
        else
         begin
          //defeat
          Field[ax,ay]:=fEmpty;
          AtPlay:=2;
          PlayerMsg1:=Format('D%d%d%d%d%d%d',[ax,ay,bx,by,d,c]);
          PlayerMsg2:=Format('d%d%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,d,c]);
         end;
       end
      else
        PlayerMsg1:=Format('error 1 src %d not mobile or dest %d not opponent',[Field[ax,ay],Field[bx,by]])
    else
      PlayerMsg1:='error 1 attack out of range';
    //else abort
   end
  else

  //else raise?
    PlayerMsg1:='error 1 unexpected "'+Data+'"';
end;

procedure TGameData.Signal2(const Data:UTF8String);
var
  ax,ay,bx,by,i,c,d:integer;
begin
  PlayerMsg2:='';
  LastMove:=Now;

  if Data='next' then //wait for next move
  else

  if (Length(Data)=31) and (Data[1]='f') then //field setup
   begin
    i:=1;
    for ay:=7 to 9 do
      for ax:=0 to 9 do
       begin
        inc(i);
        c:=byte(Data[i]) and $F;
        if (c<10) and (Pieces2[c]<>0) then
         begin
          Field[9-ax,9-ay]:=10+c;
          dec(Pieces2[c]);
         end;
       end;
    i:=0;
    while (i<10) and (Pieces2[i]=0) do inc(i);
    if i<10 then
     begin
      PlayerMsg2:='error Invalid field setup.';
      PlayerMsg1:='error Player2 posted an invalid field setup.';
      //Player2.Disconnect;
      //Player1.Disconnect;
     end
    else
     begin
      State2:=1;
      //Player2.SendText('ok');
     end;
   end
  else

  if (Length(Data)=5) and (Data[1]='m') and (AtPlay=2) then //move
   begin
    ax:=byte(Data[2]) and $F;
    ay:=byte(Data[3]) and $F;
    bx:=byte(Data[4]) and $F;
    by:=byte(Data[5]) and $F;
    if (ax<10) and (ay<10) and (bx<10) and (by<10) then
     begin
      ax:=9-ax;
      ay:=9-ay;
      bx:=9-bx;
      by:=9-by;
      if (Field[ax,ay] in [11..18]) and (Field[bx,by]=fEmpty) then
       begin
        Field[bx,by]:=Field[ax,ay];
        Field[ax,ay]:=fEmpty;
        AtPlay:=1;
        PlayerMsg1:=Format('m%d%d%d%d',[ax,ay,bx,by]);
       end
      else
        PlayerMsg2:=Format('error 2 src %d not mobile or dest %d not empty',[Field[ax,ay],Field[bx,by]]);
     end
    else
      PlayerMsg2:='error 2 move out of range';
    //else abort
   end
  else

  if (Length(Data)=5) and (Data[1]='a') and (AtPlay=2) then //attack
   begin
    ax:=byte(Data[2]) and $F;
    ay:=byte(Data[3]) and $F;
    bx:=byte(Data[4]) and $F;
    by:=byte(Data[5]) and $F;
    if (ax<10) and (ay<10) and (bx<10) and (by<10) then
     begin
      ax:=9-ax;
      ay:=9-ay;
      bx:=9-bx;
      by:=9-by;
      if (Field[ax,ay] in [11..18]) and (Field[bx,by] in [0..9]) then
       begin
        c:=Field[ax,ay]-10;
        d:=Field[bx,by];
        if (c>d) or ((c=1) and (d=8)) or ((c=3) and (d=9)) then //spy vs admiral, miner vs poison
          if d=0 then //flag captured?
           begin
            //game won
            PlayerMsg2:=Format('w%d%d',[9-bx,9-by]);
            //find flag position
            bx:=0;
            by:=0;
            while (by<3) and (Field[bx,by]<>10) do
             begin
              inc(bx);
              if bx=10 then
               begin
                bx:=0;
                inc(by);
               end;
             end;
            PlayerMsg1:=Format('l%d%d%d%d%d',[ax,ay,bx,by,c]);
            AtPlay:=0;
           end
          else
           begin
            //victory
            Field[ax,ay]:=fEmpty;
            Field[bx,by]:=c+10;
            AtPlay:=1;
            PlayerMsg2:=Format('V%d%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,c,d]);
            PlayerMsg1:=Format('v%d%d%d%d%d%d',[ax,ay,bx,by,c,d]);
           end
        else
        if c=d then
         begin
          //both die
          Field[ax,ay]:=fEmpty;
          Field[bx,by]:=fEmpty;
          AtPlay:=1;
          PlayerMsg2:=Format('B%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,c]);
          PlayerMsg1:=Format('b%d%d%d%d%d',[ax,ay,bx,by,c]);
         end
        else
         begin
          //defeat
          Field[ax,ay]:=fEmpty;
          AtPlay:=1;
          PlayerMsg2:=Format('D%d%d%d%d%d%d',[9-ax,9-ay,9-bx,9-by,d,c]);
          PlayerMsg1:=Format('d%d%d%d%d%d%d',[ax,ay,bx,by,d,c]);
         end;
       end
      else
        PlayerMsg2:=Format('error 2 src %d not mobile or dest %d not opponent',[Field[ax,ay],Field[bx,by]]);
     end
    else
      PlayerMsg2:='error 2 attack out of range';
    //else abort
   end
  else
  
  //else raise?
    PlayerMsg2:='error 2 unexpected "'+Data+'"';
end;

initialization
  //see xxmp since that's in CoInit'ed thread
  //GameQueue:=TGameQueue.Create;
  GameQueue:=nil;
finalization
  FreeAndNil(GameQueue);
end.
