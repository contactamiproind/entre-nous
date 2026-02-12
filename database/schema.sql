-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.departments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text,
  subcategory text,
  tags jsonb DEFAULT '[]'::jsonb,
  levels jsonb DEFAULT '[]'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  display_order integer DEFAULT 0,
  CONSTRAINT departments_pkey PRIMARY KEY (id)
);
CREATE TABLE public.end_game_assignments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  end_game_id uuid,
  user_id uuid,
  assigned_at timestamp without time zone DEFAULT now(),
  completed_at timestamp with time zone,
  score integer DEFAULT 0,
  CONSTRAINT end_game_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT end_game_assignments_end_game_id_fkey FOREIGN KEY (end_game_id) REFERENCES public.end_game_configs(id),
  CONSTRAINT end_game_assignments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.end_game_configs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  level integer CHECK (level >= 1 AND level <= 4),
  venue_data jsonb NOT NULL,
  items_data jsonb NOT NULL,
  is_active boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT end_game_configs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.profiles (
  user_id uuid NOT NULL,
  email text,
  role text DEFAULT 'user'::text CHECK (role = ANY (ARRAY['admin'::text, 'user'::text])),
  created_at timestamp with time zone DEFAULT now(),
  manually_created boolean DEFAULT false,
  orientation_completed boolean DEFAULT false,
  avatar_url text,
  bio text,
  full_name text,
  phone text,
  updated_at timestamp with time zone DEFAULT now(),
  level integer DEFAULT 1 CHECK (level >= 1 AND level <= 4),
  CONSTRAINT profiles_pkey PRIMARY KEY (user_id)
);
CREATE TABLE public.quest_types (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quest_types_pkey PRIMARY KEY (id)
);
CREATE TABLE public.questions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type_id uuid,
  dept_id uuid,
  title text NOT NULL,
  description text,
  tags jsonb DEFAULT '[]'::jsonb,
  points integer DEFAULT 10,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  options jsonb,
  correct_answer text,
  level_id uuid,
  level integer DEFAULT 1 CHECK (level >= 1 AND level <= 4),
  CONSTRAINT questions_pkey PRIMARY KEY (id),
  CONSTRAINT questions_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.quest_types(id),
  CONSTRAINT questions_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.departments(id)
);
CREATE TABLE public.usr_dept (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  dept_id uuid NOT NULL,
  dept_name text NOT NULL,
  assigned_by uuid,
  assigned_at timestamp with time zone DEFAULT now(),
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'completed'::text, 'paused'::text])),
  is_current boolean DEFAULT true,
  total_questions integer DEFAULT 0,
  answered_questions integer DEFAULT 0,
  correct_answers integer DEFAULT 0,
  total_score integer DEFAULT 0,
  max_possible_score integer DEFAULT 0,
  progress_percentage numeric DEFAULT 0.00,
  current_level integer DEFAULT 1,
  completed_levels integer DEFAULT 0,
  total_levels integer DEFAULT 0,
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  last_activity_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT usr_dept_pkey PRIMARY KEY (id),
  CONSTRAINT usr_dept_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.departments(id)
);
CREATE TABLE public.usr_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  dept_id uuid NOT NULL,
  usr_dept_id uuid NOT NULL,
  question_id uuid NOT NULL,
  question_text text,
  question_type text,
  difficulty text,
  category text,
  subcategory text,
  points integer DEFAULT 1,
  level_number integer,
  level_name text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'answered'::text, 'skipped'::text, 'flagged'::text])),
  user_answer text,
  is_correct boolean,
  score_earned integer DEFAULT 0,
  attempt_count integer DEFAULT 0,
  first_attempted_at timestamp with time zone,
  last_attempted_at timestamp with time zone,
  completed_at timestamp with time zone,
  time_spent_seconds integer DEFAULT 0,
  notes text,
  flagged_for_review boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT usr_progress_pkey PRIMARY KEY (id),
  CONSTRAINT usr_progress_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.departments(id),
  CONSTRAINT usr_progress_usr_dept_id_fkey FOREIGN KEY (usr_dept_id) REFERENCES public.usr_dept(id),
  CONSTRAINT usr_progress_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id)
);