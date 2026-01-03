-- ============================================
-- ORIENTATION PART 1 - COMPLETE QUESTIONS
-- ============================================
-- This script contains all 64 questions for Orientation Part 1
-- Based on the detailed ENEPL orientation guide
-- 16 Topics × 4 Difficulty Levels (Easy, Mid, Hard, Extreme/Bonus)

-- ============================================
-- 1. CREATE ORIENTATION PATHWAY (if not exists)
-- ============================================

INSERT INTO pathways (id, name, description) 
VALUES (
    '20000000-0000-0000-0000-000000000001',
    'Orientation',
    'Essential company knowledge, values, and operational procedures for all ENEPL team members'
)
ON CONFLICT (name) DO UPDATE 
SET description = EXCLUDED.description;

-- ============================================
-- 2. CREATE ORIENTATION PART 1 LEVEL
-- ============================================

INSERT INTO pathway_levels (id, pathway_id, level_number, level_name, required_score, description) 
VALUES (
    '21000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    1,
    'Orientation Part 1',
    0,
    'Learn about ENEPL vision, values, goals, brand guidelines, and operational procedures'
)
ON CONFLICT (pathway_id, level_number) DO UPDATE 
SET 
    level_name = EXCLUDED.level_name,
    required_score = EXCLUDED.required_score,
    description = EXCLUDED.description;

-- ============================================
-- 3. INSERT ORIENTATION QUESTIONS
-- ============================================

-- Topic 1: VISION (Ease & Delight)

-- Q1 (Easy): Single Tap Choice
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which action best creates Ease for a client?',
    'multiple_choice',
    '["Reply late but fix internally", "Share clear update with next steps", "Wait for senior approval silently", "Close task without informing"]',
    1,
    'Share clear update with next steps'
);

-- Q2 (Mid): Card Match
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match each action to Ease or Delight',
    'match_following',
    '[
        {"left": "Quick response with clear timeline", "right": "Ease"},
        {"left": "Surprise upgrade within budget", "right": "Delight"},
        {"left": "Proactive status updates", "right": "Ease"},
        {"left": "Personalized thank you note", "right": "Delight"}
    ]',
    'See match_pairs'
);

-- Q3 (Hard): Scenario Decision
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the option that delivers Delight without breaking process',
    'multiple_choice',
    '["Skip documentation to save time", "Add expensive extras without approval", "Include a thoughtful touch within approved budget", "Promise features not in scope"]',
    2,
    'Include a thoughtful touch within approved budget'
);

-- Q4 (Extreme): Budget Simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Design a solution that creates Ease, Delight & Cost Effectiveness together. Which approach is best?',
    'multiple_choice',
    '["Luxury everything regardless of budget", "Cheapest options only", "Strategic WOW moments + efficient processes + clear communication", "Standard delivery with no extras"]',
    2,
    'Strategic WOW moments + efficient processes + clear communication'
);

-- Topic 2: VALUES

-- Q5 (Easy): Single Tap Choice
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the most value-aligned action',
    'multiple_choice',
    '["Reply late but fix internally", "Share clear update with next steps", "Wait for senior approval silently", "Close task without informing"]',
    1,
    'Share clear update with next steps'
);

-- Q6 (Mid): Card Match
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match action to ENEPL value: Sending MOM (Minutes of Meeting) after call',
    'multiple_choice',
    '["Professionalism", "Partner Focus", "Lean & Responsive", "None"]',
    0,
    'Professionalism'
);

-- Q7 (Hard): Scenario Decision
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Client wants a last-minute change impacting budget. What do you do?',
    'multiple_choice',
    '["Say yes to please client", "Escalate after committing", "Explain impact + revise scope & budget", "Ignore till later"]',
    2,
    'Explain impact + revise scope & budget'
);

-- Q8 (Extreme): Decision Simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Handle conflict under pressure while protecting values',
    'multiple_choice',
    '["Cut process to save time", "Blame another team", "Take quick decision without informing client", "Align stakeholders, document change, act fast"]',
    3,
    'Align stakeholders, document change, act fast'
);

-- Topic 3: GOALS

-- Q9 (Easy): Single Tap Choice
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Pick the action that supports our goals',
    'multiple_choice',
    '["Focus only on cost cutting", "Deliver WOW moment within budget", "Finish fast without documentation", "Do extra work without alignment"]',
    1,
    'Deliver WOW moment within budget'
);

-- Q10 (Mid): Stack the Cards
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Sort action into the right goal bucket: "Accurate budget forecast"',
    'multiple_choice',
    '["Brand Building", "Quality", "Efficiency", "People"]',
    2,
    'Efficiency'
);

-- Q11 (Hard): Nuts & Bolts Puzzle
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You have limited budget. What delivers growth + quality together?',
    'multiple_choice',
    '["Expensive decor everywhere", "One strong WOW + controlled spends", "Cheapest vendors only", "Add scope without approval"]',
    1,
    'One strong WOW + controlled spends'
);

-- Q12 (Extreme): Budget Simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Build a mini event plan that hits minimum 3 goals. Which option includes 3 correct choices?',
    'multiple_choice',
    '["Team overload + Random ideas + Quick fixes", "Accurate forecast + Recognizable WOW offering + High-margin decision", "Cheap vendors + No documentation + Rush delivery", "Expensive everything + No planning + Last minute"]',
    1,
    'Accurate forecast + Recognizable WOW offering + High-margin decision'
);

-- Topic 4: BRAND GUIDELINES

-- Q13 (Easy): Single Tap Choice
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the correct primary brand color',
    'multiple_choice',
    '["Neon Green", "Wine Red", "Electric Blue", "Orange"]',
    1,
    'Wine Red'
);

-- Q14 (Mid): Divide Cards
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Sort the color into Primary vs Secondary: Gold (#F4D394)',
    'multiple_choice',
    '["Primary", "Secondary", "Accent", "Not Allowed"]',
    0,
    'Primary'
);

-- Q15 (Hard): Stack the Cards
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Pick the correct font combination for an invite',
    'multiple_choice',
    '["Comic Sans + Italics", "Raleway Bold + Montserrat Regular", "Times New Roman + Serif", "Random mix"]',
    1,
    'Raleway Bold + Montserrat Regular'
);

-- Q16 (Extreme): Visual Builder
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Build a brand-safe visual. Select the correct combination:',
    'multiple_choice',
    '["Neon colors + Random fonts + Bright background", "Charcoal background + Raleway Bold heading + Cream base tone", "Comic Sans + Electric Blue + Orange", "Times New Roman + Neon Green + Pink"]',
    1,
    'Charcoal background + Raleway Bold heading + Cream base tone'
);

-- Topic 5: ABOUT ENEPL

-- Q17 (Easy): Multi-Select (represented as MCQ for simplicity)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which are service verticals offered by Entre Nous?',
    'multiple_choice',
    '["Retail Operations", "Brand Building + Virtual Events + Nurturing Talent", "Only Event Management", "Software Development"]',
    1,
    'Brand Building + Virtual Events + Nurturing Talent'
);

-- Q18 (Mid): Card Flip
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match clients Entre Nous has worked with',
    'match_following',
    '[
        {"left": "YPO", "right": "Client"},
        {"left": "EO", "right": "Client"},
        {"left": "Google", "right": "Not Client"},
        {"left": "Tata Group", "right": "Not Client"}
    ]',
    'See match_pairs'
);

-- Q19 (Hard): Stack Cards
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Identify IP events created by Entre Nous',
    'multiple_choice',
    '["IPL + FIFA World Cup", "PLLA + Style Icon + Kala Ki Khoj", "Olympics + Commonwealth Games", "None of the above"]',
    1,
    'PLLA + Style Icon + Kala Ki Khoj'
);

-- Q20 (Extreme): Path Finder
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Where would you find client & IP event information?',
    'multiple_choice',
    '["Personal WhatsApp only", "Company Website + Instagram & Facebook", "Old Event Pics Folder", "Random Google Search"]',
    1,
    'Company Website + Instagram & Facebook'
);

-- Topic 6: JOB SHEET

-- Q21 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'What best defines a Job Sheet?',
    'multiple_choice',
    '["Personal to-do list only", "Consolidation of all jobs you are accountable for", "PM''s responsibility only", "Event checklist only"]',
    1,
    'Consolidation of all jobs you are accountable for'
);

-- Q22 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Who is responsible for creating & updating the Job Sheet?',
    'multiple_choice',
    '["Project Manager", "Team Lead", "You", "Admin"]',
    2,
    'You'
);

-- Q23 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Identify valid sources for Job Sheet entries',
    'multiple_choice',
    '["Personal reminders only", "WhatsApp messages + Emails from vendors/clients + MOMs", "Social media posts", "Random thoughts"]',
    1,
    'WhatsApp messages + Emails from vendors/clients + MOMs'
);

-- Q24 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Tasks pile up near event date. What is the right action?',
    'multiple_choice',
    '["Rush tasks closer to event", "Inform PM last minute", "Update Job Sheet immediately and flag bottlenecks early", "Wait for review meeting"]',
    2,
    'Update Job Sheet immediately and flag bottlenecks early'
);

-- Topic 7: WATERMELON STORY

-- Q25 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'What is the core message of the Watermelon Story?',
    'multiple_choice',
    '["Do tasks fast", "Do only what''s asked", "Own the outcome, not just the task", "Wait for instructions"]',
    2,
    'Own the outcome, not just the task'
);

-- Q26 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You''re asked to check vendor availability. Best response?',
    'multiple_choice',
    '["Yes, vendor available", "Share price only", "Share price + capacity + timelines + risks + next steps", "Ask senior what to do next"]',
    2,
    'Share price + capacity + timelines + risks + next steps'
);

-- Q27 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which action best shows "elder brother thinking"?',
    'multiple_choice',
    '["Finish task & log off", "Ask clarifying questions", "Anticipate follow-ups & include insights proactively", "Wait for feedback"]',
    2,
    'Anticipate follow-ups & include insights proactively'
);

-- Q28 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Client asks a basic question close to event day. What do you do?',
    'multiple_choice',
    '["Answer only what''s asked", "Forward the query", "Answer + flag risks + suggest improvements + backup plan", "Say will revert later"]',
    2,
    'Answer + flag risks + suggest improvements + backup plan'
);

-- Topic 8: PRIORITIZATION

-- Q29 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Vendor hasn''t arrived on event day. Which quadrant?',
    'multiple_choice',
    '["Quadrant 1 – Urgent & Important", "Quadrant 2 – Important, Not Urgent", "Quadrant 3 – Urgent, Not Important", "Quadrant 4 – Neither"]',
    0,
    'Quadrant 1 – Urgent & Important'
);

-- Q30 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Improve SOP documentation for future events. Which quadrant?',
    'multiple_choice',
    '["Quadrant 1 – Urgent & Important", "Quadrant 2 – Important, Not Urgent", "Quadrant 3 – Urgent, Not Important", "Quadrant 4 – Neither"]',
    1,
    'Quadrant 2 – Important, Not Urgent'
);

-- Q31 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which task should be moved out first?',
    'multiple_choice',
    '["Random WhatsApp forwards", "Final stage setup check", "Client call in 10 mins", "Fire safety approval"]',
    0,
    'Random WhatsApp forwards'
);

-- Q32 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Select 2 tasks to do NOW (most urgent)',
    'multiple_choice',
    '["Personal social media scroll + Unrelated internal chatter", "Guest arrival issue + Event debrief planning", "Random browsing + Coffee break", "Future planning + Casual chat"]',
    1,
    'Guest arrival issue + Event debrief planning'
);

-- Topic 9: GREETINGS

-- Q33 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Pick the correct greeting behaviour',
    'multiple_choice',
    '["Ignore colleagues", "Greet colleagues with a smile", "Only greet seniors", "Greet only when spoken to"]',
    1,
    'Greet colleagues with a smile'
);

-- Q34 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Morning / Goodnight message maps to:',
    'multiple_choice',
    '["Optional courtesy", "Logging in / off", "Only for seniors", "Not required"]',
    1,
    'Logging in / off'
);

-- Q35 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Guest arrives at office. First action?',
    'multiple_choice',
    '["Continue working", "Offer water & seating", "Ask them to wait", "Call senior immediately"]',
    1,
    'Offer water & seating'
);

-- Q36 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Handle call + meeting scenario correctly',
    'multiple_choice',
    '["Take call during meeting", "Excuse yourself + take call + return + apologize", "Ignore call completely", "Put call on speaker"]',
    1,
    'Excuse yourself + take call + return + apologize'
);

-- Topic 10: DRESS CODE

-- Q37 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Correct grooming rule',
    'multiple_choice',
    '["Casual appearance is fine", "Well-groomed hair & nails required", "No grooming standards", "Only for client meetings"]',
    1,
    'Well-groomed hair & nails required'
);

-- Q38 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Right outfit for office',
    'multiple_choice',
    '["Gym wear", "Smart casuals", "Party wear", "Sleepwear"]',
    1,
    'Smart casuals'
);

-- Q39 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Event setup day dress',
    'multiple_choice',
    '["Formal suit", "ENEPL Chinos + White Tee", "Casual jeans", "Sports wear"]',
    1,
    'ENEPL Chinos + White Tee'
);

-- Q40 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Client event night attire',
    'multiple_choice',
    '["Casual t-shirt + jeans", "ENEPL Black Shirt + Chinos + Closed shoes", "Party dress", "Sports jacket"]',
    1,
    'ENEPL Black Shirt + Chinos + Closed shoes'
);

-- Topic 11: ATTENDANCE & LEAVES

-- Q41 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'How to mark attendance?',
    'multiple_choice',
    '["WhatsApp message", "Razorpay link", "Email", "Not required"]',
    1,
    'Razorpay link'
);

-- Q42 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Daily check-in/out',
    'multiple_choice',
    '["Optional", "Mandatory (impacts salary)", "Only for juniors", "Only for events"]',
    1,
    'Mandatory (impacts salary)'
);

-- Q43 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Reaching office at 11:15 AM without intimation',
    'multiple_choice',
    '["Full day", "Half day", "No impact", "Warning only"]',
    1,
    'Half day'
);

-- Q44 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Save full day conditions',
    'multiple_choice',
    '["No conditions", "Inform 1 hour prior + Max 3 times/month", "Inform anytime", "Unlimited late arrivals"]',
    1,
    'Inform 1 hour prior + Max 3 times/month'
);

-- Topic 12: OFFICE DECORUM

-- Q45 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Correct office behaviour',
    'multiple_choice',
    '["Leave files scattered", "File documents neatly before leaving", "Let others clean up", "No organization needed"]',
    1,
    'File documents neatly before leaving'
);

-- Q46 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Courier arrives for absent colleague',
    'multiple_choice',
    '["Refuse delivery", "Collect parcel & note details", "Leave at reception", "Ignore courier"]',
    1,
    'Collect parcel & note details'
);

-- Q47 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Confirm delivery correctly',
    'multiple_choice',
    '["Just inform verbally", "Send picture to colleague to reconfirm", "Don''t inform", "Wait for them to ask"]',
    1,
    'Send picture to colleague to reconfirm'
);

-- Q48 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Running late / unable to come',
    'multiple_choice',
    '["Just show up late", "Inform early + update TL", "Inform after reaching", "No need to inform"]',
    1,
    'Inform early + update TL'
);

-- Topic 13: WORKING STYLE

-- Q49 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Best working-style behaviour',
    'multiple_choice',
    '["Miss deadlines often", "Follow timelines you commit to", "Extend deadlines without informing", "No timeline needed"]',
    1,
    'Follow timelines you commit to'
);

-- Q50 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Why seek acknowledgement?',
    'multiple_choice',
    '["Not necessary", "To ensure sent = received", "Just formality", "Only for important messages"]',
    1,
    'To ensure sent = received'
);

-- Q51 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Client calls, you don''t have answer',
    'multiple_choice',
    '["Make up an answer", "Say you''ll revert and actually do so", "Transfer call", "Ignore question"]',
    1,
    'Say you''ll revert and actually do so'
);

-- Q52 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Live work situation best practice',
    'multiple_choice',
    '["Wait for instructions", "Own task end-to-end + acknowledge messages + bring solutions", "Do minimum required", "Blame others for delays"]',
    1,
    'Own task end-to-end + acknowledge messages + bring solutions'
);

-- Topic 14: VENDOR INTERACTION

-- Q53 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Meet new vendor with',
    'multiple_choice',
    '["Alone", "Team Lead", "Any colleague", "No one"]',
    1,
    'Team Lead'
);

-- Q54 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'WhatsApp confirmations',
    'multiple_choice',
    '["WhatsApp only is fine", "WhatsApp backed by email (CC TL)", "No confirmation needed", "Verbal is enough"]',
    1,
    'WhatsApp backed by email (CC TL)'
);

-- Q55 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Vendor not tech-savvy',
    'multiple_choice',
    '["Skip documentation", "Screenshot WhatsApp → Email TL", "Verbal agreement only", "No follow-up needed"]',
    1,
    'Screenshot WhatsApp → Email TL'
);

-- Q56 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Correct vendor interaction',
    'multiple_choice',
    '["Work independently without updates", "Align décor with ENEPL + keep TL looped in", "Make all decisions alone", "Skip brand guidelines"]',
    1,
    'Align décor with ENEPL + keep TL looped in'
);

-- Topic 15: COMMUNICATION & RESPONSE PROTOCOL
-- (Combined with Email Etiquette)

-- Topic 16: EMAIL ETIQUETTE

-- Q57 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Schedule meetings with externals',
    'multiple_choice',
    '["WhatsApp message only", "Calendar invite + Zoom link", "Verbal confirmation", "No formal invite needed"]',
    1,
    'Calendar invite + Zoom link'
);

-- Q58 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Correct email subject structure',
    'multiple_choice',
    '["Random text", "Event name + date + mail content", "Just ''Hi''", "No subject needed"]',
    1,
    'Event name + date + mail content'
);

-- Q59 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Files shared in which format',
    'multiple_choice',
    '["Word doc", "PDF only", "Any format", "Screenshots only"]',
    1,
    'PDF only'
);

-- Q60 (Extreme)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Crisis during event',
    'multiple_choice',
    '["Handle alone quietly", "Raise Red Alert immediately on group/email", "Wait for someone to notice", "Inform after event"]',
    1,
    'Raise Red Alert immediately on group/email'
);

-- Additional questions to reach 64 total (4 more needed)

-- Q61: Communication Protocol
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Best practice for client communication',
    'multiple_choice',
    '["Reply whenever convenient", "Acknowledge within 2 hours + provide timeline", "Wait for reminder", "Reply only if urgent"]',
    1,
    'Acknowledge within 2 hours + provide timeline'
);

-- Q62: Documentation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'After important client call, you should',
    'multiple_choice',
    '["Rely on memory", "Send MOM (Minutes of Meeting) within 24 hours", "Informal WhatsApp summary", "No documentation needed"]',
    1,
    'Send MOM (Minutes of Meeting) within 24 hours'
);

-- Q63: Escalation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'When should you escalate an issue?',
    'multiple_choice',
    '["Never escalate", "When it impacts timeline/budget/quality", "Only after trying everything alone", "Wait till last moment"]',
    1,
    'When it impacts timeline/budget/quality'
);

-- Q64: Team Collaboration
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Best way to collaborate with team members',
    'multiple_choice',
    '["Work in silos", "Regular updates + shared documentation + proactive communication", "Minimal interaction", "Only speak when asked"]',
    1,
    'Regular updates + shared documentation + proactive communication'
);

-- ============================================
-- 4. VERIFICATION QUERIES
-- ============================================

-- Count pathways
SELECT 'Orientation Pathway Created: ' || COUNT(*) as message
FROM pathways 
WHERE name = 'Orientation';

-- Count levels
SELECT 'Orientation Levels Created: ' || COUNT(*) as message
FROM pathway_levels 
WHERE pathway_id = '20000000-0000-0000-0000-000000000001';

-- Count questions
SELECT 'Orientation Questions Created: ' || COUNT(*) as message
FROM question_bank 
WHERE level_id = '21000000-0000-0000-0000-000000000001';

-- Final message
SELECT 'Setup Complete! ✅' as message;
