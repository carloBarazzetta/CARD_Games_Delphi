{******************************************************************************}
{                                                                              }
{ GiocoBriscola:                                                               }
{ Simulazione gioco Briscola per Demo                                          }
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
program GiocoBriscola;

uses
  Vcl.Forms,
  CardGames.Vcl.ClientPlayerForm in '..\..\..\..\Demo\ClientServer\CardGames.Vcl.ClientPlayerForm.pas' {ClientPlayerForm},
  Briscola.CardGame in '..\..\Source\Briscola.CardGame.pas',
  CardGames.Interfaces in '..\..\..\..\Source\CardGames.Interfaces.pas',
  CardGames.Types in '..\..\..\..\Source\CardGames.Types.pas',
  CardGames.Model in '..\..\..\..\Source\CardGames.Model.pas',
  CardGames.Utils in '..\..\..\..\Source\CardGames.Utils.pas',
  CardGames.Consts in '..\..\..\..\Source\CardGames.Consts.pas',
  CardGames.Engine in '..\..\..\..\Source\CardGames.Engine.pas',
  CardGames.Events in '..\..\..\..\Source\CardGames.Events.pas',
  CardGames.Vcl.ServerForm in '..\..\..\..\Demo\ClientServer\CardGames.Vcl.ServerForm.pas' {ServerMainForm},
  CardGames.Observer in '..\..\..\..\Source\CardGames.Observer.pas',
  CardGames.GameServer in '..\..\..\..\Source\CardGames.GameServer.pas',
  CardGames.GameClient in '..\..\..\..\Source\CardGames.GameClient.pas',
  CardGames.JSONUtils in '..\..\..\..\Source\CardGames.JSONUtils.pas',
  CardGame.Server.Data in '..\..\..\..\Source\CardGame.Server.Data.pas' {CardGameServerData: TDataModule},
  CardGame.Client.Data in '..\..\..\..\Source\CardGame.Client.Data.pas' {CardGameClientData: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.ActionUpdateDelay := 50;
  Application.Title := 'BRISCOLA - Client Server Demo';

  //Application.CreateForm(TClientPlayerForm, ClientPlayerForm);

  //Simula il Server
  Application.CreateForm(TCardGameServerData, CardGameServerData);
  Application.CreateForm(TServerMainForm, ServerMainForm);
  //Simula il Client
  Application.CreateForm(TCardGameClientData, CardGameClientData);
  TClientPlayerForm.Create(Application).Show;
  //TClientPlayerForm.Create(Application).Show;
  Application.Run;
end.
