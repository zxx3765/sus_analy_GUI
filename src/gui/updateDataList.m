function updateDataList(handles)
    if isempty(handles.labels)
        set(handles.dataList, 'String', {'(无数据)'});
    else
        display_labels = cell(size(handles.labels));
        for i = 1:length(handles.labels)
            display_labels{i} = sprintf('%d. %s', i, handles.labels{i});
        end
        set(handles.dataList, 'String', display_labels);
    end

    if exist('updateSimpleDataOrderDropdowns', 'file') == 2
        try
            updateSimpleDataOrderDropdowns(handles);
        catch
        end
    end
    if exist('updateCustomOrderList', 'file') == 2
        try
            updateCustomOrderList(handles);
        catch
        end
    end

    % 刷新数据处理 tab 的数据列表
    if isfield(handles, 'dp_dataList') && ishandle(handles.dp_dataList)
        if isempty(handles.labels)
            set(handles.dp_dataList, 'String', {'(无数据)'});
        else
            strs = cellfun(@(l, i) sprintf('%d. %s', i, l), ...
                handles.labels, num2cell(1:numel(handles.labels)), ...
                'UniformOutput', false);
            set(handles.dp_dataList, 'String', strs);
        end
    end
end
