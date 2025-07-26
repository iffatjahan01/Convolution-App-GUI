classdef DiscreteConvolutionApp < matlab.apps.AppBase

    properties (Access = public)
        UIFigure             matlab.ui.Figure
        xInput              matlab.ui.control.EditField
        hInput              matlab.ui.control.EditField
        xMinInput           matlab.ui.control.NumericEditField
        xMaxInput           matlab.ui.control.NumericEditField
        hMinInput           matlab.ui.control.NumericEditField
        hMaxInput           matlab.ui.control.NumericEditField
        ConvolveButton      matlab.ui.control.Button
        AnimateButton       matlab.ui.control.Button
        StopButton          matlab.ui.control.Button
        RestartButton       matlab.ui.control.Button
        CorrelationButton   matlab.ui.control.Button  
        SpeedSliderLabel    matlab.ui.control.Label
        SpeedSlider         matlab.ui.control.Slider
        xAxes               matlab.ui.control.UIAxes
        hAxes               matlab.ui.control.UIAxes
        yAxes               matlab.ui.control.UIAxes
        animAxes            matlab.ui.control.UIAxes
        xDropDown           matlab.ui.control.DropDown
        hDropDown           matlab.ui.control.DropDown
        PredefinedLabel     matlab.ui.control.Label
        ManualLabel         matlab.ui.control.Label
        RangeLabel          matlab.ui.control.Label
        xLabel              matlab.ui.control.Label
        hLabel              matlab.ui.control.Label
        SwitchModeButton    matlab.ui.control.Button
    end

    properties (Access = private)
        StopFlag = false
        h_rev = []
        nh_rev = []
    end

    methods (Access = private)

        function [x, nx, h, nh, isValid] = getInputs(app)
            isValid = false;
            try
                nx = app.xMinInput.Value:app.xMaxInput.Value;
                n = nx;  % define n for evaluation
                x = eval(app.xInput.Value);
                if length(x) ~= length(nx)
                    errordlg('x[n] length mismatch'); return;
                end
            catch ME
                errordlg(['Invalid x[n]: ' ME.message]); 
                return;
            end
            try
                nh = app.hMinInput.Value:app.hMaxInput.Value;
                n = nh;  % define n for evaluation
                h = eval(app.hInput.Value);
                if length(h) ~= length(nh)
                    errordlg('h[n] length mismatch'); return;
                end
            catch ME
                errordlg(['Invalid h[n]: ' ME.message]); 
                return;
            end
            isValid = true;
        end
        function plotFixedSignals(app, nx, x, nh, h)
            stem(app.xAxes, nx, x, 'filled', 'LineWidth', 1.2, 'Color', 'yellow');
            app.xAxes.Color = 'k';
            title(app.xAxes, 'x[n]', 'Color', 'w'); 
            grid(app.xAxes, 'on');
            app.xAxes.XColor = 'w'; app.xAxes.YColor = 'w';
            xlim(app.xAxes, [min(nx)-1, max(nx)+1]);
            
            app.h_rev = fliplr(h);  
            app.nh_rev = -fliplr(nh);
            stem(app.hAxes, app.nh_rev, app.h_rev, 'filled', 'LineWidth', 1.2, 'Color', 'yellow');
            app.hAxes.Color = 'k';
            title(app.hAxes, 'h[-n]', 'Color', 'w'); 
            grid(app.hAxes, 'on');
            app.hAxes.XColor = 'w'; app.hAxes.YColor = 'w';
            xlim(app.hAxes, [min(app.nh_rev)-1, max(app.nh_rev)+1]);
        end
        function ConvolveButtonPushed(app, ~, ~)
            [x, nx, h, nh, isValid] = app.getInputs();
            if ~isValid, return; end
            y = conv(x, h);
            ny = nx(1)+nh(1):nx(end)+nh(end);
            stem(app.yAxes, ny, y, 'filled', 'Color', 'yellow');
            app.yAxes.Color = 'k';
            title(app.yAxes, 'x[n]*h[n]', 'Color', 'w'); 
            grid(app.yAxes, 'on');
            app.yAxes.XColor = 'w'; app.yAxes.YColor = 'w';
            xlim(app.yAxes, [min(ny)-1, max(ny)+1]);
            app.plotFixedSignals(nx, x, nh, h);
        end
        % correlation button callback function
        function CorrelationButtonPushed(app, ~, ~)
            [x, nx, h, nh, isValid] = app.getInputs();
            if ~isValid, return; end
            
            % compute correlation 
            correlation = conv(x, h(end:-1:1));
            n_corr = (nx(1) - nh(end)) : (nx(end) - nh(1));
            
            % plot 
            stem(app.yAxes, n_corr, correlation, 'filled', 'Color', 'c');
            title(app.yAxes, 'Correlation: R_{xh}[n]', 'Color', 'w');
            grid(app.yAxes, 'on');
            app.yAxes.XColor = 'w'; app.yAxes.YColor = 'w';
            xlim(app.yAxes, [min(n_corr)-1, max(n_corr)+1]);
            
            % plot the fixed signals
            app.plotFixedSignals(nx, x, nh, h);
        end
        function AnimateButtonPushed(app, ~, ~) % animate button
            app.StopFlag = false;
            [x, nx, h, nh, isValid] = app.getInputs();
            if ~isValid, return; end
            
            h_rev = fliplr(h);
            nh_rev = -fliplr(nh);
            app.h_rev = h_rev;
            app.nh_rev = nh_rev;
            
            ny = nx(1)+nh(1):nx(end)+nh(end);
            y = conv(x, h);
            
            total_time = interp1([0, 0.8, 1], [20, 5, 3], app.SpeedSlider.Value, 'linear', 'extrap');
            delay = total_time / length(ny);
            
            cla(app.animAxes); 
            cla(app.yAxes);
            stem(app.yAxes, ny, zeros(size(ny)), 'filled', 'Color', 'yellow');
            title(app.yAxes, 'x[n]*h[n]', 'Color', 'w');
            app.yAxes.Color = 'k'; 
            grid(app.yAxes, 'on');
            app.yAxes.XColor = 'w'; 
            app.yAxes.YColor = 'w';
            xlim(app.yAxes, [min(ny)-1, max(ny)+1]);
            hold(app.yAxes, 'on');
            
            for i = 1:length(ny)
                if app.StopFlag, break; end
                n = ny(i);
                shift = nh_rev + n;
                
                cla(app.animAxes);
                hold(app.animAxes, 'on');
                stem(app.animAxes, nx, x, 'filled', 'LineWidth', 1.2, 'Color', 'yellow');
                stem(app.animAxes, shift, h_rev, 'filled', 'LineWidth', 1.2, 'Color', 'r');
                
                title(app.animAxes, sprintf('Animation: n = %d', n), 'Color', 'w');
                app.animAxes.Color = 'k'; 
                grid(app.animAxes, 'on');
                app.animAxes.XColor = 'w'; 
                app.animAxes.YColor = 'w';
                xlim(app.animAxes, [min([nx, shift])-1, max([nx, shift])+1]);
                hold(app.animAxes, 'off');
                stem(app.yAxes, ny(i), y(i), 'filled', 'Color', 'red', 'MarkerSize', 8);
                drawnow;
                
                pause(delay);
            end
            hold(app.yAxes, 'off');
        end
        function StopButtonPushed(app, ~, ~)
            app.StopFlag = true;
        end
        function RestartButtonPushed(app, ~, ~)
            cla(app.animAxes); 
            cla(app.yAxes);
            app.StopFlag = false;
        end
        function updatePredefinedSignal(app, dropdown, target, minField, maxField)
            switch dropdown.Value
                case 'Impulse'
                    target.Value = 'n==0';
                    minField.Value = 0;
                    maxField.Value = 0;
                case 'Step'
                    target.Value = 'n>=0';
                    minField.Value = -2;
                    maxField.Value = 2;
                case 'Triangular'
                    target.Value = '1-abs(n)';
                    minField.Value = -1;
                    maxField.Value = 1;
                case 'Rectangular'
                    target.Value = '(n>=-0.5)&(n<=0.5)';
                    minField.Value = -1;
                    maxField.Value = 1;
                case 'Sawtooth'
                    target.Value = 'mod(n,1)';
                    minField.Value = 0;
                    maxField.Value = 3;
            end
        end
        function xDropDownChanged(app, ~, ~)
            app.updatePredefinedSignal(app.xDropDown, app.xInput, app.xMinInput, app.xMaxInput);
        end
        function hDropDownChanged(app, ~, ~)
            app.updatePredefinedSignal(app.hDropDown, app.hInput, app.hMinInput, app.hMaxInput);
        end
        function SwitchModeButtonPushed(app, ~, ~)
            delete(app.UIFigure);
            ContinuousConvolutionApp();
        end
    end
    methods (Access = public)
        function app = DiscreteConvolutionApp
            app.createComponents();
            registerApp(app, app.UIFigure);
        end
        
        function delete(app)
            delete(app.UIFigure);
        end
    end
    methods (Access = private)
        function createComponents(app) 
            app.UIFigure = uifigure('Name', 'Discrete Convolution Visualizer','Position', [100 100 970 650],'Color', [0.2 0.2 0.2]);   
            app.ManualLabel = uilabel(app.UIFigure,'Text', 'Manual Signal','Position', [50 610 100 22],'FontColor', 'w', 'FontWeight', 'bold'); 
            app.xLabel = uilabel(app.UIFigure,'Text', 'x[n]:','Position', [50 580 30 22],'FontColor', 'w');
            app.xInput = uieditfield(app.UIFigure, 'text','Position', [80 580 100 22],'Value', 'n==0','BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            app.hLabel = uilabel(app.UIFigure,'Text', 'h[n]:','Position', [50 540 30 22],'FontColor', 'w');
            app.hInput = uieditfield(app.UIFigure, 'text','Position', [80 540 100 22],'Value', 'n>=0','BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            app.RangeLabel = uilabel(app.UIFigure, 'Text', 'Index Range', 'Position', [200 610 80 22], 'FontColor', 'w','FontWeight', 'bold');
            
            uilabel(app.UIFigure, 'Text', 'Min n:', 'Position', [200 580 45 22], 'FontColor', 'w');
            app.xMinInput = uieditfield(app.UIFigure, 'numeric', 'Position', [250 580 50 22],'Value', 0, 'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            uilabel(app.UIFigure, 'Text', 'Max n:', 'Position', [310 580 45 22], 'FontColor', 'w');
            app.xMaxInput = uieditfield(app.UIFigure, 'numeric','Position', [360 580 50 22],'Value', 0,'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            uilabel(app.UIFigure, 'Text', 'Min n:', 'Position', [200 540 45 22], 'FontColor', 'w');
            app.hMinInput = uieditfield(app.UIFigure, 'numeric', 'Position', [250 540 50 22],'Value', -2,'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            uilabel(app.UIFigure, 'Text', 'Max n:', 'Position', [310 540 45 22], 'FontColor', 'w');
            app.hMaxInput = uieditfield(app.UIFigure, 'numeric','Position', [360 540 50 22],'Value', 2,'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            app.PredefinedLabel = uilabel(app.UIFigure, 'Text', 'Predefined Signal','Position', [500 610 120 22], 'FontColor', 'w', 'FontWeight', 'bold');  
            
            uilabel(app.UIFigure, 'Text', 'x[n]:', 'Position', [500 580 40 22], 'FontColor', 'w');
            app.xDropDown = uidropdown(app.UIFigure,'Position', [540 580 120 22], 'Items', {'Impulse', 'Step', 'Triangular', 'Rectangular', 'Sawtooth'}, 'ValueChangedFcn', @(~,~) app.xDropDownChanged(),'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w','FontAngle','italic');
            
            uilabel(app.UIFigure, 'Text', 'h[n]:', 'Position', [500 540 40 22], 'FontColor', 'w');
            app.hDropDown = uidropdown(app.UIFigure,'Position', [540 540 120 22],'Items', {'Impulse', 'Step', 'Triangular', 'Rectangular', 'Sawtooth'},'Value', 'Step','ValueChangedFcn', @(~,~) app.hDropDownChanged(),'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w','FontAngle','italic');
            
            % Button positions 
            app.ConvolveButton = uibutton(app.UIFigure, 'push','Text', 'Convolve','Position', [700 580 80 25],'ButtonPushedFcn', @(~,~) app.ConvolveButtonPushed(),'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.AnimateButton = uibutton(app.UIFigure, 'push', 'Text', 'Animate', 'Position', [790 580 80 25],'ButtonPushedFcn', @(~,~) app.AnimateButtonPushed(),'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.CorrelationButton = uibutton(app.UIFigure, 'push', 'Text', 'Correlation', 'Position', [880 580 80 25], 'ButtonPushedFcn', @(~,~) app.CorrelationButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4], 'FontColor', 'w'); % NEW
            app.StopButton = uibutton(app.UIFigure, 'push', 'Text', 'Stop', 'Position', [700 540 80 25], 'ButtonPushedFcn', @(~,~) app.StopButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.RestartButton = uibutton(app.UIFigure, 'push','Text', 'Restart','Position', [790 540 80 25], 'ButtonPushedFcn', @(~,~) app.RestartButtonPushed(),'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.SpeedSliderLabel = uilabel(app.UIFigure,'Text', 'Animation Speed','FontAngle','italic','Position',  [670 130 100 22],'FontColor', 'w');
            app.SpeedSlider = uislider(app.UIFigure,'Position', [670 120 180 3],'Limits', [0 1],'Value', 0.5,'MajorTicks', [0 0.2 0.4 0.6 0.8 1],'MajorTickLabels', {'0', '0.2', '0.4', '0.6', '0.8', '1'},'FontColor','w');
            app.SwitchModeButton = uibutton(app.UIFigure, 'push', 'Text', 'Switch to Continuous', 'Position', [50 100 180 25],'ButtonPushedFcn', @(~,~) app.SwitchModeButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4], 'FontColor', 'w');
            
            app.xAxes = uiaxes(app.UIFigure,'Position', [40 380 360 150], 'Box', 'on');
            title(app.xAxes, 'x[n]','Color','w','FontName','Times new roman');
            app.hAxes = uiaxes(app.UIFigure,'Position', [500 380 360 150],'Box', 'on');
            title(app.hAxes, 'h[-n]','Color','w','FontName','Times new roman');
            app.yAxes = uiaxes(app.UIFigure,'Position', [40 180 360 150],'Box', 'on');
            title(app.yAxes, 'x[n]*h[n]','Color','w','FontName','Times new roman');
            app.animAxes = uiaxes(app.UIFigure, 'Position', [500 180 360 150],'Box', 'on');
            title(app.animAxes, 'Animation: x[k] and h[n-k]','Color','w','FontName','Times new roman');
            axesList = [app.xAxes, app.hAxes, app.yAxes, app.animAxes]; 
            for ax = axesList
                ax.Color = 'k';
                ax.XColor = 'w';
                ax.YColor = 'w';
                ax.GridColor = [0.5 0.5 0.5];
                ax.GridAlpha = 0.3;
                ax.FontWeight = 'bold';
                grid(ax, 'on');
            end

            app.xDropDown.Value = 'Impulse';
            app.hDropDown.Value = 'Step';
            app.xDropDownChanged();
            app.hDropDownChanged();
        end
    end
end