classdef batch_model_file_utilsTest < matlab.unittest.TestCase
    %BATCH_MODEL_FILE_UTILSTEST 模型文件路径解析测试。

    properties
        TemporaryDirectory
        ModelFile
    end

    methods (TestMethodSetup)
        function createTemporaryModelFile(testCase)
            testCase.TemporaryDirectory = [tempname ' folder with spaces'];
            mkdir(testCase.TemporaryDirectory);
            testCase.ModelFile = fullfile(testCase.TemporaryDirectory, ...
                'MovedModel.slx');
            fileID = fopen(testCase.ModelFile, 'w');
            testCase.assertGreaterThan(fileID, 0);
            fclose(fileID);
        end
    end

    methods (TestMethodTeardown)
        function removeTemporaryModelFile(testCase)
            if isfolder(testCase.TemporaryDirectory)
                rmdir(testCase.TemporaryDirectory, 's');
            end
        end
    end

    methods (Test)
        function testAbsolutePathWithSpaces(testCase)
            [ok, modelName, modelFile, message] = ...
                batch_model_file_utils(testCase.ModelFile, pwd);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(modelName, 'MovedModel');
            testCase.verifyEqual(modelFile, canonicalFile(testCase.ModelFile));
        end

        function testCopiedQuotedPath(testCase)
            quoted = ['"' testCase.ModelFile '"'];
            [ok, ~, modelFile, message] = ...
                batch_model_file_utils(quoted, pwd);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(modelFile, canonicalFile(testCase.ModelFile));
        end

        function testRelativePathUsesReferenceDirectory(testCase)
            [ok, ~, modelFile, message] = batch_model_file_utils( ...
                'MovedModel.slx', testCase.TemporaryDirectory);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(modelFile, canonicalFile(testCase.ModelFile));
        end

        function testExtensionCanBeOmitted(testCase)
            [ok, ~, modelFile, message] = batch_model_file_utils( ...
                'MovedModel', testCase.TemporaryDirectory);
            testCase.verifyTrue(ok, message);
            testCase.verifyEqual(modelFile, canonicalFile(testCase.ModelFile));
        end

        function testMissingPathReportsParsedInput(testCase)
            missingFile = fullfile(testCase.TemporaryDirectory, 'missing.slx');
            [ok, ~, ~, message] = batch_model_file_utils(missingFile, pwd);
            testCase.verifyFalse(ok);
            testCase.verifySubstring(message, missingFile);
            testCase.verifySubstring(message, '解析基准目录');
        end
    end
end

function value = canonicalFile(fileName)
[ok, attributes] = fileattrib(fileName);
assert(ok);
value = attributes.Name;
end
