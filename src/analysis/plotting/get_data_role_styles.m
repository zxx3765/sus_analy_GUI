function [line_styles, colors, line_widths] = get_data_role_styles(labels, data_role_mapping, config)
%% 根据数据角色映射获取绘图样式
% 根据用户指定的数据角色（被动、设计算法等）分配特定的线型和颜色
%
% 输入参数:
%   labels: 数据标签 cell array
%   data_role_mapping: 数据角色映射结构体
%   config: 配置结构体
%
% 输出参数:
%   line_styles: 线型 cell array
%   colors: 颜色矩阵
%   line_widths: 线宽数组
%
% 使用示例:
%   mapping.passive_index = 1;      % 被动悬架对应第1个数据
%   mapping.designed_index = 3;     % 设计算法对应第3个数据
%   [styles, colors, widths] = get_data_role_styles(labels, mapping, config);

%% 初始化默认样式
num_data = length(labels);
line_styles = cell(num_data, 1);
colors = lines(num_data);
line_widths = ones(num_data, 1) * 1.0;  % 默认线宽

%% 默认样式分配
for i = 1:num_data
    line_styles{i} = '-';  % 默认实线
    line_widths(i) = 1.0;  % 默认线宽
end

%% 检查是否有角色映射配置
if nargin < 2 || isempty(data_role_mapping)
    % 如果没有指定映射，使用原有逻辑
    % 第一个为虚线，最后一个为黑色实线
    if num_data >= 1
        line_styles{1} = '--';      % 第一个为虚线
        line_widths(1) = 1.5;
    end
    if num_data >= 2
        line_styles{end} = '-';     % 最后一个为实线
        colors(end,:) = [0,0,0];    % 黑色
        line_widths(end) = 1.5;
    end
    return;
end

%% 应用角色映射
% 被动悬架样式
if isfield(data_role_mapping, 'passive_index') && ~isempty(data_role_mapping.passive_index)
    idx = data_role_mapping.passive_index;
    if idx >= 1 && idx <= num_data
        line_styles{idx} = '--';        % 虚线
        colors(idx,:) = [0, 0.4470, 0.7410];  % 蓝色
        line_widths(idx) = 1.5;
        fprintf('  📊 被动悬架: 第%d个数据 (%s) - 蓝色虚线\n', idx, labels{idx});
    end
end

% 设计算法样式
if isfield(data_role_mapping, 'designed_index') && ~isempty(data_role_mapping.designed_index)
    idx = data_role_mapping.designed_index;
    if idx >= 1 && idx <= num_data
        line_styles{idx} = '-';         % 实线
        colors(idx,:) = [0, 0, 0];      % 黑色
        line_widths(idx) = 1.8;         % 较粗线条
        fprintf('  🎯 设计算法: 第%d个数据 (%s) - 黑色粗实线\n', idx, labels{idx});
    end
end

% 半主动悬架样式（如果有）
if isfield(data_role_mapping, 'semiactive_index') && ~isempty(data_role_mapping.semiactive_index)
    idx = data_role_mapping.semiactive_index;
    if idx >= 1 && idx <= num_data
        line_styles{idx} = '-.';        % 点划线
        colors(idx,:) = [0.8500, 0.3250, 0.0980];  % 橙色
        line_widths(idx) = 1.3;
        fprintf('  🟡 半主动悬架: 第%d个数据 (%s) - 橙色点划线\n', idx, labels{idx});
    end
end

% 主动悬架样式（如果有）
if isfield(data_role_mapping, 'active_index') && ~isempty(data_role_mapping.active_index)
    idx = data_role_mapping.active_index;
    if idx >= 1 && idx <= num_data
        line_styles{idx} = '-';         % 实线
        colors(idx,:) = [0.9290, 0.6940, 0.1250];  % 黄色
        line_widths(idx) = 1.3;
        fprintf('  🟠 主动悬架: 第%d个数据 (%s) - 黄色实线\n', idx, labels{idx});
    end
end

% 参考控制器样式（如果有）
if isfield(data_role_mapping, 'reference_index') && ~isempty(data_role_mapping.reference_index)
    idx = data_role_mapping.reference_index;
    if idx >= 1 && idx <= num_data
        line_styles{idx} = ':';         % 点线
        colors(idx,:) = [0.4940, 0.1840, 0.5560];  % 紫色
        line_widths(idx) = 1.2;
        fprintf('  🟣 参考控制器: 第%d个数据 (%s) - 紫色点线\n', idx, labels{idx});
    end
end

%% 应用语言相关的样式调整
if isfield(config, 'language') && strcmp(config.language, 'en')
    % 英文环境下可能的样式调整
    % (预留接口)
end

%% 调试信息
if isfield(config, 'debug') && config.debug
    fprintf('  数据角色映射应用完成:\n');
    for i = 1:num_data
        fprintf('    数据%d (%s): %s, 线宽%.1f\n', i, labels{i}, line_styles{i}, line_widths(i));
    end
end

end
