classdef gui_fdei_analysisTest < matlab.unittest.TestCase
    %GUI_FDEI_ANALYSISTEST FDEI page and legacy page regression checks.

    properties
        FigureHandle
        PreviousDefaultFigureVisible
    end

    methods (TestMethodSetup)
        function createGui(testCase)
            testCase.PreviousDefaultFigureVisible = get(0, 'DefaultFigureVisible');
            set(0, 'DefaultFigureVisible', 'off');
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            addpath(genpath(fullfile(projectRoot, 'src')));
            main_gui;
            testCase.FigureHandle = findall(0, 'Type', 'figure', ...
                'Name', '悬架分析工具 - Suspension Analysis GUI');
            testCase.FigureHandle = testCase.FigureHandle(1);
            set(testCase.FigureHandle, 'Visible', 'off');
        end
    end

    methods (TestMethodTeardown)
        function closeGui(testCase)
            delete(testCase.FigureHandle);
            set(0, 'DefaultFigureVisible', testCase.PreviousDefaultFigureVisible);
        end
    end

    methods (Test)
        function testTopLevelPagesAndFdeiSubPages(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            testCase.verifyTrue(isfield(handles, 'analysisPage'));
            testCase.verifyTrue(isfield(handles, 'batchPage'));
            testCase.verifyTrue(isfield(handles, 'fdeiPage'));
            testCase.verifyTrue(isfield(handles, 'fdei'));
            topTitles = string(get(handles.mainTabGroup.Children, 'Title'));
            testCase.verifyTrue(any(topTitles == "分析页面"));
            testCase.verifyTrue(any(topTitles == "批量执行页面"));
            testCase.verifyTrue(any(topTitles == "FDEI 分析"));
            subTitles = string(get(handles.fdei.subTabGroup.Children, 'Title'));
            testCase.verifyTrue(any(subTitles == "① 批量仿真"));
            testCase.verifyTrue(any(subTitles == "② 分析绘图"));
        end

        function testFdeiPublicControlsArePresent(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'algorithmTable'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'runButton'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'browseModelButton'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'signalMappingButton'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'exportConfigButton'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'importConfigButton'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'outputDirLabel'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'browseOutputDirButton'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'progressBackground'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'progressFill'));
            testCase.verifyTrue(isfield(handles.fdei.batchUi, 'actionPanel'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'sourceFileList'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'resultTable'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'figure1Button'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'figure2Button'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'sourcePanel'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'parameterPanel'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'resultPanel'));
            testCase.verifyTrue(isfield(handles.fdei.plotUi, 'buttonPanel'));
            testCase.verifyTrue(isfield(handles, 'modelTypePopup'));
        end


        function testImportedConfigurationUpdatesControls(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            cfg = handles.fdei.config;
            cfg.model = 'D:\models\imported_quarter_car.slx';
            cfg.frequencyHz = [1 3 5];
            cfg.amplitudeMode = 'constant_velocity';
            cfg.cMin = 875;
            cfg.forceInputMode = 'total';
            fdei_config_utils('applybatch', handles.fdei.batchUi, cfg);
            fdei_config_utils('applyanalysis', handles.fdei.plotUi, cfg);
            testCase.verifyEqual(get(handles.fdei.batchUi.modelEdit, 'String'), ...
                cfg.model);
            testCase.verifyEqual(get(handles.fdei.batchUi.frequencyEdit, 'String'), ...
                '1, 3, 5');
            testCase.verifyEqual(get(handles.fdei.plotUi.cMinEdit, 'String'), '875');
            testCase.verifyEqual(get(handles.fdei.plotUi.forceModePopup, 'Value'), 1);
        end

        function testProgressBarUpdates(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            fraction = fdei_config_utils('updateprogress', ...
                handles.fdei.batchUi, 2, 4, 'SUCCESS');
            fillPosition = get(handles.fdei.batchUi.progressFill, 'Position');
            progressText = string(get( ...
                handles.fdei.batchUi.progressText, 'String'));
            testCase.verifyEqual(fraction, 0.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(fillPosition(3), 0.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(contains(progressText, "50%"));
        end

        function testOutputDirectoryRowIsAligned(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            labelPosition = get(handles.fdei.batchUi.outputDirLabel, 'Position');
            editPosition = get(handles.fdei.batchUi.outputDirEdit, 'Position');
            labelCenter = labelPosition(2) + labelPosition(4)/2;
            editCenter = editPosition(2) + editPosition(4)/2;
            testCase.verifyEqual(labelCenter, editCenter, ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(get(handles.fdei.batchUi.outputDirEdit, ...
                'Parent'), handles.fdei.batchUi.actionPanel);
        end

        function testBatchPageUsesSeparatedActionPanel(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            algorithmPosition = get(handles.fdei.batchUi.algorithmPanel, ...
                'Position');
            logPosition = get(handles.fdei.batchUi.logPanel, 'Position');
            actionPosition = get(handles.fdei.batchUi.actionPanel, 'Position');
            actionTop = actionPosition(2) + actionPosition(4);
            testCase.verifyGreaterThan(algorithmPosition(2), actionTop);
            testCase.verifyGreaterThan(logPosition(2), actionTop);
            testCase.verifyEqual(algorithmPosition(2), logPosition(2), ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(algorithmPosition(4), logPosition(4), ...
                'AbsTol', 1e-12);
        end

        function testPlotPageUsesWorkflowLayout(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            sourcePosition = get(handles.fdei.plotUi.sourcePanel, 'Position');
            parameterPosition = get(handles.fdei.plotUi.parameterPanel, ...
                'Position');
            resultPosition = get(handles.fdei.plotUi.resultPanel, 'Position');
            buttonPosition = get(handles.fdei.plotUi.buttonPanel, 'Position');
            resultTop = resultPosition(2) + resultPosition(4);
            buttonTop = buttonPosition(2) + buttonPosition(4);
            testCase.verifyEqual(sourcePosition(2), parameterPosition(2), ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(sourcePosition(4), parameterPosition(4), ...
                'AbsTol', 1e-12);
            testCase.verifyLessThan(resultTop, sourcePosition(2));
            testCase.verifyLessThan(buttonTop, resultPosition(2));
            testCase.verifyGreaterThan(parameterPosition(3), sourcePosition(3));
            testCase.verifyEqual(get(handles.fdei.plotUi.frequencyFilterEdit, ...
                'Parent'), handles.fdei.plotUi.sourcePanel);
        end
    end
end
