//
//  SVLoginViewController.m
//  Selvee
//
//  Created by Leonard Loo on 14/9/14.
//  Copyright (c) 2014 Selvee. All rights reserved.
//

#import "SVLoginViewController.h"

@interface SVLoginViewController () <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet FBLoginView *loginView;

@end

@implementation SVLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    FBLoginView *loginView = [[FBLoginView alloc] initWithReadPermissions:@[@"public_profile", @"email", @"user_friends"]];
    self.loginView.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    // Perform loginSegue
    [self performSegueWithIdentifier:@"loginSegue" sender:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
