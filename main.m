%% 悬架分析项目主启动脚本
% 运行此脚本来初始化项目环境并开始使用

clc; clear;

fprintf('========================================\n');
fprintf('    车辆半车悬架控制系统分析工具\n');
fprintf('========================================\n\n');

%% 1. 设置项目路径
fprintf('1. 正在初始化项目环境...\n');
try
    setup_paths(false); % 非交互式运行
    fprintf('   ✓ 项目路径设置完成\n\n');
catch ME
    fprintf('   ✗ 路径设置失败: %s\n\n', ME.message);
    return;
end

%% 2. 验证核心功能
fprintf('2. 正在验证核心功能...\n');
try
    % 检查关键函数是否可用
    key_functions = {
        'suspension_analysis_tool';
        'plot_frequency_response_universal';
        'quick_config';
        'analysis_half_v2';
    };
    
    for i = 1:length(key_functions)
        if exist(key_functions{i}, 'file')
            fprintf('   ✓ %s 可用\n', key_functions{i});
        else
            fprintf('   ✗ %s 不可用\n', key_functions{i});
        end
    end
    fprintf('   ✓ 核心功能验证完成\n\n');
catch ME
    fprintf('   ✗ 功能验证失败: %s\n\n', ME.message);
end

%% 3. 显示使用指南
fprintf('3. 使用指南:\n');
fprintf('\n🖥️ **图形界面** (新功能):\n');
fprintf('   launch_gui                          %% 启动图形化分析界面\n');
fprintf('   suspension_analysis_gui             %% 直接启动GUI\n');

fprintf('\n📊 **快速分析** (推荐新用户):\n');
fprintf('   analysis_half_v2                    %% 自动检测数据并分析\n');

fprintf('\n🔧 **自定义分析**:\n');
fprintf('   config = quick_config(''half'', ''cn'', true);\n');
fprintf('   suspension_analysis_tool(data_sets, labels, ''Config'', config);\n');

fprintf('\n🧪 **测试功能**:\n');
fprintf('   test_optimized_tools                %% 完整功能测试\n');
fprintf('   test_functions_fix                  %% 基础函数测试\n');

fprintf('\n📚 **学习资源**:\n');
fprintf('   example_usage                       %% 详细使用示例\n');
fprintf('   open(''README.md'')                   %% 项目文档\n');

fprintf('\n🗂️ **项目结构**:\n');
fprintf('   src/models/          - 数学模型 (状态空间、观测器)\n');
fprintf('   src/analysis/        - 分析工具和绘图函数\n');
fprintf('   src/scripts/         - 用户调用脚本\n');
fprintf('   src/gui/             - 图形化界面 (新增)\n');
fprintf('   simulink/           - Simulink模型文件\n');
fprintf('   docs/               - 文档和示例\n');
fprintf('   tests/              - 测试脚本\n');

fprintf('\n========================================\n');
fprintf('项目初始化完成！开始您的悬架分析之旅吧！\n');
fprintf('========================================\n');

%% 4. 选择启动方式
fprintf('\n选择启动方式:\n');
fprintf('1. 图形界面 (GUI) - 新用户推荐\n');
fprintf('2. 快速测试工具\n');
fprintf('3. 仅完成初始化\n');

choice = input('请选择 (1-3): ', 's');

switch choice
    case '1'
        fprintf('\n启动图形界面...\n');
        try
            launch_gui;
        catch ME
            fprintf('GUI启动失败: %s\n', ME.message);
            fprintf('您可以稍后手动运行: launch_gui\n');
        end
        
    case '2' 
        fprintf('\n正在运行快速测试...\n');
        try
            test_functions_fix;
        catch ME
            fprintf('测试失败: %s\n', ME.message);
        end
        
    case '3'
        fprintf('\n初始化完成，您可以开始使用了！\n');
        
    otherwise
        fprintf('\n无效选择，初始化完成。\n');
        fprintf('您可以运行以下命令:\n');
        fprintf('  launch_gui        - 启动图形界面\n');
        fprintf('  analysis_half_v2  - 命令行分析\n');
end