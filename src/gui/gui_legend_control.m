function handles = gui_legend_control(parent, handles)
%% 图例控制GUI模块
% 提供图例样式的控制界面
%
% 输入:
%   parent - 父容器对象
%   handles - GUI句柄结构体
%
% 输出:  
%   handles - 更新后的句柄结构体

    % 图例控制面板
    legendPanel = uipanel('Parent', parent, ...
                         'Title', '🎨 图例控制', ...
                         'Position', [0.02, 0.02, 0.96, 0.96], ...
                         'FontSize', 10, ...
                         'FontWeight', 'bold', ...
                         'BackgroundColor', [0.97, 0.98, 1.0], ...
                         'ForegroundColor', [0.3, 0.1, 0.7]);
    
    % === 图例预设样式选择 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', '📋 预设样式:', ...
              'Position', [15, 430, 80, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    preset_options = {'default', 'compact', 'presentation', 'paper', 'colorful', 'minimal', 'hidden'};
    preset_labels_cn = {'默认', '紧凑', '演示', '论文', '彩色', '极简', '隐藏'};
    
    handles.legendPresetDropdown = uicontrol('Parent', legendPanel, ...
                                            'Style', 'popupmenu', ...
                                            'String', preset_labels_cn, ...
                                            'Position', [100, 430, 120, 25], ...
                                            'FontSize', 9, ...
                                            'Value', 1, ...
                                            'Callback', {@onLegendPresetChange, handles});
    
    % 存储预设选项映射
    handles.legend_preset_options = preset_options;
    
    % === 图例位置选择 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', '📍 图例位置:', ...
              'Position', [15, 395, 80, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    position_options = {'auto', 'best', 'northeast', 'northwest', 'southeast', 'southwest', ...
                       'north', 'south', 'east', 'west', 'eastoutside', 'westoutside'};
    position_labels_cn = {'自动', '最佳', '右上角', '左上角', '右下角', '左下角', ...
                         '顶部', '底部', '右侧', '左侧', '图外右侧', '图外左侧'};
    
    handles.legendPositionDropdown = uicontrol('Parent', legendPanel, ...
                                              'Style', 'popupmenu', ...
                                              'String', position_labels_cn, ...
                                              'Position', [100, 395, 120, 25], ...
                                              'FontSize', 9, ...
                                              'Value', 2, ... % 默认选择'最佳'
                                              'Callback', {@onLegendPositionChange, handles});
    
    % 存储位置选项映射
    handles.legend_position_options = position_options;
    
    % === 图例显示控制 ===
    handles.legendShowCheckbox = uicontrol('Parent', legendPanel, ...
                                          'Style', 'checkbox', ...
                                          'String', '显示图例', ...
                                          'Position', [15, 365, 80, 20], ...
                                          'FontSize', 9, ...
                                          'FontWeight', 'bold', ...
                                          'Value', 1, ...
                                          'Callback', {@onLegendShowToggle, handles});
    
    % === 字体大小控制 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', '🔤 字体大小:', ...
              'Position', [15, 335, 80, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    handles.legendFontSizeEdit = uicontrol('Parent', legendPanel, ...
                                          'Style', 'edit', ...
                                          'String', '10', ...
                                          'Position', [100, 335, 50, 25], ...
                                          'FontSize', 9, ...
                                          'HorizontalAlignment', 'center', ...
                                          'Callback', {@onLegendFontSizeChange, handles});
    
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', '(8-16)', ...
              'Position', [155, 335, 40, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 8, ...
              'ForegroundColor', [0.5, 0.5, 0.5]);
    
    % === 图例方向控制 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', '📐 图例方向:', ...
              'Position', [15, 305, 80, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    handles.legendOrientationGroup = uibuttongroup('Parent', legendPanel, ...
                                                  'Position', [100, 300, 120, 30], ...
                                                  'BorderType', 'none', ...
                                                  'BackgroundColor', get(legendPanel, 'BackgroundColor'));
    
    handles.legendVerticalRadio = uicontrol('Parent', handles.legendOrientationGroup, ...
                                           'Style', 'radiobutton', ...
                                           'String', '垂直', ...
                                           'Position', [5, 5, 50, 20], ...
                                           'FontSize', 9, ...
                                           'Value', 1);
    
    handles.legendHorizontalRadio = uicontrol('Parent', handles.legendOrientationGroup, ...
                                             'Style', 'radiobutton', ...
                                             'String', '水平', ...
                                             'Position', [60, 5, 50, 20], ...
                                             'FontSize', 9, ...
                                             'Value', 0);
    
    % === 自定义标签区域 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', '🏷️ 自定义标签映射:', ...
              'Position', [15, 270, 120, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    % 自定义标签表格 (简化版)
    handles.customLabelsTable = uitable('Parent', legendPanel, ...
                                       'Position', [15, 150, 200, 115], ...
                                       'ColumnName', {'原标签', '新标签'}, ...
                                       'ColumnWidth', {90, 90}, ...
                                       'ColumnEditable', [false, true], ...
                                       'Data', cell(5, 2), ...
                                       'FontSize', 8, ...
                                       'CellEditCallback', {@onCustomLabelEdit, handles});
    
    % === 预览和应用按钮 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'pushbutton', ...
              'String', '👁️ 预览图例', ...
              'Position', [15, 110, 95, 30], ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.2, 0.6, 0.9], ...
              'ForegroundColor', 'white', ...
              'Callback', {@previewLegend, handles});
    
    uicontrol('Parent', legendPanel, ...
              'Style', 'pushbutton', ...
              'String', '✅ 应用设置', ...
              'Position', [120, 110, 95, 30], ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.1, 0.7, 0.1], ...
              'ForegroundColor', 'white', ...
              'Callback', {@applyLegendSettings, handles});
    
    % === 重置按钮 ===
    uicontrol('Parent', legendPanel, ...
              'Style', 'pushbutton', ...
              'String', '🔄 重置默认', ...
              'Position', [15, 70, 95, 25], ...
              'FontSize', 9, ...
              'BackgroundColor', [0.9, 0.9, 0.9], ...
              'Callback', {@resetLegendSettings, handles});
    
    % === 帮助信息 ===
    help_text = ['💡 图例控制说明：', newline, ...
                '• 选择预设样式快速配置', newline, ...
                '• 自定义位置和字体大小', newline, ...
                '• 映射原标签到新标签', newline, ...
                '• 预览效果后再应用'];
    
    uicontrol('Parent', legendPanel, ...
              'Style', 'text', ...
              'String', help_text, ...
              'Position', [15, 10, 200, 55], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 8, ...
              'ForegroundColor', [0.4, 0.4, 0.4]);
    
    % 初始化自定义标签表格数据
    initializeCustomLabelsTable(handles);
    
end

%% 初始化自定义标签表格
function initializeCustomLabelsTable(handles)
    % 根据当前数据的标签初始化表格
    if isfield(handles, 'data') && ~isempty(handles.data) && isfield(handles.data, 'labels')
        labels = handles.data.labels;
        table_data = cell(max(5, length(labels)), 2);
        for i = 1:length(labels)
            table_data{i, 1} = labels{i};
            table_data{i, 2} = '';  % 新标签留空，用户可以填写
        end
        set(handles.customLabelsTable, 'Data', table_data);
    end
end

%% 回调函数 - 预设样式改变
function onLegendPresetChange(src, ~, handles)
    handles = get(handles.fig, 'UserData');
    preset_idx = get(src, 'Value');
    preset_name = handles.legend_preset_options{preset_idx};
    
    % 根据预设更新其他控件的值
    preset_config = legend_style_presets(preset_name, 'cn');
    
    % 更新显示状态
    set(handles.legendShowCheckbox, 'Value', preset_config.show_legend);
    
    % 更新字体大小
    set(handles.legendFontSizeEdit, 'String', num2str(preset_config.font_size));
    
    % 更新方向
    if strcmp(preset_config.orientation, 'vertical')
        set(handles.legendVerticalRadio, 'Value', 1);
        set(handles.legendHorizontalRadio, 'Value', 0);
    else
        set(handles.legendVerticalRadio, 'Value', 0);
        set(handles.legendHorizontalRadio, 'Value', 1);
    end
    
    gui_utils('addLog', handles, sprintf('图例预设已更改为: %s', preset_name));
end

%% 回调函数 - 位置改变
function onLegendPositionChange(src, ~, handles)
    handles = get(handles.fig, 'UserData');
    position_idx = get(src, 'Value');
    position_name = handles.legend_position_options{position_idx};
    
    gui_utils('addLog', handles, sprintf('图例位置已更改为: %s', position_name));
end

%% 回调函数 - 显示状态切换
function onLegendShowToggle(src, ~, handles)
    handles = get(handles.fig, 'UserData');
    show_state = get(src, 'Value');
    
    if show_state
        gui_utils('addLog', handles, '图例显示已启用');
    else
        gui_utils('addLog', handles, '图例显示已禁用');
    end
end

%% 回调函数 - 字体大小改变
function onLegendFontSizeChange(src, ~, handles)
    handles = get(handles.fig, 'UserData');
    font_size_str = get(src, 'String');
    font_size = str2double(font_size_str);
    
    % 验证字体大小范围
    if isnan(font_size) || font_size < 6 || font_size > 20
        set(src, 'String', '10');  % 重置为默认值
        gui_utils('addLog', handles, '字体大小无效，已重置为10');
        return;
    end
    
    gui_utils('addLog', handles, sprintf('图例字体大小已设置为: %d', font_size));
end

%% 回调函数 - 自定义标签编辑
function onCustomLabelEdit(~, event, handles)
    handles = get(handles.fig, 'UserData');
    
    % 获取编辑的信息
    row = event.Indices(1);
    col = event.Indices(2);
    new_value = event.NewData;
    
    if col == 2 && ~isempty(new_value)  % 编辑的是新标签列
        gui_utils('addLog', handles, sprintf('自定义标签映射已添加: 第%d行', row));
    end
end

%% 预览图例
function previewLegend(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    try
        % 创建一个简单的预览图
        preview_fig = figure('Name', '图例预览', 'Position', [200, 200, 400, 300]);
        
        % 绘制示例数据
        x = 0:0.1:10;
        hold on;
        plot(x, sin(x), 'b-', 'LineWidth', 2, 'DisplayName', '示例数据1');
        plot(x, cos(x), 'r--', 'LineWidth', 2, 'DisplayName', '示例数据2');
        plot(x, sin(x).*cos(x), 'g:', 'LineWidth', 2, 'DisplayName', '示例数据3');
        
        % 应用当前图例设置
        legend_config = getCurrentLegendConfig(handles);
        apply_legend_settings(preview_fig, legend_config);
        
        xlabel('时间 (s)');
        ylabel('幅值');
        title('图例预览');
        grid on;
        
        gui_utils('addLog', handles, '图例预览已生成');
        
    catch ME
        gui_utils('addLog', handles, sprintf('预览生成失败: %s', ME.message));
    end
end

%% 应用图例设置
function applyLegendSettings(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 获取当前图例配置
    legend_config = getCurrentLegendConfig(handles);
    
    % 保存到handles中，供分析函数使用
    handles.current_legend_config = legend_config;
    set(handles.fig, 'UserData', handles);
    
    gui_utils('addLog', handles, '图例设置已应用到当前配置');
end

%% 重置图例设置
function resetLegendSettings(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 重置所有控件到默认值
    set(handles.legendPresetDropdown, 'Value', 1);  % default
    set(handles.legendPositionDropdown, 'Value', 2);  % best
    set(handles.legendShowCheckbox, 'Value', 1);
    set(handles.legendFontSizeEdit, 'String', '10');
    set(handles.legendVerticalRadio, 'Value', 1);
    set(handles.legendHorizontalRadio, 'Value', 0);
    
    % 清空自定义标签表格
    table_data = cell(5, 2);
    set(handles.customLabelsTable, 'Data', table_data);
    
    gui_utils('addLog', handles, '图例设置已重置为默认值');
end

%% 获取当前图例配置
function legend_config = getCurrentLegendConfig(handles)
    
    % 基础配置
    legend_config = struct();
    
    % 预设样式
    preset_idx = get(handles.legendPresetDropdown, 'Value');
    preset_name = handles.legend_preset_options{preset_idx};
    
    % 位置
    position_idx = get(handles.legendPositionDropdown, 'Value');
    position_name = handles.legend_position_options{position_idx};
    
    % 显示状态
    show_legend = get(handles.legendShowCheckbox, 'Value');
    
    % 字体大小
    font_size = str2double(get(handles.legendFontSizeEdit, 'String'));
    
    % 方向
    if get(handles.legendVerticalRadio, 'Value')
        orientation = 'vertical';
    else
        orientation = 'horizontal';
    end
    
    % 应用预设配置
    if ~strcmp(preset_name, 'custom')
        preset_config = legend_style_presets(preset_name, 'cn');
        legend_config = preset_config;
    else
        legend_config.show_legend = show_legend;
        legend_config.location = position_name;
        legend_config.orientation = orientation;
        legend_config.font_size = font_size;
    end
    
    % 覆盖用户自定义的设置
    if ~strcmp(position_name, 'auto')
        legend_config.location = position_name;
    end
    legend_config.show_legend = show_legend;
    legend_config.font_size = font_size;
    legend_config.orientation = orientation;
    
    % 获取自定义标签映射
    table_data = get(handles.customLabelsTable, 'Data');
    custom_labels = containers.Map();
    for i = 1:size(table_data, 1)
        if ~isempty(table_data{i, 1}) && ~isempty(table_data{i, 2})
            custom_labels(table_data{i, 1}) = table_data{i, 2};
        end
    end
    legend_config.custom_labels = custom_labels;
    
    % 示例标签 (如果没有真实数据)
    if ~isfield(handles, 'data') || isempty(handles.data)
        legend_config.labels = {'示例数据1', '示例数据2', '示例数据3'};
        legend_config.final_labels = legend_config.labels;
    end
end
