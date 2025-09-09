function updateCustomOrderList(handles)
% 根据 handles.labels 与已有配置更新“自定义顺序”列表
% 需要 GUI 中存在 handles.customOrderList 控件

if ~isfield(handles, 'customOrderList') || ~ishandle(handles.customOrderList)
    return;
end

if ~isfield(handles, 'labels') || isempty(handles.labels)
    set(handles.customOrderList, 'String', {'(无数据)'});
    set(handles.customOrderList, 'UserData', []);
    set(handles.customOrderList, 'Value', 1);
    return;
end

labels = handles.labels;
N = numel(labels);
order = 1:N;

% 如果配置中已有自定义顺序，按其重排
try
    if isfield(handles, 'config') && isfield(handles.config, 'data_order_list')
        ord = handles.config.data_order_list;
        ord = sanitizeOrderList(ord, N);
        if ~isempty(ord)
            order = ord;
        end
    end
catch
end

strs = arrayfun(@(i) sprintf('%d. %s', order(i), labels{order(i)}), 1:numel(order), 'UniformOutput', false);
set(handles.customOrderList, 'String', strs);
set(handles.customOrderList, 'UserData', order);
set(handles.customOrderList, 'Value', 1);

end

function ord = sanitizeOrderList(order_list, n)
if ~isnumeric(order_list) || isempty(order_list)
    ord = [];
    return;
end
order_list = order_list(:)';
order_list = unique(order_list, 'stable');
order_list = order_list(order_list>=1 & order_list<=n);
rest = setdiff(1:n, order_list, 'stable');
ord = [order_list, rest];
end
