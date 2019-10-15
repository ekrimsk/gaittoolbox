function obj = loadViconMat(fname)   
	% Load mat file generated by parseViconCSV.py and return an instance of ViconBody class
	%
	% :param fname: mat file name
	%
	% :return: instance of ViconBody class.
	%
	% .. Author: - Luke Sy (UNSW GSBME)
    load(fname);
    
    obj = mocapdb.ViconBody('srcFileName', fname, 'posUnit', 'mm', ...
        'LFEP', LHJC(:, 1:3), 'LFEO', LKJC(:, 1:3), ...
        'LTIO', LAJC(:, 1:3), 'LTOE', LTOE(:, 1:3), ...
        'RFEP', RHJC(:, 1:3), 'RFEO', RKJC(:, 1:3), ...
        'RTIO', RAJC(:, 1:3), 'RTOE', RTOE(:, 1:3), ...
        'PELV', (RASI(:, 1:3)+LASI(:, 1:3))/2, 'fs', 100, 'frame', 'vicon');
        
    n = size(RASI); n = n(1);
    
    PELV_y = (LASI-RASI) ./ vecnorm(LASI-RASI, 2, 2);
    PELV_c = (RPSI-RASI);
    PELV_cIdx = any(isnan(PELV_c), 2);
    PELV_c(PELV_cIdx, :) = LPSI(PELV_cIdx, :) - RASI(PELV_cIdx, :);
    PELV_z = cross(PELV_y, PELV_c, 2);
    PELV_z = PELV_z ./ vecnorm(PELV_z, 2, 2);
    PELV_x = cross(PELV_y, PELV_z, 2);
    PELV_x = PELV_x ./ vecnorm(PELV_x, 2, 2);
    PELV_CS = zeros(3, 3, n);
    PELV_CS(:, 1, :) = reshape(PELV_x', 3, 1, n);
    PELV_CS(:, 2, :) = reshape(PELV_y', 3, 1, n);
    PELV_CS(:, 3, :) = reshape(PELV_z', 3, 1, n);
    obj.qRPV = rotm2quat(PELV_CS);
    
    LTHI_z = (obj.LFEP-obj.LFEO) ./ vecnorm(obj.LFEP-obj.LFEO, 2, 2);
    LTHI_c = (LKNE-obj.LFEO);
    LTHI_x = cross(LTHI_c, LTHI_z, 2);
    LTHI_x = LTHI_x ./ vecnorm(LTHI_x, 2, 2);
    LTHI_y = cross(LTHI_z, LTHI_x, 2);
    LTHI_y = LTHI_y ./ vecnorm(LTHI_y, 2, 2);
    LTHI_CS = zeros(3, 3, n);
    LTHI_CS(:, 1, :) = reshape(LTHI_x', 3, 1, n);
    LTHI_CS(:, 2, :) = reshape(LTHI_y', 3, 1, n);
    LTHI_CS(:, 3, :) = reshape(LTHI_z', 3, 1, n);
    obj.qLTH = rotm2quat(LTHI_CS);
    
    LSHK_z = (obj.LFEO-obj.LTIO) ./ vecnorm(obj.LFEO-obj.LTIO, 2, 2);
    LSHK_c = (LANK-obj.LTIO);
    LSHK_x = cross(LSHK_c, LSHK_z, 2);
    LSHK_x = LSHK_x ./ vecnorm(LSHK_x, 2, 2);
    LSHK_y = cross(LSHK_z, LSHK_x, 2);
    LSHK_y = LSHK_y ./ vecnorm(LSHK_y, 2, 2);
    LSHK_CS = zeros(3, 3, n);
    LSHK_CS(:, 1, :) = reshape(LSHK_x', 3, 1, n);
    LSHK_CS(:, 2, :) = reshape(LSHK_y', 3, 1, n);
    LSHK_CS(:, 3, :) = reshape(LSHK_z', 3, 1, n);
    obj.qLSK = rotm2quat(LSHK_CS);
    
    RTHI_z = (obj.RFEP-obj.RFEO) ./ vecnorm(obj.RFEP-obj.RFEO, 2, 2);
    RTHI_c = (obj.RFEO-RKNE);
    RTHI_x = cross(RTHI_c, RTHI_z, 2);
    RTHI_x = RTHI_x ./ vecnorm(RTHI_x, 2, 2);
    RTHI_y = cross(RTHI_z, RTHI_x, 2);
    RTHI_y = RTHI_y ./ vecnorm(RTHI_y, 2, 2);
    RTHI_CS = zeros(3, 3, n);
    RTHI_CS(:, 1, :) = reshape(RTHI_x', 3, 1, n);
    RTHI_CS(:, 2, :) = reshape(RTHI_y', 3, 1, n);
    RTHI_CS(:, 3, :) = reshape(RTHI_z', 3, 1, n);
    obj.qRTH = rotm2quat(RTHI_CS);
    
    RSHK_z = (obj.RFEO-obj.RTIO) ./ vecnorm(obj.RFEO-obj.RTIO, 2, 2);
    RSHK_c = (obj.RTIO-RANK);
    RSHK_x = cross(RSHK_c, RSHK_z, 2);
    RSHK_x = RSHK_x ./ vecnorm(RSHK_x, 2, 2);
    RSHK_y = cross(RSHK_z, RSHK_x, 2);
    RSHK_y = RSHK_y ./ vecnorm(RSHK_y, 2, 2);
    RSHK_CS = zeros(3, 3, n);
    RSHK_CS(:, 1, :) = reshape(RSHK_x', 3, 1, n);
    RSHK_CS(:, 2, :) = reshape(RSHK_y', 3, 1, n);
    RSHK_CS(:, 3, :) = reshape(RSHK_z', 3, 1, n);
    obj.qRSK = rotm2quat(RSHK_CS);
    
    obj.nSamples = n;
end