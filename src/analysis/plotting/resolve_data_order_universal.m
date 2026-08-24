function order = resolve_data_order_universal(n_datasets, config)
%% 解析分析图中数据集的最终显示顺序
% 先应用自定义顺序，再应用置顶/置底映射。频带RMS计算和绘图共用本函数，
% 从而保证“第一组数据=100%”中的第一组与图中实际顺序一致。

validateattributes(n_datasets, {'numeric'}, ...
    {'scalar', 'integer', 'nonnegative'}, mfilename, 'n_datasets');

order = 1:n_datasets;
if isfield(config, 'data_order_list') && ~isempty(config.data_order_list)
    requested = unique(config.data_order_list(:)', 'stable');
    requested = requested(requested >= 1 & requested <= n_datasets);
    order = [requested, setdiff(order, requested, 'stable')];
end

if isfield(config, 'data_order_mapping') && ~isempty(config.data_order_mapping)
    mapping = config.data_order_mapping;
    if isfield(mapping, 'first_index') && any(order == mapping.first_index)
        order = [mapping.first_index, ...
            setdiff(order, mapping.first_index, 'stable')];
    end
    if isfield(mapping, 'last_index') && any(order == mapping.last_index)
        order = [setdiff(order, mapping.last_index, 'stable'), ...
            mapping.last_index];
    end
end

end
