% Process MultiSine_0A.mat - truncate to first 4 seconds
input_file = 'D:\Project\SynologyDrive\analysis_GUI\HILData\HILData0525\MultiSine_0A.mat';
output_file = 'D:\Project\SynologyDrive\analysis_GUI\HILData\HILData0525\MultiSine_0A_truncated.mat';

truncate_hil_multisine(input_file, output_file, 4);
