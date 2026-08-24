classdef calculate_band_rms_universalTest < matlab.unittest.TestCase
    %CALCULATE_BAND_RMS_UNIVERSALTEST 频带RMS数值和错误处理测试。

    methods (TestClassSetup)
        function addProjectSourceToPath(testCase)
            project_root = fileparts(fileparts(mfilename('fullpath')));
            source_root = fullfile(project_root, 'src');
            fixture = matlab.unittest.fixtures.PathFixture(source_root, ...
                IncludingSubfolders=true);
            testCase.applyFixture(fixture);
        end
    end

    methods (Test)
        function testPureTonesFallIntoExpectedBands(testCase)
            [time_vector, sample_rate_hz] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            signal_data = [sin(2*pi*1*time_vector), ...
                sin(2*pi*5*time_vector), sin(2*pi*12*time_vector)];
            config = calculate_band_rms_universalTest.makeConfig();

            actual = calculate_band_rms_universal(signal_data, time_vector, ...
                {'1 Hz', '5 Hz', '12 Hz'}, config);

            expected_diagonal = repmat(1/sqrt(2), 3, 1);
            actual_diagonal = diag(actual);
            off_diagonal = actual - diag(actual_diagonal);
            testCase.verifyEqual(sample_rate_hz, 200, AbsTol=1e-12);
            testCase.verifyEqual(actual_diagonal, expected_diagonal, RelTol=0.03);
            testCase.verifyLessThan(max(abs(off_diagonal), [], 'all'), 0.02);
        end

        function testMixtureMatchesTheoreticalBandRms(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            signal_data = sin(2*pi*1*time_vector) + ...
                2*sin(2*pi*5*time_vector) + 0.5*sin(2*pi*12*time_vector);
            config = calculate_band_rms_universalTest.makeConfig();

            actual = calculate_band_rms_universal(signal_data, time_vector, ...
                {'Mixture'}, config);

            expected = [1, 2, 0.5] / sqrt(2);
            testCase.verifyEqual(actual, expected, RelTol=0.03);
        end

        function testConstantDetrendRejectsDcOffset(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            signal_data = 7 + sin(2*pi*5*time_vector);
            config = calculate_band_rms_universalTest.makeConfig();

            actual = calculate_band_rms_universal(signal_data, time_vector, ...
                {'Offset signal'}, config);

            testCase.verifyLessThan(actual(1), 0.02);
            testCase.verifyEqual(actual(2), 1/sqrt(2), RelTol=0.03);
            testCase.verifyLessThan(actual(3), 0.02);
        end

        function testAdjacentBandPowersPartitionCombinedRange(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            signal_data = sin(2*pi*1*time_vector) + ...
                2*sin(2*pi*5*time_vector) + 0.5*sin(2*pi*12*time_vector);
            config = calculate_band_rms_universalTest.makeConfig();
            combined_config = config;
            combined_config.band_rms.names = {'B1-B3'};
            combined_config.band_rms.ranges_hz = [0.5, 20];

            [~, ~, separate_power] = calculate_band_rms_universal( ...
                signal_data, time_vector, {'Mixture'}, config);
            [~, ~, combined_power] = calculate_band_rms_universal( ...
                signal_data, time_vector, {'Mixture'}, combined_config);

            testCase.verifyEqual(sum(separate_power, 2), combined_power, ...
                AbsTol=1e-12);
        end

        function testNonfiniteSignalErrors(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(10, 200);
            signal_data = sin(2*pi*5*time_vector);
            signal_data(100) = NaN;
            config = calculate_band_rms_universalTest.makeConfig();

            operation = @() calculate_band_rms_universal( ...
                signal_data, time_vector, {'NaN signal'}, config);

            testCase.verifyError(operation, ...
                'calculate_band_rms_universal:NonFiniteSignal');
        end

        function testNonuniformTimeErrors(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(10, 200);
            time_vector(1000) = time_vector(1000) + 0.002;
            signal_data = sin(2*pi*5*time_vector);
            config = calculate_band_rms_universalTest.makeConfig();

            operation = @() calculate_band_rms_universal( ...
                signal_data, time_vector, {'Nonuniform'}, config);

            testCase.verifyError(operation, ...
                'calculate_band_rms_universal:NonuniformTime');
        end

        function testBandAboveNyquistErrors(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 30);
            signal_data = sin(2*pi*5*time_vector);
            config = calculate_band_rms_universalTest.makeConfig();

            operation = @() calculate_band_rms_universal( ...
                signal_data, time_vector, {'Low sample rate'}, config);

            testCase.verifyError(operation, ...
                'calculate_band_rms_universal:BandExceedsNyquist');
        end

        function testZeroBaselineWarns(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            signal_data = [zeros(size(time_vector)), sin(2*pi*5*time_vector)];
            config = calculate_band_rms_universalTest.makeConfig();

            operation = @() calculate_band_rms_universal( ...
                signal_data, time_vector, {'Zero', 'Signal'}, config);

            testCase.verifyWarning(operation, ...
                'calculate_band_rms_universal:ZeroBaseline');
        end

        function testZeroBaselineReturnsNaNRelativeValues(testCase)
            fixture = matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                'calculate_band_rms_universal:ZeroBaseline');
            testCase.applyFixture(fixture);
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            signal_data = [zeros(size(time_vector)), sin(2*pi*5*time_vector)];
            config = calculate_band_rms_universalTest.makeConfig();

            [~, relative_percentages] = calculate_band_rms_universal( ...
                signal_data, time_vector, {'Zero', 'Signal'}, config);

            testCase.verifyTrue(all(isnan(relative_percentages), 'all'));
        end

        function testFirstDisplayedDatasetIsBaseline(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            mixture = sin(2*pi*1*time_vector) + sin(2*pi*5*time_vector) + ...
                sin(2*pi*12*time_vector);
            signal_data = [2*mixture, mixture];
            config = calculate_band_rms_universalTest.makeConfig();
            config.data_order_list = [2, 1];

            [~, relative_percentages, ~, metadata] = ...
                calculate_band_rms_universal( ...
                signal_data, time_vector, {'Double', 'Baseline'}, config);

            testCase.verifyEqual(metadata.display_order, [2, 1]);
            testCase.verifyEqual(metadata.baseline_index, 2);
            testCase.verifyEqual(relative_percentages(2, :), ...
                [100, 100, 100], AbsTol=1e-10);
            testCase.verifyEqual(relative_percentages(1, :), ...
                [200, 200, 200], RelTol=1e-10);
        end

        function testFirstIndexMappingDefinesBaselineAfterCustomOrder(testCase)
            [time_vector, ~] = ...
                calculate_band_rms_universalTest.makeTimeVector(60, 200);
            mixture = sin(2*pi*1*time_vector) + sin(2*pi*5*time_vector) + ...
                sin(2*pi*12*time_vector);
            signal_data = [2*mixture, mixture, 3*mixture];
            config = calculate_band_rms_universalTest.makeConfig();
            config.data_order_list = [3, 1, 2];
            config.data_order_mapping = struct('first_index', 2);

            [~, relative_percentages, ~, metadata] = ...
                calculate_band_rms_universal( ...
                signal_data, time_vector, {'Double', 'Baseline', 'Triple'}, ...
                config);

            testCase.verifyEqual(metadata.display_order, [2, 3, 1]);
            testCase.verifyEqual(metadata.baseline_index, 2);
            testCase.verifyEqual(relative_percentages(2, :), ...
                [100, 100, 100], AbsTol=1e-10);
            testCase.verifyEqual(relative_percentages(1, :), ...
                [200, 200, 200], RelTol=1e-10);
            testCase.verifyEqual(relative_percentages(3, :), ...
                [300, 300, 300], RelTol=1e-10);
        end
    end

    methods (Static, Access = private)
        function config = makeConfig()
            config = suspension_analysis_config('quarter');
            config.band_rms.segment_duration_seconds = 20;
            config.band_rms.overlap_ratio = 0.5;
        end

        function [time_vector, sample_rate_hz] = makeTimeVector(duration_seconds, sample_rate_hz)
            time_vector = (0:1/sample_rate_hz: ...
                duration_seconds - 1/sample_rate_hz).';
        end
    end
end
