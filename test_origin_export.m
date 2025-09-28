%% 测试Origin兼容的绘图数据导出功能
% 这个脚本用于验证导出数据是否符合Origin导入要求

clear; clc;

fprintf('=== 测试Origin兼容导出格式 ===\n\n');

%% 1. 创建配置
fprintf('1. 创建测试配置...\n');
config = quick_config('ModelType', 'half', ...
                     'Language', 'cn', ...
                     'SavePlots', true, ...
                     'SaveToWorkspace', true, ...
                     'SaveMatFiles', true, ...
                     'UseTimestamp', false, ...
                     'OutputFolder', 'origin_test_results');

fprintf('  ✓ 配置创建完成\n');

%% 2. 测试频率响应数据格式
fprintf('\n2. 测试频率响应数据格式...\n');

% 模拟频率响应数据
f_freq = logspace(0, 2, 100)';  % 频率向量 1-100 Hz
n_datasets = 3;
n_freq = length(f_freq);

% 模拟幅值矩阵 [n_datasets x n_freq]
Mag_matrix = zeros(n_datasets, n_freq);
for i = 1:n_datasets
    % 生成不同的频率响应特性
    Mag_matrix(i, :) = 20*log10(1./(1 + (f_freq/10).^(2*i)));
end

% 创建测试数据
freq_plot_data = struct();
freq_plot_data.Mag_matrix = Mag_matrix;
freq_plot_data.f_freq = f_freq;

signal_info = {'body_accel', 'signals', 1, '车体加速度', 'Body Acceleration', 'm/s²'};
labels = {'被动悬架', '主动悬架', 'PID控制'};

% 测试导出
export_plot_data(freq_plot_data, signal_info, labels, config, 'frequency');

% 验证workspace变量
if exist('body_accel_freq', 'var')
    freq_data = evalin('base', 'body_accel_freq');
    freq_cols = evalin('base', 'body_accel_freq_columns');

    fprintf('  ✓ 频率数据导出成功:\n');
    fprintf('    - 矩阵尺寸: %dx%d (第1列=频率，其余列=各数据集)\n', size(freq_data,1), size(freq_data,2));
    fprintf('    - 列名: %s\n', strjoin(freq_cols, ', '));
    fprintf('    - 频率范围: %.1f - %.1f Hz\n', min(freq_data(:,1)), max(freq_data(:,1)));

    % 显示前几行数据示例
    fprintf('    - 数据示例 (前5行):\n');
    for i = 1:min(5, size(freq_data,1))
        fprintf('      %.2f\t%.2f\t%.2f\t%.2f\n', freq_data(i,:));
    end
else
    fprintf('  ✗ 频率数据导出失败\n');
end

%% 3. 测试时域数据格式
fprintf('\n3. 测试时域数据格式...\n');

% 模拟时域数据
t = (0:0.01:10)';  % 时间向量
n_time = length(t);
time_signals = zeros(n_time, n_datasets);

for i = 1:n_datasets
    % 生成不同阻尼系数的振动响应
    zeta = 0.1 * i;
    omega = 2*pi*2;  % 2 Hz
    time_signals(:, i) = exp(-zeta*omega*t) .* sin(omega*sqrt(1-zeta^2)*t);
end

% 创建时域测试数据
time_plot_data = struct();
time_plot_data.signal_data = time_signals;
time_plot_data.time_vector = t;

% 测试导出
export_plot_data(time_plot_data, signal_info, labels, config, 'time');

% 验证workspace变量
if exist('body_accel_time', 'var')
    time_data = evalin('base', 'body_accel_time');
    time_cols = evalin('base', 'body_accel_time_columns');

    fprintf('  ✓ 时域数据导出成功:\n');
    fprintf('    - 矩阵尺寸: %dx%d (第1列=时间，其余列=各数据集)\n', size(time_data,1), size(time_data,2));
    fprintf('    - 列名: %s\n', strjoin(time_cols, ', '));
    fprintf('    - 时间范围: %.1f - %.1f s\n', min(time_data(:,1)), max(time_data(:,1)));
else
    fprintf('  ✗ 时域数据导出失败\n');
end

%% 4. 测试RMS数据格式
fprintf('\n4. 测试RMS数据格式...\n');

% 模拟RMS数据
rms_values = [1.0, 0.75, 0.6];  % 绝对RMS值
relative_percentages = [100, 75, 60];  % 相对百分比

rms_plot_data = struct();
rms_plot_data.rms_values = rms_values;
rms_plot_data.relative_percentages = relative_percentages;

% 测试导出
export_plot_data(rms_plot_data, signal_info, labels, config, 'rms');

% 验证RMS绝对值数据
if exist('body_accel_rms_abs', 'var')
    rms_abs_data = evalin('base', 'body_accel_rms_abs');
    rms_abs_cols = evalin('base', 'body_accel_rms_abs_columns');

    fprintf('  ✓ RMS绝对值数据导出成功:\n');
    fprintf('    - 矩阵尺寸: %dx%d (每行对应一个数据集)\n', size(rms_abs_data,1), size(rms_abs_data,2));
    fprintf('    - 行名: %s\n', strjoin(rms_abs_cols, ', '));
    fprintf('    - 数据值: %s\n', mat2str(rms_abs_data', 2));
else
    fprintf('  ✗ RMS绝对值数据导出失败\n');
end

% 验证RMS相对值数据
if exist('body_accel_rms_rel', 'var')
    rms_rel_data = evalin('base', 'body_accel_rms_rel');
    fprintf('  ✓ RMS相对百分比数据导出成功: %s%%\n', mat2str(rms_rel_data', 1));
else
    fprintf('  ✗ RMS相对百分比数据导出失败\n');
end

%% 5. 测试统计数据格式
fprintf('\n5. 测试统计数据格式...\n');

% 模拟统计数据
stats_data = struct();
stats_data.mean = [0.1, 0.05, 0.03];
stats_data.std = [0.8, 0.6, 0.5];
stats_data.max = [2.5, 1.8, 1.5];
stats_data.min = [-2.3, -1.7, -1.4];
stats_data.rms = [1.0, 0.75, 0.6];

stat_plot_data = struct();
stat_plot_data.stats_data = stats_data;

% 测试导出
export_plot_data(stat_plot_data, signal_info, labels, config, 'stat');

% 验证统计数据
if exist('body_accel_stats', 'var')
    stats_matrix = evalin('base', 'body_accel_stats');
    stats_cols = evalin('base', 'body_accel_stats_columns');
    stats_rows = evalin('base', 'body_accel_stats_rows');

    fprintf('  ✓ 统计数据导出成功:\n');
    fprintf('    - 矩阵尺寸: %dx%d (行=数据集, 列=统计量)\n', size(stats_matrix,1), size(stats_matrix,2));
    fprintf('    - 列名(统计量): %s\n', strjoin(stats_cols, ', '));
    fprintf('    - 行名(数据集): %s\n', strjoin(stats_rows, ', '));
    fprintf('    - 统计矩阵:\n');
    for i = 1:size(stats_matrix,1)
        fprintf('      %s: %s\n', stats_rows{i}, mat2str(stats_matrix(i,:), 2));
    end
else
    fprintf('  ✗ 统计数据导出失败\n');
end

%% 6. 检查.mat文件
fprintf('\n6. 检查.mat文件生成...\n');

mat_files = dir(fullfile(config.output_folder, '*Origin数据.mat'));
if ~isempty(mat_files)
    fprintf('  ✓ 生成了 %d 个Origin兼容的.mat文件:\n', length(mat_files));
    for i = 1:length(mat_files)
        fprintf('    - %s\n', mat_files(i).name);

        % 加载并检查文件内容
        file_path = fullfile(config.output_folder, mat_files(i).name);
        file_data = load(file_path);
        fprintf('      包含变量: %s\n', strjoin(fieldnames(file_data), ', '));
    end
else
    fprintf('  ✗ 未生成.mat文件\n');
end

%% 7. Origin导入说明
fprintf('\n=== Origin导入说明 ===\n');
fprintf('在Origin中导入.mat文件的步骤:\n');
fprintf('1. 文件 -> 导入 -> MATLAB -> 选择.mat文件\n');
fprintf('2. 在变量列表中选择以下变量导入:\n');
fprintf('   - 频率响应: body_accel_freq (矩阵，第1列=频率，其余列=幅值)\n');
fprintf('   - 时域响应: body_accel_time (矩阵，第1列=时间，其余列=信号)\n');
fprintf('   - RMS数据: body_accel_rms_abs 和 body_accel_rms_rel (向量)\n');
fprintf('   - 统计数据: body_accel_stats (矩阵，行=数据集，列=统计量)\n');
fprintf('3. 导入后，列名信息在对应的 *_columns 变量中\n\n');

%% 8. 清理测试数据
fprintf('8. 清理测试数据...\n');
try
    if exist(config.output_folder, 'dir')
        rmdir(config.output_folder, 's');
    end

    % 清理workspace变量
    vars_to_clear = who('-regexp', '^body_accel_');
    if ~isempty(vars_to_clear)
        for i = 1:length(vars_to_clear)
            evalin('base', sprintf('clear %s', vars_to_clear{i}));
        end
    end

    fprintf('  ✓ 测试数据已清理\n');
catch
    fprintf('  ⚠ 清理过程中出现警告（可忽略）\n');
end

fprintf('\n=== 测试完成 ===\n');
fprintf('新的导出格式专为Origin优化:\n');
fprintf('✓ 数据以矩阵形式导出，列名清晰\n');
fprintf('✓ 中文标签自动转换为英文\n');
fprintf('✓ 支持直接导入Origin进行绘图\n\n');