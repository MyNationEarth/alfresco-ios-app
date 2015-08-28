/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "SearchViewControllerDataSource.h"

@implementation SearchViewControllerDataSource

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType
{
    self = [super init];
    if(self)
    {
        switch (dataSourceType) {
            case SearchViewControllerDataSourceTypeLandingPage:
            {
                self.dataSourceArrays = [NSMutableArray new];
                self.sectionHeaderStringsArray = [NSMutableArray new];
                self.numberOfSections = 1;
                self.showsSearchBar = NO;
                
                NSMutableArray *sectionDataSource = [[NSMutableArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.files", @"Files"), kCellTextKey, @"small_document", kCellImageKey, nil], [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.folders", @"Folders"), kCellTextKey, @"small_folder", kCellImageKey, nil], [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.sites", @"Sites"), kCellTextKey, @"mainmenu-sites", kCellImageKey, nil], [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.people", @"People"), kCellTextKey, @"mainmenu-user", kCellImageKey, nil], nil];
                [self.dataSourceArrays addObject:sectionDataSource];
                
                [self.sectionHeaderStringsArray addObject:NSLocalizedString(@"search.searchfor", @"Search for")];

                break;
            }
            case SearchViewControllerDataSourceTypeSearchFiles:
            {
                [self setupDataSourceForSearchType:SearchViewControllerDataSourceTypeSearchFiles];
                break;
            }
            case SearchViewControllerDataSourceTypeSearchFolders:
            {
                [self setupDataSourceForSearchType:SearchViewControllerDataSourceTypeSearchFolders];
                break;
            }
            case SearchViewControllerDataSourceTypeSearchSites:
            {
                [self setupDataSourceForSearchType:SearchViewControllerDataSourceTypeSearchSites];
                break;
            }
            case SearchViewControllerDataSourceTypeSearchUsers:
            {
                [self setupDataSourceForSearchType:SearchViewControllerDataSourceTypeSearchUsers];
                break;
            }
        }
    }
    
    return self;
}

#pragma mark - Private methods
- (void) setupDataSourceForSearchType:(SearchViewControllerDataSourceType)searchType
{
    self.dataSourceArrays = [NSMutableArray new];
    self.sectionHeaderStringsArray = [NSMutableArray new];
    
    [self.sectionHeaderStringsArray addObject:NSLocalizedString(@"search.search", @"Search")];
    [self.sectionHeaderStringsArray addObject:NSLocalizedString(@"search.previoussearches", @"Previous searches")];
    
    [self.dataSourceArrays addObject:[NSMutableArray new]];
    [self.dataSourceArrays addObject:[self retriveSearchStringsArrayForSearchType:searchType]];
    
    self.numberOfSections = 2;
    self.showsSearchBar = YES;
}

- (NSString *)userDefaultsKeyForSearchType:(SearchViewControllerDataSourceType)searchType
{
    NSString *key;
    
    switch (searchType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            key = kSearchTypeFiles;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            key = kSearchTypeFolders;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            key = kSearchTypeSites;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            key = kSearchTypeUsers;
            break;
        }
        default:
        {
            key = @"";
            break;
        }
    }
    
    return key;
}

#pragma mark - Public methods
- (void)saveSearchString:(NSString *)stringToSave forSearchType:(SearchViewControllerDataSourceType)searchType
{
    NSMutableArray *savedStringsForCurrentDataSourceType = [[[NSUserDefaults standardUserDefaults] objectForKey:[self userDefaultsKeyForSearchType:searchType]] mutableCopy];
    if((!savedStringsForCurrentDataSourceType) || (savedStringsForCurrentDataSourceType.count == 0))
    {
        savedStringsForCurrentDataSourceType = [NSMutableArray new];
    }
    
    if([savedStringsForCurrentDataSourceType indexOfObject:stringToSave] == NSNotFound)
    {
        //Always insert a new string at the begining of the array in order to have the newest strings at the top
        [savedStringsForCurrentDataSourceType insertObject:stringToSave atIndex:0];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:savedStringsForCurrentDataSourceType forKey:[self userDefaultsKeyForSearchType:searchType]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setupDataSourceForSearchType:searchType];
}

- (NSArray *)retriveSearchStringsArrayForSearchType:(SearchViewControllerDataSourceType)searchType
{
    NSArray *previousSearches = [[NSUserDefaults standardUserDefaults] objectForKey:[self userDefaultsKeyForSearchType:searchType]];
    if(!previousSearches)
    {
        previousSearches = [NSArray new];
    }
    
    return previousSearches;
}

@end
