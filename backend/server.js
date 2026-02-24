const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_TIMEOUT_MS = 55_000; // fail fast; app times out at 25s so backend should respond before that when possible

app.use(cors());
app.use(express.json({ limit: '4mb' })); // allow base64 images

// System prompt is fully defined here. App only sends userContext (goals, challenges); no user configuration.
const BASE_INSTRUCTIONS = `You are a supportive, non-judgmental fat loss coach. Be warm, brief, and practical. You have access to their goal weight, weekly calorie target, and things they find challenging. Reference their data when relevant. If they ask you to remember something as a challenge, acknowledge it. Do not give medical advice. Keep responses concise (a few short paragraphs max) unless they ask for more. Ground your advice in the coaching framework below. When the user shares a photo of their plate or meal, estimate the calories and give brief, supportive feedback (e.g. balance, volume-eating tips, how it fits their budget).`;

const COACH_FRAMEWORK = `
COACHING FRAMEWORK — Use these concepts when supporting the user:

**Your WHY:** Weight loss isn't one-size-fits-all. The first step is understanding WHY they want to lose weight—e.g. setting an example for kids, feeling confident with a partner, less stress about clothes. Encourage them to name and use their why as a daily reminder, especially when it's hard.

**Future self:** Their future self is them. Encourage envisioning the lighter (physically and mentally) version: how she feels around food (confident, at ease, calm, energized), how she looks in the mirror, how she feels getting out of bed. A day in the life of their ideal self (wake, exercise, meals, wind-down) helps clarify what to be consistent with and what to let go.

**Food budget:** They have a weekly calorie budget. Like a spending budget: if they overspend one day, they can balance it by staying under other days. The goal is to be consistently under budget for the week. All foods and drinks count as energy (calories).

**Volume eating:** Eat more for less—not to "trick" the body but to feel nourished and full while staying in budget. Protein and fiber are key. You should hit your body weight in grams of protein every day because protein is what keeps you full. Examples: It's better to have a double serving of greek yogurt than a single serving of greek yogurt + granola; double the protein in salads; veggies to munch while cooking. Snack once a day or not at all; make snacks meaningful (real hunger or a small intentional dessert).

**Dining out:** Check the menu online and decide before arriving. Order salad first (dressing on the side—two tbsp can add 150–200 cal) or broth-based soup. Look for lower-calorie words: steamed, baked, roasted, grilled, broiled, seared. Avoid higher-calorie words: creamy, buttery, breaded, fried, battered, glazed, alfredo. Request butter/sauces on the side; use the fork-dip method for dressings. Ask for a to-go box and put half away immediately. Say no to bread basket/chips or take one portion. Drink water; don't arrive starving; plan a short walk after. Pop a mint when done. Give yourself a quick pep talk. For restricted diets: plan ahead, ask for off-menu options, pile on sides, choose variety (grains, plant protein, veggies).

**Hunger vs. cravings:** Physical hunger = biologically driven, emptiness, low energy, irritability; it's normal to feel a bit hungry in a deficit. Manage it with regular meals, protein and fiber, starting with salad or soup. Cravings = intense urge for a specific food, often triggered by sight/smell, stress, boredom, social media, places. Address the trigger: rest if tired, activity or support if bored, redirect thoughts, drink water (64+ oz daily), go for a walk. Learn to address the trigger, not the craving.`;

function buildSystemPrompt(userContext) {
  const parts = [BASE_INSTRUCTIONS, COACH_FRAMEWORK];
  if (userContext && (userContext.goalWeightLbs > 0 || userContext.weeklyCalorieTarget > 0)) {
    parts.push(`User's goal weight: ${userContext.goalWeightLbs || 0} lbs. Weekly calorie target: ${Math.round(userContext.weeklyCalorieTarget || 0)} cal (this is their weekly food budget).`);
  }
  if (userContext && userContext.userChallenges && userContext.userChallenges.length > 0) {
    parts.push(`Things the user finds challenging: ${userContext.userChallenges.join('; ')}.`);
  }
  return parts.join('\n\n');
}

// POST /chat - proxy to OpenAI; optional image for plate/calorie analysis (vision). Prompt is built on server.
app.post('/chat', async (req, res) => {
  const sendError = (msg) => res.status(200).json({ reply: null, error: msg });

  try {
    if (!OPENAI_API_KEY) {
      console.error('OPENAI_API_KEY is not set in Railway Variables. Add it in your service → Variables.');
      return sendError('Something went wrong. Please try again later.');
    }

    const body = req.body || {};
    const { messages, imageBase64, userContext } = body;
    if (!Array.isArray(messages)) {
      console.error('Invalid request: body keys', Object.keys(body), 'messages type', typeof messages);
      return sendError('Backend received an invalid request. Check that the app is using the latest version.');
    }

    const systemPrompt = buildSystemPrompt(userContext || {});

    const openaiMessages = [
      { role: 'system', content: systemPrompt },
      ...messages.map((m, i) => {
        const isLastUser = m && m.role === 'user' && i === messages.length - 1;
        const content = (m && m.content != null) ? String(m.content) : '';
        if (isLastUser && imageBase64 && typeof imageBase64 === 'string') {
          const prefix = imageBase64.startsWith('data:') ? '' : 'data:image/jpeg;base64,';
          return {
            role: 'user',
            content: [
              { type: 'text', text: content || 'Here\'s my plate - can you estimate the calories and give me feedback?' },
              { type: 'image_url', image_url: { url: prefix + imageBase64 } },
            ],
          };
        }
        return { role: (m && m.role) || 'user', content };
      }),
    ];

    const controller = new AbortController();
    let timeoutId = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: openaiMessages,
        max_tokens: 600,
      }),
    });

    clearTimeout(timeoutId);

    const data = await response.json();

    if (!response.ok) {
      const openaiMsg = data.error?.message || data.error?.code || `HTTP ${response.status}`;
      console.error('OpenAI API error:', response.status, openaiMsg);
      return sendError(openaiMsg || 'Something went wrong. Please try again later.');
    }

    const reply = data.choices?.[0]?.message?.content?.trim();
    if (!reply) {
      console.error('OpenAI returned no reply:', JSON.stringify(data).slice(0, 200));
      return sendError('Something went wrong. Please try again later.');
    }

    res.json({ reply });
  } catch (e) {
    if (e.name === 'AbortError') {
      return sendError('This is taking longer than usual. Please try again.');
    }
    console.error('Chat endpoint error:', e);
    return sendError('Something went wrong. Please try again later.');
  }
});

// Health check for hosting platforms
app.get('/health', (_, res) => res.json({ ok: true }));

// Debug: verify backend sees the API key (do not expose the key). Open in browser: https://your-app.up.railway.app/debug
app.get('/debug', (_, res) => res.json({ ok: true, hasApiKey: !!OPENAI_API_KEY }));

app.listen(PORT, () => {
  console.log(`FLF chat backend listening on port ${PORT}`);
  if (!OPENAI_API_KEY) console.warn('WARNING: OPENAI_API_KEY not set. Set it before using /chat.');
});
