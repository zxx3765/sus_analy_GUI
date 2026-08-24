function varargout = batch_algorithm_config_utils(action, varargin)
%% 批量算法清单的纯校验、命名和合并工具
% 通过 action 提供可独立测试的配置逻辑，GUI 只负责交互和控件状态。
%
% [ok, message, algorithms] = batch_algorithm_config_utils( ...
%     'validate', algorithms, strictTypes, requireEnabled)
% [ok, message, algorithms, configState] = batch_algorithm_config_utils( ...
%     'validateconfig', config)
% [ok, message, merged, skipped] = batch_algorithm_config_utils( ...
%     'mergeappend', current, incoming)
% name = batch_algorithm_config_utils('outputname', displayName)

if nargin < 1
    error('batch_algorithm_config_utils:MissingAction', ...
        '必须指定工具操作。');
end
action = lower(char(action));
switch action
    case 'validate'
        algorithms = varargin{1};
        strictTypes = getLogicalOption(varargin, 2, false);
        requireEnabled = getLogicalOption(varargin, 3, false);
        [varargout{1}, varargout{2}, varargout{3}] = ...
            validateAlgorithms(algorithms, strictTypes, requireEnabled);
    case 'validateconfig'
        config = varargin{1};
        [ok, message, algorithms, configState] = validateConfig(config);
        varargout{1} = ok;
        varargout{2} = message;
        varargout{3} = algorithms;
        if nargout >= 4
            varargout{4} = configState;
        end
    case 'mergeappend'
        current = varargin{1};
        incoming = varargin{2};
        [varargout{1}, varargout{2}, varargout{3}, varargout{4}] = ...
            mergeAppend(current, incoming);
    case 'outputname'
        varargout{1} = makeOutputName(varargin{1});
    otherwise
        error('batch_algorithm_config_utils:UnknownAction', ...
            '未知工具操作：%s。', action);
end
end

function option = getLogicalOption(values, index, defaultValue)
option = defaultValue;
if numel(values) >= index && ~isempty(values{index})
    option = logical(values{index});
end
end

function [ok, message, algorithms, configState] = validateConfig(config)
ok = false;
message = '';
algorithms = struct('enabled', {}, 'display_name', {}, ...
    'subsystem_label', {});
configState = struct('schema_version', [], 'model_file', '');
if ~isstruct(config) || ~isscalar(config)
    message = '算法清单必须是标量结构体。';
    return;
end
if ~isfield(config, 'schema_version')
    message = '算法清单缺少 schema_version。';
    return;
end
schema = config.schema_version;
if ~isnumeric(schema) || ~isscalar(schema) || ~isreal(schema) || ...
        ~isfinite(schema) || ~ismember(schema, [1, 2])
    message = 'schema_version 必须是标量数值 1 或 2。';
    return;
end
configState.schema_version = schema;

if schema >= 2 && ~isfield(config, 'model_file')
    message = 'schema_version 2 的算法清单缺少 model_file。';
    return;
end
if isfield(config, 'model_file')
    [modelOK, modelFile] = normalizeText(config.model_file, true);
    if ~modelOK || isempty(strtrim(modelFile))
        message = 'model_file 必须是非空 char 行向量或 string 标量。';
        return;
    end
    configState.model_file = strtrim(modelFile);
end
if ~isfield(config, 'algorithms') || ~isstruct(config.algorithms)
    message = 'algorithms 必须是结构体数组。';
    return;
end
[ok, message, algorithms] = validateAlgorithms(config.algorithms, true, false);
end

function [ok, message, algorithms] = validateAlgorithms(algorithms, ...
        strictTypes, requireEnabled)
ok = false;
message = '';
if ~isstruct(algorithms)
    message = '算法列表必须是结构体数组。';
    return;
end
requiredFields = {'enabled', 'display_name', 'subsystem_label'};
for i = 1:numel(requiredFields)
    if ~isfield(algorithms, requiredFields{i})
        message = ['算法列表缺少字段：' requiredFields{i} '。'];
        return;
    end
end
if isempty(algorithms)
    message = '算法列表不能为空。';
    return;
end

normalized = repmat(struct('enabled', true, 'display_name', '', ...
    'subsystem_label', ''), size(algorithms));
enabledCount = 0;
outputNames = cell(numel(algorithms), 1);
displayNames = cell(numel(algorithms), 1);
for i = 1:numel(algorithms)
    [enabledOK, enabledValue] = normalizeEnabled( ...
        algorithms(i).enabled, strictTypes);
    if ~enabledOK
        message = sprintf(['第 %d 行的 enabled 必须是标量 logical，' ...
            '或值为 0/1 的标量数值。'], i);
        return;
    end
    [displayOK, displayName] = normalizeText( ...
        algorithms(i).display_name, strictTypes);
    if ~displayOK
        message = sprintf(['第 %d 行的 display_name 必须是标量 char 行向量' ...
            '或 string 标量。'], i);
        return;
    end
    [subsystemOK, subsystemName] = normalizeText( ...
        algorithms(i).subsystem_label, strictTypes);
    if ~subsystemOK
        message = sprintf(['第 %d 行的 subsystem_label 必须是标量 char 行向量' ...
            '或 string 标量。'], i);
        return;
    end

    displayName = strtrim(displayName);
    if isempty(displayName)
        message = sprintf('第 %d 行的显示名称不能为空。', i);
        return;
    end
    if isempty(strtrim(subsystemName))
        message = sprintf('第 %d 行的模型子系统名称不能为空。', i);
        return;
    end

    normalized(i).enabled = enabledValue;
    normalized(i).display_name = displayName;
    normalized(i).subsystem_label = subsystemName;
    displayNames{i} = displayName;
    outputNames{i} = makeOutputName(displayName);
    if enabledValue
        enabledCount = enabledCount + 1;
    end
end

if requireEnabled && enabledCount == 0
    message = '请至少勾选一个参与本次批量仿真的算法。';
    return;
end
if numel(unique(displayNames)) ~= numel(displayNames)
    message = '显示名称不能重复。';
    return;
end
if numel(unique(outputNames)) ~= numel(outputNames)
    message = '显示名称规范化后产生重复的保存变量名，请修改名称。';
    return;
end
algorithms = normalized;
ok = true;
end

function [ok, value] = normalizeEnabled(value, strictTypes)
ok = false;
if strictTypes
    if islogical(value) && isscalar(value)
        ok = true;
    elseif isnumeric(value) && isscalar(value) && isreal(value) && ...
            isfinite(value) && (value == 0 || value == 1)
        ok = true;
    end
    if ok
        value = logical(value);
    end
    return;
end
if islogical(value) && isscalar(value)
    ok = true;
elseif isnumeric(value) && isscalar(value) && isreal(value) && ...
        isfinite(value) && (value == 0 || value == 1)
    ok = true;
    value = logical(value);
end
end

function [ok, value] = normalizeText(value, strictTypes)
ok = false;
if ischar(value)
    ok = isrow(value);
elseif isstring(value)
    ok = isscalar(value) && ~ismissing(value);
    if ok
        value = char(value);
    end
elseif ~strictTypes && (isnumeric(value) || islogical(value))
    % 仅用于 GUI 表格路径的兼容性归一化；MAT 导入走 strictTypes=true。
    if isscalar(value)
        value = num2str(value);
        ok = true;
    end
end
end

function [ok, message, merged, skipped] = mergeAppend(current, incoming)
skipped = struct('display_name', {}, 'output_name', {});
[ok, message, current] = validateAlgorithms(current, false, false);
if ~ok
    merged = current;
    return;
end
[ok, message, incoming] = validateAlgorithms(incoming, true, false);
if ~ok
    merged = current;
    return;
end

% 统一为列向量，保证 GUI 表格和 MAT 文件的行/列形状不会影响追加结果。
current = reshape(current, [], 1);
incoming = reshape(incoming, [], 1);
merged = current;
currentNames = cell(numel(current), 1);
for i = 1:numel(current)
    currentNames{i} = makeOutputName(current(i).display_name);
end
for i = 1:numel(incoming)
    incomingName = makeOutputName(incoming(i).display_name);
    if any(strcmp(currentNames, incomingName))
        skipped(end + 1).display_name = incoming(i).display_name; %#ok<AGROW>
        skipped(end).output_name = incomingName;
    else
        merged(end + 1, 1) = incoming(i); %#ok<AGROW>
        currentNames{end + 1} = incomingName; %#ok<AGROW>
    end
end
end

function outputName = makeOutputName(displayName)
if isstring(displayName)
    displayName = char(displayName);
end
displayName = strtrim(displayName);
try
    outputName = matlab.lang.makeValidName(['out_' displayName]);
catch
    outputName = ['out_' regexprep(displayName, '[^a-zA-Z0-9_]', '_')];
end
if isempty(outputName) || strcmp(outputName, 'out_') || ~isvarname(outputName)
    outputName = ['out_algorithm_' textCode(displayName)];
end
end

function code = textCode(value)
value = double(value);
if isempty(value)
    code = '0';
    return;
end
weighted = sum(value .* (1:numel(value)));
code = sprintf('%u', mod(round(weighted), 2147483647));
end
