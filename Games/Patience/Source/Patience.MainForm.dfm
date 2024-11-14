object MainForm: TMainForm
  Left = 540
  Top = 304
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'Patience Game'
  ClientHeight = 539
  ClientWidth = 728
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 13
  object RedealButton: TButton
    Left = 20
    Top = 40
    Width = 65
    Height = 25
    Caption = 'Redeal'
    Enabled = False
    TabOrder = 0
    Visible = False
    OnClick = RedealButtonClick
  end
  object MainMenu: TMainMenu
    Left = 672
    Top = 40
    object G1: TMenuItem
      Caption = 'Game'
      object NewGame1: TMenuItem
        Caption = 'New Game'
        Enabled = False
        OnClick = NewGame1Click
      end
      object FullScreen1: TMenuItem
        Caption = 'Full Screen'
        OnClick = FullScreen1Click
      end
      object QuitProgram1: TMenuItem
        Caption = 'Quit Program'
        OnClick = QuitProgram1Click
      end
    end
    object ChooseGame1: TMenuItem
      Caption = 'Game Type'
      object Canfield1: TMenuItem
        Caption = 'Canfield'
        OnClick = Canfield1Click
      end
      object FourSeasons1: TMenuItem
        Caption = 'Four Seasons'
        OnClick = FourSeasons1Click
      end
      object Klondike11: TMenuItem
        Caption = 'Klondike 1'
        OnClick = Klondike11Click
      end
      object Klondike21: TMenuItem
        Caption = 'Klondike 2'
        OnClick = Klondike21Click
      end
      object Streets1: TMenuItem
        Caption = 'Streets'
        OnClick = Streets1Click
      end
      object Yukon1: TMenuItem
        Caption = 'Yukon'
        OnClick = Yukon1Click
      end
    end
    object Options1: TMenuItem
      Caption = 'Options'
      object BackgroundMode1: TMenuItem
        Caption = 'Background Mode'
        object StretchPicture1: TMenuItem
          Caption = 'Stretch Picture'
          OnClick = StretchPicture1Click
        end
        object TilePicture1: TMenuItem
          Caption = 'Tile Picture'
          Checked = True
          OnClick = TilePicture1Click
        end
      end
      object BackgroundPicture1: TMenuItem
        Caption = 'Background Picture'
        OnClick = BackgroundPicture1Click
      end
      object ChooseBack1: TMenuItem
        Caption = 'Choose Card Back'
        OnClick = ChooseBack1Click
      end
      object ChooseDeck1: TMenuItem
        Caption = 'Choose Card Deck'
        OnClick = ChooseDeck1Click
      end
      object SaveOptions1: TMenuItem
        Caption = 'Save Options'
        OnClick = SaveOptions1Click
      end
      object ShadeMode1: TMenuItem
        Caption = 'Shade Mode'
        object CardBased1: TMenuItem
          Caption = 'Card Based'
          Checked = True
          OnClick = CardBased1Click
        end
        object MouseBased1: TMenuItem
          Caption = 'Mouse Based'
          OnClick = MouseBased1Click
        end
      end
    end
  end
end
