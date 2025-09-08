function [line_styles, colors, line_widths] = get_simple_data_styles(labels, data_order_mapping, config)
%% 简化的数据样式映射 - 只指定第一个和最后一个
% 根据用户指定的第一个数据（虚线）和最后一个数据（黑色实线）分配样式
%
% 输入参数:
%   labels: 数据标签 cell array
%   data_order_mapping: 数据顺序映射结构体
%     - first_index: 第一个数据的索引（虚线）
%     - last_index: 最后一个数据的索引（黑色实线）
%   config: 配置结构体
%
% 输出参数:
%   line_styles: 线型 cell array
%   colors: 颜色矩阵
%   line_widths: 线宽数组

%% 初始化默认样式
num_data = length(labels);
line_styles = cell(num_data, 1);
colors = lines(num_data);
line_widths = ones(num_data, 1) * 1.0;

%% 默认样式分配 - 所有都是实线
for i = 1:num_data
    line_styles{i} = '-';
    line_widths(i) = 1.0;
end

%% 检查是否有顺序映射配置
if nargin < 2 || isempty(data_order_mapping)
    % 如果没有指定映射，使用原有逻辑：第一个虚线，最后一个黑色
    if num_data >= 1
        line_styles{1} = '--';
        line_widths(1) = 1.5;
    end
    if num_data >= 2
        colors(end,:) = [0,0,0];    % 最后一个为黑色
        line_widths(end) = 1.5;
    end
    
    if isfield(config, 'debug') && config.debug
        fprintf('  使用默认顺序: 第1个虚线，最后一个黑色\n');
    end
    return;
end

%% 应用用户指定的第一个数据（虚线）
if isfield(data_order_mapping, 'first_index') && ~isempty(data_order_mapping.first_index)
    first_idx = data_order_mapping.first_index;
    if first_idx >= 1 && first_idx <= num_data
        line_styles{first_idx} = '--';        % 虚线
        line_widths(first_idx) = 1.5;
        fprintf('  第一个数据: 第%d个 (%s) - 虚线\n', first_idx, labels{first_idx});
    end
end

%% 应用用户指定的最后一个数据（黑色实线）
if isfield(data_order_mapping, 'last_index') && ~isempty(data_order_mapping.last_index)
    last_idx = data_order_mapping.last_index;
    if last_idx >= 1 && last_idx <= num_data
        line_styles{last_idx} = '-';         % 实线
        colors(last_idx,:) = [0, 0, 0];      % 黑色
        line_widths(last_idx) = 1.5;         % 稍粗
        fprintf('  最后一个数据: 第%d个 (%s) - 黑色实线\n', last_idx, labels{last_idx});
    end
end

%% 调试信息
if isfield(config, 'debug') && config.debug
    fprintf('  简化数据样式映射完成:\n');
    for i = 1:num_data
        color_desc = sprintf('[%.2f,%.2f,%.2f]', colors(i,1), colors(i,2), colors(i,3));
        fprintf('    数据%d (%s): %s, 线宽%.1f, 颜色%s\n', ...
                i, labels{i}, line_styles{i}, line_widths(i), color_desc);
    end
end

end
