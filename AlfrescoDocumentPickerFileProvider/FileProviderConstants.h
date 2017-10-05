/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AlfrescoFileProviderItemIdentifierType)
{
    AlfrescoFileProviderItemIdentifierTypeAccount,
    AlfrescoFileProviderItemIdentifierTypeFolder,
    AlfrescoFileProviderItemIdentifierTypeDocument,
    AlfrescoFileProviderItemIdentifierTypeSite,
    AlfrescoFileProviderItemIdentifierTypeMyFiles,
    AlfrescoFileProviderItemIdentifierTypeSharedFiles,
    AlfrescoFileProviderItemIdentifierTypeSites,
    AlfrescoFileProviderItemIdentifierTypeMySites,
    AlfrescoFileProviderItemIdentifierTypeFavoriteSites,
    AlfrescoFileProviderItemIdentifierTypeFavorites,
    AlfrescoFileProviderItemIdentifierTypeSynced
};

extern NSString * const kAccountsListIdentifier;

extern NSString * const kFileProviderAccountsIdentifierPrefix;

extern NSString * const kFileProviderSharedFilesFolderIdentifierSuffix;
extern NSString * const kFileProviderMyFilesFolderIdentifierSuffix;
extern NSString * const kFileProviderFavoritesFolderIdentifierSuffix;
extern NSString * const kFileProviderSyncedFolderIdentifierSuffix;
extern NSString * const kFileProviderSitesFolderIdentifierSuffix;
extern NSString * const kFileProviderMySitesFolderIdentifierSuffix;
extern NSString * const kFileProviderFavoriteSitesFolderIdentifierSuffix;

extern NSString * const kFileProviderFolderPathString;
extern NSString * const kFileProviderSitePathString;
extern NSString * const kFileProviderDocumentPathString;

extern int const kFileProviderMaxItemsPerListingRetrieve;
