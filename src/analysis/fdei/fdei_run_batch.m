function [runs, batchManifest, files] = fdei_run_batch(cfg, varargin)
%FDEI_RUN_BATCH Run serial FDEI simulations and persist compatible results.
%   The runner uses SimulationInput/SimulationOutput for each case. Model
%   settings are captured before execution and restored by onCleanup even if
%   a simulation fails or a cooperative stop is requested.

options = parseOptions(varargin{:});
cfg = fdei_validate_batch_config(cfg, true);
sine_cases = fdei_build_cases(cfg);
if isfield(cfg, 'roadAmplitudeWarningThreshold_m') && ...
        any(sine_cases(:,2) > cfg.roadAmplitudeWarningThreshold_m)
    warning('fdei_run_batch:LargeRoadAmplitude', ...
        '%d 个工况的道路位移幅值超过 %.4g m。', ...
        nnz(sine_cases(:,2) > cfg.roadAmplitudeWarningThreshold_m), ...
        cfg.roadAmplitudeWarningThreshold_m);
end
[modelName, modelFile] = resolveModel(cfg.model);
outputDir = char(string(cfg.outputDir));
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
rawOutputDir = fullfile(outputDir, 'raw_simulation_outputs');
if cfg.saveRawSimulationOutputs && ~exist(rawOutputDir, 'dir')
    mkdir(rawOutputDir);
end
checkpointFile = fullfile(outputDir, cfg.checkpointMatName);
finalFile = fullfile(outputDir, cfg.outputMatName);
manifestFile = fullfile(outputDir, cfg.manifestCsvName);

wasLoaded = bdIsLoaded(modelName);
if wasLoaded
    loadedFile = get_param(modelName, 'FileName');
    if ~sameFile(loadedFile, modelFile)
        error('fdei_run_batch:ModelNameCollision', ...
            '模型 %s 已从另一文件加载：%s。请先关闭该模型。', ...
            modelName, loadedFile);
    end
end
load_system(modelFile);
original = captureModelSettings(modelName, cfg);
cleanup = onCleanup(@() restoreModelSettings(modelName, original, ...
    wasLoaded, cfg)); %#ok<NASGU>

runs = repmat(runTemplate(), 0, 1);
manifestRows = repmat(manifestTemplate(), 0, 1);
simulationIndex = 0;
totalCount = size(sine_cases,1)*size(cfg.controllerCases,1);
timer = tic;
stopped = false;
emitLog(options, sprintf('FDEI 批量仿真开始：%d 个工况。', totalCount));

for caseIndex = 1:size(sine_cases,1)
    frequencyHz = sine_cases(caseIndex,1);
    amplitude = sine_cases(caseIndex,2);
    stopTime = fdei_compute_stop_time(frequencyHz, cfg);
    targetDt = fdei_compute_target_dt(frequencyHz, cfg);
    for controllerIndex = 1:size(cfg.controllerCases,1)
        if shouldStop(options, simulationIndex, totalCount)
            stopped = true;
            emitLog(options, '收到停止请求，将保留当前 checkpoint。');
            break;
        end
        simulationIndex = simulationIndex+1;
        variantLabel = cfg.controllerCases{controllerIndex,1};
        strategy = cfg.controllerCases{controllerIndex,2};
        row = manifestTemplate();
        row.SimulationIndex = simulationIndex;
        row.CaseIndex = caseIndex;
        row.ControllerIndex = controllerIndex;
        row.Strategy = strategy;
        row.VariantLabel = variantLabel;
        row.Frequency_Hz = frequencyHz;
        row.RoadAmplitude_m = amplitude;
        row.StopTime_s = stopTime;
        row.TargetDt_s = targetDt;
        row.Status = 'RUNNING';
        oneTimer = tic;
        emitLog(options, sprintf('运行 %d/%d：%s @ %.6g Hz。', ...
            simulationIndex, totalCount, strategy, frequencyHz));
        try
            in = Simulink.SimulationInput(modelName);
            in = in.setModelParameter('StopTime', numberText(stopTime), ...
                'FastRestart', 'off');
            if cfg.enforceSolverStep
                in = in.setModelParameter('MaxStep', numberText(targetDt));
            end
            in = in.setBlockParameter(fullBlockPath(modelName, ...
                cfg.variantSubsystemPath), 'LabelModeActiveChoice', variantLabel);
            in = in.setBlockParameter(fullBlockPath(modelName, ...
                cfg.roadSelectPath), 'Value', cfg.roadSelectValue);
            if strcmpi(cfg.parameterWorkspace, 'model')
                in = in.setVariable(cfg.frequencyVariable, frequencyHz, ...
                    'Workspace', modelName);
                in = in.setVariable(cfg.amplitudeVariable, amplitude, ...
                    'Workspace', modelName);
            else
                in = in.setVariable(cfg.frequencyVariable, frequencyHz);
                in = in.setVariable(cfg.amplitudeVariable, amplitude);
            end
            simOut = sim(in);
            [run, alignment] = fdei_extract_run(simOut, strategy, ...
                frequencyHz, cfg, targetDt);
            [ampChange, phaseChange, checkSignal] = ...
                steadyStateCheck(run, frequencyHz, cfg);
            runs(end+1,1) = run; %#ok<AGROW>
            row.SavedRunIndex = numel(runs);
            row.SamplesSaved = numel(run.t);
            row.SamplesPerCycle = alignment.samplesPerCycle;
            row.RawMinSamplesPerCycle = alignment.rawMinSamplesPerCycle;
            row.SavedWindowStart_s = run.t(1);
            row.SavedWindowEnd_s = run.t(end);
            row.SteadyCheckSignal = checkSignal;
            row.SteadyAmplitudeChange_pct = ampChange;
            row.SteadyPhaseChange_deg = phaseChange;
            if isfinite(ampChange) && ampChange > cfg.steadyAmplitudeTolerance_pct
                warning('fdei_run_batch:NonSteadyAmplitude', ...
                    '%.6g Hz / %s：稳态幅值变化 %.3f%% 超过 %.3f%%。', ...
                    frequencyHz, strategy, ampChange, ...
                    cfg.steadyAmplitudeTolerance_pct);
            end
            if isfinite(phaseChange) && ...
                    phaseChange > cfg.steadyPhaseTolerance_deg
                warning('fdei_run_batch:NonSteadyPhase', ...
                    '%.6g Hz / %s：稳态相位变化 %.3f deg 超过 %.3f deg。', ...
                    frequencyHz, strategy, phaseChange, ...
                    cfg.steadyPhaseTolerance_deg);
            end
            if isfinite(row.RawMinSamplesPerCycle) && ...
                    row.RawMinSamplesPerCycle < cfg.minimumRawSamplesPerCycle
                warning('fdei_run_batch:SparseRawSamples', ...
                    '%.6g Hz / %s：原始日志 %.1f 点/周期低于 %.1f。', ...
                    frequencyHz, strategy, row.RawMinSamplesPerCycle, ...
                    cfg.minimumRawSamplesPerCycle);
            end
            if cfg.saveRawSimulationOutputs
                rawFile = fullfile(rawOutputDir, sprintf('raw_%s_%.8gHz.mat', ...
                    regexprep(strategy, '[^a-zA-Z0-9_]', '_'), frequencyHz));
                save(rawFile, 'simOut', '-v7.3');
                row.RawOutputFile = rawFile;
            end
            row.Status = 'SUCCESS';
            row.Message = '';
            emitLog(options, sprintf('完成：%s @ %.6g Hz。', strategy, frequencyHz));
        catch exception
            row.Status = 'FAILED';
            row.Message = exception.message;
            emitLog(options, sprintf('失败：%s。', exception.message));
        end
        row.Elapsed_s = toc(oneTimer);
        manifestRows(end+1,1) = row; %#ok<AGROW>
        batchManifest = manifestTable(manifestRows);
        if cfg.saveCheckpoint
            saveBatch(checkpointFile, runs, cfg, sine_cases, batchManifest);
        end
        emitProgress(options, simulationIndex, totalCount, row);
        if strcmp(row.Status, 'FAILED') && cfg.stopOnError
            error('FDEI:BatchStopped', ...
                '工况失败，已写入 checkpoint：%s。', checkpointFile);
        end
    end
    if stopped
        break;
    end
end

batchElapsed_s = toc(timer); %#ok<NASGU>
batchCfg = cfg; %#ok<NASGU>
batchManifest = manifestTable(manifestRows);
save(finalFile, 'runs', 'batchCfg', 'sine_cases', 'batchManifest', ...
    'batchElapsed_s', '-v7.3');
if ~isempty(batchManifest)
    writetable(batchManifest, manifestFile);
end
% A cooperative stop is an intentional resumable boundary.  Keep its
% checkpoint instead of deleting it after writing the partial final file.
if cfg.saveCheckpoint && ~stopped && exist(checkpointFile, 'file') == 2
    delete(checkpointFile);
end
if cfg.assignRunsToBase
    assignin('base', 'runs', runs);
    assignin('base', 'FDEI_batch_manifest', batchManifest);
end
files = struct('mat', finalFile, 'manifest', manifestFile, ...
    'checkpoint', checkpointFile);
emitLog(options, sprintf('FDEI 批量仿真结束：成功 %d/%d。', ...
    numel(runs), totalCount));
end

function options = parseOptions(varargin)
options = struct('ProgressFcn', [], 'LogFcn', [], 'StopFcn', []);
for index = 1:2:numel(varargin)
    name = char(string(varargin{index}));
    if index+1 > numel(varargin) || ~isfield(options, name)
        error('fdei_run_batch:InvalidOption', '未知或缺失选项：%s。', name);
    end
    options.(name) = varargin{index+1};
end
end

function [modelName, modelFile] = resolveModel(value)
modelText = char(string(value));
[folder, name, extension] = fileparts(modelText);
if isempty(extension)
    extension = '.slx';
end
if isempty(folder)
    modelFile = which([name extension]);
else
    modelFile = fullfile(folder, [name extension]);
end
% Once Simulink is loaded, EXIST can classify a block-diagram model as 4
% instead of the ordinary file code 2. Both values identify a loadable
% model file here.
if isempty(modelFile) || ~ismember(exist(modelFile, 'file'), [2 4])
    error('fdei_run_batch:ModelNotFound', '找不到 Simulink 模型：%s。', modelText);
end
modelName = name;
end

function pathName = fullBlockPath(modelName, configuredPath)
pathName = char(string(configuredPath));
if ~startsWith(pathName, [modelName '/']) && ~strcmp(pathName, modelName)
    pathName = [modelName '/' pathName];
end
end

function original = captureModelSettings(modelName, cfg)
original = struct();
original.StopTime = get_param(modelName, 'StopTime');
original.FastRestart = get_param(modelName, 'FastRestart');
original.SolverType = get_param(modelName, 'SolverType');
original.MaxStep = get_param(modelName, 'MaxStep');
original.Variant = get_param(fullBlockPath(modelName, cfg.variantSubsystemPath), ...
    'LabelModeActiveChoice');
original.RoadValue = get_param(fullBlockPath(modelName, cfg.roadSelectPath), 'Value');
end

function restoreModelSettings(modelName, original, wasLoaded, cfg)
if ~bdIsLoaded(modelName)
    return;
end
try
    set_param(modelName, 'StopTime', original.StopTime, ...
        'FastRestart', original.FastRestart, 'MaxStep', original.MaxStep);
    set_param(fullBlockPath(modelName, cfg.variantSubsystemPath), ...
        'LabelModeActiveChoice', original.Variant);
    set_param(fullBlockPath(modelName, cfg.roadSelectPath), ...
        'Value', original.RoadValue);
    if ~wasLoaded && cfg.closeModelWhenDone
        close_system(modelName, 0);
    end
catch exception
    warning('fdei_run_batch:RestoreFailed', ...
        '恢复模型设置失败：%s', exception.message);
end
end

function tf = sameFile(leftFile, rightFile)
leftFile = canonicalFile(leftFile);
rightFile = canonicalFile(rightFile);
tf = strcmpi(leftFile, rightFile);
end

function value = canonicalFile(value)
[ok, attributes] = fileattrib(char(string(value)));
if ok
    value = attributes.Name;
else
    value = char(string(value));
end
end

function value = shouldStop(options, completed, total)
value = false;
if isempty(options.StopFcn)
    return;
end
try
    value = logical(options.StopFcn(completed, total));
catch exception
    warning('fdei_run_batch:StopCallback', ...
        '停止回调失败，继续执行：%s', exception.message);
end
end

function emitProgress(options, completed, total, row)
if isempty(options.ProgressFcn)
    return;
end
try
    options.ProgressFcn(completed, total, row);
catch exception
    warning('fdei_run_batch:ProgressCallback', ...
        '进度回调失败：%s', exception.message);
end
end

function emitLog(options, message)
if isempty(options.LogFcn)
    fprintf('[FDEI] %s\n', message);
    return;
end
try
    options.LogFcn(message);
catch exception
    warning('fdei_run_batch:LogCallback', ...
        '日志回调失败：%s', exception.message);
end
end

function [ampChangePct, phaseChangeDeg, signalName] = steadyStateCheck(run, fHz, cfg)
if ~isempty(run.vd) && rmsLocal(run.vd) > 1e-12
    signal = run.vd;
    signalName = 'vd';
elseif rmsLocal(run.vs) > 1e-12
    signal = run.vs;
    signalName = 'vs';
elseif ~isempty(run.Fd) && rmsLocal(run.Fd) > 1e-12
    signal = run.Fd;
    signalName = 'Fd';
else
    ampChangePct = NaN;
    phaseChangeDeg = NaN;
    signalName = '';
    return;
end
blockTime = cfg.steadyCheckCycles/fHz;
tEnd = run.t(end);
recent = run.t >= tEnd-blockTime;
previous = run.t >= tEnd-2*blockTime & run.t < tEnd-blockTime;
if nnz(recent) < 10 || nnz(previous) < 10
    ampChangePct = NaN;
    phaseChangeDeg = NaN;
    return;
end
recentPhasor = simplePhasor(run.t(recent), signal(recent), 2*pi*fHz);
previousPhasor = simplePhasor(run.t(previous), signal(previous), 2*pi*fHz);
ampChangePct = 100*abs(abs(recentPhasor)-abs(previousPhasor))/ ...
    max(abs(recentPhasor), 1e-12);
phaseChangeDeg = abs(rad2deg(wrapPhase(angle(recentPhasor/previousPhasor))));
end

function value = rmsLocal(signal)
value = sqrt(mean(signal(:).^2));
end

function value = simplePhasor(t, signal, omega)
tau = t(:)-t(1);
A = [ones(size(tau)), cos(omega*tau), sin(omega*tau)];
coeff = A\signal(:);
value = (coeff(2)-1i*coeff(3))*exp(-1i*omega*t(1));
end

function value = wrapPhase(value)
value = mod(value+pi, 2*pi)-pi;
end

function saveBatch(fileName, runs, cfg, sine_cases, batchManifest)
batchCfg = cfg; %#ok<NASGU>
save(fileName, 'runs', 'batchCfg', 'sine_cases', 'batchManifest', '-v7.3');
end

function tableValue = manifestTable(rows)
if isempty(rows)
    tableValue = table();
elseif isscalar(rows)
    tableValue = struct2table(rows, 'AsArray', true);
else
    tableValue = struct2table(rows);
end
end

function value = numberText(number)
value = sprintf('%.15g', number);
end

function row = manifestTemplate()
row = struct('SimulationIndex', NaN, 'CaseIndex', NaN, ...
    'ControllerIndex', NaN, 'SavedRunIndex', NaN, 'Strategy', '', ...
    'VariantLabel', '', 'Frequency_Hz', NaN, 'RoadAmplitude_m', NaN, ...
    'StopTime_s', NaN, 'TargetDt_s', NaN, 'SamplesSaved', NaN, ...
    'SamplesPerCycle', NaN, 'RawMinSamplesPerCycle', NaN, ...
    'SavedWindowStart_s', NaN, 'SavedWindowEnd_s', NaN, ...
    'SteadyCheckSignal', '', 'SteadyAmplitudeChange_pct', NaN, ...
    'SteadyPhaseChange_deg', NaN, 'Elapsed_s', NaN, 'Status', '', ...
    'Message', '', 'RawOutputFile', '');
end

function run = runTemplate()
run = struct('strategy', "", 'fHz', NaN, 't', [], 'vs', [], ...
    'as', [], 'vd', [], 'vu', [], 'Fd', [], 'cCmd', [], 'xr', [], ...
    'xu', [], 'tireDef', [], 'suspDef', []);
end
