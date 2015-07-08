//
//  AIFileManager.h
//  AIFileManagerExample
//
//  Created by aidenjlee on 2015. 2. 25..
//  Copyright (c) 2015년 entist. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    AIDirectoryTypeNone                 = 0,
    AIDirectoryTypeApplicationSupport   = 1,
    AIDirectoryTypeDocument             = 2,
    AIDirectoryTypeCaches               = 3,
    AIDirectoryTypeLibrary              = 4,
    AIDirectoryTypeMainBundle           = 5
} AIDirectoryType;


extern NSString * const AIErrorHandlerNotification;

@interface AIFileManager : NSObject

@property (nonatomic, strong, readonly) NSString *strApplicationSupportPath;
@property (nonatomic, strong, readonly) NSString *strDocumentPath;
@property (nonatomic, strong, readonly) NSString *strCachesPath;
@property (nonatomic, strong, readonly) NSString *strLibraryPath;

@property (nonatomic, strong, readonly) NSString *strMainBundlePath;


+ (AIFileManager *)sharedInstance;
+ (void)releaseSharedInstance;


#pragma mark Create
- (BOOL)saveContent:(NSObject *)content atName:(NSString *)name;


#pragma mark Read
// Content lists of Directory
- (NSArray *)contentsAtPath:(NSString *)path;
- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep;
- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep withPrefix:(NSString *)prefix;
- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep withSuffix:(NSString *)suffix;
- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep withExtension:(NSString *)extension;


#pragma mark Update
- (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath;
- (BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath;


#pragma mark Delete
- (BOOL)removeItemAtPath:(NSString *)path;                                          // 아이템 삭제
- (BOOL)removeItemAtPath:(NSString *)path withExtension:(NSString *)extension;      // 옵션 : 확장자 지정해서 삭제
- (BOOL)removeItemAtPath:(NSString *)path withPrefix:(NSString *)prefix;            // 옵션 : prefix로 삭제
- (BOOL)removeItemAtPath:(NSString *)path withSuffix:(NSString *)suffix;            // 옵션 : suffix로 삭제


#pragma mark Utility
- (NSNumber *)sizeOfItemAtPath:(NSString *)path;                                    // 사이즈 체크
- (BOOL)isFileExistsAtPath:(NSString *)path;                                        // 파일이 존재 하는지
- (BOOL)isFileItemAtPath:(NSString *)path;                                          // 파일인지 체크
- (id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key error:(NSError **)error; // 속성
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path;

- (NSString *)absolutePath:(NSString *)path;

@end
