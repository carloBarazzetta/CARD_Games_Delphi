{******************************************************************************}
{                                                                              }
{ CardGames.Messaging:                                                         }
{ Messaging unit for Client/Server interaction                                 }
{                                                                              }
{ Copyright (c) 2024                                                           }
{ Author: Carlo Barazzetta                                                     }
{ Contributor: Lorenzo Barazzetta                                              }
{                                                                              }
{ https://github.com/carloBarazzetta/CARD_Games_Delphi                         }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit CardGames.Messaging;

interface

uses
  System.SysUtils, System.Generics.Collections;

type

  /// <Summary>
  ///  Base class for all messages
  /// </Summary>
  TCardGameMessage = class abstract;

  TCardGameMessageListener = reference to procedure(const Sender: TObject; const M: TCardGameMessage);
  TCardGameMessageListenerMethod = procedure (const Sender: TObject; const M: TCardGameMessage) of object;

  /// <Summary>
  ///  TCardGameMessageManager can have many independent instances
  ///  but maintains one global instance accessible by
  ///  TCardGameMessageManager.CardMessagesManager
  /// </Summary>
  TCardGameMessageManager = class
  protected
  type
    TListenerWithId = record
      Id: Integer;
      Listener: TCardGameMessageListener;
      ListenerMethod: TCardGameMessageListenerMethod;
    end;
    PListenerWithId = ^TListenerWithId;
    TListenerList = class(TList<TListenerWithId>)
    strict private
      FProcessing: Integer;

      procedure IterateAndSend(const Sender: TObject; const AMessage: TCardGameMessage);
      procedure Compact;
    private
      FRemoveCount: Integer;

      procedure Unsubscribe(Index: Integer; Immediate: Boolean); inline;
      procedure SendMessage(const Sender: TObject; const AMessage: TCardGameMessage); inline;
      class procedure InternalCopyListener(FromListener, ToListener: PListenerWithId); inline;
    end;
    TListenerRegistry = TObjectDictionary<TClass, TListenerList>;
  private
    FListeners: TListenerRegistry;
    FLastId: Integer;
    procedure RegisterMessageClass(const AMessageClass: TClass);

    /// <Summary> Global instance</Summary>
    class var FCardMessagesManager: TCardGameMessageManager;
    class function GetCardMessagesManager: TCardGameMessageManager; static;
    class function SearchListener(const ArrayToSearch: array of TListenerWithId; Id: Integer; AMinValue, AMaxValue: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    class destructor UnInitialize;
    procedure Unsubscribe(const AMessageClass: TClass; Id: Integer; Immediate: Boolean = False); overload;
    procedure Unsubscribe(const AMessageClass: TClass; const AListener: TCardGameMessageListener; Immediate: Boolean = False); overload;
    procedure Unsubscribe(const AMessageClass: TClass; const AListenerMethod: TCardGameMessageListenerMethod; Immediate: Boolean = False); overload;
    procedure SendMessage(const Sender: TObject; AMessage: TCardGameMessage); overload; inline;
    procedure SendMessage(const Sender: TObject; AMessage: TCardGameMessage; ADispose: Boolean); overload;
    function SubscribeToMessage(const AMessageClass: TClass; const AListener: TCardGameMessageListener): Integer; overload;
    function SubscribeToMessage(const AMessageClass: TClass; const AListenerMethod: TCardGameMessageListenerMethod): Integer; overload;
    class property CardMessagesManager: TCardGameMessageManager read GetCardMessagesManager;
  end;

implementation

uses System.Types, System.RTLConsts;

{ TCardGameMessageManager }

constructor TCardGameMessageManager.Create;
begin
  FListeners := TListenerRegistry.Create([doOwnsValues]);
  FLastId := 1;
end;

destructor TCardGameMessageManager.Destroy;
begin
  FListeners.Free;
  inherited;
end;

class function TCardGameMessageManager.GetCardMessagesManager: TCardGameMessageManager;
begin
  if FCardMessagesManager = nil then
    FCardMessagesManager := TCardGameMessageManager.Create;

  Result := FCardMessagesManager;
end;

class destructor TCardGameMessageManager.UnInitialize;
begin
  FreeAndNil(FCardMessagesManager);
end;

procedure TCardGameMessageManager.RegisterMessageClass(const AMessageClass: TClass);
begin
  if not FListeners.ContainsKey(AMessageClass) then
    FListeners.Add(AMessageClass, TListenerList.Create);
end;

function TCardGameMessageManager.SubscribeToMessage(const AMessageClass: TClass; const AListener: TCardGameMessageListener) : Integer;
var
  L: TListenerWithId;
  Subscribers: TListenerList;
begin
  Result := -1;
  RegisterMessageClass(AMessageClass);
  if FListeners.TryGetValue(AMessageClass, Subscribers) then
  begin
    L.Listener := AListener;
    L.ListenerMethod := nil;
    Inc(FLastId);
    L.Id := FLastId;
    Result := L.Id;
    Subscribers.Add(L);
  end;
end;

function TCardGameMessageManager.SubscribeToMessage(const AMessageClass: TClass; const AListenerMethod: TCardGameMessageListenerMethod): Integer;
var
  L: TListenerWithId;
  Subscribers: TListenerList;
begin
  Result := -1;
  RegisterMessageClass(AMessageClass);
  if FListeners.TryGetValue(AMessageClass, Subscribers) then
  begin
    L.Listener := nil;
    L.ListenerMethod := AListenerMethod;
    Inc(FLastId);
    L.Id := FLastId;
    Result := L.Id;
    Subscribers.Add(L);
  end;
end;


procedure TCardGameMessageManager.Unsubscribe(const AMessageClass: TClass; const AListener: TCardGameMessageListener; Immediate: Boolean);
var
  Subscribers: TListenerList;
  I: Integer;
begin
  if FListeners.TryGetValue(AMessageClass, Subscribers) then
    for I := 0 to Subscribers.Count - 1 do
      if Pointer((@Subscribers.List[I].Listener)^) = Pointer((@AListener)^) then
      begin
        Subscribers.Unsubscribe(I,Immediate);
        Break;
      end;
end;

procedure TCardGameMessageManager.Unsubscribe(const AMessageClass: TClass; const AListenerMethod: TCardGameMessageListenerMethod; Immediate: Boolean);
var
  Subscribers: TListenerList;
  I: Integer;
begin
  if FListeners.TryGetValue(AMessageClass, Subscribers) then
    for I := 0 to Subscribers.Count - 1 do
      if TMethod(Subscribers[I].ListenerMethod) = TMethod(AListenerMethod) then
      begin
        Subscribers.Unsubscribe(I,Immediate);
        break;
      end;
end;

procedure TCardGameMessageManager.Unsubscribe(const AMessageClass: TClass; Id: Integer; Immediate: Boolean);
var
  Index: Integer;
  Subscribers: TListenerList;
begin
  if FListeners.TryGetValue(AMessageClass, Subscribers) then
  begin
    Index := SearchListener(Subscribers.List, Id, 0, Subscribers.Count - 1);
    if Index >= 0 then
      Subscribers.Unsubscribe(Index, Immediate);
  end;
end;


procedure TCardGameMessageManager.SendMessage(const Sender: TObject; AMessage: TCardGameMessage; ADispose: Boolean);
var
  Subscribers: TListenerList;
begin
  if AMessage <> nil then
    try
      if FListeners.TryGetValue(AMessage.ClassType, Subscribers) then
        Subscribers.SendMessage(Sender, AMessage);

    finally
      if ADispose then
        AMessage.Free;
    end
  else
    raise Exception.CreateRes(@SArgumentInvalid);
end;

procedure TCardGameMessageManager.SendMessage(const Sender: TObject; AMessage: TCardGameMessage);
begin
  SendMessage(Sender, AMessage, True);
end;

class function TCardGameMessageManager.SearchListener(const ArrayToSearch: array of TListenerWithId; Id: Integer; AMinValue, AMaxValue: Integer): Integer;
var
  IMin, IMid, IMax: Integer;
begin
  if (AMaxValue < AMinValue) then
    Exit(-1);
  IMin := AMinValue;
  IMax := AMaxValue;

  while IMax >= IMin do
  begin
    IMid := (IMax + IMin) shr 1;
    if ArrayToSearch[IMid].Id < Id then
    begin
      IMin := IMid + 1;
    end
    else
      if ArrayToSearch[IMid].Id > Id then
        IMax := IMid - 1
      else
        Exit(IMid);
  end;
  Result := -1;
end;

{ TCardGameMessageManager.TListenerList }

class procedure TCardGameMessageManager.TListenerList.InternalCopyListener(FromListener, ToListener: PListenerWithId);
begin
  ToListener.Id := FromListener.Id;
  ToListener.Listener := FromListener.Listener;
  ToListener.ListenerMethod := FromListener.ListenerMethod;
end;

procedure TCardGameMessageManager.TListenerList.IterateAndSend(const Sender: TObject;
  const AMessage: TCardGameMessage);
var
  I: Integer;
  Listener: PListenerWithId;
begin
  for I := 0 to Count - 1 do
  begin
    Listener := @List[I];
    if Assigned(Listener.Listener) then
      Listener.Listener(Sender, AMessage)
    else
      if Assigned(Listener.ListenerMethod) then
        TCardGameMessageListenerMethod(Listener.ListenerMethod)(Sender, AMessage);
  end;
end;

procedure TCardGameMessageManager.TListenerList.SendMessage(const Sender: TObject;
  const AMessage: TCardGameMessage);
begin
  if (FProcessing = 0) and (FRemoveCount > 0) and (((FRemoveCount * 100) div Count) > 10) then
    Compact;
  Inc(FProcessing);
  try
    IterateAndSend(Sender, AMessage);
  finally
    Dec(FProcessing);
  end;
end;

procedure TCardGameMessageManager.TListenerList.Unsubscribe(Index: Integer;
  Immediate: Boolean);
begin
  if FProcessing > 0 then
  begin
    // Recursive call, no compacting should be performed
    List[Index].Listener := nil;
    List[Index].ListenerMethod := nil;
    Inc(FRemoveCount);
  end
  else
  begin
    if Immediate then
      Delete(Index)
    else
    begin
      List[Index].Listener := nil;
      List[Index].ListenerMethod := nil;
      Inc(FRemoveCount);
      if (FRemoveCount shl 1) > (Count + 4) then
        Compact;
    end;
  end;
end;

procedure TCardGameMessageManager.TListenerList.Compact;
var
  I, N: Integer;
  Listener: PListenerWithId;
begin
  N := 0;
  FRemoveCount := 0;
  for I := 0 to Count - 1 do
  begin
    Listener := @List[I];
    if Assigned(Listener.Listener) or Assigned(Listener.ListenerMethod) then
    begin
      if N <> I then
        InternalCopyListener(Listener, @List[N]);
      Inc(N);
    end;
  end;
  Count := N;
end;

end.

