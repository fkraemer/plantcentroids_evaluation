% Script for SEP evaluation by detection measures.
% Solution and GT SEP pixel masks are expected in separate
% subfolders, both in the same order
% The pixel mask should encode a detection as a non-zero pixel, where its
% value corresponds to the detections score (0-255)

clear all
%
rootFolder = '../../../30_data/160609/images/1150/';
%The ground truth mask files
imagefilesGT = dir(strcat(rootFolder,'label_sparse/*.png'));
% The solution to be evaluated
imagefilesProposal = dir(strcat(rootFolder,'test_segm/*.png'));
nfiles = length(imagefilesGT)    % Number of files found
assert(nfiles == length(imagefilesProposal));

distanceThresholds = [6., 18. 30.];
recallCollected = {};
precisionCollected = {};
for h=1:length(distanceThresholds)
    gtCounter = 0;
    solCounter = 0;
    distanceThresh = distanceThresholds(h);
    
    solutionScores = [];
    solutionSuccess = [];
    solutionDistances = [];
    for i=1:nfiles
        %% data read
        namesplitted = strsplit(imagefilesProposal(i).name,'.');
        rawName = namesplitted{1};
        GT = imread(strcat(imagefilesGT(i).folder,'/',imagefilesGT(i).name) );         
        [gtX, gtY] = ind2sub(size(GT),find(GT));
        gtCounter = gtCounter + size(gtX,1);
        
        solImg = imread(strcat(imagefilesProposal(i).folder,'/',imagefilesProposal(i).name));
        [solX, solY] = ind2sub(size(solImg),find(solImg));
        solRawScores = solImg(find(solImg));
        
        solCounter = solCounter + size(solX,1);

        if isempty(gtX) | isempty(solX)
            continue
        end
        
        [solScores, idx] = sort(solRawScores,'descend');
        solX = solX(idx);
        solY = solY(idx);
        for j= 1:size(solX,1)
            %first compute the closest distance in the GT
            distance2D = [gtX gtY] - [solX(j), solY(j)];
            distances = sqrt( distance2D(:,1).^2 + distance2D(:,2).^2 );
            [minDist, minIdx] = min(distances);
            solutionScores = [solutionScores solScores(j) ];
            if minDist<distanceThresh
                solutionSuccess = [solutionSuccess true];
                solutionDistances = [solutionDistances minDist];
                 %exclude this GT from further being available in the minDist processing
                 gtX(minIdx) = NaN;
                 gtY(minIdx) = NaN;
            else
                solutionSuccess = [solutionSuccess false];             
                solutionDistances = [solutionDistances NaN];   
            end
        end
        
        
        
    end %1:nfiles
    
    %% iterate over all matched solutions from all files
    [solutionScores, sortIdx] = sort(solutionScores,'descend');
    solutionSuccess = solutionSuccess(sortIdx);
    solutionDistances = solutionDistances(sortIdx);
    recall = zeros(size(solutionScores));
    precision = zeros(size(solutionScores));
    solutionsCorrect = 0;
    for j=1:size(solutionScores,2)
        solutionsCorrect = solutionsCorrect + solutionSuccess(j);
        precision(j) = solutionsCorrect / double(j);
        recall(j) = solutionsCorrect / double(gtCounter);        
    end
    
    %% Evaluation per threshold step
    recallCollected{h} = recall;
    precisionCollected{h} = precision;
    printoutDistanceIdx = 30;
    
    
    %% Average Precision and Mean Average Distance error
    mapRecallSteps = 201; %default=201
    [ap, mad] = mAp(precision,recall,solutionDistances,mapRecallSteps);
    ap = mean(ap(~isnan(ap)));
    mad = mean(mad(~isnan(mad)));
    fprintf('Stepped for dist %.1fpx. AP: %.3f, MAD: %.3fpx\n', distanceThresh, ...
        ap, mad);
end


%% Plot the Prec./Rec. curve

f = figure;
printForDistanceIdx = 1:length(distanceThresholds); %choose which distanceThresholds to print for
colors = ['r','g','b','k','c','m','y'];
legendEntries = {};
hold on
precision = zeros(size(printForDistanceIdx,2),size(solutionSuccess,2));
recall = zeros(size(printForDistanceIdx,2),size(solutionSuccess,2));
for i=1:length(printForDistanceIdx)
    distanceIdx= printForDistanceIdx(i);
    distance = distanceThresholds(distanceIdx);
    plot(recallCollected{distanceIdx},precisionCollected{distanceIdx},'Color',colors(i));
    legendEntries{i} = sprintf(' <%2.1fpx',distance);
    recall(i,:)=recallCollected{distanceIdx};
    precision(i,:)=precisionCollected{distanceIdx};
end

ylabel('Precision')
xlabel('Recall')
xlim([0 1])
ylim([0 1])
legend(legendEntries,'Location','southeast')