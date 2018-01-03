{
  Copyright 2017-2018 Michalis Kamburelis and Jan Adamec.

  This file is part of "view3dscene-mobile".

  "view3dscene-mobile" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "view3dscene-mobile" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "view3dscene-mobile"; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA

  ----------------------------------------------------------------------------
}

{ Implements the application logic, independent from Android / standalone. }
unit Game;

interface

uses CastleWindowTouch;

var
  Window: TCastleWindowTouch;

implementation

uses Classes, SysUtils, Math,
  CastleControls, CastleKeysMouse, CastleFilesUtils, Castle2DSceneManager,
  CastleVectors, CastleBoxes, Castle3D, CastleSceneCore, CastleUtils, CastleColors,
  CastleUIControls, CastleUIState, CastleMessaging, CastleLog, CastleImages,
  CastleCameras, CastleWindow, CastleScene,
  CastleGLImages,
  X3DNodes,
  V3DMInfoDlg, V3DMOptions, V3DMOptionsDlg, V3DMViewpointsDlg;

{ main game stuff ------------------------------------------------------------ }
type
  TButtonsHandler = class
    class procedure BtnNavClick(Sender: TObject);
    class procedure BtnScreenshotClick(Sender: TObject);
    class procedure BtnOptionsClick(Sender: TObject);
    class procedure BtnInfoClick(Sender: TObject);
    class procedure BtnViewpointNextClick(Sender: TObject);
    class procedure BtnViewpointListClick(Sender: TObject);
    class procedure ViewpointSelected(ViewpointIdx: integer);
    class procedure BoundNavigationInfoChanged(Sender: TObject);
  end;

var
  BtnNavWalk, BtnNavFly, BtnNavExamine, {BtnNavTurntable,} BtnOptions,
    BtnViewpointPrev, BtnViewpointNext, BtnViewpointList,
    BtnScreenshot, BtnInfo: TCastleButton;
  ToolbarPanel: TCastlePanel;
  Status: TCastleLabel;

  CurrentViewpointIdx: integer;
  SceneBoundingBox: TTransformNode;

{ One-time initialization. }
procedure ApplicationInitialize;
const
  ButtonPadding = 20;
begin
  AppOptions := TAppOptions.Create;
  AppOptions.Load;

  SceneBoundingBox := nil;
  CurrentViewpointIdx := 0;
  StateInfoDlg := TStateInfoDlg.Create(Application);
  StateOptionsDlg := TStateOptionsDlg.Create(Application);
  StateViewpointsDlg := TStateViewpointsDlg.Create(Application);

  Window.SceneManager.OnBoundNavigationInfoChanged := @TButtonsHandler(nil).BoundNavigationInfoChanged;

  // Create UI
  ToolbarPanel := TCastlePanel.Create(Application);
  ToolbarPanel.VerticalSeparators.Count := 3;
  Window.Controls.InsertFront(ToolbarPanel);
  // TODO: check view3Dscene.CreateStatusToolbar

  BtnNavWalk := TCastleButton.Create(Window);
  //BtnNavWalk.Caption := 'Walk';
  BtnNavWalk.Image := CastleImages.LoadImage(ApplicationData('nav_walk.png'));
  BtnNavWalk.OnClick := @TButtonsHandler(nil).BtnNavClick;
  BtnNavWalk.Toggle := true;
  BtnNavWalk.PaddingHorizontal := ButtonPadding;
  BtnNavWalk.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnNavWalk);

  BtnNavFly := TCastleButton.Create(Window);
  //BtnNavFly.Caption := 'Fly';
  BtnNavFly.Image := CastleImages.LoadImage(ApplicationData('nav_fly.png'));
  BtnNavFly.OnClick := @TButtonsHandler(nil).BtnNavClick;
  BtnNavFly.Toggle := true;
  BtnNavFly.PaddingHorizontal := ButtonPadding;
  BtnNavFly.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnNavFly);

  BtnNavExamine := TCastleButton.Create(Window);
  //BtnNavExamine.Caption := 'Examine';
  BtnNavExamine.Image := CastleImages.LoadImage(ApplicationData('nav_examine.png'));
  BtnNavExamine.OnClick := @TButtonsHandler(nil).BtnNavClick;
  BtnNavExamine.Toggle := true;
  BtnNavExamine.PaddingHorizontal := ButtonPadding;
  BtnNavExamine.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnNavExamine);

  {BtnNavTurntable := TCastleButton.Create(Window);
  BtnNavTurntable.Caption := 'Turntable';
  BtnNavTurntable.OnClick := @TButtonsHandler(nil).BtnNavClick;
  BtnNavTurntable.PaddingHorizontal := ButtonPadding;
  BtnNavTurntable.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnNavTurntable);}

  BtnScreenshot := TCastleButton.Create(Window);
  BtnScreenshot.Image := CastleImages.LoadImage(ApplicationData('screenshot.png'));
  BtnScreenshot.OnClick := @TButtonsHandler(nil).BtnScreenshotClick;
  BtnScreenshot.PaddingHorizontal := ButtonPadding;
  BtnScreenshot.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnScreenshot);

  BtnOptions := TCastleButton.Create(Window);
  BtnOptions.Caption := 'Options';
  BtnOptions.OnClick := @TButtonsHandler(nil).BtnOptionsClick;
  BtnOptions.PaddingHorizontal := ButtonPadding;
  BtnOptions.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnOptions);

  BtnInfo := TCastleButton.Create(Window);
  BtnInfo.Caption := '(i)';
  BtnInfo.OnClick := @TButtonsHandler(nil).BtnInfoClick;
  BtnInfo.PaddingHorizontal := ButtonPadding;
  BtnInfo.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnInfo);

  BtnViewpointPrev := TCastleButton.Create(Window);
  BtnViewpointPrev.Caption := '<';
  BtnViewpointPrev.OnClick := @TButtonsHandler(nil).BtnViewpointNextClick;
  BtnViewpointPrev.PaddingHorizontal := ButtonPadding;
  BtnViewpointPrev.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnViewpointPrev);

  BtnViewpointList := TCastleButton.Create(Window);
  BtnViewpointList.Caption := 'Viewpoints';
  BtnViewpointList.OnClick := @TButtonsHandler(nil).BtnViewpointListClick;
  BtnViewpointList.PaddingHorizontal := ButtonPadding;
  BtnViewpointList.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnViewpointList);

  BtnViewpointNext := TCastleButton.Create(Window);
  BtnViewpointNext.Caption := '>';
  BtnViewpointNext.OnClick := @TButtonsHandler(nil).BtnViewpointNextClick;
  BtnViewpointNext.PaddingHorizontal := ButtonPadding;
  BtnViewpointNext.PaddingVertical := ButtonPadding;
  Window.Controls.InsertFront(BtnViewpointNext);

  Status := TCastleLabel.Create(Window);
  Status.Caption := ' ';
  Status.Padding := 5;
  Status.Color := Red;
  Window.Controls.InsertFront(Status);
end;

procedure WindowResize(Container: TUIContainer);
const
  ToolbarMargin = 5;  {< between buttons and toolbar panel }
  ButtonsMargin = 8; {< between buttons }
  ButtonsSeparatorsMargin = 8; {< between buttons and separators }
var
  NextLeft, ButtonsHeight, ButtonsBottom: Integer;
  NextTop: Integer;
begin
  NextLeft := ToolbarMargin;
  NextTop := Window.Height;
  NextTop := NextTop - 50; // Device status bar height (window extends below it)

  ButtonsHeight := Max(BtnNavExamine.CalculatedHeight, BtnOptions.CalculatedHeight);
  ButtonsBottom := NextTop - ButtonsHeight - ToolbarMargin;

  if ToolbarPanel.Exists then
  begin
    ToolbarPanel.Left := 0;
    ToolbarPanel.Width := Window.Width;
    ToolbarPanel.Height := ButtonsHeight + ToolbarMargin * 2;
    ToolbarPanel.Bottom := NextTop - ToolbarPanel.Height;
    NextTop := ToolbarPanel.Bottom;

    BtnNavWalk.Left := NextLeft;
    BtnNavWalk.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnNavWalk.CalculatedWidth;
    BtnNavFly.Left := NextLeft;
    BtnNavFly.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnNavFly.CalculatedWidth;
    BtnNavExamine.Left := NextLeft;
    BtnNavExamine.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnNavExamine.CalculatedWidth + ButtonsSeparatorsMargin;

    ToolbarPanel.VerticalSeparators[0] := NextLeft;
    NextLeft := NextLeft + ToolbarPanel.SeparatorSize + ButtonsSeparatorsMargin;

    BtnViewpointPrev.Left := NextLeft;
    BtnViewpointPrev.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnViewpointPrev.CalculatedWidth;
    BtnViewpointList.Left := NextLeft;
    BtnViewpointList.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnViewpointList.CalculatedWidth;
    BtnViewpointNext.Left := NextLeft;
    BtnViewpointNext.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnViewpointNext.CalculatedWidth + ButtonsSeparatorsMargin;

    ToolbarPanel.VerticalSeparators[1] := NextLeft;
    NextLeft := NextLeft + ToolbarPanel.SeparatorSize + ButtonsSeparatorsMargin;

    BtnScreenshot.Left := NextLeft;
    BtnScreenshot.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnScreenshot.CalculatedWidth + ButtonsSeparatorsMargin;

    ToolbarPanel.VerticalSeparators[2] := NextLeft;
    NextLeft := NextLeft + ToolbarPanel.SeparatorSize + ButtonsSeparatorsMargin;

    BtnOptions.Left := NextLeft;
    BtnOptions.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnOptions.CalculatedWidth + ButtonsMargin;
    BtnInfo.Left := NextLeft;
    BtnInfo.Bottom := ButtonsBottom;
    NextLeft := NextLeft + BtnInfo.CalculatedWidth + ButtonsMargin;
  end;

  Status.Left := 10;
  Status.Bottom := NextTop - ButtonsMargin - Status.CalculatedHeight;
end;

procedure InitializeSceneBoundingBox;
var
  BBox: TBox3D;
  BoxNode: TBoxNode;
  ShapeNode: TShapeNode;
  Material: TMaterialNode;
begin
  BBox := Window.MainScene.BoundingBox;
  BoxNode := TBoxNode.Create;
  BoxNode.Size := BBox.Size;

  Material := TMaterialNode.Create;
  Material.ForcePureEmissive;
  Material.EmissiveColor := GreenRGB;

  ShapeNode := TShapeNode.Create;
  ShapeNode.Geometry := BoxNode;
  ShapeNode.Shading := shWireframe;
  ShapeNode.Material := Material;
  ShapeNode.Appearance.ShadowCaster := false;

  SceneBoundingBox := TTransformNode.Create;
  SceneBoundingBox.Translation := BBox.Center;
  SceneBoundingBox.AddChildren(ShapeNode);

  Window.MainScene.RootNode.AddChildren(SceneBoundingBox);
end;

procedure WindowDropFiles(Container: TUIContainer; const FileNames: array of string);
var
  Url: string;
  ViewpointsPresent: boolean;
begin
  if Length(FileNames) = 0 then Exit;
  Url := FileNames[0];

  SceneBoundingBox := nil;

  Application.Log(etInfo, 'Opened ' + Url);

  Window.Load(Url);
  Window.MainScene.Spatial := [ssRendering, ssDynamicCollisions];
  Window.MainScene.ProcessEvents := true;

  Window.MainScene.Collides := AppOptions.CollisionsOn;

  { // TODO: not implemented in the engine for OpenGLES yet
  Window.MainScene.Attributes.WireframeEffect := weWireframeOnly;
  Window.MainScene.Attributes.WireframeColor  := RedRGB;}

  CurrentViewpointIdx := 0;
  ViewpointsPresent := Window.MainScene.ViewpointsCount > 0;
  BtnViewpointPrev.Enabled := ViewpointsPresent;
  BtnViewpointList.Enabled := ViewpointsPresent;
  BtnViewpointNext.Enabled := ViewpointsPresent;
end;

procedure WindowUpdate(Container: TUIContainer);
begin
  if Status.Exists <> AppOptions.ShowFps then
    Status.Exists := AppOptions.ShowFps;

  if Status.Exists then
    Status.Caption := Format('FPS: %f (real : %f)',
      [Window.Fps.OnlyRenderFps, Window.Fps.RealFps]);

  if (Window.MainScene <> nil) and (Assigned(SceneBoundingBox) <> AppOptions.ShowBBox) then
  begin
    if AppOptions.ShowBBox then
      InitializeSceneBoundingBox
    else begin
      Window.MainScene.RootNode.RemoveChildren(SceneBoundingBox);
      SceneBoundingBox := nil;
    end;
  end;

end;

class procedure TButtonsHandler.BtnNavClick(Sender: TObject);
begin
  if Sender = BtnNavWalk then
     Window.NavigationType := ntWalk
  else if Sender = BtnNavFly then
    Window.NavigationType := ntFly
  else if Sender = BtnNavExamine then
    Window.NavigationType := ntExamine;
  {else if Sender = BtnNavTurntable then
    Window.NavigationType := ntTurntable;}
  BoundNavigationInfoChanged(Sender);
end;

class procedure TButtonsHandler.BoundNavigationInfoChanged(Sender: TObject);
var
  NavType: TNavigationType;
begin
  NavType := Window.NavigationType;
  BtnNavWalk.Pressed := (NavType = ntWalk);
  BtnNavFly.Pressed := (NavType = ntFly);
  BtnNavExamine.Pressed := ((NavType = ntExamine) or (NavType = ntTurntable));
end;

class procedure TButtonsHandler.BtnScreenshotClick(Sender: TObject);
var
  Image: TRGBImage;
begin
  // TODO: hide controls
  Image := Window.SaveScreen;
  try
    //SaveImage(Image, File);
  finally FreeAndNil(Image) end;
  // TODO: show controls
  // TODO: save to photos app
end;

class procedure TButtonsHandler.BtnOptionsClick(Sender: TObject);
begin
  StateOptionsDlg.FScene := Window.MainScene;
  TUIState.Push(StateOptionsDlg);
end;

class procedure TButtonsHandler.BtnInfoClick(Sender: TObject);
var
  Statistics: TRenderStatistics;
  NumShapesSkip: integer;
begin
  Statistics := Window.SceneManager.Statistics;
  if SceneBoundingBox <> nil then NumShapesSkip := 1 else NumShapesSkip := 0;

  StateInfoDlg.FScene := Window.MainScene;
  StateInfoDlg.FStatistics := Format('Rendered shapes: %d / %d',
    [Statistics.ShapesRendered - NumShapesSkip, Statistics.ShapesVisible - NumShapesSkip]);
  TUIState.Push(StateInfoDlg);
end;

class procedure TButtonsHandler.BtnViewpointNextClick(Sender: TObject);
begin
  if Window.MainScene = nil then exit;
  if Sender = BtnViewpointNext then
    Inc(CurrentViewpointIdx)
  else
    Dec(CurrentViewpointIdx);

  if CurrentViewpointIdx < 0 then
    CurrentViewpointIdx := Window.MainScene.ViewpointsCount;
  if CurrentViewpointIdx > Window.MainScene.ViewpointsCount - 1 then
    CurrentViewpointIdx := 0;

  Window.MainScene.MoveToViewpoint(CurrentViewpointIdx);
end;

class procedure TButtonsHandler.BtnViewpointListClick(Sender: TObject);
begin
  StateViewpointsDlg.FScene := Window.MainScene;
  StateViewpointsDlg.FCurrentViewpointIdx := CurrentViewpointIdx;
  StateViewpointsDlg.FOnViewpointSelected := @TButtonsHandler(nil).ViewpointSelected;
  TUIState.Push(StateViewpointsDlg);
end;

class procedure TButtonsHandler.ViewpointSelected(ViewpointIdx: integer);
begin
  CurrentViewpointIdx := ViewpointIdx;
  Window.MainScene.MoveToViewpoint(CurrentViewpointIdx);
end;

function MyGetApplicationName: string;
begin
  Result := 'view3dscene-mobile';
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  OnGetApplicationName := @MyGetApplicationName;

  InitializeLog;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindowTouch.Create(Application);
  Window.OnResize := @WindowResize;
  Window.OnUpdate := @WindowUpdate;
  Window.OnDropFiles := @WindowDropFiles;
  Window.FpsShowOnCaption := false;
  Window.AutomaticTouchInterface := true;
  Window.AutoRedisplay := false;
  Application.MainWindow := Window;

  OptimizeExtensiveTransformations := true;

finalization
end.
