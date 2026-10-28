# Termux Command Library — စတင်တပ်ဆင်ခြင်း လမ်းညွှန်

ဤလမ်းညွှန်သည် Termux Command Library ကို ကိုယ်တိုင်တည်ဆောက်၊
Firebase နှင့် ချိတ်ဆက်၊ Termux နှင့် Groq AI ကို ပြင်ဆင်အသုံးပြုရန်
အဆင့်ဆင့် ရှင်းပြထားသည်။

> **အရေးကြီး:** ဤ repository တွင် Firebase သို့မဟုတ် Groq ၏ လျှို့ဝှက်
> credential များ မပါဝင်ပါ။ အောက်ပါအဆင့်များကို သင်ကိုယ်တိုင်
> ပြုလုပ်ရမည်။ မည်သည့် service-account JSON၊ keystore သို့မဟုတ် API ကီးကိုမျှ
> Git သို့ မတင်ပါနှင့်။

---

## ၁။ ဤ app အကြောင်း

Termux Command Library သည် Termux command များနှင့် အဆင့်များစွာပါသော
command လမ်းညွှန်များကို ရှာဖွေ၊ သိမ်းဆည်း၊ ကူးယူ၊ ဖတ်ရှုနိုင်သော
Android app ဖြစ်သည်။

အဓိကလုပ်ဆောင်ချက်များ:

- command လမ်းညွှန်များကို ရှာဖွေခြင်း၊ အမျိုးအစားခွဲခြင်း၊ စီစဉ်ခြင်း။
- အဆင့်များစွာပါသော command guide များကို ဖန်တီး၊ တည်းဖြတ်ခြင်း။
- တစ်ခုချင်း သို့မဟုတ် command အားလုံးကို ကူးယူခြင်း။
- Termux သို့ command ပို့ခြင်း (အတည်ပြုချက်နှင့် အန္တရာယ်သတိပေးချက်ဖြင့်)။
- favorite နှင့် pin လုပ်ခြင်း (pin အစီအစဉ်ကို ထိန်းသိမ်းသည်)။
- အော့ဖ်လိုင်းအသုံးပြုခြင်း၊ အွန်လိုင်းပြန်ရောက်သောအခါ ပြန်လည်ချိတ်ဆက်ခြင်း။
- Email/Password ဖြင့် စာရင်းသွင်း/ဝင်ရောက်ခြင်း၊ ဧည့်သည်အကောင့် ချိတ်ဆက်ခြင်း။
- ကိုယ်ပိုင် Groq API ကီးဖြင့် AI အကူအညီ (မဖြစ်မနေ မဟုတ်ပါ)။
- အင်္ဂလိပ်/မြန်မာ ဘာသာစကား၊ အလင်း/အမှောင် theme၊ ဖောင့် ရွေးချယ်မှုများ။

**ဤ app သည် terminal emulator မဟုတ်ပါ။** command များကို Termux ကသာ
လုပ်ဆောင်မည်။ app သည် "Termux သို့ ပို့ပြီး" ဟုသာ ပြမည်၊ command
အောင်မြင်ပြီးဟု မပြောနိုင်ပါ။

Firebase ကို **Authentication နှင့် Cloud Firestore** အတွက်သာ
အသုံးပြုသည်။ **Firebase Storage ကို လုံးဝမသုံးပါ။**

---

## ၂။ လိုအပ်သော ကိရိယာများ

| ကိရိယာ | လိုအပ်ချက် |
| --- | --- |
| Flutter | 3.47.8 သို့မဟုတ် အထက် (stable) |
| Dart | 3.13.7 သို့မဟုတ် အထက် |
| JDK | 17 |
| Android SDK | API 24 (Android 7.0) နှင့် အထက် |
| Node.js | Firebase CLI အတွက် (ရွေးချယ်နိုင်) |
| Android စက် သို့မဟုတ် Emulator | app စမ်းသပ်ရန် |

စစ်ဆေးရန်:

```bash
flutter --version
flutter doctor -v
java -version
```

`flutter doctor` တွင် Android toolchain နှင့် JDK အနီရောင် မပြရပါ။
လိုအပ်ပါက:

```bash
flutter doctor --android-licenses
```

---

## ၃။ Project ကို ပြင်ဆင်ခြင်း

Project folder ထဲသို့ ဝင်ပြီး:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

ဤ command များသည် package များ၊ ဘာသာပြန်ဖိုင် နှင့် Drift database code
များကို ပြင်ဆင်ပေးမည်။ `build_runner` ကို database table သို့မဟုတ် DAO
ပြောင်းတိုင်း ပြန်လုပ်ပါ။

စစ်ဆေးရန်:

```bash
dart format lib test
flutter analyze
flutter test
```

Analysis တွင် ပြဿနာမရှိဘဲ test အားလုံး အောင်ရမည်။

---

## ၄။ Firebase မပါဘဲ စမ်းသပ်ခြင်း (အော့ဖ်လိုင်း)

```bash
flutter run
```

Firebase configuration မရှိလျှင် app သည် **local-only mode** ဖြင့်
အလုပ်လုပ်မည်:

- SQLite ထဲတွင် ပါဝင်သော seed guide ၅၂ ခုကို ဖတ်နိုင်သည်။
- ဧည့်သည် (local guest) အဖြစ် favorite/pin လုပ်နိုင်သည်။
- အကောင့်ဝင်ရန် ကြိုးစားလျှင် Firebase မတပ်ဆင်ရသေးကြောင်း ရှင်းလင်းစွာ ပြမည်။
- App သည် crash မဖြစ်ဘဲ ဒေတာများကို မဖျက်ပါ။

UI နှင့် အော့ဖ်လိုင်းလုပ်ဆောင်ချက်များကို စမ်းသပ်ရန် ဤနည်းကို
အသုံးပြုနိုင်သည်။

---

## ၅။ Firebase ပရောဂျက် ဖန်တီးခြင်း

1. <https://console.firebase.google.com> သို့ ဝင်ပါ။
2. **Add project** ကို နှိပ်ပြီး ပရောဂျက်အမည် ပေးပါ။
3. Google Analytics ကို မဖြစ်မနေ မလိုပါ။ ဤ app သည် Analytics မသုံးပါ။
4. ဖန်တီးပြီးနောက် **Project settings → General** မှ **Project ID**
   ကို မှတ်ထားပါ။

### Android app မှတ်ပုံတင်ခြင်း

1. **Project settings → Your apps → Android** ကို ရွေးပါ။
2. Package name ကို အတိအကျ ထည့်ပါ:

   ```text
   com.termuxcommandlibrary.mm
   ```

3. Google Sign-In အတွက် Debug နှင့် Release/Play App Signing
   SHA-1/SHA-256 လက်ဗွေများကို **Project settings → Your apps → Android
   app → Add fingerprint** တွင် ထည့်ပါ။ Email/Password နှင့် Anonymous
   အတွက် လက်ဗွေ မလိုအပ်ပါ။ လက်ဗွေထည့်ပြီးနောက်
   `google-services.json` ကို ပြန် download လုပ်ပါ။
4. Console မှ ရရှိသော `google-services.json` ကို
   `android/app/google-services.json` အဖြစ် ထည့်ပါ။ ဖိုင်ရှိလျှင်
   Google Services Gradle plugin အလိုအလျောက် အလုပ်လုပ်ပြီး app က
   Firebase project ကို အလိုအလျောက် ရှာတွေ့မည်။ ဤဖိုင်ကို
   `.gitignore` တွင် ထည့်ထားသဖြင့် Git သို့ မတင်ပါ။
   `--dart-define` ဖြင့်လည်း configuration ပေးနိုင်သည်။ နှစ်မျိုးလုံး
   ရှိလျှင် တူညီသော Firebase app ဖြစ်ရမည်။

လက်ရှိ working copy သည် project `termuxcommandlibrary` နှင့် package
`com.termuxcommandlibrary.mm` အတွက် ချိတ်ဆက်ထားသည်။

**လျှို့ဝှက်ချက်:** Firebase client value များ (apiKey, appId,
senderId, projectId) သည် app binary ထဲတွင် ပါလေ့ရှိသော client
identifier များဖြစ်သည်။ သို့သော် `google-services.json` နှင့်
service-account JSON သည် repository ထဲ မထည့်ရပါ။

---

## ၆။ Firebase Authentication ဖွင့်ခြင်း

Firebase Console → **Authentication** → **Get started**:

1. **Sign-in method → Email/Password** ကို **Enable** လုပ်ပါ။
   Email link ကို မလိုအပ်ပါ။
2. **Anonymous** ကို **Enable** လုပ်ပါ။
3. **Google** ကို **Enable** လုပ်ပါ။ Support email ရွေးပါ။ ထို့နောက်
   **Project settings** တွင် Debug နှင့် Release SHA-1/SHA-256
   လက်ဗွေများ ထည့်ပြီး `google-services.json` ကို ပြန် download
   လုပ်ပါ။ လက်ဗွေမပါလျှင် Google ဖြင့် ဝင်ရောက်မရနိုင်ပါ။

   Google ဝင်ရောက်မှုသည် native account picker ကို သုံးပြီး Firebase
   hosted browser handler ကို မဖွင့်ပါ။ `google-services.json` ထဲမှ
   Web OAuth client ကို အလိုအလျောက် ဖတ်သည်။
4. **GitHub** ကို **Enable** လုပ်ပါ။ GitHub တွင် **Settings → Developer
   settings → OAuth Apps → New OAuth App** ဖြင့် app တစ်ခု ဖန်တီးပြီး
   Authorization callback URL ကို အောက်ပါအတိုင်း ထည့်ပါ:

   ```text
   https://<project-id>.firebaseapp.com/__/auth/handler
   ```

   ရရှိသော **Client ID** နှင့် **Client secret** ကို Firebase ၏ GitHub
   provider ထဲ ထည့်ပါ။ Client secret ကို app ထဲ၊ `--dart-define` ထဲ
   သို့မဟုတ် Git ထဲ မထည့်ပါ။ GitHub သည် Firebase hosted flow ကို
   သုံးသောကြောင့် ဝင်ရောက်ရာတွင် browser (Custom Tab) လိုအပ်သည်။
5. **Settings → Authorized domains** တွင် Firebase domain များ
   ပါဝင်ကြောင်း စစ်ပါ။
6. **Templates** တွင် app အမည်နှင့် support email ကို ပြင်နိုင်သည်။

ဤ app တွင် OTP၊ SMS verification သို့မဟုတ် မဖြစ်မနေ email
verification အဆင့် မပါပါ။ Google နှင့် GitHub သာ ပါဝင်ပြီး Apple
သို့မဟုတ် Facebook မပါပါ။

### Google/GitHub ဖြင့် ဝင်ရောက်ခြင်း

- Sign-in နှင့် Create account မျက်နှာပြင်တွင် အီးမေးလ် ဖောင်၏
  **အောက်တွင်** Google နှင့် GitHub အိုင်ကွန် ခလုတ်နှစ်ခု ပြပါမည်။
  အီးမေးလ်/စကားဝှက်သည် အဓိက နည်းလမ်းအဖြစ် ဆက်ရှိသည်။
  `google-services.json` မရှိသော local-only build တွင် ခလုတ်များ
  ပေါ်မည် မဟုတ်ပါ။
- Google သည် native account picker ကို ဖွင့်သည်။ GitHub သည်
  Firebase hosted flow ကို browser (Custom Tab) ဖြင့် ဖွင့်သည်။
- သာမန် Sign-in တွင် provider အကောင့်ကို ဝင်ရောက် သို့မဟုတ်
  အသစ်ဖန်တီးမည်။ Create account တွင် လက်ရှိ anonymous Firebase
  အကောင့်ရှိနေလျှင် provider ကို ထိုအကောင့်နှင့် link လုပ်မည်။
  ထို့ကြောင့် UID၊ favorite၊ pin နှင့် သင့် guide များ မပျောက်ပါ။
- Provider အကောင့်သည် အခြား Firebase UID နှင့် ချိတ်ထားပြီးဖြစ်လျှင်
  link မရနိုင်ပါ။ App က ထိုအကောင့်ဖြင့် ဝင်ရောက်ရန် ပြမည်။
  Firebase UID နှစ်ခုကို ပေါင်းစည်းခြင်း မလုပ်ပါ။
- Google အကောင့်ရွေးချယ်မှု ပယ်ဖျက်ခြင်း သို့မဟုတ် GitHub browser
  tab ပိတ်ခြင်းကို error အဖြစ် မပြပါ။ ဖောင် ပြန်အသုံးပြုနိုင်ပါသည်။
- Provider လုပ်ဆောင်ချက် ၄၅ စက္ကန့်ကျော်လျှင် browser တွင် ဝင်ရောက်မှု
  ပြီးအောင်လုပ်ရန် သို့မဟုတ် နောက်သို့ပြန်ပြီး ထပ်စမ်းရန်
  အကြံပြုချက် ပြသည်။

စာရင်းသွင်းရာတွင်:

- Avatar (app ထဲပါ built-in avatar)။
- Nickname။
- Email — `@` မပါဘဲ ရိုက်ပါက အလိုအလျောက် `@gmail.com` ဖြည့်ပေးမည်။
  ဥပမာ `myusername` → `myusername@gmail.com`။
  `user@outlook.com` ကဲ့သို့ domain ပါပြီးသား စာများကို မပြောင်းပါ။
- Password နှင့် Confirm Password။

အနည်းဆုံး စကားဝှက် ၈ လုံး လိုအပ်သည်။

---

## ၇။ Cloud Firestore ဖန်တီးခြင်း

1. Firebase Console → **Firestore Database** → **Create database**။
2. **Production mode** ကို ရွေးပါ။ ကျွန်ုပ်တို့၏ rules များက
   default ကို အစားထိုးမည်။
3. သင့်အသုံးပြုသူများနှင့် နီးသော region ကို ရွေးပါ။
   နောက်ပိုင်း region ပြောင်းရန် ခက်ခဲသည်။
4. ဤ app အတွက် **Storage bucket မဖန်တီးပါနှင့်**။

အသုံးပြုသော collection နှစ်ခုသာ ရှိသည်:

```text
commands/{commandId}   — public command guide များ
users/{uid}            — ကိုယ်ပိုင် profile၊ favorite/pin စာရင်း
```

အသေးစိတ် document shape ကို
[Firestore setup](firestore-setup.md) တွင် ဖတ်ပါ။

---

## ၈။ Rules နှင့် Indexes ကို Deploy လုပ်ခြင်း

Firebase CLI ကို တပ်ဆင်ပါ (တစ်ကြိမ်သာ):

```bash
npm install -g firebase-tools
firebase login
```

Project folder ထဲတွင်:

```bash
firebase use --add
```

Console တွင် ဖန်တီးထားသော project ကို ရွေးပြီး alias (ဥပမာ `default`)
ပေးပါ။ ထို့နောက်:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

- `firebase.json` သည် `firestore.rules` နှင့်
  `firestore.indexes.json` ကို ညွှန်ထားသည်။
- Index များ တည်ဆောက်ရန် မိနစ်အနည်းငယ် ကြာနိုင်သည်။
- Index မပြီးသေးလျှင် refresh တွင် error ပြနိုင်သော်လည်း
  အော့ဖ်လိုင်း browsing မရပ်ပါ။

Rules အကြောင်း အသေးစိတ်:
[Security rules](security-rules.md)။

---

## ၉။ Firebase နှင့် ချိတ်ဆက်ပြီး App ကို Run လုပ်ခြင်း

`android/app/google-services.json` ကို ထည့်ထားပြီးပါက flag မလိုအပ်ပါ:

```bash
flutter run
```

Gradle က JSON ကို Android resource အဖြစ် ပြောင်းပေးပြီး app က
`Firebase.initializeApp()` မှတစ်ဆင့် project ကို အလိုအလျောက်
ရှာတွေ့မည်။

CI အတွက် သို့မဟုတ် JSON မပါသော build များတွင်
`--dart-define` ဖြင့် ပေးနိုင်သည်။ JSON နှင့် define နှစ်မျိုးလုံး
သုံးလျှင် တူညီသော project ဖြစ်ရမည်။
Console ၏ **Project settings → General → Your apps** မှ အောက်ပါ
value များကို ယူပါ:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN` (မဖြစ်မနေ မဟုတ်)

Windows PowerShell:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

macOS/Linux:

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

မှတ်ချက်:

- Value များသည် compile-time ဖြစ်သည်။ Hot reload မလုပ်ပါနှင့်၊
  app ကို ပြန်လည် run ပါ။ `google-services.json` ကို အစားထိုးလျှင်လည်း
  ပြန် build လုပ်ရမည်။
- `--dart-define` သုံးလျှင် API key, app ID, sender ID, project ID
  လေးခု မရှိမဖြစ်လိုသည်။
- တစ်ခုခု မှားလျှင် app သည် local-only mode သို့ ပြန်ကျပြီး
  အလုပ်ဆက်လုပ်နိုင်မည်။

---

## ၁၀။ Admin သတ်မှတ်ခြင်း

Admin သည် profile field မဟုတ်ပါ။ Firebase Authentication ၏
**custom claim** ဖြစ်သည်:

```json
{ "admin": true }
```

Custom claim ကို client က ကိုယ်တိုင် မရေးနိုင်ပါ။ Trusted machine မှ
Firebase Admin SDK ဖြင့် သတ်မှတ်ရမည်။ အဆင့်ပြည့်အစီအစဉ်နှင့်
script ကို [Admin configuration](admin-setup.md) တွင် ကြည့်ပါ။

အကျဉ်းချုပ်:

1. Admin ဖြစ်မည့်သူ၏ Firebase Auth UID ကို ရှာပါ။
2. Admin SDK ဖြင့် `setCustomUserClaims(uid, { admin: true })` လုပ်ပါ။
3. အသုံးပြုသူကို sign out/in ပြန်လုပ်ခိုင်းပါ (token အသစ်ရမည်)။
4. Firestore rules က `request.auth.token.admin == true` ကို စစ်မည်။

Service-account JSON ကို repository ထဲ မထည့်ပါနှင့်။

---

## ၁၁။ Groq AI သတ်မှတ်ခြင်း (BYOK)

AI သည် ရွေးချယ်နိုင်သော လုပ်ဆောင်ချက်ဖြစ်ပြီး မူရင်းအားဖြင့်
ပိတ်ထားသည်။ သင့်ကိုယ်ပိုင် Groq API ကီး လိုအပ်သည်။

1. <https://console.groq.com/keys> တွင် ကီးတစ်ခု ဖန်တီးပါ။
2. App ထဲတွင် **Profile → Settings → AI Assistant** ကို ဖွင့်ပါ။
3. ကီးကို ထည့်ပါ။
4. **Test key** ကို နှိပ်ပါ။
5. **Fetch models** ကို နှိပ်ပြီး model ရွေးပါ။
6. AI ကို ဖွင့်ပါ။

လုံခြုံရေး:

- ကီးကို Android secure storage တွင်သာ သိမ်းသည်။
- SQLite၊ Firestore၊ history၊ cache၊ log သို့မဟုတ် Git ထဲ
  မရေးပါ။
- ကီး ပေါက်ကြားသည်ဟု သံသယရှိလျှင် Groq console တွင် ချက်ချင်း
  revoke လုပ်ပြီး အသစ်ဖန်တီးပါ။
- ကီးကို screenshot၊ issue သို့မဟုတ် chat တွင် မတင်ပါနှင့်။

အသေးစိတ်: [Groq API setup](groq-setup.md)။

---

## ၁၂။ Termux သတ်မှတ်ခြင်း

Termux ကို တရားဝင် GitHub release မှ ဒေါင်းလုဒ်လုပ်ပါ:

<https://github.com/termux/termux-app/releases>

Play Store version သည် ဟောင်းနေပြီး မထောက်ပံ့တော့ပါ။

Termux ထဲတွင် external app များကို ခွင့်ပြုရန်:

```bash
echo "allow-external-apps=true" >> ~/.termux/termux.properties
termux-reload-settings
```

ထို့နောက် app ၏ **Termux guide** ကို ဖွင့်ပြီး လိုအပ်သော
`RUN_COMMAND` permission ကို ခွင့်ပြုပါ။

Command တစ်ခုကို run လုပ်သောအခါ app သည်:

1. Termux ရှိ/မရှိ စစ်သည်။
2. Permission ရှိ/မရှိ စစ်သည်။
3. Command အားလုံးကို ပြသသည်။
4. အန္တရာယ်ရှိသော command များအတွက် သတိပေးချက် ပြသည်။
5. အတည်ပြုချက် တောင်းသည်။
6. Termux သို့ ပို့သည်။
7. "Sent to Termux" ဟုသာ ပြသည်။ အောင်မြင်ပြီးဟု မပြောပါ။

အသေးစိတ်: [Termux integration](termux-integration.md)။

---

## ၁၃။ APK တည်ဆောက်ခြင်း

Debug APK:

```bash
flutter build apk --debug
```

Firebase နှင့်အတူ: `google-services.json` ထည့်ထားလျှင် အပိုထည့်ရန်
မလိုပါ။ CI အတွက် `--dart-define` ဖြင့် ပေးနိုင်သည်:

```bash
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=...
```

APK ကို ဤနေရာတွင် တွေ့နိုင်သည်:

```text
build/app/outputs/flutter-apk/
```

**ထုတ်ဝေရန် အရေးကြီး:** လက်ရှိ `android/app/build.gradle.kts` သည်
release build အတွက် debug signing ကို ယာယီသုံးထားသည်။ တကယ့်
ထုတ်ဝေမှုအတွက် သင့်ကိုယ်ပိုင် keystore ဖြင့် release signing
ပြင်ဆင်ရမည်။ Keystore၊ password နှင့် `android/key.properties` ကို
Git သို့ မတင်ပါနှင့်။ အဆင့်ပြည့်:
[Build instructions](build.md)။

---

## ၁၄။ စမ်းသပ်စစ်ဆေးရန် စာရင်း

Firebase မပါဘဲ:

- [ ] App ဖွင့်ပြီး seed guide များ မြင်ရသည်။
- [ ] ရှာဖွေမှု၊ အမျိုးအစား filter နှင့် sort အလုပ်လုပ်သည်။
- [ ] Guide တစ်ခုကို ဖွင့်ပြီး command ကူးယူနိုင်သည်။
- [ ] Favorite/pin လုပ်ပြီး app ပြန်ဖွင့်လျှင် ရှိနေသည်။
- [ ] Theme အလင်း/အမှောင်/စနစ် ပြောင်းနိုင်သည်။
- [ ] မြန်မာဘာသာ ရွေးလျှင် စာများ ဖတ်နိုင်သည်။
- [ ] Termux မရှိလျှင် ရှင်းလင်းသော လမ်းညွှန် ပြသည်။

Firebase နှင့်အတူ:

- [ ] Email/Password ဖြင့် စာရင်းသွင်း/ဝင်နိုင်သည်။
- [ ] Password reset email ရသည်။
- [ ] Guide publish လုပ်ပြီး Firestore တွင် မြင်ရသည်။
- [ ] အခြားအကောင့်က ထို guide ကို မတည်းဖြတ်နိုင်ပါ။
- [ ] Favorite/pin သည် စက်ပြန်ဖွင့်၊ sign out/in ပြီးနောက် ရှိနေသည်။
- [ ] အော့ဖ်လိုင်းတွင် ပြောင်းလဲမှုများ queue ဖြစ်ပြီး အွန်လိုင်းပြန်ရောက်လျှင် ပို့သည်။
- [ ] Account delete လုပ်လျှင် ကိုယ်ပိုင် guide များ ပျက်ပြီး public cache မပျက်ပါ။
- [ ] Admin claim ရှိသူသာ အခြားသူ၏ guide ကို စီမံနိုင်သည်။

Groq နှင့်အတူ:

- [ ] မှားသော ကီးဖြင့် ရှင်းလင်းသော error ရသည်။
- [ ] Model စာရင်း fetch လုပ်နိုင်သည်။
- [ ] မေးခွန်းတစ်ခု ပို့ပြီး အဖြေ stream ဖြင့် ရသည်။
- [ ] ကီးကို log/history/Firestore တွင် မတွေ့ပါ။

---

## ၁၅။ ပြဿနာဖြေရှင်းခြင်း (အကျဉ်း)

| ပြဿနာ | ဖြေရှင်းနည်း |
| --- | --- |
| Firebase မတပ်ဆင်ရသေးဟု ပြ | `android/app/google-services.json` နှင့် package name စစ်ပါ၊ သို့မဟုတ် `--dart-define` လေးခု စစ်ပါ၊ app ကို ပြန် run ပါ |
| `PERMISSION_DENIED` | Rules deploy လုပ်ပါ၊ အကောင့်/owner/admin စစ်ပါ |
| Index error | `firebase deploy --only firestore:indexes` လုပ်ပြီး စောင့်ပါ |
| Sign-in မရ | Email/Password၊ Anonymous၊ Google နှင့် GitHub provider ဖွင့်ထားခြင်း စစ်ပါ |
| Google ဖြင့် ဝင်မရ | Debug/Release SHA-1/SHA-256 လက်ဗွေထည့်ပြီး `google-services.json` ပြန် download လုပ်ပါ။ Android OAuth client နှင့် လက်မှတ် ကိုက်ညီမှုကို စစ်ပါ |
| Browser တွင် "missing initial state" | နောက်ဆုံး build သို့ update လုပ်ပါ (Google သည် native picker သုံးပြီ)။ GitHub အတွက် tab ပိတ်ပြီး ပုံမှန် tab ဖြင့် ပြန်စမ်းပါ | |
| GitHub redirect error | OAuth App callback သည် `https://<project-id>.firebaseapp.com/__/auth/handler` အတိအကျ ဖြစ်ရမည် |
| Termux မတွေ့ | GitHub release မှ ပြန်တပ်ဆင်ပါ၊ Termux ကို တစ်ကြိမ်ဖွင့်ပါ |
| Command မလုပ် | `allow-external-apps=true` နှင့် permission စစ်ပါ |
| AI 401 | ကီး မှန်/မမှန်၊ revoke ဖြစ်/မဖြစ် စစ်ပါ |
| AI 429 | Rate limit — ခဏစောင့်ပြီး ပြန်စမ်းပါ |
| မြန်မာစာ မဖတ်နိုင် | မြန်မာဘာသာ ရွေးပါ၊ Noto Sans Myanmar fallback ကို မဖျက်ပါ |
| Test ရပ်နေ | Drift widget test တွင် unmount + pump + `tester.runAsync(db.close)` လုပ်ပါ |

အသေးစိတ်: [Troubleshooting](troubleshooting.md)။

---

## ၁၆။ လုံခြုံရေးနှင့် ဒေတာ မှတ်ချက်များ

- Firebase Storage မသုံးပါ။ Avatar များသည် app ထဲပါ built-in ပုံများသာ။
- AI ကီးကို Firebase သို့ မပို့ပါ။
- AI history ကို မူရင်းအားဖြင့် local တွင်သာ သိမ်းသည်။
- Favorite/pin များကို user profile document တွင် သိမ်းသည်။
- Firestore rules က owner/admin ခွင့်ပြုချက်ကို တကယ်စစ်သည်။
  Button ဖျောက်ထားခြင်းကို လုံခြုံရေးအဖြစ် မသတ်မှတ်ပါ။
- **Local cache ရှင်းခြင်း** နှင့် **Account ဖျက်ခြင်း** သည် မတူပါ။
  Cache ရှင်းလျှင် public post များ မပျက်ပါ။ Account ဖျက်လျှင်
  ကိုယ်ပိုင် public guide များ ပျက်မည်။
- Secure storage သည် စက်တစ်ခုလုံး လုံခြုံသည်ဟု အာမမခံနိုင်ပါ။
  Root ပြုလုပ်ထားသော သို့မဟုတ် malware ရှိသော စက်တွင် ကီး
  ပေါက်ကြားနိုင်သည်။
- Service-account JSON၊ keystore၊ password နှင့် API ကီးများကို
  Git သို့ မတင်ပါနှင့်။

---

## ၁၇။ နောက်ထပ် ဖတ်ရန်

- [Burmese next steps](burmese-next-steps.md) — လက်ရှိ build အတွက်
  ကျန်ရှိသော လုပ်ငန်းများ
- [Firebase setup](firebase-setup.md)
- [Firebase Authentication setup](firebase-auth-setup.md)
- [Firestore setup](firestore-setup.md)
- [Security rules](security-rules.md)
- [Admin configuration](admin-setup.md)
- [Groq API setup](groq-setup.md)
- [Termux integration](termux-integration.md)
- [Build instructions](build.md)
- [Troubleshooting](troubleshooting.md)
- [Architecture](architecture.md)
- [Synchronization](synchronization.md)
