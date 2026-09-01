function cfg = fdei_default_config(varargin)
%FDEI_DEFAULT_CONFIG Create default batch and validation configuration.
%   CFG = FDEI_DEFAULT_CONFIG returns a self-contained configuration for
%   FDEI batch simulation and Figures 1/2 analysis.  The default model path
%   is intentionally empty; callers must choose a model that belongs to the
%   current project.

mode = "all";
if nargin >= 1 && ~isempty(varargin{1})
    mode = lower(string(varargin{1}));
end

cfg = struct();

% Model, Variant, and road settings.
cfg.model = '';
cfg.variantSubsystemPath = '';
cfg.roadSelectPath = '';
cfg.roadSelectValue = '1';
cfg.controllerCases = { ...
    'Passive', 'Passive';
    'SkyHook', 'Skyhook';
    'ADD', 'ADD';
    'SH_ADD', 'SHADD'};
cfg.frequencyVariable = 'sine_freq';
cfg.amplitudeVariable = 'sine_amp';
cfg.parameterWorkspace = 'model';

% Excitation sweep.
cfg.frequencyHz = [0.5 0.7 0.8 0.9 1.0 1.1 1.2 1.4 1.6 2.0 ...
    2.5 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 ...
    15.0 17.0 20.0 25.0 30.0];
cfg.amplitudeMode = 'legacy_A_over_f';
cfg.legacyAmplitudeScale = 0.026;
cfg.constantRoadVelocityPeak_mps = 0.05;
cfg.constantRoadDisplacement_m = 0.005;
cfg.manualSineCases = zeros(0, 2);
cfg.roadAmplitudeWarningThreshold_m = 0.05;

% Simulation timing and steady-state retention.
cfg.minimumSettlingTime_s = 12;
cfg.transientCycles = 6;
cfg.savedCycles = 12;
cfg.validatorLastNCycles = 10;
cfg.samplesPerCycle = 120;
cfg.maxUniformSampleTime_s = 2e-3;
cfg.minimumRawSamplesPerCycle = 50;
cfg.enforceSolverStep = true;
cfg.steadyCheckCycles = 3;
cfg.steadyAmplitudeTolerance_pct = 2.0;
cfg.steadyPhaseTolerance_deg = 2.0;

% Signal access.
cfg.signalSource = 'logsout';
cfg.logsoutVariable = 'logsout';
cfg.timeVariable = 'tout';
cfg.signal = struct( ...
    'vs', 'simout:state(:,1)', ...
    'as', 'as', ...
    'vd', 'v_def', ...
    'vu', 'simout:state(:,3)', ...
    'Fd', 'simout:F_cmd', ...
    'cCmd', '', ...
    'xr', 'simout:xr', ...
    'xu', 'xu', ...
    'tireDef', 'x_tire', ...
    'suspDef', 'x_def');
cfg.cCmdInterpolation = 'previous';
cfg.otherInterpolation = 'linear';
cfg.optionalSignalMissingPolicy = 'warning';

% Result persistence and execution behavior.
cfg.outputDir = fullfile(pwd, 'FDEI_batch_results');
cfg.outputMatName = 'FDEI_batch_runs.mat';
cfg.manifestCsvName = 'FDEI_batch_manifest.csv';
cfg.checkpointMatName = 'FDEI_batch_checkpoint.mat';
cfg.saveCheckpoint = true;
cfg.saveRawSimulationOutputs = false;
cfg.stopOnError = true;
cfg.assignRunsToBase = false;
cfg.closeModelWhenDone = false;

% Validation and plotting settings.
cfg.cMin = 1000;
cfg.cMax = 2000;
cfg.ks = 20000;
cfg.alpha = 2*pi*1.41;
cfg.vdToCanonicalSign = 1;
cfg.forceToCanonicalSign = 1;
cfg.forceInputMode = 'control_increment';
cfg.forceBaselineDamping = 0.5*(cfg.cMax + cfg.cMin);
cfg.switchPolarity = -1;
cfg.zeroSwitchState = -1;
cfg.analysisStartTime = NaN;
cfg.analysisEndTime = Inf;
cfg.lastNCycles = 10;
cfg.harmonicOrder = 9;
cfg.minSamplesPerCycle = 25;
cfg.smallSignalRelTol = 1e-6;
cfg.boundaryRelTol = 1e-4;
cfg.selectedStrategies = "all";
cfg.selectedFrequencies_Hz = [];
cfg.batchOutputDir = cfg.outputDir;
cfg.batchResultFile = fullfile(cfg.outputDir, cfg.outputMatName);
cfg.batchResultFiles = {};
cfg.autoDetectBatchResult = true;
cfg.useCheckpointIfFinalMissing = true;
cfg.importBatchTiming = true;
cfg.makePlots = false;
cfg.saveResults = false;
cfg.saveFigures = true;
cfg.plotSelection = "figures12";
cfg.analysisOutputDir = fullfile(pwd, 'FDEI_validation_results');

switch mode
    case {"all", "batch", "analysis"}
        % Keep one shared schema.  A mode argument is provided for callers
        % that want a semantic hint without creating two incompatible cfgs.
    otherwise
        error('fdei_default_config:InvalidMode', ...
            '模式必须是 all、batch 或 analysis。');
end
end
