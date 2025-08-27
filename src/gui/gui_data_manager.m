function handles = gui_data_manager(parent, handles)
%% 数据管理模块
% 负责数据的导入、管理和显示
%
% 功能:
% - 从工作空间导入数据
% - 从文件导入数据  
% - 数据列表管理
% - 数据标签编辑
% - 数据清除操作
%
% 输入:
%   parent - 父容器对象
%   handles - GUI句柄结构体
%
% 输出:  
%   handles - 更新后的句柄结构体

    % 数据管理面板 - 修复顶部被覆盖问题
    dataPanel = uipanel('Parent', parent, ...
                       'Title', '📁 数据管理', ...
                       'Position', [0.02, 0.75, 0.96, 0.23], ...
                       'FontSize', 10, ...
                       'FontWeight', 'bold', ...
                       'ForegroundColor', [0.2, 0.4, 0.8]);
    
    % 数据导入按钮 - 修复位置
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '📊 工作空间导入', ...
              'Position', [10, 130, 160, 32], ...
              'Callback', {@importFromWorkspace, handles}, ...
              'FontSize', 9, ...
              'BackgroundColor', [0.9, 0.95, 1], ...
              'FontWeight', 'bold');
    
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '📁 文件导入', ...
              'Position', [180, 130, 140, 32], ...
              'Callback', {@importFromFile, handles}, ...
              'FontSize', 9, ...
              'BackgroundColor', [0.9, 0.95, 1], ...
              'FontWeight', 'bold');
    
    % 已导入数据标签
    uicontrol('Parent', dataPanel, ...
              'Style', 'text', ...
              'String', '已导入的数据:', ...
              'Position', [10, 105, 100, 18], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9);
    
    handles.dataList = uicontrol('Parent', dataPanel, ...
                                'Style', 'listbox', ...
                                'Position', [10, 15, 310, 85], ...
                                'FontSize', 9, ...
                                'Max', 10, ...
                                'BackgroundColor', 'white', ...
                                'Callback', {@selectDataItem, handles});
    
    % 数据操作按钮 - 修复位置
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '✏️ 编辑', ...
              'Position', [330, 95, 70, 26], ...
              'Callback', {@editLabel, handles}, ...
              'FontSize', 8, ...
              'BackgroundColor', [1, 0.98, 0.9]);
    
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '🗑️ 删选中', ...
              'Position', [330, 65, 70, 26], ...
              'Callback', {@clearSelectedData, handles}, ...
              'FontSize', 8, ...
              'BackgroundColor', [1, 0.95, 0.95]);
    
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '🗑️ 清空', ...
              'Position', [330, 35, 70, 26], ...
              'Callback', {@clearAllData, handles}, ...
              'FontSize', 8, ...
              'BackgroundColor', [1, 0.9, 0.9]);

end

%% 从工作空间导入数据
function importFromWorkspace(~, ~, handles)
    % 确保获取最新的handles
    if ~isstruct(handles) || ~isfield(handles, 'fig')
        warning('handles参数无效');
        return;
    end
    
    handles = get(handles.fig, 'UserData');
    
    % 获取工作空间变量列表
    workspace_vars = evalin('base', 'who');
    
    if isempty(workspace_vars)
        msgbox('工作空间中没有找到变量', '提示', 'warn');
        return;
    end
    
    % 选择变量对话框
    [selection, ok] = listdlg('ListString', workspace_vars, ...
                             'SelectionMode', 'multiple', ...
                             'Name', '选择数据变量', ...
                             'PromptString', '选择要导入的仿真数据变量:');
    
    if ~ok
        return;
    end
    
    % 导入选中的变量
    for i = 1:length(selection)
        var_name = workspace_vars{selection(i)};
        try
            data = evalin('base', var_name);
            
            % 验证数据格式
            if isstruct(data) && isfield(data, 'tout')
                handles.data{end+1} = data;
                
                % 生成友好的标签
                label = generateDataLabel(var_name);
                handles.labels{end+1} = label;
                
                gui_utils('addLog', handles, sprintf('已导入数据: %s', var_name));
            else
                gui_utils('addLog', handles, sprintf('警告: %s 不是有效的仿真数据格式', var_name));
            end
        catch ME
            gui_utils('addLog', handles, sprintf('导入 %s 失败: %s', var_name, ME.message));
        end
    end
    
    % 更新数据列表显示
    updateDataList(handles);
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end

%% 从文件导入数据
function importFromFile(~, ~, handles)
    % 确保获取最新的handles
    if ~isstruct(handles) || ~isfield(handles, 'fig')
        warning('handles参数无效');
        return;
    end
    
    handles = get(handles.fig, 'UserData');
    
    [filename, pathname] = uigetfile({'*.mat', 'MATLAB数据文件 (*.mat)'}, ...
                                    '选择数据文件', 'MultiSelect', 'on');
    
    if isequal(filename, 0)
        return;
    end
    
    % 确保filename是cell数组
    if ~iscell(filename)
        filename = {filename};
    end
    
    for i = 1:length(filename)
        try
            filepath = fullfile(pathname, filename{i});
            loaded_data = load(filepath);
            
            % 查找有效的仿真数据
            field_names = fieldnames(loaded_data);
            found_data = false;
            
            % 首先查找所有以'out'开头的变量
            out_variables = {};
            other_variables = {};
            
            for j = 1:length(field_names)
                field_name = field_names{j};
                if startsWith(lower(field_name), 'out')
                    out_variables{end+1} = field_name;
                else
                    other_variables{end+1} = field_name;
                end
            end
            
            % 优先处理out变量
            variables_to_check = [out_variables, other_variables];
            
            for j = 1:length(variables_to_check)
                field_name = variables_to_check{j};
                field_data = loaded_data.(field_name);
                
                % 更宽松的数据结构检查
                is_valid = false;
                validation_info = '';
                
                if isstruct(field_data)
                    struct_fields = fieldnames(field_data);
                    
                    % 检查必需字段
                    has_tout = isfield(field_data, 'tout');
                    has_time = isfield(field_data, 'time') || isfield(field_data, 't');
                    
                    if has_tout || has_time
                        is_valid = true;
                        
                        % 获取时间字段名
                        if has_tout
                            time_field = 'tout';
                        elseif isfield(field_data, 'time')
                            time_field = 'time';
                        else
                            time_field = 't';
                        end
                        
                        % 检查时间数据
                        time_data = field_data.(time_field);
                        if isnumeric(time_data) && length(time_data) > 1
                            validation_info = sprintf('时间长度: %d, 范围: %.2f-%.2f s', ...
                                length(time_data), time_data(1), time_data(end));
                        else
                            validation_info = '时间数据格式异常';
                            is_valid = false;
                        end
                        
                        % 如果没有标准时间字段名，需要转换
                        if ~has_tout && is_valid
                            field_data.tout = field_data.(time_field);
                            gui_utils('addLog', handles, sprintf('将 %s 字段转换为 tout', time_field));
                        end
                        
                    else
                        validation_info = sprintf('缺少时间字段, 现有字段: %s', strjoin(struct_fields, ', '));
                    end
                    
                    % 检查其他重要字段
                    if is_valid
                        optional_info = {};
                        if isfield(field_data, 'y_bus')
                            y_size = size(field_data.y_bus);
                            optional_info{end+1} = sprintf('y_bus: %s', mat2str(y_size));
                        end
                        if isfield(field_data, 'xr')
                            xr_size = size(field_data.xr);
                            optional_info{end+1} = sprintf('xr: %s', mat2str(xr_size));
                        end
                        if isfield(field_data, 'real_x_bus')
                            x_size = size(field_data.real_x_bus);
                            optional_info{end+1} = sprintf('real_x_bus: %s', mat2str(x_size));
                        end
                        
                        if ~isempty(optional_info)
                            validation_info = [validation_info, ', ' strjoin(optional_info, ', ')];
                        end
                    end
                    
                else
                    validation_info = sprintf('非结构体数据 (%s)', class(field_data));
                end
                
                if is_valid
                    handles.data{end+1} = field_data;
                    
                    % 生成更好的标签
                    if startsWith(lower(field_name), 'out')
                        label = generateDataLabelFromOut(field_name);
                    else
                        label = field_name;
                    end
                    
                    % 不再添加文件名信息，避免标签过长
                    handles.labels{end+1} = label;
                    
                    found_data = true;
                    gui_utils('addLog', handles, sprintf('✓ 从 %s 导入: %s', filename{i}, field_name));
                    gui_utils('addLog', handles, sprintf('  数据信息: %s', validation_info));
                else
                    gui_utils('addLog', handles, sprintf('⚠ 跳过 %s.%s: %s', filename{i}, field_name, validation_info));
                end
            end
            
            if ~found_data
                gui_utils('addLog', handles, sprintf('警告: %s 中未找到有效的仿真数据', filename{i}));
                % 显示文件中的变量列表供用户参考
                if ~isempty(field_names)
                    var_list = strjoin(field_names, ', ');
                    gui_utils('addLog', handles, sprintf('文件包含变量: %s', var_list));
                end
            else
                gui_utils('addLog', handles, sprintf('成功从 %s 导入了 %d 个数据集', filename{i}, ...
                       sum(arrayfun(@(k) startsWith(lower(field_names{k}), 'out') || ...
                           (isstruct(loaded_data.(field_names{k})) && ...
                            isfield(loaded_data.(field_names{k}), 'tout')), 1:length(field_names)))));
            end
            
        catch ME
            % 现在handles已经是正确的结构体
            gui_utils('addLog', handles, sprintf('加载文件 %s 失败: %s', filename{i}, ME.message));
        end
    end
    
    % 更新数据列表显示
    updateDataList(handles);
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end

%% 生成数据标签
function label = generateDataLabel(var_name)
    switch var_name
        case 'out_passive'
            label = '被动悬架';
        case 'out_sk_ob'
            label = '天棚观测器';
        case {'out_sk', 'out_skyhook'}
            label = '天棚控制';
        case 'out_active'
            label = '主动悬架';
        otherwise
            label = strrep(var_name, 'out_', '');
            label = strrep(label, '_', ' ');
    end
end

%% 从out变量名生成友好标签
function label = generateDataLabelFromOut(var_name)
    % 专门处理以out开头的变量名
    var_lower = lower(var_name);
    
    % 常见的变量名映射 - 注意顺序很重要，更具体的匹配应该在前面
    if contains(var_lower, 'passive')
        label = '被动悬架';
    elseif contains(var_lower, 'active')
        label = '主动悬架';
    % 更精确的匹配：天棚观测器 (需要同时包含sky/sk和ob)
    elseif (contains(var_lower, {'sky', 'sk'}) && contains(var_lower, 'ob')) || strcmp(var_lower, 'out_sk_ob')
        label = '天棚观测器';
    % 天棚控制 (包含sky/sk但不包含ob)
    elseif contains(var_lower, {'sky', 'sk'})
        label = '天棚控制';
    elseif contains(var_lower, 'pid')
        label = 'PID控制';
    elseif contains(var_lower, 'lqr')
        label = 'LQR控制';
    elseif contains(var_lower, 'fuzzy')
        label = '模糊控制';
    elseif contains(var_lower, 'neural') || contains(var_lower, 'nn')
        label = '神经网络';
    else
        % 默认处理：移除out前缀，替换下划线
        label = strrep(var_name, 'out_', '');
        label = strrep(label, '_', ' ');
        % 首字母大写
        if ~isempty(label)
            label(1) = upper(label(1));
        else
            label = var_name; % 如果处理后为空，使用原名
        end
    end
end

%% 更新数据列表显示
function updateDataList(handles)
    if isempty(handles.labels)
        set(handles.dataList, 'String', {'(无数据)'});
    else
        % 添加序号
        display_labels = cell(size(handles.labels));
        for i = 1:length(handles.labels)
            display_labels{i} = sprintf('%d. %s', i, handles.labels{i});
        end
        set(handles.dataList, 'String', display_labels);
    end
end

%% 选择数据项回调函数
function selectDataItem(~, ~, handles)
    % 当用户选择数据列表中的项时触发
    % 这里可以添加选择项的处理逻辑
end

%% 编辑标签回调函数
function editLabel(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 获取当前选中的数据项
    selection = get(handles.dataList, 'Value');
    if isempty(handles.labels) || selection > length(handles.labels) || selection == 0
        msgbox('请先选择一个数据项', '提示', 'warn');
        return;
    end
    
    % 获取当前标签
    current_label = handles.labels{selection};
    
    % 显示输入对话框让用户编辑标签
    new_label = inputdlg('请输入新的标签:', '编辑标签', 1, {current_label});
    
    % 如果用户点击了取消或关闭对话框
    if isempty(new_label)
        return;
    end
    
    % 更新标签
    new_label_str = new_label{1};
    if ~isempty(new_label_str)
        handles.labels{selection} = new_label_str;
        
        % 更新数据列表显示
        updateDataList(handles);
        
        % 保存handles
        set(handles.fig, 'UserData', handles);
        
        gui_utils('addLog', handles, sprintf('已更新标签: %s -> %s', current_label, new_label_str));
    end
end

%% 清除选中数据
function clearSelectedData(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    selection = get(handles.dataList, 'Value');
    if isempty(handles.data) || selection > length(handles.data)
        return;
    end
    
    % 删除选中的数据
    handles.data(selection) = [];
    handles.labels(selection) = [];
    
    % 重置选择
    set(handles.dataList, 'Value', 1);
    
    % 更新显示
    updateDataList(handles);
    
    gui_utils('addLog', handles, '已删除选中的数据');
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end

%% 清除全部数据
function clearAllData(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    handles.data = {};
    handles.labels = {};
    
    updateDataList(handles);
    gui_utils('addLog', handles, '已清除全部数据');
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end