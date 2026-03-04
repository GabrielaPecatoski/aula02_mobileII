# ARCH — Documentação da Refatoração

## Estrutura Final (feature-first)

```
lib/
├── main.dart
├── core/
│   └── errors/
│       └── app_errors.dart
└── features/
    └── todos/
        ├── data/
        │   ├── datasources/
        │   │   ├── todo_local_datasource.dart
        │   │   └── todo_remote_datasource.dart
        │   ├── models/
        │   │   └── todo_model.dart
        │   └── repositories/
        │       └── todo_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── todo.dart
        │   └── repositories/
        │       └── todo_repository.dart
        └── presentation/
            ├── app_root.dart
            ├── pages/
            │   └── todos_page.dart
            ├── viewmodels/
            │   └── todo_viewmodel.dart
            └── widgets/
                └── add_todo_dialog.dart
```

## Fluxo de Dependências

```
┌─────────────────┐
│   UI (Pages)    │  ← widgets: AddTodoDialog, CheckboxListTile, etc.
└────────┬────────┘
         │ observa estado
         ▼
┌─────────────────────┐
│  ViewModel          │  ← gerencia estado (ChangeNotifier)
│  TodoViewModel      │    - items, isLoading, errorMessage
└────────┬────────────┘
         │ usa interface abstrata
         ▼
┌─────────────────────┐
│ Repository (Abstract)│  ← define contrato
│ TodoRepository       │
└────────┬────────────┘
         │ implementação
         ▼
┌─────────────────────┐     ┌─────────────────────┐
│ RemoteDataSource    │     │ LocalDataSource     │
│ (HTTP client)       │     │ (SharedPreferences) │
└─────────────────────┘     └─────────────────────┘
```

## Justificativa da Estrutura

### Domain Layer (核)
- **entities/**: Contém a entidade pura `Todo` - o modelo de negócio sem dependências externas
- **repositories/**: Interface abstrata `TodoRepository` que define o contrato entre domain e data

### Data Layer
- **models/**: `TodoModel` estende `Todo` e adiciona `fromJson/toJson` - responsabilidade de parsing
- **datasources/**: 
  - `TodoRemoteDataSource`: Chama API HTTP (jsonplaceholder)
  - `TodoLocalDataSource`: Persiste lastSync via SharedPreferences
- **repositories/**: `TodoRepositoryImpl` implementa o contrato, coordenando qual datasource usar

### Presentation Layer
- **pages/**: `TodosPage` - UI que observa ViewModel
- **widgets/**: `AddTodoDialog` - diálogos e componentes reutilizáveis
- **viewmodels/**: `TodoViewModel` - estado e lógica de apresentação
- **app_root.dart**: Ponto de entrada do app com MaterialApp

### Core
- **errors/**: `AppError` - classe de erro reutilizável

## Decisões de Responsabilidade

### Onde ficou a validação?
A validação de "título não vazio" ficou no **ViewModel** (`todo_viewmodel.dart`):
```dart
if (title.trim().isEmpty) {
  errorMessage = 'Título não pode ser vazio.';
  notifyListeners();
  return;
}
```
**Justificativa**: Validação de entrada de usuário é responsabilidade da camada de apresentação.

### Onde ficou o parsing JSON?
O parsing JSON está no **Model** (`todo_model.dart`):
```dart
factory TodoModel.fromJson(Map<String, dynamic> json) {
  return TodoModel(
    id: (json['id'] as num).toInt(),
    title: (json['title'] ?? '').toString(),
    completed: (json['completed'] ?? false) as bool,
  );
}
```
**Justificativa**: Models são responsáveis por converter dados externos (JSON) para entidades do domínio.

### Como você tratou erros?
1. **DataSources**: Lançam `Exception` com mensagem HTTP:
   ```dart
   if (res.statusCode < 200 || res.statusCode >= 300) {
     throw Exception('HTTP ${res.statusCode}');
   }
   ```

2. **Repository**: Propaga exceções para o ViewModel

3. **ViewModel**: Captura exceções e armazena em `errorMessage`:
   ```dart
   } catch (e) {
     errorMessage = 'Falha ao carregar: $e';
   }
   ```

4. **UI**: Exibe mensagem de erro ao usuário quando `errorMessage != null`

**Justificativa**: O fluxo de erros sobe pela cadeia até ser tratado na UI, onde o usuário pode visualizar e agir.

## Regras Cumpridas

- UI não chama HTTP nem SharedPreferences diretamente
- ViewModel não conhece Widgets/BuildContext (exceto via estado notifyListeners)
- Repository centraliza escolha entre fonte remota e local
- Lógica interna das classes mantida intacta
- Estrutura escalável feature-first

