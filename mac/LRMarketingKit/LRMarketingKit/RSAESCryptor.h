//
//  RSAESCryptor.h
//  RSAESCryptor
//
//  Created by San Chen on 7/15/12.
//  Copyright (c) 2012 Learningtech. All rights reserved.
//

@import Foundation;

@interface RSAESCryptor : NSObject

- (void)loadPublicKey:(NSString *)keyPath;
- (NSData *)encryptData:(NSData *)content;

- (void)loadPrivateKey:(NSString *)keyPath password:(NSString *)password;
- (NSData *)decryptData:(NSData *)content;

@end
