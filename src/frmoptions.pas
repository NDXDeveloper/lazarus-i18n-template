{ ═══════════════════════════════════════════════════════════════════════════════
  frmoptions.pas - Options dialog of the Lazarus i18n Template.

  Hosts the language selector. The drop-down list is filled from
  Locale.AvailableLanguages / Locale.LanguageNames, and switching language is
  applied on the fly (no restart) through the OnLanguageApply callback, which
  the main form assigns so it can refresh every open window.

  License: MIT (see LICENSE at the repository root).
  ═══════════════════════════════════════════════════════════════════════════════ }

unit frmoptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type

  { TfrmOptions }

  TfrmOptions = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    cmbLanguage: TComboBox;
    gbLanguage: TGroupBox;
    lblLanguage: TLabel;
    lblHint: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FOnLanguageApply: TNotifyEvent;
    FInitialLang: string;
    procedure PopulateLanguages;
  public
    { Prepare the dialog from the active language: fill the list and select the
      current language. Call this before ShowModal. }
    procedure InitFromCurrent;
    { Re-applies every visible string from the active language. }
    procedure UpdateLocale;
    { ISO code currently selected in the combo (e.g. 'en', 'fr'). }
    function SelectedLanguageCode: string;
    { Raised when the user applies a language; the host wires the actual switch. }
    property OnLanguageApply: TNotifyEvent read FOnLanguageApply write FOnLanguageApply;
  end;

var
  { The unit is named "frmoptions", so the global instance cannot also be called
    "frmOptions" (Pascal identifiers are case-insensitive). We use OptionsForm. }
  OptionsForm: TfrmOptions;

implementation

{$R *.lfm}

uses
  uLocale;

{ TfrmOptions }

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  PopulateLanguages;
  UpdateLocale;
end;

procedure TfrmOptions.PopulateLanguages;
var
  I: Integer;
begin
  cmbLanguage.Items.BeginUpdate;
  try
    cmbLanguage.Items.Clear;
    { AvailableLanguages and LanguageNames are parallel lists, so the combo
      index maps 1:1 to a language code. }
    for I := 0 to Locale.LanguageNames.Count - 1 do
      cmbLanguage.Items.Add(Locale.LanguageNames[I]);
  finally
    cmbLanguage.Items.EndUpdate;
  end;
end;

procedure TfrmOptions.InitFromCurrent;
var
  Idx: Integer;
begin
  FInitialLang := Locale.CurrentLanguage;
  PopulateLanguages;
  Idx := Locale.AvailableLanguages.IndexOf(Locale.CurrentLanguage);
  if Idx >= 0 then
    cmbLanguage.ItemIndex := Idx
  else if cmbLanguage.Items.Count > 0 then
    cmbLanguage.ItemIndex := 0;
  UpdateLocale;
end;

function TfrmOptions.SelectedLanguageCode: string;
begin
  if (cmbLanguage.ItemIndex >= 0) and
     (cmbLanguage.ItemIndex < Locale.AvailableLanguages.Count) then
    Result := Locale.AvailableLanguages[cmbLanguage.ItemIndex]
  else
    Result := '';
end;

procedure TfrmOptions.UpdateLocale;
begin
  Caption          := Locale.GetString('Options', 'Title', 'Options');
  gbLanguage.Caption := Locale.GetString('Options', 'LanguageGroup', 'Language');
  lblLanguage.Caption := Locale.GetString('Options', 'Language', 'Language:');
  lblHint.Caption  := Locale.GetString('Options', 'Hint',
    'Changes apply instantly — no need to restart the application.');
  btnOK.Caption     := Locale.Button('OK', 'OK');
  btnCancel.Caption := Locale.Button('Cancel', 'Cancel');
  btnApply.Caption  := Locale.Button('Apply', 'Apply');
end;

procedure TfrmOptions.btnApplyClick(Sender: TObject);
begin
  if Assigned(FOnLanguageApply) then
    FOnLanguageApply(Self);
end;

procedure TfrmOptions.btnOKClick(Sender: TObject);
begin
  if Assigned(FOnLanguageApply) then
    FOnLanguageApply(Self);
  ModalResult := mrOK;
end;

procedure TfrmOptions.btnCancelClick(Sender: TObject);
var
  Idx: Integer;
begin
  { Revert to the language that was active when the dialog opened. }
  if (FInitialLang <> '') and (Locale.CurrentLanguage <> FInitialLang) then
  begin
    Idx := Locale.AvailableLanguages.IndexOf(FInitialLang);
    if Idx >= 0 then
      cmbLanguage.ItemIndex := Idx;
    if Assigned(FOnLanguageApply) then
      FOnLanguageApply(Self);
  end;
  ModalResult := mrCancel;
end;

end.
