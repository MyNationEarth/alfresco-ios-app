//
//  TaskDetailsViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TaskDetailsViewController.h"
#import "TaskHeaderView.h"
#import "MBProgressHUD.h"
#import "PagedScrollView.h"
#import "ThumbnailDownloader.h"
#import "Utility.h"
#import "AlfrescoNodeCell.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "DocumentPreviewViewController.h"
#import "Utility.h"
#import "ErrorDescriptions.h"
#import "TextView.h"
#import "UIColor+Custom.h"
#import "TasksAndAttachmentsViewController.h"

static NSString * const kReviewKey = @"Review";
static CGFloat const kMaxCommentTextViewHeight = 60.0f;

typedef NS_ENUM(NSUInteger, TaskType)
{
    TaskTypeTask = 0,
    TaskTypeProcess
};

@interface TaskDetailsViewController () <TextViewDelegate, UIGestureRecognizerDelegate>

//// Layout Constraints ////
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textViewContainerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomSpacingOfTextViewContainerConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *doneButtonWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *approveButtonWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rejectButtonWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *reassignButtonWidthConstraint;

//// Data Models ////
// Models
@property (nonatomic, strong) AlfrescoWorkflowProcess *process;
@property (nonatomic, strong) AlfrescoWorkflowTask *task;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, assign) TaskType taskType;
// Services
@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;

//// Views ////
// Header
@property (nonatomic, weak) TaskHeaderView *taskHeaderView;
@property (nonatomic, weak) IBOutlet UIView *taskHeaderViewContainer;
// Container
@property (nonatomic, weak) IBOutlet UIView *detailsContainerView;
// Comments
@property (nonatomic, weak) IBOutlet TextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UIButton *approveButton;
@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UIButton *reassignButton;

@end

@implementation TaskDetailsViewController

- (instancetype)initWithTask:(AlfrescoWorkflowTask *)task session:(id<AlfrescoSession>)session
{
    self = [self initWithTaskType:TaskTypeTask session:session];
    if (self)
    {
        self.task = task;
    }
    return self;
}

- (instancetype)initWithProcess:(AlfrescoWorkflowProcess *)process session:(id<AlfrescoSession>)session
{
    self = [self initWithTaskType:TaskTypeProcess session:session];
    if (self)
    {
        self.process = process;
    }
    return self;
}

- (instancetype)initWithTaskType:(TaskType)taskType session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.taskType = taskType;
        [self createServicesWithSession:session];
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // configure the view
    [self configureForType:self.taskType];

    // dismiss keyboard gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    // localise UI
    [self localiseUI];
}

#pragma mark - Private Functions

- (void)localiseUI
{
    self.textView.placeholderText = NSLocalizedString(@"tasks.textview.addcomment.placeholder", @"Ad comment placeholder");
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createServicesWithSession:session];
}

- (void)createServicesWithSession:(id<AlfrescoSession>)session
{
    self.workflowService = [[AlfrescoWorkflowService alloc] initWithSession:session];
}

- (void)configureForType:(TaskType)type
{
    [self createTaskHeaderView];
    
    TasksAndAttachmentsViewController *attachmentViewController = nil;
    
    if (type == TaskTypeTask)
    {
        // configure the header view for the task
        [self.taskHeaderView configureViewForTask:self.task];
        // configure the transition buttons
        [self configureTransitionButtonsForTask:self.task];
        // init the attachment controller
        attachmentViewController = [[TasksAndAttachmentsViewController alloc] initWithTask:self.task session:self.session];
        // set the tableview inset to ensure the content isn't behind the comment view
        attachmentViewController.tableViewInsets = UIEdgeInsetsMake(0, 0, self.textViewContainerHeightConstraint.constant, 0);
        // retrieve the process definition for the header view
        [self retrieveProcessDefinitionNameForIdentifier:self.task.processDefinitionIdentifier];
    }
    else if (type == TaskTypeProcess)
    {
        // configure the header view for the process
        [self.taskHeaderView configureViewForProcess:self.process];
        // init the attachment controller
        attachmentViewController = [[TasksAndAttachmentsViewController alloc] initWithProcess:self.process session:self.session];
        // hide the comment view
        self.textViewContainerHeightConstraint.constant = 0;
        // retrieve the process definition for the header view
        [self retrieveProcessDefinitionNameForIdentifier:self.process.processDefinitionIdentifier];
    }
    
    // add the attachment controller
    [self addChildViewController:attachmentViewController];
    attachmentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.detailsContainerView addSubview:attachmentViewController.view];
    [attachmentViewController didMoveToParentViewController:self];
    
    // setup the constraints to the container view
    NSDictionary *views = @{@"childView" : attachmentViewController.view};
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    [self.detailsContainerView addConstraints:verticalConstraints];
    [self.detailsContainerView addConstraints:horizontalConstraints];
    
    // setup the comments text view
    self.textView.maximumHeight = kMaxCommentTextViewHeight;
    self.textView.layer.cornerRadius = 5.0f;
    self.textView.layer.borderColor = [[UIColor borderGreyColor] CGColor];
    self.textView.layer.borderWidth = 0.5f;
    self.textView.font = [UIFont systemFontOfSize:12.0f];
}

- (void)configureTransitionButtonsForTask:(AlfrescoWorkflowTask *)task
{
    if ([self shouldDisplayApproveAndRejectButtonsForTask:task])
    {
        self.doneButtonWidthConstraint.constant = 0;
    }
    else
    {
        self.approveButtonWidthConstraint.constant = 0;
        self.rejectButtonWidthConstraint.constant = 0;
    }
}

- (BOOL)shouldDisplayApproveAndRejectButtonsForTask:(AlfrescoWorkflowTask *)task
{
    BOOL displayApproveAndReject = NO;
    // if it contains review in the processDefinitionIdentifier - It's a review and approve task.
    if ([task.processDefinitionIdentifier rangeOfString:kReviewKey options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        displayApproveAndReject = YES;
    }
    return displayApproveAndReject;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    
    NSNumber *animationSpeed = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect keyboardRectForScreen = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardRectForView = [self.view convertRect:keyboardRectForScreen fromView:self.view.window];

    CGSize kbSize = keyboardRectForView.size;
    
    [UIView animateWithDuration:animationSpeed.doubleValue delay:0.0f options:animationCurve.unsignedIntegerValue animations:^{
        self.bottomSpacingOfTextViewContainerConstraint.constant = kbSize.height;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    
    NSNumber *animationSpeed = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView animateWithDuration:animationSpeed.doubleValue delay:0.0f options:animationCurve.unsignedIntegerValue animations:^{
        self.bottomSpacingOfTextViewContainerConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)createTaskHeaderView
{
    TaskHeaderView *taskHeaderView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TaskHeaderView class]) owner:self options:nil] lastObject];
    [self.taskHeaderViewContainer addSubview:taskHeaderView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(taskHeaderView);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[taskHeaderView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    NSArray *verticalContraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[taskHeaderView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    
    [self.taskHeaderViewContainer addConstraints:horizontalConstraints];
    [self.taskHeaderViewContainer addConstraints:verticalContraints];
    self.taskHeaderView = taskHeaderView;
}

- (void)retrieveProcessDefinitionNameForIdentifier:(NSString *)identifier
{
    [self.workflowService retrieveProcessDefinitionWithIdentifier:identifier completionBlock:^(AlfrescoWorkflowProcessDefinition *processDefinition, NSError *error) {
        if (processDefinition)
        {
            [self.taskHeaderView updateTaskTypeLabelToString:processDefinition.name];
        }
    }];
}

- (void)completeTaskWithProperties:(NSDictionary *)properties
{
    __block MBProgressHUD *completingProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:completingProgressHUD];
    [completingProgressHUD show:YES];
    
    self.approveButton.enabled = NO;
    self.rejectButton.enabled = NO;
    [self.textView resignFirstResponder];
    
    __weak typeof(self) weakSelf = self;
    [self.workflowService completeTask:self.task properties:properties completionBlock:^(AlfrescoWorkflowTask *task, NSError *error) {
        [completingProgressHUD hide:YES];
        completingProgressHUD = nil;
        weakSelf.approveButton.enabled = YES;
        weakSelf.rejectButton.enabled = YES;
        
        if (error)
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.add.comment.failed", @"Adding Comment Failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
            [weakSelf.textView becomeFirstResponder];
        }
        else
        {
            weakSelf.textView.text = NSLocalizedString(@"tasks.textview.addcomment.placeholder", @"Add Comment");
            // TODO
        }
    }];
}

- (void)didTapView:(UITapGestureRecognizer *)gesture
{
    [self.textView resignFirstResponder];
}

#pragma mark - IBActions

- (IBAction)pressedApproveButton:(id)sender
{
    NSMutableDictionary *properties = [@{kAlfrescoWorkflowTaskReviewOutcome : kAlfrescoWorkflowTaskTransitionApprove} mutableCopy];
    
    if (self.textView.hasText)
    {
        [properties setObject:self.textView.text forKey:kAlfrescoWorkflowTaskComment];
    }
    
    [self completeTaskWithProperties:properties];
}

- (IBAction)pressedRejectButton:(id)sender
{
    NSMutableDictionary *properties = [@{kAlfrescoWorkflowTaskReviewOutcome : kAlfrescoWorkflowTaskTransitionReject} mutableCopy];
    
    if (self.textView.hasText)
    {
        [properties setObject:self.textView.text forKey:kAlfrescoWorkflowTaskComment];
    }
    
    [self completeTaskWithProperties:properties];
}

#pragma mark - TextViewDelegate Functions

- (void)textViewHeightDidChange:(TextView *)textView
{
    [self.view sizeToFit];
}

#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldRecieveTouch = YES;
    
    if ([touch.view isDescendantOfView:self.detailsContainerView])
    {
        shouldRecieveTouch = NO;
    }
    
    return shouldRecieveTouch;
}

@end