/*
 ******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *****************************************************************************
 */

#import "AlfrescoProfileConfig.h"
#import "AlfrescoConfigPropertyConstants.h"

@interface AlfrescoProfileConfig ()
@property (nonatomic, assign, readwrite) BOOL isDefault;
@property (nonatomic, strong, readwrite) NSString *rootViewId;
@end

@implementation AlfrescoProfileConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super initWithDictionary:properties];
    if (nil != self)
    {
        self.isDefault = [properties[kAlfrescoProfileConfigPropertyIsDefault] boolValue];
        self.rootViewId = properties[kAlfrescoProfileConfigPropertyRootViewId];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.isDefault = [aDecoder decodeBoolForKey:kAlfrescoProfileConfigPropertyIsDefault];
        self.rootViewId = [aDecoder decodeObjectForKey:kAlfrescoProfileConfigPropertyRootViewId];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:self.isDefault forKey:kAlfrescoProfileConfigPropertyIsDefault];
    [aCoder encodeObject:self.rootViewId forKey:kAlfrescoProfileConfigPropertyRootViewId];
}

@end
