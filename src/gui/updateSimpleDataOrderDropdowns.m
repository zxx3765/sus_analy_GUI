function updateSimpleDataOrderDropdowns(handles)
% 更新简化数据顺序设置模块的两个下拉列表
% - 根据 handles.data / handles.labels 的数量与名称动态生成选项
% - 保持当前选择值在有效范围内

    % 生成选项
    if ~isfield(handles, 'data') || isempty(handles.data)
        first_options = {'(默认第1个)'};
        last_options  = {'(默认最后1个)'};
        % 仍然展示至少3项的占位，避免空下拉
        for i = 1:3
            first_options{end+1} = sprintf('数据%d', i); %#ok<AGROW>
            last_options{end+1}  = sprintf('数据%d', i); %#ok<AGROW>
        end
    else
        num_datasets = length(handles.data);
        first_options = cell(1, num_datasets + 1);
        last_options  = cell(1, num_datasets + 1);
        first_options{1} = '(默认第1个)';
        last_options{1}  = '(默认最后1个)';
        for i = 1:num_datasets
            if isfield(handles, 'labels') && ~isempty(handles.labels) && length(handles.labels) >= i
                label = handles.labels{i};
                first_options{i+1} = sprintf('数据%d: %s', i, label);
                last_options{i+1}  = sprintf('数据%d: %s', i, label);
            else
                first_options{i+1} = sprintf('数据%d', i);
                last_options{i+1}  = sprintf('数据%d', i);
            end
        end
    end

    % 应用到控件
    if isfield(handles, 'firstDataDropdown') && ishandle(handles.firstDataDropdown)
        set(handles.firstDataDropdown, 'String', first_options);
        val = get(handles.firstDataDropdown, 'Value');
        if val > numel(first_options)
            set(handles.firstDataDropdown, 'Value', 1);
        end
    end

    if isfield(handles, 'lastDataDropdown') && ishandle(handles.lastDataDropdown)
        set(handles.lastDataDropdown, 'String', last_options);
        val = get(handles.lastDataDropdown, 'Value');
        if val > numel(last_options)
            set(handles.lastDataDropdown, 'Value', 1);
        end
    end

    % 若配置已有映射，则同步值
    if isfield(handles, 'config') && isfield(handles.config, 'data_order_mapping')
        dom = handles.config.data_order_mapping;
        if isfield(dom, 'first_index') && isfield(handles, 'firstDataDropdown') && ishandle(handles.firstDataDropdown)
            fi = dom.first_index; % 1-based
            opts = get(handles.firstDataDropdown, 'String');
            if ~isempty(fi) && fi+1 <= numel(opts)
                set(handles.firstDataDropdown, 'Value', fi+1);
            end
        end
        if isfield(dom, 'last_index') && isfield(handles, 'lastDataDropdown') && ishandle(handles.lastDataDropdown)
            li = dom.last_index; % 1-based
            opts = get(handles.lastDataDropdown, 'String');
            if ~isempty(li) && li+1 <= numel(opts)
                set(handles.lastDataDropdown, 'Value', li+1);
            end
        end
    end

    % 更新状态文字（如果存在）
    if isfield(handles, 'orderStatusText') && ishandle(handles.orderStatusText)
        try
            % 复用模块里的状态更新，如果存在
            if exist('updateOrderStatus', 'file') == 2
                updateOrderStatus(handles); %#ok<UNRCH>
            else
                % 简单显示
                set(handles.orderStatusText, 'String', '数据顺序下拉已更新');
            end
        catch
            % 忽略
        end
    end
end
