%% 悬架分析GUI启动器
% 这个脚本用于启动悬架分析图形界面

%% 环境设置
fprintf('=== 悬架分析GUI启动器 ===\n');

% 设置路径
try
    if exist('setup_paths', 'file') == 2
        setup_paths(false); % 非交互式运行，避免重复提示
        fprintf('✓ 路径设置完成\n');
    elseif exist('main', 'file') == 2
        main;
        fprintf('✓ 主程序初始化完成\n');
    else
        warning('未找到setup_paths或main函数，尝试手动设置路径');
        % 手动添加GUI路径
        gui_path = fullfile(pwd, 'src', 'gui');
        if exist(gui_path, 'dir')
            addpath(gui_path);
            fprintf('✓ 手动添加GUI路径完成\n');
        end
    end
catch ME
    warning('路径设置失败: %s', ME.message);
    fprintf('尝试手动添加GUI路径...\n');
    
    % 手动添加关键路径
    paths_to_try = {
        fullfile(pwd, 'src', 'gui');
        fullfile(pwd, 'src', 'analysis', 'core');
        fullfile(pwd, 'src', 'analysis', 'plotting');
    };
    
    for i = 1:length(paths_to_try)
        if exist(paths_to_try{i}, 'dir')
            addpath(paths_to_try{i});
            fprintf('✓ 添加路径: %s\n', paths_to_try{i});
        end
    end
end

%% 检查依赖项
fprintf('检查依赖项...\n');

required_functions = {'quick_config', 'suspension_analysis_tool', 'suspension_analysis_config'};
missing_functions = {};

for i = 1:length(required_functions)
    if exist(required_functions{i}, 'file') ~= 2
        missing_functions{end+1} = required_functions{i};
    end
end

if ~isempty(missing_functions)
    fprintf('警告: 以下依赖项缺失:\n');
    for i = 1:length(missing_functions)
        fprintf('  - %s\n', missing_functions{i});
    end
    fprintf('某些功能可能不可用\n');
else
    fprintf('✓ 所有依赖项检查通过\n');
end

%% 检查示例数据
fprintf('检查示例数据...\n');

example_vars = {'out_passive', 'out_sk_ob', 'out_sk', 'out_active'};
available_vars = {};

for i = 1:length(example_vars)
    if evalin('base', sprintf('exist(''%s'', ''var'')', example_vars{i}))
        available_vars{end+1} = example_vars{i};
    end
end

if ~isempty(available_vars)
    fprintf('✓ 找到以下示例数据:\n');
    for i = 1:length(available_vars)
        fprintf('  - %s\n', available_vars{i});
    end
else
    fprintf('提示: 工作空间中没有示例数据\n');
    fprintf('您可以先运行Simulink仿真或导入.mat文件\n');
end

%% 启动GUI
fprintf('\n启动悬架分析GUI...\n');

try
    % 最后检查GUI函数是否可用
    if exist('suspension_analysis_gui', 'file') ~= 2
        fprintf('GUI函数不可用，尝试最后的修复...\n');
        
        % 直接添加GUI路径
        gui_file_path = fullfile(pwd, 'src', 'gui');
        if exist(gui_file_path, 'dir')
            addpath(gui_file_path);
            fprintf('已添加GUI路径: %s\n', gui_file_path);
        end
        
        % 再次检查
        if exist('suspension_analysis_gui', 'file') ~= 2
            error('无法找到GUI函数，请检查文件是否存在');
        end
    end
    
    % 启动GUI
    suspension_analysis_gui();
    fprintf('✓ GUI已成功启动\n');
    
    % 显示使用提示
    fprintf('\n=== 使用提示 ===\n');
    fprintf('1. 从"数据管理"部分导入仿真数据\n');
    fprintf('2. 在"分析配置"部分调整设置\n');
    fprintf('3. 点击"开始分析"执行分析\n');
    fprintf('4. 在"结果查看"部分查看生成的图片和文件\n');
    fprintf('5. 使用时间戳文件夹避免结果覆盖\n');
    
catch ME
    fprintf('✗ GUI启动失败: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('错误位置: %s (第%d行)\n', ME.stack(1).file, ME.stack(1).line);
    end
    
    % 提供详细的故障排除建议
    fprintf('\n=== 详细故障排除 ===\n');
    
    % 检查文件存在性
    gui_file = fullfile(pwd, 'src', 'gui', 'suspension_analysis_gui.m');
    fprintf('1. GUI文件检查:\n');
    fprintf('   文件路径: %s\n', gui_file);
    fprintf('   文件存在: %s\n', mat2str(exist(gui_file, 'file') == 2));
    
    % 检查路径
    fprintf('\n2. 路径检查:\n');
    current_path = path;
    gui_in_path = contains(current_path, 'gui');
    fprintf('   GUI路径已添加: %s\n', mat2str(any(gui_in_path)));
    
    % 提供解决方案
    fprintf('\n3. 手动解决方案:\n');
    fprintf('   运行以下命令:\n');
    fprintf('   >> addpath(''%s'');\n', fullfile(pwd, 'src', 'gui'));
    fprintf('   >> addpath(''%s'');\n', fullfile(pwd, 'src', 'analysis', 'core'));
    fprintf('   >> suspension_analysis_gui;\n');
    
    fprintf('\n4. 替代方案:\n');
    fprintf('   - 运行 fix_gui_paths 尝试自动修复\n');
    fprintf('   - 使用命令行版本: analysis_half_v2\n');
    fprintf('   - 重启MATLAB后重试\n');
    
    fprintf('\n5. 如果问题持续存在:\n');
    fprintf('   - 检查MATLAB版本是否支持GUI功能\n');
    fprintf('   - 确保有创建GUI窗口的权限\n');
    fprintf('   - 运行 test_gui 进行完整诊断\n');
end

fprintf('\n=== 启动完成 ===\n');