
%% 生成三角波
t = 0:N-1;
period = fs/f;                   % 每周期采样点数=128
triangle = sawtooth(2*pi*f*t/fs + pi/2, 0.5); % 生成三角波（MATLAB的sawtooth函数）
triangle = 0.5*peak2peak*(triangle + 1);      % 偏移到[0,1]范围

%% 正弦波采样5kHz数据
% 参数设置
fs = 2e7;          % 采样频率20MHz
f = 5e3;           % 正弦波频率5kHz
peak = 255;        % 峰值255
N = 81920;          % 采样点数4096

% 生成时间序列
t = (0:N-1)/fs;

% 生成0-255范围的正弦波（偏移并缩放到0-255）
sin_wave = sin(2*pi*f*t);            % 标准正弦波（范围[-1,1]）
sin_wave = (sin_wave + 1) * (peak/2); % 转换到[0,255]范围

% 转换为16位无符号整数（uint16）
% 注意：原始数据是0-255，但用16位存储时会自动补零高位
data_uint16 = uint16(round(sin_wave)); % 四舍五入取整

% 打开文件写入二进制数据
fid = fopen('sine_wave_5kHz_unsigned.txt', 'w');

% 将每个16位无符号整数写入文件（二进制格式）
for i = 1:N
    % 获取当前样本的16位二进制表示（自动补零到16位）
    binary_str = dec2bin(data_uint16(i), 16);
    
    % 写入文件
    fprintf(fid, '%s\n', binary_str);
end

fclose(fid);
disp('文件已保存为 sine_wave_5kHz_unsigned.txt');

% 验证波形（可选）
figure;
plot(t(1:200), sin_wave(1:200));      % 绘制前200个点（对应0.2ms）
xlabel('时间（秒）'); ylabel('幅值');
title('5kHz正弦波（0-255范围）');
grid on;