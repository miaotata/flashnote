import 'package:drift/drift.dart';

/// Web 端空执行器：不依赖任何 SQLite / WASM。
/// 所有读写均为空操作，UI 正常渲染，数据不持久。
class _NoOpExecutor extends QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) async {
    return [];
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 1;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 1;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() => _NoOpTransactionExecutor();

  @override
  QueryExecutor beginExclusive() => _NoOpExecutor();
}

class _NoOpTransactionExecutor extends _NoOpExecutor
    implements TransactionExecutor {
  @override
  bool get supportsNestedTransactions => false;

  @override
  Future<void> send() async {}

  @override
  Future<void> rollback() async {}
}

QueryExecutor createQueryExecutor() {
  return _NoOpExecutor();
}
