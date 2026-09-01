function varargout = fdei_config_utils(action, varargin)
%FDEI_CONFIG_UTILS Convert FDEI page controls to validated configurations.
%   This utility keeps parsing and validation out of GUI callbacks.

switch lower(char(string(action)))
    case 'default'
        varargout{1} = fdei_default_config();
    case 'frequencytext'
        varargout{1} = parseNumbers(varargin{1}, '频率');
    case 'parsemanualcases'
        varargout{1} = parseManualCases(varargin{1});
    case 'readbatch'
        varargout{1} = readBatch(varargin{1}, varargin{2}, true);
    case 'readbatchdraft'
        varargout{1} = readBatch(varargin{1}, varargin{2}, false);
    case 'readanalysis'
        varargout{1} = readAnalysis(varargin{1}, varargin{2});
    case 'applybatch'
        applyBatch(varargin{1}, varargin{2});
    case 'applyanalysis'
        applyAnalysis(varargin{1}, varargin{2});
    case 'updateprogress'
        varargout{1} = updateProgress(varargin{1}, varargin{2}, ...
            varargin{3}, varargin{4});
    case 'validateanalysis'
        varargout{1} = validateAnalysis(varargin{1});
    otherwise
        error('fdei_config_utils:InvalidAction', '未知配置操作：%s。', action);
end
end

function cfg = readBatch(ui, baseCfg, validateConfig)
cfg = baseCfg;
cfg.model = strtrim(getString(ui.modelEdit));
cfg.variantSubsystemPath = strtrim(getString(ui.variantPathEdit));
cfg.roadSelectPath = strtrim(getString(ui.roadPathEdit));
cfg.roadSelectValue = strtrim(getString(ui.roadValueEdit));
cfg.frequencyHz = parseNumbers(getString(ui.frequencyEdit), '频率');
modeItems = get(ui.amplitudeModePopup, 'String');
cfg.amplitudeMode = char(string(modeItems{get(ui.amplitudeModePopup, 'Value')}));
cfg.legacyAmplitudeScale = parseScalar(getString(ui.amplitudeScaleEdit), ...
    'legacyAmplitudeScale');
cfg.constantRoadVelocityPeak_mps = parseScalar( ...
    getString(ui.velocityAmplitudeEdit), 'constantRoadVelocityPeak_mps');
cfg.constantRoadDisplacement_m = parseScalar( ...
    getString(ui.displacementAmplitudeEdit), 'constantRoadDisplacement_m');
cfg.minimumSettlingTime_s = parseScalar(getString(ui.settlingTimeEdit), ...
    'minimumSettlingTime_s');
cfg.savedCycles = parseScalar(getString(ui.savedCyclesEdit), 'savedCycles');
cfg.samplesPerCycle = parseScalar(getString(ui.samplesPerCycleEdit), ...
    'samplesPerCycle');
cfg.outputDir = strtrim(getString(ui.outputDirEdit));
cfg.saveCheckpoint = logical(get(ui.checkpointCheck, 'Value'));
cfg.stopOnError = logical(get(ui.stopOnErrorCheck, 'Value'));
tableData = get(ui.algorithmTable, 'Data');
cfg.controllerCases = tableToCases(tableData);
if validateConfig
    cfg = fdei_validate_batch_config(cfg, false);
end
end

function applyBatch(ui, cfg)
set(ui.modelEdit, 'String', cfg.model);
set(ui.variantPathEdit, 'String', cfg.variantSubsystemPath);
set(ui.roadPathEdit, 'String', cfg.roadSelectPath);
set(ui.roadValueEdit, 'String', cfg.roadSelectValue);
set(ui.frequencyEdit, 'String', joinNumbers(cfg.frequencyHz));
setPopupText(ui.amplitudeModePopup, cfg.amplitudeMode);
set(ui.amplitudeScaleEdit, 'String', numberText(cfg.legacyAmplitudeScale));
set(ui.velocityAmplitudeEdit, 'String', ...
    numberText(cfg.constantRoadVelocityPeak_mps));
set(ui.displacementAmplitudeEdit, 'String', ...
    numberText(cfg.constantRoadDisplacement_m));
set(ui.settlingTimeEdit, 'String', numberText(cfg.minimumSettlingTime_s));
set(ui.savedCyclesEdit, 'String', numberText(cfg.savedCycles));
set(ui.samplesPerCycleEdit, 'String', numberText(cfg.samplesPerCycle));
set(ui.outputDirEdit, 'String', cfg.outputDir);
set(ui.checkpointCheck, 'Value', logical(cfg.saveCheckpoint));
set(ui.stopOnErrorCheck, 'Value', logical(cfg.stopOnError));
set(ui.algorithmTable, 'Data', controllerTableData(cfg.controllerCases));
end

function applyAnalysis(ui, cfg)
set(ui.cMinEdit, 'String', numberText(cfg.cMin));
set(ui.cMaxEdit, 'String', numberText(cfg.cMax));
set(ui.ksEdit, 'String', numberText(cfg.ks));
set(ui.alphaEdit, 'String', numberText(cfg.alpha));
set(ui.lastNCyclesEdit, 'String', numberText(cfg.lastNCycles));
set(ui.harmonicOrderEdit, 'String', numberText(cfg.harmonicOrder));
set(ui.forceBaselineDampingEdit, 'String', ...
    numberText(cfg.forceBaselineDamping));
setSignPopup(ui.vdSignPopup, cfg.vdToCanonicalSign);
setSignPopup(ui.forceSignPopup, cfg.forceToCanonicalSign);
setSignPopup(ui.switchSignPopup, cfg.switchPolarity);
setSignPopup(ui.zeroStatePopup, cfg.zeroSwitchState);
setPopupText(ui.forceModePopup, cfg.forceInputMode);
set(ui.frequencyFilterEdit, 'String', joinNumbers(cfg.selectedFrequencies_Hz));
setStrategySelection(ui.strategyList, cfg.selectedStrategies);
end

function fraction = updateProgress(ui, completed, total, status)
if ~(isnumeric(completed) && isscalar(completed) && isfinite(completed)) || ...
        ~(isnumeric(total) && isscalar(total) && isfinite(total))
    error('fdei_config_utils:InvalidProgress', ...
        '进度 completed 和 total 必须是有限标量。');
end
if total > 0
    fraction = max(0, min(1, completed/total));
    label = sprintf('%d/%d（%.0f%%） %s', round(completed), round(total), ...
        100*fraction, char(string(status)));
else
    fraction = 0;
    label = char(string(status));
end
set(ui.progressFill, 'Position', [0 0 fraction 1]);
set(ui.progressText, 'String', label);
drawnow limitrate;
end

function cfg = readAnalysis(ui, baseCfg)
cfg = baseCfg;
cfg.cMin = parseScalar(getString(ui.cMinEdit), 'cMin');
cfg.cMax = parseScalar(getString(ui.cMaxEdit), 'cMax');
cfg.ks = parseScalar(getString(ui.ksEdit), 'ks');
cfg.alpha = parseScalar(getString(ui.alphaEdit), 'alpha');
cfg.lastNCycles = parseScalar(getString(ui.lastNCyclesEdit), 'lastNCycles');
cfg.harmonicOrder = parseScalar(getString(ui.harmonicOrderEdit), 'harmonicOrder');
cfg.forceBaselineDamping = parseScalar( ...
    getString(ui.forceBaselineDampingEdit), 'forceBaselineDamping');
cfg.vdToCanonicalSign = popupSign(ui.vdSignPopup);
cfg.forceToCanonicalSign = popupSign(ui.forceSignPopup);
cfg.switchPolarity = popupSign(ui.switchSignPopup);
cfg.zeroSwitchState = popupSign(ui.zeroStatePopup);
forceItems = get(ui.forceModePopup, 'String');
cfg.forceInputMode = char(string(forceItems{get(ui.forceModePopup, 'Value')}));
cfg.selectedFrequencies_Hz = parseNumbersOrEmpty(...
    getString(ui.frequencyFilterEdit));
selected = get(ui.strategyList, 'String');
selectedIndex = get(ui.strategyList, 'Value');
if isempty(selected)
    cfg.selectedStrategies = "all";
else
    cfg.selectedStrategies = string(selected(selectedIndex));
end
cfg = validateAnalysis(cfg);
end

function cfg = validateAnalysis(cfg)
if cfg.cMin < 0 || cfg.cMax <= cfg.cMin || cfg.ks <= 0 || cfg.alpha <= 0
    error('fdei_config_utils:InvalidAnalysis', ...
        '必须满足 0 <= cMin < cMax，且 ks、alpha 为正。');
end
end

function cases = tableToCases(tableData)
if isempty(tableData)
    error('fdei_config_utils:EmptyAlgorithms', '至少选择一个 FDEI 算法。');
end
enabled = [tableData{:,1}];
displayNames = tableData(:,2);
variantNames = tableData(:,3);
cases = cell(nnz(enabled), 2);
row = 0;
for index = 1:numel(enabled)
    if ~enabled(index)
        continue;
    end
    row = row+1;
    cases{row,1} = char(string(variantNames{index}));
    cases{row,2} = char(string(displayNames{index}));
end
cases = cases(1:row,:);
end

function data = controllerTableData(cases)
data = cell(size(cases, 1), 3);
for index = 1:size(cases, 1)
    data(index,:) = {true, char(string(cases{index,2})), ...
        char(string(cases{index,1}))};
end
end

function value = parseScalar(text, name)
value = str2double(strtrim(char(string(text))));
if ~isfinite(value)
    error('fdei_config_utils:InvalidNumber', '%s 必须是有限数值。', name);
end
end

function values = parseNumbers(text, name)
tokens = regexp(strtrim(char(string(text))), '[,;\s]+', 'split');
tokens = tokens(~cellfun(@isempty, tokens));
values = str2double(tokens);
if isempty(values) || any(~isfinite(values)) || any(values <= 0)
    error('fdei_config_utils:InvalidVector', ...
        '%s 必须是由逗号、分号或空格分隔的正数。', name);
end
values = values(:).';
end

function values = parseNumbersOrEmpty(text)
if isempty(strtrim(char(string(text))))
    values = [];
else
    values = parseNumbers(text, '频率筛选');
end
end

function cases = parseManualCases(text)
text = strtrim(char(string(text)));
if isempty(text)
    cases = zeros(0, 2);
    return;
end
text = regexprep(text, '[\[\]]', '');
rows = regexp(text, '[;\r\n]+', 'split');
rows = rows(~cellfun(@(value) isempty(strtrim(value)), rows));
cases = zeros(numel(rows), 2);
for index = 1:numel(rows)
    tokens = regexp(strtrim(rows{index}), '[,\s]+', 'split');
    values = str2double(tokens);
    if numel(values) ~= 2 || any(~isfinite(values)) || any(values <= 0)
        error('fdei_config_utils:InvalidManualCases', ...
            '手工工况每行必须是两个正数：频率 Hz, 位移幅值 m。');
    end
    cases(index,:) = values;
end
end

function value = getString(control)
value = get(control, 'String');
if iscell(value)
    value = strjoin(value, ' ');
end
value = char(string(value));
end

function value = popupSign(control)
value = 1;
if get(control, 'Value') == 2
    value = -1;
end
end

function setPopupText(control, target)
items = string(get(control, 'String'));
index = find(strcmpi(items, string(target)), 1);
if isempty(index)
    error('fdei_config_utils:PopupValue', ...
        '控件不支持配置值 %s。', char(string(target)));
end
set(control, 'Value', index);
end

function setSignPopup(control, signValue)
set(control, 'Value', 1 + double(signValue < 0));
end

function setStrategySelection(control, selected)
items = string(get(control, 'String'));
selected = string(selected);
if isempty(selected) || any(strcmpi(selected, 'all'))
    indices = find(strcmpi(items, 'all'), 1);
else
    indices = find(ismember(lower(items), lower(selected)));
end
if isempty(indices)
    indices = 1;
end
set(control, 'Value', indices);
end

function value = numberText(number)
value = sprintf('%.15g', number);
end

function value = joinNumbers(numbers)
if isempty(numbers)
    value = '';
    return;
end
value = strjoin(arrayfun(@(number) sprintf('%.15g', number), numbers, ...
    'UniformOutput', false), ', ');
end
