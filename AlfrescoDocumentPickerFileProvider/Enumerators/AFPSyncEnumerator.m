/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
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
 ******************************************************************************/

#import "AFPSyncEnumerator.h"
#import "AFPDataManager.h"
#import "AFPItem.h"
#import "AFPItemIdentifier.h"
#import "AFPAccountManager.h"
#import "AFPServerEnumerator+Internals.h"

@implementation AFPSyncEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSError *authenticationError = [AFPAccountManager authenticationErrorForPIN];
    if (authenticationError)
    {
        [observer finishEnumeratingWithError:authenticationError];
    }
    else
    {
        AFPPage *alfrescoPage = [NSKeyedUnarchiver unarchiveObjectWithData:page];
        if(alfrescoPage.hasMoreItems || alfrescoPage == nil)
        {
            __weak typeof(self) weakSelf = self;
            [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
                __strong typeof(self) strongSelf = weakSelf;
                RealmSyncNodeInfo *syncNode = [[AFPDataManager sharedManager] syncItemForId:strongSelf.itemIdentifier];
                AlfrescoNode *parentNode = syncNode.alfrescoNode;
                [self enumerateItemsInFolder:(AlfrescoFolder *)parentNode skipCount:alfrescoPage.skipCount];
            }];
        }
        
        //==== old ====
//        NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
//        NSMutableArray *enumeratedSyncedItems = [NSMutableArray new];
//        NSString *nodeId = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.itemIdentifier];
//        RLMResults<RealmSyncNodeInfo *> *syncedItems = [[AFPDataManager sharedManager] syncItemsInParentNodeWithSyncId:nodeId forAccountIdentifier:accountIdentifier];
//        for(RealmSyncNodeInfo *node in syncedItems)
//        {
//            AFPItem *fpItem = [[AFPItem alloc] initWithSyncedNode:node parentItemIdentifier:self.itemIdentifier];
//            [enumeratedSyncedItems addObject:fpItem];
//        }
//
//        [observer didEnumerateItems:enumeratedSyncedItems];
//        [observer finishEnumeratingUpToPage:nil];
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

@end
