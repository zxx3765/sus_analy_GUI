% Batch process all MultiSine HIL data files - truncate to first 4 seconds

base_dir = 'D:\Project\SynologyDrive\analysis_GUI\HILData\HILData0525\';

files = {
    'MultiSine_0A.mat'
    'MultiSine_FDC.mat'
    'MultiSine_MultiIF.mat'
    'MultiSine_SHADD.mat'
};

fprintf('Processing %d files...\n\n', length(files));

for i = 1:length(files)
    input_file = fullfile(base_dir, files{i});
    [~, name, ext] = fileparts(files{i});
    output_file = fullfile(base_dir, [name '_truncated' ext]);

    fprintf('=== [%d/%d] %s ===\n', i, length(files), files{i});

    try
        truncate_hil_multisine(input_file, output_file, 4);
        fprintf('SUCCESS\n\n');
    catch ME
        fprintf('ERROR: %s\n\n', ME.message);
    end
end

fprintf('All done!\n');
