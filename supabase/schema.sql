-- ============================================================
-- KAKEIBO APP - Supabase Schema
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROFILES
-- ============================================================
CREATE TABLE profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email        TEXT NOT NULL,
  full_name    TEXT,
  avatar_url   TEXT,
  currency     TEXT NOT NULL DEFAULT 'IDR',
  monthly_budget DECIMAL(15,2) DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. ACCOUNTS
-- ============================================================
CREATE TABLE accounts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  type         TEXT NOT NULL CHECK (type IN ('cash', 'bank', 'e-wallet', 'credit')),
  balance      DECIMAL(15,2) NOT NULL DEFAULT 0,
  color        TEXT DEFAULT '#4A90E2',
  icon         TEXT DEFAULT 'wallet',
  is_default   BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. CATEGORIES
-- ============================================================
CREATE TABLE categories (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id   UUID REFERENCES profiles(id) ON DELETE CASCADE, -- NULL = system category
  name         TEXT NOT NULL,
  name_en      TEXT NOT NULL,
  kakeibo_type TEXT NOT NULL CHECK (kakeibo_type IN ('needs', 'wants', 'culture', 'unexpected')),
  icon         TEXT NOT NULL DEFAULT 'category',
  color        TEXT NOT NULL DEFAULT '#888888',
  is_system    BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Default Kakeibo categories (system)
INSERT INTO categories (id, name, name_en, kakeibo_type, icon, color, is_system) VALUES
  -- NEEDS
  (uuid_generate_v4(), 'Makanan & Minuman', 'Food & Drinks', 'needs', 'restaurant', '#E07A5F', TRUE),
  (uuid_generate_v4(), 'Transportasi', 'Transportation', 'needs', 'directions_car', '#3D405B', TRUE),
  (uuid_generate_v4(), 'Tagihan & Utilitas', 'Bills & Utilities', 'needs', 'receipt', '#81B29A', TRUE),
  (uuid_generate_v4(), 'Kesehatan', 'Healthcare', 'needs', 'favorite', '#F2CC8F', TRUE),
  (uuid_generate_v4(), 'Belanja Kebutuhan', 'Groceries', 'needs', 'shopping_cart', '#E07A5F', TRUE),
  -- WANTS
  (uuid_generate_v4(), 'Hiburan', 'Entertainment', 'wants', 'movie', '#F4A261', TRUE),
  (uuid_generate_v4(), 'Fashion', 'Fashion', 'wants', 'checkroom', '#E9C46A', TRUE),
  (uuid_generate_v4(), 'Makan di Luar', 'Dining Out', 'wants', 'dining', '#F4A261', TRUE),
  (uuid_generate_v4(), 'Hobi', 'Hobbies', 'wants', 'sports_esports', '#E9C46A', TRUE),
  -- CULTURE
  (uuid_generate_v4(), 'Buku & Edukasi', 'Books & Education', 'culture', 'menu_book', '#2A9D8F', TRUE),
  (uuid_generate_v4(), 'Kursus & Pelatihan', 'Courses & Training', 'culture', 'school', '#264653', TRUE),
  (uuid_generate_v4(), 'Konser & Event', 'Concerts & Events', 'culture', 'event', '#2A9D8F', TRUE),
  -- UNEXPECTED
  (uuid_generate_v4(), 'Perbaikan Darurat', 'Emergency Repairs', 'unexpected', 'build', '#E76F51', TRUE),
  (uuid_generate_v4(), 'Biaya Tak Terduga', 'Unexpected Costs', 'unexpected', 'warning', '#E76F51', TRUE),
  (uuid_generate_v4(), 'Hadiah & Donasi', 'Gifts & Donations', 'unexpected', 'card_giftcard', '#E9C46A', TRUE);

-- ============================================================
-- 4. TRANSACTIONS
-- ============================================================
CREATE TABLE transactions (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  account_id   UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  category_id  UUID REFERENCES categories(id) ON DELETE SET NULL,
  type         TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  amount       DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  note         TEXT,
  date         DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. SAVINGS GOALS
-- ============================================================
CREATE TABLE savings_goals (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  target_amount   DECIMAL(15,2) NOT NULL CHECK (target_amount > 0),
  current_amount  DECIMAL(15,2) NOT NULL DEFAULT 0,
  target_date     DATE,
  icon            TEXT DEFAULT 'savings',
  color           TEXT DEFAULT '#2A9D8F',
  is_completed    BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 6. WEEKLY REFLECTIONS
-- ============================================================
CREATE TABLE weekly_reflections (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  week_end_date   DATE NOT NULL,
  -- Kakeibo 4 questions
  income_amount      DECIMAL(15,2) DEFAULT 0,
  expense_amount     DECIMAL(15,2) DEFAULT 0,
  savings_amount     DECIMAL(15,2) DEFAULT 0,
  -- Reflection answers
  what_earned        TEXT,  -- Berapa banyak yang saya hasilkan?
  what_spent         TEXT,  -- Berapa banyak yang saya habiskan?
  how_could_improve  TEXT,  -- Bagaimana saya bisa meningkatkan ini?
  savings_goal_note  TEXT,  -- Berapa banyak yang ingin saya tabung?
  mood_score         INTEGER CHECK (mood_score BETWEEN 1 AND 5),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(profile_id, week_start_date)
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_goals     ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_reflections ENABLE ROW LEVEL SECURITY;

-- Profiles: user can only read/update their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Accounts
CREATE POLICY "Users manage own accounts"
  ON accounts FOR ALL USING (auth.uid() = profile_id);

-- Categories: system categories are readable by all, personal by owner
CREATE POLICY "View system categories"
  ON categories FOR SELECT USING (is_system = TRUE OR auth.uid() = profile_id);
CREATE POLICY "Users manage own categories"
  ON categories FOR INSERT WITH CHECK (auth.uid() = profile_id);
CREATE POLICY "Users update own categories"
  ON categories FOR UPDATE USING (auth.uid() = profile_id AND is_system = FALSE);
CREATE POLICY "Users delete own categories"
  ON categories FOR DELETE USING (auth.uid() = profile_id AND is_system = FALSE);

-- Transactions
CREATE POLICY "Users manage own transactions"
  ON transactions FOR ALL USING (auth.uid() = profile_id);

-- Savings Goals
CREATE POLICY "Users manage own savings goals"
  ON savings_goals FOR ALL USING (auth.uid() = profile_id);

-- Weekly Reflections
CREATE POLICY "Users manage own reflections"
  ON weekly_reflections FOR ALL USING (auth.uid() = profile_id);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Update account balance on transaction insert
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.type = 'income' THEN
      UPDATE accounts SET balance = balance + NEW.amount WHERE id = NEW.account_id;
    ELSE
      UPDATE accounts SET balance = balance - NEW.amount WHERE id = NEW.account_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.type = 'income' THEN
      UPDATE accounts SET balance = balance - OLD.amount WHERE id = OLD.account_id;
    ELSE
      UPDATE accounts SET balance = balance + OLD.amount WHERE id = OLD.account_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Revert old
    IF OLD.type = 'income' THEN
      UPDATE accounts SET balance = balance - OLD.amount WHERE id = OLD.account_id;
    ELSE
      UPDATE accounts SET balance = balance + OLD.amount WHERE id = OLD.account_id;
    END IF;
    -- Apply new
    IF NEW.type = 'income' THEN
      UPDATE accounts SET balance = balance + NEW.amount WHERE id = NEW.account_id;
    ELSE
      UPDATE accounts SET balance = balance - NEW.amount WHERE id = NEW.account_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_transaction_change
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW EXECUTE PROCEDURE update_account_balance();

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at();
CREATE TRIGGER update_accounts_updated_at
  BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE PROCEDURE update_updated_at();
CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE PROCEDURE update_updated_at();
CREATE TRIGGER update_savings_goals_updated_at
  BEFORE UPDATE ON savings_goals FOR EACH ROW EXECUTE PROCEDURE update_updated_at();
CREATE TRIGGER update_weekly_reflections_updated_at
  BEFORE UPDATE ON weekly_reflections FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_transactions_profile_id ON transactions(profile_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_date ON transactions(date DESC);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_accounts_profile_id ON accounts(profile_id);
CREATE INDEX idx_savings_goals_profile_id ON savings_goals(profile_id);
CREATE INDEX idx_weekly_reflections_profile_id ON weekly_reflections(profile_id);
CREATE INDEX idx_weekly_reflections_week ON weekly_reflections(week_start_date);
