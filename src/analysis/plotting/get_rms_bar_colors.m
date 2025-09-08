function colors = get_rms_bar_colors(num_bars, last_index, config)
%% 获取RMS柱状图颜色 - 只有最后一个算法的颜色不同
% 
% 输入参数:
%   num_bars: 柱子数量
%   last_index: 最后一个算法的索引（如果指定）
%   config: 配置结构体
%
% 输出参数:
%   colors: 颜色矩阵 [num_bars x 3]

%% 初始化颜色矩阵
colors = zeros(num_bars, 3);

% 默认颜色：浅蓝色
default_color = [155,223,223]./255;  % 浅蓝色

% 最后一个算法的颜色：浅红色
last_color = [252,178,175]./255;     % 浅红色

%% 分配颜色
for i = 1:num_bars
    colors(i, :) = default_color;  % 默认都是浅蓝色
end

%% 确定最后一个算法的位置
if nargin >= 2 && ~isempty(last_index)
    % 用户指定了最后一个算法的位置
    if last_index >= 1 && last_index <= num_bars
        colors(last_index, :) = last_color;
        if isfield(config, 'debug') && config.debug
            fprintf('  RMS柱状图: 第%d个柱子设为红色\n', last_index);
        end
    end
else
    % 默认：最后一个柱子为红色
    colors(end, :) = last_color;
    if isfield(config, 'debug') && config.debug
        fprintf('  RMS柱状图: 最后一个柱子设为红色（默认）\n');
    end
end

end
