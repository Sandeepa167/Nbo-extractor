object Form13: TForm13
  Left = 0
  Top = 0
  Caption = 'Form13'
  ClientHeight = 499
  ClientWidth = 945
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 457
    Height = 129
    TabOrder = 0
    object LabelProgress: TLabel
      Left = 8
      Top = 85
      Width = 35
      Height = 13
      Caption = 'Status:'
    end
    object EditFilePath: TEdit
      Left = 8
      Top = 8
      Width = 411
      Height = 21
      TabOrder = 0
    end
    object BtnBrowse: TButton
      Left = 248
      Top = 35
      Width = 171
      Height = 25
      Caption = 'open'
      TabOrder = 1
      OnClick = BtnBrowseClick
    end
    object BtnExtract: TButton
      Left = 248
      Top = 66
      Width = 171
      Height = 25
      Caption = 'extract'
      TabOrder = 2
      OnClick = BtnExtractClick
    end
    object ProgressBar1: TProgressBar
      Left = 8
      Top = 104
      Width = 433
      Height = 17
      TabOrder = 3
    end
  end
  object MemoOutput: TMemo
    Left = 0
    Top = 143
    Width = 465
    Height = 354
    Lines.Strings = (
      'MemoOutput')
    TabOrder = 1
  end
  object ListView1: TListView
    Left = 471
    Top = 8
    Width = 474
    Height = 489
    Columns = <
      item
        Caption = 'name'
        Width = 100
      end
      item
        Caption = 'size'
        Width = 100
      end
      item
        Caption = 'offset'
        Width = 100
      end
      item
        Caption = 'system'
        Width = 100
      end>
    MultiSelect = True
    TabOrder = 2
    ViewStyle = vsReport
  end
  object OpenDialog: TOpenDialog
    Left = 576
    Top = 24
  end
  object SaveDialog1: TSaveDialog
    Left = 480
    Top = 24
  end
  object FileSaveDialog1: TFileSaveDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 520
    Top = 24
  end
end
