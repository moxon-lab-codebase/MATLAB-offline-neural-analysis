function [cluster_struct, res] = do_cluster_analysis(rec_results, rr_data, ...
        event_info, window_start, window_end, response_start, response_end, ...
        bin_size, mixed_smoothing, span, consec_bins, bin_gap)

    %% Create cluster results table
    headers = [["chan_group", "string"]; ["channel", "string"]; ["event", "string"]; ...
               ["tot_clusters", "double"]; ["first_first_latency", "double"]; ...
               ["first_last_latency", "double"]; ["first_duration", "double"]; ...
               ["first_peak_latency", "double"]; ["first_peak_response", "double"]; ...
               ["first_corrected_peak", "double"]; ["first_response_magnitude", "double"]; ...
               ["first_corrected_response_magnitude", "double"]; ["first_norm_response_magnitude", "double"]; ...
               ["primary_first_latency", "double"]; ["primary_last_latency", "double"]; ...
               ["primary_duration", "double"]; ["primary_peak_latency", "double"]; ...
               ["primary_peak_response", "double"]; ["primary_corrected_peak", "double"]; ...
               ["primary_response_magnitude", "double"]; ["primary_corrected_response_magnitude", "double"]; ...
               ["primary_norm_response_magnitude", "double"]; ["last_first_latency", "double"]; ...
               ["last_last_latency", "double"]; ["last_duration", "double"]; ["last_peak_latency", "double"]; ...
               ["last_peak_response", "double"]; ["last_corrected_peak", "double"]; ...
               ["last_response_magnitude", "double"]; ["last_corrected_response_magnitude", "double"]; ...
               ["last_norm_response_magnitude", "double"]];
    res = prealloc_table(headers, [0, size(headers, 1)]);
    cluster_struct = struct;

    %% Get info on chan_group, events, and bins
    [~, tot_bins] = get_bins(window_start, window_end, bin_size);
    unique_ch_groups = fieldnames(rr_data);
    unique_events = unique(event_info.event_labels);
    for ch_group_i = 1:numel(unique_ch_groups)
        ch_group = unique_ch_groups{ch_group_i};
        chan_order = rr_data.(ch_group).chan_order;
        for event_i = 1:numel(unique_events)
            event = unique_events{event_i};
            sig_chans = rec_results.channel(strcmpi(rec_results.chan_group, ch_group) ...
                & strcmpi(rec_results.event, event) & rec_results.significant == 1, :);
            [~, sig_chan_i, ~] = intersect(chan_order, sig_chans);
            if isempty(sig_chan_i)
                %% Skips event if there are not significant channels
                continue
            end
            event_indices = event_info.event_indices(strcmpi(event_info.event_labels, event), :);
            for sig_i = 1:numel(sig_chan_i)
                chan_i = sig_chan_i(sig_i);
                chan = chan_order{chan_i};
                threshold = rec_results.threshold(strcmpi(rec_results.chan_group, ch_group) ...
                    & strcmpi(rec_results.event, event) & strcmpi(rec_results.channel, chan), :);
                bfr = rec_results.background_rate(strcmpi(rec_results.chan_group, ch_group) ...
                    & strcmpi(rec_results.event, event) & strcmpi(rec_results.channel, chan), :);
                %% Get channel relative response
                chan_e = chan_i * tot_bins;
                chan_s = chan_e - tot_bins + 1;
                chan_rr = rr_data.(ch_group).relative_response(event_indices, chan_s:chan_e);
                [chan_clusters, cluster_res] = find_clusters(chan_rr, ...
                    window_start, window_end, response_start, response_end, ...
                    bin_size, mixed_smoothing, span, bin_gap, consec_bins, bfr, threshold);
                %% Append on other results to array
                if ~isempty(cluster_res)
                    cluster_struct.(ch_group).(chan).(event) = chan_clusters;
                    a = [{ch_group}, {chan}, {event}, num2cell(cluster_res)];
                    res = vertcat_cell(res, a, headers(:, 1), "after");
                end
            end
        end
    end
end

function [res, res_array] = find_clusters(chan_rr, window_start, window_end, ...
    response_start, response_end, bin_size, mixed_smoothing, span, bin_gap, consec_bins, bfr, threshold)
    res = struct; res_array = [];
    [response_edges, ~] = get_bins(response_start, response_end, bin_size);

    %% Create psth
    psth = calc_psth(chan_rr);
    psth = smooth(psth, span)';
    response_psth = slice_rr(psth, bin_size, window_start, ...
        window_end, response_start, response_end);

    supra_i = find(response_psth > threshold);
    %% Explanation of dark magic below
    % diff calculates diff of indices in supra_i (points where bins cross threshold)
    % find then looks at the diff array and find the indices in supra_i that are larger than the bin gap
    % 0 is prepended so that the first cluster starts at the beginning of the response
    % 0 is prepended instead of 1 being cluster_edges_i is used as a start exlusive array and +1 is needed to get the right index
    % numel(supra_i) is appended to end the last cluster since cluster_edges_i is start exclusive
    cluster_edges_i = [0, find(diff(supra_i) >= bin_gap), numel(supra_i)];

    curr_cluster = 'cluster_1'; tot_clusters = 1;
    max_rm = 0; primary_cluster = curr_cluster;
    res.(curr_cluster) = struct;
    for cluster_i = 1:length(cluster_edges_i) - 1
        cluster_s = cluster_edges_i(cluster_i) + 1; % getting start exclusive range
        cluster_e = cluster_edges_i(cluster_i + 1); % +1 to grab the next index in the array
        cluster_indices = supra_i(cluster_s:cluster_e); % use edges to grab all indices for cluster

        if length(cluster_indices) < consec_bins || ~check_consec_bins(cluster_indices, consec_bins)
            %% if cluster does not meet definition of a significant response, skip to next cluster
            continue
        end

        %% Compare current cluster to max response
        fl_i = cluster_indices(1); ll_i = cluster_indices(end);
        [fl, ll, duration] = get_response_latencies(response_edges, fl_i, ll_i);
        [sig_edges, ~] = get_bins(fl, ll, bin_size);
        if mixed_smoothing
            %% Unsmooth if mixed_smoothing is true
            psth = calc_psth(chan_rr);
            response_psth = slice_rr(psth, bin_size, window_start, ...
                window_end, response_start, response_end);
        end
        sig_psth = response_psth(fl_i:ll_i);
        [pl, peak, corrected_peak, rm, corrected_rm] = calc_response_rf(...
            bfr, sig_psth, duration, sig_edges);
        if rm > max_rm
            max_rm = rm;
            primary_cluster = curr_cluster;
        end
        cluster_res = [fl, ll, duration, pl, peak, corrected_peak, rm, corrected_rm, rm];

        %% Store and update cluster info
        res.(curr_cluster).cluster_indices = cluster_indices;
        res.(curr_cluster).res = cluster_res;
        if cluster_i < length(cluster_edges_i) - 1
            tot_clusters = tot_clusters + 1;
            curr_cluster = ['cluster_', num2str(tot_clusters)];
        end
    end
    all_clusters = fieldnames(res);
    if length(all_clusters) == 1
        %% Return if there is only 1 valid cluster
        return
    end
    %% Grab cluster results
    first_res = res.(all_clusters{1}).res;
    primary_res = res.(primary_cluster).res;
    last_res = res.(all_clusters{end}).res;
    %% Normalize rm across clusters
    first_res(end) = first_res(end) / max_rm;
    last_res(end) = last_res(end) / max_rm;
    primary_res(end) = primary_res(end) / max_rm;
    %% Store results
    res_array = [tot_clusters, first_res, primary_res, last_res];
    res.first_cluster = res.(all_clusters{1});
    res.last_cluster = res.(all_clusters{end});
    res.primary_cluster = res.(primary_cluster);
    res.supra_i = supra_i; res.cluster_edges_i = cluster_edges_i;
end