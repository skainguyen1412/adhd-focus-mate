## Design System: ADHD Timer AI

### Pattern
- **Name:** Webinar Registration
- **Conversion Focus:**  speaker avatar float,  urgent ticker, Limited seats logic. 'Live' indicator. Auto-fill timezone.
- **CTA Placement:** Hero (Right side form) + Bottom anchor
- **Color Strategy:** Urgency: Red/Orange. Professional: Blue/Navy. Form: High contrast white.
- **Sections:** 1. Hero (Topic + Timer + Form), 2. What you'll learn, 3. Speaker Bio, 4. Urgency/Bonuses, 5. Form (again)

### Style
- **Name:** Micro-interactions
- **Keywords:** Small animations, gesture-based, tactile feedback, subtle animations, contextual interactions, responsive
- **Best For:** Mobile apps, touchscreen UIs, productivity tools, user-friendly, consumer apps, interactive components
- **Performance:** ⚡ Excellent | **Accessibility:** ✓ Good

### Colors
| Role | Hex |
|------|-----|
| Primary | #0D9488 |
| Secondary | #14B8A6 |
| CTA | #F97316 |
| Background | #F0FDFA |
| Text | #134E4A |

*Notes: Teal focus + action orange*

### Typography
- **Heading:** Lora
- **Body:** Raleway
- **Mood:** calm, wellness, health, relaxing, natural, organic
- **Best For:** Health apps, wellness, spa, meditation, yoga, organic brands
- **Google Fonts:** https://fonts.google.com/share?selection.family=Lora:wght@400;500;600;700|Raleway:wght@300;400;500;600;700
- **CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600;700&family=Raleway:wght@300;400;500;600;700&display=swap');
```

### Key Effects
Small hover (50-100ms), loading spinners, success/error state anim, gesture-triggered (swipe/pinch), haptic

### Avoid (Anti-patterns)
- Complex onboarding
- Slow performance

### Pre-Delivery Checklist
- [ ] No emojis as icons (use SVG: Heroicons/Lucide)
- [ ] cursor-pointer on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard nav
- [ ] prefers-reduced-motion respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px

