function legend_config = legend_control(config, signal_info, labels)
%% 图例控制配置函数
% 提供灵活的图例控制选项
%
% 输入参数:
%   config: 主配置结构体
%   signal_info: 信号信息 {name, source, index, cn_label, en_label, unit}
%   labels: 原始标签
%
% 输出参数:
%   legend_config: 图例配置结构体
%
% 使用示例:
%   legend_config = legend_control(config, signal_info, labels);
%   apply_legend_settings(fig_handle, legend_config);

%% 初始化图例配置
legend_config = struct();

%% 基础配置
legend_config.show_legend = true;              % 是否显示图例
legend_config.location = 'best';               % 图例位置
legend_config.orientation = 'vertical';        % 图例方向: 'vertical', 'horizontal'
legend_config.font_size = config.plot.font_size;  % 字体大小
legend_config.font_weight = 'normal';          % 字体粗细: 'normal', 'bold'

%% 位置选项
legend_config.location_options = {
    'best', 'north', 'south', 'east', 'west', ...
    'northeast', 'northwest', 'southeast', 'southwest', ...
    'northoutside', 'southoutside', 'eastoutside', 'westoutside', ...
    'northeastoutside', 'northwestoutside', 'southeastoutside', 'southwestoutside'
};

%% 标签配置
if strcmp(config.language, 'cn')
    legend_config.labels = labels;  % 使用中文标签
else
    legend_config.labels = convertLabelsToEnglish(labels);  % 使用英文标签
end

%% 样式配置
legend_config.box = 'on';                      % 图例边框: 'on', 'off'
legend_config.edge_color = [0.15, 0.15, 0.15]; % 边框颜色
legend_config.text_color = [0, 0, 0];          % 文字颜色
legend_config.background_color = [1, 1, 1];    % 背景颜色 (白色)
legend_config.alpha = 0.9;                     % 透明度 (0-1)

%% 高级选项
legend_config.auto_update = true;              % 自动更新图例
legend_config.interpreter = 'none';            % 文本解释器: 'none', 'tex', 'latex'
legend_config.item_token_size = [30, 18];      % 图例项目标记大小 [width, height]

%% 自定义标签映射 (可扩展)
legend_config.custom_labels = containers.Map();

% 添加常用信号的自定义标签映射
if strcmp(config.language, 'cn')
    legend_config.custom_labels('被动悬架') = '被动悬架';
    legend_config.custom_labels('半主动悬架') = '半主动悬架';
    legend_config.custom_labels('主动悬架') = '主动悬架';
    legend_config.custom_labels('天棚阻尼') = '天棚阻尼';
    legend_config.custom_labels('地棚阻尼') = '地棚阻尼';
    legend_config.custom_labels('强化学习') = '强化学习';
else
    legend_config.custom_labels('Passive Suspension') = 'Passive';
    legend_config.custom_labels('Semi-Active Suspension') = 'Semi-Active';
    legend_config.custom_labels('Active Suspension') = 'Active';
    legend_config.custom_labels('Sky-hook Damping') = 'Sky-hook';
    legend_config.custom_labels('Ground-hook Damping') = 'Ground-hook';
    legend_config.custom_labels('Reinforcement Learning') = 'RL Control';
end

%% 处理GUI配置（如果存在）
if isfield(config, 'current_legend_config')
    gui_legend_config = config.current_legend_config;
    
    % 覆盖默认设置
    if isfield(gui_legend_config, 'show_legend')
        legend_config.show_legend = gui_legend_config.show_legend;
    end
    if isfield(gui_legend_config, 'location')
        legend_config.location = gui_legend_config.location;
    end
    if isfield(gui_legend_config, 'orientation')
        legend_config.orientation = gui_legend_config.orientation;
    end
    if isfield(gui_legend_config, 'font_size')
        legend_config.font_size = gui_legend_config.font_size;
    end
    if isfield(gui_legend_config, 'custom_labels') && ~isempty(gui_legend_config.custom_labels)
        legend_config.custom_labels = gui_legend_config.custom_labels;
    end
    
    % 应用其他样式设置
    style_fields = {'box', 'edge_color', 'text_color', 'background_color', 'alpha', 'interpreter', 'item_token_size'};
    for i = 1:length(style_fields)
        field = style_fields{i};
        if isfield(gui_legend_config, field)
            legend_config.(field) = gui_legend_config.(field);
        end
    end
end

%% 处理自定义标签
legend_config.final_labels = legend_config.labels;
for i = 1:length(legend_config.labels)
    original_label = legend_config.labels{i};
    if legend_config.custom_labels.isKey(original_label)
        legend_config.final_labels{i} = legend_config.custom_labels(original_label);
    end
end

%% 根据信号类型调整图例位置
signal_name = signal_info{1};
switch signal_name
    case {'sprung_acc', 'unsprung_acc', 'body_acc'}
        % 加速度信号通常在图的上部，图例放在右下角
        legend_config.location = 'southeast';
    case {'susp_def', 'tire_def'}
        % 变形信号通常居中，图例放在最佳位置
        legend_config.location = 'best';
    case {'reward', 'road_input'}
        % 奖励和路面输入信号，图例放在右上角
        legend_config.location = 'northeast';
    otherwise
        legend_config.location = 'best';
end

%% 根据标签数量调整图例方向
if length(legend_config.final_labels) > 4
    legend_config.orientation = 'vertical';
    % 标签较多时，优先考虑外部位置
    if strcmp(legend_config.location, 'best')
        legend_config.location = 'eastoutside';
    end
else
    legend_config.orientation = 'vertical';  % 保持垂直，更清晰
end

%% 调试信息
if isfield(config, 'debug') && config.debug
    fprintf('  图例配置:\n');
    fprintf('    显示图例: %s\n', mat2str(legend_config.show_legend));
    fprintf('    位置: %s\n', legend_config.location);
    fprintf('    方向: %s\n', legend_config.orientation);
    fprintf('    标签数量: %d\n', length(legend_config.final_labels));
    fprintf('    标签: %s\n', strjoin(legend_config.final_labels, ', '));
end

end
