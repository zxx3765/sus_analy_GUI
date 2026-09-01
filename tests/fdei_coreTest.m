classdef fdei_coreTest < matlab.unittest.TestCase
    %FDEI_CORETEST Public FDEI configuration and analysis interfaces.

    methods (Test)
        function testAmplitudeModesAndCaseGeneration(testCase)
            cfg = fdei_default_config('batch');
            cfg.frequencyHz = [1 2];
            cfg.amplitudeMode = 'legacy_A_over_f';
            cases = fdei_build_cases(cfg);
            testCase.verifyEqual(cases, [1 0.026; 2 0.013], 'AbsTol', 1e-12);

            cfg.amplitudeMode = 'constant_velocity';
            cfg.constantRoadVelocityPeak_mps = 0.1;
            cases = fdei_build_cases(cfg);
            testCase.verifyEqual(cases(:,2), [0.1/(2*pi); 0.1/(4*pi)], ...
                'AbsTol', 1e-12);

            cfg.amplitudeMode = 'manual';
            cfg.manualSineCases = [1 0.01; 3 0.005];
            testCase.verifyEqual(fdei_build_cases(cfg), cfg.manualSineCases, ...
                'AbsTol', 1e-12);
        end

        function testPassiveSyntheticRunFdei(testCase)
            [runs, cfg, damping] = makePassiveRun();
            [results, summary] = fdei_analyze_runs(runs, cfg);
            testCase.verifyEqual(height(results), 1);
            testCase.verifyEqual(results.Ceq_Damper_NsPm, damping, 'AbsTol', 1e-6);
            testCase.verifyEqual(results.Beq_Damper_kg, 0, 'AbsTol', 1e-8);
            testCase.verifyEqual(results.Keq_Damper_NPm, 0, 'AbsTol', 1e-6);
            testCase.verifyEqual(results.Ceq_Total_NsPm, damping, 'AbsTol', 1e-6);
            testCase.verifyEqual(results.Keq_Total_NPm, cfg.ks, 'AbsTol', 1e-5);
            testCase.verifyEqual(height(summary), 1);
        end

        function testInvalidAmplitudeModeIsRejected(testCase)
            cfg = fdei_default_config('batch');
            cfg.amplitudeMode = 'unknown_mode';
            testCase.verifyError(@() fdei_build_cases(cfg), ...
                'fdei_build_cases:InvalidAmplitudeMode');
        end

        function testInvalidAnalysisConfigurationIsRejected(testCase)
            [runs, cfg] = makePassiveRun();
            cfg.cMax = cfg.cMin;
            testCase.verifyError(@() fdei_analyze_runs(runs, cfg), ...
                'fdei_analyze_runs:InvalidDampingRange');
        end

        function testAlgorithmAliasConflictIsRemoved(testCase)
            testCase.verifyEqual(fdei_canonical_algorithm_name('CRFRSas_c'), 'CRFRSas_c');
            testCase.verifyEqual(fdei_canonical_algorithm_name('CRFRSvs_c'), 'CRFRSvs_c');
            testCase.verifyError(@() fdei_canonical_algorithm_name('acctive'), ...
                'fdei_canonical_algorithm_name:UnknownAlgorithm');
        end

        function testMissingRelativeVelocityMappingIsRejected(testCase)
            cfg = fdei_default_config('batch');
            cfg.variantSubsystemPath = 'QuarterCar/Controller';
            cfg.roadSelectPath = 'QuarterCar/RoadSelect';
            cfg.signal.vd = '';
            cfg.signal.vu = '';
            testCase.verifyError(@() fdei_validate_batch_config(cfg, false), ...
                'fdei_validate_batch_config:MissingRelativeVelocity');
        end

        function testOptionalPartnerSignalMayBeMissing(testCase)
            [simOut, cfg] = makeExtractionInput();
            warningState = warning('off', 'fdei_extract_run:OptionalSignal');
            testCase.addTeardown(@() warning(warningState));
            run = fdei_extract_run(simOut, 'Passive', 1, cfg, 0.01);
            testCase.verifyNotEmpty(run.vd);
            testCase.verifyEmpty(run.vu);
            testCase.verifyNotEmpty(run.Fd);
        end

        function testManualCaseTextParsing(testCase)
            cases = fdei_config_utils('parsemanualcases', ...
                '[1, 0.01; 3 0.005]');
            testCase.verifyEqual(cases, [1 0.01; 3 0.005], ...
                'AbsTol', 1e-12);
        end

        function testFigures12RenderFromAnalysisResults(testCase)
            [runs, cfg] = makePassiveRun();
            results = fdei_analyze_runs(runs, cfg);
            cfg.saveFigures = false;
            figures = fdei_plot_figures12(results, cfg, 'Visible', 'off');
            testCase.addTeardown(@() deleteFigures(figures));
            testCase.verifyEqual(numel(figures), 2);
            testCase.verifyTrue(all(cellfun(@isgraphics, figures)));
        end

        function testConfigurationMatRoundTrip(testCase)
            configFile = [tempname '.mat'];
            testCase.addTeardown(@() deleteFileIfPresent(configFile));
            cfg = makeExportConfiguration();
            savedFile = fdei_save_config(configFile, cfg);
            loadedCfg = fdei_load_config(savedFile, fdei_default_config());
            testCase.verifyEqual(loadedCfg.model, cfg.model);
            testCase.verifyEqual(loadedCfg.frequencyHz, cfg.frequencyHz, ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(loadedCfg.manualSineCases, ...
                cfg.manualSineCases, 'AbsTol', 1e-12);
            testCase.verifyEqual(loadedCfg.signal.vd, cfg.signal.vd);
            testCase.verifyEqual(loadedCfg.cMin, cfg.cMin, 'AbsTol', 1e-12);
        end
    end
end

function [simOut, cfg] = makeExtractionInput()
cfg = fdei_default_config('batch');
cfg.signalSource = 'simulationoutput';
cfg.timeVariable = 'tout';
cfg.signal = struct('vs', 'vs', 'as', 'as', 'vd', 'vd', ...
    'vu', 'missingVu', 'Fd', 'Fd', 'cCmd', '', 'xr', '', 'xu', '', ...
    'tireDef', '', 'suspDef', '');
t = (0:0.01:14).';
omega = 2*pi;
simOut = struct('tout', t, 'vs', sin(omega*t), ...
    'as', omega*cos(omega*t), 'vd', 0.1*sin(omega*t), ...
    'Fd', 1500*0.1*sin(omega*t));
end

function deleteFigures(figures)
for index = 1:numel(figures)
    if isgraphics(figures{index})
        delete(figures{index});
    end
end
end

function cfg = makeExportConfiguration()
cfg = fdei_default_config();
cfg.model = 'D:\models\quarter_car.slx';
cfg.frequencyHz = [0.5 1 2.5];
cfg.amplitudeMode = 'manual';
cfg.manualSineCases = [0.5 0.02; 2.5 0.004];
cfg.signal.vd = 'relative_velocity';
cfg.cMin = 900;
end

function deleteFileIfPresent(fileName)
if exist(fileName, 'file') == 2
    delete(fileName);
end
end

function [runs, cfg, damping] = makePassiveRun()
cfg = fdei_default_config('analysis');
cfg.forceInputMode = 'total';
cfg.cMin = 1000;
cfg.cMax = 2000;
cfg.ks = 20000;
cfg.lastNCycles = 10;
cfg.harmonicOrder = 3;
cfg.minSamplesPerCycle = 20;
fHz = 2;
damping = 1500;
t = (0:0.001:10).';
omega = 2*pi*fHz;
vs = 0.2*cos(omega*t);
as = -0.2*omega*sin(omega*t);
vd = 0.05*cos(omega*t);
runs = struct('strategy', 'Passive', 'fHz', fHz, 't', t, ...
    'vs', vs, 'as', as, 'vd', vd, 'vu', vs-vd, ...
    'Fd', damping*vd, 'cCmd', [], 'xr', [], 'xu', [], ...
    'tireDef', [], 'suspDef', []);
end
