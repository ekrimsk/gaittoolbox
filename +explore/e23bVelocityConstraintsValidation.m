% motion list
mot = struct('file', 'S01-Trial-Walk-1', ...
             'algo', "NS2+lieekfv1+Aw__sOw__sIw__v+Sav03+P023+M101+C007");

dataSfname = sprintf('neura-sparse01/imu/%s', mot.file);
ns = extractBetween(mot.algo, 1, 3);

load(sprintf('neura-sparse01/explore-v2/%s-%s-debug.mat', ns, mot.file));
load(sprintf('neura-sparse01/explore-v2/%s-%s-%s.mat', ns, mot.file, mot.algo));

if cs.initSrc == 'w__v'
    aLabel = 'w__v';
    vb = W__viconBody;
    d_pelvis = norm(vb.RFEP(1,:) - vb.LFEP(1,:));
    d_rfemur = norm(vb.RFEP(1,:) - vb.RFEO(1,:));
    d_lfemur = norm(vb.LFEP(1,:) - vb.LFEO(1,:));
    d_rtibia = norm(vb.RFEO(1,:) - vb.RTIO(1,:));
    d_ltibia = norm(vb.LFEO(1,:) - vb.LTIO(1,:));
elseif cs.initSrc == 'v__v'
    aLabel = 'v__v';
    vb = V__viconBody;
else
    aLabel = 'w__x';
    vb = W__xsensBody;
end
if ( strcmp(cs.accData, 'w__s') || strcmp(cs.accData, 'v__s') || ...
   strcmp(cs.accData, 'w__sf') || strcmp(cs.accData, 'v__sf') )
    eLabel = strcat(cs.accData, cs.initSrc(end));
else
    eLabel = cs.accData;
end
idx = allIdx.(cs.initSrc);
    
avel1 = wbodyOri.(aLabel);
csQOri = qOri.(aLabel);
csBodyWOri = wbodyOri.(strcat(cs.oriData, cs.initSrc(end)));

N = struct('samples', estBody.nSamples);
body = struct('PV_d', d_pelvis, ...
              'LT_d', d_lfemur, 'RT_d', d_rfemur, ...
              'LS_d', d_ltibia, 'RS_d', d_rtibia);
W_R_ = struct('PV', quat2rotm(csQOri.PELV), ...
                 'LS', quat2rotm(csQOri.LTIB), ...
                 'RS', quat2rotm(csQOri.RTIB) );
B_w_ = struct('PV', csBodyWOri.PELV, ...
              'LS', csBodyWOri.LTIB, ...
              'RS', csBodyWOri.RTIB);               

if true
    dt = 1/vb.fs;
    B_w2_ = struct();
    for i = {'PV', 'LS', 'RS'}
        bname = i{1};
        B_w2_.(bname) = zeros(N.samples, 3);
        for j=1:(N.samples-1)
            B_w2_.(bname)(j, :) = rot2vec(W_R_.(bname)(:,:,j)'*W_R_.(bname)(:,:,j+1))/dt;
        end
    end
else
    B_w2_ = B_w_;
end
for i = {'PV', 'LS', 'RS'}
    bname = i{1};
    W_w_.(bname) = zeros(3, N.samples);
    for j=1:N.samples
        W_w_.(bname)(:, j) = W_R_.(bname)(:,:,j)*B_w2_.(bname)(j,:)';
    end
end
vel1 = vb.calcJointVel({'MIDPEL', 'LFEO', 'RFEO', 'LFEP', 'RFEP', 'LTIO', 'RTIO'});
avel1 = vb.calcSegAngVel({'qRPV', 'qLTH', 'qRTH', 'qLSK', 'qRSK'}, 'W');

vel2 = estBody.calcJointVel({'MIDPEL', 'LFEO', 'RFEO', 'LFEP', 'RFEP', 'LTIO', 'RTIO'});
avel2 = estBody.calcSegAngVel({'qRPV', 'qLTH', 'qRTH', 'qLSK', 'qRSK'}, 'W');

%% compare avel2 and W_w_
updateFigureContents('Compare angular velocity');
clf; pelib.viz.plotXYZ(100, avel2.qLSK, W_w_.LS, avel2.qRSK, W_w_.RS, avel2.qRPV, W_w_.PV); 

cctol = 0.99;
%% validate W_v_LH and W_v_RH
W_v_LH1 = vel1.MIDPEL + cross(avel1.qRPV, vb.LFEP-vb.MIDPEL);
W_v_RH1 = vel1.MIDPEL + cross(avel1.qRPV, vb.RFEP-vb.MIDPEL);
ccL = corrcoef(W_v_LH1, vel1.LFEP);
assert(ccL(1,2) > cctol);
ccR = corrcoef(W_v_RH1, vel1.RFEP);
assert(ccR(1,2) > cctol);
fprintf("Vicon W_v_L/RHip CC: %.2f %.2f\n", ccL(1,2), ccR(1,2));

W_v_LH2 = vel2.MIDPEL + cross(avel2.qRPV, estBody.LFEP-estBody.MIDPEL);
W_v_RH2 = vel2.MIDPEL + cross(avel2.qRPV, estBody.RFEP-estBody.MIDPEL);
ccL = corrcoef(W_v_LH2, vel2.LFEP);
assert(ccL(1,2) > cctol);
ccR = corrcoef(W_v_RH2, vel2.RFEP);
assert(ccR(1,2) > cctol);
fprintf("estBody W_v_L/RHip CC: %.2f %.2f\n", ccL(1,2), ccR(1,2));

%% validate W_v_LK and W_v_RK
W_v_LK1 = vel1.LTIO + cross(avel1.qLSK, vb.LFEO-vb.LTIO);
W_v_RK1 = vel1.RTIO + cross(avel1.qRSK, vb.RFEO-vb.RTIO);
ccL = corrcoef(W_v_LK1, vel1.LFEO);
assert(ccL(1,2) > cctol);
ccR = corrcoef(W_v_RK1, vel1.RFEO);
assert(ccR(1,2) > cctol);
fprintf("Vicon W_v_L/RKnee CC: %.2f %.2f\n", ccL(1,2), ccR(1,2));

W_v_LK2 = vel2.LTIO + cross(avel2.qLSK, estBody.LFEO-estBody.LTIO);
W_v_RK2 = vel2.RTIO + cross(avel2.qRSK, estBody.RFEO-estBody.RTIO);
ccL = corrcoef(W_v_LK2, vel2.LFEO);
assert(ccL(1,2) > cctol);
ccR = corrcoef(W_v_RK2, vel2.RFEO);
assert(ccR(1,2) > cctol);
fprintf("estBody W_v_L/RKnee CC: %.2f %.2f\n", ccL(1,2), ccR(1,2));

%% validate base equation W_v_LH = w x W_N_LTz + W_v_LK
W_v_LHb1 = W_v_LK1 + cross(avel1.qLTH, vb.LFEP-vb.LFEO);
W_v_RHb1 = W_v_RK1 + cross(avel1.qRTH, vb.RFEP-vb.RFEO);
ccL = corrcoef(W_v_LHb1, W_v_LH1);
assert(ccL(1,2) > cctol);
ccR = corrcoef(W_v_RHb1, W_v_RH1);
assert(ccR(1,2) > cctol);
fprintf("Vicon W_v_L/R Hip from base vs Hip CC: %.2f %.2f\n", ccL(1,2), ccR(1,2));

W_v_LHb2 = W_v_LK2 + cross(avel2.qLTH, estBody.LFEP-estBody.LFEO);
W_v_RHb2 = W_v_RK2 + cross(avel2.qRTH, estBody.RFEP-estBody.RFEO);
ccL = corrcoef(W_v_LHb2, W_v_LH2);
% assert(ccL(1,2) > cctol);
ccR = corrcoef(W_v_RHb2, W_v_RH2);
% assert(ccR(1,2) > cctol);
fprintf("estBody W_v_L/R Hip from base vs Hip CC: %.2f %.2f\n", ccL(1,2), ccR(1,2));

updateFigureContents('Validate vel generated by kane equation');
clf; pelib.viz.plotXYZ(100, W_v_LHb1, W_v_LH1, W_v_LHb2, W_v_LH2); 

%% Validate that LS_w_LK and RS_w_RK on has components in the thigh y axis
updateFigureContents('Validate LS_w_LK');
LS_w_LK1 = quatrotate(vb.qLTH, avel1.qLTH-avel1.qLSK);
LS_w_LK2 = quatrotate(estBody.qLTH, avel2.qLTH-avel2.qLSK);
RS_w_RK1 = quatrotate(vb.qRTH, avel1.qRTH-avel1.qRSK);
RS_w_RK2 = quatrotate(estBody.qRTH, avel2.qRTH-avel2.qRSK);
clf; pelib.viz.plotXYZ(100, LS_w_LK1, LS_w_LK2); 

%% Validate that W_v_LH-W_v_LK-W_w_LS x W_n_LTz has components only in the thigh x axis
updateFigureContents('Validate LT_v_LH');
LT_v_LH1 = quatrotate(vb.qLTH, W_v_LH1-W_v_LK1-cross(avel1.qLSK, vb.LFEP-vb.LFEO));
RT_v_RH1 = quatrotate(vb.qRTH, W_v_RH1-W_v_RK1-cross(avel1.qRSK, vb.RFEP-vb.RFEO));
LT_v_LH2 = quatrotate(estBody.qLTH, W_v_LH2-W_v_LK2-cross(avel2.qLSK, estBody.LFEP-estBody.LFEO));
RT_v_RH2 = quatrotate(estBody.qRTH, W_v_RH2-W_v_RK2-cross(avel2.qRSK, estBody.RFEP-estBody.RFEO));
clf; pelib.viz.plotXYZ(100, LT_v_LH1, RT_v_RH1); 