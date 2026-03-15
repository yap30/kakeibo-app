# 🏮 Kakeibo App — Flutter + Supabase

> Aplikasi pencatat keuangan pribadi berbasis metode budgeting Jepang, **Kakeibo (家計簿)**

---

## 📁 Struktur Folder

```
lib/
├── main.dart                          # Entry point
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Color palette, typography, KakeiboTypeConfig
│   ├── router/
│   │   └── app_router.dart            # GoRouter setup + auth guard
│   ├── shell/
│   │   └── main_shell.dart            # Bottom navigation shell
│   └── extensions/
│       └── currency_extension.dart    # toRupiah() helper
│
└── features/
    ├── auth/
    │   └── presentation/pages/
    │       └── auth_pages.dart        # Login & Register
    │
    ├── dashboard/
    │   └── presentation/
    │       ├── pages/dashboard_page.dart
    │       └── providers/providers.dart   # ALL Riverpod providers (central)
    │
    ├── transactions/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── supabase_datasource.dart   # API calls
    │   │   ├── models/
    │   │   │   └── models.dart                # JSON serialization
    │   │   └── repositories/
    │   │       └── repositories.dart          # Business logic + Either<>
    │   ├── domain/
    │   │   └── entities/
    │   │       └── entities.dart              # ALL domain entities
    │   └── presentation/pages/
    │       ├── add_transaction_page.dart      # <3 detik UX
    │       └── transaction_history_page.dart
    │
    ├── savings/
    │   └── presentation/pages/
    │       └── savings_page.dart
    │
    ├── reflections/
    │   └── presentation/pages/
    │       └── reflection_page.dart          # 4 pertanyaan Kakeibo
    │
    └── profile/
        └── presentation/pages/
            └── profile_page.dart

supabase/
└── schema.sql                               # Database schema lengkap
```

---

## 🗄️ Database Schema

### Tabel Utama
| Tabel | Deskripsi |
|-------|-----------|
| `profiles` | Data pengguna (extends auth.users) |
| `accounts` | Akun keuangan (cash, bank, e-wallet, credit) |
| `categories` | Kategori transaksi — system + custom |
| `transactions` | Catatan pemasukan & pengeluaran |
| `savings_goals` | Target tabungan |
| `weekly_reflections` | Refleksi mingguan Kakeibo |

### 4 Kategori Kakeibo
| Tipe | Kanji | Warna | Deskripsi |
|------|-------|-------|-----------|
| `needs` | 必要 | Hijau Forest | Kebutuhan wajib |
| `wants` | 欲しい | Terracotta | Keinginan |
| `culture` | 文化 | Indigo | Pengembangan diri |
| `unexpected` | 予期せぬ | Amber | Tak terduga |

---

## 🚀 Quick Start

### 1. Setup Supabase
```bash
# Buat project di supabase.com
# Jalankan schema.sql di SQL Editor Supabase
```

### 2. Setup Flutter
```bash
flutter pub get
```

### 3. Konfigurasi environment
```bash
# Method 1: --dart-define (recommended)
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# Method 2: Edit langsung di main.dart (development only)
```

### 4. Build & Run
```bash
flutter run
flutter build apk --release
flutter build ios --release
```

---

## 🏗️ Arsitektur

### Clean Architecture (3 Layer)

```
Presentation  →  Domain  →  Data
(Riverpod)      (Entity)   (Supabase)
```

**Data Flow:**
```
UI Widget
  → ref.watch(provider)
    → Repository
      → Supabase DataSource
        → Supabase REST API
          → PostgreSQL
```

### State Management (Riverpod)
```dart
// Provider hierarchy:
supabaseClientProvider           // SupabaseClient instance
  → datasource providers         // Raw API access
    → repository providers       // Business logic + Either<Failure, T>
      → data providers           // FutureProvider for UI
        → UI widgets             // ref.watch()
```

---

## 🔐 Authentication Flow

```
App Start
  → GoRouter redirect check
    → authStateProvider (Stream<AuthState>)
      → Not logged in → /login
      → Logged in     → /dashboard
```

```dart
// Supabase Auth usage
await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);
// GoRouter auto-redirects via authStateProvider stream
```

---

## 💰 Currency Extension

```dart
// Usage
double amount = 1500000;
amount.toRupiah()              // → "Rp1.500.000"
amount.toRupiah(compact: true) // → "Rp1,5jt"
amount.toRupiah(showSymbol: false) // → "1.500.000"
```

---

## 📱 Screens

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| Login | `/login` | Supabase email auth |
| Register | `/register` | Sign up + email konfirmasi |
| Dashboard | `/dashboard` | Summary + Kakeibo breakdown |
| History | `/history` | Timeline transaksi by date |
| Savings | `/savings` | Target tabungan + progress |
| Reflection | `/reflect` | 4 pertanyaan Kakeibo mingguan |
| Profile | `/profile` | Akun & pengaturan |
| Add Transaction | `/add-transaction` | Modal - < 3 detik UX |

---

## ⚡ Performance Notes

### Add Transaction UX (<3 detik target)
- Custom numpad (tidak perlu buka keyboard)
- Horizontal scroll category picker
- Satu tap untuk pilih kategori
- Submit langsung tanpa konfirmasi dialog

### Data Fetching
- Semua query menggunakan Supabase **JOIN** (1 request untuk transactions + category + account)
- Provider auto-invalidate setelah mutasi
- `FutureProvider` dengan proper loading/error states

---

## 🎨 Design System

### Colors (Japanese Aesthetic)
```dart
KakeiboColors.ink      // #1C1C1E - Sumi Ink (墨)
KakeiboColors.paper    // #F5F0E8 - Washi Paper (和紙)
KakeiboColors.needs    // #3D6B4F - Forest Green
KakeiboColors.wants    // #B85C3A - Terracotta
KakeiboColors.culture  // #4A6FA5 - Indigo Blue
KakeiboColors.unexpected // #B8963A - Amber Gold
```

### Typography
- **Heading/Display**: NotoSerifJP (nuansa Jepang)
- **Body/Label**: Inter (modern & readable)

---

## 📦 Dependencies

```yaml
# Core
supabase_flutter: ^2.3.0    # Backend
flutter_riverpod: ^2.4.9    # State management
go_router: ^13.0.0          # Navigation

# UI
fl_chart: ^0.67.0           # Charts (dashboard)
shimmer: ^3.0.0             # Skeleton loading

# Utils
dartz: ^0.10.1              # Either<Failure, T>
intl: ^0.19.0               # Currency & date format
```

---

## 🔄 Menambah Fitur Baru

### Contoh: Tambah Export PDF
```dart
// 1. Tambah use case di domain layer
class ExportTransactionsUseCase {
  Future<Either<Failure, File>> call(DateTime month) { ... }
}

// 2. Tambah provider
final exportProvider = FutureProvider.family<File, DateTime>((ref, month) async {
  final useCase = ref.watch(exportUseCaseProvider);
  final result = await useCase.call(month);
  return result.fold((l) => throw l.message, (r) => r);
});

// 3. Trigger dari UI
ref.read(exportProvider(selectedMonth));
```

---

## 🌱 Roadmap

- [ ] Push notification pengingat harian
- [ ] Export data CSV / PDF
- [ ] Widget home screen (balance summary)
- [ ] Multi-currency support
- [ ] Recurring transactions
- [ ] Budget per kategori dengan alert
- [ ] Dark mode
- [ ] Backup & sync cloud
