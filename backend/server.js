const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_TIMEOUT_MS = 55_000; // fail fast; app times out at 25s so backend should respond before that when possible

app.use(cors());
app.use(express.json({ limit: '4mb' })); // allow base64 images

// System prompt is fully defined here. App only sends userContext (goals, challenges); no user configuration.
const BASE_INSTRUCTIONS = `CRITICAL - Food logging: When the user asks to "log" a meal, "help me log", or shares a meal photo/description, you MUST end your reply with a [FOOD_LOG] JSON block. The app uses this to show buttons so they can add items with one tap. You are NOT "logging" for them—you are providing the list; the app does the rest. FORBIDDEN: Do not say "I can't log", "I can't directly log", "I can't log the meal for you", "write it down", "enter it into your app", or "just add this to your log". Those are wrong. The correct response is: one short sentence like "Tap each item below to add it to your Food log." then the [FOOD_LOG] block with every ingredient (name, calories, protein, quantity). No text after the block.

[FOOD_LOG]
{"items":[{"name":"Kale","calories":60,"protein":2,"quantity":"2 cups"},{"name":"Wild rice","calories":100,"protein":4,"quantity":"1/2 cup"},{"name":"Goat cheese","calories":100,"protein":6,"quantity":"1/4 cup"}]}
[/FOOD_LOG]

You are a supportive, non-judgmental fat loss coach. Be warm, brief, and practical. You have access to their goal weight, weekly calorie target, and things they find challenging. Reference their data when relevant. If they ask you to remember something as a challenge, acknowledge it. Do not give medical advice. Keep responses concise (a few short paragraphs max) unless they ask for more. Ground your advice in the coaching framework below. When the user shares a photo of their plate or meal, estimate the calories and give brief, supportive feedback (e.g. balance, volume-eating tips, how it fits their budget).`;

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

// When the main reply mentions logging but has no [FOOD_LOG] block, ask the model for the block and return it (or null).
async function fetchFoodLogBlock(lastUserMessage, assistantReply, apiKey) {
  const sys = `You output ONLY a [FOOD_LOG] block. No other text. Extract the meal/foods from the conversation and output valid JSON in this exact format:
[FOOD_LOG]
{"items":[{"name":"Food name","calories":N,"protein":N,"quantity":"e.g. 1 cup"}]}
[/FOOD_LOG]
Every item must have name, calories, protein (number), and quantity (string). If you cannot infer specific foods, output a single generic item. No text before or after the block.`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15_000);

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: sys },
          { role: 'user', content: `User said: ${lastUserMessage}` },
          { role: 'assistant', content: assistantReply },
          { role: 'user', content: 'Output only the [FOOD_LOG] block for the meal discussed above.' },
        ],
        max_tokens: 400,
      }),
    });
    clearTimeout(timeoutId);
    const data = await response.json();
    const text = data.choices?.[0]?.message?.content?.trim();
    if (!text || !response.ok) return null;
    // Extract block: [FOOD_LOG]...[/FOOD_LOG] or raw JSON line
    const tagged = text.match(/\[FOOD_LOG\]\s*([\s\S]*?)\s*\[\/FOOD_LOG\]/i);
    const raw = tagged ? tagged[1].trim() : text.trim();
    const jsonMatch = raw.match(/\{[\s\S]*"items"[\s\S]*\}/);
    if (!jsonMatch) return null;
    const parsed = JSON.parse(jsonMatch[0]);
    if (!parsed.items || !Array.isArray(parsed.items)) return null;
    return `[FOOD_LOG]\n${JSON.stringify(parsed)}\n[/FOOD_LOG]`;
  } catch (e) {
    clearTimeout(timeoutId);
    return null;
  }
}

// Fallback: parse the assistant reply for meal lines (e.g. "**Chicken (4 oz)**: 200-250 calories") and build [FOOD_LOG] block.
function parseReplyForMealItems(reply) {
  const items = [];
  // Match lines like "- **Food name (portion)**: 200-250 calories" or "**Food**: 150 calories"
  const lineRe = /[-*]?\s*\*\*([^*]+)\*\*\s*:\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*calories?/gi;
  let m;
  while ((m = lineRe.exec(reply)) !== null) {
    const fullName = m[1].trim();
    const lo = parseInt(m[2], 10);
    const hi = m[3] ? parseInt(m[3], 10) : lo;
    const calories = Math.round((lo + hi) / 2);
    const quantityMatch = fullName.match(/^(.+?)\s*\(([^)]+)\)\s*$/);
    const name = quantityMatch ? quantityMatch[1].trim() : fullName;
    const quantity = quantityMatch ? quantityMatch[2].trim() : '';
    items.push({ name, calories, protein: 0, quantity: quantity || undefined });
  }
  if (items.length === 0) return null;
  return `[FOOD_LOG]\n${JSON.stringify({ items })}\n[/FOOD_LOG]`;
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

    let reply = data.choices?.[0]?.message?.content?.trim();
    if (!reply) {
      console.error('OpenAI returned no reply:', JSON.stringify(data).slice(0, 200));
      return sendError('Something went wrong. Please try again later.');
    }

    // If the reply talks about logging or looks like a meal breakdown (ingredients + calories), auto-trigger [FOOD_LOG] and append block
    const lastUserContent = messages.length > 0 && messages[messages.length - 1]?.role === 'user'
      ? String(messages[messages.length - 1].content || '')
      : '';
    const replyMentionsLogging = /\b(log|logging|food log|add to your (log|app)|enter it|write it down|track(ing)?|manually)\b/i.test(reply);
    const userAskedToLog = /\b(log|help me log|can you log|let's log)\b/i.test(lastUserContent);
    const replyLooksLikeMealBreakdown = /\d+\s*calories?/.test(reply) && (/\([^)]+\)\s*:\s*\d+/i.test(reply) || /\*\*[^*]+\*\*\s*:\s*\d+/i.test(reply));
    const alreadyHasBlock = /\[FOOD_LOG\]/.test(reply);

    if ((replyMentionsLogging || userAskedToLog || replyLooksLikeMealBreakdown) && !alreadyHasBlock) {
      try {
        let block = await fetchFoodLogBlock(lastUserContent, reply, OPENAI_API_KEY);
        if (!block) block = parseReplyForMealItems(reply);
        if (block) {
          reply = reply.replace(/\s*(I can't (directly )?log[^.!?]*[.!?]|Just (add|enter|write)[^.!?]*[.!?]|To log your meal[^.!?]*[.!?]|you can (start|mark)[^.!?]*[.!?])\s*/gi, ' ');
          reply = reply.replace(/\s*(If you're using a food diary[^.!?]*[.!?]|Make sure to note[^.!?]*[.!?])\s*/gi, ' ');
          reply = reply.trim();
          if (!reply.endsWith('.')) reply += '.';
          reply += '\n\nTap each item below to add it to your Food log.\n\n' + block;
        }
      } catch (_) {
        // Leave reply unchanged if follow-up block fetch fails
      }
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
