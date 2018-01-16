//
//  HKViewController.m
//  HK_AudioVideoRecoder
//
//  Created by houke on 2018/1/15.
//  Copyright © 2018年 houke. All rights reserved.
//

#import "HKViewController.h"
#import <AudioToolbox/AudioToolbox.h>//这个是 C 的接口，偏向于底层，主要用于在线流媒体播放,比 AVPlayer,MPMusicPlayerController功能要更强大
#import <AVFoundation/AVFoundation.h>//提供了音频和回放的底层 API,同时也负责管理音频硬件


@interface HKViewController ()<AVAudioRecorderDelegate>//遵守录音代理协议
{
    AVAudioRecorder *recorder;//用来录音
    //设置定时监测,用来监听当前音量大小,控制话筒图片
    NSTimer *timer;
    //用来记录本地录音的保存路径
    NSURL *urlPlay;
    
    UIView *voiceView;
}

/**
 用来控制录音功能
 */
@property (weak, nonatomic) IBOutlet UIButton *btn;

/**
 用来播放已经录好的音频文件
 */
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

/**
 控制音量的图片
 */
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

/**
 音频播放器
 */
@property (nonatomic, weak) AVAudioPlayer *avPlayer;
@end

@implementation HKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the voiceView.
    //1、进行录音设置
    [self audio];
    
    voiceView = [[UIView alloc] init];
    voiceView.backgroundColor = [UIColor yellowColor];
    [self.imageView addSubview:voiceView];
    voiceView.hidden = YES;
    
    
}
/**
 录音设置
 */
-(void)audio
{
    //先配置 Recoder
    NSMutableDictionary *recoderSetting = [NSMutableDictionary dictionary];
    //设置录音的格式
    [recoderSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    
    //设置录音采样率
    [recoderSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    
    //设置录音通道数
    [recoderSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    
    //线性采样位数8,16,24,32
    [recoderSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    
    //录音质量
    [recoderSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    //进行录音设置添加
    //设置路径
    NSString *strUrl = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/record.aac", strUrl]];
    urlPlay = url;
    
    //进行设置的初始化
    NSError *error;
    recorder = [[AVAudioRecorder alloc] initWithURL:urlPlay settings:recoderSetting error:&error];
    
    //开启音量检测
    recorder.meteringEnabled = YES;
    recorder.delegate = self;
    
}

//录音按钮被按下
- (IBAction)btnDown:(id)sender {
    [sender setTitle:@"stop" forState:UIControlStateNormal];
    
    //创建录音文件，准备录音
    if ([recorder prepareToRecord]) {
        //开始
        [recorder record];
    }
    
    //设置定时检测,检测间隔时间为0的话即为时刻检测
    timer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(detectionVoice) userInfo:nil repeats:YES];
}

#pragma mark 按钮点击事件
//录音按钮手指抬起
- (IBAction)btnUp:(UIButton *)sender {
    [sender setTitle:@"start" forState:UIControlStateNormal];
    
    double cTime = recorder.currentTime;//记录当前时间
    if (cTime>2) {
        NSLog(@"把录音发出去");
    }else{
        [recorder deleteRecording];//删除记录文件
    }
    [recorder stop];//停止录音
    [timer invalidate];//计时器暂停
    
}
//录音按钮触摸拖动离开控制范围
- (IBAction)btnDragUp:(id)sender {
    
    [sender setTitle:@"start" forState:UIControlStateNormal];
    
    //删除录制文件
    [recorder deleteRecording];
    [recorder stop];
    [timer invalidate];
    
    NSLog(@"取消发送");
}
- (IBAction)playRecordSound:(UIButton *)sender {
    
    if (self.avPlayer.playing) {
        [self.avPlayer stop];
        return;
    }
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:urlPlay error:nil];
    self.avPlayer = player;
    
    [self.avPlayer play];
}


/**
 检测当前声音
 */
-(void)detectionVoice
{
    voiceView.hidden = NO;
    [recorder updateMeters];//刷新当天音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    
    double lowPassResults = pow(10,(0.05*[recorder peakPowerForChannel:0]));//[recorder peakPowerForChannel:0] 为当前音量
    NSLog(@"当前音量为：%f",lowPassResults);
    
    //取值范围是 0-1
    if (0<lowPassResults <0.06) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.06) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.06);
    }else if (0.06<lowPassResults<=0.13) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.13) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.13);
    }else if (0.13<lowPassResults<=0.20) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.20) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.20);
    }else if (0.20<lowPassResults<=0.27) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.27) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.27);
    }else if (0.27<lowPassResults<=0.34) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.34) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.34);
    }else if (0.34<lowPassResults<=0.41) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.41) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.41);
    }else if (0.41<lowPassResults<=0.48) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.48) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.48);
    }else if (0.48<lowPassResults<=0.55) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.55) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.55);
    }else if (0.55<lowPassResults<=0.62) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.62) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.62);
    }else if (0.62<lowPassResults<=0.69) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.69) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.69);
    }else if (0.69<lowPassResults<=0.76) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.76) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.76);
    }else if (0.76<lowPassResults<=0.83) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.83) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.83);
    }else if (0.83<lowPassResults<=0.9) {
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-0.9) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame )*0.9);
    }else{
        voiceView.frame = CGRectMake(0, CGRectGetHeight(self.imageView.frame)*(1-1) , CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame ));
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end













