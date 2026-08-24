function [band_rms_values, relative_percentages, band_power_values, metadata] = ...
    calculate_band_rms_universal(sig_mat, time_vector, labels, config)
%% 计算多个数据集在指定频带内的RMS
% 输入:
%   sig_mat:     信号矩阵 [n_samples x n_datasets]
%   time_vector: 公共时间向量 [n_samples x 1]
%   labels:      数据集标签
%   config:      包含band_rms配置的分析配置
%
% 输出:
%   band_rms_values:     频带RMS [n_datasets x n_bands]
%   relative_percentages:相对基准百分比 [n_datasets x n_bands]
%   band_power_values:   频带功率 [n_datasets x n_bands]
%   metadata:            频带、采样率和Welch参数

validateattributes(sig_mat, {'numeric'}, {'2d', 'real', 'nonempty'}, ...
    mfilename, 'sig_mat');
validateattributes(time_vector, {'numeric'}, {'vector', 'real', 'finite'}, ...
    mfilename, 'time_vector');

time_vector = time_vector(:);
if size(sig_mat, 1) ~= numel(time_vector)
    error('calculate_band_rms_universal:LengthMismatch', ...
        '信号样本数(%d)与时间向量长度(%d)不一致。', ...
        size(sig_mat, 1), numel(time_vector));
end
if any(~isfinite(sig_mat), 'all')
    error('calculate_band_rms_universal:NonFiniteSignal', ...
        '信号数据包含NaN或Inf，无法计算频带RMS。');
end
if numel(time_vector) < 8
    error('calculate_band_rms_universal:InsufficientSamples', ...
        '频带RMS至少需要8个样本。');
end
if exist('pwelch', 'file') ~= 2
    error('calculate_band_rms_universal:MissingSignalProcessingToolbox', ...
        '频带RMS的Welch方法需要Signal Processing Toolbox中的pwelch函数。');
end

band_config = validate_band_config(config);
display_order = resolve_data_order_universal(size(sig_mat, 2), config);
[sample_rate_hz, sample_interval, relative_jitter] = ...
    validate_time_vector(time_vector, band_config.time_uniformity_tolerance);

nyquist_hz = sample_rate_hz / 2;
if max(band_config.ranges_hz(:, 2)) > nyquist_hz * (1 + 10 * eps)
    error('calculate_band_rms_universal:BandExceedsNyquist', ...
        '最高频带上限%.6g Hz超过奈奎斯特频率%.6g Hz。', ...
        max(band_config.ranges_hz(:, 2)), nyquist_hz);
end

record_duration_seconds = time_vector(end) - time_vector(1);
lowest_frequency_hz = min(band_config.ranges_hz(:, 1));
low_band_cycles = record_duration_seconds * lowest_frequency_hz;
if low_band_cycles < band_config.minimum_low_band_cycles
    warning('calculate_band_rms_universal:ShortRecord', ...
        ['记录时长%.3g s仅包含约%.2f个最低频率周期；' ...
         '低频带RMS估计可能不稳定。'], ...
        record_duration_seconds, low_band_cycles);
end

segment_length = min(size(sig_mat, 1), ...
    max(8, round(sample_rate_hz * band_config.segment_duration_seconds)));
overlap_samples = floor(segment_length * band_config.overlap_ratio);
overlap_samples = min(overlap_samples, segment_length - 1);
nfft = max(256, 2 ^ nextpow2(segment_length));
window = hann(segment_length, 'periodic');

n_datasets = size(sig_mat, 2);
n_bands = size(band_config.ranges_hz, 1);
band_power_values = zeros(n_datasets, n_bands);

for dataset_index = 1:n_datasets
    signal = sig_mat(:, dataset_index);
    if strcmpi(band_config.detrend, 'constant')
        signal = signal - mean(signal, 1);
    end

    [psd_values, frequency_hz] = pwelch(signal, window, overlap_samples, ...
        nfft, sample_rate_hz, 'onesided');

    for band_index = 1:n_bands
        band_limits = band_config.ranges_hz(band_index, :);
        band_power_values(dataset_index, band_index) = ...
            integrate_psd_band(frequency_hz, psd_values, ...
            band_limits(1), band_limits(2));
    end
end

band_power_values = max(band_power_values, 0);
band_rms_values = sqrt(band_power_values);

% 百分比基准跟随最终绘图顺序，而不是固定的原始数据下标。
baseline_index = display_order(1);
baseline_values = band_rms_values(baseline_index, :);
scale = max(1, max(band_rms_values, [], 'all'));
zero_baseline = abs(baseline_values) <= eps(scale);
relative_percentages = NaN(size(band_rms_values));
relative_percentages(:, ~zero_baseline) = ...
    100 * band_rms_values(:, ~zero_baseline) ./ baseline_values(~zero_baseline);

if any(zero_baseline)
    warning('calculate_band_rms_universal:ZeroBaseline', ...
        '基准数据集在一个或多个频带中的RMS为零；相对百分比已设为NaN。');
end

metadata = struct();
metadata.band_names = band_config.names;
metadata.ranges_hz = band_config.ranges_hz;
metadata.method = band_config.method;
metadata.detrend = band_config.detrend;
metadata.sample_rate_hz = sample_rate_hz;
metadata.sample_interval_seconds = sample_interval;
metadata.time_relative_jitter = relative_jitter;
metadata.record_duration_seconds = record_duration_seconds;
metadata.segment_length_samples = segment_length;
metadata.overlap_samples = overlap_samples;
metadata.nfft = nfft;
metadata.frequency_spacing_hz = sample_rate_hz / nfft;
metadata.display_order = display_order;
metadata.baseline_index = baseline_index;
metadata.dataset_labels = labels;

end

function band_config = validate_band_config(config)
if ~isfield(config, 'band_rms') || ~isstruct(config.band_rms)
    error('calculate_band_rms_universal:MissingConfiguration', ...
        '配置中缺少band_rms设置。');
end

band_config = config.band_rms;
required_fields = {'names', 'ranges_hz', 'method', 'detrend', ...
    'segment_duration_seconds', 'overlap_ratio', ...
    'time_uniformity_tolerance', 'minimum_low_band_cycles'};
for field_index = 1:numel(required_fields)
    field_name = required_fields{field_index};
    if ~isfield(band_config, field_name)
        error('calculate_band_rms_universal:MissingConfiguration', ...
            'band_rms配置缺少字段: %s。', field_name);
    end
end

validateattributes(band_config.ranges_hz, {'numeric'}, ...
    {'2d', 'real', 'finite', 'nonempty', 'ncols', 2}, ...
    mfilename, 'config.band_rms.ranges_hz');
if any(band_config.ranges_hz(:, 1) < 0) || ...
        any(band_config.ranges_hz(:, 2) <= band_config.ranges_hz(:, 1))
    error('calculate_band_rms_universal:InvalidBands', ...
        '每个频带必须满足0 <= 下限 < 上限。');
end
if any(band_config.ranges_hz(2:end, 1) < band_config.ranges_hz(1:end-1, 2))
    error('calculate_band_rms_universal:OverlappingBands', ...
        '频带必须按频率升序排列且不能重叠。');
end

if isstring(band_config.names)
    band_config.names = cellstr(band_config.names);
elseif ischar(band_config.names)
    band_config.names = {band_config.names};
end
if ~iscellstr(band_config.names) || ...
        numel(band_config.names) ~= size(band_config.ranges_hz, 1) %#ok<ISCLSTR>
    error('calculate_band_rms_universal:InvalidBandNames', ...
        '频带名称数量必须与频带范围行数一致。');
end

if ~strcmpi(band_config.method, 'welch')
    error('calculate_band_rms_universal:UnsupportedMethod', ...
        '当前仅支持Welch频谱积分方法。');
end
if ~any(strcmpi(band_config.detrend, {'constant', 'none'}))
    error('calculate_band_rms_universal:InvalidDetrend', ...
        'detrend必须为''constant''或''none''。');
end

validateattributes(band_config.segment_duration_seconds, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(band_config.overlap_ratio, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<', 1});
validateattributes(band_config.time_uniformity_tolerance, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(band_config.minimum_low_band_cycles, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});
end

function [sample_rate_hz, sample_interval, relative_jitter] = ...
    validate_time_vector(time_vector, tolerance)
time_steps = diff(time_vector);
if any(time_steps <= 0)
    error('calculate_band_rms_universal:NonIncreasingTime', ...
        '时间向量必须严格递增。');
end

sample_interval = median(time_steps);
relative_jitter = max(abs(time_steps - sample_interval)) / sample_interval;
if relative_jitter > tolerance
    error('calculate_band_rms_universal:NonuniformTime', ...
        ['时间向量不是等间隔采样：相对抖动%.3g超过容差%.3g。' ...
         '初版频带RMS不自动重采样。'], relative_jitter, tolerance);
end
sample_rate_hz = 1 / sample_interval;
end

function power_value = integrate_psd_band(frequency_hz, psd_values, low_hz, high_hz)
interior = frequency_hz > low_hz & frequency_hz < high_hz;
band_frequency = [low_hz; frequency_hz(interior); high_hz];
band_psd = interp1(frequency_hz, psd_values, band_frequency, 'linear');
power_value = trapz(band_frequency, band_psd);
end
