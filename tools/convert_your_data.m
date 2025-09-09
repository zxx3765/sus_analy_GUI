%% convert_your_data.m - 通用Simulink数据文件转换工具
% 自动检测并转换所有Simulink.SimulationOutput变量

fprintf('=== 通用Simulink数据文件转换工具 ===\n');

%% 获取输入文件路径
% 方式1：使用文件选择对话框
[filename, pathname] = uigetfile({'*.mat', 'MATLAB数据文件 (*.mat)'}, ...
                                '选择要转换的数据文件');

if isequal(filename, 0)
    fprintf('用户取消了文件选择\n');
    return;
end

input_file = fullfile(pathname, filename);

% 方式2：如果要使用固定路径，请取消下面的注释并修改路径
% input_file = 'D:\Project\SynologyDrive\Imp_Half\dataset\random_20s.mat';

% 生成输出文件名
[filepath, name, ext] = fileparts(input_file);
output_file = fullfile(filepath, [name '_converted' ext]);

fprintf('输入文件: %s\n', input_file);
fprintf('输出文件: %s\n\n', output_file);

try
    %% 加载原始数据
    fprintf('加载原始数据...\n');
    loaded_data = load(input_file);
    
    % 获取所有变量名
    var_names = fieldnames(loaded_data);
    fprintf('找到 %d 个变量: %s\n\n', length(var_names), strjoin(var_names, ', '));
    
    %% 分析变量类型
    simulink_vars = {};
    struct_vars = {};
    other_vars = {};
    
    for i = 1:length(var_names)
        var_name = var_names{i};
        var_data = loaded_data.(var_name);
        
        if isa(var_data, 'Simulink.SimulationOutput')
            simulink_vars{end+1} = var_name;
        elseif isstruct(var_data)
            struct_vars{end+1} = var_name;
        else
            other_vars{end+1} = var_name;
        end
    end
    
    fprintf('变量分类:\n');
    fprintf('  Simulink.SimulationOutput: %d 个 - %s\n', length(simulink_vars), strjoin(simulink_vars, ', '));
    fprintf('  结构体变量: %d 个 - %s\n', length(struct_vars), strjoin(struct_vars, ', '));
    fprintf('  其他类型: %d 个 - %s\n\n', length(other_vars), strjoin(other_vars, ', '));
    
    %% 转换所有Simulink.SimulationOutput变量
    if isempty(simulink_vars)
        fprintf('警告: 未找到需要转换的Simulink.SimulationOutput变量\n');
        return;
    end
    
    converted_data = struct();
    conversion_success = false;
    
    for i = 1:length(simulink_vars)
        var_name = simulink_vars{i};
        fprintf('=== 转换变量: %s ===\n', var_name);
        
        original_var = loaded_data.(var_name);
        converted_var = convertSimulinkData(original_var, var_name);
        
        if ~isempty(converted_var)
            converted_data.(var_name) = converted_var;
            fprintf('✓ %s 转换成功\n\n', var_name);
            conversion_success = true;
        else
            fprintf('✗ %s 转换失败\n\n', var_name);
        end
    end
    
    %% 复制其他变量（结构体和其他类型）
    fprintf('=== 复制其他变量 ===\n');
    for i = 1:length(struct_vars)
        var_name = struct_vars{i};
        converted_data.(var_name) = loaded_data.(var_name);
        fprintf('✓ 复制结构体变量: %s\n', var_name);
    end
    
    for i = 1:length(other_vars)
        var_name = other_vars{i};
        converted_data.(var_name) = loaded_data.(var_name);
        fprintf('✓ 复制其他变量: %s (%s)\n', var_name, class(loaded_data.(var_name)));
    end
    
    %% 保存转换后的数据
    if conversion_success
        fprintf('\n=== 保存转换后的数据 ===\n');
        
        try
            save(output_file, '-struct', 'converted_data');
            fprintf('✓ 数据已保存到: %s\n', output_file);
        catch ME
            fprintf('✗ 保存失败: %s\n', ME.message);
            return;
        end
        
        %% 验证转换结果
        fprintf('\n=== 验证转换结果 ===\n');
        verification_data = load(output_file);
        
        for i = 1:length(simulink_vars)
            var_name = simulink_vars{i};
            if isfield(verification_data, var_name)
                var_data = verification_data.(var_name);
                if isstruct(var_data) && isfield(var_data, 'tout')
                    time_info = sprintf('时间: %.3f-%.3f s (%d点)', ...
                        var_data.tout(1), var_data.tout(end), length(var_data.tout));
                    fprintf('✓ %s: 结构体格式, 包含时间向量 (%s)\n', var_name, time_info);
                else
                    fprintf('✗ %s: 格式不正确或缺少时间向量\n', var_name);
                end
            else
                fprintf('✗ %s: 在验证文件中未找到\n', var_name);
            end
        end
        
        fprintf('\n=== 转换完成 ===\n');
        fprintf('转换摘要:\n');
        fprintf('  成功转换: %d 个 Simulink.SimulationOutput 变量\n', length(simulink_vars));
        fprintf('  保留原样: %d 个结构体变量\n', length(struct_vars));
        fprintf('  保留原样: %d 个其他变量\n', length(other_vars));
        fprintf('\n转换后的文件: %s\n', output_file);
        fprintf('现在可以在GUI中导入此文件！\n');        
    else
        fprintf('\n✗ 没有成功转换任何变量\n');
    end
    
catch ME
    fprintf('✗ 转换过程出错: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('错误位置: %s (第%d行)\n', ME.stack(1).name, ME.stack(1).line);
    end
end

%% 通用转换函数
function converted_struct = convertSimulinkData(sim_output, var_name)
    converted_struct = struct();
    
    try
        fprintf('  分析 %s 的结构...\n', var_name);
        
        % 获取所有属性
        props = properties(sim_output);
        fprintf('  找到 %d 个属性: %s\n', length(props), strjoin(props, ', '));
        
        %% 1. 寻找时间向量
        time_found = false;
        
        % 方法1: 直接查找时间字段
        if isprop(sim_output, 'tout')
            converted_struct.tout = sim_output.tout;
            fprintf('  ✓ 找到时间向量 (tout): %d 点, %.3f-%.3f s\n', ...
                length(sim_output.tout), sim_output.tout(1), sim_output.tout(end));
            time_found = true;
        elseif isprop(sim_output, 'time')
            converted_struct.tout = sim_output.time;
            fprintf('  ✓ 找到时间向量 (time): %d 点, %.3f-%.3f s\n', ...
                length(sim_output.time), sim_output.time(1), sim_output.time(end));
            time_found = true;
        end
        
        % 方法2: 从其他属性中寻找时间向量
        if ~time_found
            fprintf('  未找到直接时间字段，搜索其他属性...\n');
            for i = 1:length(props)
                prop_name = props{i};
                try
                    prop_data = sim_output.(prop_name);
                    if isobject(prop_data)
                        if isprop(prop_data, 'Time') && isnumeric(prop_data.Time)
                            converted_struct.tout = prop_data.Time;
                            fprintf('  ✓ 从 %s.Time 中提取时间向量: %d 点\n', prop_name, length(prop_data.Time));
                            time_found = true;
                            break;
                        elseif isprop(prop_data, 'time') && isnumeric(prop_data.time)
                            converted_struct.tout = prop_data.time;
                            fprintf('  ✓ 从 %s.time 中提取时间向量: %d 点\n', prop_name, length(prop_data.time));
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
            fprintf('  ✗ 错误: 无法找到时间向量\n');
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
                    fprintf('  ✓ 提取数值信号: %s %s\n', prop_name, mat2str(size(prop_data)));
                    signal_count = signal_count + 1;
                    
                elseif isobject(prop_data)
                    % 处理对象类型的数据
                    extracted = extractFromObject(prop_data, prop_name);
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
                    fprintf('  ✓ 复制结构体: %s\n', prop_name);
                    signal_count = signal_count + 1;
                end
                
            catch ME2
                fprintf('  ! 警告: 无法处理属性 %s: %s\n', prop_name, ME2.message);
            end
        end
        
        fprintf('  ✓ 转换完成: 1个时间向量 + %d个信号字段\n', signal_count);
        
        % 显示最终结果字段
        final_fields = fieldnames(converted_struct);
        fprintf('  最终字段: %s\n', strjoin(final_fields, ', '));
        
    catch ME
        fprintf('  ✗ 转换出错: %s\n', ME.message);
        converted_struct = [];
    end
end

%% 从对象中提取数据的辅助函数
function extracted = extractFromObject(obj, base_name)
    extracted = struct();
    
    try
        % 检查常见的数据属性
        if isprop(obj, 'Data') && isnumeric(obj.Data)
            extracted.(base_name) = obj.Data;
            fprintf('  ✓ 提取对象数据: %s.Data %s\n', base_name, mat2str(size(obj.Data)));
            
        elseif isprop(obj, 'Values') && isnumeric(obj.Values)
            extracted.(base_name) = obj.Values;
            fprintf('  ✓ 提取对象值: %s.Values %s\n', base_name, mat2str(size(obj.Values)));
            
        elseif isprop(obj, 'signals')
            % 处理Dataset类型的对象
            signals = obj.signals;
            if isstruct(signals)
                signal_names = fieldnames(signals);
                fprintf('  ✓ 找到Dataset对象，包含 %d 个信号\n', length(signal_names));
                for i = 1:length(signal_names)
                    signal_name = signal_names{i};
                    signal_data = signals.(signal_name);
                    if isnumeric(signal_data)
                        extracted.(signal_name) = signal_data;
                        fprintf('    - 提取信号: %s %s\n', signal_name, mat2str(size(signal_data)));
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
                        fprintf('  ✓ 提取对象属性: %s %s\n', field_name, mat2str(size(prop_data)));
                    end
                catch
                    continue;
                end
            end
        end
        
    catch ME
        fprintf('  ! 从对象 %s 提取数据时出错: %s\n', base_name, ME.message);
    end
end