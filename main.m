// Copyright (c) 2016 Ce Zheng
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <dlfcn.h>

static NSString *xcodeDefaultPath = @"/Applications/Xcode.app";

static NSString *xcodePath() {
  FILE *fp;
  char path[1000];
  fp = popen("/usr/bin/xcode-select -p", "r");
  if (fp == NULL) {
    return xcodeDefaultPath;
  }
  fgets(path, sizeof(path) - 1, fp);
  pclose(fp);
  NSString *developDir = [NSString stringWithUTF8String:path];
  return [[developDir stringByDeletingLastPathComponent]
             stringByDeletingLastPathComponent]
             ?: xcodeDefaultPath;
}

static void loadXcodeFrameworks() {
  NSBundle *xcodeBundle = [NSBundle bundleWithPath:xcodePath()];
  assert(xcodeBundle && "Xcode is not installed.");
  NSURL *xcodeContentsURL =
      [[xcodeBundle privateFrameworksURL] URLByDeletingLastPathComponent];
  NSArray<NSString *> *frameworks = @[
    @"DVTFoundation.framework",
    @"DVTSourceControl.framework",
    @"DVTServices.framework",
    @"DVTPortal.framework",
    @"DVTAnalyticsClient.framework",
    @"DVTAnalytics.framework",
    @"IBFoundation.framework",
    @"IBAutolayoutFoundation.framework",
    @"SourceKit.framework",
    @"IDEFoundation.framework",
    @"Xcode3Core.ideplugin",
  ];
  NSArray *xcodeSubdirectories =
      [[NSFileManager defaultManager] contentsOfDirectoryAtURL:xcodeContentsURL
                                    includingPropertiesForKeys:nil
                                                       options:0
                                                         error:NULL];
  for (NSString *framework in frameworks) {
    for (NSURL *frameworksDirectoryURL in xcodeSubdirectories) {
      NSURL *frameworkURL =
          [frameworksDirectoryURL URLByAppendingPathComponent:framework];
      NSBundle *frameworkBundle = [NSBundle bundleWithURL:frameworkURL];
      if (frameworkBundle) {
        assert([frameworkBundle load] && "Load framework failed");
      }
    }
  }
}

static void initializeXcodeFrameworks() {
  void (*IDEInitialize)(int initializationOptions, NSError **error) =
      dlsym(RTLD_DEFAULT, "IDEInitialize");
  assert(IDEInitialize && "IDEInitialize function not found.");

  void (*XCInitializeCoreIfNeeded)(int initializationOptions) =
      dlsym(RTLD_DEFAULT, "XCInitializeCoreIfNeeded");
  assert(XCInitializeCoreIfNeeded &&
         "XCInitializeCoreIfNeeded function not found.");

  fflush(stderr);
  int saved_stderr = dup(STDERR_FILENO);
  int dev_null = open("/dev/null", O_WRONLY);
  dup2(dev_null, STDERR_FILENO);
  close(dev_null);

  IDEInitialize(1, NULL);
  XCInitializeCoreIfNeeded(0);

  fflush(stderr);
  dup2(saved_stderr, STDERR_FILENO);
  close(saved_stderr);
}

@protocol SelectorsNeeded <NSObject>
+ (id)projectWithFile:(id)arg1;
- (BOOL)writeToFileSystemProjectFile:(BOOL)arg1
                            userFile:(BOOL)arg2
                    checkNeedsRevert:(BOOL)arg3;
@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    assert(argc > 1 && "missing argument for project path");
    NSString *path = [NSString stringWithUTF8String:argv[1]];
    loadXcodeFrameworks();
    initializeXcodeFrameworks();
    Class PBXProject = NSClassFromString(@"PBXProject");
    id project = [PBXProject projectWithFile:path];
    if (![project writeToFileSystemProjectFile:YES
                                      userFile:NO
                              checkNeedsRevert:NO]) {
      exit(1);
    };
  }
  return 0;
}
