//
//  CPGraphView.m
//  Silverline
//
//  Created by VC on 28/08/2013.
//  Copyright (c) 2013 Silverline. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView

- (GraphView *)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.weights = @[@0.05, @0.14, @0.23, @0.32, @0.41, @0.49, @0.59, @0.68, @0.78, @0.88];
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // Draw history lines
    CGContextRef context = UIGraphicsGetCurrentContext();
    int graphColumn = 70;
    for (int barCount = 0; barCount < 7; barCount++) {
        if (barCount == 6){
            CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:208/255.0 green:19/255.0 blue:184/255.0 alpha:1].CGColor);
            UILabel *TodayLabel = [[UILabel alloc] initWithFrame:CGRectMake(230, 180, 35, 20)];
            TodayLabel.text = NSLocalizedString(@"Today", @"WellBeing/Graph Text/Today");
            TodayLabel.textAlignment = NSTextAlignmentCenter;
            TodayLabel.lineBreakMode = NSLineBreakByWordWrapping;
            TodayLabel.numberOfLines = 0;
            [TodayLabel setTextColor:[UIColor colorWithRed:208/255.0 green:19/255.0 blue:184/255.0 alpha:1]];
            [TodayLabel setBackgroundColor:[UIColor clearColor]];
            [TodayLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:11.0f]];
            [self addSubview:TodayLabel];
        }else{
            CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:208/255.0 green:19/255.0 blue:184/255.0 alpha:1].CGColor);
            UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(240 - (6 - barCount)*30, 180, 20, 20)];
            dateLabel.text = [NSString stringWithFormat:@"%d",  (6 - barCount)];
            dateLabel.textAlignment = NSTextAlignmentCenter;
            dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
            dateLabel.numberOfLines = 0;
            [dateLabel setTextColor:[UIColor colorWithRed:208/255.0 green:19/255.0 blue:184/255.0 alpha:1]];
            [dateLabel setBackgroundColor:[UIColor clearColor]];
            [dateLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:11.0f]];
            [self addSubview:dateLabel];
        }
        CGContextSetLineWidth(context, 5.0);
        CGContextMoveToPoint(context, graphColumn, 177);
        
        int xValue = 0;
        switch (self.type) {
            case WATER:
            {
                xValue = [self.values[6 - barCount] intValue];
                break;
            }
            case EXERCISE:
            {
                if([self.values[6 - barCount] intValue] == 1){
                    xValue = 0;
                }else{
                    xValue = 9;
                }
                break;
            }
            case MOOD:
            {
                if([self.values[6 - barCount] intValue] == 3){
                    xValue = 0;
                }else if([self.values[6 - barCount] intValue] == 4){
                    xValue = 5;
                }else{
                    xValue = 9;
                }
                break;
            }
            default:
                break;
        }
        float weightToUse = [self.weights[xValue] floatValue];
        CGContextAddLineToPoint(context, graphColumn, 177 * (1 - weightToUse));
        CGContextStrokePath(context);
        graphColumn += 30;
    }

    // Draw Axis
    UIImage *axisImageObject = [UIImage imageNamed:self.axisImage];
    UIImageView *axisImageView =
      [[UIImageView alloc] initWithFrame:CGRectMake(8, 10, 290, 180)];
    [axisImageView setImage:axisImageObject];
    [self addSubview:axisImageView];
}

@end
