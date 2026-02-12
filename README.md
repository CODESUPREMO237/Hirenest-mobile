# jobconnect

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Architecture
See [docs/architecture.md](docs/architecture.md) for clean architecture layers, folder structure, testing strategy, and Docker guidance.


## Clean Architecture Overview
This project is organized into clear layers so domain logic remains independent from framework and delivery concerns.

### Layers
- Domain
- Application
- Infrastructure
- Interfaces

### Folder Structure
See [docs/architecture.md](docs/architecture.md) for the structure and responsibilities of each layer.

### Quality
- Linting configured for code quality checks.
- Unit and integration tests scaffolded under 	ests/unit and 	ests/integration.
- Dockerfile included for reproducible runtime.

