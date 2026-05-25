%% 实验数据结构诊断脚本
% 用于检查实验数据的实际结构

fprintf('=== 实验数据结构诊断 ===\n\n');

% 检查工作空间中的实验数据变量
vars = evalin('base', 'who');
exp_vars = {};

fprintf('正在搜索实验数据变量...\n');
for i = 1:length(vars)
    var_name = vars{i};
    try
        var_data = evalin('base', var_name);
        if isstruct(var_data) && isfield(var_data, 'X') && isfield(var_data, 'Y')
            exp_vars{end+1} = var_name;
            fprintf('找到实验数据: %s\n', var_name);
        end
    catch
        continue;
    end
end

if isempty(exp_vars)
    fprintf('\n未找到实验数据变量。\n');
    fprintf('请先加载实验数据到工作空间，例如:\n');
    fprintf('  DATA = load("your_data_file.mat");\n');
    fprintf('  exp_data = DATA.Random_0A;\n');
    return;
end

% 选择第一个实验数据进行分析
var_name = exp_vars{1};
exp_data = evalin('base', var_name);

fprintf('\n=== 分析变量: %s ===\n', var_name);

% 检查X字段
if isfield(exp_data, 'X') && ~isempty(exp_data.X)
    fprintf('\nX字段 (时间数据):\n');
    fprintf('  数组长度: %d\n', length(exp_data.X));

    if ~isempty(exp_data.X)
        X_data = exp_data.X(1).Data;
        fprintf('  X(1).Data 大小: %s\n', mat2str(size(X_data)));
        fprintf('  X(1).Data 类型: %s\n', class(X_data));
        fprintf('  X(1).Data 范围: [%.6f, %.6f]\n', min(X_data(:)), max(X_data(:)));

        % 显示前几个值
        if numel(X_data) > 0
            fprintf('  前5个值: ');
            disp(X_data(1:min(5, numel(X_data))));
        end
    end
end

% 检查Y字段
if isfield(exp_data, 'Y') && ~isempty(exp_data.Y)
    fprintf('\nY字段 (信号数据):\n');
    fprintf('  信号数量: %d\n', length(exp_data.Y));

    % 检查前几个信号
    for i = [1, 3, 13, 14, 16]
        if i <= length(exp_data.Y)
            Y_data = exp_data.Y(i).Data;
            fprintf('\n  Y(%d).Data:\n', i);
            fprintf('    大小: %s\n', mat2str(size(Y_data)));
            fprintf('    类型: %s\n', class(Y_data));
            fprintf('    范围: [%.6f, %.6f]\n', min(Y_data(:)), max(Y_data(:)));
            fprintf('    非零元素数: %d / %d\n', sum(Y_data(:) ~= 0), numel(Y_data));
        end
    end
end

fprintf('\n=== 诊断完成 ===\n');
