// filesama.window.pas — main application window and FTML integration
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Window;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ftpas, ftpas.types, ftpas.api, ftpas.app, ftpas.canvas, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.menus, ftpas.views, ftpas.dialogs, ftpas.ftml,
  FileSama.Model, FileSama.Ops;

type
  TFileSamaWindow = class(TFtFTMLForm)
  private
    FModel         : TDirectoryModel;
    FHistory       : TStringList;
    FHistoryIndex  : Integer;
    FFilterQuery   : string;
    FNavigating    : Boolean;

    // Controls resolved from FTML
    FPathBar       : TFtPathBar;
    FFileTable     : TFtTable;
    FPlacesTree    : TFtTreeView;
    FSearchEntry   : TFtEntry;
    FStatusText    : TFtLabel;
    FStatusRight   : TFtLabel;
    FBtnBack       : TFtButton;
    FBtnForward    : TFtButton;
    FBtnUp         : TFtButton;
    FBtnHome       : TFtButton;
    FBtnRefresh    : TFtButton;
    FBtnNewFolder  : TFtButton;
    FBtnHidden     : TFtButton;
    FContextMenu   : TFtPopupMenu;

    { File dialog icon bitmaps }
    FIconFolder    : TFtBitmap;
    FIconFile      : TFtBitmap;
    FIconImage     : TFtBitmap;
    FIconCode      : TFtBitmap;
    FIconArchive   : TFtBitmap;
    FIconHome      : TFtBitmap;
    FIconDesktop   : TFtBitmap;
    FIconDocuments : TFtBitmap;
    FIconDownloads : TFtBitmap;
    FIconPictures  : TFtBitmap;
    FIconMusic     : TFtBitmap;
    FIconDrive     : TFtBitmap;

    function  GetCurrentPath(): string;
    procedure InitIcons();
    procedure FreeIcons();
    procedure SetupPlacesIcons();
    function  GetFileIcon(AIsDirectory: Boolean; const AFileName: string): TFtBitmap;
    procedure SetupUI();
    procedure HookMenu(const AId: string; AHandler: TFtMenuClickEvent);
    procedure UpdateNavigationState();
    procedure RefreshTable();
    procedure UpdateStatusBar();

    // Event handlers
    procedure HandlePathNavigate(Sender: TFtPathBar; const Path: string);
    procedure HandleTreeSelect(Sender: TFtTreeView; Node: TFtTreeNode);
    procedure HandleTableSelectRow(Sender: TFtTable; RowIndex: Integer);
    procedure HandleTableRowDoubleClick(Sender: TFtTable; RowIndex: Integer);
    procedure HandleColumnClick(Sender: TFtTable; ColumnIndex: Integer);

    // Menu actions
    procedure MenuNewFolder(Sender: TFtMenuItem);
    procedure MenuProperties(Sender: TFtMenuItem);
    procedure MenuQuit(Sender: TFtMenuItem);
    procedure MenuCut(Sender: TFtMenuItem);
    procedure MenuCopy(Sender: TFtMenuItem);
    procedure MenuRename(Sender: TFtMenuItem);
    procedure MenuDelete(Sender: TFtMenuItem);
    procedure MenuSelectAll(Sender: TFtMenuItem);
    procedure MenuToggleHidden(Sender: TFtMenuItem);
    procedure MenuRefresh(Sender: TFtMenuItem);
    procedure MenuGoHome(Sender: TFtMenuItem);
    procedure MenuGoDesktop(Sender: TFtMenuItem);
    procedure MenuGoDocuments(Sender: TFtMenuItem);
    procedure MenuGoDownloads(Sender: TFtMenuItem);
    procedure MenuGoParent(Sender: TFtMenuItem);
    procedure MenuGoRoot(Sender: TFtMenuItem);
    procedure MenuOpenTerminal(Sender: TFtMenuItem);
    procedure MenuAbout(Sender: TFtMenuItem);
    procedure MenuOpenSelection(Sender: TFtMenuItem);
  public
    constructor Create(const AInitialPath: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure NavigateTo(const APath: string; AAddToHistory: Boolean = True);

    // Actions and Event Handlers
    procedure ActionBack(Sender: TFtButton);
    procedure ActionForward(Sender: TFtButton);
    procedure ActionUp(Sender: TFtButton);
    procedure ActionHome(Sender: TFtButton);
    procedure ActionRefresh(Sender: TFtButton);
    procedure ActionNewFolder(Sender: TFtButton);
    procedure ActionToggleHidden(Sender: TFtButton; AToggled: Boolean);
    procedure HandleSearchChange(Sender: TFtWidget; const AText: string);

    property Model: TDirectoryModel read FModel;
    property CurrentPath: string read GetCurrentPath;
    property PathBar: TFtPathBar read FPathBar;
    property FileTable: TFtTable read FFileTable;
    property PlacesTree: TFtTreeView read FPlacesTree;
    property SearchEntry: TFtEntry read FSearchEntry;
    property StatusText: TFtLabel read FStatusText;
    property StatusRight: TFtLabel read FStatusRight;
    property History: TStringList read FHistory;
    property HistoryIndex: Integer read FHistoryIndex;
  end;

implementation

{$R filesama.res}

// -----------------------------------------------------------------------------
// TFileSamaWindow Implementation
// -----------------------------------------------------------------------------

constructor TFileSamaWindow.Create(const AInitialPath: string);
var
  startPath: string;
begin
  inherited Create(1040, 680, 'filesama', 'TFileSamaWindow');

  FModel := TDirectoryModel.Create();
  FHistory := TStringList.Create();
  FHistoryIndex := -1;
  FFilterQuery := '';
  FNavigating := False;

  InitIcons();
  SetupUI();

  if AInitialPath <> '' then
    startPath := AInitialPath
  else
    startPath := GetHomeDir();

  NavigateTo(startPath, True);
end;

destructor TFileSamaWindow.Destroy();
begin
  FreeIcons();
  FHistory.Free();
  FModel.Free();
  inherited Destroy();
end;

procedure TFileSamaWindow.InitIcons();
var
  isDark: Boolean;
begin
  isDark := FtApp().DarkMode;
  FIconFolder    := FtApp().GetIconBitmap('folder', 16, 16, isDark);
  FIconFile      := FtApp().GetIconBitmap('file', 16, 16, isDark);
  FIconImage     := FtApp().GetIconBitmap('file-image', 16, 16, isDark);
  FIconCode      := FtApp().GetIconBitmap('file-code', 16, 16, isDark);
  FIconArchive   := FtApp().GetIconBitmap('file-archive', 16, 16, isDark);
  FIconHome      := FtApp().GetIconBitmap('outline-home', 16, 16, isDark);
  FIconDesktop   := FtApp().GetIconBitmap('outline-desktop', 16, 16, isDark);
  FIconDocuments := FtApp().GetIconBitmap('outline-documents', 16, 16, isDark);
  FIconDownloads := FtApp().GetIconBitmap('outline-downloads', 16, 16, isDark);
  FIconPictures  := FtApp().GetIconBitmap('outline-pictures', 16, 16, isDark);
  FIconMusic     := FtApp().GetIconBitmap('outline-music', 16, 16, isDark);
  FIconDrive     := FtApp().GetIconBitmap('outline-drive', 16, 16, isDark);
end;

procedure TFileSamaWindow.FreeIcons();
begin
  FreeAndNil(FIconFolder);
  FreeAndNil(FIconFile);
  FreeAndNil(FIconImage);
  FreeAndNil(FIconCode);
  FreeAndNil(FIconArchive);
  FreeAndNil(FIconHome);
  FreeAndNil(FIconDesktop);
  FreeAndNil(FIconDocuments);
  FreeAndNil(FIconDownloads);
  FreeAndNil(FIconPictures);
  FreeAndNil(FIconMusic);
  FreeAndNil(FIconDrive);
end;

function TFileSamaWindow.GetFileIcon(AIsDirectory: Boolean; const AFileName: string): TFtBitmap;
var
  ext: string;
begin
  if AIsDirectory then
    Exit(FIconFolder);

  ext := LowerCase(ExtractFileExt(AFileName));
  if (ext <> '') and (ext[1] = '.') then
    Delete(ext, 1, 1);
  if (ext = 'png') or (ext = 'jpg') or (ext = 'jpeg') or (ext = 'bmp') or
     (ext = 'svg') or (ext = 'gif') or (ext = 'webp') or (ext = 'ico') then
    Result := FIconImage
  else if (ext = 'pas') or (ext = 'pp') or (ext = 'c') or (ext = 'h') or
          (ext = 'cpp') or (ext = 'py') or (ext = 'sh') or (ext = 'bash') or
          (ext = 'json') or (ext = 'xml') or (ext = 'html') or (ext = 'css') or
          (ext = 'md') or (ext = 'js') or (ext = 'ts') or (ext = 'sql') then
    Result := FIconCode
  else if (ext = 'zip') or (ext = 'tar') or (ext = 'gz') or (ext = 'xz') or
          (ext = '7z') or (ext = 'bz2') or (ext = 'rar') then
    Result := FIconArchive
  else
    Result := FIconFile;
end;

procedure TFileSamaWindow.SetupPlacesIcons();
var
  i: Integer;
  node: TFtTreeNode;
begin
  if (FPlacesTree = nil) or (FPlacesTree.Root = nil) then Exit;
  for i := 0 to FPlacesTree.Root.ChildCount - 1 do
  begin
    node := FPlacesTree.Root.Children[i];
    if node = nil then Continue;
    if node.Text = 'Home' then node.SetIcon(FIconHome)
    else if node.Text = 'Desktop' then node.SetIcon(FIconDesktop)
    else if node.Text = 'Documents' then node.SetIcon(FIconDocuments)
    else if node.Text = 'Downloads' then node.SetIcon(FIconDownloads)
    else if node.Text = 'Pictures' then node.SetIcon(FIconPictures)
    else if node.Text = 'Music' then node.SetIcon(FIconMusic)
    else if node.Text = 'Videos' then node.SetIcon(FIconPictures)
    else if node.Text = 'Root' then node.SetIcon(FIconDrive);
  end;
end;

function TFileSamaWindow.GetCurrentPath(): string;
begin
  if FModel <> nil then
    Result := FModel.CurrentPath
  else
    Result := '';
end;

procedure TFileSamaWindow.SetupUI();
var
  w: TFtWidget;
begin
  w := FindWidget('pathBar');
  if w is TFtPathBar then FPathBar := TFtPathBar(w);

  w := FindWidget('fileTable');
  if w is TFtTable then FFileTable := TFtTable(w);

  w := FindWidget('placesTree');
  if w is TFtTreeView then FPlacesTree := TFtTreeView(w);

  w := FindWidget('searchEntry');
  if w is TFtEntry then FSearchEntry := TFtEntry(w);

  w := FindWidget('statusText');
  if w is TFtLabel then FStatusText := TFtLabel(w);

  w := FindWidget('statusRight');
  if w is TFtLabel then FStatusRight := TFtLabel(w);

  w := FindWidget('btnBack');
  if w is TFtButton then FBtnBack := TFtButton(w);

  w := FindWidget('btnForward');
  if w is TFtButton then FBtnForward := TFtButton(w);

  w := FindWidget('btnUp');
  if w is TFtButton then FBtnUp := TFtButton(w);

  w := FindWidget('btnHome');
  if w is TFtButton then FBtnHome := TFtButton(w);

  w := FindWidget('btnRefresh');
  if w is TFtButton then FBtnRefresh := TFtButton(w);

  w := FindWidget('btnNewFolder');
  if w is TFtButton then FBtnNewFolder := TFtButton(w);

  w := FindWidget('btnHidden');
  if w is TFtButton then
  begin
    FBtnHidden := TFtButton(w);
    FBtnHidden.OnToggle := @ActionToggleHidden;
  end;

  w := FindWidget('fileContextMenu');
  if w is TFtPopupMenu then FContextMenu := TFtPopupMenu(w);

  // Wire up button signals
  if FBtnBack <> nil then FBtnBack.OnClick := @ActionBack;
  if FBtnForward <> nil then FBtnForward.OnClick := @ActionForward;
  if FBtnUp <> nil then FBtnUp.OnClick := @ActionUp;
  if FBtnHome <> nil then FBtnHome.OnClick := @ActionHome;
  if FBtnRefresh <> nil then FBtnRefresh.OnClick := @ActionRefresh;
  if FBtnNewFolder <> nil then FBtnNewFolder.OnClick := @ActionNewFolder;

  // Wire up widget signals
  if FPathBar <> nil then FPathBar.OnNavigate := @HandlePathNavigate;
  if FPlacesTree <> nil then FPlacesTree.OnSelect := @HandleTreeSelect;
  if FSearchEntry <> nil then FSearchEntry.OnChange := @HandleSearchChange;

  if FFileTable <> nil then
  begin
    FFileTable.OnSelectRow := @HandleTableSelectRow;
    FFileTable.OnRowDoubleClick := @HandleTableRowDoubleClick;
    FFileTable.OnColumnClick := @HandleColumnClick;
    if FContextMenu <> nil then
      FFileTable.ContextMenuHandle := FContextMenu.Handle;
  end;

  // Wire up Menu actions
  HookMenu('newFolderItem', @MenuNewFolder);
  HookMenu('propertiesItem', @MenuProperties);
  HookMenu('quitItem', @MenuQuit);
  HookMenu('cutItem', @MenuCut);
  HookMenu('copyItem', @MenuCopy);
  HookMenu('renameItem', @MenuRename);
  HookMenu('deleteItem', @MenuDelete);
  HookMenu('selectAllItem', @MenuSelectAll);
  HookMenu('refreshItem', @MenuRefresh);
  HookMenu('showHiddenItem', @MenuToggleHidden);
  HookMenu('goHomeItem', @MenuGoHome);
  HookMenu('goDesktopItem', @MenuGoDesktop);
  HookMenu('goDocumentsItem', @MenuGoDocuments);
  HookMenu('goDownloadsItem', @MenuGoDownloads);
  HookMenu('goParentItem', @MenuGoParent);
  HookMenu('goRootItem', @MenuGoRoot);
  HookMenu('openTerminalItem', @MenuOpenTerminal);
  HookMenu('aboutItem', @MenuAbout);

  // Context menu actions
  HookMenu('ctxOpenItem', @MenuOpenSelection);
  HookMenu('ctxOpenTerminalItem', @MenuOpenTerminal);
  HookMenu('ctxCutItem', @MenuCut);
  HookMenu('ctxCopyItem', @MenuCopy);
  HookMenu('ctxRenameItem', @MenuRename);
  HookMenu('ctxDeleteItem', @MenuDelete);
  HookMenu('ctxPropertiesItem', @MenuProperties);

  SetupPlacesIcons();
end;

procedure TFileSamaWindow.HookMenu(const AId: string; AHandler: TFtMenuClickEvent);
var
  mi: TFtMenuItem;
begin
  mi := FindMenuItem(AId);
  if mi <> nil then
    mi.OnClick := AHandler;
end;

procedure TFileSamaWindow.NavigateTo(const APath: string; AAddToHistory: Boolean);
var
  resolved: string;
begin
  if FNavigating then Exit;
  FNavigating := True;
  try
    resolved := ExpandFileName(APath);
    if not DirectoryExists(resolved) then Exit;

    if AAddToHistory then
    begin
      // Trim forward history if we are in the middle of stack
      while FHistory.Count > FHistoryIndex + 1 do
        FHistory.Delete(FHistory.Count - 1);
      FHistory.Add(resolved);
      FHistoryIndex := FHistory.Count - 1;
    end;

    FModel.ScanDirectory(resolved);

    if FPathBar <> nil then
      FPathBar.Path := resolved;

    Title := ExtractFileName(resolved) + ' — Files';
    if Title = ' — Files' then
      Title := '/ — Files';

    RefreshTable();
    UpdateNavigationState();
    UpdateStatusBar();
  finally
    FNavigating := False;
  end;
end;

procedure TFileSamaWindow.RefreshTable();
var
  i, rowIdx: Integer;
  item: TFileItem;
  matches: Boolean;
begin
  if FFileTable = nil then Exit;

  FFileTable.ClearRows();

  for i := 0 to FModel.Count - 1 do
  begin
    item := FModel[i];

    // Filter check
    if FFilterQuery <> '' then
    begin
      matches := Pos(LowerCase(FFilterQuery), LowerCase(item.Name)) > 0;
      if not matches then Continue;
    end;

    rowIdx := FFileTable.AddRow();
    FFileTable.SetCell(rowIdx, 0, item.Name);
    FFileTable.SetCell(rowIdx, 1, item.SizeFormatted);
    FFileTable.SetCell(rowIdx, 2, item.ModTimeFormatted);
    FFileTable.SetCell(rowIdx, 3, item.TypeDescription);
    FFileTable.SetCellIcon(rowIdx, 0, GetFileIcon(item.IsDirectory, item.Name));
  end;
end;

procedure TFileSamaWindow.UpdateNavigationState();
begin
  if FBtnBack <> nil then
    FBtnBack.Enabled := (FHistoryIndex > 0);

  if FBtnForward <> nil then
    FBtnForward.Enabled := (FHistoryIndex < FHistory.Count - 1);

  if FBtnUp <> nil then
    FBtnUp.Enabled := (FModel.CurrentPath <> '/') and (FModel.CurrentPath <> '');
end;

procedure TFileSamaWindow.UpdateStatusBar();
var
  dirs, files: Integer;
  i: Integer;
  infoStr: string;
begin
  dirs := 0;
  files := 0;
  for i := 0 to FModel.Count - 1 do
  begin
    if FModel[i].IsDirectory then
      Inc(dirs)
    else
      Inc(files);
  end;

  infoStr := Format('%d items (%d folders, %d files)', [FModel.Count, dirs, files]);
  if FStatusText <> nil then
    FStatusText.Text := infoStr;

  if FStatusRight <> nil then
    FStatusRight.Text := GetAvailableDiskSpace(FModel.CurrentPath);
end;

// -----------------------------------------------------------------------------
// Signal Handlers
// -----------------------------------------------------------------------------

procedure TFileSamaWindow.HandlePathNavigate(Sender: TFtPathBar; const Path: string);
begin
  NavigateTo(Path, True);
end;

procedure TFileSamaWindow.HandleTreeSelect(Sender: TFtTreeView; Node: TFtTreeNode);
var
  nodeName: string;
begin
  if Node = nil then Exit;
  nodeName := Node.Text;

  if nodeName = 'Home' then
    NavigateTo(GetHomeDir())
  else if nodeName = 'Desktop' then
    NavigateTo(GetDesktopDir())
  else if nodeName = 'Documents' then
    NavigateTo(GetDocumentsDir())
  else if nodeName = 'Downloads' then
    NavigateTo(GetDownloadsDir())
  else if nodeName = 'Pictures' then
    NavigateTo(GetPicturesDir())
  else if nodeName = 'Music' then
    NavigateTo(GetMusicDir())
  else if nodeName = 'Videos' then
    NavigateTo(GetVideosDir())
  else if nodeName = 'Root' then
    NavigateTo('/');
end;

procedure TFileSamaWindow.HandleTableSelectRow(Sender: TFtTable; RowIndex: Integer);
var
  item: TFileItem;
begin
  if (RowIndex >= 0) and (RowIndex < FModel.Count) then
  begin
    item := FModel[RowIndex];
    if FStatusText <> nil then
      FStatusText.Text := Format('"%s" selected (%s, %s)', [item.Name, item.TypeDescription, item.SizeFormatted]);
  end;
end;

procedure TFileSamaWindow.HandleTableRowDoubleClick(Sender: TFtTable; RowIndex: Integer);
var
  item: TFileItem;
begin
  if (RowIndex >= 0) and (RowIndex < FModel.Count) then
  begin
    item := FModel[RowIndex];
    if item.IsDirectory then
      NavigateTo(item.FullPath, True)
    else
      LaunchFile(item.FullPath);
  end;
end;

procedure TFileSamaWindow.HandleSearchChange(Sender: TFtWidget; const AText: string);
begin
  FFilterQuery := Trim(AText);
  RefreshTable();
end;

// -----------------------------------------------------------------------------
// Button Action Handlers
// -----------------------------------------------------------------------------

procedure TFileSamaWindow.ActionBack(Sender: TFtButton);
begin
  if FHistoryIndex > 0 then
  begin
    Dec(FHistoryIndex);
    NavigateTo(FHistory[FHistoryIndex], False);
  end;
end;

procedure TFileSamaWindow.ActionForward(Sender: TFtButton);
begin
  if FHistoryIndex < FHistory.Count - 1 then
  begin
    Inc(FHistoryIndex);
    NavigateTo(FHistory[FHistoryIndex], False);
  end;
end;

procedure TFileSamaWindow.ActionUp(Sender: TFtButton);
begin
  NavigateTo(GetParentPath(FModel.CurrentPath), True);
end;

procedure TFileSamaWindow.ActionHome(Sender: TFtButton);
begin
  NavigateTo(GetHomeDir(), True);
end;

procedure TFileSamaWindow.ActionRefresh(Sender: TFtButton);
begin
  NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.ActionNewFolder(Sender: TFtButton);
begin
  MenuNewFolder(nil);
end;

procedure TFileSamaWindow.ActionToggleHidden(Sender: TFtButton; AToggled: Boolean);
var
  mi: TFtMenuItem;
begin
  FModel.ShowHidden := AToggled;
  mi := FindMenuItem('showHiddenItem');
  if mi <> nil then
    mi.Checked := AToggled;
  NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.HandleColumnClick(Sender: TFtTable; ColumnIndex: Integer);
begin
  if FModel.SortColumn = ColumnIndex then
    FModel.Sort(ColumnIndex, not FModel.SortAscending)
  else
    FModel.Sort(ColumnIndex, True);
  RefreshTable();
end;

// -----------------------------------------------------------------------------
// Menu Action Handlers
// -----------------------------------------------------------------------------

procedure TFileSamaWindow.MenuNewFolder(Sender: TFtMenuItem);
var
  folderName: string;
  i: Integer;
begin
  folderName := 'New Folder';
  i := 1;
  while DirectoryExists(FModel.CurrentPath + '/' + folderName) do
  begin
    Inc(i);
    folderName := Format('New Folder %d', [i]);
  end;

  if CreateNewFolder(FModel.CurrentPath, folderName) then
    NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.MenuProperties(Sender: TFtMenuItem);
var
  selRow: Integer;
  item: TFileItem;
  msg: string;
begin
  if FFileTable = nil then Exit;
  selRow := FFileTable.SelectedRow;
  if (selRow >= 0) and (selRow < FModel.Count) then
  begin
    item := FModel[selRow];
    msg := Format('Name: %s' + LineEnding +
                  'Path: %s' + LineEnding +
                  'Type: %s (%s)' + LineEnding +
                  'Size: %s' + LineEnding +
                  'Permissions: %s' + LineEnding +
                  'Modified: %s',
                  [item.Name, item.FullPath, item.TypeDescription, item.MimeType,
                   item.SizeFormatted, item.Permissions, item.ModTimeFormatted]);
    TFtMessageDialog.ShowMessage(msg, 'Item Properties');
  end
  else
  begin
    msg := Format('Location: %s' + LineEnding +
                  'Available Space: %s',
                  [FModel.CurrentPath, GetAvailableDiskSpace(FModel.CurrentPath)]);
    TFtMessageDialog.ShowMessage(msg, 'Directory Properties');
  end;
end;

procedure TFileSamaWindow.MenuQuit(Sender: TFtMenuItem);
begin
  Close();
end;

procedure TFileSamaWindow.MenuCut(Sender: TFtMenuItem);
begin
  // Clipboard cut stub
end;

procedure TFileSamaWindow.MenuCopy(Sender: TFtMenuItem);
begin
  // Clipboard copy stub
end;

procedure TFileSamaWindow.MenuRename(Sender: TFtMenuItem);
begin
  // Rename stub
end;

procedure TFileSamaWindow.MenuDelete(Sender: TFtMenuItem);
var
  selRow: Integer;
  item: TFileItem;
begin
  if FFileTable = nil then Exit;
  selRow := FFileTable.SelectedRow;
  if (selRow >= 0) and (selRow < FModel.Count) then
  begin
    item := FModel[selRow];
    DeleteItem(item.FullPath);
    NavigateTo(FModel.CurrentPath, False);
  end;
end;

procedure TFileSamaWindow.MenuSelectAll(Sender: TFtMenuItem);
begin
  if FFileTable <> nil then
    FFileTable.SelectAll();
end;

procedure TFileSamaWindow.MenuToggleHidden(Sender: TFtMenuItem);
begin
  FModel.ShowHidden := not FModel.ShowHidden;
  if Sender <> nil then
    Sender.Checked := FModel.ShowHidden;
  if FBtnHidden <> nil then
    FBtnHidden.Toggled := FModel.ShowHidden;
  NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.MenuRefresh(Sender: TFtMenuItem);
begin
  ActionRefresh(nil);
end;

procedure TFileSamaWindow.MenuGoHome(Sender: TFtMenuItem);
begin
  NavigateTo(GetHomeDir(), True);
end;

procedure TFileSamaWindow.MenuGoDesktop(Sender: TFtMenuItem);
begin
  NavigateTo(GetDesktopDir(), True);
end;

procedure TFileSamaWindow.MenuGoDocuments(Sender: TFtMenuItem);
begin
  NavigateTo(GetDocumentsDir(), True);
end;

procedure TFileSamaWindow.MenuGoDownloads(Sender: TFtMenuItem);
begin
  NavigateTo(GetDownloadsDir(), True);
end;

procedure TFileSamaWindow.MenuGoParent(Sender: TFtMenuItem);
begin
  NavigateTo(GetParentPath(FModel.CurrentPath), True);
end;

procedure TFileSamaWindow.MenuGoRoot(Sender: TFtMenuItem);
begin
  NavigateTo('/', True);
end;

procedure TFileSamaWindow.MenuOpenTerminal(Sender: TFtMenuItem);
begin
  LaunchTerminalAt(FModel.CurrentPath);
end;

procedure TFileSamaWindow.MenuAbout(Sender: TFtMenuItem);
begin
  TFtMessageDialog.ShowMessage('Samarinda Files (filesama)' + LineEnding +
                               'FTML Desktop File Manager' + LineEnding +
                               'Copyright (c) 2026 Dio Affriza',
                               'About Filesama');
end;

procedure TFileSamaWindow.MenuOpenSelection(Sender: TFtMenuItem);
var
  selRow: Integer;
  item: TFileItem;
begin
  if FFileTable = nil then Exit;
  selRow := FFileTable.SelectedRow;
  if (selRow >= 0) and (selRow < FModel.Count) then
  begin
    item := FModel[selRow];
    if item.IsDirectory then
      NavigateTo(item.FullPath, True)
    else
      LaunchFile(item.FullPath);
  end;
end;

end.
