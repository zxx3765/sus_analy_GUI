function stopTime = fdei_compute_stop_time(frequencyHz, cfg)
%FDEI_COMPUTE_STOP_TIME Compute a stop time covering transient and steady cycles.

validateattributes(frequencyHz, {'numeric'}, {'scalar','real','finite','positive'});
stopTime = max(cfg.minimumSettlingTime_s + cfg.savedCycles/frequencyHz, ...
    (cfg.transientCycles + cfg.savedCycles)/frequencyHz);
end
