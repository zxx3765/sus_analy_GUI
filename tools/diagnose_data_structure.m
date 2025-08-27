%% diagnose_data_structure.m - 诊断数据文件结构
% 帮助诊断和修复数据导入问题

function diagnose_data_structure(filename)
    if nargin < 1
        [filename, pathname] = uigetfile('*.mat', '选择要诊断的数据文件');
        if isequal(filename, 0)
            return;
        end
        filepath = fullfile(pathname, filename);
    else
        filepath = filename;
    end
    
    fprintf('=== 数据文件结构诊断 ===\n');
    fprintf('文件: %s\n\n', filepath);
    
    try
        % 加载文件
        loaded_data = load(filepath);
        field_names = fieldnames(loaded_data);
        
        fprintf('1. 文件概况:\n');
        fprintf('   包含 %d 个变量\n', length(field_names));
        fprintf('   变量列表: %s\n\n', strjoin(field_names, ', '));
        
        % 分析每个变量
        fprintf('2. 变量详细分析:\n');
        fprintf('%-20s %-10s %-15s %-20s %s\n', '变量名', '类型', '大小', '主要字段', '是否兼容');
        fprintf('%s\n', repmat('-', 1, 80));
        
        for i = 1:length(field_names)
            var_name = field_names{i};
            var_data = loaded_data.(var_name);
            
            % 基本信息
            var_type = class(var_data);
            var_size = sprintf('%s', mat2str(size(var_data)));
            
            % 检查是否为结构体
            if isstruct(var_data)
                struct_fields = fieldnames(var_data);
                main_fields = strjoin(struct_fields(1:min(3, length(struct_fields))), ', ');
                if length(struct_fields) > 3
                    main_fields = [main_fields, '...'];
                end
                
                % 检查兼容性
                has_tout = isfield(var_data, 'tout');
                has_y_bus = isfield(var_data, 'y_bus');
                has_xr = isfield(var_data, 'xr');
                
                if has_tout
                    compatible = '✓ 兼容';
                    if ~has_y_bus && ~has_xr
                        compatible = '⚠ 部分兼容';
                    end
                else
                    compatible = '✗ 不兼容';
                end
                
            else
                main_fields = '(非结构体)';
                compatible = '✗ 不兼容';
            end
            
            fprintf('%-20s %-10s %-15s %-20s %s\n', var_name, var_type, var_size, main_fields, compatible);
        end
        
        fprintf('\n');
        
        % 详细检查兼容的变量
        fprintf('3. 详细结构检查:\n');
        for i = 1:length(field_names)
            var_name = field_names{i};
            var_data = loaded_data.(var_name);
            
            if isstruct(var_data)
                fprintf('\n变量: %s\n', var_name);
                struct_fields = fieldnames(var_data);
                
                % 检查关键字段
                key_fields = {'tout', 'y_bus', 'xr', 'real_x_bus'};
                fprintf('  关键字段检查:\n');
                
                for j = 1:length(key_fields)
                    field = key_fields{j};
                    if isfield(var_data, field)
                        field_data = var_data.(field);
                        field_size = size(field_data);
                        fprintf('    ✓ %s: %s %s\n', field, class(field_data), mat2str(field_size));
                        
                        % 检查数据合理性
                        if strcmp(field, 'tout') && isnumeric(field_data)
                            if length(field_data) > 1
                                dt = field_data(2) - field_data(1);
                                duration = field_data(end) - field_data(1);
                                fprintf('      时间步长: %.4f s, 总时长: %.2f s\n', dt, duration);
                            end
                        elseif strcmp(field, 'y_bus') && isnumeric(field_data)
                            fprintf('      输出通道数: %d\n', size(field_data, 2));
                        elseif strcmp(field, 'xr') && isnumeric(field_data)
                            fprintf('      输入通道数: %d\n', size(field_data, 2));
                        end
                    else
                        fprintf('    ✗ %s: 不存在\n', field);
                    end
                end
                
                % 显示所有字段
                fprintf('  所有字段 (%d个): %s\n', length(struct_fields), strjoin(struct_fields, ', '));
            end
        end
        
        fprintf('\n4. 兼容性建议:\n');
        compatible_vars = 0;
        for i = 1:length(field_names)
            var_name = field_names{i};
            var_data = loaded_data.(var_name);
            
            if isstruct(var_data) && isfield(var_data, 'tout')
                compatible_vars = compatible_vars + 1;
                
                % 检查可能的问题
                issues = {};
                if ~isfield(var_data, 'y_bus')
                    issues{end+1} = '缺少 y_bus 字段';
                end
                if ~isfield(var_data, 'xr')
                    issues{end+1} = '缺少 xr 字段';
                end
                
                if isempty(issues)
                    fprintf('  ✓ %s: 完全兼容\n', var_name);
                else
                    fprintf('  ⚠ %s: 可能的问题 - %s\n', var_name, strjoin(issues, ', '));
                end
            end
        end
        
        if compatible_vars == 0
            fprintf('  ✗ 没有找到兼容的变量\n');
            fprintf('  建议: 确保数据结构包含 tout 字段（时间向量）\n');
        else
            fprintf('  找到 %d 个潜在兼容的变量\n', compatible_vars);
        end
        
    catch ME
        fprintf('✗ 诊断失败: %s\n', ME.message);
    end
    
    fprintf('\n=== 诊断完成 ===\n');
end