classdef gui_batch_executionTest < matlab.unittest.TestCase
    %GUI_BATCH_EXECUTIONTEST 批量执行页面的持久 MATLAB GUI 测试。

    properties
        FigureHandle
        PreviousDefaultFigureVisible
    end

    methods (TestMethodSetup)
        function createGui(testCase)
            testCase.PreviousDefaultFigureVisible = ...
                get(0, 'DefaultFigureVisible');
            set(0, 'DefaultFigureVisible', 'off');
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            addpath(genpath(fullfile(projectRoot, 'src')));
            main_gui;
            figures = findall(0, 'Type', 'figure', ...
                'Name', '悬架分析工具 - Suspension Analysis GUI');
            testCase.verifyNotEmpty(figures);
            testCase.FigureHandle = figures(1);
            set(testCase.FigureHandle, 'Visible', 'off');
        end
    end

    methods (TestMethodTeardown)
        function closeGui(testCase)
            if ~isempty(testCase.FigureHandle) && ...
                    ishandle(testCase.FigureHandle)
                delete(testCase.FigureHandle);
            end
            set(0, 'DefaultFigureVisible', ...
                testCase.PreviousDefaultFigureVisible);
        end
    end

    methods (Test)
        function testTopLevelPagesAndAnalysisControls(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            testCase.verifyTrue(isfield(handles, 'analysisPage'));
            testCase.verifyTrue(isfield(handles, 'batchPage'));
            testCase.verifyTrue(isfield(handles, 'batch'));
            testCase.verifyEqual(handles.batch.schema_version, 2);
            pageTitles = get(handles.mainTabGroup, 'Children');
            pageTitles = get(pageTitles, 'Title');
            if ischar(pageTitles)
                pageTitles = {pageTitles};
            end
            testCase.verifyTrue(any(strcmp(pageTitles, '分析页面')));
            testCase.verifyTrue(any(strcmp(pageTitles, '批量执行页面')));
            testCase.verifyNotEmpty(findall(handles.analysisPage, ...
                'Type', 'uicontrol'));
            testCase.verifyTrue(isfield(handles, 'modelTypePopup'));
        end

        function testDefaultAlgorithmsAndOutputNames(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            data = get(handles.batch.ui.algorithmTable, 'Data');
            testCase.verifySize(data, [3, 4]);
            testCase.verifyEqual([data{:, 1}], [true, true, true]);
            testCase.verifyEqual(data(:, 2), ...
                {'Passive'; 'lqr'; 'IF_IMP_Latest_simple'});
            testCase.verifyEqual(data(:, 3), data(:, 2));
            testCase.verifyEqual(data(:, 4), ...
                {'out_Passive'; 'out_lqr'; 'out_IF_IMP_Latest_simple'});
        end

        function testModelScenarioDisablesOverrides(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            testCase.verifyEqual( ...
                get(handles.batch.ui.useModelScenarioCheck, 'Value'), 1);
            testCase.verifyEqual( ...
                get(handles.batch.ui.scenarioPopup, 'Enable'), 'off');
            testCase.verifyEqual( ...
                get(handles.batch.ui.randomGradePopup, 'Enable'), 'off');
        end

        function testBatchExecutionLogMatchesAnalysisLogAndClears(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            batchLogText = handles.batch.ui.executionLogText;
            analysisLogText = handles.logText;

            testCase.verifyEqual(get(batchLogText, 'Style'), ...
                get(analysisLogText, 'Style'));
            testCase.verifyEqual(get(batchLogText, 'Max'), ...
                get(analysisLogText, 'Max'));
            testCase.verifyEqual(get(batchLogText, 'BackgroundColor'), ...
                get(analysisLogText, 'BackgroundColor'));
            testCase.verifyEqual(get(batchLogText, 'ForegroundColor'), ...
                get(analysisLogText, 'ForegroundColor'));
            testCase.verifyEqual(get(batchLogText, 'FontName'), ...
                get(analysisLogText, 'FontName'));

            logLines = cellstr(get(batchLogText, 'String'));
            testCase.verifyTrue(any(contains(logLines, '批量执行页面已就绪')));
            panel = findall(handles.batchPage, 'Type', 'uipanel', ...
                'Title', '📝 执行日志');
            testCase.verifyNumElements(panel, 1);

            set(batchLogText, 'String', {'第一行'; '第二行'});
            clearButton = handles.batch.ui.clearExecutionLogButton;
            invokeCallback(clearButton, get(clearButton, 'Callback'));
            testCase.verifyEmpty(get(batchLogText, 'String'));
        end

        function testScenarioOverrideLinkage(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            useModel = handles.batch.ui.useModelScenarioCheck;
            scenario = handles.batch.ui.scenarioPopup;
            grade = handles.batch.ui.randomGradePopup;

            set(useModel, 'Value', 0);
            invokeCallback(useModel, get(useModel, 'Callback'));
            testCase.verifyEqual(get(scenario, 'Enable'), 'on');
            testCase.verifyEqual(get(grade, 'Enable'), 'off');

            set(scenario, 'Value', 2);
            invokeCallback(scenario, get(scenario, 'Callback'));
            testCase.verifyEqual(get(grade, 'Enable'), 'on');

            set(scenario, 'Value', 1);
            invokeCallback(scenario, get(scenario, 'Callback'));
            testCase.verifyEqual(get(grade, 'Enable'), 'off');

            set(useModel, 'Value', 1);
            invokeCallback(useModel, get(useModel, 'Callback'));
            testCase.verifyEqual(get(scenario, 'Enable'), 'off');
            testCase.verifyEqual(get(grade, 'Enable'), 'off');
        end

        function testInvalidAndDuplicateTableEditsRollback(testCase)
            handles = get(testCase.FigureHandle, 'UserData');
            tableHandle = handles.batch.ui.algorithmTable;
            original = get(tableHandle, 'Data');
            callback = get(tableHandle, 'CellEditCallback');

            invalid = original;
            invalid{1, 2} = '';
            set(tableHandle, 'Data', invalid);
            invokeCallback(tableHandle, callback);
            testCase.verifyEqual(get(tableHandle, 'Data'), original);

            duplicate = original;
            duplicate{2, 2} = duplicate{1, 2};
            set(tableHandle, 'Data', duplicate);
            invokeCallback(tableHandle, callback);
            testCase.verifyEqual(get(tableHandle, 'Data'), original);
        end
    end
end

function invokeCallback(source, callback)
if iscell(callback)
    feval(callback{1}, source, []);
else
    feval(callback, source, []);
end
end
