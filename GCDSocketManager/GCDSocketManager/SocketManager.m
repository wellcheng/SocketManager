//
//  SocketManager.m
//  GCDSocketManager
//
//  Created by Well Cheng on 14-10-23.
//  Copyright (c) 2014年 Well Cheng. All rights reserved.
//

#import "SocketManager.h"


#define KEY_COMPLETE_HANDLER @"xxxxcc"
#define KEY_REQUEST @"ososoccc"

#define REQUEST_HEADER_TAG 1
#define REQUEST_TAG 2


@implementation SocketManager



- (id)init
{
    self = [super init];
    if (self)
    {
        _isRunning = NO;
        _requests = [[NSMutableArray alloc] init];
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                             delegateQueue:dispatch_get_main_queue()];
        NSError *error;
        [_socket connectToHost:@"192.168.10.2" onPort:2223 error:&error];
        if (error != nil)
        {
            @throw [NSException exceptionWithName:@"GCDAsyncSocket"
                                           reason:[error localizedDescription]
                                         userInfo:nil];
        }
        NSLog(@"初始化 socket 并连接成功");
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Instance methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)sendRequest:(NSData *)request onCompleted:(void (^)(NSData *))completeHandler
{
    // 字典保存 请求以及请求结果
    NSDictionary *req = @{KEY_REQUEST: request,
                          KEY_COMPLETE_HANDLER: completeHandler};
    // 将请求保存到 请求队列
    [_requests addObject:req];
    
    NSData *requestData = request;
    int32_t length = [requestData length];
    length = htonl(length);
    NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(int32_t)];
    
    NSMutableData *data = [[NSMutableData alloc] initWithData:lengthData];
    [data appendData:requestData];
    NSLog(@"start send");
    [_socket writeData:data withTimeout:30 tag:REQUEST_TAG];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - GCDAsyncSocketDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"did write");
    if (tag == REQUEST_TAG)
    {
        if (!_isRunning)
        {
            _isRunning = YES;
            NSLog(@"DID WRITE DATA TAG=%ld",tag);
            [_socket readDataToLength:sizeof(int32_t) withTimeout:-1 tag:REQUEST_HEADER_TAG];
        }
    }
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    switch (tag) {
        case REQUEST_HEADER_TAG:
        {
            int length;
            [data getBytes:&length length:sizeof(int32_t)];
            length = ntohl(length);
            NSLog(@"will reading %d bytes", length);
            [_socket readDataToLength:length withTimeout:30 tag:REQUEST_TAG];
            break;
        }
            
        case REQUEST_TAG:
        {
            NSDictionary *requestInfo = [_requests objectAtIndex:0];
            NSLog(@"请求数量%30d",[requestInfo count]);
            [_requests removeObject:requestInfo];
            NSLog(@"did read");
            NSData *response = data;
            NSLog(@"reponse length:%d",[data length]);
            
            void (^completeHandler)(NSData *) = requestInfo[KEY_COMPLETE_HANDLER];
            completeHandler(response);
            
            if ([_requests count] > 0)
            {
                [_socket readDataToLength:sizeof(int32_t) withTimeout:-1 tag:REQUEST_HEADER_TAG];
            }
            else
            {
                _isRunning = NO;
                NSLog(@"Socket 请求队列为空。");
            }
            break;
        }
            
        default:
            break;
    }
}
- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"%s",__FUNCTION__);
}

- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"%s",__FUNCTION__);
}
@end