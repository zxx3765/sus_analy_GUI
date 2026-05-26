function handles = gui_data_processing(parent, handles)
%% 数据处理模块 - 数据截断功能

mainPanel = uipanel('Parent', parent, ...
    'Title', '⚙️ 数据处理', ...
    'Units', 'normalized', ...
    'Position', [0.02, 0.02, 0.96, 0.96], ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.97, 0.97, 0.97]);

uicontrol('Parent', mainPanel, 'Style', 'text', ...
    'String', '选择数据集（可多选）:', ...
    'Units', 'normalized', 'Position', [0.04, 0.88, 0.92, 0.06], ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'BackgroundColor', [0.97, 0.97, 0.97]);

handles.dp_dataList = uicontrol('Parent', mainPanel, 'Style', 'listbox', ...
    'String', {'(无数据)'}, 'Max', 2, ...
    'Units', 'normalized', 'Position', [0.04, 0.70, 0.92, 0.18], ...
    'FontSize', 9);

uicontrol('Parent', mainPanel, 'Style', 'text', ...
    'String', '当前时间范围:', ...
    'Units', 'normalized', 'Position', [0.04, 0.64, 0.45, 0.05], ...
    'HorizontalAlignment', 'left', 'FontSize', 9, ...
    'BackgroundColor', [0.97, 0.97, 0.97]);

handles.dp_rangeText = uicontrol('Parent', mainPanel, 'Style', 'text', ...
    'String', '(未选择)', ...
    'Units', 'normalized', 'Position', [0.04, 0.57, 0.92, 0.07], ...
    'HorizontalAlignment', 'center', 'FontSize', 9, ...
    'BackgroundColor', [0.93, 0.95, 1.0]);

uicontrol('Parent', mainPanel, 'Style', 'pushbutton', ...
    'String', '刷新预览', ...
    'Units', 'normalized', 'Position', [0.25, 0.49, 0.50, 0.07], ...
    'FontSize', 9, ...
    'Callback', {@previewTimeRange, handles});

uicontrol('Parent', mainPanel, 'Style', 'text', ...
    'String', '起始时间 (s)', ...
    'Units', 'normalized', 'Position', [0.04, 0.43, 0.44, 0.05], ...
    'HorizontalAlignment', 'center', 'FontSize', 9, ...
    'BackgroundColor', [0.97, 0.97, 0.97]);

uicontrol('Parent', mainPanel, 'Style', 'text', ...
    'String', '结束时间 (s)', ...
    'Units', 'normalized', 'Position', [0.52, 0.43, 0.44, 0.05], ...
    'HorizontalAlignment', 'center', 'FontSize', 9, ...
    'BackgroundColor', [0.97, 0.97, 0.97]);

handles.dp_startEdit = uicontrol('Parent', mainPanel, 'Style', 'edit', ...
    'String', '0', ...
    'Units', 'normalized', 'Position', [0.04, 0.35, 0.44, 0.08], ...
    'FontSize', 10);

handles.dp_endEdit = uicontrol('Parent', mainPanel, 'Style', 'edit', ...
    'String', '4', ...
    'Units', 'normalized', 'Position', [0.52, 0.35, 0.44, 0.08], ...
    'FontSize', 10);

uicontrol('Parent', mainPanel, 'Style', 'pushbutton', ...
    'String', '执行截断 → 新增数据', ...
    'Units', 'normalized', 'Position', [0.04, 0.26, 0.92, 0.08], ...
    'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.6, 0.85, 0.6], ...
    'Callback', {@executeTruncation, handles});

uicontrol('Parent', mainPanel, 'Style', 'text', ...
    'String', '操作日志:', ...
    'Units', 'normalized', 'Position', [0.04, 0.21, 0.92, 0.04], ...
    'HorizontalAlignment', 'left', 'FontSize', 8, ...
    'BackgroundColor', [0.97, 0.97, 0.97]);

handles.dp_logList = uicontrol('Parent', mainPanel, 'Style', 'listbox', ...
    'String', {}, 'Max', 2, ...
    'Units', 'normalized', 'Position', [0.04, 0.02, 0.92, 0.19], ...
    'FontSize', 8, 'Enable', 'inactive');

end

%% 刷新数据列表
function refreshDpDataList(handles)
    if isempty(handles.labels)
        set(handles.dp_dataList, 'String', {'(无数据)'});
    else
        strs = cellfun(@(l, i) sprintf('%d. %s', i, l), ...
            handles.labels, num2cell(1:numel(handles.labels)), ...
            'UniformOutput', false);
        set(handles.dp_dataList, 'String', strs);
    end
end

%% 刷新预览回调
function previewTimeRange(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    sel = get(handles.dp_dataList, 'Value');
    if isempty(handles.data) || isempty(sel) || sel(1) > numel(handles.data)
        set(handles.dp_rangeText, 'String', '(无数据)');
        return;
    end
    data = handles.data{sel(1)};
    if isMultiSineStruct(data)
        tv = data.X(1).Data;
    elseif isfield(data, 'tout')
        tv = data.tout;
    else
        set(handles.dp_rangeText, 'String', '(无法读取时间)');
        return;
    end
    set(handles.dp_rangeText, 'String', ...
        sprintf('%.4f  ~  %.4f  s  (%d 点)', tv(1), tv(end), length(tv)));
end

%% 执行截断回调
function executeTruncation(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    sel = get(handles.dp_dataList, 'Value');
    if isempty(handles.data) || isempty(sel)
        msgbox('请先导入并选择数据集', '提示', 'warn');
        return;
    end

    t_start = str2double(get(handles.dp_startEdit, 'String'));
    t_end   = str2double(get(handles.dp_endEdit,   'String'));
    if isnan(t_start) || isnan(t_end) || t_start >= t_end
        msgbox('请输入有效的时间范围（起始 < 结束）', '输入错误', 'error');
        return;
    end

    for k = 1:numel(sel)
        idx = sel(k);
        if idx > numel(handles.data), continue; end
        data = handles.data{idx};
        orig_label = handles.labels{idx};

        if isMultiSineStruct(data)
            new_data = truncateMultiSineStruct(data, t_start, t_end);
            type_str = 'MultiSine';
        else
            new_data = truncateGeneralStruct(data, t_start, t_end);
            type_str = '通用';
        end

        new_label = sprintf('%s_截断[%.2f~%.2f]', orig_label, t_start, t_end);
        handles.data{end+1}   = new_data;
        handles.labels{end+1} = new_label;

        msg = sprintf('[%s] %s -> %s', type_str, orig_label, new_label);
        addDpLog(handles, msg);
        try; gui_utils('addLog', handles, ['数据截断: ' msg]); catch; end
    end

    set(handles.fig, 'UserData', handles);

    if exist('updateDataList', 'file') == 2
        try; updateDataList(handles); catch; end
    end
    refreshDpDataList(handles);
end

%% 通用结构体截断（参考 truncate_hil_data.m）
function new_data = truncateGeneralStruct(data, t_start, t_end)
    time = data.tout;
    idx  = (time >= t_start) & (time <= t_end);
    new_data = data;
    fields = fieldnames(data);
    for i = 1:numel(fields)
        v = data.(fields{i});
        if isnumeric(v) && size(v, 1) == length(time)
            new_data.(fields{i}) = v(idx, :);
        end
    end
end

%% MultiSine 结构体截断（参考 truncate_hil_multisine.m）
function new_data = truncateMultiSineStruct(data, t_start, t_end)
    new_data = data;
    for i = 1:length(data.X)
        tv  = data.X(i).Data;
        idx = (tv >= t_start) & (tv <= t_end);
        new_data.X(i).Data = tv(idx);
    end
    for i = 1:length(data.Y)
        x_idx = data.Y(i).XIndex;
        tv    = data.X(x_idx).Data;
        idx   = (tv >= t_start) & (tv <= t_end);
        new_data.Y(i).Data = data.Y(i).Data(idx);
    end
end

%% 检测是否为 MultiSine 结构
function tf = isMultiSineStruct(data)
    tf = isstruct(data) && isfield(data, 'X') && isfield(data, 'Y') ...
         && isstruct(data.X) && ~isempty(data.X) && isfield(data.X(1), 'Data');
end

%% 写入本地操作日志
function addDpLog(handles, msg)
    try
        timestamp = datestr(now, 'HH:MM:SS');
        entry = sprintf('[%s] %s', timestamp, msg);
        cur = get(handles.dp_logList, 'String');
        if ischar(cur), cur = {cur}; end
        set(handles.dp_logList, 'String', [cur; {entry}]);
        set(handles.dp_logList, 'Value', length(cur) + 1);
    catch
    end
end
