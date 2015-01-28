//
//  CPGraphView.h
//  Silverline
//
//  Created by VC on 28/08/2013.
//  Copyright (c) 2013 Silverline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef enum{
    WATER,
    EXERCISE,
    MOOD
} GraphType;

@interface GraphView : UIView

-(GraphView *)initWithFrame:(CGRect)frame;

@property (atomic) NSMutableArray * values;
@property (atomic) NSArray* weights;
@property (nonatomic, strong) NSString *axisImage;
@property (nonatomic, assign) GraphType type;

@end
