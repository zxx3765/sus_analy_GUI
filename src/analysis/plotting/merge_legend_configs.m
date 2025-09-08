function merged_config = merge_legend_configs(base_config, preset_config)
%% 合并图例配置函数
% 将预设配置与基础配置合并，预设配置优先
%
% 输入参数:
%   base_config: 基础配置结构体
%   preset_config: 预设配置结构体
%
% 输出参数:
%   merged_config: 合并后的配置结构体

merged_config = base_config;

% 获取预设配置的所有字段
preset_fields = fieldnames(preset_config);

% 逐个字段合并，预设配置优先
for i = 1:length(preset_fields)
    field_name = preset_fields{i};
    
    % 跳过一些特殊字段，保留原有的标签设置
    if strcmp(field_name, 'labels') || strcmp(field_name, 'final_labels')
        continue;
    end
    
    % 应用预设值
    merged_config.(field_name) = preset_config.(field_name);
end

% 保留原有的标签设置，但可以应用自定义映射
if isfield(preset_config, 'custom_labels') && ~isempty(preset_config.custom_labels)
    % 应用自定义标签映射
    if isfield(base_config, 'final_labels')
        merged_config.final_labels = base_config.final_labels;
        for i = 1:length(merged_config.final_labels)
            original_label = merged_config.final_labels{i};
            if preset_config.custom_labels.isKey(original_label)
                merged_config.final_labels{i} = preset_config.custom_labels(original_label);
            end
        end
    end
end

end
