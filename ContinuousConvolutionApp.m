classdef ContinuousConvolutionApp < matlab.apps.AppBase

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
        tau = []
        x_t = []
        t_x = []
        h_t = []
        t_h = []
        y_t = []
        t_y = []
    end

    methods (Access = private)

       function [x, t_x, h, t_h, isValid] = getInputs(app)
    isValid = false;

    % Process x(t)
    try
        t_start = app.xMinInput.Value;
        t_end = app.xMaxInput.Value;
        if t_start >= t_end
            errordlg('x(t) start must be less than end');
            return;
        end
        t_x = linspace(t_start, t_end, 1000);
        t = t_x;

        if strcmpi(strtrim(app.xInput.Value), 'Impulse')
            x = zeros(size(t_x));
            [~, idx0] = min(abs(t_x));
            x(idx0) = 1 / (t_x(2) - t_x(1)); % Approximate delta with area 1
        else
            x = double(eval(app.xInput.Value));
        end

        if length(x) ~= length(t_x)
            errordlg('x(t) length mismatch');
            return;
        end
    catch ME
        errordlg(['Invalid x(t): ' ME.message]);
        return;
    end

    % Process h(t)
    try
        t_start = app.hMinInput.Value;
        t_end = app.hMaxInput.Value;
        if t_start >= t_end
            errordlg('h(t) start must be less than end');
            return;
        end
        t_h = linspace(t_start, t_end, 1000);
        t = t_h;

        if strcmpi(strtrim(app.hInput.Value), 'Impulse')
            h = zeros(size(t_h));
            [~, idx0] = min(abs(t_h));
            h(idx0) = 1 / (t_h(2) - t_h(1)); % Approximate delta
        else
            h = double(eval(app.hInput.Value));
        end

        if length(h) ~= length(t_h)
            errordlg('h(t) length mismatch');
            return;
        end
    catch ME
        errordlg(['Invalid h(t): ' ME.message]);
        return;
    end

    % Save results
    app.t_x = t_x;
    app.x_t = x;
    app.t_h = t_h;
    app.h_t = h;

    isValid = true;
end

        function plotFixedSignals(app)
            plot(app.xAxes, app.t_x, app.x_t, 'y', 'LineWidth', 1.5);
            app.xAxes.Color = 'k';
            title(app.xAxes, 'x(t)', 'Color', 'w'); 
            grid(app.xAxes, 'on');
            app.xAxes.XColor = 'w'; app.xAxes.YColor = 'w';
            xlim(app.xAxes, [min(app.t_x)-0.5, max(app.t_x)+0.5]);
            
            app.h_rev = fliplr(app.h_t);
            app.tau = -fliplr(app.t_h);
            plot(app.hAxes, app.tau, app.h_rev, 'y', 'LineWidth', 1.5);
            app.hAxes.Color = 'k';
            title(app.hAxes, 'h(-τ)', 'Color', 'w'); 
            grid(app.hAxes, 'on');
            app.hAxes.XColor = 'w'; app.hAxes.YColor = 'w';
            xlim(app.hAxes, [min(app.tau)-0.5, max(app.tau)+0.5]);
        end
       function ConvolveButtonPushed(app, ~, ~)
    [x, t_x, h, t_h, isValid] = app.getInputs();
    if ~isValid, return; end

    dt = t_x(2) - t_x(1);
    isImpulseX = strcmpi(strtrim(app.xInput.Value), 'Impulse');
    isImpulseH = strcmpi(strtrim(app.hInput.Value), 'Impulse');

    % Determine output y(t) based on impulse presence
    if isImpulseX && ~isImpulseH
        % x(t) = delta(t), so y(t) = h(t)
        conv_result = h;
        t_conv = t_h;
    elseif ~isImpulseX && isImpulseH
        % h(t) = delta(t), so y(t) = x(t)
        conv_result = x;
        t_conv = t_x;
    else
        % Normal convolution
        conv_result = conv(x, h, 'full') * dt;
        t_conv = t_x(1) + t_h(1) + (0:length(conv_result)-1) * dt;
    end

    app.y_t = conv_result;
    app.t_y = t_conv;

    % Plot result
    plot(app.yAxes, app.t_y, app.y_t, 'y', 'LineWidth', 1.5);
    app.yAxes.Color = 'k';
    title(app.yAxes, 'x(t)*h(t)', 'Color', 'w');
    grid(app.yAxes, 'on');
    app.yAxes.XColor = 'w';
    app.yAxes.YColor = 'w';
    xlim(app.yAxes, [min(app.t_y)-0.5, max(app.t_y)+0.5]);

    app.plotFixedSignals();
end

        % Correlation button callback function
        function CorrelationButtonPushed(app, ~, ~)
            [x, t_x, h, t_h, isValid] = app.getInputs();
            if ~isValid, return; end
            
            dt = t_x(2) - t_x(1);
            % Computing correlation via convolution with time-reversed signal
            correlation = conv(x, h(end:-1:1), 'full') * dt;
            t_corr = t_x(1) - t_h(end) + (0:length(correlation)-1)*dt;
             
            plot(app.yAxes, t_corr, correlation, 'c', 'LineWidth', 1.5);
            app.yAxes.Color = 'k';
            title(app.yAxes, 'Correlation: R_{xh}(\tau)', 'Color', 'w');
            grid(app.yAxes, 'on');
            app.yAxes.XColor = 'w'; app.yAxes.YColor = 'w';
            xlim(app.yAxes, [min(t_corr)-0.5, max(t_corr)+0.5]);
            
            app.plotFixedSignals();
        end

        function AnimateButtonPushed(app, ~, ~)
            app.StopFlag = false;
            [x, t_x, h, t_h, isValid] = app.getInputs();
            if ~isValid, return; end
           
            dt = t_x(2) - t_x(1);
            conv_result = conv(x, h, 'full') * dt;
            t_conv = t_x(1) + t_h(1) + (0:length(conv_result)-1)*dt;
            app.y_t = conv_result;
            app.t_y = t_conv;
            num_frames = length(t_conv);
            
            cla(app.animAxes);
            cla(app.yAxes);
            plot(app.yAxes, app.t_y, app.y_t, 'y', 'LineWidth', 1.5);
            title(app.yAxes, 'x(t)*h(t)', 'Color', 'w');
            app.yAxes.Color = 'k'; 
            grid(app.yAxes, 'on');
            app.yAxes.XColor = 'w'; 
            app.yAxes.YColor = 'w';
            xlim(app.yAxes, [min(app.t_y)-0.5, max(app.t_y)+0.5]);
            hold(app.yAxes, 'on');
            
            tau_min = min([t_x, t_h]);
            tau_max = max([t_x, t_h]);
            tau = linspace(tau_min, tau_max, 1000);
            
            x_tau = interp1(t_x, x, tau, 'linear', 0);
            
            i = 1;
            while i <= num_frames
                if app.StopFlag, break; end
                t_val = t_conv(i);
                
                query_points = t_val - tau;
                h_shifted = interp1(t_h, h, query_points, 'linear', 0);
                
                cla(app.animAxes);
                hold(app.animAxes, 'on');
                plot(app.animAxes, tau, x_tau, 'y', 'LineWidth', 1.5);
                plot(app.animAxes, tau, h_shifted, 'r', 'LineWidth', 1.5);
                plot(app.yAxes, t_val, app.y_t(i), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
                
                title(app.animAxes, sprintf('Animation: t = %.2f', t_val), 'Color', 'w');
                app.animAxes.Color = 'k'; 
                grid(app.animAxes, 'on');
                app.animAxes.XColor = 'w'; 
                app.animAxes.YColor = 'w';
                xlim(app.animAxes, [tau_min-0.5, tau_max+0.5]);
                
                min_val = min([min(x), min(h)]);
                max_val = max([max(x), max(h)]);
                if min_val == max_val
                    padding = 1;
                else
                    padding = 0.2*(max_val - min_val);
                end
                ylim(app.animAxes, [min_val - padding, max_val + padding]);
                
                hold(app.animAxes, 'off');
                drawnow;
                
                while app.SpeedSlider.Value == 0 && ~app.StopFlag
                    pause(0.05);
                end
                if app.StopFlag, break; end
                
                s = app.SpeedSlider.Value;
                step_time = 0.1 * s;
                step_samples = round(step_time / dt);
                if step_samples < 1
                    step_samples = 1;
                end
                i = i + step_samples;
                
                pause(0.01);
            end
            hold(app.yAxes, 'off');
        end

        function StopButtonPushed(app, ~, ~)
            app.StopFlag = true;
        end

        function RestartButtonPushed(app, ~, ~)
            cla(app.animAxes); 
            cla(app.yAxes);
            cla(app.hAxes);
            cla(app.xAxes);
            app.StopFlag = false;
        end

        function updatePredefinedSignal(app, dropdown, target, minField, maxField)
            switch dropdown.Value
                case 'Impulse'
                    
                  target.Value = 'Impulse';
                  minField.Value = -1;
                  maxField.Value = 1;

                case 'Step'
                    target.Value = '(t>=0)';
                    minField.Value = -2;
                    maxField.Value = 2;
                case 'Triangular'
                    target.Value = 'max(0,1-abs(t))';
                    minField.Value = -1;
                    maxField.Value = 1;
                case 'Rectangular'
                    target.Value = '((t>=-0.5)&(t<=0.5))';
                    minField.Value = -1;
                    maxField.Value = 1;
                case 'Sawtooth'
                    target.Value = 'mod(t,1)';
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
            DiscreteConvolutionApp();
        end
    end

    methods (Access = public)
        function app = ContinuousConvolutionApp
            app.createComponents();
            registerApp(app, app.UIFigure);
        end
        
        function delete(app)
            delete(app.UIFigure);
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Name', 'Continuous Convolution Visualizer','Position', [100 100 970 650],'Color', [0.2 0.2 0.2]);
            app.ManualLabel = uilabel(app.UIFigure,'Text', 'Manual Signal','Position', [50 610 100 22],'FontColor', 'w','FontWeight', 'bold');
            app.xLabel = uilabel(app.UIFigure,'Text', 'x(t):','Position', [50 580 30 22],'FontColor', 'w');
            app.xInput = uieditfield(app.UIFigure, 'text','Position', [80 580 100 22],'Value', '(t==0)','BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            app.hLabel = uilabel(app.UIFigure, 'Text', 'h(t):', 'Position', [50 540 30 22],'FontColor', 'w');
            app.hInput = uieditfield(app.UIFigure, 'text','Position', [80 540 100 22], 'Value', '(t>=0)', 'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            app.RangeLabel = uilabel(app.UIFigure,'Text', 'Time Range','Position', [200 610 80 22], 'FontColor', 'w','FontWeight', 'bold');
            
            uilabel(app.UIFigure, 'Text', 'Min t:', 'Position', [200 580 45 22], 'FontColor', 'w');
            app.xMinInput = uieditfield(app.UIFigure, 'numeric','Position', [250 580 50 22], 'Value', -1,'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            uilabel(app.UIFigure, 'Text', 'Max t:', 'Position', [310 580 45 22], 'FontColor', 'w');
            app.xMaxInput = uieditfield(app.UIFigure, 'numeric', 'Position', [360 580 50 22],'Value', 1,'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            uilabel(app.UIFigure, 'Text', 'Min t:', 'Position', [200 540 45 22], 'FontColor', 'w');
            app.hMinInput = uieditfield(app.UIFigure, 'numeric','Position', [250 540 50 22], 'Value', -2, 'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            uilabel(app.UIFigure, 'Text', 'Max t:', 'Position', [310 540 45 22], 'FontColor', 'w');
            app.hMaxInput = uieditfield(app.UIFigure, 'numeric','Position', [360 540 50 22],'Value', 2, 'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w');
            
            app.PredefinedLabel = uilabel(app.UIFigure,'Text', 'Predefined Signal', 'Position', [500 610 120 22],'FontColor', 'w','FontWeight', 'bold');
            
            uilabel(app.UIFigure, 'Text', 'x(t):', 'Position', [500 580 40 22], 'FontColor', 'w');
            app.xDropDown = uidropdown(app.UIFigure,'Position', [540 580 120 22],'Items', {'Impulse', 'Step', 'Triangular', 'Rectangular', 'Sawtooth'},'ValueChangedFcn', @(~,~) app.xDropDownChanged(),'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w','FontAngle','italic');
            
            uilabel(app.UIFigure, 'Text', 'h(t):', 'Position', [500 540 40 22], 'FontColor', 'w');
            app.hDropDown = uidropdown(app.UIFigure,'Position', [540 540 120 22],'Items', {'Impulse', 'Step', 'Triangular', 'Rectangular', 'Sawtooth'},'Value', 'Step','ValueChangedFcn', @(~,~) app.hDropDownChanged(),'BackgroundColor', [0.3 0.3 0.3],'FontColor', 'w','FontAngle','italic');

            % Button positions 
            app.ConvolveButton = uibutton(app.UIFigure, 'push','Text', 'Convolve','Position', [700 580 80 25],'ButtonPushedFcn', @(~,~) app.ConvolveButtonPushed(),'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.AnimateButton = uibutton(app.UIFigure, 'push', 'Text', 'Animate', 'Position', [790 580 80 25],'ButtonPushedFcn', @(~,~) app.AnimateButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.CorrelationButton = uibutton(app.UIFigure, 'push', 'Text', 'Correlation', 'Position', [880 580 80 25], 'ButtonPushedFcn', @(~,~) app.CorrelationButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4], 'FontColor', 'w'); % NEW
            app.StopButton = uibutton(app.UIFigure, 'push', 'Text', 'Stop', 'Position', [700 540 80 25],'ButtonPushedFcn', @(~,~) app.StopButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.RestartButton = uibutton(app.UIFigure, 'push','Text', 'Restart','Position', [790 540 80 25],'ButtonPushedFcn', @(~,~) app.RestartButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4],'FontColor', 'w');
            app.SpeedSliderLabel = uilabel(app.UIFigure, 'Text', 'Animation Speed','FontAngle','italic','Position', [670 130 100 22],'FontColor', 'w');
            app.SpeedSlider = uislider(app.UIFigure,'Position', [670 120 180 3], 'Limits', [0 1],'Value', 0.5,'MajorTicks', [0 0.2 0.4 0.6 0.8 1],'MajorTickLabels', {'0', '0.2', '0.4', '0.6', '0.8', '1'},'FontColor','w'); 
            app.SwitchModeButton = uibutton(app.UIFigure, 'push', 'Text', 'Switch to Discrete', 'Position', [50 100 180 25],'ButtonPushedFcn', @(~,~) app.SwitchModeButtonPushed(), 'BackgroundColor', [0.4 0.4 0.4], 'FontColor', 'w');
   
            app.xAxes = uiaxes(app.UIFigure,'Position', [40 380 360 150], 'Box', 'on');
            title(app.xAxes, 'x(t)','Color','w','FontName','Times new roman');
            
            app.hAxes = uiaxes(app.UIFigure,'Position', [500 380 360 150],'Box', 'on');
            title(app.hAxes, 'h(-τ)','Color','w','FontName','Times new roman');
            
            app.yAxes = uiaxes(app.UIFigure,'Position', [40 180 360 150],'Box', 'on');
            title(app.yAxes, 'x(t)*h(t)','Color','w','FontName','Times new roman');
            
            app.animAxes = uiaxes(app.UIFigure,'Position', [500 180 360 150],'Box', 'on');
            title(app.animAxes, 'Animation: x(τ) and h(t-τ)','Color','w','FontName','Times new roman');
            
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