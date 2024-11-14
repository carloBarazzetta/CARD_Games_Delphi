object CardDeckForm: TCardDeckForm
  Left = 127
  Top = 223
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Card Deck Selector.'
  ClientHeight = 357
  ClientWidth = 534
  Color = clBtnFace
  ParentFont = True
  Position = poOwnerFormCenter
  OnClose = FormClose
  TextHeight = 15
  object ListBox1: TListBox
    Left = 7
    Top = 7
    Width = 226
    Height = 342
    ItemHeight = 15
    TabOrder = 0
    OnClick = ListBox1Click
    OnKeyPress = ListBox1KeyPress
  end
  object Button1: TButton
    Left = 469
    Top = 329
    Width = 61
    Height = 20
    Caption = 'OK'
    TabOrder = 1
    OnClick = Button1Click
  end
end
