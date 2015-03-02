//
//  AIFileManager.h
//  AIFileManagerExample
//
//  Created by aidenjlee on 2015. 2. 25..
//  Copyright (c) 2015년 entist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
- (BOOL)saveContent:(NSObject *)content atName:(NSString *)name;                                // Object 저장 - 기본 경로는 Document
- (BOOL)saveContent:(NSObject *)content atName:(NSString *)name withType:(AIDirectoryType)type; // Object 저장 - 경로 지정은 사용자가


#pragma mark Read
// 모든 오브젝트는 Data로 불러 올 수 있음 - 그 외의 API는 옵션임
- (NSData *)readDataAtName:(NSString *)name;                                                    // Object 읽기 - 기본 경로는 Document
- (NSData *)readDataAtName:(NSString *)name withType:(AIDirectoryType)type;                     // Object 읽기 - 경로 지정은 사용자가

- (NSString *)readFileAtName:(NSString *)name;                                                  // String 읽기 - txt?
- (NSString *)readFileAtName:(NSString *)name withType:(AIDirectoryType)type;

- (NSArray *)readArrayAtName:(NSString *)name;                                                  // Array 읽기
- (NSArray *)readArrayAtName:(NSString *)name withType:(AIDirectoryType)type;

- (NSDictionary *)readDictionaryAtName:(NSString *)name;                                        // Dictionary 읽기
- (NSDictionary *)readDictionaryAtName:(NSString *)name withType:(AIDirectoryType)type;

- (NSObject *)readCustomModelAtName:(NSString *)name;                                           // Model data 읽기 - 이것은 아카이빙함
- (NSObject *)readCustomModelAtName:(NSString *)name withType:(AIDirectoryType)type;

- (UIImage *)readImageAtName:(NSString *)name;                                                  // Image 읽기
- (UIImage *)readImageAtName:(NSString *)name withType:(AIDirectoryType)type;

- (NSDictionary *)readJSONObjectAtName:(NSString *)name;                                        // JSON 읽기
- (NSDictionary *)readJSONObjectAtName:(NSString *)name withType:(AIDirectoryType)type;


#pragma mark Update
// 이름이 어렵다... 아.. name이 Path도 포함 하는건데 이름이 안나오네
- (BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath;
- (BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath;
- (BOOL)renameItemAtPath:(NSString *)path withName:(NSString *)name;


#pragma mark Delete
// Remove Object
- (BOOL)removeItemAtName:(NSString *)name;                                                      // 아이템 하나 삭제 - 기본 Document 폴더
- (BOOL)removeItemAtName:(NSString *)name withType:(AIDirectoryType)type;                       // 아이템 하나 삭제 - 폴더 지정
- (BOOL)removeItemAtNames:(NSArray *)arrNames;                                                  // 아이템들 삭제 - 기본 Document 폴더
- (BOOL)removeItemAtNames:(NSArray *)arrNames withType:(AIDirectoryType)type;                   // 아이템들 삭제 - 폴더 지정

// Remove Object in Directory - !!아직 작업 안됨
- (BOOL)removeItemAtPath:(NSString *)path withExtension:(NSString *)extension;                  // 옵션 : 확장자 지정해서 삭제
- (BOOL)removeItemAtPath:(NSString *)path withExtension:(NSString *)extension withType:(AIDirectoryType)type;

- (BOOL)removeItemAtPath:(NSString *)path withPrefix:(NSString *)prefix;                        // 옵션 : prefix로 삭제
- (BOOL)removeItemAtPath:(NSString *)path withPrefix:(NSString *)prefix withType:(AIDirectoryType)type;

- (BOOL)removeItemAtPath:(NSString *)path withSuffix:(NSString *)suffix;                        // 옵션 : suffix로 삭제
- (BOOL)removeItemAtPath:(NSString *)path withSuffix:(NSString *)suffix withType:(AIDirectoryType)type;

- (BOOL)makeEmptyDirectoryWithType:(AIDirectoryType)type;                                       // 기본 폴더 내용 삭제
- (BOOL)makeEmptyDirectoryWithType:(AIDirectoryType)type deep:(BOOL)deep;                       // 기본 폴더 내용 삭제 - 하위 디렉토리까지 전부


#pragma mark Utility
// Content lists of Directory
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withType:(AIDirectoryType)type;

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix withType:(AIDirectoryType)type;

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix withType:(AIDirectoryType)type;

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension withType:(AIDirectoryType)type;

//// Content lists of Directory & Content lists of SubDirectory
//- (NSArray *)contentListsAtPath:(NSString *)path;
//- (NSArray *)contentListsAtPath:(NSString *)path withExtension:(NSString *)extension;
//- (NSArray *)contentListsAtPath:(NSString *)path withPrefix:(NSString *)prefix;
//- (NSArray *)contentListsAtPath:(NSString *)path withSuffix:(NSString *)suffix;
//
//- (NSArray *)contentListsAtPath:(NSString *)path withType:(AIDirectoryType)type;
//- (NSArray *)contentListsAtPath:(NSString *)path withExtension:(NSString *)extension withType:(AIDirectoryType)type;
//- (NSArray *)contentListsAtPath:(NSString *)path withPrefix:(NSString *)prefix withType:(AIDirectoryType)type;
//- (NSArray *)contentListsAtPath:(NSString *)path withSuffix:(NSString *)suffix withType:(AIDirectoryType)type;

- (NSNumber *)sizeOfItemAtPath:(NSString *)path;                                    // 사이즈 체크
- (BOOL)fileExistsAtPath:(NSString *)path;                                          // 파일이 존재 하는지
- (BOOL)isFileItemAtPath:(NSString *)path;                                          // 파일인지 체크
- (NSDate *)creationDateOfItemAtPath:(NSString *)path;                              // 아이템 생성일
- (NSDate *)modificationDateOfItemAtPath:(NSString *)path;                          // 아이템 수정일
- (id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key;                // 키로 아이템 속성 찾기

@end
