<<<<<<< HEAD
# smart-fitting-room
Desarrollar una solución integral basada en tecnologías de Realidad Aumentada (AR), Inteligencia Artificial (IA), Internet de las Cosas (IoT) y plataformas móviles, que transforme la experiencia de compra en tiendas de moda, optimizando los procesos de selección, prueba y adquisición de prendas.
=======
# smart_fitting_room

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> d7c2818 (update READMEmain project Flutter)

# Proyecto Flutter — Smart Fitting Room & AR Commerce

Este proyecto corresponde al desarrollo de una aplicación móvil Flutter como parte del sistema “Smart Fitting Room & AR Commerce”, una solución tecnológica para tiendas de moda que integra probadores inteligentes con realidad aumentada, cámaras y algoritmos de IA.

## Contexto del Proyecto

El objetivo es diseñar una app modular y escalable para clientes y estilistas que interactúe con un ecosistema de hardware IoT (espejos AR, sensores RFID, brazos robóticos) y software inteligente (recomendador de outfits, chatbot estilista, CRM VIP).

### Supuestos

- Se usarán Firebase, n8n, MQTT, y servicios REST/GraphQL como backend.
- Flutter será el framework único para ambas apps (cliente y estilista).
- Se seguirá la arquitectura MVVM + Clean Architecture para asegurar testabilidad, separación de responsabilidades y mantenibilidad.

## Estructura del Proyecto (lib/)

lib/
├── config/               # Temas, rutas, inyección de dependencias
├── data/                 # Implementaciones concretas
│   ├── models/           # Modelos de datos (DTOs)
│   ├── repositories/     # Repositorios concretos (API, DB)
│   └── services/         # Integración con APIs, almacenamiento, etc.
├── domain/               # Reglas del negocio (independientes de Flutter)
│   ├── entities/         # Entidades puras
│   ├── usecases/         # Casos de uso (lógica de negocio)
│   └── repositories/     # Interfaces que usa domain
├── presentation/         # Capa de interfaz
│   ├── screens/          # Pantallas (vistas)
│   ├── widgets/          # Componentes reutilizables
│   └── viewmodels/       # Lógica de presentación (estado, controladores)
├── utils/                # Extensiones, helpers, constantes
└── main.dart             # Punto de entrada de la app

## Riesgos Previstos

- Acoplamiento excesivo entre capas si no se respetan las dependencias unidireccionales.
- Sobrecarga de ViewModels por lógica no delegada a casos de uso.
- Latencia o fallos en conexión con dispositivos IoT (puertas, RFID, etc.).
- Errores en sincronización entre app y backend (Firebase, n8n).
- Complejidad en pruebas de integración con servicios externos (p.ej., visor de AR).

## Pruebas Previstas

### En domain/usecases/

- Pruebas unitarias de reglas de negocio puras (sin dependencias).
- Validación de entrada/salida y transformación de datos.
- Casos extremos o edge cases (outfits no disponibles, error de cámara, etc.).
