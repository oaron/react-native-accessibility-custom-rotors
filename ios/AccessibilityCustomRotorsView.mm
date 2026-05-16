#import "AccessibilityCustomRotorsView.h"

#import <React/RCTConversions.h>
#import <React/RCTLog.h>

#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/Props.h>
#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@implementation AccessibilityCustomRotorsView

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<AccessibilityCustomRotorsViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const AccessibilityCustomRotorsViewProps>();
    _props = defaultProps;
    // Don't touch self.contentView — RCTViewComponentView's default child
    // mounting works fine; overriding it here was preventing the wrapper
    // subtree from being walkable for accessibilityIdentifier lookup.
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  // Call super FIRST so the base class doesn't overwrite our
  // accessibilityCustomRotors when processing standard view props.
  [super updateProps:props oldProps:oldProps];

  const auto &newViewProps =
      *std::static_pointer_cast<AccessibilityCustomRotorsViewProps const>(props);

  RCTLogWarn(@"[CustomRotors] updateProps: %lu rotors", (unsigned long)newViewProps.rotors.size());
  fprintf(stderr, "[CustomRotors] updateProps: %lu rotors\n", (unsigned long)newViewProps.rotors.size());

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
    RCTLogWarn(@"[CustomRotors]   rotor '%@' has %lu items", rotorName, (unsigned long)items.count);
    fprintf(stderr, "[CustomRotors]   rotor '%s' has %lu items\n", rotorName.UTF8String, (unsigned long)items.count);

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
  RCTLogWarn(@"[CustomRotors] accessibilityCustomRotors now: %lu", (unsigned long)self.accessibilityCustomRotors.count);
  fprintf(stderr, "[CustomRotors] accessibilityCustomRotors now: %lu\n", (unsigned long)self.accessibilityCustomRotors.count);
}

#pragma mark - Rotor lookup

- (nullable UIAccessibilityCustomRotorItemResult *)
    rotorItemResultForItems:(NSArray<NSDictionary *> *)items
                  predicate:(UIAccessibilityCustomRotorSearchPredicate *)predicate
                  rotorName:(NSString *)rotorName
{
  RCTLogWarn(@"[CustomRotors] search '%@' dir=%@ items=%lu",
             rotorName,
             predicate.searchDirection == UIAccessibilityCustomRotorDirectionNext ? @"next" : @"prev",
             (unsigned long)items.count);
  fprintf(stderr, "[CustomRotors] search '%s' dir=%s items=%lu\n",
          rotorName.UTF8String,
          predicate.searchDirection == UIAccessibilityCustomRotorDirectionNext ? "next" : "prev",
          (unsigned long)items.count);

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
      RCTLogWarn(@"[CustomRotors]   FOUND '%@' → %@ isA11y=%d frame=%@",
                 item[@"testID"], NSStringFromClass(view.class), view.isAccessibilityElement, NSStringFromCGRect(view.frame));
      fprintf(stderr, "[CustomRotors]   FOUND '%s'\n", [item[@"testID"] UTF8String]);
    } else {
      RCTLogWarn(@"[CustomRotors]   MISS '%@'", item[@"testID"]);
      fprintf(stderr, "[CustomRotors]   MISS '%s'\n", [item[@"testID"] UTF8String]);
    }
  }
  RCTLogWarn(@"[CustomRotors] resolved %lu/%lu; self.subviews=%lu",
             (unsigned long)resolved.count,
             (unsigned long)items.count,
             (unsigned long)self.subviews.count);
  fprintf(stderr, "[CustomRotors] resolved %lu/%lu; self.subviews=%lu\n",
          (unsigned long)resolved.count, (unsigned long)items.count, (unsigned long)self.subviews.count);

  if (resolved.count == 0) {
    RCTLogWarn(@"[CustomRotors] nothing matched — dumping subview tree:");
    [self _dumpTreeFrom:self depth:0];
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
    RCTLogWarn(@"[CustomRotors] end of list (currentIndex=%ld, nextIndex=%ld)", (long)currentIndex, (long)nextIndex);
    fprintf(stderr, "[CustomRotors] end of list (curr=%ld next=%ld)\n", (long)currentIndex, (long)nextIndex);
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
  RCTLogWarn(@"[CustomRotors] → RETURN index=%ld %@ isA11y=%d label='%@'",
             (long)nextIndex, NSStringFromClass(target.class), target.isAccessibilityElement, target.accessibilityLabel ?: @"");
  fprintf(stderr, "[CustomRotors] → RETURN index=%ld\n", (long)nextIndex);
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
