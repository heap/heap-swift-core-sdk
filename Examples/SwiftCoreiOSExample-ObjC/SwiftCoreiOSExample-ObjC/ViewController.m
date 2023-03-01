//
//  ViewController.m
//  SwiftCoreiOSExample-ObjC
//
//  Created by Brian Nickel on 3/1/23.
//

#import "ViewController.h"
@import HeapSwiftCore;

@interface ViewController ()
@end

@implementation ViewController

- (IBAction)buttonClicked:(id)sender
{
    [Heap.sharedInstance track:@"Button Clicked" properties:@{
        @"source language": @"Objective C ❤️",
    }];
}

@end
