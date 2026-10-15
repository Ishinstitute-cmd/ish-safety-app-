-- ============================================================================
-- ISH Institute of Safety & Health (ishinstitutes.org)
-- Mobile Learning App - Complete Supabase PostgreSQL Schema
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. PROFILES TABLE (Linked with Supabase Auth)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    language_pref TEXT DEFAULT 'en' CHECK (language_pref IN ('en', 'ur')),
    streak_count INT DEFAULT 1,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. CATEGORIES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    title_en TEXT NOT NULL,
    title_ur TEXT NOT NULL,
    description_en TEXT,
    description_ur TEXT,
    icon TEXT NOT NULL,
    color_hex TEXT NOT NULL DEFAULT '#F59E0B',
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 3. CONCEPT CARDS TABLE (2-minute mini lessons: Learn tab)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.concept_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    title_en TEXT NOT NULL,
    title_ur TEXT NOT NULL,
    body_en TEXT NOT NULL,
    body_ur TEXT NOT NULL,
    key_points_en TEXT[] NOT NULL DEFAULT '{}',
    key_points_ur TEXT[] NOT NULL DEFAULT '{}',
    image_url TEXT,
    read_time_minutes INT DEFAULT 2,
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 4. QUESTIONS TABLE (MCQs with instant feedback & concept link)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    concept_id UUID REFERENCES public.concept_cards(id) ON DELETE SET NULL,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')) DEFAULT 'medium',
    question_en TEXT NOT NULL,
    question_ur TEXT NOT NULL,
    option_a_en TEXT NOT NULL,
    option_a_ur TEXT NOT NULL,
    option_b_en TEXT NOT NULL,
    option_b_ur TEXT NOT NULL,
    option_c_en TEXT NOT NULL,
    option_c_ur TEXT NOT NULL,
    option_d_en TEXT NOT NULL,
    option_d_ur TEXT NOT NULL,
    correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('a', 'b', 'c', 'd')),
    explanation_en TEXT NOT NULL,
    explanation_ur TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 5. INTERVIEW QUESTIONS TABLE (Interview Prep by role)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.interview_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role TEXT NOT NULL, -- e.g. 'HSE Officer', 'Safety Supervisor', 'Fire Safety Officer'
    question_en TEXT NOT NULL,
    question_ur TEXT NOT NULL,
    model_answer_en TEXT NOT NULL,
    model_answer_ur TEXT NOT NULL,
    key_takeaways_en TEXT[] NOT NULL DEFAULT '{}',
    key_takeaways_ur TEXT[] NOT NULL DEFAULT '{}',
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 6. HAZARD HUNT LEVELS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.hazard_levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level_number INT UNIQUE NOT NULL,
    title_en TEXT NOT NULL,
    title_ur TEXT NOT NULL,
    image_url TEXT NOT NULL,
    time_limit INT NOT NULL DEFAULT 90, -- in seconds
    required_stars_to_unlock INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 7. HAZARDS TABLE (Interactive percentage coordinates 0-100%)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.hazards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level_id UUID NOT NULL REFERENCES public.hazard_levels(id) ON DELETE CASCADE,
    concept_id UUID REFERENCES public.concept_cards(id) ON DELETE SET NULL,
    x NUMERIC(5,2) NOT NULL, -- 0.00 to 100.00 percentage of image width
    y NUMERIC(5,2) NOT NULL, -- 0.00 to 100.00 percentage of image height
    radius NUMERIC(5,2) NOT NULL DEFAULT 8.00, -- radius percentage
    name_en TEXT NOT NULL,
    name_ur TEXT NOT NULL,
    reason_en TEXT NOT NULL,
    reason_ur TEXT NOT NULL,
    control_en TEXT NOT NULL,
    control_ur TEXT NOT NULL,
    control_level TEXT NOT NULL CHECK (control_level IN ('Elimination', 'Substitution', 'Engineering', 'Administrative', 'PPE')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 8. USER SCORES & QUIZ HISTORY
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    score INT NOT NULL,
    total_questions INT NOT NULL,
    quiz_type TEXT NOT NULL DEFAULT 'practice' CHECK (quiz_type IN ('daily', 'practice', 'test')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 9. BOOKMARKS TABLE (Interview Questions, Concept Cards)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL CHECK (item_type IN ('interview', 'concept', 'question')),
    item_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, item_type, item_id)
);

-- ============================================================================
-- 10. HAZARD LEVEL PROGRESS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.level_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    level_id UUID NOT NULL REFERENCES public.hazard_levels(id) ON DELETE CASCADE,
    stars INT NOT NULL DEFAULT 0 CHECK (stars BETWEEN 0 AND 3),
    high_score INT NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, level_id)
);

-- ============================================================================
-- 11. USER MASTERY & SPACED REPETITION QUEUE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    concept_id UUID NOT NULL REFERENCES public.concept_cards(id) ON DELETE CASCADE,
    correct_count INT NOT NULL DEFAULT 0,
    incorrect_count INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'learning' CHECK (status IN ('learning', 'review', 'mastered')),
    next_review_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '1 day'),
    last_reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, concept_id)
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.concept_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hazard_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hazards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.level_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_mastery ENABLE ROW LEVEL SECURITY;

-- 1. Profiles: Users can select, update and insert their own profile
CREATE POLICY "Public profiles are readable by everyone" 
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" 
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Content tables: Public read-only for anonymous & authenticated users
CREATE POLICY "Categories are readable by everyone" 
    ON public.categories FOR SELECT USING (true);

CREATE POLICY "Concept cards are readable by everyone" 
    ON public.concept_cards FOR SELECT USING (true);

CREATE POLICY "Questions are readable by everyone" 
    ON public.questions FOR SELECT USING (true);

CREATE POLICY "Interview questions are readable by everyone" 
    ON public.interview_questions FOR SELECT USING (true);

CREATE POLICY "Hazard levels are readable by everyone" 
    ON public.hazard_levels FOR SELECT USING (true);

CREATE POLICY "Hazards are readable by everyone" 
    ON public.hazards FOR SELECT USING (true);

-- 3. User isolated tables: Restricted to auth.uid() = user_id
CREATE POLICY "Users can manage their own scores" 
    ON public.scores FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own bookmarks" 
    ON public.bookmarks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own level progress" 
    ON public.level_progress FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own mastery" 
    ON public.user_mastery FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Leaderboard query helper view / security definition:
-- Profiles streak & scores can be read publicly for the Top 20 weekly leaderboard
CREATE OR REPLACE VIEW public.leaderboard_weekly AS
    SELECT 
        p.id AS user_id,
        p.full_name,
        p.avatar_url,
        COALESCE(SUM(s.score), 0) AS total_score,
        COUNT(s.id) AS quizzes_completed
    FROM public.profiles p
    LEFT JOIN public.scores s ON s.user_id = p.id AND s.created_at >= (NOW() - INTERVAL '7 days')
    GROUP BY p.id, p.full_name, p.avatar_url
    ORDER BY total_score DESC
    LIMIT 20;

-- Auto create profile on auth signup trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url, language_pref)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        'en'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- 1. Insert Categories
INSERT INTO public.categories (id, slug, title_en, title_ur, description_en, description_ur, icon, color_hex, order_index)
VALUES 
('11111111-1111-1111-1111-111111111101', 'nebosh', 'NEBOSH IGC', 'نیبوش آئی جی سی', 'International General Certificate in Occupational Health & Safety', 'پیشہ ورانہ صحت اور حفاظت میں بین الاقوامی جنرل سرٹیفکیٹ', 'award', '#F59E0B', 1),
('11111111-1111-1111-1111-111111111102', 'iosh', 'IOSH Managing Safely', 'آئی او ایس ایچ مینیجنگ سیفلی', 'Practical health and safety management for managers and team leaders', 'مینیجرز اور سپروائزرز کے لیے عملی سیفٹی مینجمنٹ', 'briefcase', '#10B981', 2),
('11111111-1111-1111-1111-111111111103', 'osha', 'OSHA Standards', 'اوشا معیارات', 'US Occupational Safety and Health Administration compliance rules', 'امریکی اوشا تعمیلی رہنما اصول اور تقاضے', 'shield-check', '#3B82F6', 3),
('11111111-1111-1111-1111-111111111104', 'first-aid', 'First Aid at Work', 'ابتدائی طبی امداد', 'Life-saving CPR, bleeding control, trauma response, and casualty triage', 'سی پی آر، خون روکنے اور ہنگامی طبی امداد کی تربیت', 'plus-circle', '#EF4444', 4),
('11111111-1111-1111-1111-111111111105', 'fire-safety', 'Fire Safety', 'آگ سے حفاظت', 'Fire chemistry, prevention, extinguisher classes, and evacuation protocols', 'آتشزدگی کی روک تھام، آگ بجھانے کے آلات اور اخراج کا منصوبہ', 'flame', '#F97316', 5),
('11111111-1111-1111-1111-111111111106', 'ppe', 'PPE Regulations', 'حفاظتی سامان (PPE)', 'Personal Protective Equipment standards, selection, and maintenance', 'ذاتی حفاظتی آلات کے انتخاب اور استعمال کے طریقے', 'hard-hat', '#8B5CF6', 6),
('11111111-1111-1111-1111-111111111107', 'hazards', 'Hazard Identification', 'خطرات کی نشاندہی', 'Physical, chemical, biological, ergonomic, and psychological hazards', 'جسمانی، کیمیائی اور دیگر خطرات کی بروقت پہچان', 'alert-triangle', '#EAB308', 7),
('11111111-1111-1111-1111-111111111108', 'construction', 'Construction Safety', 'تعمیراتی حفاظت', 'Scaffolding, excavation, crane rigging, fall protection, and confined spaces', 'اسکیفولڈنگ، کھدائی، بلندی پر کام اور کرین سیفٹی', 'hammer', '#06B6D4', 8)
ON CONFLICT (slug) DO NOTHING;

-- 2. Insert Concept Cards (2-minute mini lessons)
INSERT INTO public.concept_cards (id, category_id, title_en, title_ur, body_en, body_ur, key_points_en, key_points_ur, image_url, read_time_minutes, order_index)
VALUES
(
    '22222222-2222-2222-2222-222222222201',
    '11111111-1111-1111-1111-111111111101', -- NEBOSH
    'The Hierarchy of Controls',
    'خطرات کے کنٹرول کا درجہ بندی نظام',
    'The Hierarchy of Controls is a step-by-step approach to eliminate or reduce workplace hazards. It ranks safety controls from the highest level of protection and reliability down to the least effective.',
    'کنٹرولز کا درجہ بندی نظام کام کی جگہ کے خطرات کو ختم کرنے یا کم کرنے کا بنیادی اصول ہے۔ یہ سب سے مؤثر طریقہ کار سے کم سے کم مؤثر طریقہ کار کی ترتیب پر مبنی ہے۔',
    ARRAY[
        '1. Elimination: Physically remove the hazard entirely (Most effective)',
        '2. Substitution: Replace the hazard with a safer alternative',
        '3. Engineering Controls: Isolate people from the hazard (barriers, ventilation)',
        '4. Administrative Controls: Change the way people work (training, procedures, signage)',
        '5. PPE: Protect the worker with Personal Protective Equipment (Last line of defense)'
    ],
    ARRAY[
        '1. خاتمہ (Elimination): خطرے کو مکمل طور پر ختم کرنا (سب سے زیادہ مؤثر)',
        '2. متبادل (Substitution): خطرے کو محفوظ چیز سے تبدیل کرنا',
        '3. انجینئرنگ کنٹرولز: ملازمین کو خطرے سے دور رکھنا (بیریئرز، وینٹی لیشن)',
        '4. انتظامی کنٹرولز: کام کے طریقہ کار کو تبدیل کرنا (تربیت، سائن بورڈ)',
        '5. ذاتی حفاظتی سامان (PPE): ملازم کو آلات فراہم کرنا (آخری دفاع)'
    ],
    'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80',
    2,
    1
),
(
    '22222222-2222-2222-2222-222222222202',
    '11111111-1111-1111-1111-111111111105', -- Fire Safety
    'Fire Extinguisher Classes & The PASS Method',
    'آگ بجھانے والے سلنڈرز کی اقسام اور PASS طریقہ',
    'Different fires require different extinguishing agents. Using water on an electrical fire can be fatal. Remember PASS: Pull the pin, Aim at the base, Squeeze the lever, and Sweep side to side.',
    'مختلف اقسام کی آگ کے لیے مخصوص سلنڈر استعمال کیے جاتے ہیں۔ بجلی کی آگ پر پانی ڈالنا جان لیوا ثابت ہو سکتا ہے۔ PASS کا فارمولا ہمیشہ یاد رکھیں۔',
    ARRAY[
        'Class A: Solid combustibles (Wood, Paper, Textiles) -> Water / Foam',
        'Class B: Flammable liquids (Petrol, Diesel, Paints) -> Dry Powder / Foam / CO2',
        'Class C: Flammable gases (Methane, Propane) -> Dry Chemical Powder',
        'Class D: Combustible metals (Magnesium, Lithium) -> Special Dry Powder',
        'Class F (K): Cooking oils and fats -> Wet Chemical',
        'Electrical fires: Use CO2 or Clean Agent; NEVER use Water'
    ],
    ARRAY[
        'کلاس A: لکڑی، کاغذ، کپڑا -> پانی یا فوم',
        'کلاس B: پیٹرول، ڈیزل، کیمیکلز -> ڈرائی پاؤڈر، فوم، CO2',
        'کلاس C: گیسوں کی آگ (ایل پی جی، میتھین) -> کیمیکل پاؤڈر',
        'کلاس D: دھاتیں (میگنیشیم، سوڈیم) -> خصوصی خشک پاؤڈر',
        'کلاس F: کچن کا کوکنگ آئل اور چکنائی -> ویٹ کیمیکل',
        'بجلی کی آگ: صرف CO2 یا ڈرائی پاؤڈر؛ پانی کا استعمال کبھی نہ کریں'
    ],
    'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&w=600&q=80',
    2,
    1
),
(
    '22222222-2222-2222-2222-222222222203',
    '11111111-1111-1111-1111-111111111104', -- First Aid
    'Cardiopulmonary Resuscitation (CPR) & DRSABCD',
    'سی پی آر (CPR) اور ابتدائی طبی امداد کے بنیادی اصول',
    'When a casualty is unresponsive and not breathing normally, immediate CPR keeps oxygenated blood circulating to the brain and vital organs until emergency services arrive.',
    'اگر کوئی شخص بے ہوش ہو جائے اور سانس نہ لے رہا ہو تو فوری سی پی آر شروع کرنے سے دماغ اور دل کو آکسیجن کی فراہمی جاری رہتی ہے۔',
    ARRAY[
        'D - Danger: Ensure the area is safe for you, bystanders, and casualty',
        'R - Response: Check responsiveness (Shake shoulders and talk loudly)',
        'S - Send for help: Call emergency services immediately',
        'A - Airway: Open airway by tilting head back and lifting chin',
        'B - Breathing: Look, listen, and feel for normal breathing for 10 seconds',
        'C - CPR: 30 chest compressions (5-6cm deep, 100-120 bpm) followed by 2 rescue breaths',
        'D - Defibrillation: Attach an AED as soon as it is available and follow voice prompts'
    ],
    ARRAY[
        'D - خطرہ چیک کریں: اپنے لیے اور مریض کے لیے ماحول کا محفوظ ہونا یقینی بنائیں',
        'R - ردعمل دیکھیں: کندھے ہلا کر آواز دیں اور ہوش چیک کریں',
        'S - ایمرجنسی کال کریں: فوراً ایمبولینس کو طلب کریں',
        'A - سانس کی نالی کھولیں: سر پیچھے جھکا کر ٹھوڑی اوپر اٹھائیں',
        'B - سانس چیک کریں: 10 سیکنڈ تک سانس کی جانچ کریں',
        'C - سی پی آر: 30 بار چھاتی کو 5-6 سینٹی میٹر دبائیں پھر 2 بار مصنوعی سانس دیں',
        'D - ڈیفبریلیٹر (AED): مشین ملتے ہی لگا کر ہدایات پر عمل کریں'
    ],
    'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&w=600&q=80',
    2,
    1
),
(
    '22222222-2222-2222-2222-222222222204',
    '11111111-1111-1111-1111-111111111108', -- Construction Safety
    'Working at Height & Scaffolding Safety',
    'بلندی پر کام اور اسکیفولڈنگ سیفٹی کے تقاضے',
    'Falls from height are the number one cause of fatal injuries in the construction sector. Complete edge protection, certified scaffolding, and full-body harnesses are mandatory.',
    'تعمیراتی شعبے میں اموات کی سب سے بڑی وجہ بلندی سے گرنا ہے۔ مناسب ریلنگ، تصدیق شدہ اسکیفولڈنگ اور سیفٹی ہارنس کا استعمال لازمی ہے۔',
    ARRAY[
        'Scaffold Tag System: GREEN (Safe to use), YELLOW (Restrictions apply), RED (Do NOT use)',
        'Full Body Harness: Required when working above 2 meters (6 feet) without guardrails',
        '100% Tie-Off: Twin lanyards must be attached to an engineered anchor point at all times',
        'Toe-boards & Guardrails: Top rail (950mm-1150mm), Mid-rail (470mm), Toe-board (150mm)',
        'Ladder 4:1 Rule: For every 4 meters of vertical height, base must be 1 meter out'
    ],
    ARRAY[
        'اسکیفولڈ ٹیگنگ: سبز (محفوظ)، پیلا (مخصوص شرائط)، سرخ (استعمال پر پابندی)',
        'فل باڈی ہارنس: 2 میٹر (6 فٹ) سے زائد بلندی پر باڈی ہارنس لازمی ہے',
        'ڈبل لینیارڈ: چلتے پھرتے بھی ہمیشہ ایک ہک اینکر پوائنٹ سے منسلک ہونا چاہیے',
        'حفاظتی ریلنگ: ٹاپ ریل، مڈ ریل اور ٹو بورڈ گرنے سے روکنے کے لیے ضروری ہیں',
        'سیڑھی کا 4:1 اصول: ہر 4 فٹ اونچائی کے لیے سیڑھی کا پیندہ 1 فٹ دور رکھیں'
    ],
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=600&q=80',
    2,
    1
)
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Practice Questions
INSERT INTO public.questions (id, category_id, concept_id, difficulty, question_en, question_ur, option_a_en, option_a_ur, option_b_en, option_b_ur, option_c_en, option_c_ur, option_d_en, option_d_ur, correct_option, explanation_en, explanation_ur)
VALUES
(
    '33333333-3333-3333-3333-333333333301',
    '11111111-1111-1111-1111-111111111101', -- NEBOSH
    '22222222-2222-2222-2222-222222222201', -- Hierarchy of Controls
    'medium',
    'According to the Hierarchy of Controls, which measure is considered the FIRST and most effective line of defense?',
    'خطرات کے کنٹرول کے درجہ بندی نظام کے مطابق، سب سے پہلا اور سب سے مؤثر دفاع کون سا ہے؟',
    'Personal Protective Equipment (PPE)',
    'ذاتی حفاظتی سامان (PPE)',
    'Elimination',
    'خاتمہ (Elimination)',
    'Engineering Controls',
    'انجینئرنگ کنٹرولز',
    'Administrative Controls',
    'انتظامی کنٹرولز',
    'b',
    'Elimination physically removes the hazard from the workplace completely, making it the most effective control measure. PPE is the lowest and least effective control.',
    'خاتمہ (Elimination) خطرے کو مکمل طور پر ختم کر دیتا ہے، اس لیے یہ سب سے زیادہ مؤثر ہے۔ PPE فہرست میں سب سے آخری دفاع ہے۔'
),
(
    '33333333-3333-3333-3333-333333333302',
    '11111111-1111-1111-1111-111111111105', -- Fire Safety
    '22222222-2222-2222-2222-222222222202', -- Fire Extinguisher
    'easy',
    'Which type of fire extinguisher should NEVER be used on live electrical equipment?',
    'برقی آلات پر چلتی بجلی کی حالت میں کس قسم کا فائر ایکسٹنگوشر کبھی استعمال نہیں کرنا چاہیے؟',
    'Carbon Dioxide (CO2)',
    'کاربن ڈائی آکسائیڈ (CO2)',
    'Dry Chemical Powder',
    'خشک کیمیکل پاؤڈر',
    'Water Extinguisher',
    'پانی والا سلنڈر',
    'Clean Agent',
    'کلین ایجنٹ',
    'c',
    'Water conducts electricity! Spraying water on live electrical equipment will cause an electric shock or electrocution to the operator. Use CO2 or Dry Powder instead.',
    'پانی بجلی کا موصل ہے! برقی آلات پر پانی کا چھڑکاؤ کرنے سے کرنٹ لگنے یا جان جانے کا شدید خطرہ ہوتا ہے۔ بجلی کی آگ پر CO2 یا خشک پاؤڈر استعمال کریں۔'
),
(
    '33333333-3333-3333-3333-333333333303',
    '11111111-1111-1111-1111-111111111104', -- First Aid
    '22222222-2222-2222-2222-222222222203', -- CPR
    'medium',
    'What is the standard ratio of chest compressions to rescue breaths during adult CPR?',
    'بالغ فرد کے سی پی آر (CPR) کے دوران چھاتی دبانے اور مصنوعی سانس دینے کا معیاری تناسب کیا ہے؟',
    '15 compressions to 2 breaths',
    '15 بار دبانا اور 2 بار سانس',
    '30 compressions to 2 breaths',
    '30 بار دبانا اور 2 بار سانس',
    '50 compressions to 5 breaths',
    '50 بار دبانا اور 5 بار سانس',
    'Continuous compressions only',
    'صرف مسلسل چھاتی دبانا',
    'b',
    'The international standard for adult single-rescuer CPR is 30 chest compressions followed by 2 rescue breaths at a rate of 100-120 compressions per minute.',
    'بالغ فرد کے سی پی آر کا بین الاقوامی معیار 30 بار چھاتی کو دبانا اور پھر 2 بار مصنوعی سانس دینا ہے، جس کی رفتار 100 سے 120 فی منٹ ہونی چاہیے۔'
),
(
    '33333333-3333-3333-3333-333333333304',
    '11111111-1111-1111-1111-111111111108', -- Construction
    '22222222-2222-2222-2222-222222222204', -- Working at Height
    'medium',
    'What does a RED tag displayed on a scaffolding structure signify?',
    'اسکیفولڈنگ پر لگایا گیا سرخ (RED) ٹیگ کیا ظاہر کرتا ہے؟',
    'The scaffold is safe for heavy duty work only',
    'اسکیفولڈ صرف بھاری کام کے لیے محفوظ ہے',
    'The scaffold is under inspection but safe to climb',
    'اسکیفولڈ زیرِ معائنہ ہے مگر چڑھنا محفوظ ہے',
    'The scaffold is unsafe and strictly forbidden to use',
    'اسکیفولڈ غیر محفوظ ہے اور اس کا استعمال سختی سے منع ہے',
    'The scaffold requires a personal safety net underneath',
    'اسکیفولڈ کے نیچے حفاظتی جال لگانا ضروری ہے',
    'c',
    'A RED scaffold tag indicates danger; the scaffold is incomplete, damaged, or undergoing alterations, and NO ONE may use or step onto it.',
    'سرخ ٹیگ کا مطلب ہے کہ اسکیفولڈ نامکمل، خراب یا مرمت کے مرحلے میں ہے اور اس پر کسی بھی صورت چڑھنا سختی سے منع ہے۔'
)
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Interview Questions
INSERT INTO public.interview_questions (id, role, question_en, question_ur, model_answer_en, model_answer_ur, key_takeaways_en, key_takeaways_ur, order_index)
VALUES
(
    '44444444-4444-4444-4444-444444444401',
    'HSE Officer',
    'How do you conduct a dynamic Risk Assessment before a high-risk activity starts on site?',
    'سائٹ پر کسی بھی زیادہ خطرے والے کام سے قبل آپ متحرک رسک اسیسمنٹ (Risk Assessment) کیسے کرتے ہیں؟',
    'I follow the 5-step risk assessment model: 1) Identify the hazards (physical, environmental, mechanical). 2) Decide who might be harmed and how. 3) Evaluate the risks and decide on control measures adhering to the Hierarchy of Controls. 4) Record significant findings in the JSA/PTW and conduct a Tool Box Talk (TBT) with workers to ensure full comprehension. 5) Review throughout the task as conditions change.',
    'میں خطرے کی جانچ کے 5 بنیادی مراحل پر عمل کرتا ہوں: 1) تمام ممکنہ خطرات کی نشاندہی کرنا۔ 2) یہ طے کرنا کہ کون اور کیسے متاثر ہو سکتا ہے۔ 3) خطرے کی شدت کا جائزہ لے کر کنٹرول کا درجہ بندی نظام لاگو کرنا۔ 4) جے ایس اے (JSA) اور پرمٹ ٹو ورک (PTW) میں دستاویزی ریکارڈ بنانا اور ٹول باکس ٹاک (TBT) کے ذریعے ورکرز کو بریف کرنا۔ 5) کام کے دوران مسلسل مانیٹرنگ کرنا۔',
    ARRAY['5-Step HSE Model', 'Hierarchy of Controls', 'Toolbox Talk (TBT)', 'Permit to Work (PTW) Verification'],
    ARRAY['5 بنیادی مراحل', 'کنٹرولز کا درجہ بندی نظام', 'ٹول باکس ٹاک', 'ورک پرمٹ کی جانچ'],
    1
),
(
    '44444444-4444-4444-4444-444444444402',
    'Safety Supervisor',
    'What immediate actions do you take if a worker refuses to wear required PPE at height?',
    'اگر کوئی ورکر بلندی پر کام کرتے وقت مطلوبہ حفاظتی سامان (PPE) پہننے سے انکار کرے تو آپ فوری کیا اقدام کریں گے؟',
    'First, I exercise Stop Work Authority immediately to prevent an imminent fall hazard. Second, I safely escort the worker down from the elevated platform. Third, I engage in open dialogue to understand the underlying issue (ill-fitting harness, lack of training, or discomfort). Fourth, I provide compliant equipment and re-brief on life-saving consequences. If willful violation persists, I escalate to site management according to company disciplinary HSE policy.',
    'سب سے پہلے میں فوری طور پر اسٹاپ ورک اتھارٹی (Stop Work Authority) استعمال کرتے ہوئے کام رکوائوں گا۔ دوسرا قدم یہ ہوگا کہ ورکر کو بلندی سے بحفاظت نیچے اترواؤں گا۔ تیسرا، ورکر سے وجہ معلوم کروں گا (کیا ہارنس غیر آرام دہ ہے یا تربیت کی کمی ہے)۔ چوتھا، درست سامان مہیا کروں گا اور حفاظتی اصول سمجھاؤں گا۔ جان بوجھ کر خلاف ورزی پر کمپنی پالیسی کے تحت انتظامیہ کو رپورٹ کروں گا۔',
    ARRAY['Stop Work Authority', 'Root Cause Discovery', 'Re-education before discipline', 'Zero tolerance for life-threatening risk'],
    ARRAY['اسٹاپ ورک اتھارٹی کا استعمال', 'وجہ جاننا اور حل نکالنا', 'تنبیہ سے قبل تربیت', 'جان لیوا خطرے پر کوئی سمجھوتہ نہیں'],
    2
)
ON CONFLICT (id) DO NOTHING;

-- 5. Insert Hazard Hunt Level 1 (Construction Site)
INSERT INTO public.hazard_levels (id, level_number, title_en, title_ur, image_url, time_limit, required_stars_to_unlock)
VALUES
(
    '55555555-5555-5555-5555-555555555501',
    1,
    'Level 1: Construction Site Perimeter',
    'لیول 1: تعمیراتی سائٹ کا منظر',
    'assets/images/hazard_levels/construction_site.png',
    90,
    0
)
ON CONFLICT (level_number) DO NOTHING;

-- 6. Insert Level 1 Hazards (8-10 hazards with relative % coordinates and Hierarchy of Controls)
INSERT INTO public.hazards (id, level_id, concept_id, x, y, radius, name_en, name_ur, reason_en, reason_ur, control_en, control_ur, control_level)
VALUES
(
    '66666666-6666-6666-6666-666666666601',
    '55555555-5555-5555-5555-555555555501',
    '22222222-2222-2222-2222-222222222204', -- Working at Height
    24.50, 28.30, 7.50,
    'Worker without Safety Helmet',
    'حفاظتی ہیلمٹ کے بغیر ورکر',
    'Falling tools, bricks, or debris from overhead scaffolding can cause fatal head injuries.',
    'بلندی سے گرنے والے اوزار یا اینٹیں سر پر لگنے سے جان لیوا چوٹ آ سکتی ہے۔',
    'Provide and enforce EN 397 / ANSI Z89 compliant industrial safety helmets on site at all times.',
    'تمام ملازمین کے لیے تصدیق شدہ سیفٹی ہیلمٹ لازمی قرار دیں اور معائنہ کریں۔',
    'PPE'
),
(
    '66666666-6666-6666-6666-666666666602',
    '55555555-5555-5555-5555-555555555501',
    '22222222-2222-2222-2222-222222222204',
    72.00, 22.10, 8.00,
    'Working at Height Without Harness',
    'سیفٹی ہارنس کے بغیر اونچائی پر کام',
    'Working on open edge scaffold at 6+ meters height with no fall arrest harness risks immediate death upon slipping.',
    '6 میٹر سے زیادہ اونچائی پر بغیر باڈی ہارنس کام کرنے سے پھسل کر گرنے کا شدید خطرہ ہے۔',
    'Install perimeter guardrails with toe-boards and mandate 100% tied-off full body safety harness.',
    'اسکیفولڈنگ پر مکمل حفاظتی ریلنگ لگائیں اور ڈبل ہک باڈی ہارنس لازمی کریں۔',
    'Engineering'
),
(
    '66666666-6666-6666-6666-666666666603',
    '55555555-5555-5555-5555-555555555501',
    NULL,
    48.20, 78.40, 7.00,
    'Exposed High Voltage Electrical Cable',
    'ننگی ہائی وولٹیج بجلی کی تار',
    'Unshielded power cable lying across pedestrian walkway creates severe electrocution and trip hazards.',
    'پیدل راستے پر کھلی بجلی کی تار گزرنے سے کرنٹ لگنے اور ٹھوکر کھانے کا خطرہ ہے۔',
    'Route cables overhead via insulated poles or bury in protective underground conduits with warning tape.',
    'تاروں کو اونچائی پر پولز کے ذریعے گزاریں یا حفاظتی پائپ میں محفوظ کریں۔',
    'Engineering'
),
(
    '66666666-6666-6666-6666-666666666604',
    '55555555-5555-5555-5555-555555555501',
    '22222222-2222-2222-2222-222222222202', -- Fire Safety
    88.50, 65.00, 6.50,
    'Blocked Emergency Fire Exit',
    'ایمرجنسی فائر ایگزٹ کے آگے سامان کا ڈھیر',
    'Pallets and scrap timber stacked against the fire exit door prevent rapid evacuation during an explosion or blaze.',
    'ایگزٹ گیٹ کے آگے لکڑی اور سامان پڑا ہونے کی وجہ سے ہنگامی حالت میں فوری انخلا ممکن نہیں۔',
    'Immediately relocate stored materials to designated storage bays and maintain clear 1.2m egress routes.',
    'سامان کو فوری ہٹا کر مخصوص گودام میں منتقل کریں اور اخراج کا راستہ ہمیشہ صاف رکھیں۔',
    'Administrative'
),
(
    '66666666-6666-6666-6666-666666666605',
    '55555555-5555-5555-5555-555555555501',
    NULL,
    15.00, 72.50, 8.50,
    'Deep Excavation Without Barricades',
    'بغیر حفاظتی جنگلے کے گہری کھدائی',
    'Unshored trench deeper than 1.5m without barricading can collapse or cause workers/machinery to tumble in.',
    '1.5 میٹر سے گہرے گڑھے پر جنگلہ نہ ہونے کی وجہ سے ورکرز یا مشینری کے اندر گرنے کا خطرہ ہے۔',
    'Install rigid edge barriers, warning flashing beacons, and trench shoring boxes to prevent cave-ins.',
    'کھدائی کے گرد مضبوط بیریئرز لگائیں، سائن بورڈ لگائیں اور مٹی گرنے سے روکنے کا بندوبست کریں۔',
    'Engineering'
),
(
    '66666666-6666-6666-6666-666666666606',
    '55555555-5555-5555-5555-555555555501',
    NULL,
    60.50, 84.00, 6.80,
    'Hydraulic Oil Spill on Walkway',
    'راستے پر ہائیڈرولک آئل کا بہاؤ',
    'Greasy oil puddle creates slippery surface causing severe slip and fall fractures, plus environmental contamination.',
    'تیل کا پھسلن بھرا تالاب ورکرز کے پھسل کر شدید زخمی ہونے کا سبب بن سکتا ہے۔',
    'Deploy spill kit with absorbent pads, clean surface thoroughly, and repair leaking machinery seals.',
    'اسپل کٹ استعمال کر کے فوری صفائی کریں اور مشینری کی لیکیج کو مکمل طور پر ٹھیک کریں۔',
    'Elimination'
),
(
    '66666666-6666-6666-6666-666666666607',
    '55555555-5555-5555-5555-555555555501',
    '22222222-2222-2222-2222-222222222204',
    38.00, 48.00, 7.20,
    'Unsecured Ladder at Steep Angle',
    'بغیر باندھی گئی اور ٹیڑھی سیڑھی',
    'Ladder is set at unsafe 45 degree angle without top or bottom tied anchors, risking sudden slippage.',
    'سیڑھی خطرناک زاویے پر رکھی ہے اور اوپر نیچے سے باندھی نہیں گئی، جس سے گرنے کا خطرہ ہے۔',
    'Secure ladder at top and base, position at proper 75 degree angle (4:1 ratio), extend 1m past landing.',
    'سیڑھی کو 4:1 کے اصول پر کھڑا کریں اور اوپر و نیچے سے مضبوطی سے باندھیں',
    'Administrative'
),
(
    '66666666-6666-6666-6666-666666666608',
    '55555555-5555-5555-5555-555555555501',
    NULL,
    84.00, 40.00, 8.00,
    'Worker Under Suspended Crane Load',
    'کرین کے لٹکتے ہوئے وزن کے نیچے کھڑا ورکر',
    'Standing within crane swing radius underneath a suspended steel beam exposes worker to catastrophic crush injuries if rigging fails.',
    'کرین کے اٹھائے ہوئے وزن کے نیچے کھڑے ہونے کی صورت میں وزنی سامان گرنے سے ہلاکت ہو سکتی ہے۔',
    'Establish exclusion drop zone with warning cones; no personnel permitted under crane boom.',
    'کرین کے بوم کے نیچے مکمل نو-گو زون قائم کریں اور کسی کو نیچے کھڑا نہ ہونے دیں۔',
    'Administrative'
)
ON CONFLICT (id) DO NOTHING;
