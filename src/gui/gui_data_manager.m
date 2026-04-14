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
                       'Units', 'normalized', ...
                       'Position', [0.02, 0.75, 0.96, 0.23], ...
                       'FontSize', 10, ...
                       'FontWeight', 'bold', ...
                       'BackgroundColor', [0.98, 0.99, 0.98], ...
                       'ForegroundColor', [0.2, 0.4, 0.8]);
    
    % 数据导入按钮 - 修复位置
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '📊 工作空间导入', ...
              'Units', 'normalized', ...
              'Position', [0.02, 0.74, 0.40, 0.20], ...
              'Callback', {@importFromWorkspace, handles}, ...
              'FontSize', 9, ...
              'BackgroundColor', [0.90, 0.95, 1.00], ...
              'FontWeight', 'bold');
    
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '📁 文件导入', ...
              'Units', 'normalized', ...
              'Position', [0.44, 0.74, 0.32, 0.20], ...
              'Callback', {@importFromFile, handles}, ...
              'FontSize', 9, ...
              'BackgroundColor', [0.90, 0.95, 1.00], ...
              'FontWeight', 'bold');
    
    % 已导入数据标签
    uicontrol('Parent', dataPanel, ...
              'Style', 'text', ...
              'String', '已导入的数据:', ...
              'Units', 'normalized', ...
              'Position', [0.02, 0.62, 0.40, 0.10], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    handles.dataList = uicontrol('Parent', dataPanel, ...
                                'Style', 'listbox', ...
                                'Units', 'normalized', ...
                                'Position', [0.02, 0.08, 0.70, 0.52], ...
                                'FontSize', 9, ...
                                'Max', 10, ...
                                'BackgroundColor', 'white', ...
                                'Callback', {@selectDataItem, handles});
    
    % 数据操作按钮 - 修复位置
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '✏️ 编辑', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.50, 0.22, 0.18], ...
              'Callback', {@editLabel, handles}, ...
              'FontSize', 8, ...
              'BackgroundColor', [1.00, 0.98, 0.90]);
    
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '🗑️ 删选中', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.28, 0.22, 0.18], ...
              'Callback', {@clearSelectedData, handles}, ...
              'FontSize', 8, ...
              'BackgroundColor', [1.00, 0.95, 0.95]);
    
    uicontrol('Parent', dataPanel, ...
              'Style', 'pushbutton', ...
              'String', '🗑️ 清空', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.06, 0.22, 0.18], ...
              'Callback', {@clearAllData, handles}, ...
              'FontSize', 8, ...
              'BackgroundColor', [1.00, 0.90, 0.90]);

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

            % 验证数据格式 - 支持结构体(tout/time/t字段)和Simulink.SimulationOutput
            is_valid = false;

            if isstruct(data)
                if isfield(data, 'tout')
                    is_valid = true;
                elseif isfield(data, 'time')
                    data.tout = data.time;
                    is_valid = true;
                    gui_utils('addLog', handles, sprintf('  将 time 字段转换为 tout'));
                elseif isfield(data, 't')
                    data.tout = data.t;
                    is_valid = true;
                    gui_utils('addLog', handles, sprintf('  将 t 字段转换为 tout'));
                end
            elseif isa(data, 'Simulink.SimulationOutput')
                gui_utils('addLog', handles, sprintf('  检测到Simulink.SimulationOutput，开始转换...'));
                converted = convertSimulinkVariableForGUI(data, var_name, handles);
                if ~isempty(converted)
                    data = converted;
                    is_valid = true;
                end
            end

            if is_valid
                handles.data{end+1} = data;
                label = generateDataLabel(var_name);
                handles.labels{end+1} = label;
                gui_utils('addLog', handles, sprintf('✓ 已导入数据: %s', var_name));
            else
                gui_utils('addLog', handles, sprintf('警告: %s 不是有效的仿真数据格式 (类型: %s)', var_name, class(data)));
                % 显示结构体字段供参考
                if isstruct(data)
                    gui_utils('addLog', handles, sprintf('  现有字段: %s', strjoin(fieldnames(data), ', ')));
                end
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
                validation_info = ''; %#ok<NASGU>  % 供后续日志输出使用
                
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
                    % 数据无效，尝试转换
                    gui_utils('addLog', handles, sprintf('⚠ 数据格式不合法，尝试转换 %s.%s', filename{i}, field_name));
                    converted_data = attemptDataConversion(field_data, field_name, handles);

                    if ~isempty(converted_data)
                        handles.data{end+1} = converted_data;

                        % 生成标签
                        if startsWith(lower(field_name), 'out')
                            label = generateDataLabelFromOut(field_name);
                        else
                            label = field_name;
                        end
                        handles.labels{end+1} = label;

                        found_data = true;
                        gui_utils('addLog', handles, sprintf('✓ 转换成功并导入: %s.%s', filename{i}, field_name));
                    else
                        gui_utils('addLog', handles, sprintf('✗ 转换失败，跳过 %s.%s: %s', filename{i}, field_name, validation_info));
                    end
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
    
    % 更新简化数据顺序的下拉列表
    if exist('updateSimpleDataOrderDropdowns', 'file') == 2
        try
            updateSimpleDataOrderDropdowns(handles);
        catch
            % 如果函数不存在或调用失败，静默处理
        end
    end
    % 更新自定义顺序列表
    if exist('updateCustomOrderList', 'file') == 2
        try
            updateCustomOrderList(handles);
        catch
        end
    end
end

%% 选择数据项回调函数
function selectDataItem(~, ~, ~)
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

%% 尝试转换不合法的数据
function converted_data = attemptDataConversion(field_data, field_name, handles)
    converted_data = [];

    try
        % 检查是否是Simulink.SimulationOutput类型
        if isa(field_data, 'Simulink.SimulationOutput')
            gui_utils('addLog', handles, sprintf('  检测到Simulink.SimulationOutput，开始转换...'));
            converted_data = convertSimulinkVariableForGUI(field_data, field_name, handles);
        else
            gui_utils('addLog', handles, sprintf('  数据类型 %s 不支持自动转换', class(field_data)));
        end
    catch ME
        gui_utils('addLog', handles, sprintf('  转换过程出错: %s', ME.message));
        converted_data = [];
    end
end

%% GUI专用的Simulink数据转换函数
function converted_struct = convertSimulinkVariableForGUI(sim_output, var_name, handles)
    converted_struct = struct();

    try
        gui_utils('addLog', handles, sprintf('  分析 %s 的结构...', var_name));

        % 获取所有属性
        props = properties(sim_output);
        gui_utils('addLog', handles, sprintf('  找到 %d 个属性', length(props)));

        %% 1. 寻找时间向量
        time_found = false;

        % 方法1: 直接查找时间字段
        if isprop(sim_output, 'tout')
            converted_struct.tout = sim_output.tout;
            gui_utils('addLog', handles, sprintf('  ✓ 找到时间向量 (tout): %d 点', length(sim_output.tout)));
            time_found = true;
        elseif isprop(sim_output, 'time')
            converted_struct.tout = sim_output.time;
            gui_utils('addLog', handles, sprintf('  ✓ 找到时间向量 (time): %d 点', length(sim_output.time)));
            time_found = true;
        end

        % 方法2: 从其他属性中寻找时间向量
        if ~time_found
            gui_utils('addLog', handles, sprintf('  未找到直接时间字段，搜索其他属性...'));
            for i = 1:length(props)
                prop_name = props{i};
                try
                    prop_data = sim_output.(prop_name);
                    if isobject(prop_data)
                        if isprop(prop_data, 'Time') && isnumeric(prop_data.Time)
                            converted_struct.tout = prop_data.Time;
                            gui_utils('addLog', handles, sprintf('  ✓ 从 %s.Time 中提取时间向量: %d 点', prop_name, length(prop_data.Time)));
                            time_found = true;
                            break;
                        elseif isprop(prop_data, 'time') && isnumeric(prop_data.time)
                            converted_struct.tout = prop_data.time;
                            gui_utils('addLog', handles, sprintf('  ✓ 从 %s.time 中提取时间向量: %d 点', prop_name, length(prop_data.time)));
                            time_found = true;
                            break;
                        end
                    end
                catch
                    continue;
                end
            end
        end

        % 如果仍然没有找到时间向量
        if ~time_found
            gui_utils('addLog', handles, sprintf('  ✗ 错误: 无法找到时间向量'));
            converted_struct = [];
            return;
        end

        %% 2. 处理所有其他属性
        signal_count = 0;
        for i = 1:length(props)
            prop_name = props{i};

            % 跳过已处理的时间字段
            if strcmpi(prop_name, 'tout') || strcmpi(prop_name, 'time')
                continue;
            end

            try
                prop_data = sim_output.(prop_name);

                if isnumeric(prop_data)
                    % 直接是数值数据
                    converted_struct.(prop_name) = prop_data;
                    signal_count = signal_count + 1;

                elseif isobject(prop_data)
                    % 处理对象类型的数据
                    extracted = extractFromObjectForGUI(prop_data, prop_name, handles);
                    if ~isempty(extracted)
                        % 将提取的字段合并到结果中
                        field_names = fieldnames(extracted);
                        for j = 1:length(field_names)
                            field_name = field_names{j};
                            converted_struct.(field_name) = extracted.(field_name);
                            signal_count = signal_count + 1;
                        end
                    end

                elseif isstruct(prop_data)
                    % 如果是结构体，直接复制
                    converted_struct.(prop_name) = prop_data;
                    signal_count = signal_count + 1;
                end

            catch ME2
                gui_utils('addLog', handles, sprintf('  ! 警告: 无法处理属性 %s: %s', prop_name, ME2.message));
            end
        end

        gui_utils('addLog', handles, sprintf('  ✓ 转换完成: 1个时间向量 + %d个信号字段', signal_count));

        % 显示最终结果字段
        final_fields = fieldnames(converted_struct);
        gui_utils('addLog', handles, sprintf('  最终字段: %s', strjoin(final_fields, ', ')));

    catch ME
        gui_utils('addLog', handles, sprintf('  ✗ 转换出错: %s', ME.message));
        converted_struct = [];
    end
end

%% GUI专用的从对象中提取数据的辅助函数
function extracted = extractFromObjectForGUI(obj, base_name, handles)
    extracted = struct();

    try
        % 检查常见的数据属性
        if isprop(obj, 'Data') && isnumeric(obj.Data)
            extracted.(base_name) = obj.Data;
            gui_utils('addLog', handles, sprintf('  ✓ 提取对象数据: %s.Data', base_name));

        elseif isprop(obj, 'Values') && isnumeric(obj.Values)
            extracted.(base_name) = obj.Values;
            gui_utils('addLog', handles, sprintf('  ✓ 提取对象值: %s.Values', base_name));

        elseif isprop(obj, 'signals')
            % 处理Dataset类型的对象
            signals = obj.signals;
            if isstruct(signals)
                signal_names = fieldnames(signals);
                gui_utils('addLog', handles, sprintf('  ✓ 找到Dataset对象，包含 %d 个信号', length(signal_names)));
                for i = 1:length(signal_names)
                    signal_name = signal_names{i};
                    signal_data = signals.(signal_name);
                    if isnumeric(signal_data)
                        extracted.(signal_name) = signal_data;
                    end
                end
            end

        else
            % 尝试其他可能的属性
            obj_props = properties(obj);
            for i = 1:length(obj_props)
                prop_name = obj_props{i};
                try
                    prop_data = obj.(prop_name);
                    if isnumeric(prop_data) && ~isempty(prop_data)
                        field_name = sprintf('%s_%s', base_name, prop_name);
                        extracted.(field_name) = prop_data;
                    end
                catch
                    continue;
                end
            end
        end

    catch ME
        gui_utils('addLog', handles, sprintf('  ! 从对象 %s 提取数据时出错: %s', base_name, ME.message));
    end
end