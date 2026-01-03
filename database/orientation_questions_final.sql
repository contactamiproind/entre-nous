-- ============================================
-- ORIENTATION QUIZ DATA
-- ============================================
-- This script adds the Orientation pathway with 16 topics
-- Each topic has 4 questions (Easy, Mid, Hard, Extreme/Bonus)
-- Total: 64 questions
-- 
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. CREATE ORIENTATION PATHWAY
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
-- Question 1 (Easy): Single choice
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which action best creates Ease for a client?',
    'multiple_choice',
    '["Reply late but fix internally", "Share clear update with next steps", "Wait for senior approval silently", "Close task without informing"]',
    1
);

-- Question 2 (Mid): Match following
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match each action to Ease or Delight',
    'match_following',
    '[
        {"left": "Quick response with clear timeline", "right": "Ease"},
        {"left": "Surprise upgrade within budget", "right": "Delight"},
        {"left": "Proactive status updates", "right": "Ease"},
        {"left": "Personalized thank you note", "right": "Delight"}
    ]'
);

-- Question 3 (Hard): Scenario decision
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the option that delivers Delight without breaking process',
    'multiple_choice',
    '["Skip documentation to save time", "Add expensive extras without approval", "Include a thoughtful touch within approved budget", "Promise features not in scope"]',
    2
);

-- Question 4 (Extreme): Budget simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Design a solution that creates Ease, Delight & Cost Effectiveness together. Which approach is best?',
    'multiple_choice',
    '["Luxury everything regardless of budget", "Cheapest options only", "Strategic WOW moments + efficient processes + clear communication", "Standard delivery with no extras"]',
    2
);

-- Topic 2: VALUES
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the most value-aligned action',
    'multiple_choice',
    '["Reply late but fix internally", "Share clear update with next steps", "Wait for senior approval silently", "Close task without informing"]',
    1
);

-- Question 2 (Mid): Match action to value
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match each action to the correct ENEPL value',
    'match_following',
    '[
        {"left": "Sending MOM after call", "right": "Professionalism"},
        {"left": "Proactive client updates", "right": "Partner Focus"},
        {"left": "Quick decision without delays", "right": "Lean & Responsive"},
        {"left": "Documenting all processes", "right": "Professionalism"}
    ]'
);

-- Question 3 (Hard): Scenario
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Client wants a last-minute change impacting budget. What do you do?',
    'multiple_choice',
    '["Say yes to please client", "Escalate after committing", "Explain impact + revise scope & budget", "Ignore till later"]',
    2
);

-- Question 4 (Extreme): Decision simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Handle conflict under pressure while protecting values. What is the best approach?',
    'multiple_choice',
    '["Cut process to save time", "Blame another team", "Take quick decision without informing client", "Align stakeholders, document change, act fast"]',
    3
);

-- Topic 3: GOALS
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Pick the action that supports our goals',
    'multiple_choice',
    '["Focus only on cost cutting", "Deliver WOW moment within budget", "Finish fast without documentation", "Do extra work without alignment"]',
    1
);

-- Question 2 (Mid): Sort into goal buckets
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match each action to the correct company goal',
    'match_following',
    '[
        {"left": "Accurate budget forecast", "right": "Efficiency"},
        {"left": "Signature event element", "right": "Brand Building"},
        {"left": "Zero-defect delivery", "right": "Quality"},
        {"left": "Team skill development", "right": "People"}
    ]'
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You have limited budget. What delivers growth + quality together?',
    'multiple_choice',
    '["Expensive decor everywhere", "One strong WOW + controlled spends", "Cheapest vendors only", "Add scope without approval"]',
    1
);

-- Question 4 (Extreme): Build event plan
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Build a mini event plan that hits 3 goals minimum. Select the best combination:',
    'multiple_choice',
    '["Team overload + Random vendors + No documentation", "Accurate forecast + Recognizable WOW offering + High-margin decision", "Cheapest everything + No branding + Rush delivery", "Expensive setup + Delayed timeline + No tracking"]',
    1
);

-- Topic 4: BRAND GUIDELINES
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the correct primary brand color',
    'multiple_choice',
    '["Neon Green", "Wine Red", "Electric Blue", "Orange"]',
    1
);

-- Question 2 (Mid): Sort colors
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Classify these colors as Primary or Secondary for ENEPL brand',
    'match_following',
    '[
        {"left": "Gold (#F4D394)", "right": "Primary"},
        {"left": "Wine Red", "right": "Primary"},
        {"left": "Charcoal", "right": "Secondary"},
        {"left": "Cream", "right": "Secondary"}
    ]'
);

-- Question 3 (Hard): Font combination
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Pick the correct font combination for an invite',
    'multiple_choice',
    '["Comic Sans + Italics", "Raleway Bold + Montserrat Regular", "Times New Roman + Serif", "Random mix"]',
    1
);

-- Question 4 (Extreme): Visual builder
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Build a brand-safe visual. Which combination is correct?',
    'multiple_choice',
    '["Charcoal background + Raleway Bold heading + Cream base tone", "Random bright colors + Any font + No guidelines", "Neon colors + Comic Sans + White only", "Black only + No typography rules"]',
    0
);

-- Topic 5: ABOUT ENEPL
-- Question 1 (Easy): Multi-select converted to MCQ
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which of the following are service verticals offered by Entre Nous?',
    'multiple_choice',
    '["Only Brand Building", "Brand Building, Virtual Events, and Nurturing Talent", "Only Retail Operations", "None of the above"]',
    1
);

-- Question 2 (Mid): Client identification
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match these organizations to their relationship with ENEPL',
    'match_following',
    '[
        {"left": "YPO", "right": "Client"},
        {"left": "EO", "right": "Client"},
        {"left": "Tata Group", "right": "Client"},
        {"left": "Google", "right": "Not a client"}
    ]'
);

-- Question 3 (Hard): IP events
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Identify IP events created by Entre Nous',
    'multiple_choice',
    '["Only PLLA", "PLLA, Style Icon, and Kala Ki Khoj", "Only IPL", "None are IP events"]',
    1
);

-- Question 4 (Extreme): Information sources
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Where would you find client & IP event information?',
    'multiple_choice',
    '["Only Personal WhatsApp", "Company Website, Instagram & Facebook", "Old Event Pics Folder only", "Information is not documented"]',
    1
);

-- Topic 6: JOB SHEET
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'What best defines a Job Sheet?',
    'multiple_choice',
    '["Personal to-do list only", "Consolidation of all jobs you are accountable for", "PM''s responsibility only", "Event checklist only"]',
    1
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Who is responsible for creating & updating the Job Sheet?',
    'multiple_choice',
    '["Project Manager", "Team Lead", "You (yourself)", "Admin"]',
    2
);

-- Question 3 (Hard): Valid sources
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Identify which are valid sources for adding jobs to Job Sheet',
    'match_following',
    '[
        {"left": "WhatsApp messages & groups", "right": "Valid"},
        {"left": "Emails from vendors/clients", "right": "Valid"},
        {"left": "MoMs (Minutes of Meeting)", "right": "Valid"},
        {"left": "Personal reminders only", "right": "Invalid"}
    ]'
);

-- Question 4 (Extreme): Crisis scenario
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You missed updating your Job Sheet and tasks pile up near event date. What is the right action?',
    'multiple_choice',
    '["Rush tasks closer to event", "Inform PM last minute", "Update Job Sheet immediately and flag bottlenecks early", "Wait for review meeting"]',
    2
);

-- Topic 7: WATER MELON STORY
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'What is the core message of the Water Melon Story?',
    'multiple_choice',
    '["Do tasks fast", "Do only what''s asked", "Own the outcome, not just the task", "Wait for instructions"]',
    2
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You''re asked to "check vendor availability." What''s the most ENEPL-aligned response?',
    'multiple_choice',
    '["Yes, vendor available", "Share price only", "Share price + capacity + timelines + risks + next steps", "Ask senior what to do next"]',
    2
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which action best shows "elder brother thinking" in an event task?',
    'multiple_choice',
    '["Finish task & log off", "Ask clarifying questions before starting", "Anticipate follow-ups & include insights proactively", "Wait for feedback"]',
    2
);

-- Question 4 (Extreme): Scenario chain
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Client asks a basic question close to event day. What should you do?',
    'multiple_choice',
    '["Answer only what''s asked", "Forward the query", "Answer + flag risks + suggest improvements + share backup plan", "Say will revert later"]',
    2
);

-- Topic 8: PRIORITIZATION
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Task: "Vendor hasn''t arrived on event day" - Which quadrant does this belong to?',
    'multiple_choice',
    '["Quadrant 1 – Urgent & Important", "Quadrant 2 – Important, not Urgent", "Quadrant 3 – Urgent, not Important", "Quadrant 4 – Neither"]',
    0
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match each task to the correct priority quadrant',
    'match_following',
    '[
        {"left": "Vendor crisis on event day", "right": "Q1: Urgent & Important"},
        {"left": "Improve SOP documentation", "right": "Q2: Important, not Urgent"},
        {"left": "Random WhatsApp forwards", "right": "Q4: Neither"},
        {"left": "Unnecessary meeting", "right": "Q3: Urgent, not Important"}
    ]'
);

-- Question 3 (Hard): Clear the clutter
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Clear the clutter: Which task should be moved out first?',
    'multiple_choice',
    '["Random WhatsApp forwards", "Final stage setup check", "Client call in 10 mins", "Fire safety approval"]',
    0
);

-- Question 4 (Extreme): Balance the day
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Balance the day: Select 2 tasks to do NOW',
    'multiple_choice',
    '["Personal social media scroll + Unrelated chatter", "Guest arrival issue + Event debrief planning", "Only social media", "Only unrelated chatter"]',
    1
);

-- Topic 9: GREETINGS
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Pick the correct greeting behaviour',
    'multiple_choice',
    '["Start work silently", "Greet colleagues with a smile", "Only greet seniors", "Greet only if spoken to"]',
    1
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match the situation to the correct action',
    'match_following',
    '[
        {"left": "Morning / Goodnight message", "right": "Logging in / off"},
        {"left": "Guest arrives at office", "right": "Offer water & seating"},
        {"left": "Virtual call starts", "right": "Greet client first"},
        {"left": "Colleague absent", "right": "Note caller details"}
    ]'
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'A guest arrives at the office. What should you do first?',
    'multiple_choice',
    '["Ask them to wait silently", "Offer water & seating", "Continue working", "Ignore till told"]',
    1
);

-- Question 4 (Extreme): Roleplay simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Handle a call + meeting scenario correctly. Which is the complete correct approach?',
    'multiple_choice',
    '["Use first names for clients casually", "Greet client first + Address as Mr./Ms. + Note caller details for absent colleague", "Skip greetings to save time", "Only greet if client greets first"]',
    1
);

-- Topic 10: DRESS CODE
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Spot the correct grooming rule',
    'multiple_choice',
    '["Untidy hair is okay", "Well-groomed hair & nails required", "Deodorant optional", "Grooming only for events"]',
    1
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the right outfit for office work',
    'multiple_choice',
    '["Singlet & chappals", "Smart casuals", "Shorts & slippers", "Party wear"]',
    1
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match the role to correct dress code',
    'match_following',
    '[
        {"left": "Event Setup (Day)", "right": "ENEPL Chinos + White Tee"},
        {"left": "Client Event (Night)", "right": "ENEPL Black Shirt + Chinos"},
        {"left": "Office Work", "right": "Smart Casuals"},
        {"left": "Never Appropriate", "right": "Open footwear"}
    ]'
);

-- Question 4 (Extreme): Visual builder
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You''re attending a client event at night. Build the correct look:',
    'multiple_choice',
    '["Casual sandals + Any shirt", "ENEPL Black Shirt + ENEPL Chinos + Closed shoes", "Denims + Sneakers", "Party wear + Open footwear"]',
    1
);

-- Topic 11: ATTENDANCE/LEAVES
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'How do you mark daily attendance?',
    'multiple_choice',
    '["WhatsApp message", "Manual register", "Razorpay link", "Verbal confirmation"]',
    2
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Classify attendance actions as Correct or Incorrect',
    'match_following',
    '[
        {"left": "Daily check-in & check-out", "right": "Mandatory (impacts salary)"},
        {"left": "Attendance only on event days", "right": "Incorrect"},
        {"left": "Attendance optional", "right": "Incorrect"},
        {"left": "Using Razorpay link", "right": "Correct"}
    ]'
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You''re reaching office at 11:15 AM without prior intimation. What applies?',
    'multiple_choice',
    '["Full day", "Work from home", "Half day", "No impact"]',
    2
);

-- Question 4 (Extreme): Save the full day
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Save the full day: What are the correct conditions to avoid half-day marking?',
    'multiple_choice',
    '["Inform after arrival + No limit on frequency", "Inform 1 hour prior + Max 3 times per month + Update calendar", "No need to inform + Unlimited", "Inform same day + No calendar update"]',
    1
);

-- Topic 12: OFFICE DECORUM
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the correct office behaviour',
    'multiple_choice',
    '["Leave files open on desk", "File documents neatly before leaving", "Skip updates to team lead", "Enter finance area freely"]',
    1
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'A courier arrives for a colleague who isn''t present. What do you do first?',
    'multiple_choice',
    '["Ignore the parcel", "Collect parcel & note sender/delivery details", "Leave it at reception", "Open it to check"]',
    1
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Confirm the delivery correctly. What is the next step after collecting the parcel?',
    'multiple_choice',
    '["Assume it''s correct", "Send picture to colleague to reconfirm", "Store without informing", "Wait till next day"]',
    1
);

-- Question 4 (Extreme): Communication simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'You''re running late / unable to come to office. What is the complete correct response?',
    'multiple_choice',
    '["Inform after reaching office", "Inform early with reason + Update team lead so planning can adjust", "Say nothing", "Inform only team lead, skip calendar"]',
    1
);

-- Topic 13: WORKING STYLE
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Choose the best working-style behaviour',
    'multiple_choice',
    '["Do tasks when reminded", "Follow timelines you commit to", "Skip process to save time", "Pass ownership"]',
    1
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Why should you seek acknowledgement for messages?',
    'multiple_choice',
    '["To look active", "To remove assumption that sent = received", "For formality only", "Not required"]',
    1
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'A client/supplier calls but you don''t have the answer. What should you do?',
    'multiple_choice',
    '["Guess the answer", "Ask them to call later", "Say you''ll revert and actually do so", "Avoid the call"]',
    2
);

-- Question 4 (Extreme): Roleplay simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Handle a live work situation correctly. What is the complete best practice?',
    'multiple_choice',
    '["Hide gaps in understanding + Wait for reminders", "Own your task end-to-end + Acknowledge messages + Bring solution with problem", "Pass ownership + Skip acknowledgements", "Do only what''s asked + No proactive communication"]',
    1
);

-- Topic 14: VENDOR INTERACTION
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Who should you meet a new vendor with?',
    'multiple_choice',
    '["Alone", "With any teammate", "With TL (Team Lead)", "Over WhatsApp only"]',
    2
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, match_pairs)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Match the communication method to the correct backup requirement',
    'match_following',
    '[
        {"left": "WhatsApp confirmation", "right": "Backup with email (CC TL)"},
        {"left": "Verbal discussion", "right": "Follow up in writing"},
        {"left": "Email confirmation", "right": "Sufficient documentation"},
        {"left": "Phone call only", "right": "Not acceptable"}
    ]'
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Vendor is not tech-savvy. What''s the correct action?',
    'multiple_choice',
    '["Ignore confirmation", "Screenshot WhatsApp → Email TL", "Call and forget", "Ask vendor to learn email"]',
    1
);

-- Question 4 (Extreme): Scenario simulation
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Run a vendor interaction correctly. What is the complete correct approach?',
    'multiple_choice',
    '["Handle vendors alone + Skip TL involvement", "Vendor contacts handled by VRF In-charge + Align décor with ENEPL + Keep TL looped + Reply within 3-5 hours", "Take approvals without alignment", "WhatsApp only, no documentation"]',
    1
);

-- Topic 15: COMMUNICATION PROTOCOL
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'How should meetings be scheduled with external stakeholders?',
    'multiple_choice',
    '["WhatsApp message only", "Verbal confirmation", "Calendar invite + Zoom link", "Ask them to schedule"]',
    2
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'In which format should external files be shared?',
    'multiple_choice',
    '["Word / PPT", "Images on WhatsApp", "PDF only", "Any format is fine"]',
    2
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'There''s a crisis during an event. What do you do first?',
    'multiple_choice',
    '["Wait for TL to notice", "Inform later on WhatsApp", "Raise Red Alert on group/email immediately", "Call one person only"]',
    2
);

-- Question 4 (Extreme): Trail mail management
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'A vendor discussion spans months. What''s the correct way to manage communication?',
    'multiple_choice',
    '["New mail every time", "WhatsApp only", "One email chain per topic + correct trail mail subject + all operational IDs CC''d", "Forward last mail only"]',
    2
);

-- Topic 16: EMAIL ETIQUETTE
-- Question 1 (Easy)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'What is the correct email subject structure at ENEPL?',
    'multiple_choice',
    '["Casual line", "Only event name", "Event name + date + mail content", "One-word subject"]',
    2
);

-- Question 2 (Mid)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'During training period, who must be CC''d on all mails?',
    'multiple_choice',
    '["Only client", "Only TL", "SK + person who assigned the job", "No one"]',
    2
);

-- Question 3 (Hard)
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Which option follows correct email salutation & greeting?',
    'multiple_choice',
    '["Hi Garima", "Dear Garima", "Dear Ms. Mishra + Greeting from Entre Nous Experiences Pvt. Ltd.", "Hello Team"]',
    2
);

-- Question 4 (Extreme): Email chain management
INSERT INTO question_bank (level_id, question_text, question_type, options, correct_answer_index, correct_answer)
VALUES (
    '21000000-0000-0000-0000-000000000001',
    'Best practice for managing long email discussions. What is the complete correct approach?',
    'multiple_choice',
    '["New mail every time + No trail", "WhatsApp preferred over email", "One email chain per topic + correct trail subject + all operational IDs CC''d + proper documentation", "Forward last mail only when needed"]',
    2
);

-- ============================================
-- 4. VERIFICATION QUERIES
-- ============================================

-- Check if data was inserted correctly
SELECT 'Orientation Pathway Created' as status, COUNT(*) as count 
FROM pathways WHERE name = 'Orientation';

SELECT 'Orientation Levels Created' as status, COUNT(*) as count 
FROM pathway_levels 
WHERE pathway_id = (SELECT id FROM pathways WHERE name = 'Orientation');

SELECT 'Orientation Questions Created' as status, COUNT(*) as count 
FROM question_bank 
WHERE level_id = (
    SELECT id FROM pathway_levels 
    WHERE pathway_id = (SELECT id FROM pathways WHERE name = 'Orientation')
    AND level_number = 1
);

-- Expected results:
-- Orientation Pathway Created: 1
-- Orientation Levels Created: 1
-- Orientation Questions Created: 64

SELECT 'Setup Complete! ✅' as message;
