%% 测试绘图数据导出功能
% 这个脚本用于测试新添加的workspace和.mat文件导出功能

clear; clc;

fprintf('=== 测试绘图数据导出功能 ===\n\n');

%% 1. 测试配置创建
fprintf('1. 测试新的配置选项...\n');

% 创建配置，启用数据导出功能
config = quick_config('ModelType', 'half', ...
                     'Language', 'cn', ...
                     'SavePlots', true, ...
                     'SaveToWorkspace', true, ...
                     'SaveMatFiles', true, ...
                     'UseTimestamp', false, ...
                     'OutputFolder', 'test_results');

% 验证配置中包含新选项
if isfield(config, 'save_to_workspace') && isfield(config, 'save_mat_files')
    fprintf('  ✓ 配置创建成功，包含新的导出选项\n');
    fprintf('    - 保存到workspace: %s\n', mat2str(config.save_to_workspace));
    fprintf('    - 保存为.mat文件: %s\n', mat2str(config.save_mat_files));
else
    fprintf('  ✗ 配置创建失败，缺少导出选项\n');
    return;
end

%% 2. 测试导出功能（模拟数据）
fprintf('\n2. 测试数据导出功能...\n');

% 创建模拟绘图数据
test_plot_data = struct();
test_plot_data.rms_values = [1.0, 0.8, 0.6];  % 模拟RMS值
test_plot_data.relative_percentages = [100, 80, 60];  % 模拟相对百分比

% 创建信号信息
test_signal_info = {'body_accel', 'signals', 1, '车体加速度', 'Body Acceleration', 'm/s²'};
test_labels = {'被动悬架', '主动悬架', 'PID控制'};

% 测试导出函数
try
    export_plot_data(test_plot_data, test_signal_info, test_labels, config, 'rms');
    fprintf('  ✓ 导出函数调用成功\n');

    % 检查workspace中是否有导出的变量
    if exist('plot_data_body_accel_rms', 'var')
        fprintf('  ✓ 数据已成功导出到workspace变量: plot_data_body_accel_rms\n');

        % 显示导出数据的结构
        exported_data = evalin('base', 'plot_data_body_accel_rms');
        fprintf('    导出数据包含字段: %s\n', strjoin(fieldnames(exported_data), ', '));
    else
        fprintf('  ⚠ workspace中未找到导出变量\n');
    end

    % 检查.mat文件是否创建
    mat_file_path = fullfile(config.output_folder, 'body_accel_rms_绘图数据.mat');
    if exist(mat_file_path, 'file')
        fprintf('  ✓ .mat文件已成功创建: %s\n', mat_file_path);
    else
        fprintf('  ⚠ .mat文件未找到: %s\n', mat_file_path);
    end

catch ME
    fprintf('  ✗ 导出功能测试失败: %s\n', ME.message);
end

%% 3. 测试GUI配置更新
fprintf('\n3. 测试GUI配置管理器的新选项...\n');

% 检查GUI配置管理器文件是否包含新的控件创建代码
gui_config_file = 'src/gui/gui_config_manager.m';
if exist(gui_config_file, 'file')
    file_content = fileread(gui_config_file);

    if contains(file_content, 'saveToWorkspaceCheck') && contains(file_content, 'saveMatFilesCheck')
        fprintf('  ✓ GUI配置管理器已包含新的控件定义\n');
    else
        fprintf('  ✗ GUI配置管理器缺少新的控件定义\n');
    end

    if contains(file_content, 'save_to_workspace') && contains(file_content, 'save_mat_files')
        fprintf('  ✓ GUI配置管理器已包含新的配置变量处理\n');
    else
        fprintf('  ✗ GUI配置管理器缺少新的配置变量处理\n');
    end
else
    fprintf('  ✗ GUI配置管理器文件未找到\n');
end

%% 4. 验证主要绘图函数的修改
fprintf('\n4. 验证绘图函数的导出功能集成...\n');

plot_functions = {
    'src/analysis/plotting/plot_frequency_response_universal.m', 'frequency';
    'src/analysis/plotting/plot_time_response_universal.m', 'time';
    'src/analysis/plotting/plot_rms_comparison_universal.m', 'rms';
    'src/analysis/plotting/plot_peak_comparison_universal.m', 'peak'
};

for i = 1:size(plot_functions, 1)
    func_file = plot_functions{i, 1};
    func_type = plot_functions{i, 2};

    if exist(func_file, 'file')
        file_content = fileread(func_file);
        if contains(file_content, 'export_plot_data')
            fprintf('  ✓ %s 已集成导出功能\n', func_type);
        else
            fprintf('  ✗ %s 未集成导出功能\n', func_type);
        end
    else
        fprintf('  ✗ %s 文件未找到\n', func_file);
    end
end

%% 5. 清理测试数据
fprintf('\n5. 清理测试数据...\n');
try
    if exist(config.output_folder, 'dir')
        rmdir(config.output_folder, 's');
        fprintf('  ✓ 测试文件夹已清理\n');
    end

    if exist('plot_data_body_accel_rms', 'var')
        clear plot_data_body_accel_rms;
        fprintf('  ✓ 测试变量已清理\n');
    end
catch
    fprintf('  ⚠ 清理过程中出现警告（可忽略）\n');
end

fprintf('\n=== 测试完成 ===\n');
fprintf('如果所有项目都显示 ✓，则新功能已成功实现。\n');
fprintf('您现在可以在GUI界面中看到两个新的复选框：\n');
fprintf('- "保存绘图数据到workspace"\n');
fprintf('- "保存绘图数据为.mat文件"\n\n');