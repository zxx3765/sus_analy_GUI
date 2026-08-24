function [ok, modelName, modelFile, message] = batch_model_file_utils( ...
        modelInput, referenceDirectory)
%% 批量仿真模型文件路径解析
% 统一处理浏览选择、手动粘贴和算法清单导入的模型路径。
% 支持绝对路径、相对于 referenceDirectory 的路径、成对单双引号，
% 以及省略 .slx/.mdl 扩展名的输入。

ok = false;
modelName = '';
modelFile = '';
message = '';

if nargin < 2 || isempty(referenceDirectory)
    referenceDirectory = pwd;
end

[textOK, modelText] = normalizePathText(modelInput);
if ~textOK
    message = '模型文件路径必须是 char 行向量或 string 标量。';
    return;
end

modelText = stripPairedQuotes(strtrim(modelText));
if isempty(modelText)
    message = '模型文件路径不能为空。';
    return;
end

[referenceOK, referenceDirectory] = normalizePathText(referenceDirectory);
if ~referenceOK || isempty(strtrim(referenceDirectory))
    referenceDirectory = pwd;
else
    referenceDirectory = stripPairedQuotes(strtrim(referenceDirectory));
end

candidates = buildCandidates(modelText, referenceDirectory);
resolvedFile = '';
for i = 1:numel(candidates)
    try
        [resolved, attributes] = fileattrib(candidates{i});
        if resolved && isstruct(attributes) && isfield(attributes, 'Name') && ...
                (~isfield(attributes, 'directory') || ~attributes.directory)
            resolvedFile = attributes.Name;
            break;
        end
    catch
        % 继续尝试其他候选路径，并在全部失败后返回统一诊断信息。
    end
end

if isempty(resolvedFile)
    message = sprintf(['模型文件不存在。\n输入路径：%s\n' ...
        '解析基准目录：%s'], modelText, referenceDirectory);
    return;
end

[~, modelName, extension] = fileparts(resolvedFile);
if ~strcmpi(extension, '.slx') && ~strcmpi(extension, '.mdl')
    message = sprintf('模型文件必须是 .slx 或 .mdl：%s', resolvedFile);
    modelName = '';
    return;
end
if isempty(modelName) || ~isvarname(modelName)
    message = sprintf('模型文件名不是有效的 MATLAB/Simulink 名称：%s', ...
        modelName);
    modelName = '';
    return;
end

modelFile = resolvedFile;
ok = true;
end

function [ok, value] = normalizePathText(value)
ok = false;
if ischar(value)
    ok = isrow(value);
elseif isstring(value)
    ok = isscalar(value) && ~ismissing(value);
    if ok
        value = char(value);
    end
end
end

function value = stripPairedQuotes(value)
while numel(value) >= 2
    doubleQuoted = value(1) == char(34) && value(end) == char(34);
    singleQuoted = value(1) == char(39) && value(end) == char(39);
    if ~doubleQuoted && ~singleQuoted
        break;
    end
    value = strtrim(value(2:end - 1));
end
end

function candidates = buildCandidates(modelText, referenceDirectory)
if isAbsolutePath(modelText)
    candidates = {modelText};
else
    candidates = {fullfile(referenceDirectory, modelText)};
    currentCandidate = fullfile(pwd, modelText);
    if ~samePathText(currentCandidate, candidates{1})
        candidates{end + 1} = currentCandidate; %#ok<AGROW>
    end
end

[~, ~, extension] = fileparts(modelText);
if isempty(extension)
    baseCandidates = candidates;
    candidates = cell(1, 2 * numel(baseCandidates));
    for i = 1:numel(baseCandidates)
        candidates{2 * i - 1} = [baseCandidates{i} '.slx'];
        candidates{2 * i} = [baseCandidates{i} '.mdl'];
    end
end
end

function result = isAbsolutePath(value)
if ispc
    result = ~isempty(regexp(value, '^[A-Za-z]:[\\/]', 'once')) || ...
        startsWith(value, '\\') || startsWith(value, '//');
else
    result = startsWith(value, '/');
end
end

function result = samePathText(first, second)
if ispc
    result = strcmpi(first, second);
else
    result = strcmp(first, second);
end
end
