## Mapeo OWASP Movile Top

### M1 – Improper Credential Usage

- Verificado: Las claves de Supabase estaban inicialmente hardcodeadas en el archivo `supabase_config.dart`.
- Mitigación: Se movieron a un archivo `.env` local, cargado con `flutter_dotenv`, y se agregó `.env` al `.gitignore`.
- Verificación: Se imprimieron temporalmente en la terminal al correr `flutter run` en dispositivo físico.
- Consideración: En producción se evitará empaquetar `.env` como asset y se usará `--dart-define` para inyectar las claves de forma segura.
- Riesgo reducido: Las credenciales ya no están expuestas en el código fuente ni en el repositorio.



### M2 – Insecure Data Storage

- Verificado: La app no guarda datos sensibles como claves, tokens o contraseñas en el dispositivo.
- Mitigación: Las credenciales se cargan desde `.env` en desarrollo y no se almacenan localmente.
- Consideración: Si se implementa almacenamiento de sesión o tokens, se usará `flutter_secure_storage` para cifrado seguro.
- Pendiente: La contraseña del usuario aún no se cifra antes de enviarse o almacenarse. Este punto será abordado en la siguiente fase.



### M5 – Insufficient Cryptography

- Verificado: La app transmite datos sensibles por HTTPS (Supabase lo usa por defecto).
- Mitigación: Las claves API se cargan desde `.env` y no se exponen en el código ni en el almacenamiento local.
- Consideración: Se implementará cifrado para contraseñas de usuario antes de enviarlas a Supabase.
- Riesgo reducido: No se detecta uso de algoritmos débiles ni almacenamiento sin cifrado.



### M8 – Code Tampering

- Verificado: La app no expone lógica sensible ni claves en el código fuente.
- Mitigación: Las claves están fuera del código fuente y no se empaquetan en producción.
- Consideración: Para producción se compilará con firma digital y ofuscación (`--obfuscate`) para evitar repackaging o modificación maliciosa.
- Riesgo reducido: No se detecta exposición directa a manipulación del APK.



### M9 – Reverse Engineering

- Verificado: No hay claves hardcodeadas ni lógica sensible expuesta.
- Mitigación: Se eliminó el uso directo de claves en el código y se encapsuló la lógica de conexión.
- Consideración: Se usará ofuscación en builds de producción (`--obfuscate --split-debug-info`) para dificultar el análisis estático.
- Riesgo reducido: El APK no contiene información crítica en texto plano y se previene el análisis directo.
