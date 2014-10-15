//
//  ViewController.m
//  SlidePuzzle
//
//  Created by Yoshizawa Tomoya on 2014/10/03.
//  Copyright (c) 2014年 Tomoya Yoshizawa. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Cropping.h"

static NSInteger const kNumberOfRows = 4;
static NSInteger const kNumberOfColumns = 4;
static NSInteger const kNumberOfPieces = kNumberOfColumns * kNumberOfRows -1;

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (strong, nonatomic) NSArray *pieceViews;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *startDate;
@property (assign, nonatomic) CGPoint pointOfBlank;

@end

@implementation ViewController

- (CGPoint)pointFromIndex:(NSInteger)index
{
    return CGPointMake(index % kNumberOfColumns, index / kNumberOfColumns);
}

- (NSInteger)indexFromPoint:(CGPoint)point
{
    return point.y * kNumberOfColumns + point.x;
}

- (CGRect)pieceFrameAtIndex:(NSInteger)index
{
    CGPoint point = [self pointFromIndex:index];
    CGFloat width = self.mainView.frame.size.width / kNumberOfColumns;
    CGFloat height = self.mainView.frame.size.height /kNumberOfRows;
    return CGRectMake(point.x * width, point.y * height, width, height);
}

- (BOOL)canMovePieceFromPoint:(CGPoint)point
{
if (CGPointEqualToPoint(self.pointOfBlank, point))
    return NO;
    
    return self.pointOfBlank.x == point.x || self.pointOfBlank.y == point.y;
}

- (void)movePieceFromPoint:(CGPoint)point withAnimation:(BOOL)animation
{
    if (![self canMovePieceFromPoint:point])
        return;
    
    //移動方向を決定する
    NSInteger step;
    if (self.pointOfBlank.x == point.x)
        step = self.pointOfBlank.y > point.y ? kNumberOfColumns : -kNumberOfColumns;
    else
        step = self.pointOfBlank.x > point.x ? 1 : -1;
    
    //移動対象のピースを格納する配列
    NSMutableArray *targetPieceViews = [NSMutableArray array];
    
    NSInteger indexOfBlank = [self indexFromPoint:self.pointOfBlank];
    NSInteger index = [self indexFromPoint:point];
    
    //移動対象のピースを抽出する
    while (index != indexOfBlank){
        for (UIImageView *pieceView in self.pieceViews) {
            if (pieceView.tag == index){
                [targetPieceViews addObject:pieceView];
                break;
            }
        }
        index += step;
    }
    
    //移動対象のピースを実際に動かす
    //アニメーションが必要なときは0.2秒かけてアニメーションさせる
    //アニメーションが不要な場合はアニメーション時間を0秒にすることで即座に反映させる
    [UIView animateWithDuration:animation ? 0.2f : 0 animations:^{
        //このブロック内でアニメーション対象のプロパティを変更すると
        //指定した時間でアニメーションする
        for (UIImageView *pieceView in targetPieceViews) {
            pieceView.tag += step;
            pieceView.frame = [self pieceFrameAtIndex:pieceView.tag];
        }
    }];
    
    self.pointOfBlank  = point;
}

- (BOOL)isPlaying
{
    return self.imageView.hidden;
}

- (IBAction)performStartButtonAction:(id)sender
{
    //ゲーム中の場合は何もせずに終了
    if ([self isPlaying])
        return;

    //手前の画像をフェードアウト
    [UIView animateWithDuration:0.5f animations:^{
        //びゅーのalpha値をアニメーションさせることでフェードアウトする
        self.imageView.alpha =0;
    }completion:^(BOOL finished){
        //フェードアウトのアニメーション完了後に隠す
        self.imageView.hidden = YES;
    }];
    
    //乱数のシードを設定
    srand(time(0));
    //ランダムにピースを動かす
    for (NSInteger i = 0; i<100; i++) {
        NSInteger index = rand() % kNumberOfPieces;
        CGPoint point = [self pointFromIndex:index];
        [self movePieceFromPoint:point withAnimation:NO];
    }
    
    //ゲーム開始時間を保持
    self.startDate = [NSDate date];
    
    //念のためタイマーを止める
    [self.timer invalidate];
    
    //タイマーを作成・作動させて保持する
    //0.1秒毎にselfにupdateTimeLabelメッセージを送る
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                  target:self
                                                selector:@selector(updateTimeLabel) userInfo:nil repeats:YES];
}

- (void)updateTimeLabel
{
    if (![self isPlaying])
        return;
    
    //開始時間から現在までの経過時間を秒単位で習得
    NSUInteger time = (NSUInteger)[[NSDate date] timeIntervalSinceDate:self.startDate];
    
    NSUInteger hour = time / (60 * 60);
    NSUInteger minute = (time % (60 * 60));
    NSUInteger second = (time % (60 * 60)) % 60;
    
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //正方形に加工済みの画像を取得
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    //取得した画像をimageViewに設定
    self.imageView.image = image;
    
    //分割したピースの幅と高さを計算
    CGFloat width = image.size.width / kNumberOfColumns;
    CGFloat height = image.size.height / kNumberOfRows;
    
    for (NSInteger i = 0; i < kNumberOfPieces; i++){
        //画像を切り出すための短形情報を計算
        CGFloat x = (i % kNumberOfColumns) * width;
        CGFloat y = (i / kNumberOfColumns) * height;
        CGRect rect = CGRectMake(x, y, width, height);
        
        //画像を切り出す
        UIImage *croppedImage = [image croppedImageInRect:rect];
        
        //分割後の画像を設定するためのビューを取得
        UIImageView *pieceView = self.pieceViews[i];

        //ビューの座標を設定
        pieceView.frame = [self pieceFrameAtIndex:i];
        
        //ビューに分割後の画像を設定
        pieceView.image = croppedImage;
        
        //ビューの現在位置を表すインデックスをタグとして保持
        pieceView.tag = i;
    }
    //現在の空き座標を表すプロパティを一番右下の座標に設定
    self.pointOfBlank = CGPointMake(kNumberOfColumns - 1, kNumberOfRows);
    
    //スタートボタンを表示
    self.startButton.hidden = NO;
    
    //UIImagePickerControllerを閉じる
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //分割した画像を表示するためのビューを格納する配列
    NSMutableArray *pieceViews = [NSMutableArray array];
    
    for (NSInteger i = 0; i < kNumberOfPieces; i++) {
        //UIImageViewのインスタンスを作成
        UIImageView *pieceView = [[UIImageView alloc] init];
        
        //mainViewのサブビューとして追加
        [self.mainView addSubview:pieceView];
        
        //配列に追加
        [pieceViews addObject:pieceView];
    }
    
    //配列をプロパティに設定
    self.pieceViews = pieceViews;
    
    //分割前の画像を表示するためのビューを作成
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.mainView.bounds];
    [self.mainView addSubview:imageView];
    self.imageView = imageView;
    
    // 分割前の画像を表示するためのビューを作成
}

- (IBAction)performChooseImageButtonAction:(id)sender
    {
        if ([self isPlaying]) {
            return;
        }
        
        //UIImagePickerControllerのインスタンスを作成
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        
        //画像の取得元をフォトライブラリに設定
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        //画像を正方形に加工するように設定
        controller.allowsEditing = YES;
        
        //デリゲートを self に設定
        controller.delegate = self;
        
        //UIImagePickerController を表示
        [self presentViewController:controller animated:YES completion:nil];
    }

- (BOOL)isSolved
{
    for (NSInteger i = 0; i < kNumberOfPieces; i++){
        UIImageView *pieceView = self.pieceViews[i];
        if (i != pieceView.tag)
            return NO;
        }
        
        return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
if (![self isPlaying])
    return;
    
    //タッチを示すオブジェクト取得
    UITouch *touch = [touches anyObject];
    
    //タッチ情報からタッチ座標を取得
    CGPoint location = [touch locationInView:self.mainView];
    
    //タッチ座標がmainView内であれば処理する
    if (CGRectContainsPoint(self.mainView.bounds, location)) {
        
        //タッチ座標から４×４の座標を計算する
        CGFloat width = self.mainView.frame.size.width / kNumberOfColumns;
        CGFloat height = self.mainView.frame.size.height / kNumberOfRows;
        CGPoint point = CGPointMake((int)(location.x / width), (int)(location.y / height));
        
        //ピースを移動させる
        [self movePieceFromPoint:point withAnimation:YES];
        
        //パズルが完成していれば処理を行う
        if ([self isSolved]) {
            
            //タイマーを止めて破棄
            [self.timer invalidate];
            self.timer = nil;
            
            //手前の画像を表示
            self.imageView.hidden = NO;
            [UIView animateWithDuration:0.5f animations:^{
            //フェードイン
                self.imageView.alpha = 1;
            } completion:^(BOOL finished){
                //フェードイン完了後にゲームクリアのアラートを表示
                NSString *title = @"ゲームクリア！";
                NSString *message = [NSString stringWithFormat:@"タイムは%@です", self.timeLabel.text];
                [[[UIAlertView alloc] initWithTitle:title
                                            message:message delegate:nil
                                  cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }];
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
