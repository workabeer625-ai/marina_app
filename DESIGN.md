# MARINA Design System — "Riviera" 🌊✨

نظام التصميم الجديد لمتجر مارينا — هوية فاخرة موحّدة بوضعين: نهاري وليلي، مع الحفاظ على
جميع العمليات والمنطق كما هو (نفس الشاشات، نفس المسارات، نفس الـAPI).

The new design language for the MARINA store — one luxurious identity across
day & night themes. **All business logic, routes and API operations are untouched.**

---

## 🎨 اللوحة / Palette

| Token | Light (نهاري) | Dark (ليلي) | الاستخدام |
|---|---|---|---|
| `background` | عاجي دافئ `#F7F5F0` | كحلي منتصف الليل `#0C1017` | خلفية الشاشات |
| `surface` | أبيض `#FFFFFF` | `#151B28` | البطاقات والشِبِك |
| `surfaceSoft` | رملي `#F1ECE1` | `#1B2231` | حاويات ثانوية |
| `ink` | `#171B22` | `#F3F5F9` | النصوص |
| `muted` | `#6E727B` | `#98A1B0` | النصوص الثانوية |
| `line` | `#E7E2D6` | `#283042` | الحدود والفواصل |
| `gold` | ذهبي شمبانيا `#97783B` | `#E2C283` | التمييز الفاخر |
| `navy` | كحلي عميق `#101B2D` | — | الهيدرز والـHero |

## ✍️ الخطوط / Typography

- **Tajawal** (400/500/700/800) — خط الواجهة للعربية واللاتينية.
- **Marcellus** — سيريف فاخر للعناوين اللاتينية والأسعار (`MarinaType.display`).
- تباعد الحروف يُصفَّر تلقائياً في العربية (`letterSpacing: 0`) حتى لا تتفكك الحروف.

## 🧭 شريط التنقل / Navigation Dock

`lib/shared/widgets/customer_shell.dart`
- شريط عائم زجاجي (Backdrop blur) بإطار ذهبي متدرج.
- زر سلة مركزي بارز بتدرج ذهبي + **عدّاد حي لمحتويات السلة** (للمستخدم المسجّل فقط).
- تبويبات: الرئيسية · تسوّق · [السلة] · المفضلة · الحساب.
- تبديل الوضع الليلي/النهاري موجود في هيدر الرئيسية وفي: **الحساب ← المظهر**.

## 🧩 المكوّنات المشتركة / Shared widgets (`lib/shared/widgets/common.dart`)

`MarinaPage` · `MarinaIconButton` · `MarinaGoldButton` (CTA ذهبي متدرج) ·
`ProductCard` (شارة خصم ذهبية + سعر سيريف) · `StatusChip` (حالة الطلب/المرتجع بالألوان) ·
`MarinaSectionCard` · `SettingsTile` · `EmptyState` · `LoadingState` · `ErrorState` ·
`MarinaPrice` · `GoldDivider`.

## 🌓 كيف أبدّل الثيم؟ / Theme switching

- زر الشمس/القمر في هيدر الرئيسية (تبديل سريع).
- **الحساب ← المظهر** أو **اللغة ← المظهر**: نظام / نهاري / ليلي.
- الاختيار محفوظ على الجهاز (`marina_theme_mode`) مثل حفظ اللغة.

## 🧪 ملاحظات هندسية

- كل الألوان تُقرأ من `MarinaPalette.of(context)` — لا ألوان ثابتة داخل الشاشات.
- ثيم MaterialApp كامل (أزرار، حقول، حوافر، Dialogs، SnackBar، Switch/Radio…) لكل وضع.
- أُضيف مسار `/appearance` فقط؛ لم يُمَس أي منطق طلبات أو حالة (Riverpod) أو مسار قائم.
