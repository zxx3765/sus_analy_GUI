# Simulink数据转换使用指南

## 问题说明

您的数据文件包含`Simulink.SimulationOutput`对象，这是Simulink较新版本的输出格式。GUI需要标准的结构体格式数据。

## 解决方案

### 方法1: 使用专用转换脚本 (推荐)

```matlab
% 1. 设置路径
setup_paths(false)

% 2. 运行转换脚本 (请先修改脚本中的文件路径)
convert_your_data

% 3. 在GUI中导入转换后的文件
suspension_analysis_gui
```

### 方法2: 使用通用转换工具

```matlab
% 1. 设置路径
setup_paths(false)

% 2. 运行通用转换工具
convert_simulink_output  % 会弹出文件选择对话框
```

### 方法3: 手动修改脚本路径

如果您的文件路径不同，请：

1. 打开 `tools/convert_your_data.m`
2. 修改第6-7行的文件路径：
   ```matlab
   input_file = '您的文件路径/random_20s.mat';
   output_file = '您的文件路径/random_20s_converted.mat';
   ```
3. 运行脚本

## 预期结果

转换成功后，您应该看到：
```
=== 转换完成 ===
✓ out_passive: 结构体格式, 包含时间向量
✓ out_skyhook: 结构体格式, 包含时间向量
```

## 在GUI中使用

转换完成后：
1. 启动GUI: `suspension_analysis_gui`
2. 点击"从文件导入数据"
3. 选择转换后的文件 (例如: `random_20s_converted.mat`)
4. 应该能成功导入并看到详细信息

## 故障排除

如果转换失败：
1. 检查原始文件路径是否正确
2. 确保有写入权限
3. 运行 `diagnose_data_structure` 查看详细信息

## 从源头解决

为了避免以后遇到同样的问题，在Simulink中可以设置输出格式：
1. 在模型配置中设置数据导出格式为结构体
2. 或使用To Workspace块保存为结构体格式