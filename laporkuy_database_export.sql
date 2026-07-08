-- ============================================================================
-- LAPORKUY DATABASE EXPORT
-- ============================================================================
-- Aplikasi     : LaporKuy - E-Ticketing Helpdesk Mobile App
-- Backend      : Supabase (PostgreSQL 15)
-- Versi        : 1.0
-- Tanggal      : 23 Juni 2026
-- Deskripsi    : Full SQL export lengkap dengan tabel, sequence, function,
--                trigger, RLS policy, storage bucket, dan storage policy.
-- ============================================================================
-- CARA IMPORT:
--   1. Buat project Supabase baru
--   2. Buka SQL Editor
--   3. Copy-paste seluruh isi file ini
--   4. Klik RUN
--   5. Setup storage bucket via dashboard (opsional, sudah tersedia via SQL)
-- ============================================================================


-- ============================================================================
-- SECTION 1: EXTENSIONS
-- ============================================================================
-- Pastikan extension yang dibutuhkan sudah aktif

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================================================
-- SECTION 2: CLEANUP (Optional - untuk re-run safety)
-- ============================================================================
-- Hapus objek yang sudah ada agar tidak konflik saat re-run

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trg_generate_ticket_number ON public.tickets;
DROP TRIGGER IF EXISTS trg_update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS trg_update_tickets_updated_at ON public.tickets;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.generate_ticket_number() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_role(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.reset_password_with_old(TEXT, TEXT, TEXT) CASCADE;

DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.ticket_history CASCADE;
DROP TABLE IF EXISTS public.ticket_comments CASCADE;
DROP TABLE IF EXISTS public.tickets CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP SEQUENCE IF EXISTS public.ticket_number_seq CASCADE;


-- ============================================================================
-- SECTION 3: TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: public.profiles
-- Deskripsi: Extend auth.users dengan data profile user aplikasi
-- ----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user'
    CHECK (role IN ('user', 'admin', 'helpdesk')),
  phone TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Data profile user aplikasi LaporKuy';
COMMENT ON COLUMN public.profiles.id IS 'UUID, FK ke auth.users';
COMMENT ON COLUMN public.profiles.role IS 'Role user: user, admin, atau helpdesk';

-- Indexes untuk profiles
CREATE INDEX idx_profiles_username ON public.profiles(username);
CREATE INDEX idx_profiles_role ON public.profiles(role);


-- ----------------------------------------------------------------------------
-- TABLE: public.tickets
-- Deskripsi: Data tiket pelaporan
-- ----------------------------------------------------------------------------
CREATE TABLE public.tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'Medium'
    CHECK (priority IN ('Low', 'Medium', 'High')),
  status TEXT NOT NULL DEFAULT 'Open'
    CHECK (status IN ('Open', 'Assigned', 'In Progress', 'Resolved', 'Closed')),
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  attachment_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.tickets IS 'Data tiket pelaporan LaporKuy';
COMMENT ON COLUMN public.tickets.ticket_number IS 'Format TKT-XXX, auto-generated via trigger';
COMMENT ON COLUMN public.tickets.status IS 'Status tiket dalam workflow';

-- Indexes untuk tickets
CREATE INDEX idx_tickets_created_by ON public.tickets(created_by);
CREATE INDEX idx_tickets_assigned_to ON public.tickets(assigned_to);
CREATE INDEX idx_tickets_status ON public.tickets(status);
CREATE INDEX idx_tickets_created_at ON public.tickets(created_at DESC);


-- ----------------------------------------------------------------------------
-- TABLE: public.ticket_comments
-- Deskripsi: Komentar pada tiket
-- ----------------------------------------------------------------------------
CREATE TABLE public.ticket_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.ticket_comments IS 'Komentar/reply pada tiket';

-- Indexes untuk ticket_comments
CREATE INDEX idx_comments_ticket ON public.ticket_comments(ticket_id);


-- ----------------------------------------------------------------------------
-- TABLE: public.ticket_history
-- Deskripsi: Timeline riwayat aksi pada tiket
-- ----------------------------------------------------------------------------
CREATE TABLE public.ticket_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.ticket_history IS 'Timeline aksi pada tiket (audit trail)';
COMMENT ON COLUMN public.ticket_history.action IS 'Created, Assigned, Status Changed, Commented';

-- Indexes untuk ticket_history
CREATE INDEX idx_history_ticket ON public.ticket_history(ticket_id);


-- ----------------------------------------------------------------------------
-- TABLE: public.notifications
-- Deskripsi: Notifikasi untuk user
-- ----------------------------------------------------------------------------
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  ticket_id UUID REFERENCES public.tickets(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS 'Notifikasi in-app untuk user';

-- Indexes untuk notifications
CREATE INDEX idx_notifications_user ON public.notifications(user_id);


-- ============================================================================
-- SECTION 4: SEQUENCES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SEQUENCE: ticket_number_seq
-- Deskripsi: Auto-increment counter untuk nomor tiket
-- ----------------------------------------------------------------------------
CREATE SEQUENCE public.ticket_number_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

COMMENT ON SEQUENCE public.ticket_number_seq IS 'Counter untuk generate ticket_number TKT-XXX';


-- ============================================================================
-- SECTION 5: FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FUNCTION: public.generate_ticket_number()
-- Deskripsi: Auto-generate ticket number saat insert tiket
-- Trigger  : BEFORE INSERT pada tickets
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.ticket_number IS NULL OR NEW.ticket_number = '' THEN
    NEW.ticket_number := 'TKT-' || LPAD(
      nextval('public.ticket_number_seq')::TEXT,
      3,
      '0'
    );
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.generate_ticket_number() IS 'Auto-generate nomor tiket format TKT-XXX';


-- ----------------------------------------------------------------------------
-- FUNCTION: public.handle_new_user()
-- Deskripsi: Auto-create profile saat user register di auth.users
-- Trigger  : AFTER INSERT pada auth.users
-- Security : SECURITY DEFINER (bypass RLS)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  suffix INT := 0;
BEGIN
  -- Tentukan base username dari metadata atau email prefix
  base_username := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'username'), ''),
    SPLIT_PART(NEW.email, '@', 1)
  );
  final_username := base_username;

  -- Loop sampai username unik (handle collision)
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
    suffix := suffix + 1;
    final_username := base_username || suffix::TEXT;
  END LOOP;

  -- Insert profile baru
  INSERT INTO public.profiles (id, username, email, full_name, role, phone)
  VALUES (
    NEW.id,
    final_username,
    NEW.email,
    COALESCE(
      NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''),
      base_username
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    NULLIF(TRIM(NEW.raw_user_meta_data->>'phone'), '')
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log warning tanpa membatalkan signup
  RAISE WARNING 'handle_new_user error for %: %', NEW.email, SQLERRM;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS 'Auto-create profile saat user register, handle username collision';


-- ----------------------------------------------------------------------------
-- FUNCTION: public.update_updated_at()
-- Deskripsi: Auto-update kolom updated_at ke NOW() saat UPDATE
-- Trigger  : BEFORE UPDATE pada profiles dan tickets
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.update_updated_at() IS 'Auto-update timestamp updated_at';


-- ----------------------------------------------------------------------------
-- FUNCTION: public.get_user_role(user_id UUID)
-- Deskripsi: Helper function untuk mendapatkan role user (dipakai RLS)
-- Security : SECURITY DEFINER, STABLE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = user_id LIMIT 1;
$$;

COMMENT ON FUNCTION public.get_user_role(UUID) IS 'Helper untuk RLS: ambil role user berdasarkan ID';


-- ----------------------------------------------------------------------------
-- FUNCTION: public.reset_password_with_old()
-- Deskripsi: Reset password dengan verifikasi password lama
-- Type     : RPC (dipanggil dari client)
-- Security : SECURITY DEFINER
-- Return   : JSON {success, message}
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reset_password_with_old(
  user_email TEXT,
  old_password TEXT,
  new_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  target_user_id UUID;
  stored_password TEXT;
BEGIN
  -- Validasi panjang password baru
  IF LENGTH(new_password) < 6 THEN
    RETURN json_build_object('success', false, 'message', 'Password baru minimal 6 karakter');
  END IF;

  -- Cari user berdasarkan email
  SELECT id, encrypted_password INTO target_user_id, stored_password
  FROM auth.users
  WHERE email = LOWER(user_email)
  LIMIT 1;

  IF target_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Email tidak terdaftar');
  END IF;

  -- Verifikasi password lama
  IF stored_password != extensions.crypt(old_password, stored_password) THEN
    RETURN json_build_object('success', false, 'message', 'Password lama salah');
  END IF;

  -- Update password baru dengan bcrypt hash
  UPDATE auth.users
  SET
    encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
    updated_at = NOW()
  WHERE id = target_user_id;

  RETURN json_build_object('success', true, 'message', 'Password berhasil direset');
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'message', SQLERRM);
END;
$$;

COMMENT ON FUNCTION public.reset_password_with_old(TEXT, TEXT, TEXT) IS 'Reset password dengan verifikasi password lama via RPC';

-- Grant permission agar bisa dipanggil dari client
GRANT EXECUTE ON FUNCTION public.reset_password_with_old(TEXT, TEXT, TEXT) TO anon, authenticated;


-- ============================================================================
-- SECTION 6: TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER: on_auth_user_created
-- Table  : auth.users
-- Event  : AFTER INSERT
-- Action : Panggil handle_new_user() untuk create profile
-- ----------------------------------------------------------------------------
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();


-- ----------------------------------------------------------------------------
-- TRIGGER: trg_generate_ticket_number
-- Table  : public.tickets
-- Event  : BEFORE INSERT
-- Action : Panggil generate_ticket_number() untuk generate TKT-XXX
-- ----------------------------------------------------------------------------
CREATE TRIGGER trg_generate_ticket_number
BEFORE INSERT ON public.tickets
FOR EACH ROW
EXECUTE FUNCTION public.generate_ticket_number();


-- ----------------------------------------------------------------------------
-- TRIGGER: trg_update_profiles_updated_at
-- Table  : public.profiles
-- Event  : BEFORE UPDATE
-- Action : Auto-update kolom updated_at
-- ----------------------------------------------------------------------------
CREATE TRIGGER trg_update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


-- ----------------------------------------------------------------------------
-- TRIGGER: trg_update_tickets_updated_at
-- Table  : public.tickets
-- Event  : BEFORE UPDATE
-- Action : Auto-update kolom updated_at
-- ----------------------------------------------------------------------------
CREATE TRIGGER trg_update_tickets_updated_at
BEFORE UPDATE ON public.tickets
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


-- ============================================================================
-- SECTION 7: ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Enable RLS pada semua tabel di schema public
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;


-- ----------------------------------------------------------------------------
-- RLS POLICIES: public.profiles
-- ----------------------------------------------------------------------------

-- SELECT: Semua authenticated user bisa lihat semua profile
CREATE POLICY "Profiles viewable by authenticated users"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- UPDATE: User hanya bisa update profile sendiri
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- UPDATE: Admin bisa update siapa saja (untuk fitur Kelola User)
CREATE POLICY "Admins can update any profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (public.get_user_role(auth.uid()) = 'admin')
WITH CHECK (public.get_user_role(auth.uid()) = 'admin');


-- ----------------------------------------------------------------------------
-- RLS POLICIES: public.tickets
-- ----------------------------------------------------------------------------

-- SELECT: Admin all, Helpdesk assigned, User own
CREATE POLICY "Tickets visibility by role"
ON public.tickets FOR SELECT
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
  OR (public.get_user_role(auth.uid()) = 'helpdesk' AND assigned_to = auth.uid())
  OR created_by = auth.uid()
);

-- INSERT: User bisa buat tiket untuk dirinya sendiri
CREATE POLICY "Users can create tickets"
ON public.tickets FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- UPDATE: Admin, helpdesk yang assigned, atau creator
CREATE POLICY "Tickets can be updated by admin or assigned helpdesk"
ON public.tickets FOR UPDATE
TO authenticated
USING (
  public.get_user_role(auth.uid()) = 'admin'
  OR (public.get_user_role(auth.uid()) = 'helpdesk' AND assigned_to = auth.uid())
  OR created_by = auth.uid()
);


-- ----------------------------------------------------------------------------
-- RLS POLICIES: public.ticket_comments
-- ----------------------------------------------------------------------------

-- SELECT: Hanya user yang punya akses ke tiket
CREATE POLICY "Comments viewable by ticket viewers"
ON public.ticket_comments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.tickets t
    WHERE t.id = ticket_id
    AND (
      public.get_user_role(auth.uid()) = 'admin'
      OR (public.get_user_role(auth.uid()) = 'helpdesk' AND t.assigned_to = auth.uid())
      OR t.created_by = auth.uid()
    )
  )
);

-- INSERT: User authenticated bisa komentar (dengan user_id sendiri)
CREATE POLICY "Authenticated users can comment"
ON public.ticket_comments FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());


-- ----------------------------------------------------------------------------
-- RLS POLICIES: public.ticket_history
-- ----------------------------------------------------------------------------

-- SELECT: Hanya user yang punya akses ke tiket
CREATE POLICY "History viewable by ticket viewers"
ON public.ticket_history FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.tickets t
    WHERE t.id = ticket_id
    AND (
      public.get_user_role(auth.uid()) = 'admin'
      OR (public.get_user_role(auth.uid()) = 'helpdesk' AND t.assigned_to = auth.uid())
      OR t.created_by = auth.uid()
    )
  )
);

-- INSERT: User authenticated bisa insert history (dengan user_id sendiri)
CREATE POLICY "Authenticated users can insert history"
ON public.ticket_history FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());


-- ----------------------------------------------------------------------------
-- RLS POLICIES: public.notifications
-- ----------------------------------------------------------------------------

-- SELECT: User hanya lihat notif miliknya
CREATE POLICY "Users see own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- INSERT: Authenticated user siapa saja bisa insert (untuk broadcast)
CREATE POLICY "Authenticated users can insert notifications"
ON public.notifications FOR INSERT
TO authenticated
WITH CHECK (true);

-- UPDATE: User hanya bisa update notif sendiri (mark as read)
CREATE POLICY "Users update own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid());


-- ============================================================================
-- SECTION 8: STORAGE BUCKETS
-- ============================================================================
-- Note: Bucket bisa dibuat via SQL atau dashboard Supabase.
-- Berikut cara membuat via SQL:

-- ----------------------------------------------------------------------------
-- BUCKET: avatars (public)
-- Deskripsi: Menyimpan foto profil user
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,  -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- BUCKET: attachments (public)
-- Deskripsi: Menyimpan lampiran tiket
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'attachments',
  'attachments',
  true,
  10485760,  -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- SECTION 9: STORAGE POLICIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STORAGE POLICIES: avatars bucket
-- ----------------------------------------------------------------------------

-- SELECT: Public viewable
DROP POLICY IF EXISTS "Avatars publicly viewable" ON storage.objects;
CREATE POLICY "Avatars publicly viewable"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- INSERT: Authenticated bisa upload
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- UPDATE: Owner only (berdasarkan folder userId)
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- DELETE: Owner only
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);


-- ----------------------------------------------------------------------------
-- STORAGE POLICIES: attachments bucket
-- ----------------------------------------------------------------------------

-- SELECT: Public viewable
DROP POLICY IF EXISTS "Attachments publicly viewable" ON storage.objects;
CREATE POLICY "Attachments publicly viewable"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'attachments');

-- INSERT: Authenticated bisa upload
DROP POLICY IF EXISTS "Authenticated users can upload attachments" ON storage.objects;
CREATE POLICY "Authenticated users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- UPDATE: Owner only
DROP POLICY IF EXISTS "Users can update own attachment" ON storage.objects;
CREATE POLICY "Users can update own attachment"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'attachments'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- DELETE: Owner only
DROP POLICY IF EXISTS "Users can delete own attachment" ON storage.objects;
CREATE POLICY "Users can delete own attachment"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments'
  AND auth.uid()::text = (storage.foldername(name))[1]
);


-- ============================================================================
-- SECTION 10: SEED DATA (Opsional - untuk testing)
-- ============================================================================
-- CATATAN PENTING:
-- User seed HARUS dibuat via Supabase Dashboard (Authentication > Users)
-- atau via Auth API, tidak bisa langsung INSERT ke auth.users.
--
-- Setelah user dibuat via dashboard dengan email berikut:
--   1. admin@laporkuy.com (password: admin123)
--   2. helpdesk1@laporkuy.com (password: help123)
--   3. helpdesk2@laporkuy.com (password: help123)
--
-- Jalankan query berikut untuk update role mereka:

/*
UPDATE public.profiles
SET role = 'admin',
    full_name = 'Administrator',
    username = 'admin'
WHERE email = 'admin@laporkuy.com';

UPDATE public.profiles
SET role = 'helpdesk',
    full_name = 'Budi Helpdesk',
    username = 'helpdesk1'
WHERE email = 'helpdesk1@laporkuy.com';

UPDATE public.profiles
SET role = 'helpdesk',
    full_name = 'Siti Helpdesk',
    username = 'helpdesk2'
WHERE email = 'helpdesk2@laporkuy.com';
*/


-- ============================================================================
-- SECTION 11: VERIFIKASI (Query untuk cek hasil setup)
-- ============================================================================

-- Cek semua tabel yang terbentuk
/*
SELECT table_name,
       (SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = t.table_name) AS total_columns
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
*/

-- Cek semua function yang terbentuk
/*
SELECT routine_name, routine_type, data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;
*/

-- Cek semua trigger yang aktif
/*
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema IN ('public', 'auth')
ORDER BY event_object_table;
*/

-- Cek semua RLS policy
/*
SELECT schemaname, tablename, policyname, cmd AS operation
FROM pg_policies
WHERE schemaname IN ('public', 'storage')
ORDER BY tablename, policyname;
*/

-- Cek semua foreign key
/*
SELECT
  tc.table_name AS from_table,
  kcu.column_name AS from_column,
  ccu.table_name AS to_table,
  ccu.column_name AS to_column,
  rc.delete_rule AS on_delete
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;
*/

-- Cek storage bucket
/*
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE id IN ('avatars', 'attachments');
*/


-- ============================================================================
-- END OF EXPORT
-- ============================================================================
-- Total objek yang dibuat:
--   ✓ 5 Tables (profiles, tickets, ticket_comments, ticket_history, notifications)
--   ✓ 1 Sequence (ticket_number_seq)
--   ✓ 5 Functions (generate_ticket_number, handle_new_user, update_updated_at,
--                  get_user_role, reset_password_with_old)
--   ✓ 4 Triggers (on_auth_user_created, trg_generate_ticket_number,
--                 trg_update_profiles_updated_at, trg_update_tickets_updated_at)
--   ✓ 9 Indexes
--   ✓ 13 RLS Policies (untuk public schema)
--   ✓ 2 Storage Buckets (avatars, attachments)
--   ✓ 8 Storage Policies
-- ============================================================================
