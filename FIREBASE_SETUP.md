/// GUÍA DE CONFIGURACIÓN DE FIREBASE PARA UNIEVENTOS
/// 
/// PASOS A SEGUIR:
/// 
/// 1. CREAR PROYECTO EN FIREBASE:
///    - Abre https://console.firebase.google.com
///    - Click en "Create a project"
///    - Nombre: "unieventos"
///    - Desactiva Google Analytics
///    - Click "Create project"
/// 
/// 2. CONFIGURAR ANDROID:
///    a) En la consola Firebase:
///       - Haz click en el ícono de Android (≡) en "Get started"
///       - Package name: com.example.unieventos
///       - App nickname: unieventos_android (opcional)
///       - Debug signing certificate SHA-1: (opcional, puedes dejarlo en blanco)
///       - Click "Register app"
///    
///    b) Descargar google-services.json:
///       - Click "Download google-services.json"
///       - Colócalo en: android/app/google-services.json
/// 
/// 3. CONFIGURAR iOS:
///    a) En la consola Firebase:
///       - Click en el ícono de Apple (🍎) en "Get started"
///       - Bundle ID: com.example.unieventos
///       - App nickname: unieventos_ios (opcional)
///       - Click "Register app"
///    
///    b) Descargar GoogleService-Info.plist:
///       - Click "Download GoogleService-Info.plist"
///       - Abre: open ios/Runner.xcworkspace
///       - Arrastra el archivo a Runner folder
///       - Marca "Copy items if needed"
///       - Cierra Xcode
/// 
/// 4. OBTENER CREDENCIALES:
///    a) Ve a Configuración (⚙️) → Configuración del proyecto
///    b) En la pestaña "Service Accounts":
///       - Copia el Project ID
///       - Guárdalo en un lugar seguro
/// 
/// 5. HABILITAR FIREBASE MESSAGING:
///    a) En el menú lateral, ve a: Cloud Messaging
///    b) Nota el "Sender ID"
///    c) Android:
///       - Ve a: Configuración → Integraciones → Cloud Messaging
///       - Copia la "Server API key"
///    d) iOS:
///       - Ve a: APNs Authentication Key (necesitas cuenta de Apple Developer)
/// 
/// 6. ACTUALIZAR firebase_options.dart:
///    - Abre lib/firebase_options.dart
///    - Reemplaza los valores TODO con los datos de tu proyecto
///    - Puedes encontrarlos en:
///      * google-services.json (para Android)
///      * GoogleService-Info.plist (para iOS)
/// 
/// 7. EJECUTAR PUB GET:
///    flutter pub get
/// 
/// 8. CONSTRUIR LA APP:
///    flutter run
/// 
/// NOTAS IMPORTANTES:
/// - Guarda tus credenciales de forma segura
/// - Nunca compartas tus API keys públicamente
/// - Para producción, usa una configuración más segura

// TODO: Después de seguir los pasos anteriores, ejecuta esto en tu terminal:
// 
// 1. flutter pub get
// 2. flutter run
//
// Si todo funciona, deberías ver la app sin errores de Firebase.
