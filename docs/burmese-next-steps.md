# Termux Command Library — ၁၀၀% အလုပ်ဖြစ်ရန် ကျန်ရှိသော လုပ်ငန်းများ

> **ဤစာတမ်းကို မည်သူ့အတွက် ရေးထားသနည်း။**
> ဤ repository ကို clone လုပ်ပြီး ကိုယ်ပိုင် Firebase project ဖြင့်
> app ကို အပြည့်အဝ အလုပ်ဖြစ်အောင် လုပ်မည့်သူအတွက် ဖြစ်သည်။
> ယေဘုယျ setup လမ်းညွှန် မဟုတ်ပါ။ **လက်ရှိ code ၏ တကယ့်အခြေအနေ**
> ကို အခြေခံပြီး ဘာကျန်သေးသည်ကို တစ်ဆင့်ချင်း ရှင်းပြထားသည်။

| အချက် | တန်ဖိုး |
| --- | --- |
| စစ်ဆေးသည့်ရက်စွဲ | ၂၀၂၆ ခုနှစ်၊ အောက်တိုဘာ ၂၇ ရက် |
| App version | `1.0.0+1` |
| Commit | `main` branch (နောက်ဆုံး commit ကို GitHub တွင် ကြည့်ပါ) |
| GitHub repository | <https://github.com/minkhantthu2692-gif/termux-command-library-app> |
| Firebase project | `termuxcommandlibrary` |
| Android package | `com.termuxcommandlibrary.mm` |

---

## ၀။ အနှစ်ချုပ် — ဘာလုပ်ရမည်ကို အရင်ကြည့်ပါ

အောက်ပါအစီအစဉ်အတိုင်း လုပ်ပါ။ အပေါ်ဆုံးအဆင့်များကို မပြီးမချင်း
app သည် "local-only" mode တွင်သာ ရှိနေမည်။

| အစီအစဉ် | လုပ်ငန်း | အခြေအနေ |
| --- | --- | --- |
| ၁ | Firebase Authentication provider များ ဖွင့်ခြင်း | ✅ ပြီး (လေးခုလုံး) |
| ၂ | Google SHA-1/SHA-256 ထည့်ပြီး JSON အသစ်ရယူခြင်း | ✅ SHA-1 ပြီး |
| ၃ | GitHub OAuth App ဖန်တီးခြင်း | ✅ ပြီး (provider ဖွင့်ပြီး) |
| ၄ | Firestore Database ဖန်တီးခြင်း | ✅ ပြီး |
| ၅ | Rules နှင့် Indexes deploy လုပ်ခြင်း | ✅ ပြီး (index များ build ဆဲ) |
| ၆ | ပြန် build လုပ်ပြီး စက်ထဲ ထည့်ခြင်း | 🟡 build ပြီး၊ install မရသေး |
| ၇ | စက်ပေါ်တွင် စမ်းသပ်ခြင်း | ⬜ မရသေး |
| ၈ | Termux ပြင်ဆင်ခြင်း | ⬜ မရသေး |
| ၉ | Groq API ကီး ထည့်ခြင်း | ⬜ ရွေးချယ်နိုင် |
| ၁၀ | Admin custom claim သတ်မှတ်ခြင်း | ⬜ ရွေးချယ်နိုင် |
| ၁၁ | Release keystore ဖြင့် လက်မှတ်ထိုးခြင်း | ⬜ ဖြန့်ဝေမှသာ |

> **အရေးကြီး:** Firebase ချိတ်ဆက်မှု (provider များ၊ Firestore၊ rules၊
> indexes) ကို ပြီးစီးထားပြီးဖြစ်သည်။ ကျန်ရှိသော စက်ပေါ်စမ်းသပ်မှု၊
> Termux၊ Groq နှင့် release keystore ကို သင်ကိုယ်တိုင် လုပ်ရမည်။
> လျှို့ဝှက် credential များကို chat ထဲ မပို့ပါနှင့်။

---

## ၁။ လက်ရှိ အတည်ပြုပြီးသော အခြေအနေ

အောက်ပါအချက်များကို ဤ machine တွင် တကယ် run ပြီး စစ်ဆေးထားသည်။

| အချက် | အခြေအနေ | အသေးစိတ် |
| --- | --- | --- |
| Source code | ✅ ပြီး | TODO/FIXME မရှိ၊ feature အားလုံး ရေးထားပြီး |
| Static analysis | ✅ ပြီး | `flutter analyze` — ပြဿနာ မတွေ့ |
| Test များ | ✅ ပြီး | `flutter test` — 154/154 အောင် |
| Debug APK build | ✅ ပြီး | `app-debug.apk` (216.7 MB) |
| Release APK build | ✅ ပြီး | `app-release.apk` (70.4 MB) — debug key ဖြင့် |
| Native Kotlin haptics | ✅ compile အောင် | `HapticsController.class` APK ထဲ ပါဝင် |
| GitHub push | ✅ ပြီး | `origin/main` |
| Firebase project ချိတ်ဆက်မှု | ✅ ဖိုင် ရှိ | `google-services.json` package ကိုက်ညီ |
| Firebase CLI | ✅ ဝင်ပြီး | `minkhantthu2692@gmail.com` |
| Auth provider များ | ✅ ဖွင့်ပြီး | Email၊ Anonymous၊ Google၊ GitHub |
| Google SHA-1 လက်ဗွေ | ✅ ပါပြီ | JSON ထဲတွင် Android OAuth client ပါပြီ |
| Google SHA-256 လက်ဗွေ | ⚠️ မစစ်ရသေး | JSON တွင် မပါပါ (ပုံမှန်)။ Console တွင် စစ်ပါ |
| Firestore database | ✅ ရှိ | `(default)`၊ Firestore Native |
| Rules နှင့် Indexes | ✅ deploy ပြီး | index နှစ်ခု build ဆဲ (CREATING) |
| Release signing | ❌ မပါ | လက်ရှိ release သည် debug key သုံးထား |
| စက်ပေါ် စမ်းသပ်မှု | ❌ မရသေး | Android device မချိတ်ထား |
| Groq API ကီး | ❌ မရသေး | သင့်ကိုယ်ပိုင် ကီး ထည့်ရမည် |

**အနှစ်ချုပ်:** code၊ ဒေသတွင်း (offline) အလုပ်လုပ်မှု၊ Firebase project
ချိတ်ဆက်မှု၊ auth provider များ၊ Firestore rules/indexes နှင့် APK
build များ အားလုံး ပြီးစီးထားသည်။ ကျန်သည်မှာ **စက်အစစ်ပေါ်တွင်
အတည်ပြုခြင်း**၊ **Termux ပြင်ဆင်ခြင်း**၊ **Groq ကီး** နှင့်
**release keystore** သာ ဖြစ်သည်။

---

## ၂။ အဆင့် ၁ — Firebase Authentication ဖွင့်ခြင်း

> **လက်ရှိ အခြေအနေ:** ဤ project တွင် provider လေးခုလုံး
> (Email/Password၊ Anonymous၊ Google၊ GitHub) ဖွင့်ပြီးဖြစ်သည်။
> အောက်ပါအဆင့်များကို အခြား project အတွက် လိုအပ်မှသာ လုပ်ပါ။

### ၂.၁ Console သို့ ဝင်ခြင်း

1. <https://console.firebase.google.com> သို့ ဖွင့်ပါ။
2. Project `termuxcommandlibrary` ကို ရွေးပါ။
   (မတွေ့လျှင် သင့်အကောင့်တွင် ထို project မရှိသေးပါ။
   `android/app/google-services.json` ထဲမှ `project_id` နှင့်
   တူညီသော project ကို ဖန်တီးပါ။)
3. ဘယ်ဘက် menu မှ **Authentication** → **Get started** ကို နှိပ်ပါ။

### ၂.၂ Provider တစ်ခုချင်း ဖွင့်ခြင်း

**Email/Password** (မဖြစ်မနေ)

1. **Sign-in method** tab → **Email/Password** ကို နှိပ်ပါ။
2. **Enable** ကို ဖွင့်ပါ။ **Email link (passwordless)** ကို
   မဖွင့်ပါနှင့် — app က မသုံးပါ။
3. **Save** နှိပ်ပါ။

**Anonymous** (မဖြစ်မနေ)

1. **Sign-in method** → **Anonymous** ကို နှိပ်ပါ။
2. **Enable** ဖွင့်ပြီး **Save** နှိပ်ပါ။

> Anonymous မဖွင့်ထားလျှင် app ကို ပထမဆုံး ဖွင့်ချိန်တွင်
> guest session ဖန်တီး၍ မရပါ။ ထိုအခါ local-only mode သို့
> ကျသွားမည်။

**Google** (Google ဖြင့် ဝင်လိုမှသာ)

1. **Sign-in method** → **Google** → **Enable** ဖွင့်ပါ။
2. **Project support email** ကို ရွေးပါ။
3. **Save** နှိပ်ပါ။
4. ထို့နောက် အောက်ပါ **အဆင့် ၂** တွင် SHA လက်ဗွေ ထည့်ပါ။
   SHA မပါဘဲ Google ဝင်ရောက်မှု မအောင်မြင်နိုင်ပါ။

**GitHub** (GitHub ဖြင့် ဝင်လိုမှသာ)

1. အောက်ပါ **အဆင့် ၃** တွင် OAuth App ကို အရင် ဖန်တီးပါ။
2. ရရှိသော **Client ID** နှင့် **Client secret** ကို
   **Authentication → Sign-in method → GitHub** တွင် ထည့်ပါ။
3. **Enable** ဖွင့်ပြီး **Save** နှိပ်ပါ။

### ၂.၃ စစ်ဆေးရန်

- [ ] Authentication → **Users** tab တွင် အနည်းဆုံး user တစ်ခု ရှိသည်။
- [ ] **Sign-in method** တွင် ဖွင့်ထားသော provider များ
      "Enabled" ဟု ပြသည်။
- [ ] App ထဲတွင် **Create account** မျက်နှာပြင်ကို ဖွင့်ပြီး
      Email/Password ဖြင့် စာရင်းသွင်းနိုင်သည်။
- [ ] Sign out လုပ်ပြီး ပြန်ဝင်နိုင်သည်။
- [ ] Password reset email ရသည်။

---

## ၃။ အဆင့် ၂ — SHA-1/SHA-256 လက်ဗွေ ထည့်ခြင်း

### ၃.၁ လက်ရှိ အခြေအနေ

`android/app/google-services.json` တွင် **Android OAuth client**
(`client_type: 1`) ပါပြီဖြစ်ပြီး ၎င်း၏ `certificate_hash` သည်
debug SHA-1 နှင့် ကိုက်ညီသည်။ ထို့ကြောင့် **SHA-1 ကို ထည့်ပြီးဖြစ်သည်**။

မှတ်ချက်: `google-services.json` တွင် SHA-1 ကိုသာ ပြသည်။
SHA-256 ကို ဖိုင်ထဲတွင် မတွေ့ရပါ — ၎င်းသည် ပုံမှန်ဖြစ်သည်။
SHA-256 ထည့်ထားခြင်း ရှိ/မရှိကို Console ၏
**Project settings → Your apps → SHA certificate fingerprints**
တွင် စစ်ပါ။

စက်အသစ် သို့မဟုတ် keystore အသစ်အတွက် အောက်ပါအတိုင်း
လက်ဗွေ ပြန်ယူပါ။

### ၃.၂ Debug လက်ဗွေ ရယူခြင်း (Windows)

PowerShell ကို ဖွင့်ပြီး:

```powershell
keytool -list -v `
  -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -keypass android
```

ထွက်လာသော output ထဲမှ အောက်ပါတို့ကို ကူးယူပါ:

```text
SHA1: XX:XX:...
SHA256: XX:XX:...
```

`keytool` မတွေ့လျှင် JDK 17 ၏ `bin` folder ကို PATH ထဲ
ထည့်ပါ (ဥပမာ `C:\Program Files\Java\jdk-17\bin`)။

### ၃.၃ Console တွင် ထည့်ခြင်း

1. Firebase Console → ⚙️ **Project settings** → **Your apps**။
2. Android app `com.termuxcommandlibrary.mm` ကို ရွေးပါ။
3. **Add fingerprint** ကို နှိပ်ပြီး SHA-1 ကို ထည့်ပါ။
4. ထပ်နှိပ်ပြီး SHA-256 ကို ထည့်ပါ။
5. **Save** နှိပ်ပါ။
6. **google-services.json** ကို **ပြန် download** လုပ်ပါ။
7. ရလာသော ဖိုင်ဖြင့် `android/app/google-services.json` ကို
   **အစားထိုး** ပါ။

> ဖိုင်အဟောင်းဖြင့် build ထားသော APK တွင် SHA အသစ် မပါပါ။
> **ပြန် build လုပ်ရမည်။** Hot reload ဖြင့် မရပါ။

### ၃.၄ Release လက်ဗွေ (ဖြန့်ဝေမည်ဆိုမှ)

Release keystore ကို **အဆင့် ၁၁** တွင် ဖန်တီးပြီးမှ:

```powershell
keytool -list -v -alias upload -keystore android\upload-keystore.jks
```

ရလာသော SHA-1/SHA-256 ကိုလည်း Console တွင် ထည့်ပါ။
မထည့်လျှင် release APK တွင် Google Sign-In မအောင်မြင်ပါ။

---

## ၄။ အဆင့် ၃ — GitHub OAuth App ဖန်တီးခြင်း

1. <https://github.com/settings/developers> သို့ ဖွင့်ပါ။
2. **OAuth Apps** → **New OAuth App** ကို နှိပ်ပါ။
3. အောက်ပါအတိုင်း ဖြည့်ပါ:

   | Field | တန်ဖိုး |
   | --- | --- |
   | Application name | `Termux Command Library` |
   | Homepage URL | `https://github.com/minkhantthu2692-gif/termux-command-library-app` |
   | Authorization callback URL | `https://termuxcommandlibrary.firebaseapp.com/__/auth/handler` |

   > Callback URL သည် **အတိအကျ** ဖြစ်ရမည်။ `project-id` နေရာတွင်
   > သင့် Firebase project id ကို ထည့်ပါ။ ဤ project အတွက်
   > `termuxcommandlibrary` ဖြစ်သည်။

4. **Register application** နှိပ်ပါ။
5. **Client ID** ကို ကူးယူပါ။
6. **Generate a new client secret** နှိပ်ပြီး secret ကို ကူးယူပါ။
   (ဤစာမျက်နှာမှ ထွက်လျှင် ပြန်မမြင်ရပါ။)
7. Firebase Console → **Authentication → Sign-in method → GitHub**
   တွင် Client ID နှင့် Secret ကို ထည့်ပါ။
8. **Enable** ဖွင့်ပြီး **Save** နှိပ်ပါ။

> **လုံခြုံရေး:** Client secret ကို app ထဲ၊ `google-services.json` ထဲ၊
> `--dart-define` ထဲ သို့မဟုတ် Git ထဲ **မထည့်ပါနှင့်**။
> Firebase Console တွင်သာ ထားပါ။

---

## ၅။ အဆင့် ၄ — Cloud Firestore ဖန်တီးခြင်း

> **လက်ရှိ အခြေအနေ:** ဤ project တွင် `(default)` database
> (Firestore Native) ဖန်တီးပြီးဖြစ်သည်။ အောက်ပါအဆင့်များကို
> အခြား project အတွက် လိုအပ်မှသာ လုပ်ပါ။

1. Firebase Console → **Firestore Database** → **Create database**။
2. **Production mode** ကို ရွေးပါ။
   (Rules ကို နောက်အဆင့်တွင် deploy လုပ်မည်။)
3. တည်နေရာ (region) ကို ရွေးပါ။ မြန်မာနိုင်ငံအတွက်
   `asia-southeast1` (Singapore) ကို အကြံပြုသည်။
   **ဖန်တီးပြီးနောက် region ပြောင်း၍ မရပါ။**
4. **Enable** နှိပ်ပါ။

**Firebase Storage ကို မဖန်တီးပါနှင့်။** ဤ app သည် Storage ကို
လုံးဝမသုံးပါ။ Bucket မရှိလျှင် ပြဿနာ မရှိပါ။

အသုံးပြုမည့် collection နှစ်ခုသာ ရှိသည်:

```text
commands/{commandId}   — public command guide များ
users/{uid}            — profile၊ favoriteIds၊ pinnedIds
```

Collection များကို ကိုယ်တိုင် ဖန်တီးရန် မလိုပါ။ App က ပထမဆုံး
document ရေးချိန်တွင် အလိုအလျောက် ဖန်တီးမည်။

---

## ၆။ အဆင့် ၅ — Rules နှင့် Indexes Deploy လုပ်ခြင်း

### ၆.၁ Firebase CLI ဝင်ရောက်ခြင်း

CLI သည် ဤ machine တွင် တပ်ဆင်ပြီးဖြစ်သည် (version 15.34.1)။
**`minkhantthu2692@gmail.com` ဖြင့် ဝင်ပြီးဖြစ်သည်။**

အခြား machine သို့မဟုတ် အကောင့်အသစ်အတွက်:

```bash
firebase login
```

Browser ပြသလာသော **session ID** နှင့် **authorization code** ကို
မရောထွေးပါနှင့်။ အတည်ပြုပြီးနောက် ရလာသော ရှည်လျားသည့်
authorization code ကိုသာ `firebase login <code>` တွင် ထည့်ပါ။

စစ်ဆေးရန်:

```bash
firebase login:list
```

### ၆.၂ Project ရွေးခြင်း

`.firebaserc` ထဲတွင် `default` သည် `termuxcommandlibrary` ဖြစ်ပြီးသား
ဖြစ်သည်။ ထို့ကြောင့်:

```bash
firebase use default
```

`Project termuxcommandlibrary` ဟု ပြရမည်။

### ၆.၃ Deploy လုပ်ခြင်း

> **လက်ရှိ အခြေအနေ:** ဤ project တွင် deploy လုပ်ပြီးဖြစ်သည်။
> Rules သည် compile အောင်ပြီး အသက်ဝင်နေသည်။ Index နှစ်ခုသည်
> `CREATING` အခြေအနေတွင် ရှိပြီး မိနစ်အနည်းငယ်အတွင်း
> `READY` ဖြစ်လာမည်။ အောက်ပါ command ကို ပြန်လိုအပ်မှသာ
> (rules/indexes ပြင်ပြီးတိုင်း) run ပါ။

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

- **Rules** သည် ချက်ချင်း အသက်ဝင်မည်။
- **Indexes** သည် မိနစ်အနည်းငယ် ကြာနိုင်သည်။
  Console → **Firestore → Indexes** တွင် "Building" မှ "Enabled"
  ဖြစ်သည်အထိ စောင့်ပါ။

### ၆.၄ စစ်ဆေးရန်

- [x] Console → **Firestore → Rules** တွင် ဤ repo ၏
      `firestore.rules` စာသား ပေါ်နေသည်။ (deploy လုပ်ပြီး)
- [x] **Firestore → Indexes** တွင် index နှစ်ခု ရှိသည်။
      (build ဆဲ — `READY` ဖြစ်သည်အထိ စောင့်ပါ)
- [x] Console → **Authentication → Settings → Authorized domains**
      တွင် `termuxcommandlibrary.firebaseapp.com` ပါသည်။

> Index မပြီးသေးလျှင် app ၏ refresh တွင် error ပြနိုင်သည်။
> သို့သော် အော့ဖ်လိုင်း browsing မရပ်ပါ။ Index ပြီးသည်အထိ
> စောင့်ပြီး ပြန်စမ်းပါ။

---

## ၇။ အဆင့် ၆ — ပြန် Build လုပ်ပြီး စက်ထဲ ထည့်ခြင်း

`google-services.json` ကို အစားထိုးပြီးတိုင်း **ပြန် build လုပ်ရမည်**။

### ၇.၁ စက်ချိတ်ဆက်ခြင်း

1. Android စက်တွင် **Settings → About phone** → Build number ကို
   ၇ ကြိမ် နှိပ်ပြီး Developer options ဖွင့်ပါ။
2. **Developer options → USB debugging** ဖွင့်ပါ။
3. USB ကြိုးဖြင့် ကွန်ပျူတာနှင့် ချိတ်ပါ။
4. စက်ပေါ်တွင် "Allow USB debugging?" မေးလျှင် **Allow** နှိပ်ပါ။

စစ်ဆေးရန်:

```bash
flutter devices
adb devices
```

### ၇.၂ Build နှင့် Install

```bash
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

သို့မဟုတ် ဆိုဒ်သေးပြီး မြန်သည့် release APK (debug key ဖြင့်
လက်မှတ်ထိုးထားသည်၊ စမ်းသပ်ရန် သင့်တော်သည်):

```bash
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

> နှစ်မျိုးလုံးကို တစ်ချိန်တည်း install လုပ်၍ မရပါ။ တစ်ခုကို
> အရင် uninstall လုပ်ပါ၊ သို့မဟုတ် `-r` ဖြင့် အစားထိုးပါ။
> Signing key မတူလျှင် `INSTALL_FAILED_UPDATE_INCOMPATIBLE`
> error ပြနိုင်သည်။ ထိုအခါ app ကို uninstall လုပ်ပြီး ပြန် install ပါ။

`adb` မတွေ့လျှင် Android SDK ၏ `platform-tools` folder ကို
PATH ထဲ ထည့်ပါ။

တိုက်ရိုက် run လိုလျှင်:

```bash
flutter run
```

### ၇.၃ ဖိုင်ဆိုဒ် လျှော့ချခြင်း (မဖြစ်မနေ မဟုတ်)

Debug APK တွင် ABI အားလုံး ပါသဖြင့် ဆိုဒ်ကြီးသည် (၂၁၆ MB ခန့်)။
စက်တစ်ခုအတွက်သာ လိုလျှင်:

```bash
flutter build apk --debug --split-per-abi
```

ထွက်လာမည့်ဖိုင်:

```text
build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk
```

များသောအားဖြင့် ခေတ်သစ် ဖုန်းများသည် `arm64-v8a` ဖြစ်သည်။

---

## ၈။ အဆင့် ၇ — စက်ပေါ်တွင် စမ်းသပ်ရန် စာရင်း

အောက်ပါတို့ကို အစဉ်လိုက် စမ်းပါ။ တစ်ခုမအောင်လျှင်
**အဆင့် ၁၅** (ပြဿနာဖြေရှင်းခြင်း) ကို ကြည့်ပါ။

### ၈.၁ Authentication

- [ ] အကောင့်မရှိဘဲ app ဖွင့်လျှင် guest အဖြစ် အလုပ်လုပ်သည်။
- [ ] Email/Password ဖြင့် စာရင်းသွင်းနိုင်သည်။
- [ ] Email တွင် `@` မပါဘဲ ရိုက်လျှင် `@gmail.com` အလိုအလျောက် ဖြည့်သည်။
- [ ] Password နှင့် Confirm Password မတူလျှင် error ပြသည်။
- [ ] Password မျက်စိဖြင့် ကြည့်နိုင်သော toggle အလုပ်လုပ်သည်။
- [ ] Password reset email ပို့နိုင်သည်။
- [ ] Sign out လုပ်ပြီး ပြန်ဝင်နိုင်သည်။
- [ ] Guest အကောင့်ကို Email/Password သို့မဟုတ် Google/GitHub နှင့်
      link လုပ်နိုင်သည်။ Link ပြီးနောက် favorite/pin မပျောက်ပါ။
- [ ] Account delete လုပ်နိုင်သည်။ ကိုယ်ပိုင် public guide များ
      ပျက်သွားမည်။ Local cache ရှင်းခြင်းနှင့် မတူပါ။
- [ ] Google ဖြင့် ဝင်နိုင်သည် (SHA ထည့်ပြီးမှ)။
- [ ] GitHub ဖြင့် ဝင်နိုင်သည် (OAuth App ဖန်တီးပြီးမှ)။

### ၈.၂ Synchronization

- [ ] အကောင့်ဝင်ထားစဉ် guide အသစ် publish လုပ်နိုင်သည်။
- [ ] ထို guide ကို Firestore Console တွင် တွေ့ရသည်။
- [ ] အခြားစက်တစ်ခုတွင် ထို guide ပေါ်လာသည် (refresh ပြီးနောက်)။
- [ ] အော့ဖ်လိုင်း (Wi-Fi/Mobile data ပိတ်) တွင် guide များ ဖတ်နိုင်သည်။
- [ ] အော့ဖ်လိုင်းတွင် favorite/pin လုပ်ပြီး အွန်လိုင်းပြန်ရောက်လျှင်
      ပြန်လည် sync ဖြစ်သည်။
- [ ] Swipe-to-refresh အလုပ်လုပ်သည်။
- [ ] Network မရှိလျှင် error ပြသော်လည်း local data မပျက်ပါ။

### ၈.၃ Favorite နှင့် Pin

- [ ] Guide တစ်ခုကို favorite လုပ်နိုင်သည်။
- [ ] App ပိတ်ပြီး ပြန်ဖွင့်လျှင် favorite ရှိနေသည်။
- [ ] Sign out → sign in ပြန်လုပ်လျှင် favorite ရှိနေသည်။
- [ ] Pin လုပ်နိုင်ပြီး အစီအစဉ် ပြောင်းနိုင်သည်။
- [ ] Pin အစီအစဉ်သည် ပြန်ဖွင့်ပြီးနောက် မပျက်ပါ။
- [ ] Guest အဖြစ် favorite/pin လုပ်နိုင်သည် (local only)။

### ၈.၄ Command များ

- [ ] အဆင့်များစွာပါသော guide ကို ဖွင့်နိုင်သည်။
- [ ] Newline၊ space နှင့် quote များ မပျက်ပါ။
- [ ] တစ်ဆင့်ချင်း ကူးယူနိုင်သည်။
- [ ] Command အားလုံးကို တစ်ခါတည်း ကူးယူနိုင်သည်။
- [ ] အန္တရာယ်ရှိသော command (ဥပမာ `rm -rf`) အတွက်
      သတိပေးချက် ပြသည်။
- [ ] ကိုယ်ပိုင် guide ကို တည်းဖြတ်၊ ဖျက်နိုင်သည်။
- [ ] အခြားသူ၏ guide ကို တည်းဖြတ်ရန် ခလုတ် မပေါ်ပါ။
      (ပေါ်သော်လည်း Firestore rules က ငြင်းပယ်ရမည်။)

### ၈.၅ Termux

- [ ] Termux မထည့်ထားလျှင် app က ရှင်းလင်းသော လမ်းညွှန် ပြသည်။
- [ ] Termux ထည့်ပြီး `allow-external-apps=true` သတ်မှတ်ထားလျှင်
      command ပို့နိုင်သည်။
- [ ] Permission မရှိသေးလျှင် တောင်းခံသည့် မျက်နှာပြင် ပြသည်။
- [ ] Command ပို့မီ အတည်ပြုချက် တောင်းသည်။
- [ ] ပယ်ဖျက်နိုင်သည်။
- [ ] App က "Sent to Termux" ဟုသာ ပြသည်။ "အောင်မြင်ပြီး" ဟု မပြောပါ။

### ၈.၆ AI (ကီး ထည့်ပြီးမှ)

- [ ] မှားသော ကီးဖြင့် ရှင်းလင်းသော error ပြသည်။
- [ ] **Test key** အလုပ်လုပ်သည်။
- [ ] **Fetch models** ဖြင့် model စာရင်း ရသည်။
- [ ] Model ရွေးနိုင်သည်။
- [ ] မေးခွန်း ပို့ပြီး အဖြေ ရသည်။
- [ ] AI history တွင် ပြန်ကြည့်နိုင်သည်။
- [ ] History ကို တစ်ခုချင်း သို့မဟုတ် အားလုံး ဖျက်နိုင်သည်။
- [ ] ကီးကို log၊ history သို့မဟုတ် Firestore တွင် မတွေ့ပါ။

### ၈.၇ Haptics (တုန်ခါမှု) — အသစ်

- [ ] Appearance → **Haptics** တွင် Off/Light/Medium/Strong ရွေးနိုင်သည်။
- [ ] ရွေးချယ်တိုင်း ထို intensity ဖြင့် ချက်ချင်း တုန်ခါသည်။
- [ ] Light နှင့် Strong သည် သိသိသာသာ ကွာခြားသည်။
- [ ] Off ရွေးလျှင် မည်သည့် app တုန်ခါမှုမှ မရှိတော့ပါ။
- [ ] Font size နှင့် Blur slider တွင် အဆင့်တစ်ခုစီ တုန်ခါသည်။
- [ ] Switch တစ်ခုကို နှိပ်လျှင် တစ်ကြိမ်သာ တုန်ခါသည်
      (နှစ်ကြိမ် မဖြစ်ပါ)။
- [ ] Success နှင့် error တုန်ခါမှုသည် မတူပါ။
- [ ] Emulator တွင် တုန်ခါမှု မရနိုင်ပါ — စက်အစစ်ဖြင့် စမ်းပါ။

### ၈.၈ Theme နှင့် Navigation

- [ ] Light/Dark/System theme ပြောင်းနိုင်သည်။
- [ ] Status bar နှင့် navigation bar အရောင် theme နှင့် ကိုက်ညီသည်။
- [ ] အလင်းတွင် icon များ မြင်ရသည်၊ အမှောင်တွင်လည်း မြင်ရသည်။
- [ ] Accent colour၊ font size၊ font family ပြောင်းနိုင်သည်။
- [ ] မြန်မာဘာသာ ရွေးလျှင် စာများ ဖတ်နိုင်သည်။
- [ ] Bottom tab တစ်ခုမှ တစ်ခုသို့ ပြောင်းပြီး **Back** နှိပ်လျှင်
      ယခင် tab သို့ ပြန်ရောက်သည်။
- [ ] Quick Actions မှ ဖွင့်ထားသော tab များကိုလည်း Back က
      အစဉ်လိုက် ပြန်သွားသည်။
- [ ] ယခင် tab မရှိတော့မှသာ app မှ ထွက်သည်။

---

## ၉။ အဆင့် ၈ — Termux ပြင်ဆင်ခြင်း

1. Termux ကို တရားဝင် GitHub release မှ ဒေါင်းလုဒ်လုပ်ပါ:
   <https://github.com/termux/termux-app/releases>
   Play Store version သည် ဟောင်းနေပြီး မထောက်ပံ့တော့ပါ။
2. Termux ကို တစ်ကြိမ် ဖွင့်ပါ (ပထမဆုံး ဖွင့်ချိန် တပ်ဆင်မှု ပြီးစေရန်)။
3. Termux ထဲတွင် အောက်ပါကို run ပါ:

   ```bash
   echo "allow-external-apps=true" >> ~/.termux/termux.properties
   termux-reload-settings
   ```

4. App ထဲတွင် **Termux guide** ကို ဖွင့်ပြီး လိုအပ်သော
   `RUN_COMMAND` permission ကို ခွင့်ပြုပါ။
5. Android Settings → Apps → Termux → Permissions တွင် လိုအပ်သော
   permission များ ရှိကြောင်း စစ်ပါ။

> **သတိ:** App သည် command များကို အလိုအလျောက် မလုပ်ဆောင်ပါ။
> အမြဲတမ်း command ကို ပြပြီး အတည်ပြုချက် တောင်းသည်။
> အန္တရာယ်ရှိသော command များအတွက် ထပ်မံ သတိပေးသည်။

---

## ၁၀။ အဆင့် ၉ — Groq AI ကီး ထည့်ခြင်း (ရွေးချယ်နိုင်)

1. <https://console.groq.com/keys> တွင် အကောင့်ဖွင့်ပြီး
   API key တစ်ခု ဖန်တီးပါ။
2. App ထဲတွင် **Profile → Settings → AI Assistant** ကို ဖွင့်ပါ။
3. ကီးကို ထည့်ပြီး **Save** နှိပ်ပါ။
4. **Test key** ကို နှိပ်ပါ။ အောင်မြင်လျှင် အစိမ်းရောင် အခြေအနေ ပြမည်။
5. **Fetch models** ကို နှိပ်ပြီး model တစ်ခု ရွေးပါ။
6. **Enable AI** ကို ဖွင့်ပါ။

လုံခြုံရေး:

- ကီးကို Android secure storage တွင်သာ သိမ်းသည်။
- SQLite၊ Firestore၊ history၊ cache သို့မဟုတ် log ထဲ မရေးပါ။
- ကီး ပေါက်ကြားသည်ဟု သံသယရှိလျှင် Groq Console တွင်
  ချက်ချင်း **revoke** လုပ်ပြီး အသစ် ဖန်တီးပါ။
- ကီးကို screenshot၊ issue သို့မဟုတ် chat တွင် မတင်ပါနှင့်။

> AI သည် မဖြစ်မနေ မဟုတ်ပါ။ ကီး မထည့်လျှင်လည်း app ၏
> အခြားလုပ်ဆောင်ချက်များ အားလုံး အလုပ်လုပ်သည်။

---

## ၁၁။ အဆင့် ၁၀ — Admin သတ်မှတ်ခြင်း (ရွေးချယ်နိုင်)

Admin သည် profile field မဟုတ်ပါ။ Firebase Authentication ၏
**custom claim** ဖြစ်သည်:

```json
{ "admin": true }
```

Client က ကိုယ်တိုင် မရေးနိုင်ပါ။ Trusted machine မှ
Firebase Admin SDK ဖြင့် သတ်မှတ်ရမည်။

အကျဉ်းချုပ်:

1. Admin ဖြစ်မည့်သူ၏ Firebase Auth **UID** ကို ရှာပါ
   (Console → Authentication → Users)။
2. Service account JSON ကို ဒေသတွင်း သိမ်းပါ (Git ထဲ **မထည့်ပါ**)။
3. Admin SDK ဖြင့် `setCustomUserClaims(uid, { admin: true })` လုပ်ပါ။
4. အသုံးပြုသူကို sign out/in ပြန်လုပ်ခိုင်းပါ (token အသစ် ရမည်)။
5. Firestore rules က `request.auth.token.admin == true` ကို စစ်မည်။

အဆင့်ပြည့် script နှင့် ရှင်းလင်းချက်:
[Admin configuration](admin-setup.md)။

---

## ၁၂။ အဆင့် ၁၁ — Release APK ထုတ်ဝေရန် (ဖြန့်ဝေမည်ဆိုမှ)

### ၁၂.၁ လက်ရှိ အခြေအနေ

`android/app/build.gradle.kts` ၏ အောက်ပါအပိုင်းတွင်
release build သည် **debug key** ဖြင့် လက်မှတ်ထိုးထားသည်:

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```

ဤအခြေအနေဖြင့် ဖြန့်ဝေ၍ မရပါ။ သင့်ကိုယ်ပိုင် keystore လိုသည်။

> **လက်ရှိ build:** `app-release.apk` (70.4 MB) ကို ထုတ်ပြီးဖြစ်သည်။
> ၎င်းသည် release mode ဖြင့် compile ထားသော်လည်း **debug key** ဖြင့်
> လက်မှတ်ထိုးထားသည်။ `apksigner` ဖြင့် စစ်ဆေးပြီး လက်ဗွေနှစ်ခုလုံး
> Firebase တွင် ထည့်ထားသည့် တန်ဖိုးများနှင့် ကိုက်ညီသည်:
>
> ```text
> SHA-1   ef4069727593878b4d2c56caf4684370c491dd00
> SHA-256 63421e96b0707e58933bbd3856e517fd67e1654dc485e6d8e566f3ae30b96e22
> ```
>
> ထို့ကြောင့် ဤ APK ကို စက်ထဲ ထည့်၍ စမ်းသပ်နိုင်သည်။
> သို့သော် Google Play က လက်ခံမည် မဟုတ်ပါ။

### ၁၂.၂ Keystore ဖန်တီးခြင်း

```powershell
keytool -genkey -v `
  -keystore android\upload-keystore.jks `
  -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

Password နှစ်ခုကို မှတ်ထားပါ။ **မပျောက်ပါစေနှင့်** —
ပျောက်လျှင် app update မတင်နိုင်တော့ပါ။

### ၁၂.၃ `android/key.properties` ဖန်တီးခြင်း

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

ဤဖိုင်နှင့် `.jks` ဖိုင်ကို Git ထဲ **မထည့်ပါနှင့်**။
`.gitignore` တွင် ပိတ်ထားပြီးဖြစ်သည်။

### ၁၂.၄ `build.gradle.kts` ပြင်ခြင်း

`android/app/build.gradle.kts` ၏ အပေါ်ပိုင်းတွင်
`key.properties` ဖတ်ပြီး signing config ဖန်တီးကာ
`release` block ထဲတွင် အသုံးပြုပါ။

### ၁၂.၅ Build လုပ်ခြင်း

```bash
flutter build apk --release
flutter build appbundle --release
```

ထွက်လာမည့်ဖိုင်:

```text
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\bundle\release\app-release.aab
```

> `appbundle` (.aab) သည် Google Play Console အတွက် ဖြစ်သည်။
> Play Store တွင် ဖြန့်ဝေလျှင် Play App Signing ကို ဖွင့်ပြီး
> ရလာသော SHA-1/SHA-256 ကို Firebase Console တွင် ထည့်ပါ။

---

## ၁၃။ လုံခြုံရေး သတိပေးချက်များ

အောက်ပါတို့ကို **ဘယ်တော့မှ** Git သို့ မတင်ပါနှင့်:

- `android/app/google-services.json` (`.gitignore` တွင် ပိတ်ထားပြီး)
- Service account JSON (`*-service-account.json`)
- `android/key.properties` နှင့် `*.jks` / `*.keystore`
- Groq API key
- GitHub OAuth client secret

စစ်ဆေးရန်:

```bash
git check-ignore -v android/app/google-services.json
git status --porcelain --untracked-files=all
```

ပထမ command က ဖိုင်ကို ignore လုပ်ထားကြောင်း ပြရမည်။
ဒုတိယ command တွင် လျှို့ဝှက်ဖိုင် မပေါ်ရပါ။

**မှတ်ချက်:** Firebase client value များ (apiKey၊ appId၊ senderId၊
projectId) သည် app binary ထဲ ပါလေ့ရှိသော client identifier များဖြစ်သည်။
သို့သော် service account key နှင့် keystore သည် အမှန်တကယ်
လျှို့ဝှက်ချက်များ ဖြစ်သည်။

---

## ၁၄။ အမြန်စစ်ဆေးရန် Command များ

| ရည်ရွယ်ချက် | Command |
| --- | --- |
| Package များ ရယူ | `flutter pub get` |
| ဘာသာပြန် ဖိုင် ထုတ် | `flutter gen-l10n` |
| Database code ထုတ် | `dart run build_runner build --delete-conflicting-outputs` |
| Format | `dart format lib test` |
| ကုဒ် စစ်ဆေး | `flutter analyze` |
| Test အားလုံး | `flutter test` |
| စက်များ ကြည့် | `flutter devices` |
| Debug APK | `flutter build apk --debug` |
| Release APK | `flutter build apk --release` |
| APK ထည့် | `adb install -r build\app\outputs\flutter-apk\app-debug.apk` |
| Firebase ဝင်ရောက် | `firebase login` |
| Rules deploy | `firebase deploy --only firestore:rules,firestore:indexes` |

**ပြောင်းလဲမှု တစ်ခုပြီးတိုင်း** အနည်းဆုံး
`flutter analyze` နှင့် `flutter test` ကို run ပါ။

---

## ၁၅။ ပြဿနာဖြေရှင်းခြင်း

| လက္ခဏာ | အကြောင်းရင်း | ဖြေရှင်းနည်း |
| --- | --- | --- |
| App က "local-only" ဟု ပြ | Firebase initialize မဖြစ် | `google-services.json` ရှိ/မရှိ၊ package name ကိုက်/မကိုက် စစ်ပါ။ ဖိုင်အသစ်ဖြင့် **ပြန် build** လုပ်ပါ |
| Sign-in ခလုတ် မပေါ် | Firebase မရှိ | `google-services.json` ထည့်ပြီး ပြန် build လုပ်ပါ |
| `operation-not-allowed` | Provider မဖွင့်ထား | Console တွင် ထို provider ကို Enable လုပ်ပါ |
| Google ဝင်မရ | SHA မထည့် / provider မဖွင့် | SHA-1/SHA-256 ထည့်ပြီး JSON ပြန် download လုပ်ပါ။ Authentication → Google ကို Enable ဖြစ်/မဖြစ် စစ်ပါ |
| GitHub redirect error | Callback URL မမှန် | `https://termuxcommandlibrary.firebaseapp.com/__/auth/handler` အတိအကျ ဖြစ်ရမည် |
| `PERMISSION_DENIED` | Rules deploy မလုပ် | `firebase deploy --only firestore:rules` လုပ်ပါ |
| Index error | Index မပြီးသေး | Console → Indexes တွင် "Enabled" ဖြစ်သည်အထိ စောင့်ပါ |
| Refresh တွင် error | Network သို့မဟုတ် index | အော့ဖ်လိုင်း browsing ဆက်လုပ်နိုင်သည်။ Network စစ်ပါ |
| Termux မတွေ့ | Termux မထည့်/ဖွင့်မထား | GitHub release မှ ထည့်ပြီး တစ်ကြိမ် ဖွင့်ပါ |
| Command မပို့နိုင် | `allow-external-apps` မရှိ | `termux.properties` ပြင်ပြီး `termux-reload-settings` လုပ်ပါ |
| တုန်ခါမှု မရ | Off ရွေးထား/စက် မထောက်ပံ့ | Appearance → Haptics စစ်ပါ။ Emulator တွင် မရပါ |
| တုန်ခါမှု အားနည်း | စက်၏ amplitude မထောက်ပံ့ | Light/Medium/Strong သည် duration ဖြင့်သာ ကွာနိုင်သည် — ပုံမှန်ဖြစ်သည် |
| မြန်မာစာ မဖတ်နိုင် | Font fallback မရ | မြန်မာဘာသာ ရွေးပါ။ Bundled fallback font ကို မဖျက်ပါ |
| Release build crash | Debug key ဖြင့် လက်မှတ်ထိုး | ကိုယ်ပိုင် keystore ဖြင့် ပြန် build လုပ်ပါ |

အသေးစိတ်: [Troubleshooting](troubleshooting.md)။

---

## ၁၆။ "၁၀၀% အလုပ်ဖြစ်သည်" ဆိုသည်မှာ

ဤ app ၏ မဖြစ်မနေ လုပ်ဆောင်ချက်များ အားလုံး အောက်ပါအတိုင်း
စမ်းသပ်ပြီး အောင်မြင်လျှင် "၁၀၀% အလုပ်ဖြစ်သည်" ဟု ဆိုနိုင်သည်:

1. **အော့ဖ်လိုင်း** — Network မရှိဘဲ app ဖွင့်ပြီး guide များ ဖတ်နိုင်သည်။
2. **အကောင့်** — Email/Password ဖြင့် စာရင်းသွင်း၊ ဝင်၊ ပြန်ထွက်၊
   စကားဝှက် ပြန်လည်သတ်မှတ်နိုင်သည်။
3. **ဒေတာ** — Guide publish လုပ်ပြီး Firestore တွင် တွေ့ရသည်။
   အခြားစက်တွင် ပေါ်လာသည်။
4. **ပိုင်ဆိုင်မှု** — ကိုယ်ပိုင် guide ကို ပြင်နိုင်၊ ဖျက်နိုင်သည်။
   အခြားသူ၏ guide ကို မပြင်နိုင်ပါ။
5. **Favorite/Pin** — စက်ပြန်ဖွင့်၊ sign out/in ပြီးနောက်လည်း ရှိနေသည်။
6. **Command** — တစ်ဆင့်ချင်း/အားလုံး ကူးယူနိုင်သည်။ Newline မပျက်ပါ။
7. **Termux** — အတည်ပြုချက်ဖြင့် command ပို့နိုင်သည်။
8. **AI** — ကီးထည့်၊ စမ်း၊ model ရွေး၊ မေးခွန်းမေးနိုင်သည် (ရွေးချယ်နိုင်)။
9. **UI** — Light/Dark၊ မြန်မာစာ၊ Haptics အားလုံး အလုပ်လုပ်သည်။
10. **Navigation** — Back က tab များကို အစဉ်လိုက် ပြန်သွားသည်။

### လက်ရှိ ပိတ်ဆို့နေသော အချက်များ (အစဉ်လိုက်)

1. Firebase provider များ ဖွင့်ခြင်း — ✅ **ပြီး** (Email၊ Anonymous၊ Google၊ GitHub)
2. Firestore database ဖန်တီးပြီး rules/indexes deploy လုပ်ခြင်း — ✅ **ပြီး**
   (index များ `READY` ဖြစ်သည်အထိ စောင့်ရန် ကျန်)
3. SHA လက်ဗွေ — ✅ **SHA-1 ပြီး**၊ SHA-256 ကို Console တွင် စစ်ရန် ကျန်
4. GitHub OAuth App — ✅ **ပြီး** (provider ဖွင့်ပြီး)
5. စက်ပေါ်တွင် အဆင့် ၈ စာရင်းအတိုင်း စမ်းသပ်ခြင်း — ⬜ **မလုပ်ရသေး**
   (Android device မချိတ်ထား)
6. Termux ပြင်ဆင်ခြင်း — ⬜ **မလုပ်ရသေး**
7. Release keystore — ⬜ **မလုပ်ရသေး** (Play Store ဖြန့်ဝေမှသာ)
8. Groq API ကီး — ⬜ **ရွေးချယ်နိုင်** (BYOK)

အထက်ပါ ၅ နှင့် ၆ ကို ပြီးလျှင် app သည် အသုံးပြုရန် အသင့် ဖြစ်မည်။
Release ဖြန့်ဝေလိုမှသာ **အဆင့် ၁၁** (keystore) ကို ထပ်လုပ်ပါ။

---

## ၁၇။ နောက်ထပ် ဖတ်ရန်

- [Burmese full setup](burmese-setup.md) — အစမှ စတင် တပ်ဆင်ခြင်း
- [Firebase setup](firebase-setup.md)
- [Firebase Authentication](firebase-auth-setup.md)
- [Firestore setup](firestore-setup.md)
- [Security rules](security-rules.md)
- [Admin configuration](admin-setup.md)
- [Groq API setup](groq-setup.md)
- [Termux integration](termux-integration.md)
- [Build instructions](build.md)
- [Troubleshooting](troubleshooting.md)
- [Architecture](architecture.md)
- [Synchronization](synchronization.md)
