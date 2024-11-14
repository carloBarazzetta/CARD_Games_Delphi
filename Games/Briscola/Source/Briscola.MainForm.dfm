object MainForm: TMainForm
  Left = 540
  Top = 304
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Briscola'
  ClientHeight = 708
  ClientWidth = 932
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = mmMainMenu
  Position = poScreenCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 13
  object MessagePanel: TPanel
    Left = 0
    Top = 667
    Width = 932
    Height = 41
    Align = alBottom
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 0
    StyleElements = [seFont, seBorder]
  end
  object mmMainMenu: TMainMenu
    Left = 456
    Top = 184
    object miGioco: TMenuItem
      Caption = 'Gioco'
      object miNuovaPartita: TMenuItem
        Caption = 'Nuova partita'
        OnClick = miNuovaPartitaClick
      end
      object miEsci: TMenuItem
        Caption = 'Esci'
        Hint = 'Esce dal gioco'
        OnClick = miEsciClick
      end
    end
    object miOpzioni: TMenuItem
      Caption = 'Opzioni'
      object miChooseDeck: TMenuItem
        Caption = 'Scelta mazzo di carte'
        OnClick = miChooseDeckClick
      end
      object miChooseBack: TMenuItem
        Caption = 'Scelta carta coperta'
        OnClick = miChooseBackClick
      end
    end
    object miAiuto: TMenuItem
      Caption = 'Aiuto'
      object miRegoleDelGioco: TMenuItem
        Caption = 'Regole del gioco'
      end
      object miInformazioni: TMenuItem
        Caption = 'Informazioni'
        OnClick = miInformazioniClick
      end
    end
  end
end
