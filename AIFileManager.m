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

@property (nonatomic, strong) NSArray *arrPaths;

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

- (NSString *)assertName:(NSString *)name {
    // name은 비어 있거나 없을 수 없다.
    if ([name isEqualToString:@""] || !name) {
        [NSException raise:@"Invalid name" format:@"name is can`t be empty or nil."];
    }
    // name에는 시스템 경로를 포함하면 안된다 (해도 되는데 AIFileManager가 원치 않는 동작이라고 판단)
    return [self removeSystemPath:name];
}


#pragma mark -
#pragma mark Create
- (BOOL)saveContent:(NSObject *)content atName:(NSString *)name {
    return [self saveContent:content atName:name withType:AIDirectoryTypeDocument];
}

- (BOOL)saveContent:(NSObject *)content atName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    
    if ([self createDirectoriesForPath:[strAbsolutePath stringByDeletingLastPathComponent]]) {  // 파일 경로에 따른 디렉토리 만듬
        
        return [self writeFileAtPath:strAbsolutePath content:content];  // 파일 생성
        
    }
    return NO;
    
}

- (BOOL)writeFileAtPath:(NSString *)path content:(NSObject *)content {
    
    if(!content) {
        [NSException raise:@"Invalid content" format:@"content can't be nil."];
    }
    
    if([content isKindOfClass:[NSData class]]) {
        return [((NSData *)content) writeToFile:path atomically:YES];
    }
    else if([content isKindOfClass:[NSString class]]) {
        return [[((NSString *)content) dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
    }
    else if([content isKindOfClass:[NSArray class]]) {
        return [((NSArray *)content) writeToFile:path atomically:YES];
    }
    else if([content isKindOfClass:[NSDictionary class]]) {
        return [((NSDictionary *)content) writeToFile:path atomically:YES];
    }
    else if([content isKindOfClass:[NSJSONSerialization class]]) {
        return [((NSDictionary *)content) writeToFile:path atomically:YES];
    }
    else if([content isKindOfClass:[UIImage class]]) {
        return [UIImagePNGRepresentation((UIImage *)content) writeToFile:path atomically:YES];
    }
    else if([content conformsToProtocol:@protocol(NSCoding)]) {
        return [NSKeyedArchiver archiveRootObject:content toFile:path];
    }
    else {
        [NSException raise:@"Invalid content type" format:@"content of type %@ is not handled.", NSStringFromClass([content class])];
        return NO;
    }
    
}


// Read
- (NSData *)readDataAtName:(NSString *)name {
    return [self readDataAtName:name withType:AIDirectoryTypeDocument];
}

- (NSData *)readDataAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:strAbsolutePath options:NSDataReadingMapped error:&error];
    
    if (error) {
        [self createErrorNotificationWithInformation:@{
                                                       @"error": error,
                                                       @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]
                                                       }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
        return nil;
    }
    
    return data;
    
}

- (NSString *)readFileAtName:(NSString *)name {
    return [self readFileAtName:name withType:AIDirectoryTypeDocument];
}

- (NSString *)readFileAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    
    NSError *error = nil;
    NSString *strContent = [NSString stringWithContentsOfFile:strAbsolutePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        [self createErrorNotificationWithInformation:@{
                                                       @"error": error,
                                                       @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]
                                                       }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
        return nil;
    }
    
    return strContent;
    
}

- (NSArray *)readArrayAtName:(NSString *)name {
    return [self readArrayAtName:name withType:AIDirectoryTypeDocument];
}

- (NSArray *)readArrayAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    return [NSArray arrayWithContentsOfFile:strAbsolutePath];
    
}

- (NSDictionary *)readDictionaryAtName:(NSString *)name {
    return [self readDictionaryAtName:name withType:AIDirectoryTypeDocument];
}

- (NSDictionary *)readDictionaryAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    return [NSDictionary dictionaryWithContentsOfFile:strAbsolutePath];
    
}

- (NSObject *)readCustomModelAtName:(NSString *)name {
    return [self readCustomModelAtName:name withType:AIDirectoryTypeDocument];
}

- (NSObject *)readCustomModelAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:strAbsolutePath];
    
}

- (UIImage *)readImageAtName:(NSString *)name {
    return [self readImageAtName:name withType:AIDirectoryTypeDocument];
}

- (UIImage *)readImageAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    return [UIImage imageWithData:[self readDataAtName:name withType:type]];
    
}

- (NSDictionary *)readJSONObjectAtName:(NSString *)name {
    
    return [self readJSONObjectAtName:name withType:AIDirectoryTypeDocument];
    
}

- (NSDictionary *)readJSONObjectAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    NSData *data = [self readDataAtName:name withType:type];
    if(data) {
        
        NSError *error = nil;
        NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if (error) {
            
            [self createErrorNotificationWithInformation:@{
                                                           @"error": error,
                                                           @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]
                                                           }];
            NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
            
        } else {
            
            if([NSJSONSerialization isValidJSONObject:json]) {
                return (NSDictionary *)json;
            }
            
        }
        
    }
    return nil;
    
}


// Update
- (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    
    NSError *error = nil;
    BOOL success = ([self contentsOfDirectoryAtPath:toPath] &&
                    [[NSFileManager defaultManager] moveItemAtPath:[self absolutePath:path]
                                                            toPath:[self absolutePath:toPath]
                                                             error:&error]);
    
    if (error) {
        [self createErrorNotificationWithInformation:@{
                                                       @"error": error,
                                                       @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]
                                                       }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath {
    
    NSError *error = nil;
    BOOL success = ([self contentsOfDirectoryAtPath:toPath] &&
                    [[NSFileManager defaultManager] copyItemAtPath:[self absolutePath:path]
                                                            toPath:[self absolutePath:toPath]
                                                             error:&error]);
    
    if (error) {
        [self createErrorNotificationWithInformation:@{
                                                       @"error": error,
                                                       @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]
                                                       }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (BOOL)renameItemAtPath:(NSString *)path withName:(NSString *)name {
    
    // 형식이 파일인지 파악 후 디렉토리면 에러 또는 No 반환
    return [self moveItemAtPath:path toPath:[[[self absolutePath:path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:name]];
    
}


// Delete Object
- (BOOL)removeItemAtName:(NSString *)name {
    return [self removeItemAtName:name withType:AIDirectoryTypeDocument];
}

- (BOOL)removeItemAtName:(NSString *)name withType:(AIDirectoryType)type {
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:[self assertName:name]];
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:strAbsolutePath error:&error];
    
    if (error) {
        [self createErrorNotificationWithInformation:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (BOOL)removeItemAtNames:(NSArray *)arrNames {
    return [self removeItemAtNames:arrNames withType:AIDirectoryTypeDocument];
}

- (BOOL)removeItemAtNames:(NSArray *)arrNames withType:(AIDirectoryType)type {
    
    BOOL success = YES;
    for (NSString *name in arrNames) {
        success &= [self removeItemAtName:name withType:type];
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

- (BOOL)removeItemAtPath:(NSString *)path withType:(AIDirectoryType)type {
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path withExtension:(NSString *)extension withType:(AIDirectoryType)type {
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path withPrefix:(NSString *)prefix withType:(AIDirectoryType)type {
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path withSuffix:(NSString *)suffix withType:(AIDirectoryType)type {
    return NO;
}

- (BOOL)makeEmptyDirectoryWithType:(AIDirectoryType)type {
    return [self makeEmptyDirectoryWithType:type deep:NO];
}

- (BOOL)makeEmptyDirectoryWithType:(AIDirectoryType)type deep:(BOOL)deep {
    return NO;
}


#pragma mark -
#pragma mark Utility
// Directories 만들기
- (BOOL)createDirectoriesForPath:(NSString *)path {
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];
    
    if (error) {
        [self createErrorNotificationWithInformation:@{
                                                       @"error": error,
                                                       @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]
                                                       }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return success;
    
}

- (NSArray *)contentsAtPath:(NSString *)path deep:(BOOL)deep {
    
    // path에 시스템 경로가 없으면 읽어들일 방법이 없다. 에러!
    if ([self typeCheckAtPath:path] == AIDirectoryTypeNone) {
        [NSException raise:@"Invalid path" format:@"already have system path"];
    }
    
    NSArray *arrSubPaths = nil;
    
    if (deep) {
        arrSubPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    } else {
        arrSubPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    }
    return arrSubPaths;
    
}

// Content lists of Directory
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path {
    return [self contentsOfDirectoryAtPath:path withType:AIDirectoryTypeDocument];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withType:(AIDirectoryType)type {
    
    if (type == AIDirectoryTypeNone) {
        [NSException raise:@"Invalid type" format:@"none type"];
    }
    
    // Type별로 완전한 경로 생성
    NSString *strAbsolutePath = [self createPathForType:type withPath:path];
    return [self contentsAtPath:strAbsolutePath deep:NO];
    
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix {
    return [self contentsOfDirectoryAtPath:path withPrefix:prefix withType:AIDirectoryTypeDocument];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix withType:(AIDirectoryType)type {
    
    NSString *strPredicate = [NSString stringWithFormat:@"SELF BEGINSWITH[ c] '%@'", prefix];
    NSArray *list = [self contentsOfDirectoryAtPath:path withType:type];
    return [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:strPredicate]];
    
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix {
    return [self contentsOfDirectoryAtPath:path withSuffix:suffix withType:AIDirectoryTypeDocument];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix withType:(AIDirectoryType)type {
    
    NSString *strPredicate = [NSString stringWithFormat:@"SELF ENDSWITH[ c] '%@'", suffix];
    NSArray *list = [self contentsOfDirectoryAtPath:path withType:type];
    return [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:strPredicate]];
    
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension {
    return [self contentsOfDirectoryAtPath:path withExtension:extension withType:AIDirectoryTypeDocument];
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension withType:(AIDirectoryType)type {
    
    NSString *strSuffix = [NSString stringWithFormat:@".%@", extension];
    return [self contentsOfDirectoryAtPath:path withSuffix:strSuffix];
    
}


// 아이템 사이즈 구하기
- (NSNumber *)sizeOfItemAtPath:(NSString *)path {
    return (NSNumber *)[self attributeOfItemAtPath:path forKey:NSFileSize];
}

// 파일이 존재 하는지
- (BOOL)fileExistsAtPath:(NSString *)path {
    
    if ([self typeCheckAtPath:path] == AIDirectoryTypeNone) {
        return NO;
    }
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
    
}

// 파일인지 체크
- (BOOL)isFileItemAtPath:(NSString *)path {
    return ([self attributeOfItemAtPath:path forKey:NSFileType] == NSFileTypeRegular);
}

// 폴더인지 체크
- (BOOL)isDirectoryItemAtPath:(NSString *)path {
    return ([self attributeOfItemAtPath:path forKey:NSFileType] == NSFileTypeDirectory);
}

// 아이템 생성일
- (NSDate *)creationDateOfItemAtPath:(NSString *)path {
    return (NSDate *)[self attributeOfItemAtPath:path forKey:NSFileCreationDate];
}

// 아이템 수정일
- (NSDate *)modificationDateOfItemAtPath:(NSString *)path {
    return (NSDate *)[self attributeOfItemAtPath:path forKey:NSFileModificationDate];
}

// 키로 아이템 속성 알기
- (id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key {
    return [[self attributesOfItemAtPath:path] objectForKey:key];
}
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
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path {
    
    NSError *error = nil;
    NSDictionary *dicItemAtPath = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    
    if (error) {
        [self createErrorNotificationWithInformation:@{ @"error": error, @"description": [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] }];
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, error);
    }
    return dicItemAtPath;
    
}


#pragma mark -
#pragma Error 핸들링
- (void)createErrorNotificationWithInformation:(NSDictionary *)info {
    [[NSNotificationCenter defaultCenter] postNotificationName:AIErrorHandlerNotification object:nil userInfo:info];
}


#pragma mark -
#pragma mark Path Appending Methods
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

- (NSString *)createPathForType:(AIDirectoryType)type withPath:(NSString *)path {
    
    switch (type) {
        case AIDirectoryTypeApplicationSupport:
            
            return [self pathForApplicationSupportDirectoryWithPath:path];
            break;
            
        case AIDirectoryTypeDocument:
            
            return [self pathForDocumentsDirectoryWithPath:path];
            break;
            
        case AIDirectoryTypeCaches:
            
            return [self pathForCachesDirectoryWithPath:path];
            break;
            
        case AIDirectoryTypeLibrary:
            
            return [self pathForLibraryDirectoryWithPath:path];
            break;
            
        case AIDirectoryTypeMainBundle:
            
            return [self pathForMainBundleDirectoryWithPath:path];
            break;
            
        default:
            
            return [self pathForDocumentsDirectoryWithPath:path];
            break;
            
    }
    
}

// 시스템 Path가 포함 되어 있는 온전한 Path 반환
- (NSString *)absolutePath:(NSString *)path {
#warning 경로 포함 문제가 있을 듯
    return [self createPathForType:[self typeCheckAtPath:path] withPath:path];
}

- (NSString *)pathForApplicationSupportDirectoryWithPath:(NSString *)path {
    return [self.strApplicationSupportPath stringByAppendingPathComponent:path];
}

- (NSString *)pathForCachesDirectoryWithPath:(NSString *)path {
    return [self.strCachesPath stringByAppendingPathComponent:path];
}

- (NSString *)pathForDocumentsDirectoryWithPath:(NSString *)path {
    return [self.strDocumentPath stringByAppendingPathComponent:path];
}

- (NSString *)pathForLibraryDirectoryWithPath:(NSString *)path {
    return [self.strLibraryPath stringByAppendingPathComponent:path];
}

- (NSString *)pathForMainBundleDirectoryWithPath:(NSString *)path {
    return [self.strMainBundlePath stringByAppendingPathComponent:path];
}

- (NSString *)removeSystemPath:(NSString *)path {
    
    AIDirectoryType type = [self typeCheckAtPath:path];
    
    switch (type) {
        case AIDirectoryTypeApplicationSupport:
            
            return [path stringByReplacingOccurrencesOfString:self.strApplicationSupportPath  withString:@""];
            break;
            
        case AIDirectoryTypeDocument:
            
            return [path stringByReplacingOccurrencesOfString:self.strDocumentPath  withString:@""];
            break;
            
        case AIDirectoryTypeCaches:
            
            return [path stringByReplacingOccurrencesOfString:self.strCachesPath  withString:@""];
            break;
            
        case AIDirectoryTypeLibrary:
            
            return [path stringByReplacingOccurrencesOfString:self.strLibraryPath  withString:@""];
            break;
            
        case AIDirectoryTypeMainBundle:
            
            return [path stringByReplacingOccurrencesOfString:self.strMainBundlePath  withString:@""];
            break;
            
        default:
            
            return path;
            break;
            
    }
    
}

- (NSString *)replacingPath:(NSString *)path withType:(AIDirectoryType)type {
    
    NSString *strPath = [self removeSystemPath:path];
    
    switch (type) {
        case AIDirectoryTypeApplicationSupport:
            
            return [self pathForApplicationSupportDirectoryWithPath:strPath];
            break;
            
        case AIDirectoryTypeDocument:
            
            return [self pathForDocumentsDirectoryWithPath:strPath];
            break;
            
        case AIDirectoryTypeCaches:
            
            return [self pathForCachesDirectoryWithPath:strPath];
            break;
            
        case AIDirectoryTypeLibrary:
            
            return [self pathForLibraryDirectoryWithPath:strPath];
            break;
            
        case AIDirectoryTypeMainBundle:
            
            return [self pathForMainBundleDirectoryWithPath:strPath];
            break;
            
        default:
            
            return [self pathForDocumentsDirectoryWithPath:strPath];
            break;
            
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

@end
