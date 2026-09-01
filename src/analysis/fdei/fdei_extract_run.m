function [run, info] = fdei_extract_run(simOut, strategy, fHz, cfg, targetDt)
%FDEI_EXTRACT_RUN Extract, align, resample, and retain a steady-state run.
%   This public adapter accepts logsout Dataset elements and simout:<var>
%   references. It returns the runs data contract used by FDEI analysis.

if nargin < 5 || isempty(targetDt)
    targetDt = fdei_compute_target_dt(fHz, cfg);
end
raw.vs = extractConfigured(simOut, cfg, signalSpec(cfg, 'vs'), 'vs', true);
raw.as = extractConfigured(simOut, cfg, signalSpec(cfg, 'as'), 'as', true);

raw.vd = emptyRaw();
raw.vu = emptyRaw();
raw.Fd = emptyRaw();
raw.cCmd = emptyRaw();

vdSpec = signalSpec(cfg, 'vd');
vuSpec = signalSpec(cfg, 'vu');
if ~isempty(vdSpec)
    raw.vd = extractConfigured(simOut, cfg, vdSpec, 'vd', true);
end
if ~isempty(vuSpec)
    raw.vu = extractConfigured(simOut, cfg, vuSpec, 'vu', isempty(vdSpec));
end

forceSpec = signalSpec(cfg, 'Fd');
commandSpec = signalSpec(cfg, 'cCmd');
if ~isempty(forceSpec)
    raw.Fd = extractConfigured(simOut, cfg, forceSpec, 'Fd', true);
end
if ~isempty(commandSpec)
    raw.cCmd = extractConfigured(simOut, cfg, commandSpec, 'cCmd', isempty(forceSpec));
end

optionalNames = {'xr','xu','tireDef','suspDef'};
for index = 1:numel(optionalNames)
    fieldName = optionalNames{index};
    raw.(fieldName) = emptyRaw();
    spec = signalSpec(cfg, fieldName);
    if ~isempty(spec)
        raw.(fieldName) = extractConfigured(simOut, cfg, spec, fieldName, false);
    end
end

if ~raw.vd.available && ~raw.vu.available
    error('fdei_extract_run:MissingRelativeVelocity', ...
        '未获得 vd 或 vu，无法构造 runs。');
end
if ~raw.Fd.available && ~raw.cCmd.available
    error('fdei_extract_run:MissingForce', ...
        '未获得 Fd 或 cCmd，无法构造 runs。');
end

requiredFields = {'vs','as'};
requiredFields{end+1} = ternaryField(raw.vd.available, 'vd', 'vu');
requiredFields{end+1} = ternaryField(raw.Fd.available, 'Fd', 'cCmd');
starts = cellfun(@(name) raw.(name).t(1), requiredFields);
ends = cellfun(@(name) raw.(name).t(end), requiredFields);
overlapStart = max(starts);
overlapEnd = min(ends);
if overlapEnd <= overlapStart
    error('fdei_extract_run:NoOverlap', ...
        '必需信号之间不存在共同时间区间。');
end

saveStart = max(overlapStart, overlapEnd - cfg.savedCycles/fHz);
nSteps = floor((overlapEnd - saveStart)/targetDt);
validatorCycles = cfg.validatorLastNCycles;
minimumSteps = cfg.samplesPerCycle*validatorCycles*0.8;
if nSteps < minimumSteps
    error('fdei_extract_run:InsufficientSteadySamples', ...
        '统一时间轴只有 %d 个步长，少于验证所需水平。', nSteps);
end
tCommon = saveStart + (0:nSteps)'*targetDt;

run = runTemplate();
run.strategy = string(strategy);
run.fHz = double(fHz);
run.t = tCommon;
allFields = {'vs','as','vd','vu','Fd','cCmd','xr','xu','tireDef','suspDef'};
for index = 1:numel(allFields)
    fieldName = allFields{index};
    if ~raw.(fieldName).available
        continue;
    end
    covered = raw.(fieldName).t(1) <= tCommon(1) && ...
        raw.(fieldName).t(end) >= tCommon(end);
    if ~covered
        if ismember(fieldName, requiredFields)
            error('fdei_extract_run:Coverage', ...
                '必需信号 %s 未覆盖统一时间轴。', fieldName);
        end
        handleOptional(cfg, '可选信号 %s 未覆盖统一时间轴，已忽略。', fieldName);
        continue;
    end
    method = cfg.otherInterpolation;
    if strcmp(fieldName, 'cCmd')
        method = cfg.cCmdInterpolation;
    end
    run.(fieldName) = interp1(raw.(fieldName).t, raw.(fieldName).x, ...
        tCommon, method);
    run.(fieldName) = run.(fieldName)(:);
end

info = struct();
info.samplesPerCycle = numel(tCommon)/max((tCommon(end)-tCommon(1))*fHz, eps);
rawSamples = cellfun(@(name) rawSamplesPerCycle(raw.(name), tCommon, fHz), ...
    requiredFields);
finiteRaw = rawSamples(isfinite(rawSamples));
info.rawMinSamplesPerCycle = iff(isempty(finiteRaw), NaN, min(finiteRaw));
info.overlapStart_s = overlapStart;
info.overlapEnd_s = overlapEnd;
end

function spec = signalSpec(cfg, fieldName)
spec = '';
if isfield(cfg, 'signal') && isfield(cfg.signal, fieldName)
    spec = char(string(cfg.signal.(fieldName)));
end
end

function raw = extractConfigured(simOut, cfg, spec, roleName, required)
try
    [t, x] = extractSignal(simOut, cfg, spec);
    raw = makeRaw(t, x, spec);
catch exception
    if required
        error('fdei_extract_run:RequiredSignal', ...
            '提取必需信号 %s（%s）失败：%s', roleName, spec, exception.message);
    end
    handleOptional(cfg, '提取可选信号 %s（%s）失败，已忽略：%s', ...
        roleName, spec, exception.message);
    raw = emptyRaw();
end
end

function [t, x] = extractSignal(simOut, cfg, spec)
if startsWith(lower(strtrim(spec)), 'simout:')
    [t, x] = extractSimulationOutputReference(simOut, cfg, spec);
    return;
end
switch lower(strtrim(cfg.signalSource))
    case 'logsout'
        dataset = outputGet(simOut, cfg.logsoutVariable);
        if isempty(dataset)
            error('数据集 %s 为空。', cfg.logsoutVariable);
        end
        element = datasetElement(dataset, spec);
        valueObject = element;
        if isobject(element) && isprop(element, 'Values')
            valueObject = element.Values;
        end
    case 'simulationoutput'
        valueObject = outputGet(simOut, spec);
    otherwise
        error('未知 signalSource：%s。', cfg.signalSource);
end
[t, x] = unpackTimeData(valueObject, simOut, cfg, spec);
end

function [t, x] = extractSimulationOutputReference(simOut, cfg, spec)
expression = strtrim(spec(numel('simout:')+1:end));
tokens = regexp(expression, '^([A-Za-z_]\w*)\(:,\s*(\d+)\)$', ...
    'tokens', 'once');
if isempty(tokens)
    variableName = expression;
    columnIndex = [];
else
    variableName = tokens{1};
    columnIndex = str2double(tokens{2});
end
if ~isvarname(variableName)
    error('非法 SimulationOutput 引用：%s。', spec);
end
valueObject = outputGet(simOut, variableName);
if ~isempty(columnIndex)
    if ~isnumeric(valueObject) || ~ismatrix(valueObject) || ...
            size(valueObject, 2) < columnIndex
        error('SimulationOutput 变量 %s 不能按列读取。', variableName);
    end
    valueObject = valueObject(:, columnIndex);
end
[t, x] = unpackTimeData(valueObject, simOut, cfg, spec);
end

function value = outputGet(simOut, name)
if isstruct(simOut)
    if ~isfield(simOut, name)
        error('SimulationOutput 中不存在变量 %s。', name);
    end
    value = simOut.(name);
    return;
end
value = simOut.get(name);
end

function element = datasetElement(dataset, signalName)
names = {};
try
    names = dataset.getElementNames;
catch
end
if isstring(names)
    names = cellstr(names);
end
idx = find(strcmp(names, signalName), 1);
if isempty(idx)
    idx = find(strcmpi(names, signalName), 1);
end
if ~isempty(idx)
    element = dataset.getElement(idx);
    return;
end
element = dataset.getElement(signalName);
end

function [t, x] = unpackTimeData(valueObject, simOut, cfg, signalName)
if isobject(valueObject) && isprop(valueObject, 'Values')
    valueObject = valueObject.Values;
end
if isa(valueObject, 'timeseries')
    t = valueObject.Time;
    x = valueObject.Data;
    return;
end
if istimetableSafe(valueObject)
    rowTimes = valueObject.Properties.RowTimes;
    if isduration(rowTimes)
        t = seconds(rowTimes);
    elseif isdatetime(rowTimes)
        t = seconds(rowTimes - rowTimes(1));
    else
        t = double(rowTimes);
    end
    if width(valueObject) ~= 1
        error('信号 %s 必须是单列 timetable。', signalName);
    end
    x = valueObject{:,1};
    return;
end
if isstruct(valueObject)
    if isfield(valueObject, 'Time') && isfield(valueObject, 'Data')
        t = valueObject.Time;
        x = valueObject.Data;
        return;
    end
    if isfield(valueObject, 'time') && isfield(valueObject, 'signals') && ...
            isfield(valueObject.signals, 'values')
        t = valueObject.time;
        x = valueObject.signals.values;
        return;
    end
end
if isnumeric(valueObject)
    x = valueObject;
    t = outputGet(simOut, cfg.timeVariable);
    return;
end
error('暂不支持信号 %s 的数据类型：%s。', signalName, class(valueObject));
end

function raw = makeRaw(t, x, sourceName)
t = double(t(:));
x = squeeze(double(x));
if isscalar(x) && numel(t) > 1
    x = repmat(x, numel(t), 1);
end
if ~isvector(x) || numel(t) ~= numel(x)
    error('信号 %s 不是与时间轴等长的一维信号。', sourceName);
end
x = x(:);
finite = isfinite(t) & isfinite(x);
t = t(finite);
x = x(finite);
[t, order] = sort(t);
x = x(order);
[t, uniqueIndex] = unique(t, 'stable');
x = x(uniqueIndex);
if numel(t) < 2 || any(diff(t) <= 0)
    error('信号 %s 的时间轴无法整理为严格递增序列。', sourceName);
end
raw = struct('available', true, 't', t, 'x', x, 'sourceName', sourceName);
end

function raw = emptyRaw()
raw = struct('available', false, 't', [], 'x', [], 'sourceName', '');
end

function handleOptional(cfg, message, varargin)
if isfield(cfg, 'optionalSignalMissingPolicy') && ...
        strcmpi(cfg.optionalSignalMissingPolicy, 'error')
    error('fdei_extract_run:OptionalSignal', message, varargin{:});
end
warning('fdei_extract_run:OptionalSignal', message, varargin{:});
end

function value = rawSamplesPerCycle(raw, tCommon, fHz)
if ~raw.available
    value = NaN;
    return;
end
window = raw.t(raw.t >= tCommon(1) & raw.t <= tCommon(end));
if numel(window) < 3
    value = NaN;
else
    value = 1/(median(diff(window))*fHz);
end
end

function value = ternaryField(condition, trueValue, falseValue)
if condition
    value = trueValue;
else
    value = falseValue;
end
end

function value = iff(condition, trueValue, falseValue)
if condition
    value = trueValue;
else
    value = falseValue;
end
end

function tf = istimetableSafe(value)
tf = false;
try
    tf = istimetable(value);
catch
end
end

function run = runTemplate()
run = struct('strategy', "", 'fHz', NaN, 't', [], 'vs', [], ...
    'as', [], 'vd', [], 'vu', [], 'Fd', [], 'cCmd', [], 'xr', [], ...
    'xu', [], 'tireDef', [], 'suspDef', []);
end
