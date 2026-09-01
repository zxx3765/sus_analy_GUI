function cfg = fdei_validate_batch_config(cfg, varargin)
%FDEI_VALIDATE_BATCH_CONFIG Validate and normalize batch configuration.
%   CFG = FDEI_VALIDATE_BATCH_CONFIG(CFG) checks all fields needed by the
%   batch runner.  Set 'RequireModel' to false for GUI editing/preview.

requireModel = true;
if nargin > 1
    requireModel = logical(varargin{1});
end
if ~isstruct(cfg)
    error('fdei_validate_batch_config:InvalidConfig', 'cfg 必须是结构体。');
end

requiredTextFields = {'variantSubsystemPath','roadSelectPath', ...
    'frequencyVariable','amplitudeVariable','signalSource','outputDir', ...
    'roadSelectValue','outputMatName','checkpointMatName','manifestCsvName'};
for index = 1:numel(requiredTextFields)
    fieldName = requiredTextFields{index};
    requireTextField(cfg, fieldName);
end
if requireModel
    requireTextField(cfg, 'model');
end

if ~isfield(cfg, 'controllerCases') || ~iscell(cfg.controllerCases) || ...
        size(cfg.controllerCases, 2) ~= 2 || isempty(cfg.controllerCases)
    error('fdei_validate_batch_config:InvalidControllerCases', ...
        'controllerCases 必须是非空 N×2 单元数组。');
end
for index = 1:size(cfg.controllerCases, 1)
    variant = char(string(cfg.controllerCases{index, 1}));
    if isempty(strtrim(variant))
        error('fdei_validate_batch_config:InvalidVariant', ...
            'controllerCases 第 %d 行的 Variant 标签为空。', index);
    end
    cfg.controllerCases{index, 1} = variant;
    cfg.controllerCases{index, 2} = fdei_canonical_algorithm_name( ...
        cfg.controllerCases{index, 2});
end

workspaceMode = lower(strtrim(char(string(cfg.parameterWorkspace))));
if ~ismember(workspaceMode, {'model','base'})
    error('fdei_validate_batch_config:InvalidWorkspace', ...
        'parameterWorkspace 只能是 model 或 base。');
end
cfg.parameterWorkspace = workspaceMode;

if ~ismember(lower(strtrim(char(string(cfg.signalSource)))), ...
        {'logsout','simulationoutput'})
    error('fdei_validate_batch_config:InvalidSignalSource', ...
        'signalSource 只能是 logsout 或 simulationoutput。');
end
cfg.signalSource = lower(strtrim(char(string(cfg.signalSource))));
if strcmp(cfg.signalSource, 'logsout') && ...
        (~isfield(cfg, 'logsoutVariable') || ...
        strlength(strtrim(string(cfg.logsoutVariable))) == 0)
    error('fdei_validate_batch_config:MissingLogsout', ...
        'signalSource 为 logsout 时必须配置 logsoutVariable。');
end
if ~isstruct(cfg.signal)
    error('fdei_validate_batch_config:InvalidSignalConfig', ...
        'signal 必须是包含信号映射的结构体。');
end
requireSignalField(cfg.signal, 'vs');
requireSignalField(cfg.signal, 'as');
if emptySignalField(cfg.signal, 'vd') && emptySignalField(cfg.signal, 'vu')
    error('fdei_validate_batch_config:MissingRelativeVelocity', ...
        'signal.vd 与 signal.vu 至少配置一个。');
end
if emptySignalField(cfg.signal, 'Fd') && emptySignalField(cfg.signal, 'cCmd')
    error('fdei_validate_batch_config:MissingDampingForce', ...
        'signal.Fd 与 signal.cCmd 至少配置一个。');
end

optionalPolicy = lower(strtrim(char(string(cfg.optionalSignalMissingPolicy))));
if ~ismember(optionalPolicy, {'warning','error'})
    error('fdei_validate_batch_config:InvalidOptionalPolicy', ...
        'optionalSignalMissingPolicy 只能是 warning 或 error。');
end
cfg.optionalSignalMissingPolicy = optionalPolicy;

validInterpolation = {'linear','nearest','next','previous','pchip','spline','makima'};
if ~ismember(lower(strtrim(char(string(cfg.otherInterpolation)))), validInterpolation)
    error('fdei_validate_batch_config:InvalidInterpolation', ...
        'otherInterpolation 不是受支持的 interp1 插值方法。');
end
if ~ismember(lower(strtrim(char(string(cfg.cCmdInterpolation)))), validInterpolation)
    error('fdei_validate_batch_config:InvalidInterpolation', ...
        'cCmdInterpolation 不是受支持的 interp1 插值方法。');
end

positiveFields = {'minimumSettlingTime_s','transientCycles','savedCycles', ...
    'validatorLastNCycles','samplesPerCycle','maxUniformSampleTime_s', ...
    'minimumRawSamplesPerCycle', ...
    'steadyCheckCycles','steadyAmplitudeTolerance_pct', ...
    'steadyPhaseTolerance_deg'};
for index = 1:numel(positiveFields)
    validatePositiveScalar(cfg, positiveFields{index});
end
if ~isfield(cfg, 'frequencyHz')
    error('fdei_validate_batch_config:MissingFrequency', ...
        '缺少 frequencyHz。');
end
fdei_build_cases(cfg);
if cfg.savedCycles < cfg.validatorLastNCycles
    error('fdei_validate_batch_config:InsufficientSavedCycles', ...
        'savedCycles 必须不小于 validatorLastNCycles。');
end
if cfg.savedCycles < 2*cfg.steadyCheckCycles
    error('fdei_validate_batch_config:InsufficientSteadyCycles', ...
        'savedCycles 必须至少为 2*steadyCheckCycles。');
end
end

function requireTextField(cfg, fieldName)
if ~isfield(cfg, fieldName) || isempty(strtrim(char(string(cfg.(fieldName)))))
    error('fdei_validate_batch_config:MissingField', ...
        '缺少必填配置字段 %s。', fieldName);
end
end

function requireSignalField(signalCfg, fieldName)
if emptySignalField(signalCfg, fieldName)
    error('fdei_validate_batch_config:MissingSignal', ...
        '缺少或未填写必需信号映射 signal.%s。', fieldName);
end
end

function tf = emptySignalField(signalCfg, fieldName)
tf = ~isfield(signalCfg, fieldName) || ...
    strlength(strtrim(string(signalCfg.(fieldName)))) == 0;
end

function validatePositiveScalar(cfg, fieldName)
if ~isfield(cfg, fieldName) || ~(isnumeric(cfg.(fieldName)) && ...
        isscalar(cfg.(fieldName)) && isfinite(cfg.(fieldName)) && ...
        cfg.(fieldName) > 0)
    error('fdei_validate_batch_config:InvalidTiming', ...
        '%s 必须是正的有限标量。', fieldName);
end
end
