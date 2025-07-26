classdef ConvolutionModeSelectorApp < matlab.apps.AppBase
    properties
        UIFigure      matlab.ui.Figure
        ModeDropDown  matlab.ui.control.DropDown
        LaunchButton  matlab.ui.control.Button
    end
    methods (Access = private)
        function launchMode(app,~,~)
            selectedMode = app.ModeDropDown.Value;
            delete(app.UIFigure);  %close selector window
            switch selectedMode
                case 'Discrete'
                    DiscreteConvolutionApp();
                case 'Continuous'
                    ContinuousConvolutionApp();
            end
        end
        function createComponents(app)
            app.UIFigure = uifigure('Name','Select Mode','Position', [600 150 800 500],'Color', [0.2 0.2 0.2]); %dark theme
            app.ModeDropDown = uidropdown(app.UIFigure,'Items', {'Discrete', 'Continuous'},'Position', [270 260 100 30],'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            app.LaunchButton = uibutton(app.UIFigure,'push','Text', 'Launch','Position',[270 200 100 30],'ButtonPushedFcn', @app.launchMode,'FontColor', [0.1 0.1 0.1]);
        end
    end
    methods (Access = public)
        function app = ConvolutionModeSelectorApp
            createComponents(app);
        end
    end
end