function suspension_analysis_tool(data_sets, labels, varargin)
%% 通用悬架仿真结果分析工具
% 
% 输入参数:
%   data_sets: 仿真数据集合 (cell array 或 struct array)
%   labels: 各数据集的标签 (cell array of strings)
%   varargin: 可选参数
%     - 'ModelType': 'half' (默认), 'quarter' 或 'full'
%     - 'Config': 自定义配置结构体
%     - 'OutputFolder': 结果输出文件夹
%     - 'Language': 'cn' (默认) 或 'en'
%     - 'SavePlots': true (默认) 或 false
%
% 示例用法:
%   % 半车模型分析
%   suspension_analysis_tool({out_passive, out_skyhook}, {'Passive', 'Skyhook'});
%   
%   % 四分之一车模型分析
%   suspension_analysis_tool(quarter_data, quarter_labels, 'ModelType', 'quarter');
%   
%   % 自定义配置
%   config = suspension_analysis_config('half');
%   config.analysis.frequency_response = false; % 关闭频响分析
%   suspension_analysis_tool(data_sets, labels, 'Config', config);

%% 解析输入参数
p = inputParser;
addRequired(p, 'data_sets');
addRequired(p, 'labels');
addParameter(p, 'ModelType', 'half', @(x) any(validatestring(x, {'half', 'quarter', 'full'})));
addParameter(p, 'Config', [], @isstruct);
addParameter(p, 'OutputFolder', 'results', @ischar);
addParameter(p, 'Language', 'cn', @(x) any(validatestring(x, {'cn', 'en'})));
addParameter(p, 'SavePlots', true, @islogical);

parse(p, data_sets, labels, varargin{:});

model_type = p.Results.ModelType;
custom_config = p.Results.Config;
output_folder = p.Results.OutputFolder;
language = p.Results.Language;
save_plots = p.Results.SavePlots;

%% 加载或使用配置
if isempty(custom_config)
    config = suspension_analysis_config(model_type);
else
    config = custom_config;
end

% 更新配置 - 只有当没有提供自定义配置时才覆盖这些值
if isempty(custom_config)
    config.language = language;
    config.save_plots = save_plots;
    config.output_folder = output_folder;
else
    % 使用自定义配置，但允许参数覆盖某些设置
    if ~strcmp(language, 'cn')  % 如果明确指定了语言
        config.language = language;
    end
    if ~save_plots  % 如果明确指定不保存图片
        config.save_plots = save_plots;
    end
    % 保持自定义配置中的output_folder，不要覆盖时间戳文件夹
end

%% 验证和预处理数据
fprintf('正在验证和预处理数据...\n');
[processed_data, time_vector] = preprocess_data(data_sets, labels, config);

%% 创建输出文件夹
if config.save_plots
    if ~exist(config.output_folder, 'dir')
        try
            mkdir(config.output_folder);
            fprintf('已创建输出文件夹: %s\n', config.output_folder);
        catch ME
            warning('无法创建输出文件夹 %s: %s', config.output_folder, ME.message);
            % 尝试使用当前目录下的results文件夹
            config.output_folder = fullfile(pwd, 'results');
            if ~exist(config.output_folder, 'dir')
                mkdir(config.output_folder);
                fprintf('已在当前目录创建输出文件夹: %s\n', config.output_folder);
            end
        end
    end
    
    % 再次确认目录存在
    if ~exist(config.output_folder, 'dir')
        error('无法创建或访问输出文件夹: %s', config.output_folder);
    end
end

%% 执行各项分析
fprintf('开始执行分析...\n');

% 1. 频率响应分析
if config.analysis.frequency_response
    fprintf('  - 频率响应分析\n');
    perform_frequency_analysis(processed_data, time_vector, config);
end

% 2. 时域分析
if config.analysis.time_domain
    fprintf('  - 时域分析\n');
    perform_time_domain_analysis(processed_data, time_vector, config);
end

% 3. RMS对比分析
if config.analysis.rms_comparison
    fprintf('  - RMS对比分析\n');
    perform_rms_analysis(processed_data, config);
end

% 4. 频带RMS对比分析
if isfield(config.analysis, 'band_rms') && config.analysis.band_rms
    fprintf('  - 频带RMS对比分析\n');
    perform_band_rms_analysis(processed_data, time_vector, config);
end

% 5. 统计分析
if config.analysis.statistical
    fprintf('  - 统计分析\n');
    perform_statistical_analysis(processed_data, config);
end

% 6. 峰值对比分析
if isfield(config.analysis, 'peak_comparison') && config.analysis.peak_comparison
    fprintf('  - 峰值对比分析\n');
    perform_peak_analysis(processed_data, config);
end

% 7. 功率谱密度分析
if isfield(config.analysis, 'psd') && config.analysis.psd
    fprintf('  - 功率谱密度(PSD)分析\n');
    perform_psd_analysis(processed_data, config);
end

fprintf('分析完成！\n');
if config.save_plots
    fprintf('结果已保存至: %s\n', config.output_folder);
end

end

%% 数据预处理函数
function [processed_data, time_vector] = preprocess_data(data_sets, labels, config)

% 确保数据为cell array格式
if ~iscell(data_sets)
    if isstruct(data_sets) && length(data_sets) > 1
        temp_cell = cell(1, length(data_sets));
        for i = 1:length(data_sets)
            temp_cell{i} = data_sets(i);
        end
        data_sets = temp_cell;
    else
        data_sets = {data_sets};
    end
end

% 确保labels为cell array格式
if ~iscell(labels)
    if ischar(labels) || isstring(labels)
        labels = {labels};
    end
end

% 验证数据和标签数量匹配
if length(data_sets) ~= length(labels)
    error('数据集数量(%d)与标签数量(%d)不匹配', length(data_sets), length(labels));
end

% 提取时间向量
time_field = config.data_fields.time;

% 检查时间字段是否存在（兼容Simulink.SimulationOutput对象）
if isa(data_sets{1}, 'Simulink.SimulationOutput')
    % 对于Simulink.SimulationOutput对象，使用isprop检查属性
    if isprop(data_sets{1}, time_field) || isfield(data_sets{1}, time_field)
        time_vector = data_sets{1}.(time_field);
    else
        error('未找到时间字段: %s', time_field);
    end
else
    % 对于普通结构体，使用isfield
    if isfield(data_sets{1}, time_field)
        time_vector = data_sets{1}.(time_field);
    else
        error('未找到时间字段: %s', time_field);
    end
end

% 验证所有数据集具有相同的时间长度
for i = 1:length(data_sets)
    if length(data_sets{i}.(time_field)) ~= length(time_vector)
        warning('数据集 %d 的时间长度与第一个数据集不匹配', i);
    end
end

processed_data.datasets = data_sets;
processed_data.labels = labels;
processed_data.n_datasets = length(data_sets);
processed_data.n_samples = length(time_vector);

end

%% 频率响应分析
function perform_frequency_analysis(processed_data, time_vector, config)

for i = 1:length(config.analysis_signals)
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};
    
    % 提取信号数据
    signal_data = extract_signal_data(processed_data, data_source, signal_idx, config);
    
    % 提取路面激励数据
    road_data = extract_road_data(processed_data, config);
    
    % 绘制频率响应
    plot_frequency_response(signal_data, road_data, processed_data.labels, ...
                          signal_info, config);
end

end

%% 时域分析
function perform_time_domain_analysis(processed_data, time_vector, config)

for i = 1:length(config.analysis_signals)
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};
    
    % 提取信号数据
    signal_data = extract_signal_data(processed_data, data_source, signal_idx, config);
    
    % 绘制时域响应
    plot_time_response(signal_data, time_vector, processed_data.labels, ...
                      signal_info, config);
end

end

%% RMS分析
function perform_rms_analysis(processed_data, config)

% 收集所有信号的RMS值
rms_results = struct();

for i = 1:length(config.analysis_signals)
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};
    
    % 提取信号数据
    signal_data = extract_signal_data(processed_data, data_source, signal_idx, config);
    
    % 使用新的通用RMS计算函数
    [rms_values, relative_percentages] = calculate_rms_universal(signal_data, processed_data.labels, config);
    
    rms_results.(signal_name).rms = rms_values;
    rms_results.(signal_name).relative_percentages = relative_percentages;
    
    % 绘制RMS对比图
    [~, ~] = plot_rms_comparison_universal(rms_values, processed_data.labels, signal_info, config);
end

% 保存RMS结果
if config.save_plots
    save_path = fullfile(config.output_folder, 'rms_results.mat');
    save(save_path, 'rms_results');
end

end

%% 频带RMS分析
function perform_band_rms_analysis(processed_data, time_vector, config)

validate_band_rms_time_bases(processed_data, time_vector, config);

band_rms_results = struct();
n_signals = length(config.analysis_signals);
summary_tables = cell(n_signals, 1);

for i = 1:n_signals
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};

    % 频域计算不允许缺失样本后补零，因此使用严格长度检查。
    signal_data = extract_signal_data(processed_data, data_source, ...
        signal_idx, config, true);

    [band_rms_values, relative_percentages, band_power_values, metadata] = ...
        calculate_band_rms_universal(signal_data, time_vector, ...
        processed_data.labels, config);

    signal_result = struct();
    signal_result.band_rms = band_rms_values;
    signal_result.band_power = band_power_values;
    signal_result.relative_percentages = relative_percentages;
    signal_result.reduction_percentages = 100 - relative_percentages;
    signal_result.unit = signal_info{6};
    band_rms_results.signals.(signal_name) = signal_result;

    summary_tables{i} = create_band_rms_summary_table(signal_info, ...
        processed_data.labels, band_rms_values, relative_percentages, metadata);

    plot_band_rms_comparison_universal(band_rms_values, ...
        relative_percentages, processed_data.labels, signal_info, ...
        metadata, config);
end

band_rms_results.metadata = metadata;
band_rms_results.summary_table = vertcat(summary_tables{:});

if isfield(config, 'save_to_workspace') && config.save_to_workspace
    assignin('base', 'band_rms_results', band_rms_results);
end

if config.save_plots
    mat_path = fullfile(config.output_folder, 'band_rms_results.mat');
    csv_path = fullfile(config.output_folder, 'band_rms_results.csv');
    save(mat_path, 'band_rms_results');
    writetable(band_rms_results.summary_table, csv_path);
end

end

function validate_band_rms_time_bases(processed_data, reference_time, config)
time_field = config.data_fields.time;
reference_time = reference_time(:);
sample_interval = median(diff(reference_time));
time_tolerance = config.band_rms.time_uniformity_tolerance * sample_interval;

for dataset_index = 1:processed_data.n_datasets
    dataset_time = processed_data.datasets{dataset_index}.(time_field);
    dataset_time = dataset_time(:);
    if numel(dataset_time) ~= numel(reference_time)
        error('suspension_analysis_tool:BandRMSTimeLengthMismatch', ...
            '数据集%d的时间长度与基准数据集不一致，无法计算频带RMS。', ...
            dataset_index);
    end
    if max(abs(dataset_time - reference_time)) > time_tolerance
        error('suspension_analysis_tool:BandRMSTimeMismatch', ...
            '数据集%d的时间采样点与基准数据集不一致，初版频带RMS不自动重采样。', ...
            dataset_index);
    end
end
end

function summary_table = create_band_rms_summary_table(signal_info, ...
    dataset_labels, band_rms_values, relative_percentages, metadata)
n_datasets = size(band_rms_values, 1);
n_bands = size(band_rms_values, 2);
n_rows = n_datasets * n_bands;

signal_column = repmat({signal_info{1}}, n_rows, 1);
signal_label_column = repmat({signal_info{4}}, n_rows, 1);
unit_column = repmat({signal_info{6}}, n_rows, 1);
dataset_column = repelem(dataset_labels(:), n_bands, 1);
band_column = repmat(metadata.band_names(:), n_datasets, 1);
low_hz = repmat(metadata.ranges_hz(:, 1), n_datasets, 1);
high_hz = repmat(metadata.ranges_hz(:, 2), n_datasets, 1);
band_rms_column = reshape(band_rms_values.', [], 1);
relative_column = reshape(relative_percentages.', [], 1);
reduction_column = 100 - relative_column;

summary_table = table(signal_column, signal_label_column, dataset_column, ...
    band_column, low_hz, high_hz, unit_column, band_rms_column, ...
    relative_column, reduction_column, 'VariableNames', ...
    {'Signal', 'SignalLabel', 'Dataset', 'Band', 'LowHz', 'HighHz', ...
     'Unit', 'BandRMS', 'RelativePercent', 'ReductionPercent'});
end

%% 统计分析
function perform_statistical_analysis(processed_data, config)

stats_results = struct();

for i = 1:length(config.analysis_signals)
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};
    
    % 提取信号数据
    signal_data = extract_signal_data(processed_data, data_source, signal_idx, config);
    
    % 计算统计量
    for j = 1:processed_data.n_datasets
        data_col = signal_data(:,j);
        stats_results.(signal_name).mean(j) = mean(data_col);
        stats_results.(signal_name).std(j) = std(data_col);
        stats_results.(signal_name).max(j) = max(data_col);
        stats_results.(signal_name).min(j) = min(data_col);
        stats_results.(signal_name).rms(j) = sqrt(mean(data_col.^2));
    end
end

% 保存统计结果
if config.save_plots
    save_path = fullfile(config.output_folder, 'statistical_results.mat');
    save(save_path, 'stats_results');
end

% 显示统计摘要
display_statistical_summary(stats_results, processed_data.labels, config);

end

%% 峰值分析（柱形图，形式与RMS一致；不区分正负）
function perform_peak_analysis(processed_data, config)

peak_results = struct();

for i = 1:length(config.analysis_signals)
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};
    
    % 提取信号数据 [N x M]
    signal_data = extract_signal_data(processed_data, data_source, signal_idx, config);
    
    % 计算峰值（最大绝对值）
    [peak_values, relative_percentages] = calculate_peak_universal(signal_data, processed_data.labels, config);
    
    peak_results.(signal_name).peak = peak_values;
    peak_results.(signal_name).relative_percentages = relative_percentages;
    
    % 绘制峰值对比柱形图
    [~, ~] = plot_peak_comparison_universal(peak_values, processed_data.labels, signal_info, config);
end

% 保存峰值结果
if config.save_plots
    save_path = fullfile(config.output_folder, 'peak_results.mat');
    save(save_path, 'peak_results');
end

end

%% 辅助函数：提取信号数据
function signal_data = extract_signal_data(processed_data, data_source, signal_idx, config, strict_length)

if nargin < 5
    strict_length = false;
end

field_name = config.data_fields.(data_source);
n_samples = processed_data.n_samples;
n_datasets = processed_data.n_datasets;
signal_data = zeros(n_samples, n_datasets);

for i = 1:n_datasets
    dataset = processed_data.datasets{i};
    
    % 检查字段是否存在（兼容Simulink.SimulationOutput对象）
    field_exists = false;
    if isa(dataset, 'Simulink.SimulationOutput')
        field_exists = isprop(dataset, field_name) || isfield(dataset, field_name);
    else
        field_exists = isfield(dataset, field_name);
    end
    
    if field_exists
        data_matrix = dataset.(field_name);
        if size(data_matrix, 2) >= signal_idx
            if strict_length && size(data_matrix, 1) ~= n_samples
                error('suspension_analysis_tool:BandRMSSignalLengthMismatch', ...
                    ['数据集%d的字段%s包含%d个样本，期望%d个；' ...
                     '频带RMS不会对缺失样本补零。'], ...
                    i, field_name, size(data_matrix, 1), n_samples);
            end
            % 截断到n_samples长度以处理长度不一致的数据
            actual_length = min(size(data_matrix, 1), n_samples);
            signal_data(1:actual_length, i) = data_matrix(1:actual_length, signal_idx);
        else
            if strict_length
                error('suspension_analysis_tool:BandRMSSignalMissing', ...
                    '数据集%d中信号索引%d不存在。', i, signal_idx);
            else
                warning('数据集 %d 中信号索引 %d 不存在', i, signal_idx);
            end
        end
    else
        if strict_length
            error('suspension_analysis_tool:BandRMSFieldMissing', ...
                '数据集%d中未找到字段: %s。', i, field_name);
        else
            warning('数据集 %d 中未找到字段: %s', i, field_name);
        end
    end
end

end

%% 辅助函数：提取路面数据
function road_data = extract_road_data(processed_data, config)

% 根据模型类型提取路面数据
if strcmp(config.model_type, 'half')
    % 半车模型使用前轮路面输入
    road_data = extract_signal_data(processed_data, 'road_input', config.road.front_input, config);
elseif strcmp(config.model_type, 'quarter')
    % 四分之一车模型
    road_data = extract_signal_data(processed_data, 'road_input', config.road.input, config);
elseif strcmp(config.model_type, 'full')
    % 整车模型使用左前轮路面输入作为频响参考
    road_data = extract_signal_data(processed_data, 'road_input', config.road.lf_input, config);
end

end

%% 绘图函数
function plot_frequency_response(signal_data, road_data, labels, signal_info, config)
% 频率响应绘图实现 - 使用优化后的函数
fprintf('  绘制频率响应: %s\n', signal_info{1});
[Mag_matrix, f_freq] = plot_frequency_response_universal(signal_data, road_data, labels, signal_info, config);
end

function plot_time_response(signal_data, time_vector, labels, signal_info, config)
% 时域响应绘图实现 - 使用优化后的函数
fprintf('  绘制时域响应: %s\n', signal_info{1});
plot_time_response_universal(signal_data, time_vector, labels, signal_info, config);
end

function plot_rms_comparison(rms_values, labels, signal_info, config)
% RMS对比绘图实现 - 使用优化后的函数
fprintf('  绘制RMS对比: %s\n', signal_info{1});
[~, ~] = plot_rms_comparison_universal(rms_values, labels, signal_info, config);
end

%% PSD分析
function perform_psd_analysis(processed_data, config)

for i = 1:length(config.analysis_signals)
    signal_info = config.analysis_signals{i};
    signal_name = signal_info{1};
    data_source = signal_info{2};
    signal_idx = signal_info{3};

    % 提取信号数据
    signal_data = extract_signal_data(processed_data, data_source, signal_idx, config);

    % 绘制PSD
    plot_psd(signal_data, processed_data.labels, signal_info, config);
end

end

function plot_psd(signal_data, labels, signal_info, config)
% PSD绘图实现
fprintf('  绘制功率谱密度: %s\n', signal_info{1});
[PSD_matrix, f_freq] = plot_psd_universal(signal_data, labels, signal_info, config);
end

function display_statistical_summary(stats_results, labels, config)
% 显示统计摘要 - 使用优化后的函数
display_statistical_summary_universal(stats_results, labels, config);
end
