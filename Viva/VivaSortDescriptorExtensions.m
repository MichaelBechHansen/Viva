//
//  VivaSortDescriptorExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaSortDescriptorExtensions.h"

@implementation NSSortDescriptor (VivaSortDescriptorExtensions)

+(NSArray *)trackContainerSortDescriptorsForTitleAscending:(BOOL)ascending {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)]];
}

+(NSArray *)trackContainerSortDescriptorsForAlbumAscending:(BOOL)ascending {
	return [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"track.album.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"track.discNumber" ascending:YES selector:@selector(compare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"track.trackNumber" ascending:YES selector:@selector(compare:)],
			nil];
}

+(NSArray *)trackContainerSortDescriptorsForArtistAscending:(BOOL)ascending {
	
	return [[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track.album.artist.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)]]
			arrayByAddingObjectsFromArray:[self trackContainerSortDescriptorsForAlbumAscending:ascending]];
	
}

@end