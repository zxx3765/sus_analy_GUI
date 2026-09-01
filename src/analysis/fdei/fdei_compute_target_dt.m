function targetDt = fdei_compute_target_dt(frequencyHz, cfg)
%FDEI_COMPUTE_TARGET_DT Compute the uniform resampling interval.

validateattributes(frequencyHz, {'numeric'}, {'scalar','real','finite','positive'});
targetDt = min(cfg.maxUniformSampleTime_s, ...
    1/(cfg.samplesPerCycle*frequencyHz));
end
