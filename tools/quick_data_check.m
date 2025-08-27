%% quick_data_check.m - 快速检查数据文件
% 快速检查数据文件是否与GUI兼容

fprintf('=== 快速数据文件检查 ===\n');

%% 选择文件
[filename, pathname] = uigetfile('*.mat', '选择要检查的数据文件');
if isequal(filename, 0)
    fprintf('未选择文件，退出\n');
    return;
end

filepath = fullfile(pathname, filename);
fprintf('检查文件: %s\n\n', filename);

try
    %% 加载和检查
    loaded_data = load(filepath);
    field_names = fieldnames(loaded_data);
    
    fprintf('文件包含 %d 个变量: %s\n\n', length(field_names), strjoin(field_names, ', '));
    
    %% 逐一检查变量
    compatible_count = 0;
    
    for i = 1:length(field_names)
        var_name = field_names{i};
        var_data = loaded_data.(var_name);
        
        fprintf('变量 %d: %s\n', i, var_name);
        
        if isstruct(var_data)
            struct_fields = fieldnames(var_data);
            fprintf('  类型: 结构体, 包含 %d 个字段\n', length(struct_fields));
            fprintf('  字段: %s\n', strjoin(struct_fields, ', '));
            
            % 检查时间字段
            has_time = false;
            time_field = '';
            if isfield(var_data, 'tout')
                has_time = true;
                time_field = 'tout';
            elseif isfield(var_data, 'time')
                has_time = true;
                time_field = 'time';
            elseif isfield(var_data, 't')
                has_time = true;
                time_field = 't';
            end
            
            if has_time
                time_data = var_data.(time_field);
                if isnumeric(time_data) && length(time_data) > 1
                    fprintf('  ✓ 兼容: 找到时间字段 "%s", 长度 %d, 范围 %.3f-%.3f\n', ...
                        time_field, length(time_data), time_data(1), time_data(end));
                    compatible_count = compatible_count + 1;
                    
                    % 检查其他字段
                    if isfield(var_data, 'y_bus')
                        y_size = size(var_data.y_bus);
                        fprintf('    有 y_bus: %s\n', mat2str(y_size));
                    else
                        fprintf('    缺少 y_bus 字段\n');
                    end
                    
                    if isfield(var_data, 'xr')
                        xr_size = size(var_data.xr);
                        fprintf('    有 xr: %s\n', mat2str(xr_size));
                    else
                        fprintf('    缺少 xr 字段\n');
                    end
                else
                    fprintf('  ✗ 时间字段格式错误\n');
                end
            else
                fprintf('  ✗ 不兼容: 缺少时间字段 (tout/time/t)\n');
            end
        else
            fprintf('  类型: %s, 大小: %s\n', class(var_data), mat2str(size(var_data)));
            fprintf('  ✗ 不兼容: 不是结构体\n');
        end
        
        fprintf('\n');
    end
    
    %% 总结
    fprintf('=== 检查结果 ===\n');
    if compatible_count > 0
        fprintf('✓ 找到 %d 个兼容的变量，可以导入GUI\n', compatible_count);
        fprintf('建议: 启动GUI并尝试导入此文件\n');
    else
        fprintf('✗ 未找到兼容的变量\n');
        fprintf('问题: 所有变量都缺少时间字段或不是结构体\n');
        fprintf('解决方案:\n');
        fprintf('1. 确保数据是结构体格式\n');
        fprintf('2. 确保包含时间向量字段 (tout/time/t)\n');
        fprintf('3. 检查仿真设置和数据保存方式\n');
    end
    
catch ME
    fprintf('✗ 检查失败: %s\n', ME.message);
end

fprintf('\n手动诊断命令:\n');
fprintf('>> diagnose_data_structure(''%s'')\n', filepath);