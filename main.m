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
        'plot_time_response_universal';
        'quick_config';
        'analysis_half_v2';
        'suspension_analysis_gui';
        'convert_simulink_output';
        'calculate_rms_universal';
        'calculate_band_rms_universal';
        'plot_band_rms_comparison_universal';
        'plot_extreme_comparison_universal';
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

fprintf('\n🧪 **测试与诊断**:\n');
fprintf('   test_data_role_mapping              %% 数据角色映射测试\n');
fprintf('   quick_data_check                    %% 快速数据结构验证\n');
fprintf('   diagnose_data_structure             %% 详细数据格式诊断\n');

fprintf('\n🔧 **数据转换工具**:\n');
fprintf('   convert_simulink_output             %% 转换Simulink输出格式\n');
fprintf('   convert_your_data                   %% 自定义数据文件转换\n');

fprintf('\n📚 **学习资源**:\n');
fprintf('   example_usage                       %% 详细使用示例\n');
fprintf('   open(''README.md'')                   %% 项目文档\n');

fprintf('\n🗂️ **项目结构**:\n');
fprintf('   src/models/          - 数学模型 (状态空间、观测器)\n');
fprintf('   src/analysis/core/   - 核心分析引擎和配置管理\n');
fprintf('   src/analysis/plotting/ - 通用绘图函数 (支持中英文)\n');
fprintf('   src/analysis/legacy/ - 原版分析函数 (向后兼容)\n');
fprintf('   src/scripts/         - 用户调用脚本\n');
fprintf('   src/gui/             - 模块化图形界面组件\n');
fprintf('   tools/               - 数据转换和诊断工具\n');
fprintf('   simulink/           - Simulink模型文件\n');
fprintf('   docs/               - 文档和示例\n');
fprintf('   results/            - 分析结果输出目录\n');

fprintf('\n========================================\n');
fprintf('项目初始化完成！开始您的悬架分析之旅吧！\n');
fprintf('========================================\n');

%% 4. 选择启动方式
fprintf('\n选择启动方式:\n');
fprintf('1. 图形界面 (GUI) - 新用户推荐\n');
fprintf('2. 快速数据检查和测试\n');
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
        fprintf('\n正在运行快速数据检查和测试...\n');
        try
            if exist('quick_data_check', 'file')
                quick_data_check;
            elseif exist('test_data_role_mapping', 'file')
                test_data_role_mapping;
            else
                fprintf('测试文件不可用，跳过测试步骤。\n');
            end
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
