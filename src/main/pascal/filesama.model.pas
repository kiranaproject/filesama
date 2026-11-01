// filesama.model.pas — filesystem directory model and item abstraction
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Model;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, BaseUnix;

type
  TFileItem = class
  public
    Name: string;
    FullPath: string;
    Size: Int64;
    SizeFormatted: string;
    IsDirectory: Boolean;
    IsSymlink: Boolean;
    MimeType: string;
    TypeDescription: string;
    ModTime: TDateTime;
    ModTimeFormatted: string;
    Permissions: string;
    IsHidden: Boolean;
  end;

  TDirectoryModel = class
  private
    FCurrentPath: string;
    FItems: TFPList;
    FShowHidden: Boolean;
    FSortColumn: Integer;
    FSortAscending: Boolean;

    function  GetCount(): Integer;
    function  GetItem(AIndex: Integer): TFileItem;
    procedure QuickSort(L, R: Integer);
    function  CompareItems(A, B: TFileItem): Integer;
    function  FormatPermissions(AMode: mode_t): string;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Clear();
    procedure ScanDirectory(const APath: string);
    procedure Sort(AColumn: Integer; AAscending: Boolean);

    function FormatFileSize(Bytes: Int64): string;
    function DetectMimeType(const AFileName: string; AIsDir: Boolean): string;
    function GetTypeDescription(const AFileName: string; AIsDir: Boolean): string;

    property CurrentPath: string read FCurrentPath write FCurrentPath;
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TFileItem read GetItem; default;
    property ShowHidden: Boolean read FShowHidden write FShowHidden;
    property SortColumn: Integer read FSortColumn write FSortColumn;
    property SortAscending: Boolean read FSortAscending write FSortAscending;
  end;

implementation

// -----------------------------------------------------------------------------
// TDirectoryModel
// -----------------------------------------------------------------------------

constructor TDirectoryModel.Create();
begin
  inherited Create();
  FItems := TFPList.Create();
  FCurrentPath := '';
  FShowHidden := False;
  FSortColumn := 0;
  FSortAscending := True;
end;

destructor TDirectoryModel.Destroy();
begin
  Clear();
  FItems.Free();
  inherited Destroy();
end;

procedure TDirectoryModel.Clear();
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    TFileItem(FItems[i]).Free();
  FItems.Clear();
end;

function TDirectoryModel.GetCount(): Integer;
begin
  Result := FItems.Count;
end;

function TDirectoryModel.GetItem(AIndex: Integer): TFileItem;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := TFileItem(FItems[AIndex])
  else
    Result := nil;
end;

function TDirectoryModel.FormatFileSize(Bytes: Int64): string;
const
  KB = 1024;
  MB = 1024 * KB;
  GB = 1024 * MB;
begin
  if Bytes < 0 then
    Result := '--'
  else if Bytes < KB then
    Result := Format('%d B', [Bytes])
  else if Bytes < MB then
    Result := Format('%.1f KB', [Bytes / KB])
  else if Bytes < GB then
    Result := Format('%.1f MB', [Bytes / MB])
  else
    Result := Format('%.2f GB', [Bytes / GB]);
end;

function TDirectoryModel.FormatPermissions(AMode: mode_t): string;
var
  res: string;
begin
  res := '---------';
  // User
  if (AMode and S_IRUSR) <> 0 then res[1] := 'r';
  if (AMode and S_IWUSR) <> 0 then res[2] := 'w';
  if (AMode and S_IXUSR) <> 0 then res[3] := 'x';
  // Group
  if (AMode and S_IRGRP) <> 0 then res[4] := 'r';
  if (AMode and S_IWGRP) <> 0 then res[5] := 'w';
  if (AMode and S_IXGRP) <> 0 then res[6] := 'x';
  // Other
  if (AMode and S_IROTH) <> 0 then res[7] := 'r';
  if (AMode and S_IWOTH) <> 0 then res[8] := 'w';
  if (AMode and S_IXOTH) <> 0 then res[9] := 'x';
  Result := res;
end;

function TDirectoryModel.DetectMimeType(const AFileName: string; AIsDir: Boolean): string;
var
  ext: string;
begin
  if AIsDir then
    Exit('inode/directory');

  ext := LowerCase(ExtractFileExt(AFileName));
  if (ext = '.txt') or (ext = '.md') or (ext = '.log') then
    Result := 'text/plain'
  else if (ext = '.pas') or (ext = '.pp') or (ext = '.inc') then
    Result := 'text/x-pascal'
  else if (ext = '.c') or (ext = '.h') then
    Result := 'text/x-c'
  else if (ext = '.ftml') or (ext = '.xml') or (ext = '.html') or (ext = '.htm') then
    Result := 'text/html'
  else if (ext = '.json') or (ext = '.js') then
    Result := 'application/json'
  else if (ext = '.png') then
    Result := 'image/png'
  else if (ext = '.jpg') or (ext = '.jpeg') then
    Result := 'image/jpeg'
  else if (ext = '.svg') then
    Result := 'image/svg+xml'
  else if (ext = '.gif') then
    Result := 'image/gif'
  else if (ext = '.pdf') then
    Result := 'application/pdf'
  else if (ext = '.tar') or (ext = '.gz') or (ext = '.zip') or (ext = '.xz') then
    Result := 'application/zip'
  else if (ext = '.sh') or (ext = '.bash') then
    Result := 'application/x-shellscript'
  else
    Result := 'application/octet-stream';
end;

function TDirectoryModel.GetTypeDescription(const AFileName: string; AIsDir: Boolean): string;
var
  ext: string;
begin
  if AIsDir then
    Exit('Folder');

  ext := LowerCase(ExtractFileExt(AFileName));
  if (ext = '.txt') or (ext = '.log') then
    Result := 'Plain Text'
  else if (ext = '.md') then
    Result := 'Markdown Document'
  else if (ext = '.pas') or (ext = '.pp') or (ext = '.inc') then
    Result := 'Pascal Source'
  else if (ext = '.c') or (ext = '.h') then
    Result := 'C Source'
  else if (ext = '.ftml') then
    Result := 'Floria Markup'
  else if (ext = '.xml') then
    Result := 'XML Document'
  else if (ext = '.html') or (ext = '.htm') then
    Result := 'HTML Document'
  else if (ext = '.json') then
    Result := 'JSON Document'
  else if (ext = '.js') then
    Result := 'JavaScript File'
  else if (ext = '.png') then
    Result := 'PNG Image'
  else if (ext = '.jpg') or (ext = '.jpeg') then
    Result := 'JPEG Image'
  else if (ext = '.svg') then
    Result := 'SVG Vector Image'
  else if (ext = '.pdf') then
    Result := 'PDF Document'
  else if (ext = '.zip') or (ext = '.tar') or (ext = '.gz') or (ext = '.xz') then
    Result := 'Archive'
  else if (ext = '.sh') or (ext = '.bash') then
    Result := 'Shell Script'
  else if (ext = '.so') then
    Result := 'Shared Library'
  else
    Result := 'File';
end;

procedure TDirectoryModel.ScanDirectory(const APath: string);
var
  resolved, pattern, full: string;
  sr: TSearchRec;
  st: stat;
  item: TFileItem;
begin
  Clear();

  resolved := ExpandFileName(APath);
  if not DirectoryExists(resolved) then Exit;

  FCurrentPath := resolved;

  pattern := resolved;
  if (Length(pattern) > 0) and (pattern[Length(pattern)] <> '/') then
    pattern := pattern + '/';
  pattern := pattern + '*';

  if FindFirst(pattern, faAnyFile or faHidden, sr) = 0 then
  begin
    try
      repeat
        if (sr.Name <> '.') and (sr.Name <> '..') then
        begin
          if FShowHidden or (Length(sr.Name) = 0) or (sr.Name[1] <> '.') then
          begin
            full := resolved;
            if (Length(full) > 0) and (full[Length(full)] <> '/') then
              full := full + '/';
            full := full + sr.Name;

            item := TFileItem.Create();
            item.Name := sr.Name;
            item.FullPath := full;
            item.IsDirectory := (sr.Attr and faDirectory) <> 0;
            item.IsHidden := (Length(sr.Name) > 0) and (sr.Name[1] = '.');
            item.Size := sr.Size;

            if fpLstat(PChar(full), st) = 0 then
            begin
              item.IsDirectory := fpS_ISDIR(st.st_mode);
              item.IsSymlink := fpS_ISLNK(st.st_mode);
              item.Size := st.st_size;
              item.Permissions := FormatPermissions(st.st_mode);
              item.ModTime := UnixToDateTime(st.st_mtime);
            end
            else
            begin
              item.IsSymlink := (sr.Attr and faSymLink) <> 0;
              item.Permissions := 'rw-r--r--';
              item.ModTime := FileDateToDateTime(sr.Time);
            end;

            item.ModTimeFormatted := FormatDateTime('yyyy-mm-dd hh:nn', item.ModTime);
            item.MimeType := DetectMimeType(sr.Name, item.IsDirectory);
            item.TypeDescription := GetTypeDescription(sr.Name, item.IsDirectory);

            if item.IsDirectory then
              item.SizeFormatted := '--'
            else
              item.SizeFormatted := FormatFileSize(item.Size);

            FItems.Add(item);
          end;
        end;
      until FindNext(sr) <> 0;
    finally
      FindClose(sr);
    end;
  end;

  Sort(FSortColumn, FSortAscending);
end;

function TDirectoryModel.CompareItems(A, B: TFileItem): Integer;
var
  res: Integer;
begin
  // Folders always precede regular files
  if A.IsDirectory and not B.IsDirectory then
    Exit(-1);
  if not A.IsDirectory and B.IsDirectory then
    Exit(1);

  case FSortColumn of
    1: // Size
      begin
        if A.Size < B.Size then res := -1
        else if A.Size > B.Size then res := 1
        else res := CompareText(A.Name, B.Name);
      end;
    2: // Type
      begin
        res := CompareText(A.TypeDescription, B.TypeDescription);
        if res = 0 then
          res := CompareText(A.Name, B.Name);
      end;
    3: // ModTime
      begin
        if A.ModTime < B.ModTime then res := -1
        else if A.ModTime > B.ModTime then res := 1
        else res := CompareText(A.Name, B.Name);
      end;
    else // Name
      res := CompareText(A.Name, B.Name);
  end;

  if not FSortAscending then
    res := -res;

  Result := res;
end;

procedure TDirectoryModel.QuickSort(L, R: Integer);
var
  i, j: Integer;
  pivot, temp: TFileItem;
begin
  if L >= R then Exit;

  i := L;
  j := R;
  pivot := TFileItem(FItems[(L + R) div 2]);

  repeat
    while CompareItems(TFileItem(FItems[i]), pivot) < 0 do
      Inc(i);
    while CompareItems(TFileItem(FItems[j]), pivot) > 0 do
      Dec(j);

    if i <= j then
    begin
      temp := TFileItem(FItems[i]);
      FItems[i] := FItems[j];
      FItems[j] := temp;
      Inc(i);
      Dec(j);
    end;
  until i > j;

  if L < j then QuickSort(L, j);
  if i < R then QuickSort(i, R);
end;

procedure TDirectoryModel.Sort(AColumn: Integer; AAscending: Boolean);
begin
  FSortColumn := AColumn;
  FSortAscending := AAscending;
  if FItems.Count > 1 then
    QuickSort(0, FItems.Count - 1);
end;

end.
