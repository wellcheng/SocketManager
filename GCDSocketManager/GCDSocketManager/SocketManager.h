//
//  SocketManager.h
//  GCDSocketManager
//
//  Created by Well Cheng on 14-10-23.
//  Copyright (c) 2014年 Well Cheng. All rights reserved.
//
#import "GCDAsyncSocket.h"
#import <Foundation/Foundation.h>

@interface SocketManager : NSObject<GCDAsyncSocketDelegate>
{
@private
    NSMutableArray *_requests;
    BOOL _isRunning;
    
    GCDAsyncSocket *_socket;
}

// 在block中返回服务器传递的数据
- (void)sendRequest:(NSData *)request onCompleted:(void (^)(NSData *))completeHandler;


@end
