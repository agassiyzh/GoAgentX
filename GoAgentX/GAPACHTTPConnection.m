//
//  GAPACHTTPConnection.m
//  GoAgentX
//
//  Created by Xu Jiwei on 12-4-26.
//  Copyright (c) 2012年 xujiwei.com. All rights reserved.
//

#import "GAPACHTTPConnection.h"

#import "HTTPDynamicFileResponse.h"

@implementation GAPACHTTPConnection

- (NSString*)secondProxy {
    
    NSData *secondProxyData = [[NSUserDefaults standardUserDefaults] dataForKey:@"GoAgentX:SecondProxy"];
    
    NSString *secondProxy = [(NSAttributedString *)[NSUnarchiver unarchiveObjectWithData:secondProxyData] string];
    
    return secondProxy;
}

- (NSString *)secondPACDomainList {
    NSData *domainListData = [[NSUserDefaults standardUserDefaults] dataForKey:@"GoAgentX:SecondDomainList"];
    NSString *customDomainListString = domainListData ? [(NSAttributedString *)[NSUnarchiver unarchiveObjectWithData:domainListData] string] : @"";
    customDomainListString = [customDomainListString stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    customDomainListString = [customDomainListString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray *customDomainList = [customDomainListString componentsSeparatedByString:@"\n"];
    
    NSMutableArray *ret = [NSMutableArray new];
    for (NSString *line in customDomainList) {
        if ([line length] > 0) {
            [ret addObject:line];
        }
    }
    
    if ([ret count] > 0) {
        return [NSString stringWithFormat:@"|| shExpMatch(host, \"%@\")", [ret componentsJoinedByString:@"\")\n\t|| shExpMatch(host, \""]];
    }
    
    return @"";
}

- (NSString *)customPACDomainList {
    NSData *domainListData = [[NSUserDefaults standardUserDefaults] dataForKey:@"GoAgentX:CustomPACDomainList"];
    NSString *customDomainListString = domainListData ? [(NSAttributedString *)[NSUnarchiver unarchiveObjectWithData:domainListData] string] : @"";
    customDomainListString = [customDomainListString stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    customDomainListString = [customDomainListString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray *customDomainList = [customDomainListString componentsSeparatedByString:@"\n"];
    
    NSMutableArray *ret = [NSMutableArray new];
    for (NSString *line in customDomainList) {
        if ([line length] > 0) {
            [ret addObject:line];
        }
    }
    
    if ([ret count] > 0) {
        return [NSString stringWithFormat:@"|| shExpMatch(host, \"%@\")", [ret componentsJoinedByString:@"\")\n\t|| shExpMatch(host, \""]];
    }
    
    return @"";
}


- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	NSString *filePath = [self filePathForURI:path];
	
	// Convert to relative path
	
	NSString *documentRoot = [config documentRoot];
	
	if (![filePath hasPrefix:documentRoot]) {
		// Uh oh.
		// HTTPConnection's filePathForURI was supposed to take care of this for us.
		return nil;
	}
	
	NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    
	if ([relativePath isEqualToString:@"/proxy.pac"]) {
        NSString *pacTemplate = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pactemplate" ofType:@"pac"] encoding:NSUTF8StringEncoding error:NULL];
        pacTemplate = [[NSString alloc] initWithData:[NSData dataFromBase64String:pacTemplate] encoding:NSUTF8StringEncoding];
        
        NSString *query = [path substringFromIndex:[@"/proxy.pac?" length]];
        query = [query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        query = [query stringByReplacingOccurrencesOfString:@"/" withString:@" "];
        
        NSString *pacContent = [pacTemplate stringByReplacingOccurrencesOfString:@"PROXY 127.0.0.1:65536" withString:query];
        pacContent = [pacContent stringByReplacingOccurrencesOfString:@"${GoAgentX:CustomPACDomainList}"
                                                           withString:[self customPACDomainList]];
        
        
        NSString *secondProxy = [self secondProxy];

        if (nil != secondProxy && secondProxy.length != 0) {
            NSString *originProxy = @"SOCKS5 127.0.0.1:7070; SOCKS 127.0.0.1:7070; DIRECT";
            pacContent = [pacContent stringByReplacingOccurrencesOfString:originProxy withString:secondProxy];
        }
        
        pacContent = [pacContent stringByReplacingOccurrencesOfString:@"${GoAgentX:SecondProxyCDomainList}"
                                                           withString:[self secondPACDomainList]];
        
        
        NSMutableDictionary *replacementDict = [NSMutableDictionary dictionaryWithObject:pacContent forKey:@"PAC_CONTENT"];
        

		
		return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path]
                                                   forConnection:self
                                                       separator:@"%%"
                                           replacementDictionary:replacementDict];
        
       
	}
	
	return [super httpResponseForMethod:method URI:path];
}

@end
