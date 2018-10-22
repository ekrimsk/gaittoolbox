%% Fix the faulty hand IMU issue
% S01-Trial
% 90 degrees rotate for left ankle
% {'Static-1', 'Walk-1', 'Walk-2', 'TUG-1', 'TUG-2', 'Jog-1', 'Jog-2', ...
%     'JumpingJacks-1', 'JumpingJacks-2', 'SpeedSkater-1', 'SpeedSkater-2', ...
%     'HighKneeJog-1', 'HighKneeJog-2'};
% 270 degrees rotate for left ankle
% {'FigureofEight-1', 'FigureofEight-2', 'Zigzag-1', 'Zigzag-2', ...
%                  'Fivemin-1', 'Fivemin-2'};
% S02-Trial no change

name = 'neura-sparse01/imu/S01-Trial-';
name_calib = 'neura-sparse01/calib/S01-Calib-';
name_vicon = 'neura-sparse01/vicon/S01-Trial-';
basis = 'SensorW2V';
target = {'Static-1', 'Walk-1', 'Walk-2', 'TUG-1', 'TUG-2', 'Jog-1', 'Jog-2', ...
    'JumpingJacks-1', 'JumpingJacks-2', 'SpeedSkater-1', 'SpeedSkater-2', ...
    'HighKneeJog-1', 'HighKneeJog-2', 'FigureofEight-1', 'FigureofEight-2', ...
    'Zigzag-1', 'Zigzag-2', 'Fivemin-1', 'Fivemin-2'};

imus_src = {'00B40C49', '00B40C4A'};
imus_dst = {'00B40C44', '00B40C47'};   
load(sprintf('%s%s.mat', name_calib, basis));

idx = 2;
quat_viconbasis = {calcQuat(LAK_SensN, LAK_SensS, LAK_SensW, idx), ...
                   calcQuat(RAK_SensN, RAK_SensS, RAK_SensW, idx)};

theta1 = 180;
R1 = [cosd(theta1) sind(theta1) 0;
     -sind(theta1) cosd(theta1) 0;
     0 0 1];
theta2 = 0;
R2 = [cosd(theta2) sind(theta2) 0;
     -sind(theta2) cosd(theta2) 0;
     0 0 1];
quat_manual= {rotm2quat(R1), rotm2quat(R2)};
% quat_manual= {rotm2quat(eye(3)), rotm2quat(eye(3))};

for i=1:length(imus_src)
    quat_adj = quat_manual{i};
        
    f_basis = sprintf("%s%s-000_%s.txt", name_calib, basis, imus_src{i});
    T_basis = readtable(f_basis);
    quat_basis = [T_basis.Quat_q0(:) T_basis.Quat_q1(:) ...
                  T_basis.Quat_q2(:) T_basis.Quat_q3(:)];
    
    quat_adj = quatmultiply(quat_viconbasis{i}, quatconj(quat_basis));
    quat_new = quatmultiply(quat_adj, quat_basis);
    
    T_basis.Quat_q0 = quat_new(:,1);
    T_basis.Quat_q1 = quat_new(:,2);
    T_basis.Quat_q2 = quat_new(:,3);
    T_basis.Quat_q3 = quat_new(:,4);
    
    f_dst = sprintf("%s%s-000_%s.txt", name_calib, basis, imus_dst{i});
    writetable(T_basis, f_dst);
        
%     for j=1:length(target)
%         f_src = sprintf("%s%s-000_%s.txt", name, target{j}, imus_src{i});
%         T = readtable(f_src);
%         quat_new = [T.Quat_q0(:) T.Quat_q1(:) T.Quat_q2(:) T.Quat_q3(:)];
%         quat_new = quatmultiply(quat_adj, quat_new);
%         
%         T.Quat_q0 = quat_new(:,1);
%         T.Quat_q1 = quat_new(:,2);
%         T.Quat_q2 = quat_new(:,3);
%         T.Quat_q3 = quat_new(:,4);
%         
%         f_dst = sprintf("%s%s-000_%s.txt", name, target{j}, imus_dst{i});
%         writetable(T, f_dst);
%     end
end

function q = calcQuat(N, S, W, i)
    x = N(i,:) - S(i,:); x = x / norm(x);
    y = W(i,:) - N(i,:); y = y / norm(y);
    y = y - dot(x, y)*x; y = y / norm(y);
    z = cross(x, y);
    
    q = rotm2quat([x' y' z']);
end