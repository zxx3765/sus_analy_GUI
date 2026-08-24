classdef batch_algorithm_config_utilsTest < matlab.unittest.TestCase
    %BATCH_ALGORITHM_CONFIG_UTILSTEST 算法清单纯逻辑测试。

    methods (Test)
        function testValidStrictConfig(testCase)
            config = struct('schema_version', 1, ...
                'algorithms', makeAlgorithms({'Passive'}, {'Passive'}));
            [ok, message, algorithms, configState] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(algorithms(1).display_name, 'Passive');
            testCase.verifyEqual(configState.schema_version, 1);
            testCase.verifyEmpty(configState.model_file);
        end

        function testVersionTwoPersistsModelFile(testCase)
            config = struct('schema_version', 2, ...
                'model_file', "D:\models\current.slx", ...
                'algorithms', makeAlgorithms({'Passive'}, {'Passive'}));
            [ok, message, ~, configState] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(configState.schema_version, 2);
            testCase.verifyEqual(configState.model_file, ...
                'D:\models\current.slx');

            config = rmfield(config, 'model_file');
            [ok, message] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, 'model_file');

            config.model_file = 123;
            [ok, message] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, 'model_file');
        end

        function testVersionTwoMatRoundTrip(testCase)
            algorithms = makeAlgorithms({'Passive'}, {'Passive'});
            batch_algorithm_config = struct('schema_version', 2, ...
                'model_file', 'D:\models\MovedModel.slx', ...
                'algorithms', algorithms); %#ok<NASGU>
            matFile = [tempname '.mat'];
            cleanup = onCleanup(@() deleteIfPresent(matFile)); %#ok<NASGU>
            save(matFile, 'batch_algorithm_config', '-mat');
            loaded = load(matFile, 'batch_algorithm_config');

            [ok, message, restoredAlgorithms, configState] = ...
                batch_algorithm_config_utils('validateconfig', ...
                loaded.batch_algorithm_config);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(configState.model_file, ...
                'D:\models\MovedModel.slx');
            testCase.verifyEqual(restoredAlgorithms, algorithms);
        end

        function testRejectsBadSchema(testCase)
            config = struct('schema_version', '1', ...
                'algorithms', makeAlgorithms({'Passive'}, {'Passive'}));
            [ok, message] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, 'schema_version');
        end

        function testRejectsBadImportedFieldTypes(testCase)
            algorithms = makeAlgorithms({'Passive'}, {'Passive'});
            algorithms.enabled = 'true';
            config = struct('schema_version', 1, 'algorithms', algorithms);
            [ok, message] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, 'enabled');

            algorithms = makeAlgorithms({'Passive'}, {'Passive'});
            algorithms.display_name = 7;
            config.algorithms = algorithms;
            [ok, message] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, 'display_name');
        end

        function testRejectsMissingString(testCase)
            algorithms = makeAlgorithms({'Passive'}, {'Passive'});
            algorithms.display_name = string(missing);
            config = struct('schema_version', 1, 'algorithms', algorithms);
            [ok, message] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, 'display_name');
        end

        function testRejectsNormalizedOutputConflict(testCase)
            algorithms = makeAlgorithms({'A-B', 'A_B'}, {'A-B', 'A_B'});
            [ok, message] = batch_algorithm_config_utils( ...
                'validate', algorithms, true, false);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, '重复');
        end

        function testAppendSkipsOnlyCurrentConflicts(testCase)
            current = makeAlgorithms({'Passive'}, {'Passive'});
            incoming = makeAlgorithms({'Passive', 'NewAlgorithm'}, ...
                {'Passive', 'NewAlgorithm'});
            [ok, message, merged, skipped] = ...
                batch_algorithm_config_utils('mergeappend', current, incoming);
            testCase.verifyTrue(ok, message);
            testCase.verifySize(merged, [2, 1]);
            testCase.verifySize(skipped, [1, 1]);
            testCase.verifyEqual(skipped(1).display_name, 'Passive');
            testCase.verifyEqual(skipped(1).output_name, 'out_Passive');
        end

        function testIncomingSelfConflictRemainsAtomic(testCase)
            current = makeAlgorithms({'Passive'}, {'Passive'});
            incoming = makeAlgorithms({'A-B', 'A_B'}, {'A-B', 'A_B'});
            [ok, ~, merged, skipped] = ...
                batch_algorithm_config_utils('mergeappend', current, incoming);
            testCase.verifyFalse(ok);
            testCase.verifyEqual(merged, current);
            testCase.verifyEmpty(skipped);
        end

        function testExtraFieldsNormalizeAndAppend(testCase)
            incoming = makeAlgorithms({'NewAlgorithm'}, {'NewAlgorithm'});
            incoming.description = 'metadata';
            config = struct('schema_version', 1, 'algorithms', incoming);
            [ok, message, normalized] = batch_algorithm_config_utils( ...
                'validateconfig', config);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(fieldnames(normalized), ...
                {'enabled'; 'display_name'; 'subsystem_label'});

            current = makeAlgorithms({'Passive'}, {'Passive'});
            [ok, message, merged, skipped] = ...
                batch_algorithm_config_utils('mergeappend', current, incoming);
            testCase.verifyTrue(ok, message);
            testCase.verifyEmpty(skipped);
            testCase.verifySize(merged, [2, 1]);
            testCase.verifyEqual(fieldnames(merged), ...
                {'enabled'; 'display_name'; 'subsystem_label'});
        end
    end
end

function algorithms = makeAlgorithms(displayNames, subsystemNames)
algorithms = repmat(struct('enabled', true, 'display_name', '', ...
    'subsystem_label', ''), numel(displayNames), 1);
for i = 1:numel(displayNames)
    algorithms(i).display_name = displayNames{i};
    algorithms(i).subsystem_label = subsystemNames{i};
end
end

function deleteIfPresent(fileName)
if isfile(fileName)
    delete(fileName);
end
end
