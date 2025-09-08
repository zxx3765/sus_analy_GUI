%% 快速测试数据角色映射功能
% 验证功能是否正常工作

clear; close all; clc;

fprintf('=== 快速测试数据角色映射功能 ===\n');

%% 生成测试数据
t = 0:0.01:2;
data1 = sin(2*pi*t);           % 被动悬架
data2 = 0.8*sin(2*pi*t);       % 半主动悬架  
data3 = 0.5*sin(2*pi*t);       % 你的设计算法

signal_data = [data1', data2', data3'];
labels = {'被动悬架', '半主动悬架', '我的算法'};

%% 配置
config = struct();
config.language = 'cn';
config.plot.font_size = 12;
config.plot.figure_size = [600, 400];  % 添加缺失的figure_size字段
config.save_plots = false;
config.close_figures = false;

% 设置数据角色映射
mapping = struct();
mapping.passive_index = 1;      % 第1个数据 -> 蓝色虚线
mapping.designed_index = 3;     % 第3个数据 -> 黑色粗实线
mapping.semiactive_index = 2;   % 第2个数据 -> 橙色点划线

config.data_role_mapping = mapping;

signal_info = {'test_signal', 'outputs', 1, '测试信号', 'Test Signal', 'm/s²'};

%% 绘制图形
fprintf('绘制角色映射测试图...\n');
figure('Name', '数据角色映射测试', 'Position', [100, 100, 600, 400]);

plot_time_response_universal(signal_data, t, labels, signal_info, config);

fprintf('✓ 测试完成！\n');
fprintf('检查图形中的线型：\n');
fprintf('- %s 应该是蓝色虚线\n', labels{1});
fprintf('- %s 应该是橙色点划线\n', labels{2});
fprintf('- %s 应该是黑色粗实线\n', labels{3});

%% 验证样式函数
fprintf('\n验证样式函数...\n');
[line_styles, colors, line_widths] = get_data_role_styles(labels, mapping, config);

for i = 1:length(labels)
    fprintf('%s: %s, 线宽%.1f\n', labels{i}, line_styles{i}, line_widths(i));
end

fprintf('\n如果看到正确的线型样式，说明功能工作正常！\n');
