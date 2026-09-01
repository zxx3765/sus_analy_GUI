function [runs, batchCfg, batchManifest, sourceFiles] = fdei_load_batch_results(inputValue, cfg)
%FDEI_LOAD_BATCH_RESULTS Load and merge one or more FDEI MAT result files.
%   INPUTVALUE may be a path, a string/cell array of paths, or a config
%   struct containing batchResultFiles/batchOutputDir settings.

if nargin < 1 || isempty(inputValue)
    inputValue = fdei_default_config('analysis');
end
if nargin < 2 || isempty(cfg)
    if isstruct(inputValue)
        cfg = inputValue;
    else
        cfg = fdei_default_config('analysis');
    end
end
sourceFiles = resolveSources(inputValue, cfg);
runParts = cell(1, numel(sourceFiles));
manifestParts = cell(1, numel(sourceFiles));
partCount = 0;
batchCfg = struct();
manifestCount = 0;
for fileIndex = 1:numel(sourceFiles)
    loaded = load(sourceFiles{fileIndex});
    if ~isfield(loaded, 'runs') || isempty(loaded.runs)
        warning('fdei_load_batch_results:EmptyFile', ...
            '跳过不含有效 runs 的文件：%s', sourceFiles{fileIndex});
        continue;
    end
    if ~isstruct(loaded.runs)
        error('fdei_load_batch_results:InvalidRuns', ...
            '批量结果文件中的 runs 必须是结构体数组：%s', sourceFiles{fileIndex});
    end
    current = normalizeRuns(loaded.runs(:));
    if partCount > 0 && ~isequal(fieldnames(runParts{1}), fieldnames(current))
        error('fdei_load_batch_results:FieldMismatch', ...
            '批量文件字段不一致，无法合并：%s', sourceFiles{fileIndex});
    end
    partCount = partCount+1;
    runParts{partCount} = current;
    if isempty(fieldnames(batchCfg)) && isfield(loaded, 'batchCfg') && ...
            isstruct(loaded.batchCfg)
        batchCfg = loaded.batchCfg;
    end
    if isfield(loaded, 'batchManifest') && istableSafe(loaded.batchManifest)
        manifestCount = manifestCount+1;
        manifestParts{manifestCount} = loaded.batchManifest;
    end
end
if partCount == 0
    error('fdei_load_batch_results:NoRuns', '所有批量结果文件都没有可用 runs。');
end
runs = vertcat(runParts{1:partCount});
runs = deduplicateRuns(runs);
batchManifest = mergeManifests(manifestParts(1:manifestCount));
runs = filterRuns(runs, cfg);
end

function files = resolveSources(inputValue, cfg)
if isstruct(inputValue)
    files = configuredFiles(inputValue);
elseif ischar(inputValue) || isstring(inputValue)
    files = cellstr(string(inputValue));
elseif iscell(inputValue)
    files = cellstr(string(inputValue));
else
    error('fdei_load_batch_results:InvalidInput', ...
        '输入必须是路径、路径列表或配置结构体。');
end
files = files(cellfun(@(path) exist(path, 'file') == 2, files));
if isempty(files) && isstruct(cfg) && getLogical(cfg, 'useCheckpointIfFinalMissing', true)
    outputDir = getText(cfg, 'batchOutputDir', '');
    checkpointName = getText(cfg, 'checkpointMatName', 'FDEI_batch_checkpoint.mat');
    checkpoint = fullfile(outputDir, checkpointName);
    if exist(checkpoint, 'file') == 2
        files = {checkpoint};
        warning('fdei_load_batch_results:Checkpoint', ...
            '最终结果不存在，改用 checkpoint：%s', checkpoint);
    end
end
if isempty(files)
    error('fdei_load_batch_results:MissingFiles', ...
        '找不到可用 FDEI 批量结果文件。');
end
end

function files = configuredFiles(cfg)
files = {};
if isfield(cfg, 'batchResultFiles') && ~isempty(cfg.batchResultFiles)
    files = cellstr(string(cfg.batchResultFiles));
elseif getLogical(cfg, 'autoDetectBatchResult', true)
    outputDir = getText(cfg, 'batchOutputDir', getText(cfg, 'outputDir', ''));
    outputName = getText(cfg, 'outputMatName', 'FDEI_batch_runs.mat');
    [baseName, ~, extension] = fileparts(outputName);
    if isempty(extension)
        extension = '.mat';
    end
    candidates = dir(fullfile(outputDir, [baseName '*' extension]));
    if ~isempty(candidates)
        [~, order] = sort([candidates.datenum]); %#ok<DATNM>
        files = arrayfun(@(item) fullfile(item.folder, item.name), ...
            candidates(order), 'UniformOutput', false);
    end
elseif isfield(cfg, 'batchResultFile')
    files = {char(string(cfg.batchResultFile))};
end
end

function runs = normalizeRuns(runs)
required = {'strategy','fHz','t','vs','as'};
optional = {'vd','vu','Fd','cCmd','xr','xu','tireDef','suspDef'};
for index = 1:numel(required)
    if ~isfield(runs, required{index})
        error('fdei_load_batch_results:MissingRunField', ...
            'runs 缺少字段 %s。', required{index});
    end
end
for index = 1:numel(optional)
    fieldName = optional{index};
    if ~isfield(runs, fieldName)
        [runs.(fieldName)] = deal([]);
    end
end
end

function runs = deduplicateRuns(runs)
keys = strings(numel(runs),1);
keep = true(numel(runs),1);
for index = 1:numel(runs)
    canonical = fdei_canonical_algorithm_name(runs(index).strategy);
    key = sprintf('%s|%.15g', canonical, double(runs(index).fHz));
    previous = find(keys(1:index-1) == string(key), 1, 'last');
    if isempty(previous)
        keys(index) = string(key);
    else
        keep(previous) = false;
        keys(index) = string(key);
    end
end
runs = runs(keep);
for index = 1:numel(runs)
    runs(index).strategy = string(fdei_canonical_algorithm_name(runs(index).strategy));
end
end

function manifest = mergeManifests(parts)
parts = parts(~cellfun(@isempty, parts));
if isempty(parts)
    manifest = table();
else
    manifest = parts{1};
    for index = 2:numel(parts)
        manifest = [manifest; parts{index}]; %#ok<AGROW>
    end
end
end

function runs = filterRuns(runs, cfg)
selectedStrategies = string(getField(cfg, 'selectedStrategies', "all"));
if isempty(selectedStrategies) || any(strcmpi(selectedStrategies, 'all'))
    strategyKeep = true(numel(runs),1);
else
    selectedCanonical = arrayfun(@(value) string(fdei_canonical_algorithm_name(value)), ...
        selectedStrategies);
    runStrategies = arrayfun(@(run) string(fdei_canonical_algorithm_name(run.strategy)), ...
        runs);
    strategyKeep = ismember(runStrategies, selectedCanonical);
end
selectedFrequencies = double(getField(cfg, 'selectedFrequencies_Hz', []));
frequencyKeep = true(numel(runs),1);
if ~isempty(selectedFrequencies)
    if any(~isfinite(selectedFrequencies(:)) | selectedFrequencies(:) <= 0)
        error('fdei_load_batch_results:InvalidFrequencyFilter', ...
            'selectedFrequencies_Hz 必须为正有限值。');
    end
    frequencies = [runs.fHz].';
    frequencyKeep = false(numel(runs),1);
    for index = 1:numel(selectedFrequencies)
        tolerance = max(1e-10, 1e-8*abs(selectedFrequencies(index)));
        frequencyKeep = frequencyKeep | ...
            abs(frequencies-selectedFrequencies(index)) <= tolerance;
    end
end
runs = runs(strategyKeep & frequencyKeep);
if isempty(runs)
    error('fdei_load_batch_results:EmptySelection', ...
        '按算法/频率筛选后没有可分析数据。');
end
end

function value = getField(cfg, fieldName, fallback)
if isstruct(cfg) && isfield(cfg, fieldName)
    value = cfg.(fieldName);
else
    value = fallback;
end
end

function value = getText(cfg, fieldName, fallback)
value = char(string(getField(cfg, fieldName, fallback)));
end

function value = getLogical(cfg, fieldName, fallback)
value = logical(getField(cfg, fieldName, fallback));
end

function tf = istableSafe(value)
tf = false;
try
    tf = istable(value);
catch
end
end
