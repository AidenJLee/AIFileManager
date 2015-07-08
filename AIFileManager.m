//
//  AIFileManager.m
//  AIFileManagerExample
//
//  Created by aidenjlee on 2015. 2. 25..
//  Copyright (c) 2015년 entist. All rights reserved.
//

#import "AIFileManager.h"
@import UIKit;

@interface AIFileManager ()

@property (nonatomic, strong, readwrite) NSString *strApplicationSupportPath;
@property (nonatomic, strong, readwrite) NSString *strDocumentPath;
@property (nonatomic, strong, readwrite) NSString *strCachesPath;
@property (nonatomic, strong, readwrite) NSString *strLibraryPath;

@property (nonatomic, strong, readwrite) NSString *strMainBundlePath;

@end


// 에러 처리를 위한 NSNotification Center ID
NSString * const AIErrorHandlerNotification = @"AIFileManagerErrorHandlerNotification";

@implementation AIFileManager

// 그 이름도 외로운 싱.글.톤!
static AIFileManager *__instance = nil;

+ (AIFileManager *)sharedInstance {
    
    @synchronized (self) {
        
        // 만약 생성이 되어 있지 않다면
        if (__instance == nil) {
            // 생성을 한다.
            __instance = [[AIFileManager alloc] init];
        }
    }
    
    return __instance;
    
}

// 만들었으면 없어 져야죠?
+ (void)releaseSharedInstance {
    
    @synchronized (self) {
        __instance = nil;
    }
    
}


#pragma mark -
#pragma mark Init

// 초기화!
- (id)init {
    
    self = [super init];
    if (self) {
        
        // 각종 경로들.. 기본 경로는 도큐먼트경로
        // 도큐먼트 경로는 아이클라우드 백업 기능도 있고 사용자가 볼 수 있다.
        // 사용자가 보기를 원하지 않는다면 라이브러리나 캐쉬 경로를 사용하자. (뭐 그래도 볼수 있는 방법은 있지만...)
        // 캐쉬 경로는 말 그대로 캐쉬를 워한 것이고 이것은 경로는 아이클라우드 백업에 포함 되지 않는다.
        // 임시 경로는 정말 임시로 쓸 때만 쓰자.. 보통은 쓸일이 없다.
        // 메인 번들의 경우는 샌드박싱을 이해해야 하는데... 설명은 귀찮고 그냥 프로젝트 리소스에 포함 된 파일을 '읽기 전용'으로 필요하다면 접근해라. 변경이 필요하다면 메인번들에서 도큐먼트나 라이브러리로 이동하여 처리 해라.
        self.strApplicationSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
        self.strDocumentPath    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.strCachesPath      = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        self.strLibraryPath     = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
        
        self.strMainBundlePath  = [NSBundle mainBundle].resourcePath;
        
    }
    
    return self;
    
}


#pragma mark -
#pragma mark Create

- (BOOL)saveContent:(NSObject *)content atName:(NSString *)name {
    
    if ([name isEqualToString:@""] || !name) {
        [NSException raise:@"Invalid name" format:@"name is can`t be empty or nil."];
    }
    
    NSString *strAbsolutePath = [self absolutePath:name];
    [self createDirectoriesForPath:[strAbsolutePath stringByDeletingLastPathComponent]];
    return [self writeFileAtPath:strAbsolutePath content:content];
    
}

- (BOOL)writeFileAtPath:(NSString *)path content:(NSObject *)content {
    
    if(!content) {
        [NSException raise:@"Invalid content" format:@"content can't be nil."];
    }
    
    if([content isKindOfClass:[NSMutableArray class]]) {
        
        return [((NSMutableArray *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSArray class]]) {
        
        return [((NSArray *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSMutableData class]]) {
        
        return [((NSMutableData *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSData class]]) {
        
        return [((NSData *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSMutableDictionary class]]) {
        
        return [((NSMutableDictionary *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSDictionary class]]) {
        
        return [((NSDictionary *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSJSONSerialization class]]) {
        
        return [((NSDictionary *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSMutableString class]]) {
        
        return [[((NSString *)content) dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[NSString class]]) {
        
        return [[((NSString *)content) dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[UIImage class]]) {
        
        return [UIImagePNGRepresentation((UIImage *)content) writeToFile:path atomically:YES];
        
    }
    else if([content isKindOfClass:[UIImageView class]]) {
        
        return [UIImagePNGRepresentation(((UIImageView *)content).image) writeToFile:path atomically:YES];
        
    }
    else if([content conformsToProtocol:@protocol(NSCoding)]) {
        
        return [NSKeyedArchiver archiveRootObject:content toFile:path];
        
    }
    else {
        
        [NSException raise:@"Invalid content type" format:@"content of type %@ is not handled.", NSStringFromClass([content class])];
        return NO;
        
    }
    
}


#pragma mark -
#pragma mark Read

- (NSArray *)contentsAtPath:(NSString *)path {
    return [self contentsAtPath:path deep:NO];
}

- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep {
    
    // path가 없으면 예외!
    if (!path) {
        [NSException raise:@"Invalid path" format:@"path is can`t be empty or nil."];
    }
    
    NSString *strPath = [self absolutePath:path];
    NSArray *arrSubPaths = nil;
    
    if (deep) {
        arrSubPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:strPath error:nil];
    } else {
        arrSubPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:strPath error:nil];
    }
    return arrSubPaths;
    
}

- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep withPrefix:(NSString *)prefix {
    
    NSString *strPredicate = [NSString stringWithFormat:@"SELF BEGINSWITH[ c] '%@'", prefix];
    NSArray *list = [self contentsAtPath:path deep:deep];
    return [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:strPredicate]];
    
}

- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep withSuffix:(NSString *)suffix {
    
    NSString *strPredicate = [NSString stringWithFormat:@"SELF ENDSWITH[ c] '%@'", suffix];
    NSArray *list = [self contentsAtPath:path deep:deep];
    return [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:strPredicate]];
    
}

- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep withExtension:(NSString *)extension {
    
    NSString *strSuffix = [NSString stringWithFormat:@".%@", extension];
    return [self contentsAtPath:path deep:deep withSuffix:strSuffix];
    
}


#pragma mark -
#pragma mark Update

- (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:[self absolutePath:path]
                                                           toPath:[self absolutePath:toPath]
                                                            error:&error];
    
    if (error) {
        [self sendErrorWithNotification:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:[self absolutePath:path]
                                                           toPath:[self absolutePath:toPath]
                                                            error:&error];
    
    if (error) {
        [self sendErrorWithNotification:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}


#pragma mark -
#pragma mark Delete

- (BOOL)removeItemAtPath:(NSString *)path {
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[self absolutePath:path] error:&error];
    
    if (error) {
        [self sendErrorWithNotification:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (BOOL)removeItemAtPath:(NSString *)path withExtension:(NSString *)extension {
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path withPrefix:(NSString *)prefix {
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path withSuffix:(NSString *)suffix {
    return NO;
}


#pragma mark -
#pragma mark Utility
// Create : Directories
- (BOOL)createDirectoriesForPath:(NSString *)path {
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    
    if (error) {
        [self sendErrorWithNotification:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (NSNumber *)sizeOfItemAtPath:(NSString *)path {
    return [self sizeOfItemAtPath:path error:nil];
}

- (NSNumber *)sizeOfItemAtPath:(NSString *)path error:(NSError **)error {
    return (NSNumber *)[self attributeOfItemAtPath:path forKey:NSFileSize error:error];
}

// 파일이 존재 하는지
- (BOOL)isFileExistsAtPath:(NSString *)path {
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self absolutePath:path] isDirectory:&isDir];
    
    // 파일이 존재하지 않으면 폴더 생성... 왜? 파일 없으면 넣을 예정이라.. 내맘임 -_-
    if (!exists) {
        [self createDirectoriesForPath:path];
    }
    return exists;
    
}

// 파일인지 체크
- (BOOL)isFileItemAtPath:(NSString *)path {
    return ([self attributeOfItemAtPath:path forKey:NSFileType error:nil] == NSFileTypeRegular);
}

- (id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key error:(NSError **)error {
    return [[self attributesOfItemAtPath:path] objectForKey:key];
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path {
    
    NSError *error = nil;
    NSDictionary *dicItemAtPath = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    
    if (error) {
        [self sendErrorWithNotification:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return dicItemAtPath;
    
}

// Error 핸들링
- (void)sendErrorWithNotification:(NSDictionary *)info {
    [[NSNotificationCenter defaultCenter] postNotificationName:AIErrorHandlerNotification object:nil userInfo:info];
}


#pragma mark -
#pragma mark Path Appending Methods

// 시스템 Path가 포함 되어 있는 온전한 Path 반환
- (NSString *)absolutePath:(NSString *)path {
    
    AIDirectoryType type = [self typeCheckAtPath:path];
    if (type == AIDirectoryTypeNone) {
        type = AIDirectoryTypeDocument;
    }
    return [self createPathForType:type withPathComponent:path];
    
}

- (NSString *)createPathForType:(AIDirectoryType)type withPathComponent:(NSString *)pathComponent {
    
    switch (type) {
        case AIDirectoryTypeApplicationSupport:
            return [self.strApplicationSupportPath stringByAppendingPathComponent:pathComponent];
            break;
            
        case AIDirectoryTypeDocument:
            return [self.strDocumentPath stringByAppendingPathComponent:pathComponent];
            break;
            
        case AIDirectoryTypeCaches:
            return [self.strCachesPath stringByAppendingPathComponent:pathComponent];
            break;
            
        case AIDirectoryTypeLibrary:
            return [self.strLibraryPath stringByAppendingPathComponent:pathComponent];
            break;
            
        case AIDirectoryTypeMainBundle:
            return [self.strMainBundlePath stringByAppendingPathComponent:pathComponent];
            break;
            
        default:
            return [self.strDocumentPath stringByAppendingPathComponent:pathComponent];
            break;
    }
    
}

- (AIDirectoryType)typeCheckAtPath:(NSString *)path {
    
    // 경로는 nil일 수 없음
    NSAssert(path != nil, @"Invalid path. nil Path.");
    
    if ([path rangeOfString:self.strApplicationSupportPath].location != NSNotFound) {
        return AIDirectoryTypeApplicationSupport;
    }
    else if ([path rangeOfString:self.strDocumentPath].location != NSNotFound) {
        return AIDirectoryTypeDocument;
    }
    else if ([path rangeOfString:self.strCachesPath].location != NSNotFound) {
        return AIDirectoryTypeCaches;
    }
    else if ([path rangeOfString:self.strLibraryPath].location != NSNotFound) {
        return AIDirectoryTypeLibrary;
    }
    else if ([path rangeOfString:self.strMainBundlePath].location != NSNotFound) {
        return AIDirectoryTypeMainBundle;
    }
    else {
        return AIDirectoryTypeNone;
    }
    
}


#pragma mark -
#pragma mark Path Convert Method
- (NSString *)transformURLString:(NSString *)URLString {
    
    NSString *strDirectoryPath = URLString;
    strDirectoryPath = [strDirectoryPath stringByReplacingOccurrencesOfString:@"http://"  withString:@"data/"];
    strDirectoryPath = [strDirectoryPath stringByReplacingOccurrencesOfString:@"https://" withString:@"data/"];
    strDirectoryPath = [strDirectoryPath stringByReplacingOccurrencesOfString:@"ftp://"   withString:@"data/"];
    return strDirectoryPath;
    
}


#pragma mark -
#pragma mark Localfile Control Method

- (unsigned long long int)checkedNSCachesSize {
    
    NSArray *arrCachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [arrCachePaths objectAtIndex:0];
    NSArray *arrCacheFileList = [[NSFileManager defaultManager] subpathsAtPath:cacheDirectory];
    NSEnumerator *cacheEnumerator = [arrCacheFileList objectEnumerator];
    NSString *strCacheFilePath = nil;
    
    unsigned long long int cacheSize = 0;
    NSError *error = nil;
    
    while (strCacheFilePath = [cacheEnumerator nextObject]) {
        NSDictionary *dicCacheFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[cacheDirectory stringByAppendingPathComponent:strCacheFilePath] error:&error];
        cacheSize += [dicCacheFileAttributes fileSize];
    }
    return cacheSize;
    
}

@end

/*
 {
 NSFileCreationDate = "2015-02-25 08:29:14 +0000";
 NSFileExtensionHidden = 0;
 NSFileGroupOwnerAccountID = 20;
 NSFileGroupOwnerAccountName = staff;
 NSFileModificationDate = "2015-02-25 08:29:14 +0000";
 NSFileOwnerAccountID = 501;
 NSFilePosixPermissions = 493;
 NSFileReferenceCount = 7;
 NSFileSize = 238;
 NSFileSystemFileNumber = 4537765;
 NSFileSystemNumber = 16777219;
 NSFileType = NSFileTypeDirectory;
 }
 */
