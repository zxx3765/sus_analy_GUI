function export_plot_data(plot_data, signal_info, labels, config, plot_type)
%% 通用绘图数据导出函数 - Origin兼容格式
% 用于将绘图数据导出到workspace或保存为.mat文件
% 导出格式经过优化，可直接导入到Origin等绘图软件
%
% 输入参数:
%   plot_data: 绘图数据结构体
%   signal_info: 信号信息 {name, source, index, cn_label, en_label, unit}
%   labels: 数据标签
%   config: 配置结构体
%   plot_type: 绘图类型 ('frequency', 'time', 'rms', 'peak', 'stat')

% 检查是否需要导出数据
if ~config.save_to_workspace && ~config.save_mat_files
    return;
end

% 获取信号名称和标签
signal_name = signal_info{1};
clean_signal_name = regexprep(signal_name, '[^a-zA-Z0-9_]', '_');

% 清理标签名称，使其适合作为变量名
clean_labels = cell(size(labels));
for i = 1:length(labels)
    % 将中文和特殊字符替换为英文或下划线
    clean_label = labels{i};
    % 常见的中文控制策略名称映射
    label_map = containers.Map({...
        '被动悬架', '主动悬架', '天棚控制', '天棚观测器', 'PID控制', ...
        'LQR控制', '模糊控制', '神经网络', 'H∞控制', '自适应控制'}, {...
        'Passive', 'Active', 'Skyhook', 'SH_Observer', 'PID', ...
        'LQR', 'Fuzzy', 'NeuralNet', 'H_inf', 'Adaptive'});

    if isKey(label_map, clean_label)
        clean_label = label_map(clean_label);
    else
        % 通用清理：去除特殊字符，替换为下划线
        clean_label = regexprep(clean_label, '[^\w]', '_');
        clean_label = regexprep(clean_label, '_+', '_');  % 合并多个下划线
        clean_label = regexprep(clean_label, '^_|_$', ''); % 去除首尾下划线
    end
    clean_labels{i} = clean_label;
end

% 根据不同的绘图类型创建Origin友好的数据矩阵
switch lower(plot_type)
    case 'frequency'
        % 频率响应数据: [频率, 数据1, 数据2, ...]
        if isfield(plot_data, 'Mag_matrix') && isfield(plot_data, 'f_freq')
            freq_data = plot_data.f_freq(:);  % 确保为列向量
            mag_data = plot_data.Mag_matrix';  % 转置使每列对应一个数据集

            % 创建完整的数据矩阵
            export_matrix = [freq_data, mag_data];

            % 创建列名
            col_names = ['Frequency', clean_labels];

            % 导出数据
            export_to_origin_format(export_matrix, col_names, clean_signal_name, 'freq', config);
        end

    case 'time'
        % 时域数据: [时间, 数据1, 数据2, ...]
        if isfield(plot_data, 'signal_data') && isfield(plot_data, 'time_vector')
            time_data = plot_data.time_vector(:);  % 确保为列向量
            signal_data = plot_data.signal_data;   % 应该已经是正确格式

            % 创建完整的数据矩阵
            export_matrix = [time_data, signal_data];

            % 创建列名
            col_names = ['Time', clean_labels];

            % 导出数据
            export_to_origin_format(export_matrix, col_names, clean_signal_name, 'time', config);
        end

    case 'rms'
        % RMS数据: 创建两个矩阵，一个是绝对值，一个是相对百分比
        if isfield(plot_data, 'rms_values')
            % RMS绝对值矩阵 [n_datasets x 1]
            rms_matrix = plot_data.rms_values(:);
            export_to_origin_format(rms_matrix, clean_labels', clean_signal_name, 'rms_abs', config, true);

            % RMS相对百分比矩阵
            if isfield(plot_data, 'relative_percentages')
                rel_matrix = plot_data.relative_percentages(:);
                export_to_origin_format(rel_matrix, clean_labels', clean_signal_name, 'rms_rel', config, true);
            end
        end

    case 'peak'
        % 峰值数据: 类似RMS格式
        if isfield(plot_data, 'peak_values')
            % 峰值绝对值矩阵
            peak_matrix = plot_data.peak_values(:);
            export_to_origin_format(peak_matrix, clean_labels', clean_signal_name, 'peak_abs', config, true);

            % 峰值相对百分比矩阵
            if isfield(plot_data, 'relative_percentages')
                rel_matrix = plot_data.relative_percentages(:);
                export_to_origin_format(rel_matrix, clean_labels', clean_signal_name, 'peak_rel', config, true);
            end
        end

    case 'stat'
        % 统计数据: 创建统计矩阵 [n_datasets x n_stats]
        if isfield(plot_data, 'stats_data')
            stats = plot_data.stats_data;
            stat_fields = {'mean', 'std', 'max', 'min', 'rms'};
            stat_names = {'Mean', 'Std', 'Max', 'Min', 'RMS'};

            % 创建统计数据矩阵
            n_datasets = length(clean_labels);
            n_stats = length(stat_fields);
            stats_matrix = zeros(n_datasets, n_stats);

            for i = 1:n_stats
                if isfield(stats, stat_fields{i})
                    stats_matrix(:, i) = stats.(stat_fields{i})(:);
                end
            end

            % 导出统计矩阵
            export_to_origin_format(stats_matrix, stat_names, clean_signal_name, 'stats', config, false, clean_labels);
        end
end

end

function export_to_origin_format(data_matrix, col_names, signal_name, data_type, config, is_bar_data, row_names)
%% 导出Origin友好格式的数据
%
% 输入:
%   data_matrix: 要导出的数据矩阵
%   col_names: 列名称（cell数组）
%   signal_name: 信号名称
%   data_type: 数据类型标识
%   config: 配置结构体
%   is_bar_data: 是否为柱状图数据（可选，默认false）
%   row_names: 行名称（可选，用于统计数据）

if nargin < 6, is_bar_data = false; end
if nargin < 7, row_names = {}; end

% 生成变量名
var_name = sprintf('%s_%s', signal_name, data_type);

% 保存到workspace
if config.save_to_workspace
    try
        % 将数据矩阵直接保存到workspace，变量名包含列信息
        assignin('base', var_name, data_matrix);

        % 同时保存列名信息
        col_var_name = sprintf('%s_columns', var_name);
        assignin('base', col_var_name, col_names);

        % 如果有行名，也保存
        if ~isempty(row_names)
            row_var_name = sprintf('%s_rows', var_name);
            assignin('base', row_var_name, row_names);
        end

        fprintf('  绘图数据已保存到workspace:\n');
        fprintf('    - 数据矩阵: %s (%dx%d)\n', var_name, size(data_matrix,1), size(data_matrix,2));
        fprintf('    - 列名: %s\n', col_var_name);
        if ~isempty(row_names)
            fprintf('    - 行名: %s\n', row_var_name);
        end

    catch ME
        fprintf('  警告：无法保存到workspace: %s\n', ME.message);
    end
end

% 保存为.mat文件
if config.save_mat_files && config.save_plots
    try
        % 创建文件名
        if strcmp(config.language, 'cn')
            filename = sprintf('%s_%s_Origin数据.mat', signal_name, data_type);
        else
            filename = sprintf('%s_%s_Origin_data.mat', signal_name, data_type);
        end

        filepath = fullfile(config.output_folder, filename);

        % 准备保存的数据结构
        save_data = struct();
        save_data.data = data_matrix;
        save_data.columns = col_names;
        if ~isempty(row_names)
            save_data.rows = row_names;
        end
        save_data.signal_name = signal_name;
        save_data.data_type = data_type;
        save_data.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        save_data.usage_note = 'Import "data" matrix to Origin. Column names in "columns" variable.';

        % 同时保存单独的数据矩阵变量（方便Origin直接识别）
        eval([var_name ' = data_matrix;']);
        eval([col_var_name ' = col_names;']);
        if ~isempty(row_names)
            eval([row_var_name ' = row_names;']);
        end

        % 保存文件
        if ~isempty(row_names)
            save(filepath, 'save_data', var_name, col_var_name, row_var_name);
        else
            save(filepath, 'save_data', var_name, col_var_name);
        end

        fprintf('  Origin兼容数据已保存: %s\n', filepath);
        fprintf('    - 导入到Origin时请选择变量: %s\n', var_name);

    catch ME
        fprintf('  警告：无法保存.mat文件: %s\n', ME.message);
    end
end

end