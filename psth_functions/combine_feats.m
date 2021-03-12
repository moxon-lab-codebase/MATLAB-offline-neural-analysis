function [out_struct] = combine_feats(psth_struct)
    unique_features = fieldnames(psth_struct);
    overall_feature = 'all_pow_OFC_LPFC';
    out_struct = struct;
    out_struct.(overall_feature).relative_response = [];
    out_struct.(overall_feature).label_order = [];

    for feature_i = 1:numel(unique_features)
        feature = unique_features{feature_i};
        out_struct.(overall_feature).relative_response = [...
            out_struct.(overall_feature).relative_response, psth_struct.(feature).relative_response];
        out_struct.(overall_feature).label_order = [out_struct.(overall_feature).label_order; psth_struct.(feature).label_order];
    end
end