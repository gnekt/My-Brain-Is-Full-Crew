# Food Coach

> Your personal nutrition coach -- science-based, compassionate, and always in your corner.

> **DISCLAIMER: This agent is NOT a medical professional.** The Food Coach is an AI agent -- it generates suggestions based on language model output, not clinical expertise. Its meal plans, calorie calculations, and dietary guidance may be inaccurate, incomplete, or inappropriate for your specific health situation. **Always consult a real doctor or registered dietitian before making changes to your diet**, especially if you have medical conditions, allergies, eating disorders, or are pregnant/nursing. The author of this project takes absolutely no responsibility for any decisions you make based on the output of this agent. Use your own judgment. This is a personal wellness companion, not a healthcare provider.

---

## What it does

The Food Coach is your dedicated dietary coach and wellness motivator. It reads your personal health profile from the vault (weight, height, goals, restrictions, food preferences) and uses that data to give you genuinely personalized guidance -- not generic advice from a magazine.

It helps you plan meals, build grocery lists, track your weight, navigate restaurants, prep food for the week, and figure out what to cook with what you have. But it does more than logistics. It understands that food is emotional, that setbacks are normal, and that sustainable change beats a perfect plan you abandon after three days. When you slip up, it does not guilt-trip you. It validates, offers a concrete plan for the next meal, and helps you understand what triggered it.

All calculations (calories, macros, targets) are dynamic -- recalculated from your actual profile data every time. Nothing is hardcoded. When you update your weight, your targets adjust automatically. The Food Coach brings clinical dietitian expertise with the warmth of a trusted friend.

## Capabilities

- **Meal planning** -- creates weekly menus tailored to your caloric targets, dietary framework (Mediterranean, keto, plant-based, etc.), and food preferences
- **Grocery lists** -- generates organized, goal-aligned shopping lists with quantities and intended use
- **Weight tracking** -- logs weight updates, recalculates all metrics (BMI, BMR, TDEE, targets), tracks trends, celebrates milestones
- **Meal logging** -- estimates calories and macros when you report what you ate, offers balancing suggestions
- **Progress reports** -- weekly or monthly analysis of weight trends, caloric adherence, nutritional quality, and wins
- **Quick check-in** -- rapid wellness temperature check (energy, mood, hydration, challenges ahead)
- **Restaurant mode** -- smart ordering strategies for any cuisine type, with portion and social tips
- **Social event mode** -- pre-event, during-event, and post-event strategies for parties, holidays, and dinners out
- **Meal prep Sunday** -- batch cooking plans with prep checklists, container strategy, and storage timelines
- **Pantry audit** -- suggests 3-5 meals from whatever ingredients you have on hand
- **Seasonal eating** -- what is in season locally and how to use it
- **Emotional eating support** -- compassionate detection and response when eating is connected to emotions, with Wellness Guide coordination
- **Motivational support** -- celebrates wins, normalizes setbacks, and always offers a concrete next step

## How to use it

Talk to the Food Coach like you would a coach:

- "Plan my meals for the week"
- "I just weighed 105kg" / "Weight update: 82.5kg"
- "What should I eat? I have chicken and rice"
- "Generate a grocery list"
- "I had pizza for lunch -- how bad is it?"
- "I'm going to a Japanese restaurant tonight"
- "Help me prep for the week"
- "I ate because I was stressed"
- "Check in" / "How am I doing?"
- "What's in season right now?"
- "Motivate me"

In Italian: "Cosa posso mangiare", "Ho pesato 105kg", "Lista della spesa", "Ho sgarrato"
In French: "Qu'est-ce que je peux manger", "Liste de courses", "J'ai craque"
In Spanish: "Que puedo comer", "Lista de compras", "Menu semanal"
In German: "Was kann ich essen", "Einkaufsliste", "Wochenmenu"

## Example conversations

### Weekly meal plan

**You:** Plan my meals for the week

**Food Coach:** Based on your profile -- target of 1,800 kcal/day, Mediterranean framework, no dairy (lactose intolerant) -- here is your plan for the week:

**Monday:**
- Breakfast: Overnight oats with almond milk, berries, and walnuts (~360 kcal)
- Lunch: Grilled chicken salad with quinoa, roasted peppers, and olive oil dressing (~630 kcal)
- Dinner: Baked salmon with sweet potato and steamed broccoli (~540 kcal)
- Snack: Apple with almond butter (~270 kcal)
- Daily total: ~1,800 kcal

[...continues for each day...]

I avoided all dairy and included your favorites (salmon, sweet potatoes). I also added meal prep notes -- you can batch cook the chicken and quinoa on Sunday.

Want me to generate the grocery list for this plan?

---

### Weight update with milestone

**You:** I weighed 98.5kg this morning

**Food Coach:** Updated your profile. Let me run the numbers:

- Previous weight: 100.2kg (March 7)
- Change: -1.7kg in 2 weeks
- Total progress: -6.5kg since you started (January 15)
- Current BMI: 29.8 (was 31.7 at start)
- Updated TDEE: 2,340 kcal/day
- New target: 1,840 kcal/day (adjusted down slightly)

And here is the big news: you just crossed under 100kg! That is a real milestone. You have been consistently losing 0.7-0.9kg per week, which is exactly the healthy, sustainable pace we want.

The trend line is clear -- what you are doing is working. Keep going.

Progress saved to `02-Areas/Health/Nutrition/progress/2026-03 -- Diet Progress.md`.

---

### Emotional eating moment

**You:** I just ate an entire pack of cookies. I feel terrible about it.

**Food Coach:** First -- thank you for telling me. That takes honesty, and it matters.

A pack of cookies is roughly 1,200-1,500 kcal depending on the brand. That puts you over today's target, but one day does not erase the weeks of progress you have built. Your body does not work on a 24-hour ledger.

Here is the plan for the rest of today:
- For dinner, go light but satisfying: grilled chicken breast with a big salad and olive oil. Around 400 kcal.
- Drink plenty of water this evening.
- Tomorrow, return to your normal plan. No skipping meals to "make up for it" -- that leads to more overeating, not less.

Now, the important question: what was happening before you reached for the cookies? Were you stressed, bored, anxious, or tired? Understanding the trigger is more valuable than worrying about the calories.

This might also be something worth exploring with your therapist -- the connection between what you feel and what you eat is important, and they can help with that side of things.

## Works with

- **Architect** -- if the Health/Nutrition area does not exist, the Architect creates it during onboarding
- **Scribe** -- when you share unstructured food-related information, the Scribe captures it as a clean note for the Food Coach to process
- **Wellness Guide** -- when the Food Coach detects signs of emotional eating, excessive guilt, or disordered eating patterns, it coordinates with the Wellness Guide
- **Connector** -- progress notes, meal plans, and grocery lists are flagged for cross-linking
- **Postman** -- medical appointment emails, lab results, and dietary delivery services are flagged for the Food Coach

## Tips

- **Complete your health profile first.** The Food Coach cannot give personalized advice without your weight, height, goals, and preferences. The Architect collects this during onboarding, or the Food Coach will guide you through setup on first use.
- **Log your weight regularly.** Even once a week is enough. The Food Coach recalculates everything when you update, keeping your targets accurate.
- **Be honest about slip-ups.** The Food Coach never judges. Reporting what you actually ate (versus what you planned) is how you learn what triggers off-plan eating.
- **Use restaurant mode before eating out.** A 30-second conversation before you leave gives you a strategy that makes the meal more enjoyable, not less.
- **Try the pantry audit when you are stuck.** Instead of ordering delivery, tell the Food Coach what you have and get meal ideas in seconds.
- **Update your food preferences.** Tried something new and loved it? Discovered you cannot stand a food? Tell the Food Coach so future plans improve.
- **Remember: sustainable beats perfect.** The Food Coach designs plans you can actually follow 70% of the time. That is infinitely better than a perfect plan abandoned after 3 days.
