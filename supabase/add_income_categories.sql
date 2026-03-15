-- ============================================================
-- Tambah kategori pemasukan (income categories)
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- Hapus kategori income lama jika ada
DELETE FROM categories WHERE kakeibo_type = 'income';

-- Insert kategori pemasukan baru
INSERT INTO categories (name, name_en, kakeibo_type, icon, color, is_system) VALUES
  ('Gaji', 'Salary', 'income', 'payments', '#3D6B4F', TRUE),
  ('Freelance', 'Freelance', 'income', 'laptop_mac', '#4A6FA5', TRUE),
  ('Bisnis', 'Business', 'income', 'store', '#B8963A', TRUE),
  ('Investasi', 'Investment', 'income', 'trending_up', '#2A9D8F', TRUE),
  ('Hadiah', 'Gift', 'income', 'card_giftcard', '#8B4F6A', TRUE),
  ('Refund', 'Refund', 'income', 'replay', '#3D405B', TRUE),
  ('Lainnya', 'Other', 'income', 'more_horiz', '#636366', TRUE);

-- Update schema categories untuk support income type
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_kakeibo_type_check;
ALTER TABLE categories ADD CONSTRAINT categories_kakeibo_type_check
  CHECK (kakeibo_type IN ('needs', 'wants', 'culture', 'unexpected', 'income'));

SELECT name, kakeibo_type FROM categories WHERE kakeibo_type = 'income';
