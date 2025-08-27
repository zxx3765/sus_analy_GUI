# 车辆悬架控制系统分析工具 (Vehicle Suspension Analysis Tool)

一个基于MATLAB的车辆悬架仿真数据分析工具，提供图形化界面和命令行接口，支持半车和四分之一车模型的性能分析。

## 主要功能

- 🖥️ **图形化界面** - 直观的GUI界面，无需编程经验
- 📊 **多信号分析** - 时域响应、频域响应、RMS统计分析
- 🔧 **灵活配置** - 支持自定义分析参数和信号选择
- 🌐 **多语言支持** - 中文/英文界面切换
- 📁 **结果管理** - 自动生成时间戳文件夹，避免结果覆盖
- 🔄 **数据转换** - 支持Simulink输出格式自动转换

## 快速开始

### 1. 项目初始化

```matlab
% 启动MATLAB后运行
main
```

选择以下启动方式之一：
- **图形界面** (推荐新用户)
- **快速测试工具**
- **仅完成初始化**

### 2. 使用图形界面

```matlab
launch_gui          % 启动GUI（包含依赖检查）
% 或
suspension_analysis_gui  % 直接启动GUI
```

### 3. 命令行分析

```matlab
analysis_half_v2    % 自动检测工作空间数据并分析
```

## 项目结构

```
analysis_GUI/
├── src/
│   ├── models/          # 数学模型（状态空间、观测器）
│   ├── analysis/
│   │   ├── core/        # 核心分析工具
│   │   ├── plotting/    # 通用绘图函数
│   │   └── legacy/      # 原有绘图函数
│   ├── gui/            # GUI模块
│   └── scripts/        # 用户调用脚本
├── tools/              # 数据转换和诊断工具
├── config/             # 配置文件
├── results/            # 分析结果输出
├── main.m              # 主启动脚本
├── launch_gui.m        # GUI启动器
└── setup_paths.m       # 路径设置
```

## 使用指南

### 数据格式要求

支持的仿真数据格式：
```matlab
data_struct.signals.values    % 信号数据矩阵
data_struct.time             % 时间向量
```

### 数据转换

如果您的数据是Simulink.SimulationOutput格式：

```matlab
% 方法1：通用转换工具
convert_simulink_output

% 方法2：批量转换脚本（需修改文件路径）
convert_your_data
```

### 分析配置

```matlab
% 使用预设配置
config = quick_config('half', 'cn', true);

% 自定义分析
suspension_analysis_tool(data_sets, labels, 'Config', config);
```

### 支持的分析类型

- **时域响应分析** - 位移、速度、加速度时间历程
- **频域响应分析** - 传递函数、频率特性
- **RMS统计分析** - 均方根值对比
- **车身舒适性评估** - 基于ISO标准的评价指标

## 故障排除

### GUI无法启动
```matlab
% 手动修复路径
addpath('src/gui');
addpath('src/analysis/core');
suspension_analysis_gui;
```

### 数据导入失败
```matlab
% 诊断数据结构
diagnose_data_structure
quick_data_check
```

### 依赖项检查
```matlab
% 运行完整测试
test_optimized_tools
test_functions_fix
```

## 开发者信息

### 测试

```matlab
test_optimized_tools    % 完整功能测试
test_functions_fix      % 基础函数测试
```

### 路径管理

```matlab
setup_paths            % 交互式路径设置
setup_paths(false)     % 非交互式路径设置
```

## 系统要求

- MATLAB R2016b 或更高版本
- Signal Processing Toolbox（可选，用于高级信号分析）
- Control System Toolbox（可选，用于控制系统分析）

## 许可证

本项目为学术研究和教育用途开发。

## 贡献

欢迎提交问题报告和改进建议。

## 更新日志

### 版本 2.0
- 新增模块化GUI系统
- 支持多语言界面
- 改进数据转换工具
- 优化分析算法性能

### 版本 1.0
- 基础分析功能
- 命令行接口
- 原有绘图系统