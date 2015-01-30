function compute_kp_APK(annot,pred,alpha)
%% compute_kp_APK() computes apk results for keypoint predictions 
%% with tolerance alpha
%% Input
% annot : ground truth annotations
% pred  : keypoint predictions
% alpha : tolerance of the metric

%%

% get rid of flipped annotations if they exist
annot = select_annotations(annot,~annot.img_flipped);
torso_kps = {'R_Shoulder','L_Shoulder','R_Hip','L_Hip'};
[dum torso_ind] = ismember(torso_kps,annot.kps_labels);
Kp = length(annot.kps_labels);

% count number of valid keypoints
for ki=1:Kp
    cc = annot.coords(ki,1,:);
    cc = cc(:);
    kps_counts(ki) = sum(~isnan(cc));
    clear cc;
end

% Note: we evaluate pose estimation only on images with GT annotations
image_names = unique(annot.img_name);

covered = cell(Kp,1);
scrs  = cell(Kp,1);
lbls  = cell(Kp,1);

for i=1:length(image_names)
    
    fprintf('[%d/%d]\n',i,length(image_names));
    
    img_name  = image_names{i};
    
    % GT
    in_a = find(strcmp(img_name,annot.img_name));
    gt_bounds = annot.bounds(in_a,:);
    gt_coords = annot.coords(:,1:2,in_a);
    
    % Predictions
    in_pred = strcmp(img_name,pred.img_name);
    coords  = pred.coords(:,1:2,in_pred);
    scores  = pred.scores(:,in_pred);
    
    for ki=1:Kp
        [s si] = sort(scores(ki,:),'descend');
        kp_scrs{ki} = scores(ki,si);
        crds{ki}    = coords(:,:,si);
    end
    
    % evaluate each prediction
    for j=1:size(coords,3)
        
        for ki=1:Kp
            % compute the distance of keypoint ki to the GT ki's
            dist = nan(length(in_a),1);
            for a=1:length(in_a)
                if ~isnan(gt_coords(ki,1,a))
                    dist(a)=norm(gt_coords(ki,:,a)-crds{ki}(ki,:,j));
                end
                
                temp_gt_coords = gt_coords(:,:,a);
                temp_torso = temp_gt_coords(torso_ind,:);
                temp_torso = [min(temp_torso,[],1) ...
                    max(temp_torso,[],1)-min(temp_torso,[],1)];
                thresh = alpha*temp_torso(4);
                dist(a) = dist(a)/thresh;
            end
            
            [dist a] = min(dist);
                        
            scrs{ki} = [scrs{ki} kp_scrs{ki}(j)];
            if dist<=1 && ~ismember(in_a(a),covered{ki})
                covered{ki} = [covered{ki} in_a(a)];
                lbls{ki} = [lbls{ki} true];
            else
                lbls{ki} = [lbls{ki} false];
            end
            
        end
        
    end
        
end


for ki=1:Kp
    [ap(ki),rec,prec,scores] = get_precision_recall(scrs{ki}',lbls{ki}','max',kps_counts(ki));
    fprintf('%s : AP = %.2f -- Recall = %.2f\n',annot.kps_labels{ki},ap(ki)*100,max(rec)*100);
end
fprintf('Mean = %.2f\n',100*mean(ap(1:17)));
