#import "AccessibilityCustomRotorsView.h"

#import <React/RCTConversions.h>
#import <React/RCTLog.h>

#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/Props.h>
#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@implementation AccessibilityCustomRotorsView {
  UILabel *_debugOverlay;
  NSMutableArray<NSString *> *_debugLog;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<AccessibilityCustomRotorsViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const AccessibilityCustomRotorsViewProps>();
    _props = defaultProps;

    _debugLog = [NSMutableArray array];
    _debugOverlay = [[UILabel alloc] init];
    _debugOverlay.numberOfLines = 0;
    _debugOverlay.font = [UIFont monospacedSystemFontOfSize:9 weight:UIFontWeightRegular];
    _debugOverlay.textColor = [UIColor redColor];
    _debugOverlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    _debugOverlay.accessibilityElementsHidden = YES;
    _debugOverlay.userInteractionEnabled = NO;
    [self addSubview:_debugOverlay];
    [self _dbg:@"init"];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _debugOverlay.frame = CGRectMake(0, 0, self.bounds.size.width, 220);
  [self bringSubviewToFront:_debugOverlay];
}

- (void)_dbg:(NSString *)msg
{
  [_debugLog addObject:msg];
  while (_debugLog.count > 18) {
    [_debugLog removeObjectAtIndex:0];
  }
  NSString *text = [_debugLog componentsJoinedByString:@"\n"];
  if ([NSThread isMainThread]) {
    _debugOverlay.text = text;
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      self->_debugOverlay.text = text;
    });
  }
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  [super updateProps:props oldProps:oldProps];

  const auto &newViewProps =
      *std::static_pointer_cast<AccessibilityCustomRotorsViewProps const>(props);

  [self _dbg:[NSString stringWithFormat:@"updateProps: %lu rotors", (unsigned long)newViewProps.rotors.size()]];

  NSMutableArray<UIAccessibilityCustomRotor *> *nativeRotors = [NSMutableArray array];

  for (const auto &rotor : newViewProps.rotors) {
    NSString *rotorName = [NSString stringWithUTF8String:rotor.name.c_str()];

    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    for (const auto &item : rotor.items) {
      NSString *testID = [NSString stringWithUTF8String:item.testID.c_str()];
      [items addObject:@{
        @"testID" : testID,
        @"label" : [NSString stringWithUTF8String:item.label.c_str()],
      }];
    }
    [self _dbg:[NSString stringWithFormat:@"  '%@': %lu items", rotorName, (unsigned long)items.count]];

    __weak AccessibilityCustomRotorsView *weakSelf = self;
    UIAccessibilityCustomRotor *nativeRotor = [[UIAccessibilityCustomRotor alloc]
        initWithName:rotorName
         itemSearchBlock:^UIAccessibilityCustomRotorItemResult *_Nullable(
             UIAccessibilityCustomRotorSearchPredicate *_Nonnull predicate) {
           AccessibilityCustomRotorsView *strongSelf = weakSelf;
           if (!strongSelf) {
             return nil;
           }
           return [strongSelf rotorItemResultForItems:items predicate:predicate rotorName:rotorName];
         }];

    [nativeRotors addObject:nativeRotor];
  }

  self.accessibilityCustomRotors = nativeRotors;
  [self _dbg:[NSString stringWithFormat:@"a11yCustomRotors set: %lu", (unsigned long)self.accessibilityCustomRotors.count]];
}

#pragma mark - Rotor lookup

- (nullable UIAccessibilityCustomRotorItemResult *)
    rotorItemResultForItems:(NSArray<NSDictionary *> *)items
                  predicate:(UIAccessibilityCustomRotorSearchPredicate *)predicate
                  rotorName:(NSString *)rotorName
{
  [self _dbg:[NSString stringWithFormat:@"search '%@' dir=%@",
              rotorName,
              predicate.searchDirection == UIAccessibilityCustomRotorDirectionNext ? @"next" : @"prev"]];

  if (items.count == 0) {
    return nil;
  }

  NSMutableArray<UIView *> *resolved = [NSMutableArray arrayWithCapacity:items.count];
  NSMutableArray<NSString *> *labels = [NSMutableArray arrayWithCapacity:items.count];
  for (NSDictionary *item in items) {
    UIView *view = [self findViewWithTestID:item[@"testID"] inside:self];
    if (view) {
      [resolved addObject:view];
      [labels addObject:item[@"label"]];
    }
  }
  [self _dbg:[NSString stringWithFormat:@"resolved %lu/%lu subv=%lu",
              (unsigned long)resolved.count,
              (unsigned long)items.count,
              (unsigned long)self.subviews.count]];

  if (resolved.count == 0) {
    [self _dbg:@"ZERO MATCHES — see console for tree"];
    return nil;
  }

  NSInteger currentIndex = -1;
  if (predicate.currentItem.targetElement) {
    id current = predicate.currentItem.targetElement;
    for (NSUInteger i = 0; i < resolved.count; i++) {
      if (resolved[i] == current) {
        currentIndex = (NSInteger)i;
        break;
      }
    }
  }

  NSInteger nextIndex;
  if (predicate.searchDirection == UIAccessibilityCustomRotorDirectionNext) {
    nextIndex = currentIndex + 1;
  } else {
    nextIndex = currentIndex < 0 ? (NSInteger)resolved.count - 1 : currentIndex - 1;
  }

  if (nextIndex < 0 || nextIndex >= (NSInteger)resolved.count) {
    [self _dbg:[NSString stringWithFormat:@"end (curr=%ld next=%ld)", (long)currentIndex, (long)nextIndex]];
    return nil;
  }

  UIView *target = resolved[(NSUInteger)nextIndex];
  UIAccessibilityCustomRotorItemResult *result =
      [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:target
                                                              targetRange:nil];
  NSString *label = labels[(NSUInteger)nextIndex];
  if (label.length > 0 && target.accessibilityLabel.length == 0) {
    target.accessibilityLabel = label;
  }
  [self _dbg:[NSString stringWithFormat:@"RETURN [%ld] %@ a11y=%d",
              (long)nextIndex,
              NSStringFromClass(target.class),
              target.isAccessibilityElement]];
  return result;
}

// RN Fabric maps the `testID` JSX prop to `UIView.accessibilityIdentifier`,
// so the lookup walks the subview tree and matches by accessibilityIdentifier.
- (nullable UIView *)findViewWithTestID:(NSString *)testID inside:(UIView *)root
{
  if ([root.accessibilityIdentifier isEqualToString:testID]) {
    return root;
  }
  for (UIView *child in root.subviews) {
    UIView *found = [self findViewWithTestID:testID inside:child];
    if (found) {
      return found;
    }
  }
  return nil;
}

- (void)_dumpTreeFrom:(UIView *)view depth:(NSInteger)depth
{
  NSString *pad = [@"" stringByPaddingToLength:(NSUInteger)depth * 2
                                   withString:@" "
                              startingAtIndex:0];
  RCTLogWarn(@"[CustomRotors] %@%@ id='%@' a11y=%d label='%@'",
             pad,
             NSStringFromClass(view.class),
             view.accessibilityIdentifier ?: @"",
             view.isAccessibilityElement,
             view.accessibilityLabel ?: @"");
  fprintf(stderr, "[CustomRotors] %s%s id='%s' a11y=%d\n",
          pad.UTF8String,
          NSStringFromClass(view.class).UTF8String,
          (view.accessibilityIdentifier ?: @"").UTF8String,
          view.isAccessibilityElement);
  if (depth > 8) {
    return;
  }
  for (UIView *child in view.subviews) {
    [self _dumpTreeFrom:child depth:depth + 1];
  }
}

@end

Class<RCTComponentViewProtocol> AccessibilityCustomRotorsViewCls(void)
{
  return AccessibilityCustomRotorsView.class;
}
