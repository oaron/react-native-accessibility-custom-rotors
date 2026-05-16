#import "AccessibilityCustomRotorsView.h"

#import <React/RCTConversions.h>

#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/Props.h>
#import <react/renderer/components/AccessibilityCustomRotorsViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@implementation AccessibilityCustomRotorsView {
  UIView *_contentView;
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

    _contentView = [[UIView alloc] init];
    self.contentView = _contentView;
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &newViewProps =
      *std::static_pointer_cast<AccessibilityCustomRotorsViewProps const>(props);

  NSMutableArray<UIAccessibilityCustomRotor *> *nativeRotors = [NSMutableArray array];

  for (const auto &rotor : newViewProps.rotors) {
    NSString *rotorName = [NSString stringWithUTF8String:rotor.name.c_str()];

    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    for (const auto &item : rotor.items) {
      [items addObject:@{
        @"testID" : [NSString stringWithUTF8String:item.testID.c_str()],
        @"label" : [NSString stringWithUTF8String:item.label.c_str()],
      }];
    }

    __weak AccessibilityCustomRotorsView *weakSelf = self;
    UIAccessibilityCustomRotor *nativeRotor = [[UIAccessibilityCustomRotor alloc]
        initWithName:rotorName
         itemSearchBlock:^UIAccessibilityCustomRotorItemResult *_Nullable(
             UIAccessibilityCustomRotorSearchPredicate *_Nonnull predicate) {
           AccessibilityCustomRotorsView *strongSelf = weakSelf;
           if (!strongSelf) {
             return nil;
           }
           return [strongSelf rotorItemResultForItems:items predicate:predicate];
         }];

    [nativeRotors addObject:nativeRotor];
  }

  self.accessibilityCustomRotors = nativeRotors;

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - Rotor lookup

- (nullable UIAccessibilityCustomRotorItemResult *)
    rotorItemResultForItems:(NSArray<NSDictionary *> *)items
                  predicate:(UIAccessibilityCustomRotorSearchPredicate *)predicate
{
  if (items.count == 0) {
    return nil;
  }

  NSMutableArray<UIView *> *resolved = [NSMutableArray arrayWithCapacity:items.count];
  NSMutableArray<NSString *> *labels = [NSMutableArray arrayWithCapacity:items.count];
  for (NSDictionary *item in items) {
    UIView *view = [self findViewWithTestID:item[@"testID"] inside:_contentView];
    if (view) {
      [resolved addObject:view];
      [labels addObject:item[@"label"]];
    }
  }
  if (resolved.count == 0) {
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
    return nil;
  }

  UIView *target = resolved[(NSUInteger)nextIndex];
  UIAccessibilityCustomRotorItemResult *result =
      [[UIAccessibilityCustomRotorItemResult alloc] initWithTargetElement:target
                                                              targetRange:nil];
  // Override the label that VoiceOver speaks when landing on this rotor item,
  // falling back to the element's own accessibilityLabel if not provided.
  NSString *label = labels[(NSUInteger)nextIndex];
  if (label.length > 0 && target.accessibilityLabel.length == 0) {
    target.accessibilityLabel = label;
  }
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

@end

Class<RCTComponentViewProtocol> AccessibilityCustomRotorsViewCls(void)
{
  return AccessibilityCustomRotorsView.class;
}
