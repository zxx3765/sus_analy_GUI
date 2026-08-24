function handles = gui_batch_execution(parent, handles)
%% 批量执行页面
% 为 Simulink 变体子系统提供串行批量仿真界面。
% 每个算法使用独立的 Simulink.SimulationInput，并在仿真成功后将
% Simulink.SimulationOutput 写入 base workspace。

if nargin < 2 || ~isstruct(handles) || ~isfield(handles, 'fig')
    error('gui_batch_execution:InvalidHandles', ...
        '批量执行页面需要有效的 GUI handles。');
end

fig = handles.fig;

%% 页面布局
modelPanel = uipanel('Parent', parent, ...
    'Title', '模型与变体设置', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [0.015, 0.825, 0.97, 0.16]);

uicontrol('Parent', modelPanel, 'Style', 'text', ...
    'String', '模型文件', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.015, 0.53, 0.105, 0.27]);
modelEdit = uicontrol('Parent', modelPanel, 'Style', 'edit', ...
    'String', defaultModelFile(), 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'BackgroundColor', 'white', ...
    'Position', [0.12, 0.53, 0.70, 0.30], ...
    'TooltipString', '选择要执行的 .slx 或 .mdl 模型');
modelBrowseButton = uicontrol('Parent', modelPanel, 'Style', 'pushbutton', ...
    'String', '浏览...', 'Units', 'normalized', ...
    'Position', [0.835, 0.53, 0.14, 0.30], ...
    'Callback', @onBrowseModel);

uicontrol('Parent', modelPanel, 'Style', 'text', ...
    'String', '固定变体子系统路径', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.015, 0.10, 0.14, 0.27]);
uicontrol('Parent', modelPanel, 'Style', 'text', ...
    'String', 'Quarter_sys/Control/Y_1', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'ForegroundColor', [0.25, 0.25, 0.25], ...
    'Position', [0.16, 0.10, 0.66, 0.30], ...
    'TooltipString', '批量执行固定使用该 Variant Subsystem 路径');
uicontrol('Parent', modelPanel, 'Style', 'text', ...
    'String', '标签区分大小写，运行时由 Simulink 校验。', ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', ...
    'ForegroundColor', [0.35, 0.35, 0.35], ...
    'Position', [0.835, 0.08, 0.14, 0.34]);

runPanel = uipanel('Parent', parent, ...
    'Title', '批量执行设置', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [0.015, 0.695, 0.97, 0.115]);

uicontrol('Parent', runPanel, 'Style', 'text', ...
    'String', '本次仿真时间 (s)', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.015, 0.48, 0.13, 0.34]);
simTimeEdit = uicontrol('Parent', runPanel, 'Style', 'edit', ...
    'String', '5', 'Units', 'normalized', 'BackgroundColor', 'white', ...
    'HorizontalAlignment', 'left', 'Position', [0.145, 0.47, 0.08, 0.36]);

useModelScenarioCheck = uicontrol('Parent', runPanel, 'Style', 'checkbox', ...
    'String', '使用模型当前工况', 'Value', 1, 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.255, 0.46, 0.15, 0.38], ...
    'Callback', @onScenarioModeChanged, ...
    'TooltipString', '勾选时不向模型写入工况覆盖参数');

uicontrol('Parent', runPanel, 'Style', 'text', ...
    'String', '覆盖工况', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.425, 0.49, 0.08, 0.30]);
scenarioPopup = uicontrol('Parent', runPanel, 'Style', 'popupmenu', ...
    'String', {'正弦路面', '随机路面', '扫频工况'}, 'Value', 1, ...
    'Units', 'normalized', 'Position', [0.505, 0.47, 0.13, 0.36], ...
    'Callback', @onScenarioChanged);

uicontrol('Parent', runPanel, 'Style', 'text', ...
    'String', '随机路面等级', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.655, 0.49, 0.10, 0.30]);
randomGradePopup = uicontrol('Parent', runPanel, 'Style', 'popupmenu', ...
    'String', {'A  (G0 = 0.000016)', 'B  (G0 = 0.000064)', ...
               'C  (G0 = 0.000256)', 'D  (G0 = 0.001024)'}, ...
    'Value', 1, 'Units', 'normalized', 'Position', [0.755, 0.47, 0.14, 0.36]);

runButton = uicontrol('Parent', runPanel, 'Style', 'pushbutton', ...
    'String', '批量执行', 'FontWeight', 'bold', 'Units', 'normalized', ...
    'Position', [0.91, 0.42, 0.075, 0.46], ...
    'Callback', @onRun);

algorithmPanel = uipanel('Parent', parent, ...
    'Title', '需要执行的仿真算法', ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [0.015, 0.245, 0.64, 0.435]);

algorithmTable = uitable('Parent', algorithmPanel, 'Units', 'normalized', ...
    'Position', [0.015, 0.08, 0.68, 0.86], ...
    'ColumnName', {'参与', '显示名称', '模型子系统名称', '保存变量名'}, ...
    'ColumnFormat', {'logical', 'char', 'char', 'char'}, ...
    'ColumnEditable', [true, true, true, false], ...
    'ColumnWidth', {45, 160, 190, 180}, ...
    'RowName', [], 'CellEditCallback', @onTableEdit, ...
    'CellSelectionCallback', @onTableSelection);

addAlgorithmButton = uicontrol('Parent', algorithmPanel, 'Style', 'pushbutton', ...
    'String', '新增算法', 'Units', 'normalized', ...
    'Position', [0.72, 0.75, 0.255, 0.12], ...
    'Callback', @onAddAlgorithm);
editAlgorithmButton = uicontrol('Parent', algorithmPanel, 'Style', 'pushbutton', ...
    'String', '编辑选中算法', 'Units', 'normalized', ...
    'Position', [0.72, 0.54, 0.255, 0.12], ...
    'Callback', @onEditAlgorithm);
exportAlgorithmButton = uicontrol('Parent', algorithmPanel, 'Style', 'pushbutton', ...
    'String', '导出算法清单', 'Units', 'normalized', ...
    'Position', [0.72, 0.32, 0.255, 0.12], ...
    'Callback', @onExportAlgorithms);
importAlgorithmButton = uicontrol('Parent', algorithmPanel, 'Style', 'pushbutton', ...
    'String', '导入算法清单', 'Units', 'normalized', ...
    'Position', [0.72, 0.10, 0.255, 0.12], ...
    'Callback', @onImportAlgorithms);

executionLogPanel = uipanel('Parent', parent, ...
    'Title', '📝 执行日志', 'Units', 'normalized', ...
    'Position', [0.67, 0.245, 0.315, 0.435], ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.98, 0.99, 0.98], ...
    'ForegroundColor', [0.80, 0.40, 0.10]);
uicontrol('Parent', executionLogPanel, 'Style', 'text', ...
    'Units', 'normalized', 'String', '📝 批量执行日志:', ...
    'Position', [0.03, 0.88, 0.55, 0.10], ...
    'HorizontalAlignment', 'left', 'FontSize', 10, ...
    'FontWeight', 'bold', 'BackgroundColor', [0.98, 0.99, 0.98]);
clearExecutionLogButton = uicontrol('Parent', executionLogPanel, ...
    'Style', 'pushbutton', 'String', '清空日志', 'Units', 'normalized', ...
    'Position', [0.70, 0.88, 0.27, 0.09], ...
    'Callback', @onClearExecutionLog);
executionLogText = uicontrol('Parent', executionLogPanel, ...
    'Style', 'edit', 'Tag', 'ConsoleLog', 'Max', 10, ...
    'Units', 'normalized', ...
    'Position', [0.03, 0.05, 0.94, 0.80], 'FontSize', 8, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.05, 0.05, 0.05], ...
    'ForegroundColor', [0.20, 0.80, 0.20], ...
    'FontName', 'Consolas');

progressPanel = uipanel('Parent', parent, ...
    'Title', '执行进度', 'FontSize', 11, 'FontWeight', 'bold', ...
    'Position', [0.015, 0.065, 0.97, 0.15]);
progressBackground = uipanel('Parent', progressPanel, ...
    'BorderType', 'line', 'Units', 'normalized', ...
    'Position', [0.02, 0.47, 0.70, 0.24], ...
    'BackgroundColor', [0.90, 0.90, 0.90]);
progressFill = uipanel('Parent', progressBackground, ...
    'BorderType', 'none', 'Units', 'normalized', ...
    'Position', [0, 0, 0, 1], ...
    'BackgroundColor', [0.20, 0.55, 0.85]);
progressText = uicontrol('Parent', progressPanel, 'Style', 'text', ...
    'String', '未开始', 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'Position', [0.74, 0.43, 0.24, 0.30]);
statusText = uicontrol('Parent', progressPanel, 'Style', 'text', ...
    'String', '提示：变体标签必须与模型中的 LabelModeActiveChoice 完全一致。', ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', ...
    'ForegroundColor', [0.35, 0.35, 0.35], ...
    'Position', [0.02, 0.10, 0.96, 0.22]);

algorithms = defaultAlgorithms();
tableData = algorithmsToTable(algorithms);
set(algorithmTable, 'Data', tableData, 'UserData', tableData);

batch = struct();
batch.schema_version = 2;
batch.algorithms = algorithms;
batch.selectedRow = 1;
batch.isRunning = false;
batch.ui = struct('modelEdit', modelEdit, ...
    'modelBrowseButton', modelBrowseButton, ...
    'simTimeEdit', simTimeEdit, ...
    'useModelScenarioCheck', useModelScenarioCheck, ...
    'scenarioPopup', scenarioPopup, ...
    'randomGradePopup', randomGradePopup, ...
    'runButton', runButton, ...
    'algorithmTable', algorithmTable, ...
    'addAlgorithmButton', addAlgorithmButton, ...
    'editAlgorithmButton', editAlgorithmButton, ...
    'exportAlgorithmButton', exportAlgorithmButton, ...
    'importAlgorithmButton', importAlgorithmButton, ...
    'clearExecutionLogButton', clearExecutionLogButton, ...
    'executionLogText', executionLogText, ...
    'progressFill', progressFill, ...
    'progressText', progressText, ...
    'statusText', statusText);
handles.batch = batch;
set(fig, 'UserData', handles);
updateScenarioControls(fig);
batchLog(fig, '批量执行页面已就绪。');
end

%% 默认算法
function algorithms = defaultAlgorithms()
algorithms = repmat(struct('enabled', true, 'display_name', '', ...
    'subsystem_label', ''), 3, 1);
algorithms(1).display_name = 'Passive';
algorithms(1).subsystem_label = 'Passive';
algorithms(2).display_name = 'lqr';
algorithms(2).subsystem_label = 'lqr';
algorithms(3).display_name = 'IF_IMP_Latest_simple';
algorithms(3).subsystem_label = 'IF_IMP_Latest_simple';
end

%% 默认模型路径（仅在实际存在时填写）
function modelFile = defaultModelFile()
modelFile = '';
thisFile = mfilename('fullpath');
projectRoot = fileparts(fileparts(fileparts(thisFile)));
candidate = fullfile(fileparts(projectRoot), 'Imp_fcn_cal', 'Imp_sim.slx');
if exist(candidate, 'file') == 2
    modelFile = candidate;
end
end

%% 控件回调
function onBrowseModel(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
startDir = pwd;
if isfield(handles, 'batch') && isfield(handles.batch, 'ui') && ...
        ishandle(handles.batch.ui.modelEdit)
    currentFile = strtrim(get(handles.batch.ui.modelEdit, 'String'));
    [currentOK, ~, currentFile] = batch_model_file_utils(currentFile, pwd);
    if currentOK
        startDir = fileparts(currentFile);
    end
end
[fileName, filePath] = uigetfile( ...
    {'*.slx;*.mdl', 'Simulink 模型 (*.slx, *.mdl)'}, ...
    '选择 Simulink 模型', startDir);
if isequal(fileName, 0)
    return;
end
handles = latestHandles(fig);
[ok, ~, selectedFile, message] = batch_model_file_utils( ...
    fullfile(filePath, fileName), filePath);
if ~ok
    errordlg(message, '模型文件无效', 'modal');
    return;
end
set(handles.batch.ui.modelEdit, 'String', selectedFile);
set(handles.batch.ui.statusText, 'String', ...
    ['已选择模型：' selectedFile]);
set(fig, 'UserData', handles);
batchLog(fig, ['已选择模型：' selectedFile]);
end

function onScenarioModeChanged(src, ~)
fig = ancestor(src, 'figure');
updateScenarioControls(fig);
end

function onScenarioChanged(src, ~)
fig = ancestor(src, 'figure');
updateScenarioControls(fig);
end

function onClearExecutionLog(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
set(handles.batch.ui.executionLogText, 'String', '', 'Value', 1);
set(handles.batch.ui.statusText, 'String', '执行日志已清空。');
end

function onTableSelection(src, event)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
indices = [];
try
    indices = event.Indices;
catch
    % 兼容旧版 uitable 的结构体事件和新版事件对象。
end
if ~isempty(indices)
    handles.batch.selectedRow = indices(1, 1);
    set(fig, 'UserData', handles);
end
end

function onTableEdit(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
tableData = get(handles.batch.ui.algorithmTable, 'Data');
[ok, message, algorithms] = validateAlgorithmList( ...
    tableToAlgorithms(tableData), false);
if ~ok
    previousData = get(handles.batch.ui.algorithmTable, 'UserData');
    if ~isempty(previousData)
        set(handles.batch.ui.algorithmTable, 'Data', previousData);
    end
    set(handles.batch.ui.statusText, 'String', ...
        ['算法修改未保存：' message]);
    return;
end
tableData = algorithmsToTable(algorithms);
set(handles.batch.ui.algorithmTable, 'Data', tableData, ...
    'UserData', tableData);
handles.batch.algorithms = algorithms;
set(fig, 'UserData', handles);
end

function onAddAlgorithm(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
[algorithm, accepted] = algorithmDialog([]);
if ~accepted
    return;
end
algorithms = tableToAlgorithms(get(handles.batch.ui.algorithmTable, 'Data'));
algorithms(end + 1) = algorithm; %#ok<AGROW>
[ok, message, algorithms] = validateAlgorithmList(algorithms, false);
if ~ok
    errordlg(message, '新增算法失败', 'modal');
    return;
end
setAlgorithmList(fig, algorithms);
handles = latestHandles(fig);
handles.batch.selectedRow = numel(algorithms);
set(fig, 'UserData', handles);
end

function onEditAlgorithm(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
algorithms = tableToAlgorithms(get(handles.batch.ui.algorithmTable, 'Data'));
row = handles.batch.selectedRow;
if isempty(row) || row < 1 || row > numel(algorithms)
    errordlg('请先在算法表格中选择一行。', '编辑算法', 'modal');
    return;
end
[algorithm, accepted] = algorithmDialog(algorithms(row));
if ~accepted
    return;
end
algorithms(row) = algorithm;
[ok, message, algorithms] = validateAlgorithmList(algorithms, false);
if ~ok
    errordlg(message, '编辑算法失败', 'modal');
    return;
end
setAlgorithmList(fig, algorithms);
end

function onExportAlgorithms(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
algorithms = tableToAlgorithms(get(handles.batch.ui.algorithmTable, 'Data'));
[ok, message, algorithms] = validateAlgorithmList(algorithms, false);
if ~ok
    errordlg(message, '导出算法清单失败', 'modal');
    return;
end
modelText = get(handles.batch.ui.modelEdit, 'String');
[ok, ~, modelFile, message] = batch_model_file_utils(modelText, pwd);
if ~ok
    errordlg(message, '导出算法清单失败', 'modal');
    return;
end
set(handles.batch.ui.modelEdit, 'String', modelFile);
[fileName, filePath] = uiputfile('*.mat', '导出算法清单', ...
    'batch_algorithm_config.mat');
if isequal(fileName, 0)
    return;
end
batch_algorithm_config = struct('schema_version', 2, ...
    'model_file', modelFile, 'algorithms', algorithms); %#ok<NASGU>
try
    save(fullfile(filePath, fileName), 'batch_algorithm_config', '-mat');
    set(handles.batch.ui.statusText, 'String', ...
        ['算法清单已导出：' fullfile(filePath, fileName)]);
    batchLog(fig, ['算法清单已导出：' fullfile(filePath, fileName)]);
catch ME
    errordlg(['导出算法清单失败：' ME.message], '导出失败', 'modal');
end
end

function onImportAlgorithms(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
[fileName, filePath] = uigetfile('*.mat', '导入算法清单');
if isequal(fileName, 0)
    return;
end
try
    loaded = load(fullfile(filePath, fileName), 'batch_algorithm_config');
    if ~isfield(loaded, 'batch_algorithm_config')
        error('文件中没有 batch_algorithm_config 变量。');
    end
    config = loaded.batch_algorithm_config;
    [ok, message, incoming, configState] = batch_algorithm_config_utils( ...
        'validateconfig', config);
    if ~ok
        error('%s', message);
    end
catch ME
    errordlg(['导入算法清单失败：' ME.message], '导入失败', 'modal');
    return;
end

choice = questdlg('如何处理当前算法列表？', '导入算法清单', ...
    '替换当前列表', '追加到当前列表', '取消', '取消');
if strcmp(choice, '取消') || isempty(choice)
    return;
end
current = tableToAlgorithms(get(handles.batch.ui.algorithmTable, 'Data'));
modelStatus = '';
if strcmp(choice, '替换当前列表')
    result = incoming;
    skipped = struct('display_name', {}, 'output_name', {});
    if ~isempty(configState.model_file)
        [modelOK, ~, importedModelFile, modelMessage] = ...
            batch_model_file_utils(configState.model_file, filePath);
        if modelOK
            set(handles.batch.ui.modelEdit, 'String', importedModelFile);
            modelStatus = ['已恢复模型：' importedModelFile];
        else
            modelStatus = ['清单中的模型当前不可用，已保留现有模型。' ...
                strrep(modelMessage, newline, ' ')];
        end
    else
        modelStatus = '旧版清单不包含模型路径，已保留现有模型。';
    end
else
    [ok, message, result, skipped] = batch_algorithm_config_utils( ...
        'mergeappend', current, incoming);
    if ~ok
        errordlg(['追加算法清单失败：' message], '导入失败', 'modal');
        return;
    end
    if ~isempty(configState.model_file)
        modelStatus = '追加模式保留当前模型，未切换到清单关联模型。';
    end
end
if strcmp(choice, '替换当前列表') || ~isempty(skipped) || ...
        numel(result) ~= numel(current)
    setAlgorithmList(fig, result);
end
handles = latestHandles(fig);
if strcmp(choice, '追加到当前列表') && ~isempty(skipped)
    skippedText = formatSkippedAlgorithms(skipped);
    if numel(result) == numel(current)
        statusMessage = ['追加清单中的算法全部跳过：' skippedText];
    else
        statusMessage = ['算法清单已追加；跳过重复保存变量：' skippedText];
    end
else
    statusMessage = ['算法清单已导入（' choice '）。'];
end
if ~isempty(modelStatus)
    statusMessage = [statusMessage ' ' modelStatus];
end
set(handles.batch.ui.statusText, 'String', statusMessage);
batchLog(fig, [statusMessage ' 文件：' fullfile(filePath, fileName)]);
end

function message = formatSkippedAlgorithms(skipped)
items = cell(numel(skipped), 1);
for i = 1:numel(skipped)
    items{i} = sprintf('%s (%s)', skipped(i).display_name, ...
        skipped(i).output_name);
end
message = strjoin(items, '，');
end

function onRun(src, ~)
fig = ancestor(src, 'figure');
handles = latestHandles(fig);
ui = handles.batch.ui;

algorithms = tableToAlgorithms(get(ui.algorithmTable, 'Data'));
[ok, message, algorithms] = validateAlgorithmList(algorithms, true);
if ~ok
    batchLog(fig, ['执行前检查失败：' message]);
    errordlg(message, '批量执行检查失败', 'modal');
    return;
end

modelFile = get(ui.modelEdit, 'String');
[ok, modelName, modelFile, message] = batch_model_file_utils(modelFile, pwd);
if ~ok
    batchLog(fig, ['执行前检查失败：' message]);
    errordlg(message, '批量执行检查失败', 'modal');
    return;
end
set(ui.modelEdit, 'String', modelFile);

simTime = str2double(strtrim(get(ui.simTimeEdit, 'String')));
if ~isscalar(simTime) || ~isfinite(simTime) || simTime <= 0
    message = '本次仿真时间必须是大于 0 的有限数值。';
    batchLog(fig, ['执行前检查失败：' message]);
    errordlg(message, ...
        '批量执行检查失败', 'modal');
    return;
end

variantPath = 'Quarter_sys/Control/Y_1';

enabledAlgorithms = algorithms([algorithms.enabled]);
outputNames = cell(numel(enabledAlgorithms), 1);
for i = 1:numel(enabledAlgorithms)
    outputNames{i} = outputVariableName(enabledAlgorithms(i).display_name);
end
existingNames = evalin('base', 'who');
collisions = outputNames(ismember(outputNames, existingNames));
if ~isempty(collisions)
    prompt = sprintf('以下变量已存在：%s\n是否覆盖？', strjoin(collisions, ', '));
    choice = questdlg(prompt, 'base 工作区变量冲突', '覆盖', ...
        '取消', '取消');
    if ~strcmp(choice, '覆盖')
        batchLog(fig, '用户取消覆盖 base 工作区同名变量，本次执行未开始。');
        return;
    end
end

if exist('Simulink.SimulationInput', 'class') ~= 8
    message = ['当前 MATLAB 未检测到 Simulink.SimulationInput。' ...
        '请确认已安装 Simulink。'];
    batchLog(fig, ['执行前检查失败：' message]);
    errordlg(message, '批量执行检查失败', 'modal');
    return;
end

useModelScenario = logical(get(ui.useModelScenarioCheck, 'Value'));
scenarioValue = get(ui.scenarioPopup, 'Value');
gradeValue = get(ui.randomGradePopup, 'Value');
scenario = scenarioSettings(scenarioValue, gradeValue);

[ok, message] = checkLoadedModelPath(modelName, modelFile);
if ~ok
    batchLog(fig, ['执行前检查失败：' message]);
    errordlg(message, '批量执行检查失败', 'modal');
    return;
end

setRunningState(fig, true);
cleanupUI = onCleanup(@() restoreRunningState(fig)); %#ok<NASGU>
setProgress(fig, 0, sprintf('准备执行 %d 个算法...', ...
    numel(enabledAlgorithms)));
batchLog(fig, sprintf('开始批量仿真：模型=%s，算法数=%d，StopTime=%g s。', ...
    modelFile, numel(enabledAlgorithms), simTime));

modelDirectory = fileparts(modelFile);
addedModelDirectory = false;
if ~isempty(modelDirectory) && ...
        ~pathContainsDirectory(path, modelDirectory)
    addpath(modelDirectory);
    addedModelDirectory = true;
end
cleanupPath = onCleanup(@() cleanupTemporaryModelPath( ...
    modelDirectory, addedModelDirectory)); %#ok<NASGU>

successCount = 0;
failureCount = 0;
for i = 1:numel(enabledAlgorithms)
    if ~ishandle(fig)
        break;
    end
    algorithm = enabledAlgorithms(i);
    setProgress(fig, (i - 1) / numel(enabledAlgorithms), ...
        sprintf('正在执行 %d/%d：%s', i, numel(enabledAlgorithms), ...
        algorithm.display_name));
    try
        in = createSimulationInput(modelName, variantPath, algorithm, simTime, ...
            useModelScenario, scenario);
        out = sim(in);
        assignin('base', outputNames{i}, out);
        successCount = successCount + 1;
        batchLog(fig, sprintf('算法“%s”完成，结果已保存为 base.%s。', ...
            algorithm.display_name, outputNames{i}));
    catch ME
        failureCount = failureCount + 1;
        batchLog(fig, sprintf('算法“%s”失败：%s', ...
            algorithm.display_name, ME.message));
        if ~isempty(ME.stack)
            batchLog(fig, sprintf('失败位置：%s 第 %d 行。', ...
                ME.stack(1).name, ME.stack(1).line));
        end
    end
    setProgress(fig, i / numel(enabledAlgorithms), ...
        sprintf('已完成 %d/%d（成功 %d，失败 %d）', i, ...
        numel(enabledAlgorithms), successCount, failureCount));
end

if ishandle(fig)
    if failureCount == 0
        message = sprintf('批量仿真完成：%d 个算法全部成功。', successCount);
    else
        message = sprintf('批量仿真完成：成功 %d，失败 %d；失败项已记录到日志。', ...
            successCount, failureCount);
    end
    setProgress(fig, 1, message);
    batchLog(fig, message);
end
end

%% 仿真输入构造
function in = createSimulationInput(modelName, variantPath, algorithm, ...
        simTime, useModelScenario, scenario)
in = Simulink.SimulationInput(modelName);
in = in.setModelParameter('StopTime', num2str(simTime, '%.15g'));
fullVariantPath = fullBlockPath(modelName, variantPath);
in = in.setBlockParameter(fullVariantPath, ...
    'LabelModeActiveChoice', algorithm.subsystem_label);

if ~useModelScenario
    roadPath = [modelName '/road_profile/origin/road_select'];
    in = in.setBlockParameter(roadPath, ...
        'Value', num2str(scenario.road_select));
    if scenario.road_select == 3
        in = in.setVariable('G0', scenario.G0, 'Workspace', modelName);
    end
end
end

function pathName = fullBlockPath(modelName, relativePath)
relativePath = strtrim(relativePath);
prefix = [modelName '/'];
if strncmp(relativePath, prefix, length(prefix))
    pathName = relativePath;
else
    pathName = [prefix relativePath];
end
end

function scenario = scenarioSettings(scenarioValue, gradeValue)
scenario = struct('road_select', 1, 'G0', 0.000016, ...
    'name', '正弦路面');
if scenarioValue == 2
    scenario.road_select = 3;
    scenario.name = '随机路面';
    gradeValues = [0.000016, 0.000064, 0.000256, 0.001024];
    gradeValue = max(1, min(numel(gradeValues), gradeValue));
    scenario.G0 = gradeValues(gradeValue);
elseif scenarioValue == 3
    scenario.road_select = 6;
    scenario.name = '扫频工况';
end
end

%% 校验和表格转换
function [ok, message, algorithms] = validateAlgorithmList(algorithms, ...
        requireEnabled)
[ok, message, algorithms] = batch_algorithm_config_utils( ...
    'validate', algorithms, false, requireEnabled);
end

function data = algorithmsToTable(algorithms)
if isempty(algorithms)
    data = cell(0, 4);
    return;
end
data = cell(numel(algorithms), 4);
for i = 1:numel(algorithms)
    data{i, 1} = logical(algorithms(i).enabled);
    data{i, 2} = algorithms(i).display_name;
    data{i, 3} = algorithms(i).subsystem_label;
    data{i, 4} = outputVariableName(algorithms(i).display_name);
end
end

function algorithms = tableToAlgorithms(data)
if isempty(data)
    algorithms = struct('enabled', {}, 'display_name', {}, ...
        'subsystem_label', {});
    return;
end
algorithms = repmat(struct('enabled', true, 'display_name', '', ...
    'subsystem_label', ''), size(data, 1), 1);
for i = 1:size(data, 1)
    algorithms(i).enabled = logical(data{i, 1});
    algorithms(i).display_name = toChar(data{i, 2});
    algorithms(i).subsystem_label = toChar(data{i, 3});
end
end

function setAlgorithmList(fig, algorithms)
handles = latestHandles(fig);
[ok, message, algorithms] = validateAlgorithmList(algorithms, false);
if ~ok
    error('gui_batch_execution:InvalidAlgorithmList', '%s', message);
end
tableData = algorithmsToTable(algorithms);
set(handles.batch.ui.algorithmTable, 'Data', tableData, ...
    'UserData', tableData);
handles.batch.algorithms = algorithms;
handles.batch.selectedRow = min(max(1, handles.batch.selectedRow), ...
    max(1, numel(algorithms)));
set(fig, 'UserData', handles);
end

function outputName = outputVariableName(displayName)
[outputName] = batch_algorithm_config_utils('outputname', displayName);
end

function value = toChar(value)
if ischar(value)
    return;
end
if isstring(value)
    value = char(value);
elseif isnumeric(value) || islogical(value)
    value = num2str(value);
else
    value = '';
end
end

%% 模型与路径校验
function [ok, message] = checkLoadedModelPath(modelName, modelFile)
ok = true;
message = '';
if exist('bdIsLoaded', 'file') ~= 2
    return;
end
try
    if bdIsLoaded(modelName)
        loadedFile = get_param(modelName, 'FileName');
        if ~isempty(loadedFile) && ~sameFile(loadedFile, modelFile)
            ok = false;
            message = sprintf(['模型“%s”已从另一条路径加载：%s。' ...
                '请先处理同名模型冲突。'], modelName, loadedFile);
        end
    end
catch ME
    ok = false;
    message = ['无法检查已加载模型路径：' ME.message];
end
end

function result = sameFile(first, second)
result = false;
try
    [ok1, attr1] = fileattrib(first);
    [ok2, attr2] = fileattrib(second);
    if ok1 && ok2
        result = strcmpi(attr1.Name, attr2.Name);
    else
        result = strcmpi(first, second);
    end
catch
    result = strcmpi(first, second);
end
end

function result = pathContainsDirectory(pathValue, directory)
parts = strsplit(pathValue, pathsep);
result = any(strcmpi(parts, directory));
end

function cleanupTemporaryModelPath(modelDirectory, addedModelDirectory)
if addedModelDirectory && ~isempty(modelDirectory)
    try
        rmpath(modelDirectory);
    catch
        % 路径可能已由用户在仿真期间移除；清理应保持幂等。
    end
end
end

%% 页面状态和日志
function updateScenarioControls(fig)
if ~ishandle(fig)
    return;
end
handles = latestHandles(fig);
ui = handles.batch.ui;
useModel = logical(get(ui.useModelScenarioCheck, 'Value'));
if useModel
    set(ui.scenarioPopup, 'Enable', 'off');
    set(ui.randomGradePopup, 'Enable', 'off');
else
    set(ui.scenarioPopup, 'Enable', 'on');
    if get(ui.scenarioPopup, 'Value') == 2
        set(ui.randomGradePopup, 'Enable', 'on');
    else
        set(ui.randomGradePopup, 'Enable', 'off');
    end
end
if handles.batch.isRunning
    set(ui.scenarioPopup, 'Enable', 'off');
    set(ui.randomGradePopup, 'Enable', 'off');
end
end

function setRunningState(fig, isRunning)
if ~ishandle(fig)
    return;
end
handles = latestHandles(fig);
handles.batch.isRunning = logical(isRunning);
ui = handles.batch.ui;
if isRunning
    state = 'off';
else
    state = 'on';
end
fields = fieldnames(ui);
for i = 1:numel(fields)
    control = ui.(fields{i});
    if ishandle(control) && ~strcmp(fields{i}, 'progressFill') && ...
            ~strcmp(fields{i}, 'progressText') && ...
            ~strcmp(fields{i}, 'statusText') && ...
            ~strcmp(fields{i}, 'executionLogText')
        try
            set(control, 'Enable', state);
        catch
        end
    end
end
set(fig, 'UserData', handles);
if ~isRunning
    updateScenarioControls(fig);
end
end

function restoreRunningState(fig)
if ishandle(fig)
    setRunningState(fig, false);
end
end

function setProgress(fig, fraction, message)
if ~ishandle(fig)
    return;
end
handles = latestHandles(fig);
fraction = max(0, min(1, fraction));
if ishandle(handles.batch.ui.progressFill)
    set(handles.batch.ui.progressFill, 'Position', [0, 0, fraction, 1]);
end
if ishandle(handles.batch.ui.progressText)
    set(handles.batch.ui.progressText, 'String', ...
        sprintf('%3.0f%%', 100 * fraction));
end
if ishandle(handles.batch.ui.statusText)
    set(handles.batch.ui.statusText, 'String', message);
end
drawnow;
end

function batchLog(fig, message)
if ~ishandle(fig)
    fprintf('[批量仿真] %s\n', message);
    return;
end
handles = latestHandles(fig);
try
    if exist('gui_utils', 'file') == 2
        batchHandles = struct('logText', ...
            handles.batch.ui.executionLogText);
        gui_utils('addLog', batchHandles, message);
    else
        fprintf('[批量仿真] %s\n', message);
    end
catch
    fprintf('[批量仿真] %s\n', message);
end
end

function handles = latestHandles(fig)
if ishandle(fig)
    value = get(fig, 'UserData');
    if isstruct(value) && isfield(value, 'fig')
        handles = value;
        return;
    end
end
error('gui_batch_execution:InvalidFigureState', 'GUI 状态不可用。');
end

%% 新增/编辑算法对话框
function [algorithm, accepted] = algorithmDialog(existing)
accepted = false;
algorithm = struct('enabled', true, 'display_name', '', ...
    'subsystem_label', '');
theme = gui_theme();
isNewAlgorithm = nargin < 1 || isempty(existing);
if isNewAlgorithm
    existing = algorithm;
else
    algorithm = existing;
end
if isNewAlgorithm
    dialogTitle = '新增仿真算法';
else
    dialogTitle = '编辑仿真算法';
end

dialog = figure('Name', dialogTitle, 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off', ...
    'WindowStyle', 'modal', 'Position', [500, 400, 520, 265], ...
    'Color', theme.canvas, ...
    'CloseRequestFcn', @onCancel);
header = uipanel('Parent', dialog, 'BorderType', 'none', ...
    'Units', 'pixels', 'Position', [0, 205, 520, 60], ...
    'BackgroundColor', theme.primary);
uicontrol('Parent', header, 'Style', 'text', ...
    'String', '配置仿真算法', 'HorizontalAlignment', 'left', ...
    'Position', [24, 28, 470, 25], 'FontSize', 12, ...
    'FontWeight', 'bold', 'ForegroundColor', theme.onPrimary, ...
    'BackgroundColor', theme.primary);
uicontrol('Parent', header, 'Style', 'text', ...
    'String', '显示名称用于保存结果，子系统名称用于匹配 Variant 标签。', ...
    'HorizontalAlignment', 'left', 'Position', [24, 7, 470, 20], ...
    'FontSize', 8, 'ForegroundColor', theme.primarySoftText, ...
    'BackgroundColor', theme.primary);
uicontrol('Parent', dialog, 'Style', 'text', 'String', '显示名称', ...
    'HorizontalAlignment', 'left', 'Position', [25, 158, 120, 25]);
displayEdit = uicontrol('Parent', dialog, 'Style', 'edit', ...
    'String', existing.display_name, 'BackgroundColor', 'white', ...
    'Position', [150, 158, 340, 30]);
uicontrol('Parent', dialog, 'Style', 'text', ...
    'String', '模型子系统名称', 'HorizontalAlignment', 'left', ...
    'Position', [25, 112, 120, 25]);
subsystemEdit = uicontrol('Parent', dialog, 'Style', 'edit', ...
    'String', existing.subsystem_label, 'BackgroundColor', 'white', ...
    'Position', [150, 112, 340, 30]);
copyButton = uicontrol('Parent', dialog, 'Style', 'pushbutton', ...
    'String', '复制显示名称到子系统名称', 'Position', [150, 72, 190, 28], ...
    'Callback', @onCopyDisplayName);
uicontrol('Parent', dialog, 'Style', 'pushbutton', 'String', '确定', ...
    'Position', [325, 22, 78, 32], 'Callback', @onOK);
uicontrol('Parent', dialog, 'Style', 'pushbutton', 'String', '取消', ...
    'Position', [412, 22, 78, 32], 'Callback', @onCancel);
set(copyButton, 'TooltipString', '将显示名称原样复制到模型子系统名称');
gui_apply_theme(dialog);
movegui(dialog, 'center');

uiwait(dialog);
if ishandle(dialog)
    delete(dialog);
end

    function onCopyDisplayName(~, ~)
        set(subsystemEdit, 'String', get(displayEdit, 'String'));
    end

    function onOK(~, ~)
        displayName = strtrim(get(displayEdit, 'String'));
        subsystemName = get(subsystemEdit, 'String');
        if isempty(displayName)
            errordlg('显示名称不能为空。', '输入检查', 'modal');
            return;
        end
        if isempty(strtrim(subsystemName))
            errordlg('模型子系统名称不能为空。', '输入检查', 'modal');
            return;
        end
        % 编辑已有算法时保留原有的参与勾选状态；新增算法默认参与。
        algorithm.enabled = logical(existing.enabled);
        algorithm.display_name = displayName;
        algorithm.subsystem_label = subsystemName;
        accepted = true;
        uiresume(dialog);
    end

    function onCancel(~, ~)
        accepted = false;
        if ishandle(dialog)
            uiresume(dialog);
        end
    end
end
