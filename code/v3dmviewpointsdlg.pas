{
  Copyright 2017-2018 Michalis Kamburelis and Jan Adamec.

  This file is part of "view3dscene-mobile".

  "view3dscene-mobile" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "view3dscene-mobile" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

unit V3DMViewpointsDlg;

interface

uses Classes, SysUtils,
  CastleControls, CastleScene, CastleUIState, CastleKeysMouse,
  CastleControls_TableView;

type
  TViewpointSelectedEvent = procedure (ViewpointIdx : integer) of object;

  TStateViewpointsDlg = class(TUIState)
  strict private
    type
      TViewpointsDialog = class(TCastleRectangleControl, ICastleTableViewDataSource)
      strict private
        procedure TableViewDidSelectCell(Row: Integer; Sender: TCastleTableView);
      public
        constructor Create(AOwner: TComponent); reintroduce;
        procedure DoAnswered;

        function TableViewNumberOfRows(Sender: TCastleTableView): Integer;
        procedure TableViewUpdateCell(Cell: TCastleTableViewCell; Row: Integer; Sender: TCastleTableView);
      end;
    var
      Dialog: TViewpointsDialog;
  public
    FScene: TCastleScene;
    FCurrentViewpointIdx: integer;
    FOnViewpointSelected: TViewpointSelectedEvent;
    procedure Start; override;
    function Press(const Event: TInputPressRelease): boolean; override;
  end;

var
  StateViewpointsDlg: TStateViewpointsDlg;

implementation

uses
  Math,
  CastleColors, CastleWindow, CastleUIControls, CastleFilesUtils, CastleLog,
  CastleUtils, CastleVectors;

{ TStateViewpointsDlg.TViewpointsDialog ---------------------------------------------- }

constructor TStateViewpointsDlg.TViewpointsDialog.Create(AOwner: TComponent);
var
  InsideRect: TCastleRectangleControl;
  LabelWndTitle: TCastleLabel;
  TableTop, Diff: integer;
  TableView: TCastleTableView;
begin
  inherited Create(AOwner);

  Width := Min(400, StateViewpointsDlg.StateContainer.UnscaledWidth - 20);
  Height := Min(500, StateViewpointsDlg.StateContainer.UnscaledHeight - 20);
  Color := Black;

  InsideRect := TCastleRectangleControl.Create(Self);
  InsideRect.Width := CalculatedWidth - 4;
  InsideRect.Height := CalculatedHeight - 4;
  InsideRect.Color := HexToColor('505050');
  InsideRect.Anchor(hpMiddle);
  InsideRect.Anchor(vpMiddle);
  InsertFront(InsideRect);

  LabelWndTitle := TCastleLabel.Create(Self);
  LabelWndTitle.Color := White;
  LabelWndTitle.Html := true;
  LabelWndTitle.Caption := '<b>Viewpoints</b>';
  LabelWndTitle.Anchor(hpMiddle);
  LabelWndTitle.Anchor(vpTop, 0);
  InsideRect.InsertFront(LabelWndTitle);

  TableTop := -(LabelWndTitle.CalculatedHeight + 14);

  TableView := TCastleTableView.Create(Self);
  TableView.EnableDragging := true;
  TableView.OnSelectCell := @TableViewDidSelectCell;
  TableView.Width := InsideRect.Width - 10;
  TableView.Height := InsideRect.Height - 5 + TableTop;
  TableView.Anchor(hpMiddle);
  TableView.Anchor(vpTop, TableTop);
  InsideRect.InsertFront(TableView);
  TableView.DataSource := Self;

  // when tableView contents take less space, make the window smaller
  if TableView.ScrollArea.Height < TableView.Height then
  begin
    Diff := TableView.Height - TableView.ScrollArea.Height;
    TableView.Height := TableView.ScrollArea.Height;
    Height := Height - Diff;
    InsideRect.Height := CalculatedHeight - 4;
  end;
end;

function TStateViewpointsDlg.TViewpointsDialog.TableViewNumberOfRows(Sender: TCastleTableView): Integer;
begin
  if Assigned(StateViewpointsDlg.FScene) then
     Result := StateViewpointsDlg.FScene.ViewpointsCount
  else
     Result := 0;
end;

procedure TStateViewpointsDlg.TViewpointsDialog.TableViewUpdateCell(Cell: TCastleTableViewCell; Row: Integer; Sender: TCastleTableView);
begin
  Cell.Color := Vector4(0.2, 0.2, 0.2, 1.0);
  Cell.TextLabel.Caption := StateViewpointsDlg.FScene.GetViewpointName(Row);
  if Row = StateViewpointsDlg.FCurrentViewpointIdx then
    Cell.AccessoryType := tvcaCheckmark;
end;

procedure TStateViewpointsDlg.TViewpointsDialog.TableViewDidSelectCell(Row: Integer; Sender: TCastleTableView);
begin
  if Assigned(StateViewpointsDlg.FOnViewpointSelected) then
    StateViewpointsDlg.FOnViewpointSelected(Row);

  DoAnswered;
end;

procedure TStateViewpointsDlg.TViewpointsDialog.DoAnswered;
begin
  TUIState.Pop(StateViewpointsDlg);
end;

{ TStateViewpointsDlg ------------------------------------------------------------ }

procedure TStateViewpointsDlg.Start;
var
  TransparentBackground: TCastleRectangleControl;
begin
  inherited;

  InterceptInput := true;

  TransparentBackground := TCastleRectangleControl.Create(FreeAtStop);
  TransparentBackground.Color := Theme.BackgroundColor;
  TransparentBackground.FullSize := true;
  InsertFront(TransparentBackground);

  Dialog := TViewpointsDialog.Create(FreeAtStop);
  Dialog.Anchor(hpMiddle);
  Dialog.Anchor(vpMiddle);
  InsertFront(Dialog);
end;

function TStateViewpointsDlg.Press(const Event: TInputPressRelease): boolean;
begin
  Result := inherited;

  // end dialog if clicked outside dialog
  if Event.IsMouseButton(mbLeft) and (not Dialog.ScreenRect.Contains(Event.Position)) then
  begin
    Dialog.DoAnswered;
    Result := true;
  end;
end;

end.
