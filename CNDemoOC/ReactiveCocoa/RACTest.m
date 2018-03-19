//
//  RACTest.m
//  CNDemoOC
//
//  Created by apple on 2018/3/19.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "RACTest.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import "SubView.h"
#import <Masonry.h>

@interface RACTest (){
    
    SubView *view;
    UIButton *btn;
    UITextField *tf;
    
}

@property (nonatomic, copy) NSString *age;

@end

@implementation RACTest

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    //-----------替代代理----------------
    view = [[SubView alloc] init];
    view.backgroundColor = CNRGBColor(200, 200, 200);
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).with.offset(20);
        make.left.top.equalTo(self.view).with.offset(100);
        make.width.mas_equalTo(@(100));
        make.height.mas_equalTo(@(50));
    }];
    CNWeakSelf(self)
    [[view rac_signalForSelector:@selector(btnClick:)] subscribeNext:^(id  _Nullable x) {
        CNStrongSelf(self);
        NSLog(@"x:%@",x);
        self.age;
        self.view.backgroundColor = [UIColor grayColor];
    }];
    
    //-----------代替KVO-------------------
    /**
     用法和原生代码基本一致valuesForKeyPath: observer:
     self 是viewController
     age  是self的一个属性
     @param x 是age改变后的值
     */
    [[self rac_valuesForKeyPath:@"age" observer:nil] subscribeNext:^(id  _Nullable x) {
        NSLog(@"x::%@",x);
    }];
    
    //-----------事件监听----------------
    //_btn 是一个按钮，给按钮添加一个事件。不需要像原生那样addTarget:action:forControlEvents:,然后再写一个方法给action这么麻烦了。
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view.mas_right).with.offset(30);
        make.centerY.equalTo(view);
        make.width.mas_equalTo(@(200));
        make.height.mas_equalTo(@(30));
    }];
    [btn setTitle:@"事件监听:点击隐藏键盘" forState:UIControlStateNormal];
    [[btn rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@"x:::%@",x);
        [self.view endEditing:YES];
    }];
    
    //-----------输入框改变监听---------
    //这个用法就和系统一样了，只是把监听处理的代码聚合在一起，不需要另外写一个方法，提高代码阅读性。
    //我这里是监听了一个键盘弹起的一个通知。
    tf = [[UITextField alloc] init];
    tf.placeholder = @"UITextfield";
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.layer.borderWidth=1.0f;
    tf.layer.cornerRadius = 5.0;
    tf.layer.borderColor=CNRGBColor(0, 0, 0).CGColor;
    [self.view addSubview:tf];
    [tf mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view);
        make.top.equalTo(view.mas_bottom).with.offset(20);
        make.width.mas_equalTo(@(100));
        make.height.mas_equalTo(@(30));
    }];
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"键盘起来了：%@",x);
    }];
    
    //-----------处理几个信号完成后统一处理事件---------
    //创建信号1
    RACSignal * signalA = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //处理信号 。。 正在发送请求1.。
        /*
         网络请求代码。。。
         */
        //请求完成后，发送数据
        [subscriber sendNext:@"请求1完成"];
        return nil;
    }];
    //创建信号2
    RACSignal * signalB = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //处理信号 。。 正在发送请求2.。
        /*
         网络请求代码。。。
         */
        //请求完成后，发送数据
        [subscriber sendNext:@"请求2完成"];
        return nil;
    }];
    
    //监听 signalA 和 signalB 两个信号都完成了才调用request1WithContent:request2WithContent:
    //注意request1WithContent:request2WithContent:是自己写的一个方法，但是这个方法有个原则，就是有几个信号，就对应传递几个值，不可以多，也不可以少，否则运行的时候就会崩溃，报方法错误（参数错误）
    [self rac_liftSelector:@selector(request1WithContent:request2WithContent:) withSignalsFromArray:@[signalA,signalB]];
    
    
    //-------------常用的宏---------------
    [self RACMacro];
    
}

/**
 请求1和请求都完成了
 */
-(void)request1WithContent:(NSString *)content1 request2WithContent:(NSString *)content2{
    NSLog(@"请求1内容：%@",content1);
    NSLog(@"请求2内容：%@",content2);
}

- (void)RACMacro{
    /**
     元组
     */
    RACTuple * tuple = RACTuplePack(@1,@2,@3);//使用RACTuplePack宏来快速创建
    NSLog(@"TUPLE:%@",tuple);
    //使用RACTupleUnpack宏快速解包
    RACTupleUnpack(NSNumber *num1,NSNumber *num2,NSNumber *num3) = tuple;
    NSLog(@"num1:%@",num1);
    NSLog(@"num2:%@",num2);
    NSLog(@"num3:%@",num3);
    //使用下标的方式来获取
    NSLog(@"第0个:%@",tuple[0]);
    
    //1、RAC 绑定一个信号
    UILabel *conLab = [[UILabel alloc] init];
    [self.view addSubview:conLab];
    [conLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tf.mas_right).with.offset(20);
        make.centerY.equalTo(tf);
        make.right.equalTo(self.view).with.offset(-20);
        make.height.mas_equalTo(@(30));
    }];
    conLab.layer.borderWidth=1.0f;
    conLab.layer.cornerRadius = 5.0;
    conLab.layer.borderColor=CNRGBColor(0, 0, 0).CGColor;
    RAC(conLab,text) = tf.rac_textSignal;
    conLab.text = @"label";
    //2、RACObserve  相当于kvo使用
    [RACObserve(self, age) subscribeNext:^(id  _Nullable x) {
        NSLog(@"x:%@",x);
    }];
    //3、@weakify 和@strongify   这个就是为了解决在使用block的时候强引用问题，注意这两个宏是配套使用才有效。
    //3、把一个对象转换成弱指针
    @weakify(self);//self 是viewController 在block外面使用@weakify
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        //在block里面再使用@strongify
        @strongify(self);
        NSLog(@"%@,",self.view);
        return nil;
    }];
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