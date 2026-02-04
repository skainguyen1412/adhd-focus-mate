## UI Pro Max Stack Guidelines
**Stack:** swiftui | **Query:** productivity timer layout animation glassmorphism
**Source:** stacks/swiftui.csv | **Found:** 3 results

### Result 1
- **Category:** Animation
- **Guideline:** Use .animation modifier
- **Description:** Apply animations to views
- **Do:** .animation(.spring()) on view
- **Don't:** Manual animation timing
- **Code Good:** .animation(.easeInOut)
- **Code Bad:** CABasicAnimation equivalent
- **Severity:** Low
- **Docs URL:** 

### Result 2
- **Category:** Animation
- **Guideline:** Use withAnimation
- **Description:** Animate state changes
- **Do:** withAnimation for state transitions
- **Don't:** No animation for state changes
- **Code Good:** withAnimation { isExpanded.toggle() }
- **Code Bad:** isExpanded.toggle()
- **Severity:** Low
- **Docs URL:** https://developer.apple.com/documentation/swiftui/withanimation(_:_:)

### Result 3
- **Category:** Animation
- **Guideline:** Respect reduced motion
- **Description:** Check accessibility settings
- **Do:** Check accessibilityReduceMotion
- **Don't:** Ignore motion preferences
- **Code Good:** @Environment(\.accessibilityReduceMotion)
- **Code Bad:** Always animate regardless
- **Severity:** High
- **Docs URL:** 

