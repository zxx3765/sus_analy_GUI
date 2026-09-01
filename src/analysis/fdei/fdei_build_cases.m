function sine_cases = fdei_build_cases(cfg)
%FDEI_BUILD_CASES Build [frequency_Hz, displacement_amplitude_m] cases.

if ~isstruct(cfg)
    error('fdei_build_cases:InvalidConfig', 'cfg 必须是结构体。');
end
frequencyHz = double(cfg.frequencyHz(:));
if isempty(frequencyHz) || any(~isfinite(frequencyHz)) || any(frequencyHz <= 0)
    error('fdei_build_cases:InvalidFrequency', ...
        'frequencyHz 必须是非空的正有限向量。');
end

mode = lower(strtrim(char(string(cfg.amplitudeMode))));
switch mode
    case {'legacy_a_over_f', 'legacy_a/f'}
        scale = scalarField(cfg, 'legacyAmplitudeScale');
        amplitudes = scale ./ frequencyHz;
    case 'constant_velocity'
        velocity = scalarField(cfg, 'constantRoadVelocityPeak_mps');
        amplitudes = velocity ./ (2*pi*frequencyHz);
    case {'constant_displacement', 'constant_amplitude'}
        amplitude = scalarField(cfg, 'constantRoadDisplacement_m');
        amplitudes = repmat(amplitude, size(frequencyHz));
    case 'manual'
        if ~isfield(cfg, 'manualSineCases') || ...
                ~isnumeric(cfg.manualSineCases) || ...
                size(cfg.manualSineCases, 2) ~= 2 || isempty(cfg.manualSineCases)
            error('fdei_build_cases:InvalidManualCases', ...
                'manual 模式需要非空 N×2 数值 manualSineCases。');
        end
        sine_cases = double(cfg.manualSineCases);
        if any(~isfinite(sine_cases(:))) || any(sine_cases(:,1) <= 0) || ...
                any(sine_cases(:,2) < 0)
            error('fdei_build_cases:InvalidManualCases', ...
                'manualSineCases 的频率必须为正，幅值必须为非负有限值。');
        end
        return;
    otherwise
        error('fdei_build_cases:InvalidAmplitudeMode', ...
            '不支持的幅值模式：%s。', mode);
end

if any(~isfinite(amplitudes)) || any(amplitudes < 0)
    error('fdei_build_cases:InvalidAmplitude', ...
        '生成的道路幅值必须为非负有限值。');
end
sine_cases = [frequencyHz, amplitudes];
end

function value = scalarField(cfg, fieldName)
if ~isfield(cfg, fieldName) || ~(isnumeric(cfg.(fieldName)) && ...
        isscalar(cfg.(fieldName)) && isfinite(cfg.(fieldName)) && ...
        cfg.(fieldName) >= 0)
    error('fdei_build_cases:InvalidAmplitudeParameter', ...
        '%s 必须是非负有限标量。', fieldName);
end
value = double(cfg.(fieldName));
end
