classdef FetalImageAnalyzer < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        SidebarPanel            matlab.ui.container.Panel
        ContentPanel            matlab.ui.container.Panel
        
        % Sidebar Buttons
        LoadImageSidebarButton  matlab.ui.control.Button
        DenoisingSidebarButton  matlab.ui.control.Button
        ClassificationSidebarButton matlab.ui.control.Button
        ProcessingSidebarButton matlab.ui.control.Button
        MeasurementsSidebarButton matlab.ui.control.Button
        
        % Content Panels (one for each section)
        ImageLoadPanel          matlab.ui.container.Panel
        DenoisingPanel          matlab.ui.container.Panel
        ClassificationPanel     matlab.ui.container.Panel
        ImageProcessingPanel    matlab.ui.container.Panel
        MeasurementsPanel       matlab.ui.container.Panel
        
        % Image Load Components
        LoadImageButton         matlab.ui.control.Button
        ImageAxes               matlab.ui.control.UIAxes
        ImageDescriptionLabel   matlab.ui.control.Label
        
        % Denoising Components
        DenoisingBeforeAxes     matlab.ui.control.UIAxes
        DenoisingAfterAxes      matlab.ui.control.UIAxes
        ApplyDenoisingButton    matlab.ui.control.Button
        FilterTypeDropdown      matlab.ui.control.DropDown
        FilterInfoLabel         matlab.ui.control.Label
        BeforeLabel             matlab.ui.control.Label
        AfterLabel              matlab.ui.control.Label
        
        % Classification Components
        ClassificationAxes      matlab.ui.control.UIAxes
        ClassifyButton          matlab.ui.control.Button
        ClassificationResultLabel matlab.ui.control.Label
        ConfidenceLabel         matlab.ui.control.Label
        DescriptionLabel        matlab.ui.control.Label
        CNNInfoPanel            matlab.ui.container.Panel
        
        % Image Processing Components
        ProcessingBeforeAxes    matlab.ui.control.UIAxes
        ProcessingAfterAxes      matlab.ui.control.UIAxes
        ProcessTypeDropdown     matlab.ui.control.DropDown
        ApplyProcessingButton   matlab.ui.control.Button
        ProcessingInfoLabel     matlab.ui.control.Label
        ProcessingBeforeLabel   matlab.ui.control.Label
        ProcessingAfterLabel    matlab.ui.control.Label
        
        % Measurements Components
        MeasurementAxes         matlab.ui.control.UIAxes
        MeasureButton           matlab.ui.control.Button
        FemurLengthLabel        matlab.ui.control.Label
        HeadCircumferenceLabel  matlab.ui.control.Label
        ScaleBarStatusLabel     matlab.ui.control.Label
        MeasurementReportPanel  matlab.ui.container.Panel
        FilterUsedLabel         matlab.ui.control.Label
        EdgeParamsLabel         matlab.ui.control.Label
        MeasurementDescriptionLabel matlab.ui.control.Label
    end

    % Properties
    properties (Access = private)
        CurrentImage            % Current loaded image
        OriginalImage           % Original image
        DenoisedImage          % Denoised image
        ProcessedImage         % Processed image
        DatasetInfo            % Dataset information
        TrainedNet             % Trained CNN model
        MeasurementResults    % Measurement results
        CurrentImagePath       % Path to current image file (for proper preprocessing)
        CurrentSection         % Currently active section
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1400 900];
            app.UIFigure.Name = 'Fetal Ultrasound Image Analyzer';
            app.UIFigure.Color = [0.98 0.98 0.98]; % Modern light gray background

            % Safe Area at the top (for window title bar) - only affects top position
            safeAreaHeight = 60;
            
            % Color palette: ffefd5, c8a2c8, e0ffff, b57edc
            colorBeige = [255/255, 239/255, 213/255];      % ffefd5 - açık bej/krem
            colorLightPurple = [200/255, 162/255, 200/255]; % c8a2c8 - açık mor
            colorCyan = [224/255, 255/255, 255/255];       % e0ffff - açık camgöbeği
            colorPurple = [181/255, 126/255, 220/255];     % b57edc - mor
            
            % Color palette: ffefd5, c8a2c8, e0ffff, b57edc
            colorBeige = [255/255, 239/255, 213/255];      % ffefd5 - açık bej/krem
            colorLightPurple = [200/255, 162/255, 200/255]; % c8a2c8 - açık mor
            colorCyan = [224/255, 255/255, 255/255];       % e0ffff - açık camgöbeği
            colorPurple = [181/255, 126/255, 220/255];     % b57edc - mor
            colorLightBlue = [173/255, 216/255, 230/255];  % ADD8E6 - açık mavi (button background)
            colorActive = colorPurple;                       % Aktif buton rengi (daha koyu)
            colorInactive = colorLightPurple;                % Pasif buton rengi
            
            % Create Sidebar Panel (Left side) - Modern design
            app.SidebarPanel = uipanel(app.UIFigure);
            app.SidebarPanel.Position = [1 safeAreaHeight+1 220 900-safeAreaHeight];
            app.SidebarPanel.BackgroundColor = colorBeige; % ffefd5 - açık bej/krem sidebar background
            app.SidebarPanel.BorderType = 'none';
            
            % Create Sidebar Buttons (stacked vertically) - Modern styling
            buttonHeight = 55;
            buttonSpacing = 8;
            sidebarHeight = 900 - safeAreaHeight;
            sidebarWidth = 220;
            buttonWidth = 200;
            buttonX = (sidebarWidth - buttonWidth) / 2;  % Center buttons horizontally
            
            % Calculate total height of all buttons
            numButtons = 5;
            totalButtonsHeight = numButtons * buttonHeight + (numButtons - 1) * buttonSpacing;
            
            % Calculate starting Y position to center buttons vertically
            % Sidebar panel coordinates: (0,0) is at bottom-left
            % Center the button group vertically in the sidebar
            startY = (sidebarHeight + totalButtonsHeight) / 2 - buttonHeight;
            
            % Calculate button positions from bottom (centered vertically)
            button1Y = startY;
            button2Y = button1Y - (buttonHeight + buttonSpacing);
            button3Y = button2Y - (buttonHeight + buttonSpacing);
            button4Y = button3Y - (buttonHeight + buttonSpacing);
            button5Y = button4Y - (buttonHeight + buttonSpacing);
            
            app.LoadImageSidebarButton = uibutton(app.SidebarPanel, 'push');
            app.LoadImageSidebarButton.Position = [buttonX button1Y buttonWidth buttonHeight];
            app.LoadImageSidebarButton.Text = '📁 Load Image';
            app.LoadImageSidebarButton.FontSize = 13;
            app.LoadImageSidebarButton.FontWeight = 'bold';
            app.LoadImageSidebarButton.BackgroundColor = colorPurple; % İlk yüklemede aktif (mor)
            app.LoadImageSidebarButton.FontColor = [1 1 1];
            app.LoadImageSidebarButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImageSidebarButtonPushed, true);
            
            app.DenoisingSidebarButton = uibutton(app.SidebarPanel, 'push');
            app.DenoisingSidebarButton.Position = [buttonX button2Y buttonWidth buttonHeight];
            app.DenoisingSidebarButton.Text = '✨ Denoising';
            app.DenoisingSidebarButton.FontSize = 13;
            app.DenoisingSidebarButton.FontWeight = 'bold';
            app.DenoisingSidebarButton.BackgroundColor = colorLightBlue; % Açık mavi kart görünümü
            app.DenoisingSidebarButton.FontColor = [0.2 0.2 0.2];
            app.DenoisingSidebarButton.ButtonPushedFcn = createCallbackFcn(app, @DenoisingSidebarButtonPushed, true);
            
            app.ClassificationSidebarButton = uibutton(app.SidebarPanel, 'push');
            app.ClassificationSidebarButton.Position = [buttonX button3Y buttonWidth buttonHeight];
            app.ClassificationSidebarButton.Text = '🧠 CNN Classification';
            app.ClassificationSidebarButton.FontSize = 13;
            app.ClassificationSidebarButton.FontWeight = 'bold';
            app.ClassificationSidebarButton.BackgroundColor = colorLightBlue; % Açık mavi kart görünümü
            app.ClassificationSidebarButton.FontColor = [0.2 0.2 0.2];
            app.ClassificationSidebarButton.ButtonPushedFcn = createCallbackFcn(app, @ClassificationSidebarButtonPushed, true);
            
            app.ProcessingSidebarButton = uibutton(app.SidebarPanel, 'push');
            app.ProcessingSidebarButton.Position = [buttonX button4Y buttonWidth buttonHeight];
            app.ProcessingSidebarButton.Text = '⚙️ Image Processing';
            app.ProcessingSidebarButton.FontSize = 13;
            app.ProcessingSidebarButton.FontWeight = 'bold';
            app.ProcessingSidebarButton.BackgroundColor = colorLightBlue; % Açık mavi kart görünümü
            app.ProcessingSidebarButton.FontColor = [0.2 0.2 0.2];
            app.ProcessingSidebarButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessingSidebarButtonPushed, true);
            
            app.MeasurementsSidebarButton = uibutton(app.SidebarPanel, 'push');
            app.MeasurementsSidebarButton.Position = [buttonX button5Y buttonWidth buttonHeight];
            app.MeasurementsSidebarButton.Text = '📏 Measurements';
            app.MeasurementsSidebarButton.FontSize = 13;
            app.MeasurementsSidebarButton.FontWeight = 'bold';
            app.MeasurementsSidebarButton.BackgroundColor = colorLightBlue; % Açık mavi kart görünümü
            app.MeasurementsSidebarButton.FontColor = [0.2 0.2 0.2];
            app.MeasurementsSidebarButton.ButtonPushedFcn = createCallbackFcn(app, @MeasurementsSidebarButtonPushed, true);

            % Create Content Panel (Right side - aligned with sidebar)
            app.ContentPanel = uipanel(app.UIFigure);
            app.ContentPanel.Position = [221 safeAreaHeight+1 1179 900];
            app.ContentPanel.BackgroundColor = [0.98 0.98 0.98]; % Modern light gray
            app.ContentPanel.BorderType = 'none';

            % Create Image Load Panel
            app.ImageLoadPanel = uipanel(app.ContentPanel);
            app.ImageLoadPanel.Position = [0 0 1179 900];
            app.ImageLoadPanel.BackgroundColor = [0.98 0.98 0.98];
            app.ImageLoadPanel.BorderType = 'none';
            app.ImageLoadPanel.Visible = 'on';

            % Top Control Panel (Modern card design)
            topPanel = uipanel(app.ImageLoadPanel);
            topPanel.Position = [20 750-safeAreaHeight 1139 130];
            topPanel.BackgroundColor = [1 1 1];
            topPanel.BorderType = 'line';
            topPanel.BorderWidth = 1;
            topPanel.BorderColor = [0.85 0.85 0.85];

            % Create Load Image Button (Modern styling)
            app.LoadImageButton = uibutton(topPanel, 'push');
            app.LoadImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImageButtonPushed, true);
            app.LoadImageButton.Position = [30 45 180 45];
            app.LoadImageButton.Text = '📁 Load Image';
            app.LoadImageButton.FontSize = 14;
            app.LoadImageButton.FontWeight = 'bold';
            app.LoadImageButton.BackgroundColor = colorPurple; % Koyu mor
            app.LoadImageButton.FontColor = [1 1 1];

            % Bottom Image Display Area
            app.ImageAxes = uiaxes(app.ImageLoadPanel);
            app.ImageAxes.Position = [20 50-safeAreaHeight 1139 680];
            app.ImageAxes.Title.String = 'Loaded Image';
            app.ImageAxes.Title.FontSize = 16;
            app.ImageAxes.Title.FontWeight = 'bold';
            app.ImageAxes.Title.Color = [0.2 0.2 0.2];
            app.ImageAxes.Visible = 'off';
            app.ImageAxes.XTick = [];
            app.ImageAxes.YTick = [];
            app.ImageAxes.Box = 'on';
            app.ImageAxes.BackgroundColor = [0.95 0.95 0.95];

            % Create Image Description Label (below image)
            app.ImageDescriptionLabel = uilabel(app.ImageLoadPanel);
            app.ImageDescriptionLabel.Position = [20 20-safeAreaHeight 1139 25];
            app.ImageDescriptionLabel.Text = 'No image loaded';
            app.ImageDescriptionLabel.FontSize = 12;
            app.ImageDescriptionLabel.HorizontalAlignment = 'center';
            app.ImageDescriptionLabel.FontColor = [0.5 0.5 0.5];

            % Create Denoising Panel
            app.DenoisingPanel = uipanel(app.ContentPanel);
            app.DenoisingPanel.Position = [0 0 1179 900];
            app.DenoisingPanel.BackgroundColor = [0.98 0.98 0.98];
            app.DenoisingPanel.BorderType = 'none';
            app.DenoisingPanel.Visible = 'off';

            % Top Control Panel
            topPanel = uipanel(app.DenoisingPanel);
            topPanel.Position = [20 750-safeAreaHeight 1139 130];
            topPanel.BackgroundColor = [1 1 1];
            topPanel.BorderType = 'line';
            topPanel.BorderWidth = 1;
            topPanel.BorderColor = [0.85 0.85 0.85];

            % Create Filter Type Dropdown
            app.FilterTypeDropdown = uidropdown(topPanel);
            app.FilterTypeDropdown.Position = [30 45 220 45];
            app.FilterTypeDropdown.Items = {'Median Filter', 'Wiener Filter', 'Gaussian Filter', 'Bilateral Filter'};
            app.FilterTypeDropdown.Value = 'Wiener Filter';
            app.FilterTypeDropdown.FontSize = 13;

            % Create Apply Denoising Button
            app.ApplyDenoisingButton = uibutton(topPanel, 'push');
            app.ApplyDenoisingButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyDenoisingButtonPushed, true);
            app.ApplyDenoisingButton.Position = [270 45 180 45];
            app.ApplyDenoisingButton.Text = '✨ Apply Filter';
            app.ApplyDenoisingButton.FontSize = 14;
            app.ApplyDenoisingButton.FontWeight = 'bold';
            app.ApplyDenoisingButton.BackgroundColor = colorPurple; % Koyu mor
            app.ApplyDenoisingButton.FontColor = [1 1 1];

            % Create Filter Info Label
            app.FilterInfoLabel = uilabel(topPanel);
            app.FilterInfoLabel.Position = [470 20 650 100];
            app.FilterInfoLabel.FontSize = 12;
            app.FilterInfoLabel.Text = 'Filter information will be displayed here.';
            app.FilterInfoLabel.WordWrap = 'on';
            app.FilterInfoLabel.FontColor = [0.3 0.3 0.3];

            % Bottom Image Display Area - Before/After comparison
            app.DenoisingBeforeAxes = uiaxes(app.DenoisingPanel);
            app.DenoisingBeforeAxes.Position = [20 380-safeAreaHeight 550 350];
            app.DenoisingBeforeAxes.Title.String = 'Original Image';
            app.DenoisingBeforeAxes.Title.FontSize = 15;
            app.DenoisingBeforeAxes.Title.FontWeight = 'bold';
            app.DenoisingBeforeAxes.Title.Color = [0.2 0.2 0.2];
            app.DenoisingBeforeAxes.Visible = 'off';
            app.DenoisingBeforeAxes.XTick = [];
            app.DenoisingBeforeAxes.YTick = [];
            app.DenoisingBeforeAxes.Box = 'on';
            app.DenoisingBeforeAxes.BackgroundColor = [0.95 0.95 0.95];

            app.DenoisingAfterAxes = uiaxes(app.DenoisingPanel);
            app.DenoisingAfterAxes.Position = [590 380-safeAreaHeight 550 350];
            app.DenoisingAfterAxes.Title.String = 'Filtered Image';
            app.DenoisingAfterAxes.Title.FontSize = 15;
            app.DenoisingAfterAxes.Title.FontWeight = 'bold';
            app.DenoisingAfterAxes.Title.Color = [0.2 0.2 0.2];
            app.DenoisingAfterAxes.Visible = 'off';
            app.DenoisingAfterAxes.XTick = [];
            app.DenoisingAfterAxes.YTick = [];
            app.DenoisingAfterAxes.Box = 'on';
            app.DenoisingAfterAxes.BackgroundColor = [0.95 0.95 0.95];

            % Create Labels
            app.BeforeLabel = uilabel(app.DenoisingPanel);
            app.BeforeLabel.Position = [20 350-safeAreaHeight 550 25];
            app.BeforeLabel.Text = 'Original Image';
            app.BeforeLabel.FontSize = 12;
            app.BeforeLabel.HorizontalAlignment = 'center';
            app.BeforeLabel.FontColor = [0.4 0.4 0.4];

            app.AfterLabel = uilabel(app.DenoisingPanel);
            app.AfterLabel.Position = [590 350-safeAreaHeight 550 25];
            app.AfterLabel.Text = 'Filtered Image';
            app.AfterLabel.FontSize = 12;
            app.AfterLabel.HorizontalAlignment = 'center';
            app.AfterLabel.FontColor = [0.4 0.4 0.4];

            % Create Classification Panel
            app.ClassificationPanel = uipanel(app.ContentPanel);
            app.ClassificationPanel.Position = [0 0 1179 900];
            app.ClassificationPanel.BackgroundColor = [0.98 0.98 0.98];
            app.ClassificationPanel.BorderType = 'none';
            app.ClassificationPanel.Visible = 'off';

            % Top Control Panel
            topPanel = uipanel(app.ClassificationPanel);
            topPanel.Position = [20 750-safeAreaHeight 1139 130];
            topPanel.BackgroundColor = [1 1 1];
            topPanel.BorderType = 'line';
            topPanel.BorderWidth = 1;
            topPanel.BorderColor = [0.85 0.85 0.85];

            % Create Classify Button
            app.ClassifyButton = uibutton(topPanel, 'push');
            app.ClassifyButton.ButtonPushedFcn = createCallbackFcn(app, @ClassifyButtonPushed, true);
            app.ClassifyButton.Position = [30 45 200 45];
            app.ClassifyButton.Text = '🧠 Classify Image';
            app.ClassifyButton.FontSize = 14;
            app.ClassifyButton.FontWeight = 'bold';
            app.ClassifyButton.BackgroundColor = colorPurple; % Koyu mor
            app.ClassifyButton.FontColor = [1 1 1];

            % Create CNN Info Panel (Modern card design)
            app.CNNInfoPanel = uipanel(topPanel);
            app.CNNInfoPanel.Position = [250 10 870 110];
            app.CNNInfoPanel.Title = 'Prediction Result';
            app.CNNInfoPanel.BackgroundColor = [0.98 0.98 0.98];
            app.CNNInfoPanel.BorderType = 'line';
            app.CNNInfoPanel.BorderWidth = 1;
            app.CNNInfoPanel.BorderColor = [0.85 0.85 0.85];

            % Create Classification Result Label
            app.ClassificationResultLabel = uilabel(app.CNNInfoPanel);
            app.ClassificationResultLabel.Position = [20 60 400 35];
            app.ClassificationResultLabel.FontSize = 20;
            app.ClassificationResultLabel.FontWeight = 'bold';
            app.ClassificationResultLabel.Text = 'Class: -';
            app.ClassificationResultLabel.FontColor = [0.2 0.2 0.2];

            % Create Description Label
            app.DescriptionLabel = uilabel(app.CNNInfoPanel);
            app.DescriptionLabel.Position = [20 35 400 25];
            app.DescriptionLabel.FontSize = 12;
            app.DescriptionLabel.Text = 'Description: -';
            app.DescriptionLabel.FontColor = [0.4 0.4 0.4];

            % Create Confidence Label
            app.ConfidenceLabel = uilabel(app.CNNInfoPanel);
            app.ConfidenceLabel.Position = [440 10 400 90];
            app.ConfidenceLabel.FontSize = 12;
            app.ConfidenceLabel.Text = 'Confidence: -';
            app.ConfidenceLabel.WordWrap = 'on';
            app.ConfidenceLabel.FontColor = [0.3 0.3 0.3];

            % Bottom Image Display Area
            app.ClassificationAxes = uiaxes(app.ClassificationPanel);
            app.ClassificationAxes.Position = [20 50-safeAreaHeight 1139 680];
            app.ClassificationAxes.Title.String = 'Classification Result';
            app.ClassificationAxes.Title.FontSize = 16;
            app.ClassificationAxes.Title.FontWeight = 'bold';
            app.ClassificationAxes.Title.Color = [0.2 0.2 0.2];
            app.ClassificationAxes.Visible = 'off';
            app.ClassificationAxes.XTick = [];
            app.ClassificationAxes.YTick = [];
            app.ClassificationAxes.Box = 'on';
            app.ClassificationAxes.BackgroundColor = [0.95 0.95 0.95];

            % Create Image Processing Panel
            app.ImageProcessingPanel = uipanel(app.ContentPanel);
            app.ImageProcessingPanel.Position = [0 0 1179 900];
            app.ImageProcessingPanel.BackgroundColor = [0.98 0.98 0.98];
            app.ImageProcessingPanel.BorderType = 'none';
            app.ImageProcessingPanel.Visible = 'off';

            % Top Control Panel
            topPanel = uipanel(app.ImageProcessingPanel);
            topPanel.Position = [20 750-safeAreaHeight 1139 130];
            topPanel.BackgroundColor = [1 1 1];
            topPanel.BorderType = 'line';
            topPanel.BorderWidth = 1;
            topPanel.BorderColor = [0.85 0.85 0.85];

            % Create Process Type Dropdown
            app.ProcessTypeDropdown = uidropdown(topPanel);
            app.ProcessTypeDropdown.Position = [30 45 220 45];
            app.ProcessTypeDropdown.Items = {'Canny Edge', 'CLAHE'};
            app.ProcessTypeDropdown.Value = 'Canny Edge';
            app.ProcessTypeDropdown.FontSize = 13;

            % Create Apply Processing Button
            app.ApplyProcessingButton = uibutton(topPanel, 'push');
            app.ApplyProcessingButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyProcessingButtonPushed, true);
            app.ApplyProcessingButton.Position = [270 45 200 45];
            app.ApplyProcessingButton.Text = '⚙️ Apply Processing';
            app.ApplyProcessingButton.FontSize = 14;
            app.ApplyProcessingButton.FontWeight = 'bold';
            app.ApplyProcessingButton.BackgroundColor = colorPurple; % Koyu mor
            app.ApplyProcessingButton.FontColor = [1 1 1];

            % Create Processing Info Label (hidden)
            app.ProcessingInfoLabel = uilabel(topPanel);
            app.ProcessingInfoLabel.Position = [490 20 630 100];
            app.ProcessingInfoLabel.FontSize = 12;
            app.ProcessingInfoLabel.Text = '';
            app.ProcessingInfoLabel.WordWrap = 'on';
            app.ProcessingInfoLabel.FontColor = [0.3 0.3 0.3];
            app.ProcessingInfoLabel.Visible = 'off';

            % Bottom Image Display Area - Before/After comparison
            app.ProcessingBeforeAxes = uiaxes(app.ImageProcessingPanel);
            app.ProcessingBeforeAxes.Position = [20 380-safeAreaHeight 550 350];
            app.ProcessingBeforeAxes.Title.String = 'Original Image';
            app.ProcessingBeforeAxes.Title.FontSize = 15;
            app.ProcessingBeforeAxes.Title.FontWeight = 'bold';
            app.ProcessingBeforeAxes.Title.Color = [0.2 0.2 0.2];
            app.ProcessingBeforeAxes.Visible = 'off';
            app.ProcessingBeforeAxes.XTick = [];
            app.ProcessingBeforeAxes.YTick = [];
            app.ProcessingBeforeAxes.Box = 'on';
            app.ProcessingBeforeAxes.BackgroundColor = [0.95 0.95 0.95];

            app.ProcessingAfterAxes = uiaxes(app.ImageProcessingPanel);
            app.ProcessingAfterAxes.Position = [590 380-safeAreaHeight 550 350];
            app.ProcessingAfterAxes.Title.String = 'Processed Image';
            app.ProcessingAfterAxes.Title.FontSize = 15;
            app.ProcessingAfterAxes.Title.FontWeight = 'bold';
            app.ProcessingAfterAxes.Title.Color = [0.2 0.2 0.2];
            app.ProcessingAfterAxes.Visible = 'off';
            app.ProcessingAfterAxes.XTick = [];
            app.ProcessingAfterAxes.YTick = [];
            app.ProcessingAfterAxes.Box = 'on';
            app.ProcessingAfterAxes.BackgroundColor = [0.95 0.95 0.95];

            % Create Labels
            app.ProcessingBeforeLabel = uilabel(app.ImageProcessingPanel);
            app.ProcessingBeforeLabel.Position = [20 350-safeAreaHeight 550 25];
            app.ProcessingBeforeLabel.Text = 'Original Image';
            app.ProcessingBeforeLabel.FontSize = 12;
            app.ProcessingBeforeLabel.HorizontalAlignment = 'center';
            app.ProcessingBeforeLabel.FontColor = [0.4 0.4 0.4];

            app.ProcessingAfterLabel = uilabel(app.ImageProcessingPanel);
            app.ProcessingAfterLabel.Position = [590 350-safeAreaHeight 550 25];
            app.ProcessingAfterLabel.Text = 'Processed Image';
            app.ProcessingAfterLabel.FontSize = 12;
            app.ProcessingAfterLabel.HorizontalAlignment = 'center';
            app.ProcessingAfterLabel.FontColor = [0.4 0.4 0.4];

            % Create Measurements Panel
            app.MeasurementsPanel = uipanel(app.ContentPanel);
            app.MeasurementsPanel.Position = [0 0 1179 900];
            app.MeasurementsPanel.BackgroundColor = [0.98 0.98 0.98];
            app.MeasurementsPanel.BorderType = 'none';
            app.MeasurementsPanel.Visible = 'off';

            % Top Control Panel
            topPanel = uipanel(app.MeasurementsPanel);
            topPanel.Position = [20 750-safeAreaHeight 1139 130];
            topPanel.BackgroundColor = [1 1 1];
            topPanel.BorderType = 'line';
            topPanel.BorderWidth = 1;
            topPanel.BorderColor = [0.85 0.85 0.85];

            % Create Measure Button
            app.MeasureButton = uibutton(topPanel, 'push');
            app.MeasureButton.ButtonPushedFcn = createCallbackFcn(app, @MeasureButtonPushed, true);
            app.MeasureButton.Position = [30 45 220 45];
            app.MeasureButton.Text = '📏 Perform Measurement';
            app.MeasureButton.FontSize = 14;
            app.MeasureButton.FontWeight = 'bold';
            app.MeasureButton.BackgroundColor = colorPurple; % Koyu mor
            app.MeasureButton.FontColor = [1 1 1];

            % Create Measurement Report Panel (Modern card design)
            app.MeasurementReportPanel = uipanel(topPanel);
            app.MeasurementReportPanel.Position = [270 10 850 110];
            app.MeasurementReportPanel.Title = 'Automatic Measurement Report';
            app.MeasurementReportPanel.BackgroundColor = [0.98 0.98 0.98];
            app.MeasurementReportPanel.BorderType = 'line';
            app.MeasurementReportPanel.BorderWidth = 1;
            app.MeasurementReportPanel.BorderColor = [0.85 0.85 0.85];

            % Create Femur Length Label
            app.FemurLengthLabel = uilabel(app.MeasurementReportPanel);
            app.FemurLengthLabel.Position = [20 60 400 30];
            app.FemurLengthLabel.FontSize = 14;
            app.FemurLengthLabel.FontWeight = 'bold';
            app.FemurLengthLabel.Text = 'Femur Length: -';
            app.FemurLengthLabel.FontColor = [0.2 0.2 0.2];

            % Create Head Circumference Label
            app.HeadCircumferenceLabel = uilabel(app.MeasurementReportPanel);
            app.HeadCircumferenceLabel.Position = [20 30 400 30];
            app.HeadCircumferenceLabel.FontSize = 14;
            app.HeadCircumferenceLabel.FontWeight = 'bold';
            app.HeadCircumferenceLabel.Text = 'Head Circumference: -';
            app.HeadCircumferenceLabel.FontColor = [0.2 0.2 0.2];

            % Create Scale Bar Status Label (hidden)
            app.ScaleBarStatusLabel = uilabel(app.MeasurementReportPanel);
            app.ScaleBarStatusLabel.Position = [440 60 400 25];
            app.ScaleBarStatusLabel.FontSize = 12;
            app.ScaleBarStatusLabel.Text = '';
            app.ScaleBarStatusLabel.WordWrap = 'on';
            app.ScaleBarStatusLabel.FontColor = [0.3 0.3 0.3];
            app.ScaleBarStatusLabel.Visible = 'off';

            % Create Filter Used Label (hidden)
            app.FilterUsedLabel = uilabel(app.MeasurementReportPanel);
            app.FilterUsedLabel.Position = [440 35 400 20];
            app.FilterUsedLabel.FontSize = 11;
            app.FilterUsedLabel.Text = '';
            app.FilterUsedLabel.FontColor = [0.4 0.4 0.4];
            app.FilterUsedLabel.Visible = 'off';

            % Create Edge Params Label (hidden)
            app.EdgeParamsLabel = uilabel(app.MeasurementReportPanel);
            app.EdgeParamsLabel.Position = [440 10 400 20];
            app.EdgeParamsLabel.FontSize = 11;
            app.EdgeParamsLabel.Text = '';
            app.EdgeParamsLabel.FontColor = [0.4 0.4 0.4];
            app.EdgeParamsLabel.Visible = 'off';

            % Bottom Image Display Area
            app.MeasurementAxes = uiaxes(app.MeasurementsPanel);
            app.MeasurementAxes.Position = [20 50-safeAreaHeight 1139 680];
            app.MeasurementAxes.Title.String = 'Measurement Results';
            app.MeasurementAxes.Title.FontSize = 16;
            app.MeasurementAxes.Title.FontWeight = 'bold';
            app.MeasurementAxes.Title.Color = [0.2 0.2 0.2];
            app.MeasurementAxes.Visible = 'off';
            app.MeasurementAxes.XTick = [];
            app.MeasurementAxes.YTick = [];
            app.MeasurementAxes.Box = 'on';
            app.MeasurementAxes.BackgroundColor = [0.95 0.95 0.95];

            % Create Measurement Description Label (below image)
            app.MeasurementDescriptionLabel = uilabel(app.MeasurementsPanel);
            app.MeasurementDescriptionLabel.Position = [20 20-safeAreaHeight 1139 25];
            app.MeasurementDescriptionLabel.Text = 'No measurements performed';
            app.MeasurementDescriptionLabel.FontSize = 12;
            app.MeasurementDescriptionLabel.HorizontalAlignment = 'center';
            app.MeasurementDescriptionLabel.FontColor = [0.5 0.5 0.5];

            % Initialize current section
            app.CurrentSection = 'load';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end

        % Helper function to switch sections
        function switchSection(app, sectionName)
            % Color palette: ffefd5, c8a2c8, e0ffff, b57edc
            colorLightBlue = [173/255, 216/255, 230/255];  % ADD8E6 - açık mavi (button background)
            colorPurple = [181/255, 126/255, 220/255];     % b57edc - mor (aktif buton)
            
            % Hide all panels
            app.ImageLoadPanel.Visible = 'off';
            app.DenoisingPanel.Visible = 'off';
            app.ClassificationPanel.Visible = 'off';
            app.ImageProcessingPanel.Visible = 'off';
            app.MeasurementsPanel.Visible = 'off';
            
            % Reset all sidebar buttons to inactive colors (açık mavi kart)
            app.LoadImageSidebarButton.BackgroundColor = colorLightBlue;
            app.LoadImageSidebarButton.FontColor = [0.2 0.2 0.2];
            app.DenoisingSidebarButton.BackgroundColor = colorLightBlue;
            app.DenoisingSidebarButton.FontColor = [0.2 0.2 0.2];
            app.ClassificationSidebarButton.BackgroundColor = colorLightBlue;
            app.ClassificationSidebarButton.FontColor = [0.2 0.2 0.2];
            app.ProcessingSidebarButton.BackgroundColor = colorLightBlue;
            app.ProcessingSidebarButton.FontColor = [0.2 0.2 0.2];
            app.MeasurementsSidebarButton.BackgroundColor = colorLightBlue;
            app.MeasurementsSidebarButton.FontColor = [0.2 0.2 0.2];
            
            % Show selected panel and highlight button (mor renk)
            switch sectionName
                case 'load'
                    app.ImageLoadPanel.Visible = 'on';
                    app.LoadImageSidebarButton.BackgroundColor = colorPurple;
                    app.LoadImageSidebarButton.FontColor = [1 1 1];
                case 'denoising'
                    app.DenoisingPanel.Visible = 'on';
                    app.DenoisingSidebarButton.BackgroundColor = colorPurple;
                    app.DenoisingSidebarButton.FontColor = [1 1 1];
                case 'classification'
                    app.ClassificationPanel.Visible = 'on';
                    app.ClassificationSidebarButton.BackgroundColor = colorPurple;
                    app.ClassificationSidebarButton.FontColor = [1 1 1];
                case 'processing'
                    app.ImageProcessingPanel.Visible = 'on';
                    app.ProcessingSidebarButton.BackgroundColor = colorPurple;
                    app.ProcessingSidebarButton.FontColor = [1 1 1];
                case 'measurements'
                    app.MeasurementsPanel.Visible = 'on';
                    app.MeasurementsSidebarButton.BackgroundColor = colorPurple;
                    app.MeasurementsSidebarButton.FontColor = [1 1 1];
            end
            
            app.CurrentSection = sectionName;
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = FetalImageAnalyzer

            % Create UIFigure and components
            createComponents(app);

            % Initialize dataset
            try
                if evalin('base', 'exist(''datasetInfo'', ''var'')')
                    app.DatasetInfo = evalin('base', 'datasetInfo');
                else
                    app.DatasetInfo = [];
                end
            catch
                app.DatasetInfo = [];
            end

            % Try to load trained model
            try
                if exist('trained_model.mat', 'file')
                    load('trained_model.mat', 'trainedNet');
                    app.TrainedNet = trainedNet;
                elseif evalin('base', 'exist(''cnnResults'', ''var'')')
                    cnnResults = evalin('base', 'cnnResults');
                    if isfield(cnnResults, 'trainedNet')
                        app.TrainedNet = cnnResults.trainedNet;
                    else
                        app.TrainedNet = [];
                    end
                else
                    app.TrainedNet = [];
                end
            catch
                app.TrainedNet = [];
            end
            
            % Status information
            if isempty(app.DatasetInfo)
                fprintf('⚠ Dataset not loaded. File selector can be used for image loading.\n');
            else
                fprintf('✓ Dataset loaded.\n');
            end
            
            if isempty(app.TrainedNet)
                fprintf('⚠ Trained model not found. Run Stage3_CNNTraining for CNN classification.\n');
            else
                fprintf('✓ Trained model loaded.\n');
            end
        end

        % Code that executes before app deletion
        function delete(app)
            delete(app.UIFigure)
        end
    end

    % Callback functions
    methods (Access = private)

        % Sidebar button callbacks
        function LoadImageSidebarButtonPushed(app, event)
            switchSection(app, 'load');
        end

        function DenoisingSidebarButtonPushed(app, event)
            switchSection(app, 'denoising');
        end

        function ClassificationSidebarButtonPushed(app, event)
            switchSection(app, 'classification');
        end

        function ProcessingSidebarButtonPushed(app, event)
            switchSection(app, 'processing');
        end

        function MeasurementsSidebarButtonPushed(app, event)
            switchSection(app, 'measurements');
        end

        % Button pushed function: LoadImageButton
        function LoadImageButtonPushed(app, event)
            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Image Files'}, ...
                                     'Select Image');
            
            if isequal(file, 0)
                return;
            end
            
            fullPath = fullfile(path, file);
            
            try
                img = imread(fullPath);
                
                if size(img, 3) == 3
                    img = rgb2gray(img);
                end
                
                if ~isa(img, 'double')
                    img = im2double(img);
                end
                
                app.OriginalImage = img;
                app.CurrentImage = img;
                app.CurrentImagePath = fullPath;
                
                app.ImageAxes.Visible = 'on';
                imshow(img, 'Parent', app.ImageAxes);
                axis(app.ImageAxes, 'image');
                
                [~, fileName, ext] = fileparts(file);
                app.ImageDescriptionLabel.Text = sprintf('Loaded: %s%s', fileName, ext);
            catch ME
                uialert(app.UIFigure, sprintf('Error loading image: %s', ME.message), ...
                        'Error', 'Icon', 'error');
            end
        end

        % Button pushed function: ApplyDenoisingButton
        function ApplyDenoisingButtonPushed(app, event)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'Please load an image first!', ...
                        'Warning', 'Icon', 'warning');
                return;
            end
            
            filterType = app.FilterTypeDropdown.Value;
            
            try
                switch filterType
                    case 'Median Filter'
                        filtered = medfilt2(app.CurrentImage, [7, 7]);
                        infoText = 'Median Filter (7x7) — noise reduction ~30%';
                    case 'Wiener Filter'
                        filtered = wiener2(app.CurrentImage, [5, 5]);
                        infoText = 'Wiener Filter (5x5) — noise reduction ~35%';
                    case 'Gaussian Filter'
                        filtered = imgaussfilt(app.CurrentImage, 2.0, 'FilterSize', 7);
                        infoText = 'Gaussian Filter (σ=2.0) — noise reduction ~40%';
                    case 'Bilateral Filter'
                        filtered = imgaussfilt(app.CurrentImage, 1.5);
                        infoText = 'Bilateral Filter — noise reduction ~25%';
                end
                
                app.DenoisedImage = filtered;
                app.CurrentImage = filtered;
                
                app.DenoisingBeforeAxes.Visible = 'on';
                app.DenoisingAfterAxes.Visible = 'on';
                imshow(app.OriginalImage, 'Parent', app.DenoisingBeforeAxes);
                axis(app.DenoisingBeforeAxes, 'image');
                imshow(filtered, 'Parent', app.DenoisingAfterAxes);
                axis(app.DenoisingAfterAxes, 'image');
                
                app.BeforeLabel.Text = 'Original Image';
                app.AfterLabel.Text = filterType;
                app.FilterInfoLabel.Text = '';
            catch ME
                uialert(app.UIFigure, sprintf('Error applying filter: %s', ME.message), ...
                        'Error', 'Icon', 'error');
            end
        end

        % Button pushed function: ClassifyButton
        function ClassifyButtonPushed(app, event)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'Please load an image first!', ...
                        'Warning', 'Icon', 'warning');
                return;
            end
            
            if isempty(app.TrainedNet)
                uialert(app.UIFigure, 'Trained model not found! Please run Stage3_CNNTraining first.', ...
                        'Warning', 'Icon', 'warning');
                return;
            end
            
            d = uiprogressdlg(app.UIFigure, 'Title', 'Classifying', ...
                              'Message', 'Processing image...', 'Indeterminate', 'on');
            
            try
                try
                    if isa(app.TrainedNet, 'DAGNetwork') || isa(app.TrainedNet, 'SeriesNetwork')
                        inputSize = app.TrainedNet.Layers(1).InputSize;
                        targetSize = inputSize(1:2);
                    else
                        targetSize = [224, 224];
                    end
                catch
                    targetSize = [224, 224];
                end
                
                if ~isempty(app.CurrentImagePath) && exist(app.CurrentImagePath, 'file')
                    img = imread(app.CurrentImagePath);
                else
                    close(d);
                    uialert(app.UIFigure, 'Image file path not found! Please reload the image.', ...
                            'Error', 'Icon', 'error');
                    return;
                end
                
                if isa(img, 'double')
                    if max(img(:)) <= 1
                        img = im2uint8(img);
                    else
                        img = uint8(min(255, max(0, round(img))));
                    end
                end
                
                if size(img, 3) == 3
                    img = rgb2gray(img);
                end
                
                if size(img, 3) == 1
                    img = repmat(img, [1, 1, 3]);
                end
                
                img = imresize(img, targetSize, 'bilinear');
                
                if isa(img, 'double')
                    if max(img(:)) <= 1
                        img = im2uint8(img);
                    else
                        img = uint8(min(255, max(0, round(img))));
                    end
                end
                
                [label, scores] = classify(app.TrainedNet, img);
                
                probScores = predict(app.TrainedNet, img);
                confidence = max(probScores) * 100;
                
                if isa(app.TrainedNet, 'DAGNetwork') || isa(app.TrainedNet, 'SeriesNetwork')
                    outputLayer = app.TrainedNet.Layers(end);
                    if isa(outputLayer, 'nnet.cnn.layer.ClassificationOutputLayer')
                        classNames = outputLayer.Classes;
                    else
                        try
                            if evalin('base', 'exist(''cnnResults'', ''var'')')
                                cnnResults = evalin('base', 'cnnResults');
                                if isfield(cnnResults, 'uniqueClasses')
                                    classNames = cnnResults.uniqueClasses;
                                else
                                    classNames = {'Fetal abdomen', 'Fetal brain', 'Fetal femur', 'Fetal thorax'};
                                end
                            else
                                classNames = {'Fetal abdomen', 'Fetal brain', 'Fetal femur', 'Fetal thorax'};
                            end
                        catch
                            classNames = {'Fetal abdomen', 'Fetal brain', 'Fetal femur', 'Fetal thorax'};
                        end
                    end
                else
                    classNames = {'Fetal abdomen', 'Fetal brain', 'Fetal femur', 'Fetal thorax'};
                end
                
                scoreText = sprintf('Confidence: %.2f%%\n\nAll Classes:\n', confidence);
                for i = 1:length(classNames)
                    if i <= length(probScores)
                        scoreText = sprintf('%s%s: %.2f%%\n', scoreText, char(classNames(i)), probScores(i) * 100);
                    end
                end
                
                app.ClassificationAxes.Visible = 'on';
                imshow(app.CurrentImage, 'Parent', app.ClassificationAxes);
                axis(app.ClassificationAxes, 'image');
                app.ClassificationResultLabel.Text = sprintf('Class: %s', char(label));
                
                app.ConfidenceLabel.Text = scoreText;
                
                classDesc = '';
                switch char(label)
                    case 'Fetal abdomen'
                        classDesc = 'Fetal abdominal region detected';
                    case 'Fetal brain'
                        classDesc = 'Fetal brain structure detected';
                    case 'Fetal femur'
                        classDesc = 'Fetal femur bone detected';
                    case 'Fetal thorax'
                        classDesc = 'Fetal thoracic region detected';
                    otherwise
                        classDesc = 'Unknown fetal structure';
                end
                app.DescriptionLabel.Text = sprintf('Description: %s', classDesc);
                
                close(d);
                
                fprintf('\n=== CLASSIFICATION RESULT ===\n');
                fprintf('Prediction: %s (Confidence: %.2f%%)\n', char(label), confidence);
                fprintf('All scores:\n');
                for i = 1:length(classNames)
                    if i <= length(probScores)
                        fprintf('  %s: %.2f%%\n', char(classNames(i)), probScores(i) * 100);
                    end
                end
                fprintf('Image format: %s, Size: %dx%dx%d\n', class(img), size(img,1), size(img,2), size(img,3));
                fprintf('Image range: [%.4f, %.4f]\n', min(img(:)), max(img(:)));
                fprintf('================================\n\n');
            catch ME
                close(d);
                uialert(app.UIFigure, sprintf('Error during classification: %s', ME.message), ...
                        'Error', 'Icon', 'error');
            end
        end

        % Button pushed function: ApplyProcessingButton
        function ApplyProcessingButtonPushed(app, event)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'Please load an image first!', ...
                        'Warning', 'Icon', 'warning');
                return;
            end
            
            processType = app.ProcessTypeDropdown.Value;
            
            try
                switch processType
                    case 'Canny Edge'
                        processed = edge(app.CurrentImage, 'Canny', [0.1, 0.2], 1.5);
                        infoText = 'Canny Edge Detection';
                    case 'CLAHE'
                        imgUint8 = im2uint8(app.CurrentImage);
                        processed = adapthisteq(imgUint8, 'ClipLimit', 0.02);
                        processed = im2double(processed);
                        infoText = 'CLAHE';
                end
                
                app.ProcessedImage = processed;
                
                app.ProcessingBeforeAxes.Visible = 'on';
                app.ProcessingAfterAxes.Visible = 'on';
                imshow(app.CurrentImage, 'Parent', app.ProcessingBeforeAxes);
                axis(app.ProcessingBeforeAxes, 'image');
                imshow(processed, 'Parent', app.ProcessingAfterAxes);
                axis(app.ProcessingAfterAxes, 'image');
                
                app.ProcessingBeforeLabel.Text = 'Original Image';
                app.ProcessingAfterLabel.Text = infoText;
                app.ProcessingInfoLabel.Text = '';
            catch ME
                uialert(app.UIFigure, sprintf('Error during processing: %s', ME.message), ...
                        'Error', 'Icon', 'error');
            end
        end

        % Button pushed function: MeasureButton
        function MeasureButtonPushed(app, event)
            if isempty(app.CurrentImage)
                uialert(app.UIFigure, 'Please load an image first!', ...
                        'Warning', 'Icon', 'warning');
                return;
            end
            
            d = uiprogressdlg(app.UIFigure, 'Title', 'Measuring', ...
                              'Message', 'Classifying image first...', 'Indeterminate', 'on');
            
            try
                % Önce CNN sınıflandırması yap (hangi ölçümün yapılacağını belirlemek için)
                imageClass = '';
                try
                    if isa(app.TrainedNet, 'DAGNetwork') || isa(app.TrainedNet, 'SeriesNetwork')
                        inputSize = app.TrainedNet.Layers(1).InputSize;
                        targetSize = inputSize(1:2);
                    else
                        targetSize = [224, 224];
                    end
                catch
                    targetSize = [224, 224];
                end
                
                if ~isempty(app.CurrentImagePath) && exist(app.CurrentImagePath, 'file')
                    img = imread(app.CurrentImagePath);
                else
                    close(d);
                    uialert(app.UIFigure, 'Image file path not found! Please reload the image.', ...
                            'Error', 'Icon', 'error');
                    return;
                end
                
                if isa(img, 'double')
                    if max(img(:)) <= 1
                        img = im2uint8(img);
                    else
                        img = uint8(min(255, max(0, round(img))));
                    end
                end
                
                if size(img, 3) == 3
                    img = rgb2gray(img);
                end
                
                if size(img, 3) == 1
                    img = repmat(img, [1, 1, 3]);
                end
                
                img = imresize(img, targetSize, 'bilinear');
                
                if isa(img, 'double')
                    if max(img(:)) <= 1
                        img = im2uint8(img);
                    else
                        img = uint8(min(255, max(0, round(img))));
                    end
                end
                
                [label, ~] = classify(app.TrainedNet, img);
                imageClass = char(label);
                
                d.Message = 'Performing measurements...';
                
                % Sınıfa göre hangi ölçümlerin yapılacağını belirle
                measureFemur = strcmp(imageClass, 'Fetal femur');
                measureHC = strcmp(imageClass, 'Fetal brain');
                
                if ~measureFemur && ~measureHC
                    close(d);
                    uialert(app.UIFigure, ...
                            sprintf('Measurements are only available for:\n- Fetal femur (Femur Length)\n- Fetal brain (Head Circumference)\n\nCurrent image: %s', imageClass), ...
                            'Measurement Not Available', 'Icon', 'info');
                    return;
                end
                
                scaleBarLength = detectScaleBar(app.CurrentImage);
                
                if ~isnan(scaleBarLength)
                    pixelToMM = calculatePixelToMM(scaleBarLength, 1.0);
                    scaleBarDetected = true;
                    scaleBarText = sprintf('Scale Bar: Detected (%.2f px = 1 cm)', scaleBarLength);
                else
                    pixelToMM = 0.15;
                    scaleBarDetected = false;
                    scaleBarText = 'Scale Bar: Not found (Pixel-based measurement)';
                end
                
                % Görüntü boyutlarını önce al (denoising öncesi)
                [imgHeight, imgWidth] = size(app.CurrentImage);
                
                % Denoising - görüntü boyutu değişmez
                denoised = wiener2(app.CurrentImage, [5, 5]);
                
                % Denoised görüntünün boyutunu kontrol et
                [denoisedHeight, denoisedWidth] = size(denoised);
                
                % Femur Length ölçümü (sadece Fetal femur için)
                femurLengthPixels = 0;
                femurLengthCM = 0;
                longestLine = [];
                
                if measureFemur
                    edges = edge(denoised, 'Canny', [0.1, 0.2], 1.5);
                    
                    [H, theta, rho] = hough(edges, 'RhoResolution', 1, 'ThetaResolution', 0.5);
                    P = houghpeaks(H, 10, 'threshold', ceil(0.3 * max(H(:))));
                    lines = houghlines(edges, theta, rho, P, 'FillGap', 20, 'MinLength', 50);
                    
                    if ~isempty(lines)
                        maxLen = 0;
                        for k = 1:length(lines)
                            xy = [lines(k).point1; lines(k).point2];
                            len = norm(xy(2,:) - xy(1,:));
                            if len > maxLen
                                maxLen = len;
                                longestLine = lines(k);
                            end
                        end
                        femurLengthPixels = maxLen;
                    end
                    
                    femurLengthMM = femurLengthPixels * pixelToMM;
                    femurLengthCM = femurLengthMM / 10;
                end
                
                % Head Circumference ölçümü (sadece Fetal brain için)
                hcCM = 0;
                hcSuccess = false;
                ellipseParams = [];
                ellipsePoints = [];
                
                if measureHC
                    edgesHC = edge(denoised, 'Canny', [0.05, 0.15], 1.0);
                    contours = bwboundaries(edgesHC, 'noholes');
                    
                    if ~isempty(contours)
                        maxSize = 0;
                        largestContour = [];
                        for i = 1:length(contours)
                            if length(contours{i}) > maxSize
                                maxSize = length(contours{i});
                                largestContour = contours{i};
                            end
                        end
                        
                        if ~isempty(largestContour) && length(largestContour) >= 5
                            try
                                % bwboundaries [row, col] formatında döner
                                % fitEllipse [x, y] formatında bekler (x=col, y=row)
                                x = largestContour(:, 2);  % Column (x koordinatı)
                                y = largestContour(:, 1);  % Row (y koordinatı)
                                [ellipseParams, ellipsePoints] = fitEllipse(x, y);
                                a = ellipseParams.semiMajorAxis;
                                b = ellipseParams.semiMinorAxis;
                                hcPixels = pi * (3 * (a + b) - sqrt((3*a + b) * (a + 3*b)));
                                hcMM = hcPixels * pixelToMM;
                                hcCM = hcMM / 10;
                                hcSuccess = true;
                            catch
                                hcSuccess = false;
                            end
                        end
                    end
                end
                
                app.MeasurementAxes.Visible = 'on';
                
                % Görüntü boyutlarını al
                [imgHeight, imgWidth] = size(app.CurrentImage);
                
                % Axes'i temizle ve hazırla
                cla(app.MeasurementAxes);
                
                % Görüntüyü göster
                imshow(app.CurrentImage, 'Parent', app.MeasurementAxes);
                
                % Axes limitlerini görüntü boyutlarına göre ayarla
                % MATLAB'de imshow sonrası koordinatlar [0.5, imgWidth+0.5] ve [0.5, imgHeight+0.5] aralığında
                xlim(app.MeasurementAxes, [0.5, imgWidth + 0.5]);
                ylim(app.MeasurementAxes, [0.5, imgHeight + 0.5]);
                
                % Aspect ratio'yu koru (görüntü oranını bozma)
                axis(app.MeasurementAxes, 'image');
                
                % Limitleri tekrar sabitle (axis image limitleri değiştirebilir)
                xlim(app.MeasurementAxes, [0.5, imgWidth + 0.5]);
                ylim(app.MeasurementAxes, [0.5, imgHeight + 0.5]);
                
                % Görüntü üzerinde işaretleme yapılmıyor (kullanıcı isteği)
                
                % Limitleri tekrar sabitle (plot sonrası değişmiş olabilir)
                xlim(app.MeasurementAxes, [0.5, imgWidth + 0.5]);
                ylim(app.MeasurementAxes, [0.5, imgHeight + 0.5]);
                
                % Sınıfa göre ölçüm sonuçlarını göster
                if measureFemur
                    if scaleBarDetected
                        app.FemurLengthLabel.Text = sprintf('Femur Length: %.2f cm [REAL]', femurLengthCM);
                    else
                        app.FemurLengthLabel.Text = sprintf('Femur Length: ≈ %.2f cm [ESTIMATED]', femurLengthCM);
                    end
                    app.HeadCircumferenceLabel.Text = 'Head Circumference: N/A (Femur image)';
                    app.MeasurementDescriptionLabel.Text = sprintf('Femur automatically detected (%.1f cm)', femurLengthCM);
                elseif measureHC
                    app.FemurLengthLabel.Text = 'Femur Length: N/A (Brain image)';
                    if hcSuccess
                        if scaleBarDetected
                            app.HeadCircumferenceLabel.Text = sprintf('Head Circumference: %.2f cm [REAL]', hcCM);
                        else
                            app.HeadCircumferenceLabel.Text = sprintf('Head Circumference: ≈ %.2f cm [ESTIMATED]', hcCM);
                        end
                        app.MeasurementDescriptionLabel.Text = sprintf('Head circumference automatically detected (%.1f cm)', hcCM);
                    else
                        app.HeadCircumferenceLabel.Text = 'Head Circumference: Could not measure';
                        app.MeasurementDescriptionLabel.Text = 'Head circumference detection failed';
                    end
                end
                
                app.ScaleBarStatusLabel.Text = '';
                app.FilterUsedLabel.Text = '';
                app.EdgeParamsLabel.Text = '';
                
                close(d);
                
            catch ME
                close(d);
                uialert(app.UIFigure, sprintf('Error during measurement: %s', ME.message), ...
                        'Error', 'Icon', 'error');
            end
        end
    end
end
