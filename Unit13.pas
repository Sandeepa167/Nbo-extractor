unit Unit13;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.IOUtils, System.Generics.Collections, Vcl.ComCtrls;

type
  TFileHeader = record
    loDataOffset: Cardinal;
    loFileSize: Cardinal;
    hiDataOffset: Cardinal;
    hiFileSize: Cardinal;
    fileName: AnsiString;
    dataOffset: Int64;
    fileSize: Int64;
  end;

type
  TForm13 = class(TForm)
    Panel1: TPanel;
    EditFilePath: TEdit;
    BtnBrowse: TButton;
    MemoOutput: TMemo;
    BtnExtract: TButton;
    OpenDialog: TOpenDialog;
    ListView1: TListView;
    SaveDialog1: TSaveDialog;
    FileSaveDialog1: TFileSaveDialog;
    ProgressBar1: TProgressBar;
    LabelProgress: TLabel;
    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnExtractClick(Sender: TObject);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    procedure ParseFiles(const FileStream: TFileStream; const hdrsEnd: Integer;
      var fileHeaders: TList<TFileHeader>; const debug: Boolean);
    procedure ExtractFile(const FileStream: TFileStream; const fh: TFileHeader;
      const outdir: string; const debug: Boolean);
    procedure CheckFile(const nb0file: string; const hdrsEnd: Integer;
      const fileHeaders: TList<TFileHeader>; const debug: Boolean);
    function GetFileSize(const fileName: string): Int64;
    procedure AddFilesToListView(const nb0file: string);
    procedure UpdateProgress(const Progress: Integer; const Status: string);
    function FormatBytes(bytes: Int64): string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form13: TForm13;

implementation

{$R *.dfm}

procedure TForm13.AddFilesToListView(const nb0file: string);
var
  FileStream: TFileStream;
  file_count, hdrsEnd: Integer;
  fileHeaders: TList<TFileHeader>;
  i: Integer;
  ListItem: TListItem;
  FileHeaderPtr: ^TFileHeader;
begin
  if FileExists(nb0file) then
  begin
    FileStream := TFileStream.Create(nb0file, fmOpenRead);
    try
      FileStream.ReadBuffer(file_count, SizeOf(file_count));
      hdrsEnd := 4 + file_count * SizeOf(TFileHeader);
      fileHeaders := TList<TFileHeader>.Create;
      FileStream.Seek(4, soBeginning);
      for i := 0 to file_count - 1 do
        ParseFiles(FileStream, hdrsEnd, fileHeaders, False);
      ListView1.Clear;
      for i := 0 to fileHeaders.Count - 1 do
      begin
        ListItem := ListView1.Items.Add;
        ListItem.Caption := fileHeaders[i].fileName;
        ListItem.SubItems.Add(IntToStr(fileHeaders[i].dataOffset));
        ListItem.SubItems.Add(IntToStr(fileHeaders[i].fileSize));

        // Allocate memory for the file header and assign its address to Data
        New(FileHeaderPtr);
        FileHeaderPtr^ := fileHeaders[i];
        ListItem.Data := FileHeaderPtr;

        ListItem.Checked := True; // Check the checkbox by default
      end;
    finally
      FileStream.Free;
      fileHeaders.Free;
    end;
  end
  else
    ShowMessage('File not found: ' + nb0file);
end;

procedure TForm13.CheckFile(const nb0file: string; const hdrsEnd: Integer;
  const fileHeaders: TList<TFileHeader>; const debug: Boolean);
var
  lastf: Integer;
  fsizefromhdr, fsize: Int64;
begin
  lastf := fileHeaders.Count - 1;
  fsizefromhdr := fileHeaders[lastf].dataOffset + fileHeaders[lastf].fileSize;
  fsize := GetFileSize(nb0file);

  if fsize <> fsizefromhdr then
  begin
    if debug then
      MemoOutput.Lines.Add(Format('FileSize is %d and from header it is %d',
        [fsize, fsizefromhdr]));
    raise Exception.Create(nb0file + ' is not a .nb0 firmware.');
  end;
end;

procedure TForm13.ExtractFile(const FileStream: TFileStream;
  const fh: TFileHeader; const outdir: string; const debug: Boolean);
var
  tempsize, size, tsize: Int64;
  outpath: string;
  dat: TBytes;
  ofile: TFileStream;
  i: Integer;
  ListItem: string;
begin
  tempsize := fh.fileSize;
  if tempsize = 0 then
    Exit;

  outpath := TPath.Combine(outdir, fh.fileName);
  if FileExists(outpath) and (GetFileSize(outpath) = fh.fileSize) then
  begin
    if debug then
      MemoOutput.Lines.Add('Duplicate entry found ' + fh.fileName +
        ', so skipping');
    Exit;
  end;

  ListItem := '- ' + fh.fileName + ', ' + FormatBytes(fh.fileSize);
  MemoOutput.Lines.Add(ListItem);

  FileStream.Seek(fh.dataOffset, TSeekOrigin.soBeginning);
  size := 4096;
  tsize := tempsize;
  ofile := TFileStream.Create(outpath, fmCreate);
  try
    SetLength(dat, size);
    while tempsize > 0 do
    begin
      if tempsize < size then
        size := tempsize;
      FileStream.ReadBuffer(dat[0], size);
      tempsize := tempsize - size;
      ofile.WriteBuffer(dat[0], size);
      UpdateProgress(Round(100 - ((100 * tempsize) / tsize)), ListItem);
    end;
  finally
    ofile.Free;
  end;
end;

procedure TForm13.FormCreate(Sender: TObject);
begin
  ListView1.ViewStyle := vsReport; // Ensure it's set to a supported view style
  ListView1.CheckBoxes := True;
end;

procedure TForm13.ParseFiles(const FileStream: TFileStream;
  const hdrsEnd: Integer; var fileHeaders: TList<TFileHeader>;
  const debug: Boolean);
var
  fileHeader: TFileHeader;
  Item: TListItem;
  fileNameBytes: TBytes;
  fileName: string;
begin
  FileStream.ReadBuffer(fileHeader.loDataOffset,
    SizeOf(fileHeader.loDataOffset));
  FileStream.ReadBuffer(fileHeader.loFileSize, SizeOf(fileHeader.loFileSize));
  FileStream.ReadBuffer(fileHeader.hiDataOffset,
    SizeOf(fileHeader.hiDataOffset));
  FileStream.ReadBuffer(fileHeader.hiFileSize, SizeOf(fileHeader.hiFileSize));
  SetLength(fileNameBytes, 48);
  FileStream.ReadBuffer(fileNameBytes[0], Length(fileNameBytes));
  fileName := TEncoding.UTF8.GetString(fileNameBytes);

  fileHeader.fileName := Trim(fileName);

  fileHeader.dataOffset := hdrsEnd + fileHeader.hiDataOffset * Int64($100000000)
    + fileHeader.loDataOffset;
  fileHeader.fileSize := fileHeader.hiFileSize * Int64($100000000) +
    fileHeader.loFileSize;

  if debug then
  begin
    MemoOutput.Lines.Add('FileName: ' + fileHeader.fileName);
    MemoOutput.Lines.Add('FileSize: ' + IntToStr(fileHeader.fileSize));
    MemoOutput.Lines.Add('DataOffset: ' + IntToStr(fileHeader.dataOffset));
    MemoOutput.Lines.Add('');
  end;

  fileHeaders.Add(fileHeader);
  Item := ListView1.Items.Add;
  Item.Caption := fileHeader.fileName;
  Item.SubItems.Add(IntToStr(fileHeader.fileSize));
  Item.SubItems.Add(IntToStr(fileHeader.dataOffset));
end;

function TForm13.GetFileSize(const fileName: string): Int64;
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(fileName, fmOpenRead or fmShareDenyNone);
  try
    Result := FileStream.size;
  finally
    FileStream.Free;
  end;
end;

procedure TForm13.BtnBrowseClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    EditFilePath.Text := OpenDialog.fileName;
    AddFilesToListView(OpenDialog.fileName);
    MemoOutput.Lines.Add('Selected File: ' + OpenDialog.fileName);
  end;
end;

procedure TForm13.BtnExtractClick(Sender: TObject);
var
  AllChecked: Boolean;
  i: Integer;
  outdir: string;
  FileStream: TFileStream;
  fileHeader: TFileHeader;
begin
  // Check if all checkboxes are checked
  AllChecked := True;
  for i := 0 to ListView1.Items.Count - 1 do
  begin
    if not ListView1.Items[i].Checked then
    begin
      AllChecked := False;
      Break;
    end;
  end;

  // If all checkboxes are checked, proceed with extraction
  if AllChecked then
  begin
    outdir := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))
      + 'extracted';
    if not DirectoryExists(outdir) then
      ForceDirectories(outdir);
    FileStream := TFileStream.Create(EditFilePath.Text, fmOpenRead);
    try
      for i := 0 to ListView1.Items.Count - 1 do
      begin
        if ListView1.Items[i].Checked then
        begin
          Move(ListView1.Items[i].Data^, fileHeader, SizeOf(TFileHeader));
          ExtractFile(FileStream, fileHeader, outdir, False);
        end;
      end;
    finally
      FileStream.Free;
    end;
  end
  else
    ShowMessage('Please check all files before extraction.');
end;

procedure TForm13.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected then
    BtnExtractClick(Sender);
end;

procedure TForm13.UpdateProgress(const Progress: Integer; const Status: string);
begin
  ProgressBar1.Position := Progress;
  LabelProgress.Caption := Status;
end;

function TForm13.FormatBytes(bytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = Int64(KB) * 1024 * 1024;
  TB = Int64(GB) * 1024;
begin
  if bytes < KB then
    Result := IntToStr(bytes) + ' Bytes'
  else if bytes < MB then
    Result := FormatFloat('#,##0.##', bytes / KB) + ' KB'
  else if bytes < GB then
    Result := FormatFloat('#,##0.##', bytes / MB) + ' MB'
  else if bytes < TB then
    Result := FormatFloat('#,##0.##', bytes / GB) + ' GB'
  else
    Result := FormatFloat('#,##0.##', bytes / TB) + ' TB';
end;

end.
