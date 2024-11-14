object MainView: TMainView
  Left = 540
  Top = 304
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'Briscola'
  ClientHeight = 539
  ClientWidth = 570
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
  TextHeight = 13
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
        OnClick = miEsciClick
      end
    end
    object miOpzioni: TMenuItem
      Caption = 'Opzioni'
      object Impostazioni1: TMenuItem
        Caption = 'Impostazioni'
      end
    end
    object miAiuto: TMenuItem
      Caption = 'Aiuto'
      object miInformazioni: TMenuItem
        Caption = 'Informazioni'
        OnClick = miInformazioniClick
      end
    end
  end
end
