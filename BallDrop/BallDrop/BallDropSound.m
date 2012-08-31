//
//  BallDropSound.m
//  BallDrop
//
//  Created by Peter Gibson on 8/23/12.
//  Copyright (c) 2012 Brown University. All rights reserved.
//

#import "BallDropSound.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation BallDropSound

+ (void) makeSoundofType: (int)soundType ofNote: (int)note
{
    if ((soundType > 2) || (soundType < 0) || (note > 12) || (note < 0)) {
        NSLog(@"Invalid Sound File");
        return;
    }
    note++; 
    NSMutableString *soundName;

    switch (soundType){
        case 0:
            soundName = [NSMutableString stringWithString:@"Drum"];
            note = note % 8; //temp fix: are we going to have more drum sounds??
            break;
        case 1:
            soundName = [NSMutableString stringWithString:@"Bass"];
            break;
        case 2:
            soundName = [NSMutableString stringWithString:@"Bell"];
            break;
    }
    [soundName appendString:[NSString stringWithFormat:@"%i", note]];
    SystemSoundID soundID;
    NSString *path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

@end
