{ ═══════════════════════════════════════════════════════════════════════════════
  main.pas - Main form of the Lazarus i18n Template.

  Demonstrates every translation category exposed by TLocaleManager (uLocale):
  menus, toolbar + tooltips, labels, an edit with a TextHint, a status bar,
  confirmation / welcome dialogs and formatted messages (%s, %d, %%).

  Every visible string is applied through Locale.* in UpdateLocale, which is
  called once at startup and again on every language change (hot reload).

  License: MIT (see LICENSE at the repository root).
  ═══════════════════════════════════════════════════════════════════════════════ }

unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, Menus, ComCtrls, StdCtrls;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnGreet: TButton;
    btnConfirm: TButton;
    edtName: TEdit;
    lblTitle: TLabel;
    lblIntro: TLabel;
    lblName: TLabel;
    lblProgressCaption: TLabel;
    lblProgress: TLabel;
    lblSummary: TLabel;
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileRecent: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuFileExit: TMenuItem;
    mnuEdit: TMenuItem;
    mnuEditCut: TMenuItem;
    mnuEditCopy: TMenuItem;
    mnuEditPaste: TMenuItem;
    mnuEditSelectAll: TMenuItem;
    mnuOptions: TMenuItem;
    mnuOptionsLanguage: TMenuItem;
    mnuOptionsSep1: TMenuItem;
    mnuOptionsPreferences: TMenuItem;
    mnuHelp: TMenuItem;
    mnuHelpAbout: TMenuItem;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    tbProgress: TTrackBar;
    ToolBar1: TToolBar;
    tbOpen: TToolButton;
    tbOptions: TToolButton;
    tbAbout: TToolButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGreetClick(Sender: TObject);
    procedure btnConfirmClick(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure mnuFileOpenClick(Sender: TObject);
    procedure mnuFileExitClick(Sender: TObject);
    procedure mnuEditCutClick(Sender: TObject);
    procedure mnuEditCopyClick(Sender: TObject);
    procedure mnuEditPasteClick(Sender: TObject);
    procedure mnuEditSelectAllClick(Sender: TObject);
    procedure mnuOptionsPreferencesClick(Sender: TObject);
    procedure mnuHelpAboutClick(Sender: TObject);
    procedure tbProgressChange(Sender: TObject);
  private
    FRecentFiles: TStringList;
    procedure RebuildRecentMenu;
    procedure AsyncRebuildRecent(Data: PtrInt);
    procedure RecentItemClick(Sender: TObject);
    procedure mnuClearRecentClick(Sender: TObject);
    procedure OpenFile(const AFileName: string);
    procedure UpdateProgressLabel;
    procedure UpdateSummaryLabel;
    function CurrentLanguageName: string;
    { Builds the Options > Language submenu: one checkable item per available
      language, the current one ticked. }
    procedure UpdateLanguageMenu;
    procedure OnLanguageClick(Sender: TObject);
    procedure AsyncApplyLocale(Data: PtrInt);
    { Picks the language at startup: saved preference > OS language > English. }
    procedure InitializeLanguage;
    { Called by the options dialog (TfrmOptions.OnLanguageApply) to switch
      language on the fly, persist the choice, then refresh every open form. }
    procedure DoLanguageApply(Sender: TObject);
  public
    { Re-applies every visible string from the active language. Call it at
      startup and after each language change. }
    procedure UpdateLocale;
  end;

const
  APP_VERSION = '1.0.0';
  APP_AUTHOR  = 'Nicolas DEOUX';

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses
  LazUTF8, uLocale, uConfig, frmoptions;

{ Helper: confirmation dialog whose buttons are translated through Locale. }
function ConfirmYesNo(const AMessage: string): Boolean;
begin
  Result := QuestionDlg(
    Locale.Dialog('ConfirmTitle', 'Confirmation'),
    AMessage,
    mtConfirmation,
    [mrYes, Locale.Button('Yes', 'Yes'),
     mrNo, Locale.Button('No', 'No')],
    '') = mrYes;
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FRecentFiles := TStringList.Create;
  InitializeLanguage;   { restore the saved language (or detect the OS one) }
  UpdateLocale;         { apply it to every control }
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FRecentFiles.Free;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmYesNo(
    Locale.Dialog('ConfirmExit', 'Are you sure you want to quit?'));
end;

{ ── Localization ──────────────────────────────────────────────────────────── }

procedure TfrmMain.UpdateLocale;
begin
  Caption := Locale.Label_('AppTitle', 'Lazarus i18n Template');

  { Menus }
  mnuFile.Caption               := Locale.Menu('File', '&File');
  mnuFileOpen.Caption           := Locale.Menu('FileOpen', '&Open File...');
  mnuFileRecent.Caption         := Locale.Menu('FileRecent', '&Recent Files');
  mnuFileExit.Caption           := Locale.Menu('FileExit', 'E&xit');
  mnuEdit.Caption               := Locale.Menu('Edit', '&Edit');
  mnuEditCut.Caption            := Locale.Menu('EditCut', 'Cu&t');
  mnuEditCopy.Caption           := Locale.Menu('EditCopy', '&Copy');
  mnuEditPaste.Caption          := Locale.Menu('EditPaste', '&Paste');
  mnuEditSelectAll.Caption      := Locale.Menu('EditSelectAll', 'Select &All');
  mnuOptions.Caption            := Locale.Menu('Options', '&Options');
  mnuOptionsLanguage.Caption    := Locale.Menu('OptionsLanguage', '&Language');
  mnuOptionsPreferences.Caption := Locale.Menu('OptionsPreferences', '&Preferences...');
  mnuHelp.Caption               := Locale.Menu('Help', '&Help');
  mnuHelpAbout.Caption          := Locale.Menu('HelpAbout', '&About');

  { Toolbar (caption + tooltip) }
  tbOpen.Caption     := Locale.Button('Open', 'Open');
  tbOpen.Hint        := Locale.Tooltip('Open', 'Open a file');
  tbOptions.Caption  := Locale.Button('Options', 'Options');
  tbOptions.Hint     := Locale.Tooltip('Options', 'Open the options dialog');
  tbAbout.Caption    := Locale.Button('About', 'About');
  tbAbout.Hint       := Locale.Tooltip('About', 'About this application');

  { Labels and input }
  lblTitle.Caption           := Locale.Label_('Title', 'Lazarus i18n Template');
  lblIntro.Caption           := Locale.Label_('Intro',
    'A reusable template for multilingual desktop applications.');
  lblName.Caption            := Locale.Label_('Name', 'Your name:');
  edtName.TextHint           := Locale.Label_('NameHint', 'Type your name here');
  edtName.Hint               := Locale.Tooltip('Name', 'Enter the name used in the greeting');
  lblProgressCaption.Caption := Locale.Label_('Progress',
    'Move the slider to see a formatted percentage:');

  { Buttons }
  btnGreet.Caption   := Locale.Button('Greet', 'Greet');
  btnGreet.Hint      := Locale.Tooltip('Greet', 'Show a personalized welcome message');
  btnConfirm.Caption := Locale.Button('Confirm', 'Reset...');

  { Open dialog }
  OpenDialog1.Title  := Locale.Dialog('OpenFileTitle', 'Open File');
  OpenDialog1.Filter := Locale.Dialog('OpenFileFilter', 'All files|*.*');

  { Dynamic / formatted content }
  RebuildRecentMenu;
  UpdateLanguageMenu;
  UpdateProgressLabel;
  UpdateSummaryLabel;

  { Status bar }
  StatusBar1.Panels[0].Text := Locale.Status('Ready', 'Ready');
  StatusBar1.Panels[1].Text := Format('%s (%s)',
    [CurrentLanguageName, Locale.CurrentLanguage]);
end;

procedure TfrmMain.InitializeLanguage;
var
  Lang: string;
begin
  { Priority order:
      1. the language saved in the configuration (the user's last choice);
      2. otherwise the OS language detected by TLocaleManager at startup;
      3. otherwise English. }
  Lang := Config.Language;
  if Lang = '' then
  begin
    if (Locale.CurrentLanguage <> '') and
       (Locale.AvailableLanguages.IndexOf(Locale.CurrentLanguage) >= 0) then
      Lang := Locale.CurrentLanguage
    else
      Lang := 'en';
  end;
  Locale.LoadLanguage(Lang);
end;

procedure TfrmMain.DoLanguageApply(Sender: TObject);
var
  Code: string;
begin
  Code := OptionsForm.SelectedLanguageCode;
  if Code <> '' then
  begin
    Locale.LoadLanguage(Code);
    { Remember the choice and persist it now, so it is restored next launch. }
    Config.Language := Code;
    Config.Save;
  end;
  { Refresh every open form so the change is visible immediately. }
  UpdateLocale;
  OptionsForm.UpdateLocale;
  StatusBar1.Panels[0].Text := Locale.Status('LanguageChanged', 'Language changed');
end;

procedure TfrmMain.UpdateLanguageMenu;
var
  I, OriginalIndex: Integer;
  Item: TMenuItem;
  Sorted: TStringList;
begin
  mnuOptionsLanguage.Clear;

  { Sort languages alphabetically by display name, keeping each one's original
    index (which maps 1:1 to AvailableLanguages) in Objects. }
  Sorted := TStringList.Create;
  try
    for I := 0 to Locale.LanguageNames.Count - 1 do
      Sorted.AddObject(Locale.LanguageNames[I], TObject(PtrInt(I)));
    Sorted.Sort;

    for I := 0 to Sorted.Count - 1 do
    begin
      OriginalIndex := PtrInt(Sorted.Objects[I]);
      Item := TMenuItem.Create(MainMenu1);
      Item.Caption := Sorted[I];                       { endonym, not translated }
      Item.Tag := OriginalIndex;
      Item.RadioItem := True;
      Item.Checked :=
        (Locale.AvailableLanguages[OriginalIndex] = Locale.CurrentLanguage);
      Item.OnClick := @OnLanguageClick;
      mnuOptionsLanguage.Add(Item);
    end;
  finally
    Sorted.Free;
  end;
end;

procedure TfrmMain.OnLanguageClick(Sender: TObject);
var
  Idx: Integer;
  Code: string;
begin
  Idx := (Sender as TMenuItem).Tag;
  if (Idx < 0) or (Idx >= Locale.AvailableLanguages.Count) then
    Exit;
  Code := Locale.AvailableLanguages[Idx];

  Locale.LoadLanguage(Code);
  { Persist the choice, restored at next launch (same as the Options dialog). }
  Config.Language := Code;
  Config.Save;
  StatusBar1.Panels[0].Text := Locale.Status('LanguageChanged', 'Language changed');

  { Defer the full refresh: UpdateLocale rebuilds this very submenu, which would
    free the clicked item (the Sender) while it is still handling its click. }
  Application.QueueAsyncCall(@AsyncApplyLocale, 0);
end;

procedure TfrmMain.AsyncApplyLocale(Data: PtrInt);
begin
  UpdateLocale;
  OptionsForm.UpdateLocale;
end;

function TfrmMain.CurrentLanguageName: string;
var
  Idx: Integer;
begin
  Idx := Locale.AvailableLanguages.IndexOf(Locale.CurrentLanguage);
  if (Idx >= 0) and (Idx < Locale.LanguageNames.Count) then
    Result := Locale.LanguageNames[Idx]
  else
    Result := Locale.CurrentLanguage;
end;

{ ── Formatted messages (demonstrate %s, %d and %%) ────────────────────────── }

procedure TfrmMain.UpdateProgressLabel;
begin
  lblProgress.Caption := Format(
    Locale.Message('ProgressFormat', 'Progress: %d%%'), [tbProgress.Position]);
end;

procedure TfrmMain.UpdateSummaryLabel;
var
  UserName: string;
begin
  UserName := Trim(edtName.Text);
  if UserName = '' then
    UserName := Locale.Dialog('DefaultName', 'World');
  lblSummary.Caption := Format(
    Locale.Message('SummaryFormat', 'Hello %s — %d character(s), %d%% done'),
    [UserName, UTF8Length(UserName), tbProgress.Position]);
end;

procedure TfrmMain.tbProgressChange(Sender: TObject);
begin
  UpdateProgressLabel;
  UpdateSummaryLabel;
end;

procedure TfrmMain.edtNameChange(Sender: TObject);
begin
  UpdateSummaryLabel;
end;

{ ── Recent files (dynamic, translated menu) ───────────────────────────────── }

procedure TfrmMain.RebuildRecentMenu;
var
  I: Integer;
  Item: TMenuItem;
begin
  mnuFileRecent.Clear;

  if FRecentFiles.Count = 0 then
  begin
    Item := TMenuItem.Create(MainMenu1);
    Item.Caption := Locale.Menu('NoRecentFiles', '(No recent files)');
    Item.Enabled := False;
    mnuFileRecent.Add(Item);
    Exit;
  end;

  for I := 0 to FRecentFiles.Count - 1 do
  begin
    Item := TMenuItem.Create(MainMenu1);
    Item.Caption := FRecentFiles[I];
    Item.Tag := I;
    Item.OnClick := @RecentItemClick;
    mnuFileRecent.Add(Item);
  end;

  Item := TMenuItem.Create(MainMenu1);
  Item.Caption := '-';
  mnuFileRecent.Add(Item);

  Item := TMenuItem.Create(MainMenu1);
  Item.Caption := Locale.Menu('ClearRecentFiles', 'Clear Recent Files');
  Item.OnClick := @mnuClearRecentClick;
  mnuFileRecent.Add(Item);
end;

procedure TfrmMain.AsyncRebuildRecent(Data: PtrInt);
begin
  RebuildRecentMenu;
end;

procedure TfrmMain.RecentItemClick(Sender: TObject);
begin
  { Read-only on purpose: do not rebuild the menu from a child item's own
    OnClick, that item is the Sender and would be freed mid-event. }
  StatusBar1.Panels[0].Text := Format(
    Locale.Status('FileOpened', 'File opened: %s'),
    [ExtractFileName(FRecentFiles[(Sender as TMenuItem).Tag])]);
end;

procedure TfrmMain.mnuClearRecentClick(Sender: TObject);
begin
  if ConfirmYesNo(Locale.Dialog('ConfirmClear',
    'Do you really want to clear the recent files list?')) then
  begin
    FRecentFiles.Clear;
    StatusBar1.Panels[0].Text := Locale.Status('RecentCleared', 'Recent files cleared');
    { Defer the rebuild: the Sender is the dynamic "Clear" item and would be
      freed while still handling its own click. }
    Application.QueueAsyncCall(@AsyncRebuildRecent, 0);
  end;
end;

procedure TfrmMain.OpenFile(const AFileName: string);
var
  Idx: Integer;
begin
  Idx := FRecentFiles.IndexOf(AFileName);
  if Idx >= 0 then
    FRecentFiles.Delete(Idx);
  FRecentFiles.Insert(0, AFileName);
  while FRecentFiles.Count > 8 do
    FRecentFiles.Delete(FRecentFiles.Count - 1);
  RebuildRecentMenu;
  StatusBar1.Panels[0].Text := Format(
    Locale.Status('FileOpened', 'File opened: %s'), [ExtractFileName(AFileName)]);
end;

{ ── Menu / button handlers ────────────────────────────────────────────────── }

procedure TfrmMain.mnuFileOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    OpenFile(OpenDialog1.FileName);
end;

procedure TfrmMain.mnuFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.mnuEditCutClick(Sender: TObject);
begin
  edtName.CutToClipboard;
end;

procedure TfrmMain.mnuEditCopyClick(Sender: TObject);
begin
  edtName.CopyToClipboard;
end;

procedure TfrmMain.mnuEditPasteClick(Sender: TObject);
begin
  edtName.PasteFromClipboard;
end;

procedure TfrmMain.mnuEditSelectAllClick(Sender: TObject);
begin
  edtName.SelectAll;
  edtName.SetFocus;
end;

procedure TfrmMain.btnGreetClick(Sender: TObject);
var
  UserName: string;
begin
  UserName := Trim(edtName.Text);
  if UserName = '' then
    UserName := Locale.Dialog('DefaultName', 'World');
  QuestionDlg(
    Locale.Dialog('WelcomeTitle', 'Welcome'),
    Format(Locale.Dialog('Welcome', 'Welcome, %s!'), [UserName]),
    mtInformation,
    [mrOK, Locale.Button('OK', 'OK')],
    '');
end;

procedure TfrmMain.btnConfirmClick(Sender: TObject);
begin
  if ConfirmYesNo(Locale.Dialog('ConfirmReset', 'Reset the name field?')) then
  begin
    edtName.Clear;
    UpdateSummaryLabel;
    StatusBar1.Panels[0].Text := Locale.Status('Ready', 'Ready');
  end;
end;

procedure TfrmMain.mnuOptionsPreferencesClick(Sender: TObject);
begin
  OptionsForm.OnLanguageApply := @DoLanguageApply;
  OptionsForm.InitFromCurrent;
  OptionsForm.ShowModal;
end;

procedure TfrmMain.mnuHelpAboutClick(Sender: TObject);
var
  S: string;
begin
  S := Locale.GetString('About', 'AppName', 'Lazarus i18n Template') + ' ' +
       Locale.GetString('About', 'Version', 'Version') + ' ' + APP_VERSION +
       LineEnding + LineEnding +
       Locale.GetString('About', 'Description',
         'A reusable template for multilingual Lazarus / Free Pascal desktop applications.') +
       LineEnding + LineEnding +
       Locale.GetString('About', 'Author', 'Author') + ': ' + APP_AUTHOR + LineEnding +
       Locale.GetString('About', 'License', 'License') + ': MIT';
  QuestionDlg(
    Locale.GetString('About', 'Title', 'About'),
    S,
    mtInformation,
    [mrOK, Locale.Button('Close', 'Close')],
    '');
end;

end.
