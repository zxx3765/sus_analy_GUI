function legend_handle = apply_legend_settings(fig_handle, legend_config)
%% 应用图例设置函数
% 根据图例配置应用图例样式
%
% 输入参数:
%   fig_handle: 图形句柄
%   legend_config: 图例配置结构体
%
% 输出参数:
%   legend_handle: 图例句柄
%
% 使用示例:
%   legend_handle = apply_legend_settings(fig_handle, legend_config);

legend_handle = [];

% 检查是否显示图例
if ~legend_config.show_legend
    legend('off');
    return;
end

% 确保当前图形是活动的
if ishandle(fig_handle)
    figure(fig_handle);
else
    error('无效的图形句柄');
end

try
    % 创建图例
    legend_handle = legend(legend_config.final_labels, ...
                          'Location', legend_config.location, ...
                          'Orientation', legend_config.orientation, ...
                          'FontSize', legend_config.font_size, ...
                          'FontWeight', legend_config.font_weight, ...
                          'Interpreter', legend_config.interpreter, ...
                          'Box', legend_config.box, ...
                          'EdgeColor', legend_config.edge_color, ...
                          'TextColor', legend_config.text_color, ...
                          'Color', legend_config.background_color);
    
    % 设置透明度
    if isfield(legend_config, 'alpha') && legend_config.alpha < 1
        legend_handle.Color(4) = legend_config.alpha;
    end
    
    % 设置图例项目标记大小
    if isfield(legend_config, 'item_token_size')
        legend_handle.ItemTokenSize = legend_config.item_token_size;
    end
    
    % 如果启用自动更新
    if legend_config.auto_update
        legend_handle.AutoUpdate = 'on';
    else
        legend_handle.AutoUpdate = 'off';
    end
    
    % 调试信息
    if ishandle(legend_handle)
        fprintf('  ✓ 图例已应用: %s位置, %d个标签\n', ...
                legend_config.location, length(legend_config.final_labels));
    end
    
catch ME
    warning('LEGEND:ApplyError', '应用图例设置时出错: %s', ME.message);
    % 回退到简单图例
    try
        legend_handle = legend(legend_config.final_labels, 'Location', 'best');
        fprintf('  ⚠ 使用简化图例设置\n');
    catch
        fprintf('  ✗ 图例设置失败\n');
    end
end

end
