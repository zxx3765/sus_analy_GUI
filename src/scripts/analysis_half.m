%% 该脚本用于分析半车仿真结果
%% 加载数据
data_set = [out_passive,out_skyhook_ob,out_skyhook];
labels = {'Passive';'skyhook_ob';'skyhook'};
t = data_set(1).tout;

% 初始化数据
n = length(t);%数据的行数也就是时间步数
m = length(data_set);%数据的列数也就是工况数
as_f_label = zeros(n,m);
as_r_label = zeros(n,m);
as_label = zeros(n,m);
xr_f_label = zeros(n,m);
xr_r_label = zeros(n,m);
xdef_f_label = zeros(n,m);
xdef_r_label = zeros(n,m);
for i = 1:length(data_set)
    data_idx = data_set(:,i);

    as_f_label(:,i) = data_idx.y_bus(:,1);
    as_r_label(:,i) = data_idx.y_bus(:,2);
    as_label(:,i) = data_idx.y_bus(:,7);
    xr_f_label(:,i) = data_idx.xr(:,1);
    xr_r_label(:,i) = data_idx.xr(:,2);
    xdef_f_label(:,i) = data_idx.real_x_bus(:,3);
    xdef_r_label(:,i) = data_idx.real_x_bus(:,4);
 end

% x_tire_label = [out_passive.state(:,5)];
% x_def_label = [out_passive.x_def];
colors = lines(length(labels)); % 生成颜色矩阵
%% 
%% %绘制加速度的幅频特性曲线

pic_text_acc = {'Frequency (Hz)','Magnitude (dB)','Acceleration Frequency Response'};
pic_text_xt = {'Frequency (Hz)','Magnitude (dB)','Tire Deflaction Frequency Response'};
pic_text_acc_rms = {'Methods', 'Relative RMS (%)', 'RMS Values of Acceleration'};
pic_text_xt_rms = {'Methods', 'Relative RMS (%)', 'RMS Values of Tire Deflaction'};

plot_frqe_mag_labels(as_f_label,xr_f_label,labels,pic_text_acc);
% xline(11, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5,'HandleVisibility', 'off');
plot_frqe_mag_labels(as_r_label,xr_r_label,labels,pic_text_acc);

plot_frqe_mag_labels(xdef_f_label,xr_f_label,labels,pic_text_xt);
plot_frqe_mag_labels(xdef_r_label,xr_r_label,labels,pic_text_xt);
% xline(11, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5,'HandleVisibility', 'off');
plot_frqe_mag_labels(x_tire_label,xr_labels,labels,pic_text_xt);
xline(11, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5,'HandleVisibility', 'off');
%%
pic_text_acc = {'Frequency (Hz)','Magnitude (dB)','Acceleration Frequency Response'};
pic_text_xt = {'Frequency (Hz)','Magnitude (dB)','Tire Deflaction Frequency Response'};
pic_text_acc_rms = {'Methods', 'Relative RMS (%)', 'RMS Values of Acceleration'};
pic_text_xt_rms = {'Methods', 'Relative RMS (%)', 'RMS Values of Tire Deflaction'};

calculate_rms_and_plot_bar(as_label,labels,pic_text_acc_rms);
calculate_rms_and_plot_bar(x_def_label,labels,pic_text_xt_rms);
calculate_rms_and_plot_bar(x_tire_label,labels,pic_text_xt_rms);
%%  绘制时域信号
% 加速度时域信号
pic_text_acc = {'Time (s)','Front suspension acceleration (m/s^2)','Acceleration'};
plot_time_labels(as_f_label,t,labels,pic_text_acc)
pic_text_acc = {'Time (s)','Rare suspension acceleration (m/s^2)','Acceleration'};
plot_time_labels(as_r_label,t,labels,pic_text_acc)
pic_text_acc = {'Time (s)','Vertical mass acceleration (m/s^2)','Acceleration'};
plot_time_labels(as_label,t,labels,pic_text_acc)

pic_text_x_def = {'Time (s)','Suspension Workingspace (m)','Suspension Deflaction'};
plot_time_labels(x_def_label,t,labels,pic_text_x_def)
pic_text_x_tire = {'Time (s)','Tire Deflaction (m)','Acceleration Frequency Response'};
plot_time_labels(x_tire_label,t,labels,pic_text_x_tire)
